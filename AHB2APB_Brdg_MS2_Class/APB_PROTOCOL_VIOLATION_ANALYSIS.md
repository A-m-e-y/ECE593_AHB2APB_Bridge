# APB Protocol Violation Analysis - PSEL and PENABLE Timing

## Issue Summary
PSEL (Pselx) and PENABLE signals go high **simultaneously** in the Pclk domain, violating the APB protocol requirement for separate SETUP and ACCESS phases.

## APB Protocol Requirement

According to APB specification, a transaction should have two phases:
1. **SETUP Phase**: PSEL = 1, PENABLE = 0 (at least 1 Pclk cycle)
2. **ACCESS Phase**: PSEL = 1, PENABLE = 1 (1 Pclk cycle)

## Observed Behavior (Both Traditional and Class TB)

```
Time 190000ps (Pclk posedge):
- Pselx_pclk: 000 → 001
- Penable_pclk: 0 → 1
- Pwrite_pclk: 0 → 1

All signals transition TOGETHER - NO SETUP phase!
```

## Root Cause Analysis

### 1. FSM Behavior in Hclk Domain ✅ CORRECT

The FSM **does** create proper SETUP/ACCESS separation in the Hclk domain:

**State Flow for Write Transaction:**
- **ST_WWAIT** (SETUP): Pselx_temp = tempselx, **Penable_temp = 0**
- **ST_WRITE** (ACCESS): Pselx_temp = tempselx, **Penable_temp = 1**

**VCD Evidence (Hclk domain @100MHz):**
```
Time 155ns: Pselx_hclk = 001, Penable_hclk = 0  ← SETUP phase
Time 165ns: Pselx_hclk = 001, Penable_hclk = 1  ← ACCESS phase
```

Separation: **10ns** (one Hclk cycle) ✓

### 2. CDC Synchronizer Behavior ✗ PROBLEM

The CDC_Handler uses a simple 2-FF synchronizer that samples ALL signals on the **same Pclk edge**:

```systemverilog
always @(posedge Pclk) begin
    if (~Hresetn) begin
        Penable_sync1 <= 0;
        Pselx_sync1 <= 0;
        // ...
    end
    else begin
        Penable_sync1 <= Penable_hclk;  // Both sampled
        Pselx_sync1 <= Pselx_hclk;      // on SAME edge!
        // ...
    end
end
```

**Timeline of what happens:**

| Time | Event | Hclk Domain | Pclk Domain |
|------|-------|-------------|-------------|
| 155ns | Hclk posedge | Pselx_hclk=001, Penable_hclk=0 | - |
| 165ns | Hclk posedge | Pselx_hclk=001, Penable_hclk=1 | - |
| 170ns | **Pclk posedge** | Pselx_hclk=001, Penable_hclk=1 | sync1: **Both sampled together!** |
| 190ns | **Pclk posedge** | - | sync2→output: **Both appear together!** |

**The Problem**: 
- Pselx_hclk goes high at 155ns
- Penable_hclk goes high at 165ns (10ns later)
- But the FIRST Pclk edge that samples them is at 170ns - by then **both are already high**!
- The 10ns separation in Hclk domain is **lost** because it's smaller than half the Pclk period (20ns/2 = 10ns)

### 3. Conclusion: DUT CDC Design Flaw

**This is a DUT CDC design issue**, present in both traditional and class-based testbenches.

The simple 2-FF synchronizer is fundamentally unable to preserve the temporal ordering of signals when:
- The delay between signals (10ns) is equal to or less than the destination clock period (20ns)
- Both signals are synchronized independently on the same destination clock edge

## Why This Wasn't Caught Earlier

1. **Functional correctness**: The bridge still transfers data correctly (writes/reads work)
2. **APB slave tolerance**: Most APB slaves will accept transactions even without proper SETUP phase
3. **Simulation focus**: Previous verification likely focused on data integrity, not protocol timing
4. **Common oversight**: CDC for control signals is often under-specified in academic designs

## Impact Assessment

### Protocol Violation Severity: **MODERATE**

**Pros (why it might still work):**
- APB slaves typically sample on PENABLE rising edge
- Data/address are still valid when PENABLE asserts
- No data corruption - functional behavior is correct

**Cons (why this is problematic):**
- Violates APB specification
- APB slaves expecting SETUP phase won't work correctly
- Setup timing constraints for addr/data might not be met
- Not synthesizable for some APB slave combinations
- Fails protocol compliance checkers

## Possible Solutions

### Option 1: Extend SETUP Phase in FSM (Recommended)

Modify FSM to hold Pselx high for **at least 2 Hclk cycles** before asserting Penable:

```systemverilog
// Add new state ST_SETUP between ST_WWAIT and ST_WRITE
ST_WWAIT → ST_SETUP → ST_WRITE → ST_WENABLEP

ST_SETUP: begin
    Pselx_temp = tempselx;  // PSEL high
    Penable_temp = 0;       // PENABLE low
    // Hold for at least 20ns (2 Hclk cycles) to guarantee
    // Pclk samples SETUP phase before ACCESS phase
end
```

**Benefit**: Guarantees at least one Pclk cycle with PSEL=1, PENABLE=0

### Option 2: Run APB Control Signals Directly on Hclk

Remove CDC for APB control signals (Pselx, Penable, Pwrite). Only synchronize data signals.

**Pro**: Preserves FSM timing exactly
**Con**: APB slaves must tolerate Hclk-timed control signals (may cause metastability)

### Option 3: Multi-Cycle Handshake

Implement a proper handshake between Hclk and Pclk domains:
- FSM asserts 'request' when transaction starts
- Pclk side generates proper SETUP→ACCESS phases
- Pclk side acknowledges back to Hclk when complete

**Pro**: Fully protocol compliant
**Con**: Significant RTL redesign required

### Option 4: Accept As-Is (Academic Context)

Document the limitation and accept that this is a simplified CDC implementation for academic purposes.

**Pro**: No changes needed
**Con**: Not compliant with APB spec

## Recommendation

**For Academic Project**: Document as known limitation. The design is functionally correct for data transfer.

**For Production**: Implement Option 1 (extend SETUP phase) - minimal change, guaranteed protocol compliance.

## Files Affected

**RTL:**
- `rtl/APB_FSM_Controller.sv` - Would need new state for extended SETUP phase
- `rtl/CDC_Handler.sv` - No change needed if using Option 1

**Testbench:**
- No changes needed - issue is in DUT design

## References

- ARM APB Protocol Specification v2.0, Section 2.2: "Transfer with no wait states"
- CDC design best practices: "Synchronizing Multi-bit Signals Requires Additional Care"
