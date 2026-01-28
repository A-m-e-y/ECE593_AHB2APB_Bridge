`timescale 1ns/1ps

module tb_sanity_check;
  // AHB-lite signals
  reg        Hclk;
  reg        Hresetn;
  reg        Pclk;
  reg        Presetn;
  reg        Hwrite;
  reg        Hreadyin;
  reg [1:0]  Htrans;
  reg [31:0] Hwdata;
  reg [31:0] Haddr;
  reg [31:0] Prdata;

  //APB signals
  wire       Penable;
  wire       Pwrite;
  wire       Hreadyout;
  wire [1:0] Hresp;
  wire [2:0] Pselx;
  wire [31:0] Paddr;
  wire [31:0] Pwdata;
  wire [31:0] Hrdata;

  // DUT
  Bridge_Top dut (
    .Hclk(Hclk),
    .Hresetn(Hresetn),
    .Pclk(Pclk),
    .Presetn(Presetn),
    .Hwrite(Hwrite),
    .Hreadyin(Hreadyin),
    .Hreadyout(Hreadyout),
    .Hwdata(Hwdata),
    .Haddr(Haddr),
    .Htrans(Htrans),
    .Prdata(Prdata),
    .Penable(Penable),
    .Pwrite(Pwrite),
    .Pselx(Pselx),
    .Paddr(Paddr),
    .Pwdata(Pwdata),
    .Hresp(Hresp),
    .Hrdata(Hrdata)
  );

  // Clock
  always #5 Hclk = ~Hclk;
  always #10 Pclk = ~Pclk;

  initial begin
    $dumpfile("waveforms/tb_sanity_check.vcd");
    $dumpvars(0, tb_sanity_check);
  end

  initial begin
    // init
    Hclk     = 1'b0;
    Hresetn  = 1'b0;
    Pclk     = 1'b0;
    Presetn  = 1'b0;
    Hwrite   = 1'b0;
    Hreadyin = 1'b1;
    Htrans   = 2'b00;
    Hwdata   = 32'h0;
    Haddr    = 32'h0;
    Prdata   = 32'h0;

    // reset deassert
    repeat (2) @(posedge Hclk);
    #1 Hresetn = 1'b1;
    #1 Presetn = 1'b1;

    // Four AHB write transactions with proper flow control
    // Wait for Hreadyout=1 before presenting each new address phase
    
    // TRUE AHB PIPELINING:
    // Address phase of Trans(N+1) overlaps with Data phase of Trans(N)
    
    // Transaction 1 - Address Phase
    wait(Hreadyout == 1'b1);
    @(posedge Hclk);
    Hreadyin = Hreadyout;
    #1;
    Hwrite = 1'b1;
    Htrans = 2'b10; // NONSEQ
    Haddr  = 32'h8000_0004;
    $display("[%0t] TB: Trans1 addr=%h", $time, Haddr);
    
    // Transaction 1 Data + Transaction 2 Address (PIPELINED!)
    wait(Hreadyout == 1'b1);
    @(posedge Hclk);
    Hreadyin = Hreadyout;
    #1;
    Hwdata = 32'hA5A5_5A5A;
    Htrans = 2'b10; // NONSEQ for Trans2
    Haddr  = 32'h8000_0055;
    $display("[%0t] TB: Trans1 data=%h, Trans2 addr=%h", $time, Hwdata, Haddr);
    
    // Transaction 2 Data + Transaction 3 Address (PIPELINED!)
    wait(Hreadyout == 1'b1);
    @(posedge Hclk);
    Hreadyin = Hreadyout;
    #1;
    Hwdata = 32'hEAEA_EAEA;
    Htrans = 2'b10; // NONSEQ for Trans3
    Haddr  = 32'h8000_0066;
    $display("[%0t] TB: Trans2 data=%h, Trans3 addr=%h", $time, Hwdata, Haddr);
    
    // Transaction 3 Data + Transaction 4 Address (PIPELINED!)
    wait(Hreadyout == 1'b1);
    @(posedge Hclk);
    Hreadyin = Hreadyout;
    #1;
    Hwdata = 32'hBABA_BABA;
    Htrans = 2'b10; // NONSEQ for Trans4
    Haddr  = 32'h8000_0077;
    $display("[%0t] TB: Trans3 data=%h, Trans4 addr=%h", $time, Hwdata, Haddr);
    
    // Transaction 4 Data Phase (final)
    wait(Hreadyout == 1'b1);
    @(posedge Hclk);
    Hreadyin = Hreadyout;
    #1;
    Hwdata = 32'hDEAD_BEEF;
    Htrans = 2'b00; // IDLE - no more transactions
    $display("[%0t] TB: Trans4 data=%h", $time, Hwdata);

    // Haddr  = 32'h8000_0088;
    // $display("[%0t] TB: Trans5 addr=%h", $time, Haddr);

    // Wait for all to complete
    repeat (30) begin
      @(posedge Hclk);
      Hreadyin = Hreadyout;
    end
    $finish;
  end

  // Simple observation
  always @(posedge Hclk) begin
    $display("[%0t] APB sel=%b addr=%h wdata=%h en=%b | Hrdy=%b Hreadyin=%b Htrans=%b", 
             $time, Pselx, Paddr, Pwdata, Penable, Hreadyout, Hreadyin, Htrans);
  end

endmodule
