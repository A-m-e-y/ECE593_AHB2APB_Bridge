import uvm_pkg::*;
`include "uvm_macros.svh"

// Global settings
int TRANSFER = 2;  // number of transactions to be generated

module tb_top();

    bit clk;

    // AHB and APB interface instantiation (Bus Functional Models - BFMs)
    intf vif (clk);  // AHB interface

    // DUT instantiation/connection
    Bridge_Top DUT (
        .Hclk(clk),
        .Hresetn(vif.HRESETn),
        .Hwrite(vif.HWRITE),
        .Hreadyin(1'b1),           	// force it to '1 i.e be ready always
        .Htrans(vif.HTRANS),
        .Hwdata(vif.HWDATA),
        .Haddr(vif.HADDR),
        .Hrdata(vif.HRDATA),
        .Hresp(vif.HRESP),
        .Hreadyout(vif.HREADY)
    );
    
    // Clock generation block
    initial begin
        clk = 1'b0;
        forever
            #5 clk = ~clk;
    end
    
    
    // Initialization block 
    initial begin
        // Set the virtual interface handles to the config_db
	uvm_config_db#(virtual intf.AHB_DRIVER)::set(null,"*","vif",vif);
	uvm_config_db#(virtual intf.AHB_MONITOR)::set(null,"*","vif",vif);
        
	`uvm_info("TOPPP","should run test after this",UVM_DEBUG)

        run_test("ahb_apb_random_test");
    end

endmodule