#!/usr/bin/env bash

##### installers/install_gcc.sh
#
# Installs GCC into the container. Usage:
#   ./installers/install_gcc.sh <version>
#
# Where <version> can be:
#   - a numeric release like 12 or 11
#   - the literal word "default" to install the distro default (build-essential)
#
# Behaviour:
# - uses apt (assumes script runs with root privileges)
# - prefers --no-install-recommends to keep image small
# - when a numeric version is requested, installs gcc-<ver> and g++-<ver>
#   and registers them with update-alternatives so /usr/bin/gcc and /usr/bin/g++
#   point to the requested version.
# - leaves meaningful stdout for debugging
# - performs minimal cleanup to reduce image size

set -euo pipefail

GCC_VERSION="${1:?GCC_VERSION is required (example: 12 or default)}"

echo "[devlite] Installing GCC ${GCC_VERSION} ..."

apt-get update

if [[ "${GCC_VERSION}" = "default" ]]; then

  apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates

  echo
  echo "[devlite] Installed distro default build-essential (gcc, g++, make)."

else

  # Install specific gcc and g++ packages
  apt-get install -y --no-install-recommends \
    "gcc-${GCC_VERSION}" \
    "g++-${GCC_VERSION}" \
    ca-certificates

  # Verify binaries exist
  if [[ ! -x "/usr/bin/gcc-${GCC_VERSION}" ]] || [[ ! -x "/usr/bin/g++-${GCC_VERSION}" ]]; then
    echo "[devlite] Requested GCC version binaries not found: /usr/bin/gcc-${GCC_VERSION} or /usr/bin/g++-${GCC_VERSION}" >&2
    echo "[devlite] Check that the requested version is available in your apt sources." >&2
    exit 1
  fi

  # Register alternatives so `gcc` and `g++` point to the requested version
  update-alternatives --install /usr/bin/gcc gcc "/usr/bin/gcc-${GCC_VERSION}" 120 \
    --slave /usr/bin/g++ g++ "/usr/bin/g++-${GCC_VERSION}"

  # Optionally set them as the automatic choice (highest priority wins); leave as-is otherwise.
  update-alternatives --set gcc "/usr/bin/gcc-${GCC_VERSION}"

  echo
  echo "[devlite] Installed gcc-${GCC_VERSION} and g++-${GCC_VERSION} and registered alternatives."
fi

# Cleanup to keep image small
apt-get -yq autoremove
apt-get -yq clean
rm -rf /var/lib/apt/lists/*

echo
echo "[devlite] GCC installation complete."
if command -v gcc >/dev/null 2>&1; then
  gcc --version || true
fi
if command -v g++ >/dev/null 2>&1; then
  g++ --version || true
fi
