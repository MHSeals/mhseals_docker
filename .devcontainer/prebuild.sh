#!/usr/bin/env bash

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect OS
if [ -n "$WSL_DISTRO_NAME" ]; then
    OS_TYPE="wsl"
elif [ "$(uname -s)" = "Darwin" ]; then
    OS_TYPE="mac"
elif [ "$(uname -s)" = "Linux" ]; then
    OS_TYPE="linux"
else
    echo "Unsupported OS detected, exiting..."
    exit 1
fi

# Copy the appropriate override file relative to the script
cp "${SCRIPT_DIR}/docker-compose.override.${OS_TYPE}.yml" "${SCRIPT_DIR}/docker-compose.override.yml"