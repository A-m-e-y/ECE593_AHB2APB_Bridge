
class test;

    environment env;
    virtual ahb_apb_if vif;

    function new(virtual ahb_apb_if vif);
        this.vif = vif;
    endfunction

    task run();
        $display("\n========================================");
        $display("   AHB2APB Sanity Test Started");
        $display("========================================\n");
        
        env = new(vif);
        env.build();
        
        // Wait a few clocks before starting
        repeat(5) @(posedge vif.clk);
        
        // Run simple sanity test
        env.run_sanity_test();
        
        // Wait a few clocks after completion
        repeat(10) @(posedge vif.clk);
        
        $display("\n========================================");
        $display("   AHB2APB Sanity Test Ended");
        $display("========================================\n");
    endtask

endclass
