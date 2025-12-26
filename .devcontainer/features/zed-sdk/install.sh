#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Detecting platform and GPU..."

GPU_AVAILABLE=false
TARGET_PLATFORM="unknown"
ARCH=$(uname -m)

if [ "$ARCH" = "aarch64" ] && [ -d "/usr/lib/aarch64-linux-gnu/tegra" ]; then
    TARGET_PLATFORM="jetson"
    GPU_AVAILABLE=true
    echo "[INFO] Jetson detected (ARM 64-bit)"
elif [ "$ARCH" = "x86_64" ]; then
    if command -v nvidia-smi &>/dev/null; then
        TARGET_PLATFORM="desktop"
        GPU_AVAILABLE=true
        echo "[INFO] Desktop with NVIDIA GPU detected"
    else
        TARGET_PLATFORM="linux"
        echo "[WARNING] x86_64 desktop without NVIDIA GPU detected. ZED SDK will be skipped."
    fi
else
    echo "[WARNING] Unsupported architecture: $ARCH. Skipping GPU-dependent steps."
fi

echo "[INFO] TARGET_PLATFORM set to '$TARGET_PLATFORM'"

if [ "$GPU_AVAILABLE" = true ] || [ "$TARGET_PLATFORM" = "jetson" ]; then
    echo "[INFO] Installing dependencies for ZED SDK on $TARGET_PLATFORM..."

    echo "[INFO] Setting NVIDIA env vars..."
    cat <<'EOF' > /etc/profile.d/nvidia.sh
