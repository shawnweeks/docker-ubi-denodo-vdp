#!/bin/bash
set -e
umask 0027

# Import functions
. ./entrypoint_common.sh

# Copy baseline configuration files if they don't exists.
cp -n -R ${HOME}/conf_original/* ${HOME}/conf/

# Call master configuration script
configure

trap "shutdown" INT TERM

# Clear Denodo variables to prevent leakage
unset "${!DENODO_@}"

# Let's go
startup
