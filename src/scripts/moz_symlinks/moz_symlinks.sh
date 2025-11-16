#!/usr/bin/env bash
#
# moz_symlinks.sh - Manage symlinks for Moztopia Scriptz
#

set -euo pipefail

BASE="$HOME/Code/scriptz/src/scripts"
BIN="/usr/local/bin"
SELF="$(readlink -f "$0")"

verb=""
SCRIPT_FILTER="*"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        report|add|remove) verb="$1"; shift ;;
        --script=*)
            SCRIPT_FILTER="${1#--script=}"
            SCRIPT_FILTER="${SCRIPT_FILTER%.sh}"
            shift ;;
        --help) verb="--help"; shift ;;
        *) shift ;;
    esac
done

brief_usage() {
    echo "Usage: moz_symlinks <verb> [options...]"
    echo
    echo "Verbs:"
    echo "  report   - show symlink status report"
    echo "  add      - create missing symlinks"
    echo "  remove   - remove symlinks (except itself)"
    echo
    echo "Options:"
    echo "  --script=<name|glob>   Filter by script name or pattern (e.g. chunk, net-*)"
    echo
    echo "Run 'moz_symlinks --help' for detailed information."
}

detailed_help() {
    cat <<EOF
Moztopia Scriptz Symlinks Manager
--------------------------------------------------------------------
This utility crawls the ~/Code/scriptz/src/scripts/ folder, finds all
subfolders containing .sh scripts, and manages symlinks in /usr/local/bin.

Syntax:
  moz_symlinks <verb> [options...]

Verbs:
  report   - Scans all scripts and prints a table showing:
             * Command name
             * Source script path (relative to Installation Path)
             * Symlink status (OK, MISSING, Mismatch)
  add      - Creates symlinks for any missing or mismatched scripts.
             Ensures each script is executable.
  remove   - Removes symlinks for all discovered scripts except itself.
             Useful for cleanup/reset.

Options:
  --script=<name|glob>   Filter by script name or pattern.
                         Examples:
                           --script=chunk
                           --script=chunk.sh
                           --script=net-*
  --help                 Show this detailed help page.

Examples:
  moz_symlinks report
  moz_symlinks add --script=chunk
  moz_symlinks remove --script=net-*
EOF
}

# Collect all .sh scripts
declare -A scripts
while IFS= read -r -d '' file; do
    name=$(basename "$file" .sh)
    scripts["$name"]="$file"
done < <(find "$BASE" -mindepth 2 -maxdepth 2 -type f -name "*.sh" -print0)

report() {
    echo "Moztopia Scriptz Symlinks Report"
    echo "--------------------------------------------------------------------"
    echo "Installation Path: $BASE"
    echo
    printf "%-20s %-50s %-15s\n" "Command" "Source Script" "Symlink Status"
    printf "%-20s %-50s %-15s\n" "-------" "-------------" "--------------"

    for name in $(printf "%s\n" "${!scripts[@]}" | sort); do
        [[ "$name" == $SCRIPT_FILTER ]] || continue
        src="${scripts[$name]}"
        rel="${src#$BASE/}"
        dest="$BIN/$name"

        if [[ -L "$dest" ]]; then
            target=$(readlink -f "$dest")
            if [[ "$target" == "$src" ]]; then
                status="OK"
            else
                status="Mismatch"
            fi
        else
            status="MISSING"
        fi

        printf "%-20s %-50s %-15s\n" "$name" "$rel" "$status"
    done
    echo "--------------------------------------------------------------------"
}

add() {
    for name in "${!scripts[@]}"; do
        [[ "$name" == $SCRIPT_FILTER ]] || continue
        src="${scripts[$name]}"
        dest="$BIN/$name"

        if [[ -L "$dest" && "$(readlink -f "$dest")" == "$src" ]]; then
            echo "[OK] $name already linked"
        else
            echo "[ADD] Linking $src -> $dest"
            sudo ln -sf "$src" "$dest"
            sudo chmod +x "$src"
        fi
    done
}

remove() {
    for name in "${!scripts[@]}"; do
        [[ "$name" == $SCRIPT_FILTER ]] || continue
        src="${scripts[$name]}"
        dest="$BIN/$name"

        if [[ "$src" == "$SELF" ]]; then
            echo "[SKIP] Not removing self ($name)"
            continue
        fi

        if [[ -L "$dest" ]]; then
            echo "[REMOVE] $dest"
            sudo rm -f "$dest"
        else
            echo "[OK] $name not linked"
        fi
    done
}

case "$verb" in
    "") brief_usage ;;
    --help) detailed_help ;;
    report) report ;;
    add) add ;;
    remove) remove ;;
    *) echo "Unknown verb: $verb"; brief_usage; exit 1 ;;
esac

