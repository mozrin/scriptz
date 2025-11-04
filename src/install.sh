#!/bin/bash

# install.sh — Installer for Moztopia scripts
# by Moztopia
# version 0.0.5

set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$REPO_DIR/scripts"

HOME_DIR="$HOME"
if [[ "$1" == "--test" ]]; then
  HOME_DIR="$REPO_DIR/test"
  shift
  echo "[TEST MODE] Using HOME=$HOME_DIR"
fi

INSTALL_DIR="$HOME_DIR/.local/moztopia-scripts"
BIN_DIR="$HOME_DIR/.local/bin"
MANIFEST="$INSTALL_DIR/install.log"

mkdir -p "$INSTALL_DIR" "$BIN_DIR"

echo "Moztopia Installer"
echo "Source: $SRC_DIR"
echo "Install dir: $INSTALL_DIR"
echo "Bin dir: $BIN_DIR"
echo "Manifest: $MANIFEST"
echo

date > "$MANIFEST"

find "$SRC_DIR" -type f -name "*.sh" ! -name "test*" ! -iname "readme*" | while read -r f; do
  name="$(basename "$f")"
  base="${name%.sh}"
  target="$INSTALL_DIR/$name"
  link="$BIN_DIR/$base"

  cp "$f" "$target"
  chmod +x "$target"
  ln -sf "$target" "$link"
  chmod +x "$link" 2>/dev/null || true

  echo "Installed: $base"
  echo "$target -> $link" >> "$MANIFEST"
done

echo
echo "Installation complete."
