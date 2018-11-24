PROJ = blink
PIN_DEF = blink.pcf
DEVICE = up5k
PACKAGE = sg48

ARACHNE = arachne-pnr 
ARACHNE_ARGS = 
NEXTPNR = nextpnr-ice40
NEXTPNR_ARGS =
ICEPACK = icepack
ICETIME = icetime
ICEPROG = iceprog

PNR ?= arachne

all: $(PROJ).bin $(TESTBENCHES)

%.blif %.json: %.v
	yosys -p 'synth_ice40 -top $(PROJ) -blif $*.blif -json $*.json' $<

ifeq ($(PNR),next)
%.asc: $(PIN_DEF) %.json
	$(NEXTPNR) $(NEXTPNR_ARGS) --$(DEVICE) --package $(PACKAGE) --json $*.json --pcf $(PIN_DEF) --asc $@
else
%.asc: $(PIN_DEF) %.blif
	$(ARACHNE) $(ARACHNE_ARGS) -l -d $(subst up,,$(subst hx,,$(subst lp,,$(DEVICE)))) -o $@ -p $^ -P $(PACKAGE)
endif

%.bin: %.asc
	$(ICEPACK) $< $@

%.rpt: %.asc
	$(ICETIME) -d $(DEVICE) -mtr $@ $<

prog: $(PROJ).bin
	$(ICEPROG) $<

sudo-prog: $(PROJ).bin
	@echo 'Executing prog as root!!!'
	sudo $(ICEPROG) $<

clean:
	rm -f $(PROJ).blif $(PROJ).json $(PROJ).asc $(PROJ).rpt $(PROJ).bin $(TESTBENCHES) *.vcd

.SECONDARY:
.PHONY: all prog clean
