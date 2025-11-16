#!/bin/bash

##### postCreateCommand.sh
#
# Do you need to do something after your container has been created? Install some 
# ancillary utilities? 
#
# set -euox pipefail
# export postCreateCommand=true

set -euo pipefail

PYTHON_VERSION="${1:?PYTHON_VERSION is required}"
PYTHON_MAJOR_VERSION="${PYTHON_VERSION%%.*}"

echo "[devlite] Installing Python ${PYTHON_VERSION} ..."

apt-get update

# Add Deadsnakes repo directly with signed-by (no apt-key, no software-properties-common)
curl -fsSL https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x6A755776 \
  | gpg --dearmor -o /usr/share/keyrings/deadsnakes.gpg

echo "deb [signed-by=/usr/share/keyrings/deadsnakes.gpg] \
http://ppa.launchpad.net/deadsnakes/ppa/ubuntu jammy main" \
  > /etc/apt/sources.list.d/deadsnakes.list

apt-get update

apt-get install -y --no-install-recommends \
  "python${PYTHON_VERSION}" \
  "python${PYTHON_VERSION}-venv" \
  "python${PYTHON_VERSION}-dev" \
  python3-pip \
  build-essential \
  libssl-dev \
  libffi-dev \
  zlib1g-dev \
  libbz2-dev \
  libreadline-dev \
  libsqlite3-dev \
  wget \
  curl \
  llvm \
  libncurses5-dev \
  libncursesw5-dev \
  xz-utils \
  tk-dev

echo
echo "[devlite] Upgrading pip and installing ancillary Python utilities ..."
echo

# shellcheck disable=SC2086
python${PYTHON_MAJOR_VERSION} -m pip install --upgrade pip setuptools wheel

# shellcheck disable=SC2086
python${PYTHON_MAJOR_VERSION} -m pip install \
  virtualenv \
  pipenv \
  requests \
  numpy \
  pandas \
  black \
  flake8

echo
echo "[devlite] Python installation complete."
# shellcheck disable=SC2086
python${PYTHON_VERSION} --version
# shellcheck disable=SC2086
python${PYTHON_MAJOR_VERSION} -m pip --version
