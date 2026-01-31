# Files and directories to clean
CLEAN_DIRS  = csrc simv simv.daidir ucli.key  vcs.log  waveforms

# Default target
.PHONY: all
all:
	@echo "Running run.do..."
	@bash run.do

# Clean target
.PHONY: clean
clean:
	@echo "Cleaning files and directories..."
	@rm -rf $(CLEAN_DIRS)

