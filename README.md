# ECE593_AHB2APB_Bridge
This is a Final Project repo for ECE 593 AHB2APB Bridge

## Sanity Check Testbench Working
- The sanity check testbench is implemented in `tb_sanity_check.sv`.
- It tests for a simple AHB to APB write transaction.

### Expected Output in waveform:
Waveform Breakdown
- IDLE State (Before Setup)
    All signals inactive; PSEL, PENABLE, PWRITE are low.
- Setup Phase (Clock Cycle 1)
    PCLK (Rising Edge): Master asserts desired slave's PSELx (e.g., PSEL1) high.
    PCLK (Rising Edge): Master drives the target PADDR.
    PCLK (Rising Edge): Master drives PWRITE high (for write).
    PCLK (Rising Edge): Master places data on PWDATA.
    PENABLE remains low.
- Access Phase (Clock Cycle 2 - No Wait States)
    PCLK (Next Rising Edge): PENABLE goes high.
    PCLK (Next Rising Edge): Slave asserts PREADY high, signaling completion.
    PCLK (Next Rising Edge): Write data on PWDATA is accepted by the slave (valid by this point).
    PCLK (Next Rising Edge): Bus returns to IDLE, or moves to next Setup phase if more transfers are pending. 