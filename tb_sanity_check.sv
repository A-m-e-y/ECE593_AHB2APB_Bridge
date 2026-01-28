`timescale 1ns/1ps

module tb_sanity_check;
  // Clock signals
  reg        Hclk;
  reg        Pclk;
  
  // AHB-lite signals
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
    .Pclk(Pclk),
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

  // Clock generation
  // HCLK: 10ns period (100MHz)
  always #5 Hclk = ~Hclk;
  
  // PCLK: 30ns period (33.3MHz) - 3x slower than HCLK
  always #10 Pclk = ~Pclk;

  initial begin
    $dumpfile("waveforms/tb_sanity_check.vcd");
    $dumpvars(0, tb_sanity_check);
  end

  initial begin
    // init
    Hclk     = 1'b0;
    Pclk     = 1'b0;
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
    wait (Hreadyout == 1'b1);
    @(posedge Hclk);
    #1;
    Hwrite   = 1'b1;
    Htrans   = 2'b10; // NONSEQ
    Haddr    = 32'h8000_0011; // addr1
    Hreadyin = 1'b1;

    wait (Hreadyout == 1'b1);
    @(posedge Hclk);
    #1;
    Htrans = 2'b10; // NONSEQ
    Hwdata = 32'h8000_0011; // data1
    Haddr    = 32'h8000_0022; // addr2

    wait (Hreadyout == 1'b1);
    @(posedge Hclk);
    #1;
    Htrans = 2'b10; // NONSEQ
    Hwdata = 32'h8000_0022; // data2
    Haddr    = 32'h8000_0033; // addr3

    wait (Hreadyout == 1'b1);
    @(posedge Hclk);
    #1;
    Htrans = 2'b10; // NONSEQ
    Hwdata = 32'h8000_0033; // data3
    Haddr    = 32'h8000_0044; // addr4

    wait (Hreadyout == 1'b1);
    @(posedge Hclk);
    #1;
    Htrans = 2'b10; // NONSEQ
    Hwdata = 32'h8000_0044; // data4
    Haddr    = 32'h8000_0055; // addr5

    wait (Hreadyout == 1'b1);
    @(posedge Hclk);
    #1;
    Htrans = 2'b00; // IDLE
    Hwdata = 32'hDEAD_DEAD;

    wait (Hreadyout == 1'b1);
    repeat (6) @(posedge Hclk);

    wait (Hreadyout == 1'b1);
    @(posedge Hclk);
    #1;
    Htrans = 2'b10; // NONSEQ
    Haddr    = 32'h8000_0050; // addr6
    wait (Hreadyout == 1'b1);
    @(posedge Hclk);
    #1;
    Hwdata = 32'h8000_0077; // data6
    
    wait (Hreadyout == 1'b1);
    @(posedge Hclk);
    #1;
    Htrans = 2'b11; // SEQ
    Haddr    = 32'h8000_0054; // addr7
    wait (Hreadyout == 1'b1);
    @(posedge Hclk);
    #1;
    Hwdata = 32'h8000_0088; // data7
        
    wait (Hreadyout == 1'b1);
    @(posedge Hclk);
    #1;
    Htrans = 2'b11; // SEQ
    Haddr    = 32'h8000_0058; // addr8
    wait (Hreadyout == 1'b1);
    @(posedge Hclk);
    #1;
    Hwdata = 32'h8000_0099; // data8
        
    wait (Hreadyout == 1'b1);
    @(posedge Hclk);
    #1;
    Htrans = 2'b11; // SEQ
    Haddr    = 32'h8000_005C; // addr9
    wait (Hreadyout == 1'b1);
    @(posedge Hclk);
    #1;
    Hwdata = 32'h8000_00AA; // data9
    
    // wait (Hreadyout == 1'b1);
    // @(posedge Hclk);
    // #1;
    // Htrans = 2'b00; // IDLE
    // Hwdata = 32'hDEAD_DEAD; // data10
    
    wait (Hreadyout == 1'b1);
    repeat (6) @(posedge Hclk);

    wait (Hreadyout == 1'b1);
    @(posedge Hclk);
    #1;
    Htrans = 2'b10; // NONSEQ
    Haddr    = 32'h8000_00AA; // addr11
    Hwrite   = 1'b0;
    wait (Paddr == Haddr && Pwrite == 1'b0);
    Prdata  = 32'h1234_5678; // read data

    // allow APB side to complete
    wait (Hreadyout == 1'b1);
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
