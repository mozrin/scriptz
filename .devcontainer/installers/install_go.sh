#!/usr/bin/env bash

##### installers/install_go.sh
#
# Installs a specific Go version into /usr/local/go-<version>, makes
# /usr/local/go point to that version, and ensures the `go` and `gofmt`
# binaries are immediately available for the current and future shells.
#
# Usage:
#   ./installers/install_go.sh 1.25.4
#
# Behaviour:
# - resolves the exact downloadable tarball from the official Go release index
# - extracts into /usr/local/go-<version> and symlinks /usr/local/go -> that dir
# - creates /etc/profile.d/golang.sh to export GOROOT/GOPATH and PATH for interactive/login shells
# - creates safe symlinks in /usr/local/bin for immediate availability in non-login/non-interactive shells
# - optionally registers with update-alternatives if available (keeps system tidy)
# - preserves blank lines and header style consistent with other installers
#
# Requirements:
# - run as root (or with sudo) inside the container
# - curl, jq, tar, gzip expected present in the base image. If not, install them in your image.

set -euo pipefail

GO_VERSION="${1:?GO_VERSION is required (example: 1.25.4 or 1.25)}"
INSTALL_PREFIX="/usr/local"
TARGET_DIR="${INSTALL_PREFIX}/go-${GO_VERSION}"
SYMLINK_DIR="${INSTALL_PREFIX}/go"
PROFILE_D="/etc/profile.d/golang.sh"
TMP_TARBALL="/tmp/go${GO_VERSION}.linux-amd64.tar.gz"

echo "[devlite] Installing Go ${GO_VERSION} ..."

# NOTE: curl, jq, tar, gzip are expected to exist in the base image.
# If your base image lacks them, install them in the image (not here).

# ensure a minimal C build toolchain for cgo/native modules
if ! command -v gcc >/dev/null 2>&1 || ! command -v make >/dev/null 2>&1; then
  echo
  echo "[devlite] Installing minimal C toolchain (build-essential) ..."
  echo
  apt-get update
  apt-get install -y --no-install-recommends build-essential
fi

echo
echo "[devlite] Resolving download URL for Go ${GO_VERSION} using the official release index ..."
echo

RELEASE_JSON="$(mktemp)"
trap 'rm -f "${RELEASE_JSON}"' EXIT

curl -fsSL 'https://go.dev/dl/?mode=json' -o "${RELEASE_JSON}"

# Pick the exact release or the highest patch matching the requested major.minor
SELECTED_VERSION="$(jq -r --arg prefix "go${GO_VERSION}" '
  [ .[] | select(.version == $prefix or (.version | startswith($prefix + "."))) ]
  | sort_by(.version)
  | last
  | .version
  ' "${RELEASE_JSON}")"

if [[ -z "${SELECTED_VERSION}" || "${SELECTED_VERSION}" == "null" ]]; then
  echo "[devlite] Could not find any releases matching go${GO_VERSION} in the official index." >&2
  echo "[devlite] Available recent releases (top 15):"
  jq -r '.[].version' "${RELEASE_JSON}" | head -n15 | sed 's/^/  /'
  exit 1
fi

FILENAME="$(jq -r --arg ver "${SELECTED_VERSION}" '
  .[] | select(.version == $ver) | .files[] | select(.os=="linux" and .arch=="amd64") | .filename
  ' "${RELEASE_JSON}" || true)"

JSON_URL="$(jq -r --arg ver "${SELECTED_VERSION}" '
  .[] | select(.version == $ver) | .files[] | select(.os=="linux" and .arch=="amd64") | .url
  ' "${RELEASE_JSON}" || true)"

if [[ -z "${FILENAME}" || "${FILENAME}" == "null" ]]; then
  echo "[devlite] Could not find a linux/amd64 filename for ${SELECTED_VERSION}." >&2
  jq -r --arg prefix "go${GO_VERSION}" '
    .[] | select(.version == ($prefix) or (.version | startswith($prefix + "."))) |
    .version as $v | .files[] | "\($v) \(.os)/\(.arch) \(.filename) \(.url)"
    ' "${RELEASE_JSON}" | sed 's/^/  /'
  exit 1
