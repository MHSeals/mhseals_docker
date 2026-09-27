# ZED workspace builds on Xavier NX / Foxy

The JetPack 5 image uses ZED SDK 4.0.8 and ROS Foxy on Ubuntu 20.04.
An optional workspace checkout of the ZED wrapper overrides the image's
prebuilt `/opt/zed_ros2` packages. Do not use the wrapper's current `master`
with this image: it targets newer SDKs, and its `find_package(CUDAToolkit)`
also needs a newer CMake than Ubuntu 20.04 supplies.

Use the same wrapper commit as `.devcontainer/Dockerfile.jetson-jp5`:
`77a043a6d7fb5802ac49562e61efc1a4d6b5fc3f` (`humble-v4.0.8`). Despite the
tag name, this release includes Foxy support. Its interfaces submodule is
`f7f90f11f818c3dda23219cd05d8c854a569fc85` (`zed_interfaces`, not `zed_msgs`).

Inside `roboboat_dev`, with a clean wrapper checkout:

```bash
cd /home/roboboat/roboboat_ws
git -C src/zed-ros2-wrapper status --short
git -C src/zed-ros2-wrapper fetch --depth 1 origin tag humble-v4.0.8
git -C src/zed-ros2-wrapper switch --detach humble-v4.0.8
git -C src/zed-ros2-wrapper submodule update --init --recursive
source /opt/ros/foxy/setup.bash
source /opt/zed_ros2/setup.bash
MAKEFLAGS='-j2 -l2' colcon build --merge-install \
  --packages-up-to zed_ros2 --executor sequential --cmake-clean-cache \
  --cmake-args -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF \
  -DCMAKE_EXE_LINKER_FLAGS=-Wl,--allow-shlib-undefined
source install/setup.bash
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zed2i camera_name:=front
```

Preserve local wrapper modifications before switching releases. The optional
clone helper still defaults to `master`; apply this pin explicitly for Foxy.
No SDK, CUDA, CMake, or application-code upgrade is required for this build.

In another container shell, source the same overlays to inspect camera data.
ZED 4 topic names differ from ZED 5 names used by some navigation relays;
verify the driver independently before adapting those relays. The standalone
launch above does not start propulsion or other navigation nodes.

The `astro_zed_jp5_resources` and `astro_zed_jp5_settings` Docker volumes
persist SDK resources and camera settings across container recreation.

## Verified on squirtle-jetson, 2026-09-27

All four packages (`zed_interfaces`, `zed_components`, `zed_wrapper`,
`zed_ros2`) built successfully. The workspace-installed wrapper opened ZED 2i
serial 39433684 on GPU 0 as the unprivileged `roboboat` user. A separate
subscriber sampled these topics for 15 seconds using sensor-data QoS:

| Topic under `/front/zed_node/` | Messages | Observed rate |
| --- | ---: | ---: |
| `rgb/image_rect_color` | 187 | 13.31 Hz |
| `depth/depth_registered` | 175 | 12.55 Hz |
| `rgb/camera_info` | 201 | 13.80 Hz |
| `odom` | 222 | 14.83 Hz |
| `imu/data` | 2680 | 178.63 Hz |

RGB was `bgra8` and depth was `32FC1`, both 640x360 with 921600-byte
payloads. Capture was HD720 at 30 FPS, with the default 15 FPS publication
target, 2x downscaling, and ULTRA depth. These are observed subscriber
rates, not a maximum-performance benchmark. The temporary camera test was
stopped afterwards; this does not install an autostart service or validate
the full navigation launch.
