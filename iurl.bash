#! /usr/bin/env bash

# A script for uploading files to Alfresco
#
# Author Dimitar Dimitrov <mitkofr@yahoo.fr>
# ------------------------------------------

shopt -s extglob

# Print a message to stderr
warn() { echo "$@" >&2; }

if (($# < 3)); then

   warn "Usage: ${0##*/} (-w|--web-script OR -s|--schema OR -l|--library) (int|test|stage|live) files"
   warn "       ${0##*/} --help: this help text"
   exit 1

elif [[ $3 == '--help' ]]; then

   echo "Usage: ${0##*/} (-w|--web-script OR -s|--schema OR -l|--library) (int|test|stage|live) files"
   echo "       ${0##*/} --help: this help text"
   exit
else

    platform=$2

        project=org
    certificate=/etc/pki/$project.pem
         prefix=${project}_

      schemas=https://.../Web%20Forms
    libraries=https://.../Web%20Forms/$project
      scripts=https://.../Web%20Scripts/$project

    local_schemas=/mnt/.../schemas
    local_scripts=/mnt/.../widgets

    # Schemas
    if [[ $1 == @(-s|--schema) ]]; then

        for arg in "${@:3}"; do

            if curl --cert "$certificate" -k -X PUT -T \
                    "$local_schemas/$prefix$arg.xsd" \
              "$schemas/$prefix$arg/$prefix$arg.xsd"
            then echo         "Uploaded the $arg schema."
            else echo "Failed to upload the $arg schema."
            fi
        done
    fi

    # Libraries
    if [[ $1 == @(-l|--library) ]]; then

        for arg in "${@:3}"; do

            if curl --cert "$certificate" -k -X PUT -T \
                    "$local_schemas/$prefix$arg.xsd" \
                        "$libraries/$prefix$arg.xsd"
            then echo         "Uploaded the $arg library."
            else echo "Failed to upload the $arg library."
            fi
        done
    fi

    # Web Scripts
    if [[ $1 == @(-w|--web-script) ]]; then

        for arg in "${@:3}"; do

            if curl --cert "$certificate" -k -X PUT -T \
                    "$local_scripts/$arg" \
                          "$scripts/$arg"
            then echo         "Uploaded the $arg script."
            else echo "Failed to upload the $arg script."
            fi
        done
    fi
fi
