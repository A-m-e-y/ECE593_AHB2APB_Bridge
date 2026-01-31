# AHB2APB_Brdg MS1 (Traditional TB)

This directory contains the Milestone 1 implementation of the AHB to APB Bridge using a traditional testbench approach.

## Files Overview
- `README.md`: This documentation file.
- `rtl_files.list`: List of RTL files for compilation.
- `Makefile`: Makefile for building and simulating the design.
- `run.do`: Script to run the simulation using VCS.
- `rtl/`: Directory containing the RTL source files.
- `TRAD_TB/`: Directory containing the traditional testbench files.
- `doc/`: Directory containing design specifications and verification plans.

## How to Run Simulation
1. `ssh` to the MCES server (like `auto.ece.pdx.edu`):
    ```
    ssh <your_username>@auto.ece.pdx.edu
    ```
2. Load the Synopsys VCS Package and launch pkg shell:
    ```
    add_pkg_shell
    ```
3. Navigate to the `AHB2APB_Brdg_MS1_Trad` directory.
4. Use the provided `Makefile` to compile and simulate the design:
    ```
    make
    ```
5. The `make` command internally calls `run.do` to run the simulation using VCS.
6. The simulation results and waveforms will be generated in the `waveforms/` directory.
7. To clean up generated files, run:
    ```
    make clean
    ```

