if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi
export PATH=/opt/gcc-arm-none-eabi-10-2020-q4-major/bin:$PATH
export PATH="/home/ardupilot/ardupilot/Tools/autotest:"$PATH
export PATH=/usr/lib/ccache:$PATH
cd /home/$USER/ardupilot

help () {
    cat ~/.helper.txt
}