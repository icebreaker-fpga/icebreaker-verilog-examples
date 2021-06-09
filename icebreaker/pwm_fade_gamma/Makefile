PROJ = gamma_pwm
ADD_DEPS = gamma_table.hex
ADD_CLEAN = *.o gen_gamma_table *.hex

PIN_DEF = ../icebreaker.pcf
DEVICE = up5k
PACKAGE = sg48

prog: iceprog

include ../../main.mk

gen_gamma_table: gen_gamma_table.o
	gcc $< -o $@ -lm

gamma_table.hex: gen_gamma_table
	./gen_gamma_table > gamma_table.hex
