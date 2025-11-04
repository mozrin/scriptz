#!/bin/bash

##### postStartCommand.sh
#
# set -eux
# export postStartCommand=true


#!/bin/bash

if [ -x .devcontainer/hello_devlite ]; then
    .devcontainer/hello_devlite
    exit 0
fi

exit 0

##### Add your changes below here.


