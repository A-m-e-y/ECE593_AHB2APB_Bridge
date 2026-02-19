// ============================================================================
// Coverage Bind File
// ============================================================================
// This file binds the coverage collector module to the DUT for
// comprehensive functional and code coverage collection
// ============================================================================

`ifndef COVERAGE_BIND_SV
`define COVERAGE_BIND_SV

// Bind coverage collector to the top-level DUT
bind Bridge_Top coverage_collector cov_inst (
    // Clocks and Reset
    .Hclk        (Hclk),
    .Pclk        (Pclk),  // Need to add Pclk input to Bridge_Top or connect from top
    .Hresetn     (Hresetn),
    
    // AHB Interface
    .Haddr       (Haddr),
    .Hwdata      (Hwdata),
    .Hrdata      (Hrdata),
    .Htrans      (Htrans),
    .Hwrite      (Hwrite),
    .Hreadyin    (Hreadyin),
    .Hreadyout   (Hreadyout),
    .Hresp       (Hresp),
    .Hsize       (Hsize),
    .Hburst      (Hburst),
    
    // APB Interface
    .Paddr       (Paddr),
    .Pwdata      (Pwdata),
    .Prdata      (Prdata),
    .Pselx       (Pselx),
    .Penable     (Penable),
    .Pwrite      (Pwrite),
    
    // FSM State from APB_FSM_Controller
    .fsm_state   (APBControl.PRESENT_STATE),
    
    // Internal valid signal from AHB_Slave_Interface
    .valid       (AHBSlave.valid)
);

`endif // COVERAGE_BIND_SV
