# Makefile for AHB2APB Bridge Class-based Testbench
# Use with VCS simulator

# Compiler and flags
VCS = vcs
VCS_FLAGS = -sverilog -full64 -timescale=1ns/1ps -debug_access+all +v2k -LDFLAGS -Wl,--no-as-needed
COV_FLAGS = -cm line+cond+fsm+tgl+branch -cm_dir ./coverage.vdb -cm_hier coverage_exclude.cfg

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
	@echo ""

sim:
	@echo "========================================"
	@echo "  Running All Tests"
	@echo "========================================"
	./$(SIM) -l simulation.log $(COV_FLAGS)
	@echo ""
	@echo "Simulation complete - check simulation.log"

cov:
	@echo "========================================"
	@echo "  Generating Coverage Report"
	@echo "========================================"
	urg -dir ./coverage.vdb -report ./coverage_report
	@echo ""
	@echo "Coverage report generated in ./coverage_report"
	@echo "View: firefox ./coverage_report/dashboard.html"

clean:
	@echo "Cleaning up..."
	rm -rf csrc $(SIM)* *.log *.vcd *.vpd ucli.key DVEfiles coverage.vdb coverage_report AN.DB

help:
	@echo "============================================================"
	@echo "  AHB2APB Bridge Verification Makefile"
	@echo "============================================================"
	@echo ""
	@echo "Targets:"
	@echo "  make all       - Compile and run all tests"
	@echo "  make compile   - Compile the design and testbench"
	@echo "  make sim       - Run simulation (all tests)"
	@echo "  make cov       - Generate HTML coverage report"
	@echo "  make clean     - Remove all build artifacts"
	@echo "  make help      - Show this help message"
	@echo ""
	@echo "Tests that run automatically:"
	@echo "  1. SANITY         - Regression baseline (4 txns)"
	@echo "  2. RAND_SMALL     - Small random test (10 txns)"
	@echo "  3. RAND_MEDIUM    - Medium random test (50 txns)"
	@echo "  4. MULTI_SLAVE    - Multi-slave test (60 txns)"
	@echo "  5. COMPREHENSIVE  - Full coverage test (115 txns)"
	@echo ""
	@echo "Coverage:"
	@echo "  - Functional coverage via covergroups"
	@echo "  - VCS code coverage (line, cond, FSM, branch, toggle)"
	@echo "  - Coverage accumulates across all tests"
	@echo "============================================================"
