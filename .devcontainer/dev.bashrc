source /opt/ros/humble/setup.bash
source /workspace/venv/bin/activate
alias rviz2="rviz2 -d $ROS_WS/config/dark.rviz --stylesheet $ROS_WS/config/dark.qss"

if [ -d "$ROS_WS/install" ]; then
  source install/setup.bash
fi

# TODO: Improve this by reading from a text file
help () {
    cat ~/.helper.txt
}