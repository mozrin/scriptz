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

# Default to main branch if no version specified
if [[ -z "$VERSION" ]]; then
  VERSION="main"
  echo "[install] No version specified, defaulting to branch: $VERSION"
fi

# Validate against tags and branches
if curl -s "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/tags" | grep -q "\"name\": \"$VERSION\""; then
  REPO_URL="https://github.com/$REPO_OWNER/$REPO_NAME/archive/refs/tags/$VERSION.tar.gz"
elif curl -s "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/branches" | grep -q "\"name\": \"$VERSION\""; then
  REPO_URL="https://github.com/$REPO_OWNER/$REPO_NAME/archive/refs/heads/$VERSION.tar.gz"
else
  echo "[install] ERROR: Version '$VERSION' not found as tag or branch."
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
    # Extract src folder
    tar -xzf "$tmpdir/repo.tar.gz" -C "$tmpdir" --wildcards --strip-components=2 "*/src/*"
    cp -r "$tmpdir/src/"* "$SCRIPTS_DIR/"
    # Extract scriptz.sh
    tar -xzf "$tmpdir/repo.tar.gz" -C "$tmpdir" --wildcards --strip-components=2 "*/src/scripts/scriptz/scriptz.sh"
    cp "$tmpdir/src/scripts/scriptz/scriptz.sh" "$SCRIPTZ_DIR/"
    # Extract README.md from tarball root
    tar -xzf "$tmpdir/repo.tar.gz" -C "$tmpdir" --wildcards --strip-components=1 "*/README.md" || true
    [[ -f "$tmpdir/README.md" ]] && cp "$tmpdir/README.md" "$LIB_DIR/"
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

# Write version metadata
META_FILE="$LIB_DIR/VERSION.json"
if ! $DRYRUN; then
  cat > "$META_FILE" <<EOF
{
  "name": "$VERSION",
  "installed_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "source": "$REPO_URL"
}
EOF
fi

echo "[install] Installed version: $VERSION"
echo "[install] Done."

# Dump README.md to screen with Markdown formatting
README_FILE="$LIB_DIR/README.md"
if [[ -f "$README_FILE" ]]; then
  echo "[install] Displaying README.md for version $VERSION..."
  if command -v bat >/dev/null 2>&1; then
    bat --style=plain --paging=always "$README_FILE"
  elif command -v less >/dev/null 2>&1; then
    less "$README_FILE"
  else
    cat "$README_FILE"
  fi
else
  echo "[install] WARNING: README.md not found in $LIB_DIR"
fi
