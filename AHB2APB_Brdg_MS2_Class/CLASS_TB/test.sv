
class test;

    environment env;
    virtual ahb_apb_if vif;

    function new(virtual ahb_apb_if vif);
        this.vif = vif;
    endfunction

    task run();
        $display("\n========================================================================");
        $display("   AHB2APB Bridge Comprehensive Verification Suite");
        $display("========================================================================");
        $display("   Running all tests sequentially to achieve maximum coverage!");
        $display("========================================================================\n");
        
        env = new(vif);
        env.build();
        
        repeat(5) @(posedge vif.clk);
        
        // sanity check first
        $display("\n[TEST 1/5] Running SANITY test (regression baseline)...\n");
        env.run_sanity_test();
        repeat(10) @(posedge vif.clk);
        
        $display("\n[TEST 2/5] Running RAND_SMALL test...\n");
        env.run_random_test(1000, "BASE");
        repeat(10) @(posedge vif.clk);
        
        $display("\n[TEST 3/5] Running RAND_MEDIUM test...\n");
        env.run_random_test(200, "WRITE_ONLY");
        repeat(10) @(posedge vif.clk);
        env.run_random_test(200, "SEQ_TRANS");
        repeat(10) @(posedge vif.clk);
        env.run_random_test(200, "NONSEQ_TRANS");
        repeat(10) @(posedge vif.clk);
        env.run_random_test(200, "READ_ONLY");
        repeat(10) @(posedge vif.clk);
        
        $display("\n[TEST 4/5] Running MULTI_SLAVE test...\n");
        env.run_multi_slave_test(60);
        repeat(10) @(posedge vif.clk);
        
        // big test with directed sequences
        $display("\n[TEST 5/5] Running COMPREHENSIVE test...\n");
        env.run_comprehensive_test(20);
        repeat(10) @(posedge vif.clk);
        
        $display("\n========================================================================");
        $display("   All Tests Completed Successfully");
        $display("========================================================================\n");
    endtask

endclass
