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
    gawk

##### Add your changes below here. 
