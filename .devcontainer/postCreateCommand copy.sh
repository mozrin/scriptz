#!/bin/bash

##### postCreateCommand.sh
#
# Do you need to do something after your container has been created? Install some 
# ancillary utilities? 
#
# set -eux
# export postCreateCommand=true

##### User Modifiable Options

export NODEJS_INSTALLATION=false
export NODEJS_VERSION=24

export PYTHON_INSTALLATION=false
export PYTHON_VERSION=3.12

export PHP_INSTALLATION=false
export PHP_VERSION=8.3

export C_INSTALLATION=false
export C_VERSION=gcc

export CXX_INSTALLATION=true
export CXX_VERSION=g++

export GO_INSTALLATION=true
export GO_VERSION=1.23

export RUST_INSTALLATION=false
export RUST_VERSION=stable

export PASCAL_INSTALLATION=false
export PASCAL_VERSION=fpc

export BASIC_INSTALLATION=false
export BASIC_VERSION=fbc

# Resolve repo root relative to this script, regardless of caller CWD
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

##### Install OS Package Updates

echo "[devlite] Updating Installer Packages ..."
apt update

##### Install Utilities

echo "[devlite ] Installing System Utilities ..."

apt install -y \
    iputils-ping \
    gawk

if [ "${PYTHON_INSTALLATION}" = "true" ]; then
  # Prefer 'source' for readability; '.' is equivalent
  # shellcheck source=installers/install_python.sh
  source "${SCRIPT_DIR}/installers/install_python.sh" "${PYTHON_VERSION}"
  echo "Python installation complete."
fi

##### Conditional PHP Installation

if [ "$PHP_INSTALLATION" = "true" ]; then
    echo "Installing PHP $PHP_VERSION and Composer..."

    apt install -y \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-sqlite3 \
        php${PHP_VERSION}-mysql \
        php${PHP_VERSION}-redis \
        php${PHP_VERSION}-memcached \
        php${PHP_VERSION}-pgsql \
        php${PHP_VERSION}-pdo-pgsql \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-zip \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-intl \
        php${PHP_VERSION}-tokenizer \
        php${PHP_VERSION}-pdo \
        php${PHP_VERSION}-xdebug \
        php${PHP_VERSION}-gd

    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php composer-setup.php
    php -r "unlink('composer-setup.php');"
    mv composer.phar /usr/local/bin/composer
else
    echo "PHP installation skipped."
fi

##### Conditional Node.js Installation

if [ "$NODEJS_INSTALLATION" = "true" ]; then
    echo "Installing Node.js $NODEJS_VERSION ..."

    curl -fsSL "https://deb.nodesource.com/setup_${NODEJS_VERSION}.x" | sudo -E bash -
    sudo apt-get install -y nodejs
else
    echo "Node.js installation skipped."
fi

##### Conditional C Installation

if [ "$C_INSTALLATION" = "true" ]; then
    echo "Installing C compiler ($C_VERSION) ..."

    apt-get update
    apt-get install -y \
        ${C_VERSION} \
        make

    echo "C installation complete."
    ${C_VERSION} --version
else
    echo "C installation skipped."
fi

##### Conditional C++ Installation

if [ "$CXX_INSTALLATION" = "true" ]; then
    echo "Installing C++ compiler ($CXX_VERSION) ..."

    apt-get update
    apt-get install -y \
        ${CXX_VERSION} \
        make

    echo "C++ installation complete."
    ${CXX_VERSION} --version
else
    echo "C++ installation skipped."
fi

##### Conditional Go Installation

if [ "$GO_INSTALLATION" = "true" ]; then
    echo "Installing Go $GO_VERSION ..."

    apt-get update
    apt-get install -y golang-go

    echo "Go installation complete."
    go version
else
    echo "Go installation skipped."
fi

##### Conditional Rust Installation

if [ "$RUST_INSTALLATION" = "true" ]; then
    echo "Installing Rust ($RUST_VERSION) ..."

    apt-get update
    apt-get install -y curl build-essential
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain ${RUST_VERSION}
    export PATH="$HOME/.cargo/bin:$PATH"

    echo "Rust installation complete."
    rustc --version
    cargo --version
else
    echo "Rust installation skipped."
fi

##### Conditional Pascal Installation

if [ "$PASCAL_INSTALLATION" = "true" ]; then
    echo "Installing Pascal compiler ($PASCAL_VERSION) ..."

    apt-get update
    apt-get install -y ${PASCAL_VERSION}

    echo "Pascal installation complete."
    ${PASCAL_VERSION} -iV
else
    echo "Pascal installation skipped."
fi

##### Conditional BASIC Installation

if [ "$BASIC_INSTALLATION" = "true" ]; then
    . ./installers/install_basic.sh "$BASIC_VERSION"
    echo "BASIC installation complete."
fi

##### Add your changes below here. 


