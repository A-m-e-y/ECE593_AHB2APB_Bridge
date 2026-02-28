## Running the Testbench

### Prerequisites
- Synopsys VCS simulator (addpkg and addpkg_shell)
- University server - PSU ECE lab machines like "auto.ece.psu.edu"

### Compilation and Simulation
1. `ssh` to the MCES server (like `auto.ece.pdx.edu`):
    ```
    ssh <your_username>@auto.ece.pdx.edu
    ```
2. Load the Synopsys VCS Package and launch pkg shell:
    ```
    add_pkg_shell
    ```
3. Navigate to the `AHB2APB_Brdg_MS2_Class` directory.
4. Use the provided `Makefile` to compile and simulate the design:

**Using Makefile**
```bash
# Compile and run
make all

# Compile only
make compile

# Run simulation only (after compilation)
make sim

# Generate coverage report
make cov

# Clean generated files
make clean
```