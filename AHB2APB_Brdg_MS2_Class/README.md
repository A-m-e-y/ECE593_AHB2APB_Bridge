# AHB-to-APB Bridge Class-Based Testbench

## Overview
This is a complete class-based SystemVerilog testbench for verifying an AHB-to-APB bridge with Clock Domain Crossing (CDC) support.

## Design Under Test (DUT)
The bridge converts transactions from AMBA AHB (Advanced High-performance Bus) to APB (Advanced Peripheral Bus) protocol with the following features:
- **Dual clock domains**: Hclk (100MHz) and Pclk (50MHz)
- **Address mapping**: 0x8000_0000 to 0x8C00_0000 (3 APB slaves)
- **Pipelined architecture** with registered signals
- **CDC handling** using 2-FF synchronizers
- **Burst support**: SINGLE, INCR, WRAP4, INCR4

## Testbench Architecture

```
┌─────────────┐      ┌─────────┐      ┌─────────┐
│  Generator  │─────>│ Driver  │─────>│   DUT   │
└─────────────┘      └─────────┘      └─────────┘
                           │                │
                           v                v
                     ┌─────────────┐  ┌──────────┐
                     │ Scoreboard  │<─│ Monitor  │
                     └─────────────┘  └──────────┘
```

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
├── Makefile                # Build automation
├── run_vcs.sh              # Simulation script
└── README.md               # This file
```

## Running the Testbench

### Prerequisites
- Synopsys VCS simulator
- SystemVerilog support
- Linux/Unix environment

### Compilation and Simulation

**Option 1: Using Makefile**
```bash
# Compile and run
make all

# Compile only
make compile

# Run simulation only (after compilation)
make sim

# Clean generated files
make clean
```

**Option 2: Using shell script**
```bash
chmod +x run_vcs.sh
./run_vcs.sh
```

**Option 3: Manual VCS commands**
```bash
# Compile
vcs -sverilog -full64 -timescale=1ns/1ps -debug_access+all -f filelist.f -l compile.log

# Run
./simv -l simulation.log
```

## Test Coverage

The testbench includes 10 test scenarios, each run 5 times:
1. Write single halfword
2. Read single halfword
3. Write single byte
4. Read incremental halfword burst
5. Write incremental word burst
6. Read WRAP4 byte burst
7. Write WRAP4 halfword burst
8. Read WRAP4 word burst
9. Write INCR4 byte burst
10. Read INCR4 halfword burst

## Clock Configuration

- **Hclk**: 10ns period (100MHz) - AHB side
- **Pclk**: 20ns period (50MHz) - APB side
- CDC synchronizers handle the clock domain crossing

## Key Features

✅ Full OOP-based testbench architecture  
✅ Constrained-random stimulus generation  
✅ Functional coverage collection  
✅ Self-checking with scoreboard  
✅ Memory model for read/write verification  
✅ CDC-aware design  
✅ Modular and reusable components  
✅ Comprehensive logging and reporting  

## Expected Output

During simulation, you should see:
- Transaction generation logs from Generator
- Drive operations from Driver
- Monitoring logs from Monitor
- Pass/Fail checks from Scoreboard
- Final statistics report

Example:
```
[100] DRIVER: Driving transaction - Haddr=0x80000010 Hwrite=1 Htrans=10
[120] MONITOR: Haddr=0x80000010 Hwrite=1 Paddr=0x80000010 Pwrite=1
[130] SCOREBOARD PASS: Write to addr=0x80000010 data=0x12345678
```

## Debugging

If compilation fails:
1. Check `compile.log` for syntax errors
2. Verify RTL path in `filelist.f`
3. Ensure all files are present

If simulation fails:
1. Check `simulation.log` for runtime errors
2. Verify reset timing
3. Check clock generation

## Notes

- The testbench uses SystemVerilog classes and mailboxes
- All components communicate via mailbox passing
- The scoreboard maintains a golden memory model
- Coverage is automatically collected during simulation
- Includes proper reset sequencing and clock initialization

## Future Enhancements

Potential improvements:
- Add assertion-based verification (SVA)
- Extend coverage with more corner cases
- Add UVM framework support
- Include timing checks
- Add error injection scenarios
