PROJ = dvi-12bit
ADD_SRC = vga_core.v vga_timing.v

ADD_SRC += ../common/dfu_helper.v
PIN_DEF = ../icebitsy1-pmod.pcf
DEVICE = up5k
PACKAGE = sg48
#PNR_SEED = 1

prog: dfuprog

include ../../main.mk

gen_gamma_table: gen_gamma_table.o
	gcc $< -o $@ -lm

gamma_table.hex: gen_gamma_table
	./gen_gamma_table > gamma_table.hex