fi

# Build download URL from JSON url if present, otherwise from filename
if [[ -n "${JSON_URL}" && "${JSON_URL}" != "null" ]]; then
  DOWNLOAD_URL="${JSON_URL}"
else
  DOWNLOAD_URL="https://go.dev/dl/${FILENAME}"
fi

if [[ "${DOWNLOAD_URL}" =~ ^/ ]]; then
  DOWNLOAD_URL="https://go.dev${DOWNLOAD_URL}"
fi

echo "[devlite] Resolved ${FILENAME} -> ${DOWNLOAD_URL}"
echo

rm -f "${TMP_TARBALL}"
curl -fsSL "${DOWNLOAD_URL}" -o "${TMP_TARBALL}" || {
  echo "[devlite] Download failed (curl exit ${?}). URL: ${DOWNLOAD_URL}" >&2
  exit 1
}

echo
echo "[devlite] Extracting tarball ..."
echo

rm -rf /tmp/go
tar -C /tmp -xzf "${TMP_TARBALL}"

if [ ! -d "/tmp/go" ]; then
  echo "[devlite] Unexpected archive layout; /tmp/go not found" >&2
  exit 1
fi

if [ -d "${TARGET_DIR}" ]; then
  echo
  echo "[devlite] Target ${TARGET_DIR} already exists; replacing with new extract"
  echo
  rm -rf "${TARGET_DIR}"
fi

mv /tmp/go "${TARGET_DIR}"

# Update /usr/local/go symlink
if [ -L "${SYMLINK_DIR}" ] || [ -d "${SYMLINK_DIR}" ]; then
  rm -rf "${SYMLINK_DIR}"
fi

ln -s "${TARGET_DIR}" "${SYMLINK_DIR}"

# Create profile snippet for interactive/login shells
cat > "${PROFILE_D}" <<'EOF'
# Go environment for devcontainer (managed by installers/install_go.sh)
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOROOT/bin:$GOPATH/bin:$PATH
EOF

chmod 0644 "${PROFILE_D}"

# Ensure immediate availability: create (or update) symlinks in /usr/local/bin
# This makes `go` and `gofmt` available without requiring shell re-login.
if [ -x "${SYMLINK_DIR}/bin/go" ]; then
  ln -sf "${SYMLINK_DIR}/bin/go" /usr/local/bin/go
fi

if [ -x "${SYMLINK_DIR}/bin/gofmt" ]; then
  ln -sf "${SYMLINK_DIR}/bin/gofmt" /usr/local/bin/gofmt
fi

# Optionally register with update-alternatives if present (keeps system clean)
if command -v update-alternatives >/dev/null 2>&1 && [ -x "${SYMLINK_DIR}/bin/go" ]; then
  update-alternatives --install /usr/bin/go go "${SYMLINK_DIR}/bin/go" 200 \
    --slave /usr/bin/gofmt gofmt "${SYMLINK_DIR}/bin/gofmt" || true
  # Do not forcibly set; leave selection to admin, but if no alternative exists, make this one current
  if ! update-alternatives --query go >/dev/null 2>&1; then
    update-alternatives --set go "${SYMLINK_DIR}/bin/go" || true
  fi
fi

# Cleanup
rm -f "${TMP_TARBALL}"

apt-get -yq autoremove || true
apt-get -yq clean || true
rm -rf /var/lib/apt/lists/* || true

echo
echo "[devlite] Go ${SELECTED_VERSION} installed to ${TARGET_DIR}"
echo "[devlite] Symlink ${SYMLINK_DIR} -> ${TARGET_DIR}"
echo

# verify
if command -v go >/dev/null 2>&1; then
  go version || true
else
  echo "[devlite] go binary not found on PATH. You can `export PATH=/usr/local/go/bin:\$PATH` or reopen your shell." >&2
fi