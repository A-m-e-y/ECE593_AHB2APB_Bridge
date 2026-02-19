
class environment;

    generator gen;
    driver drv;
    monitor mon;
    scoreboard sb;
    apb_slave apb_slv;  // APB slave behavioral model
    
    mailbox #(transaction) gen2driv;
    mailbox #(transaction) driv2sb;
    mailbox #(transaction) mon2sb;
    
    virtual ahb_apb_if vif;

    function new(virtual ahb_apb_if vif);
        this.vif = vif;
    endfunction

    task build();
        gen2driv = new();
        driv2sb = new();
        mon2sb = new();
        
        gen = new(gen2driv);
        drv = new(gen2driv, driv2sb, vif.master);
        mon = new(mon2sb, vif.slave);
        sb = new(driv2sb, mon2sb);
        apb_slv = new(vif.master);  // APB slave uses master modport to drive Prdata
        
        $display("[%0t] ENVIRONMENT: Build phase completed", $time);
    endtask

    // Simple sanity test - sequential execution
    task run_sanity_test();
        $display("[%0t] ENVIRONMENT: Starting sanity test", $time);
        
        fork
            // Generator creates stimulus
            gen.sanity_test();
            
            // Driver continuously drives transactions
            drv.drive();
            
            // Monitor continuously observes
            mon.monitor_ahb_apb();
            
            // Scoreboard continuously checks
            sb.check_data();
            
            // APB slave responds to transactions
            apb_slv.run();
        join_any
        
        // Wait for all transactions to complete
        repeat(50) @(posedge vif.Pclk);  // Wait on slower Pclk for APB completion
        disable fork;
        
        $display("\n[%0t] ENVIRONMENT: All transactions completed\n", $time);
        sb.report();
        apb_slv.display_stats();  // Display APB slave statistics
        $display("\n[%0t] ENVIRONMENT: Sanity test completed\n", $time);
    endtask

endclass