export NVIDIA_DRIVER_CAPABILITIES=all
export NVIDIA_VISIBLE_DEVICES=all
EOF
    chmod +x /etc/profile.d/nvidia.sh

    if [ "$TARGET_PLATFORM" = "desktop" ]; then
        apt-get update -y
        apt-get install -y --no-install-recommends \
            lsb-release wget less udev zstd sudo build-essential cmake \
            python3 python3-pip libpng-dev libgomp1

        python3 -m pip install --upgrade pip
        python3 -m pip install numpy opencv-python pyopengl

        ZED_RUN_FILE="ZED_SDK_Linux_Ubuntu${UBUNTU_RELEASE_YEAR}.run"
        ZED_URL="https://download.stereolabs.com/zedsdk/${ZED_SDK_VERSION}/cu${CUDA_VERSION%%.*}/ubuntu${UBUNTU_RELEASE_YEAR}"

        echo "[INFO] Downloading ZED SDK for desktop from $ZED_URL ..."
        wget -q -O "$ZED_RUN_FILE" "$ZED_URL"

        if file "$ZED_RUN_FILE" | grep -q 'executable'; then
            chmod +x "$ZED_RUN_FILE"
            echo "[INFO] Installing ZED SDK..."
            ./"$ZED_RUN_FILE" silent
            ln -sf /lib/x86_64-linux-gnu/libusb-1.0.so.0 /usr/lib/x86_64-linux-gnu/libusb-1.0.so || true
        else
            echo "[WARNING] Downloaded ZED SDK run file is invalid. Skipping installation."
        fi

    elif [ "$TARGET_PLATFORM" = "jetson" ]; then
        RELEASE=${RELEASE:-r36.2}

        echo "[INFO] Setting up EGL/GLVND configuration..."
        mkdir -p /usr/share/egl/egl_external_platform.d/
        echo '{ "file_format_version" : "1.0.0", "ICD" : { "library_path" : "libnvidia-egl-wayland.so.1" }}' \
            > /usr/share/egl/egl_external_platform.d/nvidia_wayland.json

        mkdir -p /usr/share/glvnd/egl_vendor.d/
        echo '{ "file_format_version" : "1.0.0", "ICD" : { "library_path" : "libEGL_nvidia.so.0" }}' \
            > /usr/share/glvnd/egl_vendor.d/10_nvidia.json

        rm -f /usr/share/glvnd/egl_vendor.d/50_mesa.json || true

        echo "[INFO] Adding Tegra library paths..."
        echo "/usr/lib/aarch64-linux-gnu/tegra" >> /etc/ld.so.conf.d/nvidia-tegra.conf
        echo "/usr/lib/aarch64-linux-gnu/tegra-egl" >> /etc/ld.so.conf.d/nvidia-tegra.conf
        ldconfig

        echo "[INFO] Adding NVIDIA Jetson apt repository..."
        echo "deb https://repo.download.nvidia.com/jetson/common $RELEASE main" >> /etc/apt/sources.list
        cp /etc/jetson-ota-public.key /tmp/
        apt-key add /tmp/jetson-ota-public.key

        echo "[INFO] Installing Jetson dependencies..."
        DEBIAN_FRONTEND=noninteractive apt-get update -y
        DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
        DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
            bc bzip2 can-utils ca-certificates freeglut3-dev gnupg2 \
            gstreamer1.0-alsa gstreamer1.0-libav gstreamer1.0-plugins-bad \
            gstreamer1.0-plugins-base gstreamer1.0-plugins-good gstreamer1.0-plugins-ugly \
            gstreamer1.0-tools i2c-tools iw kbd kmod language-pack-en-base \
            libapt-pkg-dev libcanberra-gtk3-module libgles2 libglu1-mesa-dev \
            libglvnd-dev libgtk-3-0 libpython2.7 libudev1 libvulkan1 libzmq5 \
            mtd-utils parted pciutils python3 python3-pexpect python3-distutils python3-numpy \
            sox udev vulkan-tools wget wireless-tools wpasupplicant \
            lsb-release wget less zstd sudo apt-transport-https build-essential cmake

        L4T_MAJOR=$(echo "$L4T_VERSION" | cut -d. -f1)
        L4T_MINOR=$(echo "$L4T_VERSION" | cut -d. -f2)

        ZED_RUN_FILE="ZED_SDK_Linux.run"
        ZED_URL="https://download.stereolabs.com/zedsdk/${ZED_SDK_VERSION}/l4t${L4T_MAJOR}.${L4T_MINOR}/jetsons"

        echo "[INFO] Downloading ZED SDK for Jetson L4T $L4T_VERSION from $ZED_URL ..."
        wget -q -O "$ZED_RUN_FILE" "$ZED_URL"

        if file "$ZED_RUN_FILE" | grep -q 'executable'; then
            chmod +x "$ZED_RUN_FILE"
            echo "[INFO] Installing ZED SDK..."
            ./"$ZED_RUN_FILE" silent skip_tools skip_drivers
            rm -rf /usr/local/zed/resources/*
            ln -sf /usr/lib/aarch64-linux-gnu/tegra/libv4l2.so.0 /usr/lib/aarch64-linux-gnu/libv4l2.so || true
        else
            echo "[WARNING] Downloaded ZED SDK run file is invalid. Skipping installation."
        fi
    fi

    echo "[INFO] Fixing permissions..."
    chmod -R a+rX /usr/local/zed || true
    chmod -R a+rX /workspace/venv/lib || true
    
    echo "[INFO] Setting environment variables..."
    BASHRC="$HOME/.bashrc"
    if ! grep -q 'ZED_DIR=/usr/local/zed' "$BASHRC"; then
        echo "" >> "$BASHRC"
        echo "# ZED SDK environment variables" >> "$BASHRC"
        echo "export ZED_DIR=/usr/local/zed" >> "$BASHRC"
        echo "export CMAKE_PREFIX_PATH=/usr/local/zed:\$CMAKE_PREFIX_PATH" >> "$BASHRC"
        echo "export PATH=/workspace/venv/bin:\$PATH" >> "$BASHRC"
        echo "export LD_LIBRARY_PATH=/usr/local/zed/lib:\$LD_LIBRARY_PATH" >> "$BASHRC"
        echo "export PYTHONPATH=/workspace/venv/lib/python3.10/site-packages:\$PYTHONPATH" >> "$BASHRC"
        echo "[INFO] Environment variables appended to $BASHRC"
    fi
    
    rm -rf "$ZED_RUN_FILE" /var/lib/apt/lists/* || true
    mkdir -p ~/Documents/ZED/
else
    echo "[INFO] No compatible GPU detected. Skipping ZED SDK installation."
fi

echo "[INFO] ZED SDK installation complete (GPU steps skipped if unavailable)"