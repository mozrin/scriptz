#!/bin/bash

##### install_basic.sh
#
# Installer script for BASIC (FreeBASIC) compiler
# Called from postCreateCommand.sh when BASIC_INSTALLATION=true
#
# set -eux

BASIC_VERSION=$1

apt-get update
apt-get install -y "${BASIC_VERSION}"

echo "Verifying BASIC installation ..."
"${BASIC_VERSION}" --version

echo "Pausing 5 seconds"
sleep 5
