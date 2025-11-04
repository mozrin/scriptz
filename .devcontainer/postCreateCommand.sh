#!/bin/bash

##### postCreateCommand.sh
#
# Do you need to do something after your container has been created? Install some 
# ancillary utilities? 
#
# set -eux
# export postCreateCommand=true

##### Install OS Package Updates

apt update

##### Install Utilities

apt install -y \
    iputils-ping \
    gawk \
    g++ \
    make

##### Install C Database Client Libraries

apt install -y \
    libsqlite3-dev \
    libmariadb-dev \
    libpq-dev

##### Conditional PHP Installation

export PHP_INSTALLATION=false
export PHP_VERSION=8.3

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

##### Add your changes below here. 
