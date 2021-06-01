Simple example testing all the LED, Buttons and IO on the iCEBreaker-bitsy FPGA board.

This example consists of two parts.

## Part 1

Wait for the user button to be pressed for ~2s. After the button was pressed for ~2s the Green LED will go out.
When the button is then released the iCEBreauer-bitsy will reboot into the DFU bootloader.

## Part 2
All the iCEBreaker-btisy pins are combined into a 24bit shiftregister and a 1 bit is continously shifted through the outputs.
