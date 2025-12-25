#!/usr/bin/env bash
set -euo pipefail

echo "Preparing environment..."

# Detect Linux distro
. /etc/os-release

if [[ "$ID" == "arch" || "$ID_LIKE" == *"arch"* ]]; then
    echo "Arch-based distro installation running..."

    # Install yay if not present
    if ! command -v yay &> /dev/null; then
        echo "Installing AUR helper (yay)..."
        sudo pacman -S --needed --noconfirm base-devel git
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd ..
        rm -rf yay
    fi

    echo "Removing incompatible packages..."
    for pkg in docker.io docker-doc podman-docker containerd runc; do
        yay -Rns --noconfirm $pkg || true
    done

    echo "Installing required packages..."
    yay -S --noconfirm docker xorg-xwayland python-hjson nvidia-container-toolkit curl wget git gnupg

elif [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
    echo "Debian-based distro installation running..."

    echo "Removing incompatible packages..."
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        sudo apt-get remove -y $pkg || true
    done
    
    echo "Installing needed setup tools..."
    sudo apt-get update 
    sudo apt-get install -y gnupg wget curl 

    # Docker repo setup
    DOCKER_REPO="https://download.docker.com/linux/${ID}"
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL "$DOCKER_REPO/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.asc
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] $DOCKER_REPO \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin xwayland software-properties-common apt-transport-https python3-pip git
    pip install hjson

    # NVIDIA container toolkit
    curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
    curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
    sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit

else
    echo "Unsupported distro: $ID"
    exit 1
fi

# Configure Docker
echo "Configuring Docker..."
sudo groupadd -f docker
sudo usermod -aG docker $USER
sudo systemctl enable --now docker

# Install NVM and latest LTS Node
echo "Installing NVM..."
export NVM_DIR="$HOME/.nvm"
mkdir -p "$NVM_DIR"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts

# Install devcontainers CLI
echo "Installing devcontainers CLI..."
npm install -g @devcontainers/cli

echo "Headless setup completed!"