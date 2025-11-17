#!/usr/bin/env bash
#
# install_scriptz.sh - installer for Moztopia scriptz
#
# Usage:
#   ./install_scriptz.sh [--install-folder=/path] [--dry-run] [--force]
#

set -euo pipefail

INSTALL_FOLDER="/usr/local"
DRYRUN=false
FORCE=false
REPO_URL="https://github.com/moztopia/scripts/archive/refs/heads/main.tar.gz"

# Parse options
for arg in "$@"; do
  case "$arg" in
    --install-folder=*) INSTALL_FOLDER="${arg#*=}" ;;
    --dry-run) DRYRUN=true ;;
    --force)   FORCE=true ;;
    --help)
      echo "Usage: ./install_scriptz.sh [--install-folder=/path] [--dry-run] [--force]"
      exit 0
      ;;
    *) echo "[install] Unknown option: $arg"; exit 1 ;;
  esac
done

BIN_DIR="$INSTALL_FOLDER/bin"

# Determine version
if [[ -d .git ]]; then
  VERSION="$(git describe --tags --abbrev=0 2>/dev/null \
            || git rev-parse --short HEAD 2>/dev/null \
            || echo unknown)"
else
  VERSION="unknown"
fi

LIB_DIR="$INSTALL_FOLDER/lib/scriptz-$VERSION"
SCRIPTS_DIR="$LIB_DIR/scripts"
SCRIPTZ_DIR="$SCRIPTS_DIR/scriptz"

echo "[install] Target bin: $BIN_DIR"
echo "[install] Target lib: $LIB_DIR"

# Check write access
if [[ ! -w "$INSTALL_FOLDER" ]]; then
  echo "[install] ERROR: You do not have write access to $INSTALL_FOLDER."
  echo "[install] Tip: try again with sudo, or use --install-folder=\$HOME/.local"
  exit 1
fi

# Create directories
if ! $DRYRUN; then
  mkdir -p "$BIN_DIR" "$SCRIPTZ_DIR"
fi

# Copy or fetch src folder
if [[ -d "src" ]]; then
  echo "[install] Found local src/ folder"
  if ! $DRYRUN; then
    cp -r src/* "$SCRIPTS_DIR/"
    if [[ -f "scriptz.sh" ]]; then
      cp scriptz.sh "$SCRIPTZ_DIR/"
    else
      echo "[install] ERROR: scriptz.sh not found at repo root"
      exit 1
    fi
  fi
else
  echo "[install] src/ not found locally, fetching from repo..."
  tmpdir="$(mktemp -d)"
  curl -L "$REPO_URL" -o "$tmpdir/repo.tar.gz"
  if ! $DRYRUN; then
    tar -xzf "$tmpdir/repo.tar.gz" -C "$tmpdir" --wildcards --strip-components=2 "*/src/*"
    cp -r "$tmpdir/src/"* "$SCRIPTS_DIR/"
    curl -L "https://raw.githubusercontent.com/moztopia/scripts/main/scriptz.sh" -o "$SCRIPTZ_DIR/scriptz.sh"
  fi
  rm -rf "$tmpdir"
  echo "[install] src/ fetched and installed"
fi

# Symlink scriptz to the installed version
TARGET="$BIN_DIR/scriptz"
SOURCE="$SCRIPTZ_DIR/scriptz.sh"

if [[ -e "$TARGET" && $FORCE == false ]]; then
  echo "[install] Symlink $TARGET already exists. Use --force to overwrite."
else
  if ! $DRYRUN; then
    ln -sf "$SOURCE" "$TARGET"
    chmod +x "$SOURCE"
  fi
  echo "[install] Linked $TARGET → $SOURCE"
fi

echo "[install] Installed version: $VERSION"
echo "[install] Done."
