FROM ros:humble
ARG USERNAME
ARG USER_UID
ARG USER_GID

# Delete user if it exists in container (e.g Ubuntu Noble: ubuntu)
RUN if id -u $USER_UID ; then userdel `id -un $USER_UID` ; fi

# Create the user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

WORKDIR /home/${USERNAME}/roboboat_ws
COPY requirements.txt .
COPY apt-packages.txt .

RUN apt-get update && apt-get upgrade -y \
    && apt-get install -y \
       python3-pip \
       python3-venv \
       build-essential \
    && xargs sudo apt-get -y install < apt-packages.txt \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Virtualize and install Python packages, placed in a lower layer to minimize rebuilds
RUN python3 -m venv --system-site-packages /workspace/venv \
    && /workspace/venv/bin/pip install --upgrade pip \
    && /workspace/venv/bin/pip install --no-cache-dir -r requirements.txt

ENV PATH=/workspace/venv/bin:$PATH
ENV SHELL=/bin/bash

USER $USERNAME
CMD ["/bin/bash"]