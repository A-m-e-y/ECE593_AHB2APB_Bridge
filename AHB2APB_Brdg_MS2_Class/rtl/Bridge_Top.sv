// Bridge Top

module Bridge_Top(Hclk,Pclk,Hresetn,Hwrite,Hreadyin,Hreadyout,Hwdata,Haddr,Htrans,Prdata,Penable,Pwrite,Pselx,Paddr,Pwdata,Hresp,Hrdata);

input Hclk,Pclk,Hresetn,Hwrite,Hreadyin;
input [31:0] Hwdata,Haddr;
input [31:0] Prdata;
input[1:0] Htrans;
output Penable,Pwrite,Hreadyout;
output [1:0] Hresp; 
output [2:0] Pselx;
output [31:0] Paddr,Pwdata;
output [31:0] Hrdata;

//////////INTERMEDIATE SIGNALS - HCLK DOMAIN

wire valid;
wire [31:0] Haddr1,Haddr2,Hwdata1,Hwdata2;
wire Hwritereg;
wire [2:0] tempselx;
wire [31:0] Prdata_hclk;

// APB signals in HCLK domain (before CDC)
wire Penable_hclk, Pwrite_hclk;
wire [2:0] Pselx_hclk;
wire [31:0] Paddr_hclk, Pwdata_hclk;

//////////MODULE INSTANTIATIONS

// AHB Slave Interface - runs on HCLK
AHB_Slave_Interface AHBSlave (
    .Hclk(Hclk),
    .Hresetn(Hresetn),
    .Hwrite(Hwrite),
    .Hreadyin(Hreadyin),
    .Htrans(Htrans),
    .Haddr(Haddr),
    .Hwdata(Hwdata),
    .Prdata(Prdata_hclk),
    .valid(valid),
    .Haddr1(Haddr1),
    .Haddr2(Haddr2),
    .Hwdata1(Hwdata1),
    .Hwdata2(Hwdata2),
    .Hrdata(Hrdata),
    .Hwritereg(Hwritereg),
    .tempselx(tempselx),
    .Hresp(Hresp)
);

// APB FSM Controller - runs on HCLK (NOT Pclk!)
APB_FSM_Controller APBControl (
    .Hclk(Hclk),
    .Hresetn(Hresetn),
    .valid(valid),
    .Haddr(Haddr),
    .Haddr1(Haddr1),
    .Haddr2(Haddr2),
    .Hwdata(Hwdata),
    .Hwdata1(Hwdata1),
    .Hwdata2(Hwdata2),
    .Prdata(Prdata_hclk),
    .Hwrite(Hwrite),
    .Hwritereg(Hwritereg),
    .tempselx(tempselx),
    .Pwrite(Pwrite_hclk),
    .Penable(Penable_hclk),
    .Pselx(Pselx_hclk),
    .Paddr(Paddr_hclk),
    .Pwdata(Pwdata_hclk),
    .Hreadyout(Hreadyout)
);

// CDC Handler - synchronizes APB signals between HCLK and PCLK domains
CDC_Handler CDC (
    .Hclk(Hclk),
    .Pclk(Pclk),
    .Hresetn(Hresetn),
    // APB outputs from FSM (HCLK domain)
    .Penable_hclk(Penable_hclk),
    .Pwrite_hclk(Pwrite_hclk),
    .Pselx_hclk(Pselx_hclk),
    .Paddr_hclk(Paddr_hclk),
    .Pwdata_hclk(Pwdata_hclk),
    // APB outputs to APB bus (PCLK domain)
    .Penable_pclk(Penable),
    .Pwrite_pclk(Pwrite),
    .Pselx_pclk(Pselx),
    .Paddr_pclk(Paddr),
    .Pwdata_pclk(Pwdata),
    // APB read data path
    .Prdata_pclk(Prdata),
    .Prdata_hclk(Prdata_hclk)
);

endmodule
