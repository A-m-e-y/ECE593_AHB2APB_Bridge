`timescale 1ns/1ps

module debug_tb;
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
    $dumpfile("waveforms/debug_tb.vcd");
    $dumpvars(0, debug_tb);
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

    // One AHB write transaction to valid APB slave 0 range
    @(posedge Hclk);
    #1;
    Hwrite   = 1'b1;
    Htrans   = 2'b10; // NONSEQ
    Haddr    = 32'h8000_0004;
    Hreadyin = 1'b1;

    @(posedge Hclk);
    #1;
    Htrans = 2'b10; // NONSEQ - second transaction
    Hwdata = 32'hA5A5_5A5A;
    Haddr  = 32'h8000_00FF;

    @(posedge Hclk);
    #1;
    Htrans = 2'b00; // IDLE
    Hwdata = 32'hDEAD_DEAD;

    @(posedge Hclk);
    #1;
    Hwdata = 32'h0;

    // allow APB side to complete both transactions
    repeat (40) @(posedge Hclk);
    $finish;
  end

  // Debug observation
  always @(posedge Hclk) begin
    $display("[%0t] Hclk: Haddr=%h Htrans=%b Hwrite=%b Hwdata=%h valid_int=%b pending=%b addr_phase=%b next_addr_phase=%b | Hreadyout=%b", 
             $time, Haddr, Htrans, Hwrite, Hwdata, 
             dut.AHBSlave.valid_int, dut.AHBSlave.pending_req, dut.AHBSlave.addr_phase, dut.AHBSlave.next_addr_phase, Hreadyout);
  end
  
  always @(posedge Pclk) begin
    $display("[%0t] Pclk: Pselx=%b Paddr=%h Pwrite=%b Penable=%b Pwdata=%h p_req_valid=%b state=%b", 
             $time, Pselx, Paddr, Pwrite, Penable, Pwdata,
             dut.CDC.p_req_valid, dut.APBControl.state);
  end

endmodule
