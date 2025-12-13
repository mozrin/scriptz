#!/bin/bash

set -e

show_help() {
  cat <<EOF
git-release - Create a versioned release from develop to main

DESCRIPTION
  Automates the release workflow: commits version changes, merges develop
  into main, creates a git tag, and pushes everything to origin.

USAGE
  git-release new --number=<version> --name=<name> [options]

ARGUMENTS
  new               Required. The release command (only 'new' is supported).

OPTIONS
  --number=VERSION  Required. The version number (e.g., 1.2.0)
  --name=NAME       Required. The release name (e.g., "Holiday Update")
  --composer        Update version in composer.json before committing
  --help            Show this help message and exit

WORKFLOW
  1. Validates you're on the develop branch with no uncommitted changes
  2. (Optional) Updates composer.json version if --composer is set
  3. Commits with message "Release VERSION NAME"
  4. Pushes develop to origin
  5. Checks out main and merges develop
  6. Pushes main to origin
  7. Creates annotated tag vVERSION with message "NAME"
  8. Pushes tag to origin

EXAMPLES
  git-release new --number=1.0.0 --name="Initial Release"
  git-release new --number=2.1.0 --name="Spring Update" --composer

EOF
  exit 0
}

if [ "${1:-}" = "--help" ]; then
  show_help
fi

if [ "$1" != "new" ]; then
  echo "Usage: git-release new --number=<version> --name=<name> [--composer]"
  echo "Try 'git-release --help' for more information."
  exit 1
fi


for arg in "$@"; do
  case $arg in
    --number=*)
      RELEASE_NUMBER="${arg#*=}"
      ;;
    --name=*)
      RELEASE_NAME="${arg#*=}"
      ;;
    --composer)
      UPDATE_COMPOSER=true
      ;;
  esac
done

if [ -z "$RELEASE_NUMBER" ] || [ -z "$RELEASE_NAME" ]; then
  echo "Both --number and --name are required."
  exit 1
fi

BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$BRANCH" != "develop" ]; then
  echo "You must be on the develop branch to run this script."
  exit 1
fi

if ! git diff-index --quiet HEAD --; then
  echo "You have uncommitted changes. Commit or stash them first."
  exit 1
fi

echo "=========================================="
echo " Release preparation"
echo " Branch: $BRANCH"
echo " Target version: $RELEASE_NUMBER"
echo " Release name: $RELEASE_NAME"
echo " Actions:"
if [ "$UPDATE_COMPOSER" = true ]; then
  echo "  - Update composer.json version"
fi
echo "  - Commit and push to develop"
echo "  - Merge into main"
echo "  - Push main"
echo "  - Tag v$RELEASE_NUMBER ($RELEASE_NAME)"
echo "  - Push tag"
echo "=========================================="
echo

read -p "Do you want to continue with this release? (y/N) " CONFIRM
if [ "$CONFIRM" != "y" ]; then
  echo "Release aborted."
  exit 1
fi

if [ "$UPDATE_COMPOSER" = true ]; then
  sed -i.bak "s/\"version\": \".*\"/\"version\": \"$RELEASE_NUMBER\"/" composer.json
  rm composer.json.bak
  git add composer.json
fi

git commit -m "Release $RELEASE_NUMBER $RELEASE_NAME"
git push origin develop

git checkout main
git merge develop
git push origin main

git tag -a v$RELEASE_NUMBER -m "$RELEASE_NAME"
git push origin v$RELEASE_NUMBER

echo "Release $RELEASE_NUMBER ($RELEASE_NAME) completed successfully."
