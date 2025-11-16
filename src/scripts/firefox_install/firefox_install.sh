#!/usr/bin/env bash
#
# firefox_install.sh - Install Firefox on Ubuntu without Snap
#

set -euo pipefail

# Require sudo/root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run with sudo or as root."
    echo "Usage: sudo $0 [options]"
    exit 1
fi

# Default settings
REMOVE=true
CLEANUP=true
DESTINATION="/opt/firefox"
QUIET=false
LOG=true
LOGFILE="/var/log/firefox_install.log"
YES=false
LANG="en-US"
OS="linux64"

show_help() {
    cat <<EOF
Usage: $0 [options]

Options:
  --help           Show this help message and exit
  --no-remove      Do not remove old Firefox remnants
  --no-cleanup     Do not clean up temporary files after install
  --destination    Set installation directory (default: /opt/firefox)
  --quiet          Suppress interactive prompts and progress output
  --no-log         Do not write a log file
  --logfile PATH   Set custom log file path (default: /var/log/firefox_install.log)
  --yes            Automatically confirm installation plan (skip y/N prompt)
  --lang CODE      Language code (default: en-US)
  --os TYPE        OS type (default: linux64)

This script:
  * Downloads the latest Firefox tarball directly from Mozilla
  * Removes old remnants unless --no-remove
  * Installs Firefox into /opt/firefox (or --destination)
  * Creates a symlink in /usr/local/bin/firefox
  * Adds a desktop entry for system menus
  * Writes a detailed log unless --no-log
EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help) show_help; exit 0 ;;
        --no-remove) REMOVE=false ;;
        --no-cleanup) CLEANUP=false ;;
        --destination) DESTINATION="$2"; shift ;;
        --quiet) QUIET=true ;;
        --no-log) LOG=false ;;
        --logfile) LOGFILE="$2"; shift ;;
        --yes) YES=true ;;
        --lang) LANG="$2"; shift ;;
        --os) OS="$2"; shift ;;
        *) echo "Unknown option: $1"; show_help; exit 1 ;;
    esac
    shift
done

# Logging setup
if $LOG; then
    mkdir -p "$(dirname "$LOGFILE")"
    echo "--- Firefox Install Log ---" > "$LOGFILE"
    exec > >(tee -a "$LOGFILE") 2>&1
fi

# Outline plan
if ! $QUIET; then
    echo "Firefox Installation Plan:"
    echo "  Remove old remnants: $REMOVE"
    echo "  Cleanup temporary files: $CLEANUP"
    echo "  Destination directory: $DESTINATION"
    echo "  Quiet mode: $QUIET"
    echo "  Logging enabled: $LOG"
    echo "  Log file: $LOGFILE"
    echo "  Auto-confirm (--yes): $YES"
    echo "  Language: $LANG"
    echo "  OS type: $OS"
    echo
    if ! $YES; then
        read -rp "Proceed with installation? [y/N] " CONFIRM
        [[ "$CONFIRM" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 1; }
    fi
fi

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Remove old remnants
if $REMOVE; then
    echo "Removing old Firefox remnants..."
    apt-get purge -y firefox || true
    rm -rf ~/.mozilla
    rm -rf "$DESTINATION"
fi

# Download latest Firefox tarball using Mozilla redirector
echo "Downloading latest Firefox..."
URL="https://download.mozilla.org/?product=firefox-latest-ssl&os=$OS&lang=$LANG"
wget -O "$TMPDIR/firefox.tar.xz" "$URL"

# Validate download
echo "Validating download..."
if ! tar -tf "$TMPDIR/firefox.tar.xz" >/dev/null 2>&1; then
    echo "Error: Downloaded file is not a valid tar.xz archive."
    exit 1
fi

# Extract
echo "Extracting..."
tar -xJf "$TMPDIR/firefox.tar.xz" -C "$TMPDIR"

# Install
echo "Installing to $DESTINATION..."
mkdir -p "$DESTINATION"
rm -rf "$DESTINATION"/*
mv "$TMPDIR/firefox"/* "$DESTINATION"

# Symlink
echo "Creating symlink..."
ln -sf "$DESTINATION/firefox" /usr/local/bin/firefox

# Desktop entry
echo "Creating desktop entry..."
tee /usr/share/applications/firefox.desktop >/dev/null <<EOF
[Desktop Entry]
Name=Firefox
Exec=$DESTINATION/firefox %u
Icon=$DESTINATION/browser/chrome/icons/default/default128.png
Type=Application
Categories=Network;WebBrowser;
EOF

# Cleanup
if $CLEANUP; then
    echo "Cleaning up..."
    rm -rf "$TMPDIR"
fi

echo "Firefox installation complete!"

