#!/usr/bin/env bash
#
# git-cache.sh - manage Git index (cache) operations
#
# Usage:
#   git-cache.sh delete <filepath> [--dryrun] [--quiet]
#   git-cache.sh --help
#

set -euo pipefail

show_help() {
  cat <<EOF
Usage: git-cache.sh <command> [options]

Commands:
  delete <filepath>   Remove a file or folder from Git's index (cache)

Options:
  --dryrun            Show what would be removed, but do not execute
  --quiet             Suppress output
  --help              Show this help message

Examples:
  git-cache.sh delete .devcontainer/mariadb/data --dryrun
  git-cache.sh delete .devcontainer/redis/log --quiet
EOF
}

delete_file() {
  local filepath="$1"
  local dryrun=false
  local quiet=false

  shift
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dryrun) dryrun=true ;;
      --quiet) quiet=true ;;
      --help) show_help; exit 0 ;;
      *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
    shift
  done

  if [[ "$dryrun" == true ]]; then
    echo "[DRYRUN] Would run: git rm -r --cached \"$filepath\""
    return 0
  fi

  if [[ "$quiet" == true ]]; then
    git rm -r --cached "$filepath" >/dev/null 2>&1 || true
  else
    git rm -r --cached "$filepath"
  fi
}

main() {
  if [[ $# -lt 1 ]]; then
    show_help
    exit 1
  fi

  case "$1" in
    delete)
      if [[ $# -lt 2 ]]; then
        echo "Error: delete requires a <filepath>" >&2
        exit 1
      fi
      delete_file "$2" "${@:3}"
      ;;
    --help|-h)
      show_help
      ;;
    *)
      echo "Unknown command: $1" >&2
      show_help
      exit 1
      ;;
  esac
}

main "$@"
