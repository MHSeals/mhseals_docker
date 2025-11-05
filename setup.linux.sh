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
    yay -S --noconfirm docker xorg-xwayland visual-studio-code-bin
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
    sudo apt-get install -y ca-certificates curl gnupg lsb-release

    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL "$DOCKER_REPO/gpg" -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] $DOCKER_REPO \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update

    echo "Installing all required packages..."
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin xwayland software-properties-common apt-transport-https wget

    echo "Installing VSCode..."
    wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
    sudo apt update
    sudo apt install code
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

echo "Running prebuild script..."
bash .devcontainer/prebuild.sh

echo "Setup completed!"