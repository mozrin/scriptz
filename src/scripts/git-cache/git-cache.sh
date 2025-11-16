#!/usr/bin/env bash
#
# git-cache.sh - manage Git index (cache) operations
#
# Usage:
#   git-cache.sh delete <filepath> [--dry-run] [--quiet]
#   git-cache.sh --help
#

set -euo pipefail
set -f  # disable pathname expansion so wildcards are passed literally

show_help() {
  cat <<EOF
Usage: git-cache.sh <command> [options]

Commands:
  delete <filepath>   Remove a file or folder from Git's index (cache)

Options:
  --dry-run           Show what would be removed, but do not execute
  --quiet             Suppress output
  --help              Show this help message

Examples:
  git-cache.sh delete '.pai/*.txt' --dry-run
  git-cache.sh delete .devcontainer/redis/log --quiet
EOF
}

delete_file() {
  local dryrun=false
  local quiet=false
  local args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) dryrun=true ;;
      --quiet) quiet=true ;;
      --help) show_help; exit 0 ;;
      *) args+=("$1") ;;
    esac
    shift
  done

  if [[ ${#args[@]} -eq 0 ]]; then
    echo "Error: delete requires a <filepath>" >&2
    exit 1
  fi

  # Fail if more than one filepath argument was passed (means glob expanded)
  if [[ ${#args[@]} -gt 1 ]]; then
    echo "Error: wildcard expanded into multiple files. Quote or escape the pattern to pass literally." >&2
    echo "Example: git-cache.sh delete '.pai/*.txt' --dry-run" >&2
    exit 1
  fi

  if [[ "$dryrun" == true ]]; then
    echo "[DRYRUN] Would run: git rm -r --cached ${args[*]}"
    return 0
  fi

  if [[ "$quiet" == true ]]; then
    git rm -r --cached "${args[@]}" >/dev/null 2>&1 || true
  else
    git rm -r --cached "${args[@]}"
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
      delete_file "${@:2}"
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
