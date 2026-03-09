import uvm_pkg::*;
`include "uvm_macros.svh"

// Global settings
int TRANSFER = 2;  // number of transactions to be generated

module tb_top();

    bit hclk;
    bit pclk;

    // Interface instantiation with both clocks
    intf vif (hclk, pclk);

    // DUT instantiation — all ports connected
    Bridge_Top DUT (
        .Hclk      (hclk),
        .Pclk      (pclk),
        .Hresetn   (vif.HRESETn),
        .Hwrite    (vif.HWRITE),
        .Hreadyin  (1'b1),            // no upstream slave; always ready
        .Hreadyout (vif.HREADY),
        .Htrans    (vif.HTRANS),
        .Hwdata    (vif.HWDATA),
        .Haddr     (vif.HADDR),
        .Hsize     (vif.HSIZE),
        .Hburst    (vif.HBURST),
        .Hrdata    (vif.HRDATA),
        .Hresp     (vif.HRESP),
        .Prdata    (vif.PRDATA),
        .Penable   (vif.PENABLE),
        .Pwrite    (vif.PWRITE),
        .Pselx     (vif.PSELX),
        .Paddr     (vif.PADDR),
        .Pwdata    (vif.PWDATA)
    );

    // HCLK: 100 MHz (10 ns period)
    initial hclk = 1'b0;
    always #5 hclk = ~hclk;

    // PCLK: 50 MHz (20 ns period), phase-aligned with HCLK
    initial pclk = 1'b0;
    always #10 pclk = ~pclk;

    // Default drives for signals without a dedicated agent
    // HSIZE: 3'b010 = 32-bit word transfers; HBURST: 3'b000 = single
    assign vif.HSIZE  = 3'b010;
    assign vif.HBURST = 3'b000;
    // PRDATA: no APB slave model yet; drive 0 so reads return cleanly
    assign vif.PRDATA = 32'h0;

    // UVM setup
    initial begin
        uvm_config_db#(virtual intf.AHB_DRIVER)::set(null, "*", "vif", vif);
        uvm_config_db#(virtual intf.AHB_MONITOR)::set(null, "*", "vif", vif);

        `uvm_info("TOPPP", "should run test after this", UVM_DEBUG)
        run_test("ahb_apb_random_test");
    end

endmodule