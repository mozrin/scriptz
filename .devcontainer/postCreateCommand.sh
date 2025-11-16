#!/bin/bash

##### postCreateCommand.sh
#
# Once the workstaiton image is pulled down, we will load some basic utilities.
#
# The settings belowe are for debugging purposes.
#
# set -eux
# export postCreateCommand=true
#
# Setup Preload Installation Options
#
# You can change the true/false decides if that language is installed. The version is which
# version is installed. The name of the language must correspond to a file:
#
#    ./installers/install_<language_name>.sh
#
# You can execute any of these directly after the installation as well.

LANGUAGE_OPTIONS=(
  "python 3.12 false"
  "node 24 false"
  "php 8.3 false"
  "go 1.25.4 false"
  "node 24 false"
  "gcc 12 false"
  "gpp 12 false"
  "perl default false"
  "pascal default false"
)

# Common Installation Process for All Devlite Containers

echo "[devlite] Update the APT Libraries"
sudo apt-get -yq update

echo  "[devlite] Install Common Useful Utilities"
sudo apt-get -yq install --no-install-recommends \
  ca-certificates \
  curl \
  wget \
  git \
  gh \
  gnupg \
  lsb-release \
  apt-transport-https \
  gawk \
  software-properties-common \
  iproute2 \
  net-tools \
  file \
  unzip \
  tar \
  rsync \
  jq \
  build_essential

echo "[devlite] General Cleanup of APT and Downloaded Installation Files"
sudo apt-get -yq autoremove
sudo apt-get -yq clean
sudo rm -rf /var/lib/apt/lists/*

# Install Languages per the Array Above

for entry in "${LANGUAGE_OPTIONS[@]}"; do
  read -r name version enabled <<<"$entry"

  name_lc="${name,,}"

  if [[ "$enabled" == "true" ]]; then
    installer="./installers/install_${name_lc}.sh"

    if [[ -f "$installer" && -x "$installer" ]] || [[ -f "$installer" ]]; then
      (
        # shellcheck source=./installers/install_python.sh
        # shellcheck disable=SC1091
        source "$installer" "$version"
      )
    else
      printf '%s\n' "Installer not found: $installer" >&2
    fi
  fi
done

exit 0