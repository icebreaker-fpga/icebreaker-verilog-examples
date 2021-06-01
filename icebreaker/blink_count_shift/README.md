Simple example testing all the LED, Buttons and PMOD IO on the iCEBreaker FPGA board.

This example consists of three parts.

## Part 1

Binary counter displayed on the cluster of 5 LED found on the default PMOD of
the full iCEBreaker board. The LSB is the center red LED and the higher
significant bits are formed by the four green LEDs surrounding.

## Part 2

The count of depressed buttons on the main board and the default PMOD are displayed in binary on the two LEDs mounted on the main board.

## Part 3
The remaining PMOD 1A and 1B are combined into a 16bit shiftregister and a 1 bit is continously shifted through the outputs.
