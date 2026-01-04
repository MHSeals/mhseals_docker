#!/usr/bin/env bash

echo "Preparing environment..."

echo "Determining Linux distro..."
. /etc/os-release

if [[ "$ID" == "arch" || "$ID_LIKE" == *"arch"* ]]; then
    echo "Arch-based distro installation running..."

    if command -v yay &> /dev/null
    then
        echo "Yay is installed, skipping..."
    else
        echo "Installing AUR helper (yay)"
        sudo pacman -S --needed --noconfirm base-devel git
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm 
        cd ..
        rm -rf yay
    fi

    echo "Removing incompatable packages..."
    for pkg in docker.io docker-doc podman-docker containerd runc; do yay -Rns $pkg; done

    echo "Installing all required packages..."
    yay -S --noconfirm docker docker-buildx xorg-xwayland visual-studio-code-bin python-hjson jq

    if [[ "$(uname -m)" = "aarch64" && ! -f /etc/rpi-issue ]]; then
        yay -S --noconfirm nvidia-container-toolkit
    fi
elif [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID_LIKE" == *"debian"* ]]; then
    echo "Debian-based distro installation running..."

    echo "Removing incompatable packages..."
    for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

    # Set repo based on distro
    if [[ "$ID" == "ubuntu" ]]; then
        echo "Using Ubuntu-specific installation..." 
        DOCKER_REPO="https://download.docker.com/linux/ubuntu"
    else
        DOCKER_REPO="https://download.docker.com/linux/debian"
    fi

    # Install prerequisites
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg lsb-release python3-pip
    pip install hjson

    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(. /etc/os-release; echo "$VERSION_CODENAME") stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    echo "Installing all required packages..."
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin xwayland software-properties-common apt-transport-https wget curl jq

    if [ "$(uname -m)" = "aarch64" ]; then
        GET=https://github.com/hjson/hjson-go/releases/download/v4.5.0/hjson_v4.5.0_linux_arm64.tar.gz
    else
        GET=https://github.com/hjson/hjson-go/releases/download/v4.5.0/hjson_v4.5.0_linux_amd64.tar.gz
    fi

    curl -sSL $GET | sudo tar -xz -C /usr/local/bin

    echo "Installing VSCode..."
    wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
    sudo apt update
    sudo apt install code

    if [[ "$(uname -m)" = "aarch64" && ! -f /etc/rpi-issue ]]; then
        echo "Installing NVIDIA container tools..."
        curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
        curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
            sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
            sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
        
        sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
    fi
else
    echo "Installation failed!"
    echo "Unsupported distro: $ID"
    exit 1
fi

# Add user Docker user group
echo "Configuring Docker..."
sudo groupadd docker
sudo usermod -aG docker $USER

# Start and enable Docker
sudo systemctl start docker.service
sudo systemctl enable docker.service

if [[ -f .vscode/extensions.json ]]; then
    echo "Installing VSCode extensions..."
    extensions=$(jq -r '.recommendations[]' .vscode/extensions.json)
    for extension in $extensions; do
        if code --list-extensions | grep -q "$extension"; then
            echo "Extension '$extension' is already installed, skipping..."
        else
            echo "Installing '$extension'..."
            code --install-extension "$extension" || echo "Failed to install $extension"
        fi
    done
else
    echo "No .vscode/extensions.json found. Skipping extensions."
fi

echo "Adding VSCode port forwarding configuration..."
VSC_DIR="$HOME/.config/Code/User/"
VSC_CONFIG="$VSC_DIR/settings.json"
mkdir -p $VSC_DIR
touch $VSC_CONFIG
hjson -j $VSC_CONFIG > $VSC_CONFIG.tmp \
    && mv $VSC_CONFIG.tmp $VSC_CONFIG \
    && jq '.["remote.autoForwardPorts"] = false' $VSC_CONFIG > $VSC_CONFIG.tmp \
    && mv $VSC_CONFIG.tmp $VSC_CONFIG

echo "Running prebuild script..."
bash .devcontainer/prebuild.sh

echo "Setup completed!"
