#!/usr/bin/env bash
#
# scriptz.sh - unified command dispatcher for Moztopia scripts
#
# Usage:
#   scriptz <verb> [--options...]
#
# Verbs:
#   link       Manage symlinks (replace moz_symlinks)
#   list       Show available scripts and installation status
#   install    Run installer blocks with toggle options
#   extract    Ergonomic tarball extraction into workspace
#   help       Show usage examples and workflow guidance
#   version    Manage installed versions of scriptz
#
# Global Options:
#   --dry-run   Show actions without making changes
#   --verbose   Print detailed operator actions
#   --force     Overwrite existing files or links
#

set -euo pipefail

SCRIPTZ_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_FOLDER="${INSTALL_FOLDER:-/usr/local}"
BIN_DIR="$INSTALL_FOLDER/bin"
LIB_DIR="$INSTALL_FOLDER/lib"

# Print usage information
usage() {
  echo "Usage: scriptz <verb> [--options...]"
  echo "Verbs: link, list, install, extract, help, version"
  exit 1
}

# Handle symlink operations
link_cmd() {
  case "$1" in
    --list)
      ls -l "$SCRIPTZ_DIR" | grep '->' || echo "[scriptz] No symlinks found"
      ;;
    --add=*)
      target="${1#--add=}"
      shift
      dest="."
      for arg in "$@"; do
        case "$arg" in
          --dest=*|--destination=*)
            dest="${arg#*=}"
            ;;
        esac
      done
      ln -sfn "$target" "$dest" && echo "[scriptz] Linked $target → $dest"
      ;;
    --remove=*)
      dest="${1#--remove=}"
      rm -f "$dest" && echo "[scriptz] Removed symlink $dest"
      ;;
    --help)
      echo "Usage: scriptz link --list | --add=<src> [--dest=<path>] | --remove=<path>"
      ;;
    *)
      echo "[scriptz] Unknown link option: $1"
      ;;
  esac
}

# List available scripts
list_cmd() {
  concise=false
  color=false

  # Parse options
  for arg in "$@"; do
    case "$arg" in
      --concise) concise=true ;;
      --color)   color=true ;;
    esac
  done

  scripts=(git-cache.sh moz_symlinks.sh moz_scripts.sh scriptz.sh)

  if $concise; then
    for s in "${scripts[@]}"; do
      echo "$s"
    done
  else
    printf "%-20s | %-10s\n" "Script" "Status"
    printf "%-20s-+-%-10s\n" "--------------------" "----------"
    for s in "${scripts[@]}"; do
      if [[ -x "$SCRIPTZ_DIR/$s" ]]; then
        status="installed"
        [[ $color == true ]] && status="\033[32m$status\033[0m"
      else
        status="missing"
        [[ $color == true ]] && status="\033[31m$status\033[0m"
      fi
      printf "%-20s | %-10b\n" "$s" "$status"
    done
  fi
}

# Installer operations
install_cmd() {
  echo "[scriptz] install stub - implement toggle-driven installer blocks"
}

# Extraction operations
extract_cmd() {
  echo "[scriptz] extract stub - implement ergonomic tarball extraction"
}

# Version management
version_cmd() {
  action=""
  target=""

  for arg in "$@"; do
    case "$arg" in
      --select=*)
        action="select"
        target="${arg#*=}"
        ;;
      --delete=*)
        action="delete"
        target="${arg#*=}"
        ;;
    esac
  done

  versions=( $(ls -1t "$LIB_DIR" | grep '^scriptz-' || true) )
  active="$(readlink "$BIN_DIR/scriptz" | sed 's#.*/##')"

  if [[ -z "$action" ]]; then
    echo "Available versions (newest → oldest):"
    for v in "${versions[@]}"; do
      marker=""
      [[ "$v" == "$active" ]] && marker="*"
      date="$(stat -c %y "$LIB_DIR/$v" | cut -d' ' -f1)"
      echo "  $v [$date] $marker"
    done
    return
  fi

  case "$action" in
    select)
      if [[ ! -d "$LIB_DIR/$target" ]]; then
        echo "[scriptz] Version $target not found"
        exit 1
      fi
      ln -sf "$LIB_DIR/$target/scriptz.sh" "$BIN_DIR/scriptz"
      echo "[scriptz] Active version set to $target"
      ;;
    delete)
      if [[ "$target" == "$active" ]]; then
        echo "[scriptz] Cannot delete active version ($target)"
        exit 1
      fi
      if [[ "${#versions[@]}" -le 1 ]]; then
        echo "[scriptz] Cannot delete the last remaining version"
        exit 1
      fi
      rm -rf "$LIB_DIR/$target"
      echo "[scriptz] Deleted version $target"
      ;;
  esac
}

verb="${1:-}"
shift || true

case "$verb" in
  link)
    link_cmd "$@"
    ;;
  list)
    list_cmd "$@"
    ;;
  install)
    install_cmd "$@"
    ;;
  extract)
    extract_cmd "$@"
    ;;
  version)
    version_cmd "$@"
    ;;
  help)
    usage
    ;;
  *)
    echo "[scriptz] Unknown verb: $verb"
    usage
    ;;
esac
