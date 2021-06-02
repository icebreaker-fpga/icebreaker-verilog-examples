This example plays a tone through the stereo audio circuit of the gamepd & audio Pmod.

## Hardware requirements

This example is meant to be used with the gamepad & audio iCEBreaker Pmod attached to Pmod Port A on the iCEBreaker.

You can find the design files for the gamepad & audio Pmod in the [iCEBreaker Pmod github repository](https://github.com/icebreaker-fpga/icebreaker-pmod/tree/master/gamepad-n-audio) and it might be available from [1BitSquared USA](https://1bitsquared.com/collections/fpga) and [1BitSquared Germany](https://1bitsquared.de/collections/fpga).

You should be able to connect earphones to the 3.5mm audio jack and hear a sine tone. Be careful and don't hurt your ears!!!

I don't think this requires mentioning, but you do all of this at your own risk, you can keep the burned pieces. ;)

## Software requirements

No computer side software is needed to run this example.

## Building

Make sure you have the open souce FPGA dev tools installed and in your PATH. The tools you will need are: Yosys, nextpnr-ice40, icestorm.
You will also need GCC and libc installed so you can compile the sin table generator.

Connect your iCEBreaker and run:

```
make prog
```

## Testing

There is a simple testbench available for the gamepad readout core module.

Make sure you have iverilog installed and in your PATH. You will also need gtkwave or equivalent to read the resulting vcd signal trace file.

To run the simulation build the testbench target with:

```
make pdm_sine_mod_tb.vcd
```

And then open it in gtkwave with:
```
gtkwave pdm_sine_mod_tb.vcd
```

TIP: You can reload the vcd file without restarting gtkwave with Ctrl-Shift-R ;)
