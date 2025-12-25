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
    export DEBIAN_FRONTEND=noninteractive
    echo "Debian-based distro installation running..."

    echo "Removing incompatible packages..."
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do
        sudo apt-get purge -y $pkg || true
    done
    sudo apt-get autoremove -y

    echo "Installing base tools..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg wget lsb-release python3-pip git

    # Determine Docker distro
    if [[ "$ID" == "ubuntu" ]]; then
        DOCKER_DISTRO=ubuntu
    elif [[ "$ID" == "debian" ]]; then
        DOCKER_DISTRO=debian
    else
        echo "Unsupported Docker distro: $ID"
        exit 1
    fi

    # Docker GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$DOCKER_DISTRO/gpg \
        | sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg

    # Docker repo
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
        https://download.docker.com/linux/$DOCKER_DISTRO \
        $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo chmod 755 /etc/apt/keyrings
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    sudo apt-get update
    sudo apt-get install -y \
        docker-ce docker-ce-cli containerd.io \
        docker-buildx-plugin docker-compose-plugin \
        xwayland apt-transport-https software-properties-common

    pip3 install --no-input hjson

    # NVIDIA toolkit (optional)
    if lspci | grep -qi nvidia || [ -e /proc/driver/nvidia ]; then
        echo "Installing NVIDIA container toolkit..."
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
            | sudo gpg --dearmor --yes -o /usr/share/keyrings/nvidia-container-toolkit.gpg
        curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
            | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit.gpg] https://#g' \
            | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
        sudo apt-get update
        sudo apt-get install -y nvidia-container-toolkit
    else
        echo "No NVIDIA GPU detected, skipping NVIDIA toolkit."
    fi
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