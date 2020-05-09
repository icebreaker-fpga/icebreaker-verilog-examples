An example testing the (S)NES type shift register based gamepad readout.

## Hardware requirements

This example is meant to be used with the gamepad & audio iCEBreaker Pmod attached to Pmod Port A on the iCEBreaker.

You can find the design files for the gamepad & audio Pmod in the [iCEBreaker Pmod github repository](https://github.com/icebreaker-fpga/icebreaker-pmod/tree/master/gamepad-n-audio) and it might be available from [1BitSquared USA](https://1bitsquared.com/collections/fpga) and [1BitSquared Germany](https://1bitsquared.de/collections/fpga).

You can wire up your gamepads directly to the Pmod connector, but make sure to power your gamepad from the 3v3 power rail. DO NOT HOOK UP 5V SIGNALS DIRECTLY TO THE PMOD PORT!!! You will break things... that is why the dedicated gamepad Pmod has level shifters.

I don't think this requires mentioning, but you do all of this at your own risk, you can keep the burned pieces. ;)

## Software requirements

The output from this example is printing to the UART interface of the iCEBreaker. Just connect a serial terminal emulator to the second virtual UART port of the iCEBreaker at 115200 baud.

On Linux this port will be available as `/dev/ttyUSB1` (make sure you are in the dialout group).

The output should be a following block of text:

```
1FFFF
2FFFF
30000
40000
```

The first column is the game port ID. The remaining 4 columns show the gamepad 16bit register status as hexadecimal values.

If a gamepad is connected you should get all 1s aka `FFFF`. If no gamepad is connected you should get all 0s aka `0000`.

NOTE: The first version of the gamepad & audio Pmod does not have a pulldown resistor on the data lines. So the no gamepad connected state could be anything as those pins are flapping in the wind. You will get the same issue if you decide to wire up the gamepads directly to the Pmod connector.

The printed text contains an escape sequence (`"\033[4A"`) that causes the cursor to go up 4 lines and keep printing over the previous output. If you are using some software that does not understand terminal escape sequences you will probably see some garbage output and not a nice square block of text.

For reference here is the serial port configuration in minicom:

```
+------------------------------------------+
| A -    Serial Device      : /dev/ttyUSB1 |
| B - Lockfile Location     : /var/lock    |
| C -   Callin Program      :              |
| D -  Callout Program      :              |
| E -    Bps/Par/Bits       : 115200 8N1   |
| F - Hardware Flow Control : No           |
| G - Software Flow Control : No           |
|                                          |
|    Change which setting?                 |
+------------------------------------------+
```

## Building

Make sure you have the open souce FPGA dev tools installed and in your PATH. The tools you will need are: Yosys, nextpnr-ice40, icestorm.

Connect your iCEBreaker and run:

```
make prog
```

## Testing

There is a simple testbench available for the gamepad readout core module.

Make sure you have iverilog installed and in your PATH. You will also need gtkwave or equivalent to read the resulting vcd signal trace file.

To run the simulation build the testbench target with:

```
make gamepad_mod_tb.vcd
```

And then open it in gtkwave with:
```
gtkwave gamepad_mod_tb.vcd
```

TIP: You can reload the vcd file without restarting gtkwave with Ctrl-Shift-R ;)
