#!/usr/bin/env bash

##### installers/install_perl.sh
#
# Installs Perl into the container.
#
# Usage:
#   ./installers/install_perl.sh <version>
#
# Where <version> can be:
#   - the literal word "default" to install the distro perl package
#   - a perl release like 5.36.0 to install via perlbrew into /opt/perlbrew
#
# Behaviour:
# - when "default" is requested, installs the distro perl and common build deps
# - when a specific version is requested, installs perlbrew into /opt/perlbrew,
#   builds the requested perl, and exposes it under /opt/perlbrew/perls/perl-<ver>
# - leaves stdout readable for debugging and preserves blank lines and header style
# - performs minimal cleanup to reduce image size
#
# Requirements:
# - run as root (or use sudo) inside the container

set -euo pipefail

PERL_VERSION="${1:?PERL_VERSION is required (example: default or 5.36.0)}"
PERLBREW_ROOT="/opt/perlbrew"
PERLBREW_BIN="${PERLBREW_ROOT}/bin/perlbrew"
TARGET_SYMLINK="/usr/local/perl-${PERL_VERSION}"

echo "[devlite] Installing Perl ${PERL_VERSION} ..."

apt-get update

if [[ "${PERL_VERSION}" = "default" ]]; then

  apt-get install -y --no-install-recommends \
    perl \
    perl-modules-5.* \
    build-essential \
    ca-certificates \
    wget \
    curl

  echo
  echo "[devlite] Installed distro perl and build-essential."

else

  # Ensure build deps for compiling Perl from source
  apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    wget \
    curl \
    libssl-dev \
    libbz2-dev \
    libz-dev \
    libncurses5-dev \
    libreadline-dev \
    libsqlite3-dev \
    xz-utils \
    libffi-dev \
    libgdbm-dev \
    libdb-dev

  echo
  echo "[devlite] Installing perlbrew into ${PERLBREW_ROOT} ..."
  echo

  # Create perlbrew root and install perlbrew script
  mkdir -p "${PERLBREW_ROOT}"
  curl -fsSL https://install.perlbrew.pl -o /tmp/install_perlbrew.pl
  PERLBREW_INSTALL_PERLROOT=1 \
    perl /tmp/install_perlbrew.pl --noprompt --destdir="${PERLBREW_ROOT}"

  rm -f /tmp/install_perlbrew.pl

  # Ensure perlbrew bin is available in this script
  export PERLBREW_ROOT
  export PERLBREW_HOME="${PERLBREW_ROOT}"
  export PATH="${PERLBREW_ROOT}/bin:${PATH}"

  if [[ ! -x "${PERLBREW_BIN}" ]]; then
    echo "[devlite] perlbrew not found at ${PERLBREW_BIN}" >&2
    exit 1
  fi

  echo
  echo "[devlite] Using perlbrew to install perl-${PERL_VERSION} (this may take a few minutes) ..."
  echo

  # Install the requested perl release (use -j to parallelize if make supports it)
  "${PERLBREW_BIN}" --notest install "perl-${PERL_VERSION}"

  # Create a readable symlink at /usr/local/perl-<ver> pointing to perlbrew's perl
  if [[ -d "${PERLBREW_ROOT}/perls/perl-${PERL_VERSION}" ]]; then
    rm -rf "${TARGET_SYMLINK}" || true
    ln -s "${PERLBREW_ROOT}/perls/perl-${PERL_VERSION}" "${TARGET_SYMLINK}"
  else
    echo "[devlite] perlbrew did not produce expected directory: ${PERLBREW_ROOT}/perls/perl-${PERL_VERSION}" >&2
    exit 1
  fi

  # Expose a profile snippet so interactive shells pick up this perl by default
  cat > /etc/profile.d/perlbrew.sh <<'EOF'
# Perl environment for devcontainer (managed by installers/install_perl.sh)
export PERLBREW_ROOT=/opt/perlbrew
export PERLBREW_HOME=/opt/perlbrew
export PATH=/opt/perlbrew/perls/default/bin:/opt/perlbrew/bin:$PATH
EOF
  chmod 0644 /etc/profile.d/perlbrew.sh

  echo
  echo "[devlite] perl-${PERL_VERSION} installed via perlbrew and symlinked to ${TARGET_SYMLINK}."
fi

# Cleanup package manager caches to reduce image size
apt-get -yq autoremove
apt-get -yq clean
rm -rf /var/lib/apt/lists/*

echo
echo "[devlite] Perl installation complete."

# verification
if [[ "${PERL_VERSION}" = "default" ]]; then
  command -v perl >/dev/null 2>&1 && perl --version || true
else
  if [[ -x "${TARGET_SYMLINK}/bin/perl" ]]; then
    "${TARGET_SYMLINK}/bin/perl" --version || true
  else
    echo "[devlite] perl binary not found at ${TARGET_SYMLINK}/bin/perl" >&2
  fi
fi
