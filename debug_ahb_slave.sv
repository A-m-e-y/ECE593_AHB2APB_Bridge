// Debug testbench to trace AHB_Slave_Interface internal states

module debug_ahb_slave;

  reg        Hclk;
  reg        Pclk;
  reg        Hresetn;
  reg        Presetn;
  reg        Hwrite;
  reg        Hreadyin;
  reg [1:0]  Htrans;
  reg [31:0] Haddr;
  reg [31:0] Hwdata;
  wire       Hreadyout;
  wire       Hresp;
  wire [31:0] Hrdata;
  wire [2:0] Pselx;
  wire [31:0] Paddr;
  wire       Pwrite;
  wire       Penable;
  wire [31:0] Pwdata;
  wire [31:0] Prdata;

  // Clock generation
  initial Hclk = 0;
  always #5 Hclk = ~Hclk;
  
  initial Pclk = 0;
  always #10 Pclk = ~Pclk;

  // Instantiate DUT
  Bridge_Top dut (
    .Hclk(Hclk),
    .Pclk(Pclk),
    .Hresetn(Hresetn),
    .Presetn(Presetn),
    .Hwrite(Hwrite),
    .Hreadyin(Hreadyin),
    .Htrans(Htrans),
    .Haddr(Haddr),
    .Hwdata(Hwdata),
    .Prdata(Prdata),
    .Hreadyout(Hreadyout),
    .Hresp(Hresp),
    .Hrdata(Hrdata),
    .Pselx(Pselx),
    .Paddr(Paddr),
    .Pwrite(Pwrite),
    .Penable(Penable),
    .Pwdata(Pwdata)
  );

  assign Prdata = 32'hBEEF_CAFE;

  // Monitor internal AHB slave state
  always @(posedge Hclk) begin
    $display("[%0t] AHB: Htrans=%b addr=%h wdata=%h | valid_int=%b addr_phase=%b pending=%b | next_addr_phase=%b next_addr=%h | buffer_full=%b Hreadyout=%b",
      $time, Htrans, Haddr, Hwdata,
      dut.AHBSlave.valid_int,
      dut.AHBSlave.addr_phase,
      dut.AHBSlave.pending_req,
      dut.AHBSlave.next_addr_phase,
      dut.AHBSlave.next_addr,
      dut.h_buffer_full,
      Hreadyout
    );
  end

  // Monitor request firing
  always @(posedge Hclk) begin
    if (dut.AHBSlave.req_fire) begin
      $display("[%0t] >>> REQ_FIRE: addr=%h wdata=%h write=%b sel=%b",
        $time,
        dut.AHBSlave.req_addr,
        dut.AHBSlave.req_wdata,
        dut.AHBSlave.req_write,
        dut.AHBSlave.req_sel
      );
    end
  end

  // Monitor APB activity
  always @(posedge Pclk) begin
    if (Penable) begin
      $display("[%0t] APB ACCESS: sel=%b addr=%h wdata=%h write=%b",
        $time, Pselx, Paddr, Pwdata, Pwrite
      );
    end
  end

  initial begin
    $dumpfile("waveforms/debug_ahb_slave.vcd");
    $dumpvars(0, debug_ahb_slave);

    // Reset
    Hresetn = 0;
    Presetn = 0;
    Hwrite = 0;
    Hreadyin = 1;
    Htrans = 2'b00;
    Haddr = 32'h0;
    Hwdata = 32'h0;

    repeat(3) @(posedge Hclk);
    Hresetn = 1;
    Presetn = 1;
    @(posedge Hclk);

    $display("\n=== Starting 4 Transactions with TRUE PIPELINING ===\n");

    // Transaction 1 - Address Phase only
    wait(Hreadyout == 1'b1);
    @(posedge Hclk);
    Hreadyin = Hreadyout;
    #1;
    Hwrite = 1'b1;
    Htrans = 2'b10;
    Haddr = 32'h8000_0004;
    $display("[%0t] >>> TB: Trans1 ADDR=%h", $time, Haddr);
    
    // Transaction 1 Data + Transaction 2 Address (PIPELINED!)
    wait(Hreadyout == 1'b1);
    @(posedge Hclk);
    Hreadyin = Hreadyout;
    #1;
    Hwdata = 32'hA5A5_5A5A;
    Htrans = 2'b10;
    Haddr = 32'h8000_00FF;
    $display("[%0t] >>> TB: Trans1 DATA=%h + Trans2 ADDR=%h", $time, Hwdata, Haddr);
    
    // Transaction 2 Data + Transaction 3 Address (PIPELINED!)
    wait(Hreadyout == 1'b1);
    @(posedge Hclk);
    Hreadyin = Hreadyout;
    #1;
    Hwdata = 32'hAEAE_AEAE;
    Htrans = 2'b10;
    Haddr = 32'h8000_0011;
    $display("[%0t] >>> TB: Trans2 DATA=%h + Trans3 ADDR=%h", $time, Hwdata, Haddr);
    
    // Transaction 3 Data + Transaction 4 Address (PIPELINED!)
    wait(Hreadyout == 1'b1);
    @(posedge Hclk);
    Hreadyin = Hreadyout;
    #1;
    Hwdata = 32'hFEFE_FEFE;
    Htrans = 2'b10;
    Haddr = 32'h8000_0022;
    $display("[%0t] >>> TB: Trans3 DATA=%h + Trans4 ADDR=%h", $time, Hwdata, Haddr);
    
    // Transaction 4 Data Phase (final)
    wait(Hreadyout == 1'b1);
    @(posedge Hclk);
    Hreadyin = Hreadyout;
    #1;
    Hwdata = 32'hDEAD_DEAD;
    Htrans = 2'b00;
    $display("[%0t] >>> TB: Trans4 DATA=%h", $time, Hwdata);

    repeat(100) @(posedge Hclk);
    $display("\n=== Test Complete (or Timeout) ===\n");
    $finish;
  end
  
  // Timeout watchdog
  initial begin
    repeat(500) @(posedge Hclk);
    $display("\n!!! TIMEOUT - Test took too long !!!\n");
    $finish;
  end

endmodule
