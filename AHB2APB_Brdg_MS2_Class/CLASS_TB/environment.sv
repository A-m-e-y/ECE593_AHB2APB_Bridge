
class environment;

    generator gen;
    driver drv;
    monitor mon;
    scoreboard sb;
    
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
        join_any
        
        // Wait for all transactions to complete
        repeat(100) @(posedge vif.clk);
        disable fork;
        
        sb.report();
        $display("[%0t] ENVIRONMENT: Sanity test completed", $time);
    endtask

endclass
