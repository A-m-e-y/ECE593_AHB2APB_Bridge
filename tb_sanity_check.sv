`timescale 1ns/1ps

module tb_sanity_check;
  // AHB-lite signals
  reg        Hclk;
  reg        Hresetn;
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

  initial begin
    $dumpfile("waveforms/tb_sanity_check.vcd");
    $dumpvars(0, tb_sanity_check);
  end

  initial begin
    // init
    Hclk     = 1'b0;
    Hresetn  = 1'b0;
    Hwrite   = 1'b0;
    Hreadyin = 1'b1;
    Htrans   = 2'b00;
    Hwdata   = 32'h0;
    Haddr    = 32'h0;

    // reset deassert
    repeat (2) @(posedge Hclk);
    #1 Hresetn = 1'b1;

    // One AHB write transaction to valid APB slave 0 range
    @(posedge Hclk);
    #1;
    Hwrite   = 1'b1;
    Htrans   = 2'b10; // NONSEQ
    Haddr    = 32'h8000_0004; // valid range: 0x8000_0000 - 0x83FF_FFFF
    Hreadyin = 1'b1;

    @(posedge Hclk);
    #1;
    Htrans = 2'b10; // IDLE
    Hwdata = 32'hA5A5_5A5A;
    Haddr    = 32'h8000_00FF; // valid range: 0x8000_0000 - 0x83FF_FFFF

    @(posedge Hclk);
    #1;
    Htrans = 2'b00; // IDLE
    Hwdata = 32'hDEAD_DEAD;

    // allow APB side to complete
    repeat (6) @(posedge Hclk);
    $finish;
  end

  // Simple observation
  always @(posedge Hclk) begin
    if (Pselx != 3'b000) begin
      $display("[%0t] APB sel=%b addr=%h write=%b enable=%b wdata=%h", $time, Pselx, Paddr, Pwrite, Penable, Pwdata);
    end
  end

endmodule
