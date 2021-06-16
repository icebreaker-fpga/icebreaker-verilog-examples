PROJ = dvi-4bit
ADD_SRC = vga_core.v vga_timing.v

PIN_DEF = ../icebreaker.pcf
DEVICE = up5k
PACKAGE = sg48
#PNR_SEED = 1

prog: iceprog

include ../../main.mk

gen_gamma_table: gen_gamma_table.o
	gcc $< -o $@ -lm

gamma_table.hex: gen_gamma_table
	./gen_gamma_table > gamma_table.hex
