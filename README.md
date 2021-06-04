# iCEBreaker examples

[![Discord](https://img.shields.io/discord/613131135903596547?logo=discord)](https://discord.gg/P7FYThy) [![Support our crowd funding campaign at https://www.crowdsupply.com/1bitsquared/icebreaker-fpga](https://img.shields.io/badge/crowd_supply-support_us-27B1AC.svg)](https://www.crowdsupply.com/1bitsquared/icebreaker-fpga)

This repository contains examples for the iCEBreaker FPGA educational and development board.

The goal of this repository is to provide simple examples that can serve as a starting point for the exploration of the iCEBreaker ecosystem. All examples are using the Yosys/nextpnr/icestorm open source flow for ICE40 FPGA. No need for any signups and large downloads of proprietary toolchains necessary.

## Dependencies

### Manual toolchain build

For manual icestorm toolcahin flow build instructions follow the steps described on the [icestorm website](http://www.clifford.at/icestorm/#install).

### Toolchain build script

You can automate the build process of the toolchain using the [summon-fpga-tools script](https://github.com/open-tool-forge/summon-fpga-tools).

### Toolchain binary releases

You can download pre-built open source fpga toolchain binary release from [YosysHQ](https://github.com/YosysHQ/oss-cad-suite-build).

## Repository structure

This repository contains examples for multiple iCEBreaker development boards. The examples for each dev board can be found inside their respective subdirectories.

The default Placement Constraint File (.pcf) for iCEBreaker can be found in the respective dev board directory and contains references to all the default pins on the iCEBreaker development board. This file can be referenced by all the examples that use that board.

## Community

If you have any questions please join the Discord channel and ask away: [1bitsquared.com/pages/chat](https://1bitsquared.com/pages/chat/)
