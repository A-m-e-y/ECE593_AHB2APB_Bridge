// `include "intf.sv"
// `include "txn.sv"
// `include "generator.sv"
// `include "driver.sv"
// `include "monitor.sv"
// `include "scoreboard.sv"
// `include "environment.sv"
// `include "test.sv"

module ahb_apb_top;

  logic Hclk, Pclk, resetn;

  // Generate Hclk with 10ns period (100MHz)
  initial begin
    Hclk = 0;
    forever #5 Hclk = ~Hclk;
  end

  // Generate Pclk with 20ns period (50MHz) - slower APB clock for CDC
  initial begin
    Pclk = 0;
    forever #10 Pclk = ~Pclk;
  end

  // Interface instantiation
  ahb_apb_if bfm(Hclk, resetn, Pclk);

  // DUT instantiation
  Bridge_Top dut(
    .Hclk(Hclk),
    .Pclk(Pclk),
    .Hresetn(resetn),
    .Hwrite(bfm.Hwrite),
    .Hreadyin(bfm.Hreadyin),
    .Htrans(bfm.Htrans),
    .Hsize(bfm.Hsize),
    .Hburst(bfm.Hburst),
    .Hwdata(bfm.Hwdata),
    .Haddr(bfm.Haddr),
    .Hrdata(bfm.Hrdata),
    .Hresp(bfm.Hresp),
    .Hreadyout(bfm.Hreadyout),
    .Prdata(bfm.Prdata),
    .Pwdata(bfm.Pwdata),
    .Paddr(bfm.Paddr),
    .Pselx(bfm.Pselx),
    .Pwrite(bfm.Pwrite),
    .Penable(bfm.Penable)
  );

  // Test instantiation and execution
  test main_test;
  
  initial begin
    $dumpfile("tb_class_top.vcd");
    $dumpvars(0, ahb_apb_top);
  end

  initial begin
    $display("\n========================================");
    $display("   Simulation Started");
    $display("========================================\n");
    
    // Initialize signals
    bfm.Hwrite = 0;
    bfm.Hreadyin = 1;
    bfm.Htrans = 2'b00;
    bfm.Hsize = 3'b010;
    bfm.Hburst = 3'b000;
    bfm.Hwdata = 0;
    bfm.Haddr = 0;
    bfm.Prdata = 0;  // Initialize APB read data
    
    // Initialize reset (using pattern from traditional TB)
    resetn = 1;
    @(posedge Hclk);
    resetn = 0;
    repeat(2) @(posedge Hclk);
    #1 resetn = 1;
    $display("[%0t] Reset released", $time);
    
    // Wait for DUT ready
    wait(bfm.Hreadyout == 1'b1);
    repeat(2) @(posedge Hclk);
    
    // **CRITICAL FIX**: Synchronize with Pclk to ensure CDC timing alignment
    // The CDC synchronizer needs Penable_hclk pulses to align with Pclk edges
    // Wait for Pclk negedge, then posedge to ensure we start at a known Pclk phase
    @(negedge Pclk);
    @(posedge Pclk);
    @(posedge Hclk);  // Then sync to Hclk
    $display("[%0t] Synchronized with both clocks", $time);
    
    // Create and run all tests
    main_test = new(bfm);
    main_test.run();
    
    // Wait for test completion
    repeat(10) @(posedge Hclk);
    
    // Display comprehensive coverage report
    dut.cov_inst.display_coverage();
    
    $display("\n========================================");
    $display("   Simulation Completed");
    $display("========================================\n");
    $finish;
  end

  // Watchdog timer - increase for all tests running
  initial begin
    #500000;  // 500us timeout for all tests
    $display("\n========================================");
    $display("   TIMEOUT: Simulation exceeded 500us");
    $display("========================================\n");
    dut.cov_inst.display_coverage();  // Show coverage even on timeout
    $finish;
  end

endmodule
