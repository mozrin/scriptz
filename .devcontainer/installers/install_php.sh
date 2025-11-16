#!/usr/bin/env bash

##### installers/install_php.sh
#
# Installs PHP and Composer into the container.
#
# Usage:
#   ./installers/install_php.sh <version> <install-flag>
#
# Where:
#   <version>     e.g. 8.3
#   <install-flag> "true" to install, anything else to skip
#
# Behaviour:
# - installs a curated set of PHP extensions required by common apps
# - uses apt with --no-install-recommends to keep image small
# - installs Composer globally at /usr/local/bin/composer and makes it executable
# - preserves blank lines and header style consistent with other installers
#
# Requirements:
# - run as root (or with sudo) inside the container
# - apt sources must provide the requested php<version> packages

set -euo pipefail

PHP_VERSION="${1:?PHP_VERSION is required (example: 8.3)}"
PHP_INSTALLATION="${2:-true}"
COMPOSER_BIN="/usr/local/bin/composer"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

if [ "${PHP_INSTALLATION}" != "true" ]; then
  echo "[devlite] PHP installation flag not set to true; skipping PHP install."
  exit 0
fi

echo "[devlite] Adding Trusted PHP Repository (Ondrej)"

sudo add-apt-repository -y ppa:ondrej/php
sudo apt-get update

echo "[devlite] Installing PHP ${PHP_VERSION} (and required packages) and Composer ..."

apt-get install -y --no-install-recommends \
  "php${PHP_VERSION}-cli" \
  "php${PHP_VERSION}-xml" \
  "php${PHP_VERSION}-sqlite3" \
  "php${PHP_VERSION}-mysql" \
  "php${PHP_VERSION}-redis" \
  "php${PHP_VERSION}-memcached" \
  "php${PHP_VERSION}-pgsql" \
  "php${PHP_VERSION}-pdo-pgsql" \
  "php${PHP_VERSION}-mbstring" \
  "php${PHP_VERSION}-curl" \
  "php${PHP_VERSION}-zip" \
  "php${PHP_VERSION}-bcmath" \
  "php${PHP_VERSION}-intl" \
  "php${PHP_VERSION}-tokenizer" \
  "php${PHP_VERSION}-pdo" \
  "php${PHP_VERSION}-xdebug" \
  "php${PHP_VERSION}-gd"

echo
echo "[devlite] Verifying PHP installation ..."
echo

if command -v "php${PHP_VERSION}" >/dev/null 2>&1; then
  "php${PHP_VERSION}" -v || true
fi

# Ensure `php` command exists and points to installed CLI where appropriate
if ! command -v php >/dev/null 2>&1; then
  if [ -x "/usr/bin/php${PHP_VERSION}" ]; then
    ln -sf "/usr/bin/php${PHP_VERSION}" /usr/bin/php
  fi
fi

echo
echo "[devlite] Installing Composer to ${COMPOSER_BIN} ..."
echo

# Download the installer and verify basic integrity where possible.
# Note: For deterministic verification you may want to fetch and check the expected installer signature.
cd "${TMP_DIR}"

# Download installer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"

# Optionally verify installer signature by checking known hashes:
# You can pass a COMPOSER_EXPECTED_HASH environment variable or leave it unset to skip.
if [ -n "${COMPOSER_EXPECTED_HASH:-}" ]; then
  ACTUAL_HASH="$(php -r "echo hash_file('SHA384', 'composer-setup.php');")"
  if [ "${ACTUAL_HASH}" != "${COMPOSER_EXPECTED_HASH}" ]; then
    echo "[devlite] Composer installer hash mismatch!" >&2
    echo "[devlite] Expected: ${COMPOSER_EXPECTED_HASH}" >&2
    echo "[devlite] Actual:   ${ACTUAL_HASH}" >&2
    rm -f composer-setup.php
    exit 1
  fi
fi

# Install composer to /usr/local/bin
php composer-setup.php --install-dir=/usr/local/bin --filename=composer

# Cleanup installer
rm -f composer-setup.php

# Ensure executable and available
chmod +x "${COMPOSER_BIN}"

echo
echo "[devlite] Composer installed:"
"${COMPOSER_BIN}" --version || true

# Cleanup apt lists to keep image small
apt-get -yq autoremove
apt-get -yq clean
rm -rf /var/lib/apt/lists/*

echo
echo "[devlite] PHP ${PHP_VERSION} and Composer installation complete."
