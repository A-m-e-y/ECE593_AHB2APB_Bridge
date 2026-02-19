// coverage bind file
`ifndef COVERAGE_BIND_SV
`define COVERAGE_BIND_SV

bind Bridge_Top coverage_collector cov_inst (
    .Hclk        (Hclk),
    .Pclk        (Pclk),
    .Hresetn     (Hresetn),
    
    // AHB
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
    
    // APB
    .Paddr       (Paddr),
    .Pwdata      (Pwdata),
    .Prdata      (Prdata),
    .Pselx       (Pselx),
    .Penable     (Penable),
    .Pwrite      (Pwrite),
    
    .fsm_state   (APBControl.PRESENT_STATE),
    .valid       (AHBSlave.valid)
);

`endif
