PROJ = vga-12bit
ADD_SRC = vga_core.v vga_timing.v

PIN_DEF = ../icebreaker.pcf
DEVICE = up5k

include ../main.mk

gen_gamma_table: gen_gamma_table.o
	gcc $< -o $@ -lm

gamma_table.hex: gen_gamma_table
	./gen_gamma_table > gamma_table.hex
