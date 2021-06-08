
all: $(PROJ).rpt $(PROJ).bin

%.json: %.v $(ADD_SRC) $(ADD_DEPS)
	yosys -ql $*.log -p 'synth_ice40 -top top -json $@' $< $(ADD_SRC)

%.asc: $(PIN_DEF) %.json
	nextpnr-ice40 --$(DEVICE) $(if $(PACKAGE),--package $(PACKAGE)) $(if $(FREQ),--freq $(FREQ)) --json $(filter-out $<,$^) --pcf $< --asc $@

%.bin: %.asc
	icepack $< $@

%.rpt: %.asc
	icetime $(if $(FREQ),-c $(FREQ)) -d $(DEVICE) -mtr $@ $<

%_tb: %_tb.v %.v
	iverilog -g2012 -o $@ $^

%_tb.vcd: %_tb
	vvp -N $< +vcd=$@

%_syn.v: %.json
	yosys -p 'read_json $^; write_verilog $@'

%_syntb: %_tb.v %_syn.v
	iverilog -o $@ $^ `yosys-config --datdir/ice40/cells_sim.v`

%_syntb.vcd: %_syntb
	vvp -N $< +vcd=$@

iceprog: $(PROJ).bin
	iceprog $<

sudo-iceprog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo iceprog $<

dfuprog: $(PROJ).bin
ifeq ($(DFU_SERIAL),)
	dfu-util -d 1d50:6146 -a 0 -D $< -R
else
	dfu-util -d 1d50:6146 -S $(DFU_SERIAL) -a 0 -D $< -R
endif

sudo-dfuprog: $(PROJ).bin
ifeq ($(DFU_SERIAL),)
	sudo dfu-util -d 1d50:6146 -a 0 -D $< -R
else
	sudo dfu-util -d 1d50:6146 -S $(DFU_SERIAL)  -a 0 -D $< -R
endif

clean:
	rm -f $(PROJ).blif $(PROJ).asc $(PROJ).rpt $(PROJ).bin $(PROJ).json $(PROJ).log $(ADD_CLEAN)

.SECONDARY:
.PHONY: all prog clean
.DEFAULT_GOAL := all
