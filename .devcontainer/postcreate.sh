#!/usr/bin/env bash
set -e

echo "[postcreate] Appending custom bashrc..."
cat .devcontainer/dev.bashrc >> ~/.bashrc

echo "[postcreate] Creating helper text file..."
touch ~/.helper.txt
cat .devcontainer/dev.helper.txt >> ~/.helper.txt

echo "[postcreate] Updating apt packages..."
sudo apt update -y

echo "[postcreate] Updating rosdep..."
rosdep update

echo "[postcreate] Install geoid dataset for mavros..."
sudo geographiclib-get-geoids egm96-5

echo "[postcreate] Installing workspace dependencies..."
rosdep install --from-paths src --ignore-src -y \
  --skip-keys="$(tr '\n' ' ' < .devcontainer/package-ignore.txt)"

echo "[postcreate] Fixing permissions of optional ZED SDK..."
for dir in /usr/local/zed/resources /usr/local/zed/settings; do
    [ -d "$dir" ] && sudo chmod -R 777 "$dir" || true
done

echo "[postcreate] Done!"