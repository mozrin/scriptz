#!/usr/bin/env bash

##### installers/install_node.sh
#
# Installs Node.js into the container (system-wide) or installs nvm for per-user management.
#
# Usage:
#   ./installers/install_node.sh node <version>
#   ./installers/install_node.sh nvm <version|default>
#
# Examples:
#   ./installers/install_node.sh node 18    # install Node.js 18.x via NodeSource (system-wide)
#   ./installers/install_node.sh nvm 20.5.1  # install nvm and Node 20.5.1 for current user
#
# Behaviour:
# - default action 'node' uses NodeSource setup to install major versions (18,20,...)
# - 'nvm' installs nvm into /usr/local/nvm and a specified node version for the invoking user
# - keeps verbose, readable output for debugging and cleans apt lists where appropriate
#
# Requirements:
# - run as root for 'node' mode; for 'nvm' run as the target non-root user so nvm files are placed in their home
# - curl and ca-certificates expected present in base image. If not present, install them in image.

set -euo pipefail

MODE="${1:-node}"       # node | nvm
VERSION="${2:-lts}"     # for 'node' this is major (e.g., 18 or 20); for nvm it's exact (e.g., 20.5.1) or 'lts'
NVM_DIR="${NVM_DIR:-/usr/local/nvm}"
PROFILE_SNIPPET="/etc/profile.d/nodejs.sh"

echo "[devlite] install_node.sh mode=${MODE} version=${VERSION}"

if [[ "${MODE}" == "node" ]]; then

  if [[ -z "${VERSION}" ]]; then
    echo "[devlite] Version required for node mode (example: 18 or 20)" >&2
    exit 1
  fi

  echo "[devlite] Installing Node.js ${VERSION}.x via NodeSource (system-wide) ..."
  apt-get update

  apt-get install -y --no-install-recommends ca-certificates curl gnupg

  # NodeSource official setup script for major versions
  # Note: this script adds the NodeSource repo and installs nodejs package
  curl -fsSL "https://deb.nodesource.com/setup_${VERSION}.x" -o /tmp/nodesource_setup.sh
  bash /tmp/nodesource_setup.sh
  rm -f /tmp/nodesource_setup.sh

  apt-get install -y --no-install-recommends nodejs

  # Optional: install build tools for native modules
  if ! command -v gcc >/dev/null 2>&1 || ! command -v make >/dev/null 2>&1; then
    echo "[devlite] Installing build-essential for native modules ..."
    apt-get update
    apt-get install -y --no-install-recommends build-essential
  fi

  # Create profile snippet to ensure PATH consistency for interactive shells
  cat > "${PROFILE_SNIPPET}" <<'EOF'
# Node.js devcontainer path (managed by installers/install_node.sh)
export PATH=/usr/bin:$PATH
EOF
  chmod 0644 "${PROFILE_SNIPPET}"

  # Cleanup apt lists
  apt-get -yq autoremove || true
  apt-get -yq clean || true
  rm -rf /var/lib/apt/lists/* || true

  echo
  echo "[devlite] Node.js installed system-wide:"
  node --version || true
  npm --version || true
  exit 0
fi

if [[ "${MODE}" == "nvm" ]]; then

  # nvm is per-user; prefer that the script is run as the target user.
  # If running as root, NVM will be installed into /usr/local/nvm and a system-wide profile snippet created.
  echo "[devlite] Installing nvm into ${NVM_DIR} ..."
  mkdir -p "${NVM_DIR}"
  export NVM_DIR="${NVM_DIR}"

  # Install nvm (git clone of the repo)
  if [ ! -d "${NVM_DIR}/.git" ]; then
    apt-get update
    apt-get install -y --no-install-recommends ca-certificates curl git
    rm -rf "${NVM_DIR}"
    git clone https://github.com/nvm-sh/nvm.git "${NVM_DIR}"
    cd "${NVM_DIR}"
    # checkout stable release tag
    git fetch --tags --quiet
    LATEST_TAG="$(git describe --abbrev=0 --tags)"
    git checkout "${LATEST_TAG}"
  fi

  # Create profile snippet so interactive shells source nvm
  cat > "${PROFILE_SNIPPET}" <<'EOF'
# nvm (installed by installers/install_node.sh)
export NVM_DIR="${NVM_DIR}"
[ -s "${NVM_DIR}/nvm.sh" ] && \. "${NVM_DIR}/nvm.sh"
EOF
  chmod 0644 "${PROFILE_SNIPPET}"

  # Make nvm available in this script execution
  # shellcheck source=/dev/null
  if [ -s "${NVM_DIR}/nvm.sh" ]; then
    . "${NVM_DIR}/nvm.sh"
  else
    echo "[devlite] nvm.sh not found at ${NVM_DIR}/nvm.sh" >&2
    exit 1
  fi

  # Install requested node version
  if [[ "${VERSION}" == "lts" || -z "${VERSION}" ]]; then
    echo "[devlite] Installing latest LTS Node.js via nvm ..."
    nvm install --lts
    nvm alias default 'lts/*'
  else
    echo "[devlite] Installing Node.js ${VERSION} via nvm ..."
    nvm install "${VERSION}"
    nvm alias default "${VERSION}"
  fi

  echo
  echo "[devlite] nvm and Node.js installation complete."
  echo "[devlite] To use nvm in your current shell, run:"
  echo "  export NVM_DIR=\"${NVM_DIR}\" && . \"${NVM_DIR}/nvm.sh\""
  echo "Then: node --version && npm --version"
  exit 0
fi

echo "[devlite] Unknown mode: ${MODE}. Valid modes: node | nvm" >&2
exit 1
