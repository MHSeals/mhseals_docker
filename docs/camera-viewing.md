# Camera viewing

Run the camera in its Jetson container:

```sh
ros2 launch zed_wrapper zed_camera.launch.py camera_model:=zed2i camera_name:=front publish_tf:=false publish_map_tf:=false
```

On either Jetson, run `ros2 launch rosbridge_server rosbridge_websocket_launch.xml`.
In Foxglove, choose **Rosbridge**, connect to `ws://squirtle-jetson.local:9090`,
and select `/front/zed_node/left/image_rect_color/compressed` in an Image panel
(ZED 4; inspect image topics on newer wrappers).

Keep these unauthenticated endpoints on the trusted boat LAN. Foxy remains on
DDS domain 142; Jazzy remains on 42. Jazzy RViz cannot directly consume Foxy's
topics safely; use Foxglove, or a matching Foxy RViz environment.
For map-frame objects in Jazzy RViz/Foxglove, use the narrow
[object bridge](https://github.com/MHSeals/mhseals_nav/blob/main/docs/objects.md).
It transfers detections and camera static TF, not images or remote localization.
