#!/usr/bin/env bash

##### installers/install_gpp.sh
#
# Installs G++ (the GNU C++ compiler) into the container.
#
# Usage:
#   ./installers/install_gpp.sh <version>
#
# Where <version> can be:
#   - a numeric release like 12 or 11
#   - the literal word "default" to install the distro default toolchain (build-essential)
#
# Behaviour:
# - runs via apt and assumes root privileges
# - installs make and libc headers so common C/C++ builds work
# - when a numeric version is requested, installs g++-<ver> and gcc-<ver>
#   and registers them with update-alternatives so /usr/bin/g++ and /usr/bin/gcc
#   point to the requested version.
# - keeps blank lines and header style consistent with other installers
# - performs minimal cleanup to reduce image size

set -euo pipefail

GPP_VERSION="${1:?GPP_VERSION is required (example: 12 or default)}"

echo "[devlite] Installing G++ ${GPP_VERSION} ..."

apt-get update

if [[ "${GPP_VERSION}" = "default" ]]; then

  apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates

  echo
  echo "[devlite] Installed distro default build-essential (gcc, g++, make)."

else

  apt-get install -y --no-install-recommends \
    "g++-${GPP_VERSION}" \
    "gcc-${GPP_VERSION}" \
    make \
    libc6-dev \
    ca-certificates

  # Verify binaries exist
  if [[ ! -x "/usr/bin/g++-${GPP_VERSION}" ]] || [[ ! -x "/usr/bin/gcc-${GPP_VERSION}" ]]; then
    echo "[devlite] Requested G++/GCC version binaries not found: /usr/bin/g++-${GPP_VERSION} or /usr/bin/gcc-${GPP_VERSION}" >&2
    echo "[devlite] Check that the requested version is available in your apt sources." >&2
    exit 1
  fi

  # Register alternatives so `g++` and `gcc` point to the requested version
  update-alternatives --install /usr/bin/gcc gcc "/usr/bin/gcc-${GPP_VERSION}" 120 \
    --slave /usr/bin/g++ g++ "/usr/bin/g++-${GPP_VERSION}"

  # Set the alternatives to this version
  update-alternatives --set gcc "/usr/bin/gcc-${GPP_VERSION}"

  echo
  echo "[devlite] Installed g++-${GPP_VERSION} and gcc-${GPP_VERSION} and registered alternatives."
fi

# Cleanup to keep image small
apt-get -yq autoremove
apt-get -yq clean
rm -rf /var/lib/apt/lists/*

echo
echo "[devlite] G++ installation complete."

if command -v g++ >/dev/null 2>&1; then
  g++ --version || true
fi

if command -v gcc >/dev/null 2>&1; then
  gcc --version || true
fi
