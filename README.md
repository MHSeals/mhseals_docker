## Installation

Clone the repo (with packages):

```bash
git clone --recurse-submodules https://github.com/mhseals/mhseals_docker.git
```

If you didn't include the recurse-submodules flag then run to pull each needed submodule:

```
git submodule foreach '
  default_branch=$(git remote show origin | sed -n "/HEAD branch/s/.*: //p")
  echo "Pulling latest changes from $default_branch in $name"
  git fetch origin "$default_branch"
  git checkout "$default_branch"
  git pull origin "$default_branch"
'
```

For your convenience, an environment setup script for each OS has been provided. Simply run the following (`<OS>` corresponds to either `linux`, `mac`, or `windows`):

```bash
./setup.<OS>.sh
```

Now follow the OS-specific instructions below.

### Linux

Not much to do here, but for manual Docker installation instructions, visit the [Docker Engine installation guide](https://docs.docker.com/engine/install/). Be sure to follow all instructions in the [Linux post-install guide](https://docs.docker.com/engine/install/linux-postinstall/). Also be sure to get a text editor to work with the code and setup an X11 host if necessary (e.g. a Wayland-based WM).

> [!TIP]
> For those using editors other than VSCode, devcontainers offers a cli tool. Start by installing NVM:
>
> ```bash
> curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
> ```
>
> Alternatively:
>
> ```
> wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
> ```
>
> Then, make the `nvm` command available by resourcing your shell configuration file. I would highly advise ZSH users to lazy load NVM by replacing the generated commands with the [zsh-nvm](https://github.com/lukechilds/zsh-nvm) plugin. Alternatively, replace it with a [lazy loading function](https://github.com/nvm-sh/nvm/issues/730).
>
> ```bash
> source ~/.bashrc # .zshrc or config.fish depending on your shell
> ```
>
> Then, install and use the latest LTS version of npm and Node.
>
> ```bash
> nvm install --lts
> nvm use --lts
> ```
>
> Finally, install the [devcontainers cli tool (more usage information here)](https://github.com/devcontainers/cli):
>
> ```bash
> npm install -g @devcontainers/cli
> ```

### Windows

Install the following programs:

- [VcXsrv (X server for display)](https://sourceforge.net/projects/vcxsrv/)
- [Git](https://git-scm.com/downloads)
- [VSCode](https://code.visualstudio.com/)
- [Docker Desktop](https://docs.docker.com/desktop/release-notes/)

**Start the Docker Daemon each time you want to work on the project by opening the Docker Desktop application.** The first time you install it, you will be prompted to restart your system.

### Mac

> [!IMPORTANT]
> If you are willing to troubleshoot installing a newer version of OpenGL on an X11 Server (XQuartz), follow the steps below and document what you do as much as possible. Otherwise, simply install Linux on your Mac and follow the Linux instructions as normal.

Identify your chip architecture (Intel or Apple Silicon) by running `uname -m`. If you system is an Intel-based Mac, it should output `x86_64`, and if it is Apple Silicon, it will show `arm64`.

Install the following programs through your preferred method:

- [XQuartz (X server for display)](https://www.xquartz.org/)
- [Git](https://git-scm.com/downloads)
- [VSCode](https://code.visualstudio.com/)
- [Docker Desktop](https://docs.docker.com/desktop/release-notes/)

Brew provides an easy way to install all of them at once. Start by installing Brew:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Now, install all of the needed packages:

```bash
brew install git --cask visual-studio-code docker xquartz
```

You will need to restart your system to use both Docker and XQuartz. If for some reason you are running a Hackintosh or a macOS VM, it is likely that Docker will complain about Hyper-V for virtualization. Depending on your setup, you will need to add these options `+vmx,+smep,+smap,+hypervisor` to your VM/boot configuration. You will likely have to troubleshoot issues, but feel free to ask questions here.

After restarting, open XQuartz and enable `File > Preferences > Security > Allow connections from network clients`. **Each time you need to run a GUI application in the Docker container, be sure to run `xhost +` to give XQuartz access to X11 forwarding ports.** For more information, see [X11 Forwarding on macOS and Docker](https://gist.github.com/sorny/969fe55d85c9b0035b0109a31cbcb088). It may be beneficial to add a configuration to your system that runs this command automatically.

## Usage

### Simulation

There are three primary components to the simulation stack:

- Unity physics sim
- Ardupilot SITL control
- ROS navigation logic

For the Unity physics sim, visit [this page](https://github.com/MHSeals/mhseals_asv_sim) and follow the instructions for the setup.

The ROS packages/nodes you run for navigation are all completely up to you depending on what needs to be tested; however, be sure to always use the `ros_tcp_endpoint` package by running `ros2 run ros_tcp_endpoint default_server_endpoint --ros-args --<arg>:=<value>` (`ROS_IP` and `ROS_TCP_PORT` are useful args for matching the connection with Unity).

Finally, in order to start the Ardupilot SITL, you must start the devcontainer. After the it's running, in VSCode, open the activity bar. From there, select the "Remote Explorer" option. In the "Other Containers" section, should should be able to attach a VSCode window to `mhseals_docker_devcontainer (ardupilot_sitl)` (you may also just open it through a local terminal by running `docker run -it ardupilot_sitl bash`). After you have access to the terminal, run the following command below (please note it will fail initially unless the Unity connection is already up):

```bash
Tools/autotest/sim_vehicle.py -v "$VEHICLE" $SITL_EXTRA_ARGS
```

and connect it to ROS by starting the MAVROS node

```
ros2 launch mavros apm.launch fcu_url:=udp://127.0.0.1:9002
```
