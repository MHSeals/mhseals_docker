#!/usr/bin/env bash
set -e

cat /sitl.bashrc >> ~/.bashrc

touch ~/.helper.txt
cat /sitl.helper.txt >> ~/.helper.txt

exec "$@"