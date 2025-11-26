#!/usr/bin/env bash

source ~/Code/scriptz/src/scripts/scriptz_library.sh

set -euo pipefail

ORG="moztopia"
TARGET_ORG="maqbara"
QUIET=false

usage() {
  echo "Usage: archive_project <project_name> [--org=ORG] [--quiet] [--help]"
  exit 0
}

PROJECT_NAME=""
for arg in "$@"; do
  case $arg in
    --org=*)
      ORG="${arg#*=}"
      ;;
    --quiet)
      QUIET=true
      ;;
    --help)
      usage
      ;;
    *)
      PROJECT_NAME="$arg"
      ;;
  esac
done

if [[ -z "$PROJECT_NAME" ]]; then
  echo "Error: project name required"
  usage
fi

REPO="$ORG/$PROJECT_NAME"
TIMESTAMP=$(date +"%Y%m%d-%H%M")
DEST_NAME="${PROJECT_NAME}-${TIMESTAMP}"

# Decide whether to suppress JSON
API_FLAGS="--silent"
if $QUIET; then
  API_FLAGS=""
fi

log() {
  if ! $QUIET; then
    echo "$@"
  fi
}

log "Preparing to transfer $REPO → $TARGET_ORG/$DEST_NAME"

# Step 0: Ensure source repo exists
if ! gh api -X GET "repos/$ORG/$PROJECT_NAME" $API_FLAGS >/dev/null 2>&1; then
  log "Repository $REPO not found."
  exit 1
fi

# Step 1: Transfer ownership with new name
log "Transferring repository to $TARGET_ORG as $DEST_NAME..."
gh api -X POST "repos/$ORG/$PROJECT_NAME/transfer" \
  -f new_owner="$TARGET_ORG" \
  -f new_name="$DEST_NAME" $API_FLAGS
log "✔ Transfer request sent"

# Step 2: Conservative wait based on repo size
REPO_SIZE_KB=$(gh api -X GET "repos/$ORG/$PROJECT_NAME" --jq '.size')
REPO_SIZE_MB=$((REPO_SIZE_KB / 1024))
WAIT_TIME=$((REPO_SIZE_MB * 2))
if [ $WAIT_TIME -lt 5 ]; then WAIT_TIME=5; fi

log "⏳ Waiting ~${WAIT_TIME}s for transfer to propagate..."
sleep $WAIT_TIME

# Step 3: Poll destination org until repo appears
for i in {1..10}; do
  if gh api -X GET "repos/$TARGET_ORG/$DEST_NAME" $API_FLAGS >/dev/null 2>&1; then
    log "✔ Transfer confirmed: $TARGET_ORG/$DEST_NAME exists"
    break
  else
    if ! $QUIET; then
      echo "… still waiting ($i)"
    fi
    sleep 5
  fi
  if [ $i -eq 10 ]; then
    log "✖ Transfer not visible after waiting. Exiting."
    exit 1
  fi
done

# Step 4: Make private in destination org
log "Marking repository as private..."
gh api -X PATCH "repos/$TARGET_ORG/$DEST_NAME" -f private=true $API_FLAGS
log "✔ Repo marked private"

# Step 5: Archive in destination org (last step)
log "Archiving repository..."
gh api -X PATCH "repos/$TARGET_ORG/$DEST_NAME" -f archived=true $API_FLAGS
log "✔ Repo archived"

log "✅ Repo $PROJECT_NAME successfully transferred, renamed to $DEST_NAME, marked private, and archived."
