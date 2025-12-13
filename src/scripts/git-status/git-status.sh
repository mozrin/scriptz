#!/bin/bash

set -euo pipefail

SOURCE=~/Code
WIDTH=80
SKIP_NO_CHANGES=0

show_help() {
  cat <<EOF
git-status - Multi-repository status overview

DESCRIPTION
  Scans a directory for git repositories and displays a summary of each,
  including the current branch, pending changes, and available branches.
  Great for managing multiple projects at once.

USAGE
  git-status [options]

OPTIONS
  --source=PATH       Directory to scan for git repos (default: ~/Code)
  --width=N           Width of the output table in characters (default: 80)
  --skip-no-changes   Only show repos with uncommitted changes
  --help              Show this help message and exit

OUTPUT
  Displays a formatted table for each repository showing:
  - Repository name and local folder
  - Current branch name
  - Status: "up-to-date" (green) or "changes pending" (yellow)
  - List of all local branches

EXAMPLES
  git-status
  git-status --source=/projects
  git-status --skip-no-changes
  git-status --source=~/work --width=120

EOF
  exit 0
}

for arg in "$@"; do
  case $arg in
    --help)
      show_help
      ;;
    --source=*)
      SOURCE="${arg#--source=}"
      ;;
    --width=*)
      WIDTH="${arg#--width=}"
      ;;
    --skip-no-changes)
      SKIP_NO_CHANGES=1
      ;;
  esac
done


ROOT=$(realpath "$SOURCE")
echo "Root: $ROOT"

GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RESET="\033[0m"

draw_line() {
  local left="$1"
  local fill="$2"
  local right="$3"
  local width="$4"
  printf "%s" "$left"
  for ((i=1; i<=width-2; i++)); do printf "%s" "$fill"; done
  printf "%s\n" "$right"
}

pad_line() {
  local left="$1"
  local content="$2"
  local right="$3"
  local width="$4"
  printf "%s %-*s %s\n" "$left" $((width-4)) "$content" "$right"
}

find "$SOURCE" -type d -name ".git" | while read gitdir; do
  folder=$(dirname "$gitdir")
  cd "$folder" || continue
  remote=$(git remote get-url origin 2>/dev/null)
  repo=$(echo "$remote" | sed -E 's/.*[:\/]([^\/]+\/[^\/]+)(\.git)?$/\1/')
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  status="up-to-date"
  color=$GREEN
  if ! git diff --quiet || ! git diff --cached --quiet; then
    status="changes pending"
    color=$YELLOW
  fi
  if [[ $SKIP_NO_CHANGES -eq 1 && "$status" == "up-to-date" ]]; then
    continue
  fi
  branches=$(git branch --list | sed 's/^[* ] //' | paste -sd "," -)

  draw_line "╔" "═" "╗" "$WIDTH"
  pad_line "║" "Repo: $repo    Folder: ./" "║" "$WIDTH"
  draw_line "║" "─" "║" "$WIDTH"
  printf "║ Branch: %-20s Status: %b%-20s%b" "$branch" "$color" "$status" "$RESET"
  printf "%*s║\n" $((WIDTH - 4 - 20 - 8 - 20)) ""
  draw_line "║" "─" "║" "$WIDTH"
  pad_line "║" "Branches: $branches" "║" "$WIDTH"
  draw_line "╚" "═" "╝" "$WIDTH"
done
