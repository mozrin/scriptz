#!/bin/sh

usage() {
    echo "Usage: $0 <project_folder> [--template=org/template_repo] [--yes] [--quiet|--silent] [--help]"
    echo
    echo "Arguments:"
    echo "  <project_folder>   Target folder (default: current directory '.')"
    echo "  --template=URL     Optional template repository to clone"
    echo "  --yes              Skip confirmation prompt"
    echo "  --quiet|--silent   Suppress output"
    echo "  --help             Show this help message"
    exit 1
}

PROJECT="."
TEMPLATE=""
CONFIRM=true
QUIET=false

for arg in "$@"; do
    case $arg in
        --help) usage ;;
        --yes) CONFIRM=false ;;
        --quiet|--silent) QUIET=true ;;
        --template=*) TEMPLATE="${arg#*=}" ;;
        *) PROJECT="$arg" ;;
    esac
done

if [ $# -eq 0 ]; then
    usage
fi

if $CONFIRM; then
    echo "Initialize git repo in '$PROJECT'? (y/N)"
    read ans
    case "$ans" in
        y|Y) ;;
        *) echo "Aborted."; exit 1 ;;
    esac
fi

mkdir -p "$PROJECT"
cd "$PROJECT" || exit 1

# Init local repo
if $QUIET; then
    git init -b main >/dev/null 2>&1
    git checkout -b develop >/dev/null 2>&1
else
    git init -b main
    git checkout -b develop
fi

# Create GitHub repo (private by default, change with --public if desired)
REPO=$(basename "$(pwd)")
OWNER=$(gh api user --jq .login)

if ! $QUIET; then
    echo "Creating GitHub repo $OWNER/$REPO..."
fi

gh repo create "$OWNER/$REPO" --private --source=. --remote=origin --push

# Optional template remote
if [ -n "$TEMPLATE" ]; then
    if $QUIET; then
        git remote add template "$TEMPLATE" >/dev/null 2>&1
    else
        git remote add template "$TEMPLATE"
    fi
fi

# Protect main
gh api -X PUT repos/$OWNER/$REPO/branches/main/protection \
  -F required_pull_request_reviews='{"required_approving_review_count":1}' \
  -F enforce_admins=true \
  -F restrictions='{"users":[],"teams":[]}' \
  -F allow_force_pushes=false \
  -F allow_deletions=false

# Protect develop
gh api -X PUT repos/$OWNER/$REPO/branches/develop/protection \
  -F required_pull_request_reviews='{"required_approving_review_count":1}' \
  -F enforce_admins=true \
  -F restrictions='{"users":[],"teams":[]}' \
  -F allow_force_pushes=false \
  -F allow_deletions=false

# Disallow branch names starting with main* or develop*
gh api -X POST repos/$OWNER/$REPO/rulesets \
  -F name="No main* or develop* branches" \
  -F target="branch" \
  -F enforcement="active" \
  -F rules='[{"type":"branch_name_pattern","parameters":{"operator":"starts_with","pattern":"main"}}]' \
  -F rules='[{"type":"branch_name_pattern","parameters":{"operator":"starts_with","pattern":"develop"}}]'

if ! $QUIET; then
    echo "Repository $OWNER/$REPO initialized, pushed, and protections applied."
fi
