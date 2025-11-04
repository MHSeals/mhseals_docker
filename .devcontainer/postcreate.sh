#!/usr/bin/env bash
set -e

echo "[postcreate] Updating apt packages..."
sudo apt update -y

echo "[postcreate] Updating rosdep..."
rosdep update

echo "[postcreate] Installing workspace dependencies..."
rosdep install --from-paths src --ignore-src -y \
  --skip-keys="$(tr '\n' ' ' < .devcontainer/package-ignore.txt)"

echo "[postcreate] Appending custom bashrc..."
if [ -f .devcontainer/.bashrc ]; then
  cat .devcontainer/.bashrc >> ~/.bashrc
else
  echo "Warning: .devcontainer/.bashrc not found."
fi

echo "[postcreate] Done!"