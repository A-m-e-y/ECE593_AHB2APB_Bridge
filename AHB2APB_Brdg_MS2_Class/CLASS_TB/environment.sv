
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

    // ========== DIRECTED TEST - Sanity (For Regression) ==========
    task run_sanity_test();
        $display("[%0t] ENVIRONMENT: Starting sanity test", $time);
        
        fork
            gen.sanity_test();
            drv.drive();
            mon.monitor_ahb_apb();
            sb.check_data();
            apb_slv.run();
        join_any
        
        repeat(50) @(posedge vif.Pclk);
        disable fork;
        
        $display("\n[%0t] ENVIRONMENT: All transactions completed\n", $time);
        sb.report();
        apb_slv.display_stats();
        $display("\n[%0t] ENVIRONMENT: Sanity test completed\n", $time);
    endtask
    
    // ========== RANDOMIZED TESTS ==========
    
    // Run randomized test with specific constraint type
    task run_random_test(int num_txns, string test_type = "BASE");
        $display("[%0t] ENVIRONMENT: Starting %s random test (%0d transactions)", 
                 $time, test_type, num_txns);
        
        fork
            gen.generate_random_test(num_txns, test_type);
            drv.drive();
            mon.monitor_ahb_apb();
            sb.check_data();
            apb_slv.run();
        join_any
        
        // Wait for transactions to complete (more time for larger tests)
        repeat(num_txns * 10 + 50) @(posedge vif.Pclk);
        disable fork;
        
        $display("\n[%0t] ENVIRONMENT: %s test completed\n", $time, test_type);
        sb.report();
        apb_slv.display_stats();
    endtask
    
    // Run multi-slave test
    task run_multi_slave_test(int num_txns);
        $display("[%0t] ENVIRONMENT: Starting MULTI-SLAVE test (%0d transactions)", 
                 $time, num_txns);
        
        fork
            gen.generate_multi_slave_test(num_txns);
            drv.drive();
            mon.monitor_ahb_apb();
            sb.check_data();
            apb_slv.run();
        join_any
        
        repeat(num_txns * 10 + 50) @(posedge vif.Pclk);
        disable fork;
        
        $display("\n[%0t] ENVIRONMENT: MULTI-SLAVE test completed\n", $time);
        sb.report();
        apb_slv.display_stats();
    endtask
    
    // Run comprehensive test suite
    task run_comprehensive_test(int txns_per_category);
        $display("\n");
        $display("========================================================================");
        $display("  COMPREHENSIVE COVERAGE TEST - Targeting 100%%");
        $display("========================================================================");
        $display("  Strategy: Random tests + Directed FSM sequences");
        $display("  Transactions per category: %0d", txns_per_category);
        $display("========================================================================\n");
        
        fork
            gen.generate_comprehensive_test_with_sequences(txns_per_category);
            drv.drive();
            mon.monitor_ahb_apb();
            sb.check_data();
            apb_slv.run();
        join_any
        
        // Wait for all transactions to drain
        repeat(txns_per_category * 150) @(posedge vif.Pclk);
        disable fork;
        
        $display("\n");
        $display("========================================================================");
        $display("  COMPREHENSIVE TEST COMPLETED");
        $display("========================================================================\n");
        sb.report();
        apb_slv.display_stats();
    endtask

endclass
