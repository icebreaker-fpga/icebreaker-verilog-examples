This directory contains examples for the icebreaker-bitsy also known as icebitsy.

You are interested in the hardware, you can find the icebreaker-bitsy in the [US 1BitSquared store](https://1bitsquared.com/products/icebreaker-bitsy) as well as the [German 1BitSquared store](https://1bitsquared.de/products/icebreaker-bitsy).

## How to build and flash an example

To build the bitstream, enter the respective example directory and run:
```
make
```

To program the bitstream run:

```
make prog
```

## Notes
If you have more than one icebreaker-bitsy connected to your computer. The programming target will fail with an error indicating that `dfu-util` can not decide which device to program. To list the dfu-devices connected to your system run `dfu-util --list`. You should get an output that is similar to this:
```
❯ dfu-util --list
dfu-util 0.10

Copyright 2005-2009 Weston Schmidt, Harald Welte and OpenMoko Inc.
Copyright 2010-2020 Tormod Volden and Stefan Schmidt
This program is Free Software and has ABSOLUTELY NO WARRANTY
Please report bugs to http://sourceforge.net/p/dfu-util/tickets/

Found Runtime: [1d50:6147] ver=0001, devnum=107, cfg=1, intf=3, path="9-1.1.3", alt=0, name="DFU runtime", serial="e46870a4534c0d22"
Found DFU: [1d50:6146] ver=0005, devnum=112, cfg=1, intf=0, path="9-1.2", alt=1, name="RISC-V firmware", serial="e4692c7367532827"
Found DFU: [1d50:6146] ver=0005, devnum=112, cfg=1, intf=0, path="9-1.2", alt=0, name="iCE40 bitstream", serial="e4692c7367532827"
```

By unplugging and plugging in the icebitsies as needed you should be able to figure out which one is which. When you have figured that out, you can set `DFU_SERIAL` environment variable to tell the makefile which device to program. You can either do that with each invocation of the `make prog` target:
```
make prog DFU_SERIAL=<someserialnumber>
```
or you can set the environment variable for the shell session you are using:
```
export DFU_SERIAL=<someserialnumber>
```