
SRCDIR=../../src

SOURCE= $(SRCDIR)/bandpass_19khz.v

 
PROJECT=am_demod

all: sim

.PHONY: sim

sim: $(SOURCE) tb.v 19KHz_test.txt
	iverilog -grelative-include -o $(PROJECT)_design -D SIM -Winfloop tb.v $(SOURCE)
	vvp      -n $(PROJECT)_design
	gtkwave   dump.vcd config.gtkw 

clean: 
	rm $(PROJECT)_design
	rm dump.vcd
