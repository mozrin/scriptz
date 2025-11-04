#!/bin/bash

# uninstall.sh — Uninstaller for Moztopia scripts
# by Moztopia
# version 0.0.2

set -e

HOME_DIR="$HOME"
if [[ "$1" == "--test" ]]; then
  REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
  HOME_DIR="$REPO_DIR/test"
  shift
  echo "[TEST MODE] Using HOME=$HOME_DIR"
fi

INSTALL_DIR="$HOME_DIR/.local/moztopia-scripts"
BIN_DIR="$HOME_DIR/.local/bin"
MANIFEST="$INSTALL_DIR/install.log"

echo "Moztopia Uninstaller"
echo "Install dir: $INSTALL_DIR"
echo "Bin dir: $BIN_DIR"
echo "Manifest: $MANIFEST"
echo

if [ ! -f "$MANIFEST" ]; then
  echo "No manifest found. Nothing to uninstall."
  exit 0
fi

while IFS= read -r line; do
  case "$line" in
    *"->"*)
      target="$(echo "$line" | awk '{print $1}')"
      link="$(echo "$line" | awk '{print $3}')"

      if [ -L "$link" ]; then
        rm -f "$link"
        echo "Removed symlink: $link"
      fi

      if [ -f "$target" ]; then
        rm -f "$target"
        echo "Removed file: $target"
      fi
      ;;
  esac
done < "$MANIFEST"

rm -f "$MANIFEST"
echo "Removed manifest."

if [ -d "$INSTALL_DIR" ]; then
  rm -rf "$INSTALL_DIR"
  echo "Removed install dir: $INSTALL_DIR"
fi

echo
echo "Uninstall complete."
