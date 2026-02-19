
interface ahb_apb_if(input wire clk, input wire resetn, input wire Pclk);

  // AHB signals (testbench drives these as master)
  logic Hwrite;
  logic Hreadyin;
  logic [1:0] Htrans;
  logic [2:0] Hsize;   // For coverage
  logic [2:0] Hburst;  // For coverage
  logic [31:0] Hwdata;
  logic [31:0] Haddr;
  
  // AHB signals (DUT drives these as outputs)
  logic [31:0] Hrdata;
  logic [1:0] Hresp;
  logic Hreadyout;

  // APB signals (DUT drives these to APB slaves)
  wire Penable;
  wire Pwrite;
  wire [2:0] Pselx;
  wire [31:0] Pwdata;
  wire [31:0] Paddr;
  
  // APB read data (testbench drives this to simulate APB slave response)
  logic [31:0] Prdata;

  // Modports
  modport master(
    input clk, resetn, Pclk, Hreadyout, Hrdata, Hresp,
    input Penable, Pwrite, Pselx, Pwdata, Paddr,  // Driver needs to monitor APB outputs
    output Hwrite, Hreadyin, Htrans, Hsize, Hburst, Hwdata, Haddr,
    output Prdata  // Testbench drives this to simulate APB slave
  );
  
  modport slave(
    input clk, resetn, Pclk,
    input Hwrite, Hreadyin, Htrans, Hsize, Hburst, Hwdata, Haddr, Hrdata, Hresp, Hreadyout,
    input Penable, Pwrite, Pselx, Pwdata, Paddr, Prdata
  );

endinterface
