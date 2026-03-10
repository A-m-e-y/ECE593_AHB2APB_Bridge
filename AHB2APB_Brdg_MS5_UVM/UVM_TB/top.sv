import uvm_pkg::*;
`include "uvm_macros.svh"

// controls repeat count in ahb_random_sequence
int TRANSFER = 1;

module tb_top();

    bit hclk;
    bit pclk;

    intf vif (hclk, pclk);

    Bridge_Top DUT (
        .Hclk      (hclk),
        .Pclk      (pclk),
        .Hresetn   (vif.HRESETn),
        .Hwrite    (vif.HWRITE),
        .Hreadyin  (1'b1),
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

    // HCLK 100 MHz, PCLK 50 MHz
    initial hclk = 1'b0;
    always #5 hclk = ~hclk;

    initial pclk = 1'b0;
    always #10 pclk = ~pclk;

    assign vif.HSIZE  = 3'b010;   // 32-bit transfers
    assign vif.HBURST = 3'b000;   // single burst

    // use initial not assign - slave model drives PRDATA procedurally at runtime
    initial vif.PRDATA = 32'h0;

    // tap internal HCLK-domain APB wires before CDC
    assign vif.PENABLE_HCLK = DUT.Penable_hclk;
    assign vif.PWRITE_HCLK  = DUT.Pwrite_hclk;
    assign vif.PSELX_HCLK   = DUT.Pselx_hclk;
    assign vif.PADDR_HCLK   = DUT.Paddr_hclk;
    assign vif.PWDATA_HCLK  = DUT.Pwdata_hclk;

    initial begin
        uvm_config_db#(virtual intf.AHB_DRIVER)::set(null, "*", "vif",     vif);
        uvm_config_db#(virtual intf.AHB_MONITOR)::set(null, "*", "vif",    vif);
        uvm_config_db#(virtual intf.APB_HCLK_MONITOR)::set(null, "*", "apb_vif",       vif);
        uvm_config_db#(virtual intf.APB_SLAVE)::set(       null, "*", "apb_slave_vif", vif);
        uvm_config_db#(virtual intf)::set(             null, "*", "full_vif",       vif);

        `uvm_info("TOPPP", "should run test after this", UVM_DEBUG)
        run_test("ahb_b2b_test");
    end

    initial begin
        $vcdplusfile("ahb2apb_uvm.vpd");
        $vcdpluson(0, tb_top);
        $vcdplusmemon(0, tb_top);
    end

endmodule
