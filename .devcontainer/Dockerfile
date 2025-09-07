FROM ros:humble
ARG USER=USERNAME
ARG USER_UID=1000
ARG USER_GID=1000

# Delete user if it exists in container (e.g Ubuntu Noble: ubuntu)
RUN if id -u $USER_UID ; then userdel `id -un $USER_UID` ; fi

# Create the user
RUN echo "USER_GID is $USER_GID, USER is $USER" && groupadd --gid $USER_GID $USER
RUN useradd --uid $USER_UID --gid $USER_GID -m $USER 
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
RUN apt-get update 
RUN apt-get install -y sudo 
RUN echo $USER ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USER 
RUN chmod 0440 /etc/sudoers.d/$USER

RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y \
       python3-pip \
       python3-venv \
       build-essential \
       ros-humble-xacro \
       ros-humble-gazebo-ros-pkgs \
       ros-humble-ros2-control \
       ros-humble-ros2-controllers \
       ros-humble-gazebo-ros2-control \
       ros-humble-slam-toolbox \
       ros-humble-navigation2 \
       ros-humble-nav2-bringup \
       ros-humble-twist-mux \
       ros-humble-rviz2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Virtualize and install Python packages, placed in a lower layer to minimize rebuilds
WORKDIR /home/${USERNAME}/roboboat_ws
COPY requirements.txt .
RUN python3 -m venv --system-site-packages /workspace/venv \
    && /workspace/venv/bin/pip install --upgrade pip \
    && /workspace/venv/bin/pip install --no-cache-dir -r requirements.txt

ENV PATH=/workspace/venv/bin:$PATH
ENV SHELL /bin/bash

# [Optional] Set the default user. Omit if you want to keep the default as root.
USER $USER
CMD ["/bin/bash"]