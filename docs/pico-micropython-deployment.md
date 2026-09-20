# Pico MicroPython deployment from the Odroid

This note describes the supported way to install the `mhseals_hardware` Pico
controller, what makes it start after power-up, and what is still required for
verified two-way communication.

## What runs at boot

MicroPython runs `_boot.py`, then an optional `boot.py`, then an optional
`main.py`, and finally presents the REPL. `boot.py` is intended for short
hardware or network initialization and must return. `main.py` is the
application entry point and may contain an infinite loop. Therefore the
repository's `pico/thruster_controller.py` must be stored on the Pico as
`main.py`, not merely executed with `mpremote run`, to start after every power
cycle or reset.[^boot][^mpremote]

The existing helper implements that layout:

```bash
cd ~/astro_dock/src/mhseals_hardware
./scripts/flash_pico.sh --check
./scripts/flash_pico.sh
```

It creates an isolated `.pico-tools` Python environment, installs `mpremote`,
copies `pico/thruster_controller.py` to `:main.py`, and resets the board. A
leading `:` in an `mpremote fs` path denotes the Pico filesystem. The helper
prefers `/dev/serial/by-id/*MicroPython*`; specify `--port DEVICE` if detection
is ambiguous. `mpremote` also supports `connect list` and an explicit
`connect /dev/ttyACM0` for diagnosis.[^mpremote]

Verify the stored file and perform a real boot test:

```bash
.pico-tools/bin/python -m mpremote connect /dev/serial/by-id/<pico> fs ls
.pico-tools/bin/python -m mpremote connect /dev/serial/by-id/<pico> reset
```

After the reset and USB re-enumeration, run the ROS node against the stable
`/dev/serial/by-id/` path. Do not leave `mpremote` attached: it opens serial
ports exclusively and will compete with the ROS process.[^mpremote]

> **Safety:** Resetting starts `main.py`, which enables the ESC control line.
> Secure the boat, keep people and lines clear, and submerge the thrusters
> before flashing or boot testing.

## Firmware installation and recovery

The Pico must already have MicroPython firmware for the file-copy workflow.
If it does not enumerate as a MicroPython USB serial device, hold **BOOTSEL**
while connecting or resetting the Pico. It should mount as the `RPI-RP2`
mass-storage device. Download the UF2 for the exact board from MicroPython and
copy it onto that volume; the board will reboot into MicroPython.[^rp2][^uf2]

BOOTSEL/UF2 installs or recovers the interpreter. Run `flash_pico.sh`
afterward to ensure the expected application is installed. Routine application
updates need only `mpremote`; they do not require BOOTSEL.

## Serial protocol and validation

The stock RP2 MicroPython build exposes the REPL through USB serial. The
controller uses `select.poll()` on `sys.stdin` and reads one newline-delimited
ASCII command at a time, so the same USB CDC/ACM stream carries application
traffic.[^rp2-quickref] The current command format is:

```text
1500,1500,1500,1500\n
```

The Pico controller applies valid commands, neutralizes all channels on
malformed input, and neutralizes them after 500 ms without a command. It emits
newline-framed responses on the same USB stream: `READY` after startup,
`ACK,<four applied PWM values>` after a valid command,
`ERR,invalid_command` after malformed input, and `TIMEOUT` when its watchdog
neutralizes the outputs. The ROS bridge keeps a serial reader active and logs
startup, error, timeout, and unexpected responses.

This establishes bidirectional application communication and lets deployment
tests verify the exact values accepted by the Pico. A future reliability
extension could add sequence IDs, acknowledgement deadlines, and automatic
reconnection after USB disconnect/re-enumeration. Keep the Pico parser
non-blocking so its 500 ms neutral watchdog continues to run. These framing
and acknowledgement rules are project protocol design choices; MicroPython
supplies the USB serial stream but does not define the application protocol.

For initial validation with propulsion disconnected or otherwise made safe:

1. Run `flash_pico.sh --check`, then `flash_pico.sh`.
2. Confirm `main.py` with `mpremote fs ls`, issue `mpremote reset`, and wait for
   the by-id link to return.
3. Start `thruster_serial_node` using that by-id path and verify that valid
   commands are written continuously.
4. Stop commands for more than 500 ms and confirm all PWM outputs return to
   neutral with test equipment before connecting ESCs.
5. Verify `READY`, command acknowledgements, malformed-command errors, and the
   watchdog's `TIMEOUT` response. Unplug/replug recovery remains a manual
   restart until automatic serial reconnection is implemented.

## Primary sources

[^boot]: MicroPython, [Reset and Boot Sequence](https://docs.micropython.org/en/latest/reference/reset_boot.html).
[^mpremote]: MicroPython, [`mpremote` remote control](https://docs.micropython.org/en/latest/reference/mpremote.html).
[^rp2]: MicroPython, [RP2 port README](https://github.com/micropython/micropython/blob/master/ports/rp2/README.md).
[^uf2]: MicroPython, [Raspberry Pi Pico firmware downloads](https://micropython.org/download/RPI_PICO/).
[^rp2-quickref]: MicroPython, [Quick reference for the RP2](https://docs.micropython.org/en/latest/rp2/quickref.html).
