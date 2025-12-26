#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Installing dependencies for ZED SDK on $TARGET_PLATFORM..."

if [[ "$TARGET_PLATFORM" == "nvidia" || "$TARGET_PLATFORM" == "jetson" ]]; then
    if [ "$TARGET_PLATFORM" = "nvidia" ]; then
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

        if ! file "$ZED_RUN_FILE" | grep -q 'executable'; then
            echo "[ERROR] Downloaded file is not a valid .run executable. Check the ZED SDK URL for your version."
            exit 1
        fi

        chmod +x "$ZED_RUN_FILE"
        echo "[INFO] Installing ZED SDK..."
        ./"$ZED_RUN_FILE" silent

        ln -sf /lib/x86_64-linux-gnu/libusb-1.0.so.0 /usr/lib/x86_64-linux-gnu/libusb-1.0.so || true

    elif [ "$TARGET_PLATFORM" = "jetson" ]; then
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

        echo "[INFO] Adding NVIDIA Jetson apt repository and public key..."
        wget -qO - https://repo.download.nvidia.com/jetson/jetson-ota-public.asc | apt-key add -
        echo "deb https://repo.download.nvidia.com/jetson/common r$L4T_VERSION main" >> /etc/apt/sources.list

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

        apt-get update -y
        apt-get install -y --no-install-recommends \
            lsb-release wget less udev zstd sudo apt-transport-https build-essential cmake

        ZED_RUN_FILE="ZED_SDK_Linux.run"
        ZED_URL="https://download.stereolabs.com/zedsdk/${ZED_SDK_VERSION}/l4t${L4T_VERSION}/jetsons"

        echo "[INFO] Downloading ZED SDK for Jetson L4T $L4T_VERSION from $ZED_URL ..."
        wget -q -O "$ZED_RUN_FILE" "$ZED_URL"

        if ! file "$ZED_RUN_FILE" | grep -q 'executable'; then
            echo "[ERROR] Downloaded file is not a valid .run executable. Check the ZED SDK URL for Jetson L4T version."
            exit 1
        fi

        chmod +x "$ZED_RUN_FILE"
        echo "[INFO] Installing ZED SDK..."
        ./"$ZED_RUN_FILE" silent skip_tools skip_drivers

        rm -rf /usr/local/zed/resources/*
        ln -sf /usr/lib/aarch64-linux-gnu/tegra/libv4l2.so.0 /usr/lib/aarch64-linux-gnu/libv4l2.so || true

        echo "[INFO] Installing Jetson CUDA dev packages..."
        
        # Add NVIDIA repo (Jetson-specific)
        sudo apt-get update
        sudo apt-get install -y --no-install-recommends \
            cuda-toolkit-12-6 \
            libnvinfer8 \
            libnvinfer-plugin8 \
            libnvonnxparsers8 \
            libnvparsers8 \
            libnvinfer-bin \
            libnvinfer-dev \
            libcudnn8-dev \
            libcudnn8

        export CUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda
        export PATH=$CUDA_TOOLKIT_ROOT_DIR/bin:$PATH
        export LD_LIBRARY_PATH=$CUDA_TOOLKIT_ROOT_DIR/lib64:$LD_LIBRARY_PATH
    fi

    echo "[INFO] Fixing permissions..."
    chmod -R a+rX /usr/local/zed
    chmod -R a+rX /workspace/venv/lib

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

    rm -rf "$ZED_RUN_FILE" /var/lib/apt/lists/*
    mkdir -p ~/Documents/ZED/

    echo "[INFO] ZED SDK installation complete on $TARGET_PLATFORM"
else
    echo "[INFO] $TARGET_PLATFORM not supported, skipping installation" 
fi