# AHB-to-APB Bridge Class-Based Testbench

## Overview
This is a complete class-based SystemVerilog testbench for verifying an AHB-to-APB bridge with Clock Domain Crossing (CDC) support.

### Components

#### 1. **Transaction Class** (`txn.sv`)
- Randomized AHB/APB signal fields
- Coverage groups for functional coverage
- Constraint support for valid address ranges

#### 2. **Generator Class** (`generator.sv`)
- Creates stimulus transactions
- 10 test scenarios covering different:
  - Transfer sizes (byte, halfword, word)
  - Burst types (single, incr, wrap4, incr4)
  - Read/write operations

#### 3. **Driver Class** (`driver.sv`)
- Drives AHB inputs to DUT
- Uses clocking blocks for synchronization
- Handles write data phase properly

#### 4. **Monitor Class** (`monitor.sv`)
- Passively observes DUT outputs
- Captures both AHB and APB signals
- Sends observed transactions to scoreboard

#### 5. **Scoreboard Class** (`scoreboard.sv`)
- Maintains internal memory model
- Compares expected vs actual behavior
- Reports pass/fail statistics

#### 6. **Environment Class** (`environment.sv`)
- Instantiates all verification components
- Manages mailbox connections
- Provides test execution framework

#### 7. **Test Class** (`test.sv`)
- Top-level test orchestration
- Runs comprehensive test suite

#### 8. **Interface** (`intf.sv`)
- Bundles all DUT signals
- Provides clocking blocks for driver and monitor
- Modports for master (driver) and slave (monitor)

## File Structure

```
AHB2APB_Brdg_MS2_Class/
├── CLASS_TB/
│   ├── txn.sv              # Transaction class
│   ├── generator.sv        # Stimulus generator
│   ├── driver.sv           # AHB driver
│   ├── monitor.sv          # Output monitor
│   ├── scoreboard.sv       # Checker
│   ├── environment.sv      # Integration layer
│   ├── test.sv             # Test scenarios
│   ├── intf.sv             # Interface definition
│   ├── coverage.sv         # (placeholder)
│   └── class_top.sv        # Top module
├── RTL/ (in parent directory)
│   ├── Bridge_Top.sv
│   ├── AHB_Slave_Interface.sv
│   ├── APB_FSM_Controller.sv
│   └── CDC_Handler.sv
├── filelist.f              # VCS file list
├── compile.log             # VCS compile log (Transcript part 1)
├── simulate.log            # VCS simulate log (Transcript part 2)
├── Makefile                # Build automation
└── README.md               # This file
```

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