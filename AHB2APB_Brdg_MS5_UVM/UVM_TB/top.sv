import uvm_pkg::*;
`include "uvm_macros.svh"

// Global settings
int TRANSFER = 1;  // number of SEQ+IDLE repeats after the initial NONSEQ (1 = single burst)

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

    // Tap HCLK-domain APB signals directly from Bridge_Top's internal wires.
    // These are the registered outputs of APB_FSM_Controller *before* the 2-FF
    // CDC synchronizer, so the APB monitor can observe them without CDC risk.
    assign vif.PENABLE_HCLK = DUT.Penable_hclk;
    assign vif.PWRITE_HCLK  = DUT.Pwrite_hclk;
    assign vif.PSELX_HCLK   = DUT.Pselx_hclk;
    assign vif.PADDR_HCLK   = DUT.Paddr_hclk;
    assign vif.PWDATA_HCLK  = DUT.Pwdata_hclk;

    // UVM setup
    initial begin
        uvm_config_db#(virtual intf.AHB_DRIVER)::set(null, "*", "vif",     vif);
        uvm_config_db#(virtual intf.AHB_MONITOR)::set(null, "*", "vif",    vif);
        uvm_config_db#(virtual intf.APB_HCLK_MONITOR)::set(null, "*", "apb_vif", vif);

        `uvm_info("TOPPP", "should run test after this", UVM_DEBUG)
        run_test("ahb_b2b_test");
    end

    
    // waveforms
    initial begin
        $vcdplusfile("ahb2apb_uvm.vpd");
        $vcdpluson(0, tb_top);
        $vcdplusmemon(0, tb_top);
    end

endmodule