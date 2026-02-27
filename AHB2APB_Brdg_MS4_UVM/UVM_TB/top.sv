import uvm_pkg::*;
`include "uvm_macros.svh"

// Global settings
int TRANSFER = 500;  // number of transactions to be generated

// Including necessary sequence items, environment configurations, and components
`include "sequence_item.sv" //COMBINE TO ONE
//`include "apb_sequence_item.sv" //COMBINE TO ONE
//`include "ahb_apb_env_config.sv"

// Including AHB Components
`include "sequencer.sv" 
`include "driver.sv"
`include "monitor.sv"
`include "ahb_agent.sv"

// Including APB Components
//`include "apb_sequencer.sv"
//`include "apb_driver.sv"
//`include "apb_monitor.sv"
//`include "apb_agent.sv"

// Including scoreboard and environment
`include "scoreboard.sv"
`include "ahb2apb_env.sv"

// Including sequences and tests
`include "sequence.sv"
//`include "apb_sequence.sv"
//`include "ahb_apb_test.sv"
`include "base_test.sv"
//`include "ahb_apb_burst_test.sv"

module tb_top();

    bit clk;

    // AHB and APB interface instantiation (Bus Functional Models - BFMs)
    intf vif (clk);  // AHB interface
    //apb_intf APB_INF (clk);  // APB interface

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
        .Hreadyout(vif.HREADY),

		// Only one APB interface implemented, this one interface
		// will mimic different slaves connected to the bridge
        /*
        .Prdata(APB_INF.PRDATA[0]),	
        .Pwdata(APB_INF.PWDATA),
        .Paddr(APB_INF.PADDR),
        .Pselx(APB_INF.PSELx[2:0]),
        .Pwrite(APB_INF.PWRITE),
        .Penable(APB_INF.PENABLE) */
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
        uvm_config_db # (virtual intf)::set(null,"*","vif",vif); 
        //uvm_config_db # (virtual apb_intf)::set(null,"*","apb_vif",APB_INF);

        
        // run_test("ahb_apb_single_write_test");
        // run_test("ahb_apb_single_read_test");
        run_test("ahb_apb_random_test");
        // run_test("ahb_apb_burst_read_test");
    end

endmodule