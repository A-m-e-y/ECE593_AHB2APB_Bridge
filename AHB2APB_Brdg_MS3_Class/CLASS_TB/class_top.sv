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

  // clocks
  initial begin
    Hclk = 0;
    forever #5 Hclk = ~Hclk;
  end

  initial begin
    Pclk = 0;
    forever #10 Pclk = ~Pclk;  //slower for CDC
  end

  ahb_apb_if bfm(Hclk, resetn, Pclk);

  // DUT
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

  test main_test;
  
  initial begin
    $dumpfile("tb_class_top.vcd");
    $dumpvars(0, ahb_apb_top);
  end

  initial begin
    $display("\n========================================");
    $display("   Simulation Started");
    $display("========================================\n");
    
    bfm.Hwrite = 0;
    bfm.Hreadyin = 1;
    bfm.Htrans = 2'b00;
    bfm.Hsize = 3'b010;
    bfm.Hburst = 3'b000;
    bfm.Hwdata = 0;
    bfm.Haddr = 0;
    bfm.Prdata = 0;
    
    // reset
    resetn = 1;
    @(posedge Hclk);
    resetn = 0;
    repeat(2) @(posedge Hclk);
    #1 resetn = 1;
    $display("[%0t] Reset released", $time);
    
    wait(bfm.Hreadyout == 1'b1);
    repeat(2) @(posedge Hclk);
    
    // sync with both clks for CDC
    @(negedge Pclk);
    @(posedge Pclk);
    @(posedge Hclk);
    $display("[%0t] Synchronized with both clocks", $time);
    
    main_test = new(bfm);
    main_test.run();
    
    repeat(10) @(posedge Hclk);
    
    dut.cov_inst.display_coverage();
    
    $display("\n========================================");
    $display("   Simulation Completed");
    $display("========================================\n");
    $finish;
  end

  // watchdog
  initial begin
    #500000;
    $display("\n========================================");
    $display("   TIMEOUT: Simulation exceeded 500us");
    $display("========================================\n");
    dut.cov_inst.display_coverage();
    $finish;
  end

endmodule
