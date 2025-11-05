#!/bin/bash

set -e
REPO="https://github.com/moztopia/scriptz.git"
TMP_DIR="$(mktemp -d)"
INSTALL_DIR="$HOME/.local/moztopia/scriptz"
BIN_DIR="$HOME/.local/bin"
MANIFEST="$INSTALL_DIR/install.log"
mkdir -p "$INSTALL_DIR" "$BIN_DIR"
LATEST_TAG="$(git ls-remote --tags "$REPO" | awk -F'/' '{print $3}' | sed 's/\^{}//' | sort -V | tail -n1)"
git clone --depth=1 --branch "$LATEST_TAG" "$REPO" "$TMP_DIR"
date > "$MANIFEST"
find "$TMP_DIR/src/scripts" -type f -name "*.sh" | while read -r f; do
name="$(basename "$f")"
base="${name%.sh}"
target="$INSTALL_DIR/$name"
link="$BIN_DIR/$base"
conflict=false
if [ -e "$target" ]; then
if grep -q "# by Moztopia" "$target"; then
rm -f "$target"
else
target="$INSTALL_DIR/moz_$name"
link="$BIN_DIR/moz_$base"
conflict=true
fi
fi
cp "$f" "$target"
chmod +x "$target"
if [ -e "$link" ]; then
if [ -f "$link" ] && grep -q "# by Moztopia" "$link"; then
rm -f "$link"
else
link="$BIN_DIR/moz_$base"
conflict=true
fi
fi
ln -sf "$target" "$link"
chmod +x "$link" 2>/dev/null || true
echo "$target -> $link" >> "$MANIFEST"
if [ "$conflict" = true ]; then
echo "Conflict: renamed $name to moz_$name" | tee -a "$MANIFEST"
fi
done
rm -rf "$TMP_DIR"
echo "Installation complete."
