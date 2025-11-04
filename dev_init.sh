#!/usr/bin/env bash
set -e

cd ~/roboboat_ws
colcon build --symlink-install
source /opt/ros/humble/setup.bash
source install/setup.bash
echo "[dev_init] Dev environment ready"