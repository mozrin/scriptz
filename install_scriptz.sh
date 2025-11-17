#!/usr/bin/env bash
#
# install_scriptz.sh - installer for Moztopia scriptz
#
# Usage:
#   ./install_scriptz.sh [--install-folder=/path] [--version=<tag|branch>] [--dry-run]
#

set -euo pipefail

INSTALL_FOLDER="/usr/local"
DRYRUN=false
VERSION=""
REPO_OWNER="mozrin"
REPO_NAME="scriptz"

# Parse options
for arg in "$@"; do
  case "$arg" in
    --install-folder=*) INSTALL_FOLDER="${arg#*=}" ;;
    --version=*)        VERSION="${arg#*=}" ;;
    --dry-run)          DRYRUN=true ;;
    --help)
      echo "Usage: ./install_scriptz.sh [--install-folder=/path] [--version=<tag|branch>] [--dry-run]"
      exit 0
      ;;
    *) echo "[install] Unknown option: $arg"; exit 1 ;;
  esac
done

BIN_DIR="$INSTALL_FOLDER/bin"

# Determine version and tarball URL
if [[ -z "$VERSION" ]]; then
  echo "[install] No version specified, fetching latest release..."
  VERSION="$(curl -s https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest \
             | grep -Po '"tag_name": "\K.*?(?=")' || echo unknown)"
  REPO_URL="https://github.com/$REPO_OWNER/$REPO_NAME/archive/refs/tags/$VERSION.tar.gz"
else
  echo "[install] Using specified version: $VERSION"
  if [[ "$VERSION" =~ ^v[0-9] ]]; then
    REPO_URL="https://github.com/$REPO_OWNER/$REPO_NAME/archive/refs/tags/$VERSION.tar.gz"
  else
    REPO_URL="https://github.com/$REPO_OWNER/$REPO_NAME/archive/refs/heads/$VERSION.tar.gz"
  fi
fi

# Validate tarball URL
if ! curl -s --head "$REPO_URL" | grep "200 OK" >/dev/null; then
  echo "[install] ERROR: Version '$VERSION' not found in repo."
  exit 1
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
    cp "src/scripts/scriptz/scriptz.sh" "$SCRIPTZ_DIR/"
    [[ -f "README.md" ]] && cp "README.md" "$LIB_DIR/"
  fi
else
  echo "[install] src/ not found locally, fetching from $REPO_URL..."
  tmpdir="$(mktemp -d)"
  curl -L "$REPO_URL" -o "$tmpdir/repo.tar.gz"
  if ! $DRYRUN; then
    tar -xzf "$tmpdir/repo.tar.gz" -C "$tmpdir" --wildcards --strip-components=2 "*/src/*"
    cp -r "$tmpdir/src/"* "$SCRIPTS_DIR/"
    curl -L "https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$VERSION/src/scripts/scriptz/scriptz.sh" -o "$SCRIPTZ_DIR/scriptz.sh"
    curl -L "https://raw.githubusercontent.com/$REPO_OWNER/$REPO_NAME/$VERSION/README.md" -o "$LIB_DIR/README.md"
  fi
  rm -rf "$tmpdir"
  echo "[install] src/ fetched and installed"
fi

# Symlink scriptz to the installed version (always overwrite)
TARGET="$BIN_DIR/scriptz"
SOURCE="$SCRIPTZ_DIR/scriptz.sh"

if ! $DRYRUN; then
  ln -sf "$SOURCE" "$TARGET"
  chmod +x "$SOURCE"
fi
echo "[install] Linked $TARGET → $SOURCE"

echo "[install] Installed version: $VERSION"
echo "[install] Done."
