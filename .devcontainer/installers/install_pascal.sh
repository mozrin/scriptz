#!/usr/bin/env bash

##### installers/install_pascal.sh
#
# Minimal Pascal installer for VS Code devcontainers
#
# Usage:
#   ./installers/install_pascal.sh <package>
#
# Where <package> is expected to be:
#   default    -> produce the minimal devcontainer-friendly install (fpc + tools)
#   lazarus    -> (not recommended in devcontainer) will install Lazarus only when NOT in a devcontainer
#   anything else -> treated as "default" for compatibility (installer focuses on VS Code use)
#
# Behaviour:
# - In a devcontainer (DEVCONTAINER=true or /.devcontainer or VSCODE_*), installs fpc + minimal tools, never Lazarus.
# - Outside a devcontainer, "lazarus" will attempt to install the Lazarus package (not recommended for headless use).
# - Idempotent and uses --no-install-recommends to reduce extra GUI libs.
# - Must be run as root (or with sudo) inside the container.

set -euo pipefail

REQUEST_RAW="${1:-default}"
REQUEST="$(printf '%s' "${REQUEST_RAW}" | tr '[:upper:]' '[:lower:]')"

# Detect devcontainer reliably: explicit env, devcontainer folder, or VS Code env vars
DETECTED_DEVCONTAINER="false"
if [ "${DEVCONTAINER:-}" = "true" ] || [ -e "/.devcontainer" ] || env | grep -q '^VSCODE_' || env | grep -q '^REMOTE_' ; then
  DETECTED_DEVCONTAINER="true"
fi

echo "[devlite] install_pascal.sh called with: '${REQUEST_RAW}' (devcontainer=${DETECTED_DEVCONTAINER})"

# Decide install mode
INSTALL_LAZARUS="false"
case "${REQUEST}" in
  lazarus)
    if [ "${DETECTED_DEVCONTAINER}" = "true" ]; then
      echo "[devlite] Running inside a devcontainer: skipping Lazarus install (use VS Code integration instead)." 
      INSTALL_LAZARUS="false"
    else
      INSTALL_LAZARUS="true"
    fi
    ;;
  default|*)
    INSTALL_LAZARUS="false"
    ;;
esac

# Minimal package groups
FPC_PACKAGES="fpc fp-compiler"
MINIMAL_TOOLS="build-essential gdb pkg-config ca-certificates curl"
# No --no-install-recommends for build-essential/gdb sometimes pulls needed bits; keep conservative for tools.
LAZARUS_PACKAGES="lazarus"

# Ensure 'universe' component is enabled (idempotent)
if ! grep -E -q '^[^#]*universe' /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
  echo "[devlite] Enabling Ubuntu universe repository ..."
  apt-get update -y
  apt-get install -y --no-install-recommends software-properties-common || true
  add-apt-repository -y universe || true
fi

apt-get update -y

# Install minimal toolchain first (idempotent)
echo "[devlite] Installing minimal build tools: ${MINIMAL_TOOLS}"
apt-get install -y --no-install-recommends ${MINIMAL_TOOLS}

# Install fpc
echo "[devlite] Installing Free Pascal packages: ${FPC_PACKAGES}"
apt-get install -y --no-install-recommends ${FPC_PACKAGES}

# Install Lazarus only when explicitly requested and not inside a devcontainer
if [ "${INSTALL_LAZARUS}" = "true" ]; then
  echo "[devlite] Installing Lazarus IDE (this will pull GUI and LCL dependencies) ..."
  apt-get install -y ${LAZARUS_PACKAGES}
else
  echo "[devlite] Lazarus not requested or skipped for devcontainer usage."
fi

# Basic verification
echo
echo "[devlite] Verification:"
if command -v fpc >/dev/null 2>&1; then
  printf "  fpc: " ; fpc -iV || true
else
  echo "  fpc: not found"
fi

if command -v gdb >/dev/null 2>&1; then
  printf "  gdb: " ; gdb --version 2>/dev/null | head -n1 || true
else
  echo "  gdb: not found"
fi

if [ "${INSTALL_LAZARUS}" = "true" ]; then
  if command -v lazarus >/dev/null 2>&1; then
    printf "  lazarus: " ; lazarus --version || true
  else
    echo "  lazarus: not found (GUI may require X)"
  fi
fi

# Cleanup apt lists to keep image small
apt-get -yq autoremove || true
apt-get -yq clean || true
rm -rf /var/lib/apt/lists/* || true

cat <<'MSG'

[devlite] install_pascal.sh done.

Next steps for VS Code:
- Use a Pascal extension (syntax/highlight). Example extension id: wolfgang42.pascal or other marketplace choice.
- Recommended .vscode/tasks.json for build/run:

{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Pascal: Build current file",
      "type": "shell",
      "command": "fpc",
      "args": ["${file}"],
      "group": "build",
      "presentation": { "reveal": "always" },
      "problemMatcher": []
    },
    {
      "label": "Pascal: Run last binary",
      "type": "shell",
      "command": "${fileDirname}/${fileBasenameNoExtension}",
      "presentation": { "reveal": "always", "panel": "shared" },
      "problemMatcher": []
    }
  ]
}

- Use the built-in debugger (gdb) via a C/C++ debug configuration if you want to debug compiled Pascal binaries (setup launch.json with gdb and program path).

MSG

exit 0
