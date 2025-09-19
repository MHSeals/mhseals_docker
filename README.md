> [!NOTE]
> This README was sourced directly from [a separate guide on GitHub](https://github.com/taherfattahi/ros2-slam-auto-navigation). Needed changes will be made as we continue to build upon the project as a base. If you plan to write more comprehensive documentation (or would like to see more detailed guides), please view the official [MHSeals Documentation](https://docs.mhsroboboat.com).

## Docker Installation

### Linux

For your convenience, a Docker installation script is available by running the following commands in the root of this repository:

```bash
chmod +x install_docker.sh
./install_docker.sh
```

To quickly install all recommended VSCode extensions, use the provided script. 

```bash
chmod +x install_extensions.sh
./install_extensions.sh
```

For manual installation instructions, visit the [Docker Engine installation guide](https://docs.docker.com/engine/install/). Be sure to follow all instructions in the [Linux post-install guide](https://docs.docker.com/engine/install/linux-postinstall/).

### Windows/macOS

> [!IMPORTANT]
> If you are on Windows, please use the `wsl` branch of this repo for the appropriate instructions and configuration to run this container on WSL.
> Similarly, all macOS users should use the `mac` branch.

This container is primarily intended for use with Linux; however, WSL and macOS support have been implemented to accomadate for various development environments. Please write a GitHub issue if you notice anything wrong.

## ROS2 SLAM Autonomous Navigation with SLAM Toolbox and Nav2

Use SLAM Toolbox to generate a map of the environment, then utilize the Nav2 stack for autonomous navigation within that mapped space. Rviz provides visualization of the robot, its surroundings, and ongoing navigation tasks.

### Demo Video
[![IMAGE](images/image_thumbnail.png)](https://youtu.be/-g2nmHqZfgc?si=NTKtegcQCZkt2e99)


### Overview

This package provides:
- **Gazebo** simulation environment.
- **ROS2** Control integration to handle the robot’s joints and controllers.
- **SLAM Toolbox** for online (asynchronous) map building as the robot explores.
- **Nav2** stack to plan paths and autonomously navigate in the mapped environment.
- **Rviz2** visualization for monitoring robot state, the map, and navigation plans.

### Transform frame
![tf2_frames](images/tf2_frames.png)


### Dependencies and Setup

If you intend to run the `auto_nav` package on your local dev environment, you need to install the following. Otherwise, skip this section if you are using the Docker container.

-  Install ROS 2 Humble - [Read here](https://docs.ros.org/en/humble/Installation.html)
-  Create Workspace - [Read here](https://docs.ros.org/en/humble/Tutorials/Beginner-Client-Libraries/Creating-A-Workspace/Creating-A-Workspace.html)
-  Install XACRO 
```sh
sudo apt install ros-<distro-name>-xacro 
```
- Gazebo ROS Packages
```sh
sudo apt install ros-<distro-name>-gazebo-ros-pkgs
```
- ROS2 Control
```sh
sudo apt install ros-<distro-name>-ros2-control ros-<distro-name>-ros2-controllers ros-<distro-name>-gazebo-ros2-control
```
- SLAM Toolbox
```sh
sudo apt install ros-<distro-name>-slam-toolbox
```
- Nav2 and Twist Mux 
```sh
sudo apt install ros-<distro-name>-navigation2 sudo apt install ros-<distro-name>-nav2-bringup sudo apt install ros-<distro-name>-twist-mux
```

### Building the Package
After cloning this repository into your workspace’s ```src``` directory:
```sh
cd <your_ros2_ws>
colcon build
source install/setup.bash
```

### Usage

1. **Launch the Simulation**
Run the Gazebo simulation environment and spawn the robot:

```sh
ros2 launch auto_nav launch_sim.launch.py
```

2. **Launch SLAM and Navigation**
In a new terminal (with the workspace sourced), launch the SLAM Toolbox and Nav2 bringup with Rviz:
```sh
ros2 launch auto_nav slam_navigation.launch.py use_sim_time:=true
```

3. **Use Rviz2 for Visualization:** Rviz2 should start automatically from the second launch file. In Rviz2:
   - You can visualize the robot’s pose, sensors, and the map being built.
   - Interactively set navigation goals using the "2D Nav Goal" tool once the map and localization are stable.

4. **Autonomous Navigation:** Once you have a map (even partial), you can send navigation goals to the robot via Rviz. Nav2 will compute a path and command the robot to reach the desired destination.

### Launch Simulator-SLAM-Navigation-RViz commands individually

1. Launching the Simulation Environment
```sh
ros2 launch auto_nav launch_sim.launch.py
```
2. Starting the SLAM Toolbox (Online, Asynchronous Mode)
```sh
ros2 launch slam_toolbox online_async_launch.py use_sim_time:=true
```
3. Initializing the Navigation Stack
```sh
ros2 launch nav2_bringup navigation_launch.py use_sim_time:=True
```
4. Opening RViz with Navigation Visualization
```sh
ros2 run rviz2 rviz2 use_sim_time:=True -d /opt/ros/humble/share/nav2_bringup/rviz/nav2_default_view.rviz
```

### Troubleshooting
- **Simulation Issues:**
  Ensure that Gazebo, ROS2 Control, and joint publisher packages are correctly installed.

- **TF or Robot Description Issues:**
Check the URDF/Xacro files and the rsp.launch.py to ensure the robot description is being published correctly.

- **Navigation Errors:**
Confirm that SLAM Toolbox is running and providing a map. Ensure that Nav2 parameters match your robot’s configuration (e.g., footprint, sensor sources).

### Resources

- Robot Operating System [(ROS 2 Humble)](https://docs.ros.org/en/humble/index.html)
- ROS 2 [tf2](https://docs.ros.org/en/humble/Tutorials/Intermediate/Tf2/Introduction-To-Tf2.html)
- [ROS 2 Navigation](https://github.com/ros-navigation/navigation2/) Framework and System
- [Slam Toolbox](https://github.com/SteveMacenski/slam_toolbox) for lifelong mapping and localization in potentially massive maps with ROS
