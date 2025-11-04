#!/bin/bash

# Detect OS
if [ -n "$WSL_DISTRO_NAME" ]; then
    OS_TYPE="wsl"
elif [ "$(uname -s)" = "Darwin" ]; then
    OS_TYPE="mac"
else
    exit 0 # Linux
fi

# Copy the appropriate override file
cp "docker-compose.override.${OS_TYPE}.yml" "docker-compose.override.yml"