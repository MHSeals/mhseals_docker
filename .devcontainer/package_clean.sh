#!/usr/bin/env bash


apt-get remove --purge opencv-dev
apt-get autoremove
rm -rf /usr/local/include/opencv4
rm -rf /usr/local/lib/libopencv_*
rm -rf /usr/local/lib/python3*/dist-packages/cv2
rm -rf /usr/local/bin/opencv_*
ldconfig