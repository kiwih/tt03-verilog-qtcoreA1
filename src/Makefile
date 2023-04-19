# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog


# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = qtcore_a1_4baddr_scan_test


run_test: test
	./a.out

# normal simulation
ifneq ($(GATES),yes)

# this is the only part you should need to modify:
VERILOG_SOURCES += $(PWD)/kiwih_tt_top.v $(PWD)/accumulator_microcontroller.v $(PWD)/alu.v $(PWD)/shift_register.v $(PWD)/memory_bank.v $(PWD)/control_unit.v

test:
	iverilog -s $(TOPLEVEL) $(VERILOG_SOURCES) $(PWD)/qtcore_a1_4baddr_scan_test.v

else

# gate level simulation requires some extra setup, you shouldn't need to touch this
COMPILE_ARGS    += -DGL_TEST
COMPILE_ARGS    += -DFUNCTIONAL
COMPILE_ARGS    += -DUSE_POWER_PINS
COMPILE_ARGS    += -DSIM
COMPILE_ARGS    += -DUNIT_DELAY=#1
COMPILE_ARGS	+= -DSCAN_ONLY
ifneq ($(GATES_LOCAL),yes)
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
VERILOG_SOURCES += $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v
else
#local testing use only
VERILOG_SOURCES += primitives.v
VERILOG_SOURCES += sky130_fd_sc_hd.v
endif

# this gets copied in by the GDS action workflow
VERILOG_SOURCES += $(COMPILE_ARGS) $(PWD)/qtcore_a1_4baddr_scan_test.v $(PWD)/gate_level_netlist.v

test:
	iverilog -s $(TOPLEVEL) $(VERILOG_SOURCES)
	
endif

clean:
	rm -rf TEST_PASSES.txt
	rm -rf *.out

.PHONY: clean test run_test