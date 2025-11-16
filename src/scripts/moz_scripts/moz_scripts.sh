#!/usr/bin/env bash
#
# moz_scripts.sh - List function directories in ~/Code/scriptz/src/scripts
#

TARGET_DIR="$HOME/Code/scriptz/src/scripts"

# Ensure target exists
if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: $TARGET_DIR does not exist."
    exit 1
fi

echo "Moztopia Scriptz"
echo "--------------------------------------------------------------------"

# Find directories only, strip path, sort alphabetically
DIRS=$(find "$TARGET_DIR" -mindepth 1 -maxdepth 1 -type d -printf "%f\n" | sort)

# Print in wide table format (like `ls` with columns)
if command -v column >/dev/null 2>&1; then
    echo "$DIRS" | column
else
    # Fallback: simple space-separated output
    echo "$DIRS"
fi

