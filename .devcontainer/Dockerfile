FROM ros:humble
ARG USERNAME=USERNAME
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Delete user if it exists in container (e.g Ubuntu Noble: ubuntu)
RUN if id -u $USER_UID ; then userdel `id -un $USER_UID` ; fi

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

WORKDIR /home/${USERNAME}/roboboat_ws
COPY requirements.txt .
COPY apt-packages.txt .

RUN apt-get update && apt-get install -y wget lsb-release gnupg \
    && wget https://packages.osrfoundation.org/gazebo.gpg -O /usr/share/keyrings/gazebo.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/gazebo.gpg] \
    http://packages.osrfoundation.org/gazebo/ubuntu-stable $(lsb_release -cs) main" \
    | tee /etc/apt/sources.list.d/gazebo-stable.list \
    && apt-get update && apt-get upgrade -y \
    && apt-get install -y \
       python3-pip \
       python3-venv \
       build-essential \
    && xargs apt-get -y install < apt-packages.txt \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Python virtual environment
RUN python3 -m venv --system-site-packages /workspace/venv \
    && /workspace/venv/bin/pip install --upgrade pip \
    && /workspace/venv/bin/pip install --no-cache-dir -r requirements.txt

ENV PATH=/workspace/venv/bin:$PATH
ENV SHELL=/bin/bash
ENV GZ_SIM_RESOURCE_PATH="/home/${USERNAME}/roboboat_ws/src/asv_wave_sim/gz-waves-models/models:/home/${USERNAME}/roboboat_ws/src/asv_wave_sim/gz-waves-models/world_models:/home/${USERNAME}/roboboat_ws/src/asv_wave_sim/gz-waves-models/worlds"
ENV GZ_SIM_SYSTEM_PLUGIN_PATH="/home/${USERNAME}/roboboat_ws/install/lib"

RUN chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/roboboat_ws
USER ${USERNAME}

CMD ["/bin/bash"]
