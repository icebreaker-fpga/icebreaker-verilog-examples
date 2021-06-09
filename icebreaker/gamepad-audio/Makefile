PROJ = audio
ADD_SRC = pdm_sine_mod.v
ADD_DEPS = sin_table.hex
ADD_CLEAN = *.o gen_sin_table *.hex

PIN_DEF = ../icebreaker.pcf
DEVICE = up5k
PACKAGE = sg48

prog: iceprog

include ../../main.mk

gen_sin_table: gen_sin_table.o
	gcc $< -o $@ -lm

sin_table.hex: gen_sin_table
	./gen_sin_table > sin_table.hex
