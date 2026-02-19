# Makefile for AHB2APB Bridge Class-based Testbench
# Use with VCS simulator

# Compiler and flags
VCS = vcs
VCS_FLAGS = -sverilog -full64 -timescale=1ns/1ps -debug_access+all +v2k -LDFLAGS -Wl,--no-as-needed
COV_FLAGS = -cm line+cond+fsm+tgl+branch+assert -cm_dir ./coverage.vdb

# File list
FILELIST = filelist.f

# Executable
SIM = simv

# Targets
.PHONY: all compile sim clean help cov

all: compile sim

compile:
	@echo "========================================"
	@echo "  Compiling AHB2APB Bridge Testbench"
	@echo "========================================"
	$(VCS) $(VCS_FLAGS) $(COV_FLAGS) -f $(FILELIST) -l compile.log
	@echo "Compilation complete - check compile.log"

sim:
	@echo "========================================"
	@echo "  Running Simulation"
	@echo "========================================"
	./$(SIM) -l simulation.log -cm line+cond+fsm+tgl+branch+assert -cm_dir ./coverage.vdb
	@echo "Simulation complete - check simulation.log"

cov:
	@echo "========================================"
	@echo "  Generating Coverage Report"
	@echo "========================================"
	urg -dir ./coverage.vdb -report ./coverage_report
	@echo "Coverage report generated in ./coverage_report"

clean:
	@echo "Cleaning up..."
	rm -rf csrc $(SIM)* *.log *.vpd ucli.key DVEfiles coverage.vdb coverage_report

help:
	@echo "AHB2APB Bridge Testbench Makefile"
	@echo "================================="
	@echo "Targets:"
	@echo "  make all     - Compile and run simulation"
	@echo "  make compile - Compile only"
	@echo "  make sim     - Run simulation only"
	@echo "  make cov     - Generate coverage report"
	@echo "  make clean   - Remove all generated files"
	@echo "  make help    - Show this help message"
