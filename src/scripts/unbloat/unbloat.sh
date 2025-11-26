#!/bin/bash

set -e

show_help() {
  cat <<EOF
Usage: $0 [options]

Options:
  --help                       Show this help message
  --dry-run                    Print commands instead of executing
  --yes                        Run without prompting for confirmation
  --no-purge-packages          Skip purging leftover package configs
  --no-empty-trash             Skip emptying user trash
  --no-deborphan               Skip orphaned library cleanup
  --no-journal-vacuum          Skip journal vacuum
  --journal-vacuum-threshold=X Set journal vacuum threshold (default: 7d)
  --no-temp-files              Skip cleaning /tmp and /var/tmp
  --no-thumbnail-cache         Skip cleaning thumbnail cache
  --no-deep-purge              Skip kernel and deep purge
  --log_file=DIR               Directory to store logs (default: ~/.logs)
EOF
}

DRYRUN=false
CONFIRM=true
PURGE_PACKAGES=true
EMPTY_TRASH=true
DEBORPHAN=true
JOURNAL_VACUUM=true
JOURNAL_THRESHOLD="7d"
TEMP_FILES=true
THUMBNAIL_CACHE=true
DEEP_PURGE=true
LOG_DIR="$HOME/.logs"

for arg in "$@"; do
  case $arg in
    --help) show_help; exit 0 ;;
    --dry-run) DRYRUN=true ;;
    --yes) CONFIRM=false ;;
    --no-purge-packages) PURGE_PACKAGES=false ;;
    --no-empty-trash) EMPTY_TRASH=false ;;
    --no-deborphan) DEBORPHAN=false ;;
    --no-journal-vacuum) JOURNAL_VACUUM=false ;;
    --journal-vacuum-threshold=*) JOURNAL_THRESHOLD="${arg#*=}" ;;
    --no-temp-files) TEMP_FILES=false ;;
    --no-thumbnail-cache) THUMBNAIL_CACHE=false ;;
    --no-deep-purge) DEEP_PURGE=false ;;
    --log_file=*) LOG_DIR="${arg#*=}" ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

# Ensure log directory exists
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/unbloat_$(date +%Y%m%d-%H%M%S).log"

run_cmd() {
  if $DRYRUN; then
    echo "[DRY-RUN] $*" | tee -a "$LOG_FILE"
  else
    if $CONFIRM; then
      read -p "Run: $* ? [y/N] " ans
      [[ "$ans" == "y" || "$ans" == "Y" ]] || { echo "[SKIPPED] $*" | tee -a "$LOG_FILE"; return; }
    fi
    echo "[RUN] $*" | tee -a "$LOG_FILE"
    eval "$@" >>"$LOG_FILE" 2>&1
  fi
}

# Cleanup steps
$PURGE_PACKAGES && run_cmd "sudo apt purge \$(dpkg -l | awk '/^rc/ {print \$2}')"
$EMPTY_TRASH && run_cmd "rm -rf ~/.local/share/Trash/*"
$DEBORPHAN && run_cmd "sudo deborphan | xargs sudo apt purge -y"
$JOURNAL_VACUUM && run_cmd "sudo journalctl --vacuum-time=$JOURNAL_THRESHOLD"
$TEMP_FILES && run_cmd "sudo rm -rf /tmp/* /var/tmp/*"
$THUMBNAIL_CACHE && run_cmd "rm -rf ~/.cache/thumbnails/*"
$DEEP_PURGE && run_cmd "sudo apt autoremove --purge -y"

# Always clean apt caches
run_cmd "sudo apt clean"
run_cmd "sudo apt autoclean"

echo "Detailed log written to: $LOG_FILE"
