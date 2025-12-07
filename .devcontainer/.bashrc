source /opt/ros/humble/setup.bash
source /workspace/venv/bin/activate
alias rviz2="rviz2 -d $ROS_WS/config/dark.rviz --stylesheet $ROS_WS/config/dark.qss"

if [ -d "$ROS_WS/install" ]; then
  source install/setup.bash
fi

# TODO: Improve this by reading from a text file
help () {
cat << 'EOF'

--- SITL Run Command ---
Tools/autotest/sim_vehicle.py -v "$VEHICLE" $SITL_EXTRA_ARGS

--- Kill Process On Port ---
sudo lsof -i :<port>
kill -9 <pid>

--- MAVROS Build Command ---
ros2 launch mavros apm.launch fcu_url:=udp://127.0.0.1:9002

--- ROS Build Commands ---
colcon build
source install/setup.bash

--- ROS TCP Endpoint ---
ros2 run ros_tcp_endpoint default_server_endpoint --ros-args -p ROS_IP:=<ip> -p ROS_TCP_PORT:=<port>

EOF
}