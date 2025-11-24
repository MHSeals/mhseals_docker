#!/bin/bash
set -e

cd /home/$USER/ardupilot

# Ensure environment is loaded
. ~/.profile || true

echo "Starting SITL for vehicle: $VEHICLE"
echo "Extra args: $SITL_EXTRA_ARGS"

exec Tools/autotest/sim_vehicle.py -v "$VEHICLE" $SITL_EXTRA_ARGS