#!/usr/bin/env python3
"""Require actual ROS image messages; compatible with Foxy and Jazzy."""
import time

import rclpy
from rclpy.qos import qos_profile_sensor_data
from sensor_msgs.msg import Image

rclpy.init()
node = rclpy.create_node('astro_camera_probe')
received = []
subscriptions = {}
deadline = time.monotonic() + 90


def receive(message):
    if message.width > 0 and message.height > 0 and len(message.data) > 0:
        received.append((message.width, message.height, message.encoding))


try:
    while time.monotonic() < deadline and len(received) < 3:
        for topic, types in node.get_topic_names_and_types():
            if 'sensor_msgs/msg/Image' in types and topic not in subscriptions:
                subscriptions[topic] = node.create_subscription(
                    Image, topic, receive, qos_profile_sensor_data)
                print('Subscribing:', topic, flush=True)
        rclpy.spin_once(node, timeout_sec=0.2)
    if len(received) < 3:
        raise SystemExit('FAIL: fewer than three nonempty camera images in 90 seconds')
    print('PASS: received real images:', received[:3], flush=True)
finally:
    node.destroy_node()
    rclpy.shutdown()
