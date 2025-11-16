#!/usr/bin/env bash
set -euo pipefail

show_help() {
  echo "Usage: backup_project <source_pattern...> [<destination_folder>] [<date>] [--no-compress] [--quiet]"
  echo
  echo "Arguments:"
  echo "  <source_pattern...>   One or more folders (wildcards allowed)."
  echo "  <destination_folder>  Optional. Defaults to ./.project_backups"
  echo "  <date>                Optional. Format: 'YYYY-MM-DD HH:MM:SS'. Defaults to now."
  echo
  echo "Options:"
  echo "  --help                Show this help message and exit."
  echo "  --no-compress         Disable compression. By default, backups are compressed."
  echo "  --quiet               Suppress all output."
  echo
  echo "Examples:"
  echo "  backup_project \"devlite_*\""
  echo "  backup_project src1 src2 /mnt/backups"
  echo "  backup_project src1 src2 /mnt/backups \"2025-11-06 08:00:00\""
  echo "  backup_project src1 src2 --no-compress"
  echo "  backup_project src1 src2 --quiet"
}

if [ "${1:-}" = "--help" ]; then
  show_help
  exit 0
fi

args=("$@")
compress=true
quiet=false

# Detect flags
for i in "${!args[@]}"; do
  case "${args[$i]}" in
    --no-compress)
      compress=false
      unset 'args[$i]'
      ;;
    --quiet)
      quiet=true
      unset 'args[$i]'
      ;;
  esac
done

dest="./.project_backups"
date_arg=""

# Detect if last arg is a valid date
if [ "${#args[@]}" -gt 1 ] && date -d "${args[-1]}" >/dev/null 2>&1; then
  date_arg="${args[-1]}"
  unset 'args[-1]'
fi

# If more than one arg remains, check if last is destination
if [ "${#args[@]}" -gt 1 ]; then
  last="${args[-1]}"
  if [[ "$last" = /* || "$last" = .* ]]; then
    dest="$last"
    unset 'args[-1]'
  fi
fi

sources=("${args[@]}")

if [ -z "$date_arg" ]; then
  ts="$(date '+%Y-%m-%d_%H-%M-%S')"
else
  if ! ts="$(date -d "$date_arg" '+%Y-%m-%d_%H-%M-%S' 2>/dev/null)"; then
    if ! $quiet; then
      echo "Error: '$date_arg' is not a valid date."
      echo "Hint: If you meant multiple sources (e.g. devlite_*), wrap the pattern in quotes:"
      echo "  backup_project \"devlite_*\""
    fi
    exit 1
  fi
fi

mkdir -p "$dest"

archive_count=0
source_count=0

if ! $quiet; then
  echo "============================================================"
  echo "   Backup Project by Moztopia"
  echo "   Run started: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "============================================================"
  echo
  echo "Sources to be backed up:"
  for src in "${sources[@]}"; do
    [ -d "$src" ] || continue
    echo "  - $src"
  done
  echo
  echo "Press ENTER to continue or CTRL-C to stop..."
  read -t 10 || true
  echo
fi

for src in "${sources[@]}"; do
  [ -d "$src" ] || continue
  if [ "$(realpath "$src")" = "$(realpath "$dest")" ]; then
    continue
  fi

  source_count=$((source_count + 1))
  backup_dir="$dest/$(basename "$src")_$ts"
  mkdir -p "$backup_dir"

  if ! $quiet; then
    echo "[*] Backing up $src -> $backup_dir ..."
  fi
  rsync -a --info=progress2 \
    --exclude="$(basename "$dest")" \
    --exclude='**/.git' \
    "$src"/ "$backup_dir"/
  if ! $quiet; then
    echo "[✓] Backup complete for $src"
  fi

  if $compress; then
    archive_name="$(basename "$src")_$ts.tar.gz"
    tmp_dir="./.project_backups_temp"
    mkdir -p "$tmp_dir"

    if ! $quiet; then
      echo "[*] Compressing into $archive_name ..."
    fi
    if command -v pv >/dev/null 2>&1; then
      tar -C "$backup_dir" -cf - . | pv | gzip -9 > "$tmp_dir/$archive_name"
    else
      tar -czf "$tmp_dir/$archive_name" -C "$backup_dir" .
    fi

    mv "$tmp_dir/$archive_name" "$backup_dir/$archive_name"
    rm -rf "$tmp_dir"

    # remove originals, leave only archive
    find "$backup_dir" -mindepth 1 -maxdepth 1 ! -name "$archive_name" -exec rm -rf {} +
    archive_count=$((archive_count + 1))

    if ! $quiet; then
      echo "[✓] Compression complete: $backup_dir/$archive_name"
    fi
  fi

  if ! $quiet; then
    echo
  fi
done

if ! $quiet; then
  echo "============================================================"
  echo "   Backup Project by Moztopia"
  echo "   Run finished: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "------------------------------------------------------------"
  echo "   Sources processed : $source_count"
  echo "   Archives created  : $archive_count"
  echo "   Destination       : $(realpath "$dest")"
  echo "============================================================"
fi
