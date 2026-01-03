#!/usr/bin/env bash
set -e

VARIANT=${VARIANT:-garden}

if [ "${VARIANT}" = "classic" ]; then
  echo "[INFO] Installing Gazebo Classic..." 
  apt-get update && apt-get install -y \
    ros-humble-gazebo-ros-pkgs ros-humble-gazebo-ros2-control
elif [ "${VARIANT}" = "garden" ]; then
  echo "[INFO] Installing Gazebo Garden..." 

  # Get installation utilities
  apt-get update && apt-get install -y wget lsb-release gnupg
  wget https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/gazebo.gpg

  # Add Gazebo packages to source list
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/gazebo.gpg] \
  http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" \
  | tee /etc/apt/sources.list.d/gazebo-stable.list

  # Install Gazebo Garden
  apt-get update && apt-get install -y \
    libgz-cmake3-dev \
    libgz-math7-dev \
    libgz-plugin2-dev \
    libgz-common5-dev \
    libgz-msgs9-dev \
    libgz-transport12-dev \
    libgz-rendering7-dev \
    libgz-sim7-dev \
    libsdformat13-dev \
    libcgal-dev \
    libfftw3-dev

  # Add necessary environment variables
  USER_HOME="/home/${_REMOTE_USER:-vscode}"
  echo 'export GZ_SIM_RESOURCE_PATH="$HOME/roboboat_ws/src/asv_wave_sim/gz-waves-models/models:$HOME/roboboat_ws/src/asv_wave_sim/gz-waves-models/world_models:$HOME/roboboat_ws/src/asv_wave_sim/gz-waves-models/worlds"' >> "$USER_HOME/.bashrc"
  echo 'export GZ_SIM_SYSTEM_PLUGIN_PATH="$HOME/roboboat_ws/install/lib"' >> "$USER_HOME/.bashrc"
  echo 'export LD_LIBRARY_PATH="$HOME/roboboat_ws/install/lib:$LD_LIBRARY_PATH"' >> "$USER_HOME/.bashrc"

  echo "$USER_HOME/roboboat_ws/install/lib" | sudo tee /etc/ld.so.conf.d/roboboat_ws.conf
  sudo ldconfig
else
    echo "[INFO] None/unsupported version selected, skipping Gazebo installation installation..." 
fi