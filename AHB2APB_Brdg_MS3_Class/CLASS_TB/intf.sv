
interface ahb_apb_if(input wire clk, input wire resetn, input wire Pclk);

  // AHB input signals
  logic Hwrite;
  logic Hreadyin;
  logic [1:0] Htrans;
  logic [2:0] Hsize;
  logic [2:0] Hburst;
  logic [31:0] Hwdata;
  logic [31:0] Haddr;
  
  // AHB output signals
  logic [31:0] Hrdata;
  logic [1:0] Hresp;
  logic Hreadyout;

  // APB signals
  wire Penable;
  wire Pwrite;
  wire [2:0] Pselx;
  wire [31:0] Pwdata;
  wire [31:0] Paddr;
  
  logic [31:0] Prdata;  //APB read data from slave model

  // Modports
  modport master(
    input clk, resetn, Pclk, Hreadyout, Hrdata, Hresp,
    input Penable, Pwrite, Pselx, Pwdata, Paddr,
    output Hwrite, Hreadyin, Htrans, Hsize, Hburst, Hwdata, Haddr,
    output Prdata
  );
  
  modport slave(
    input clk, resetn, Pclk,
    input Hwrite, Hreadyin, Htrans, Hsize, Hburst, Hwdata, Haddr, Hrdata, Hresp, Hreadyout,
    input Penable, Pwrite, Pselx, Pwdata, Paddr, Prdata
  );

endinterface
