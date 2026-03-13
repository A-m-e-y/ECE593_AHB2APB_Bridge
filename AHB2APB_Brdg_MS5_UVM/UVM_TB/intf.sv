interface intf (input logic hclk, input logic pclk);

    // AHB signals
    logic         HRESETn;
    logic [31:0]  HADDR;
    logic [31:0]  HWDATA;
    logic [31:0]  HRDATA;
    logic [1:0]   HTRANS;
    logic         HWRITE;
    logic         HSELAHB;
    logic         HREADY;    // DUT HREADYOUT
    logic [1:0]   HRESP;
    logic [2:0]   HSIZE;
    logic [2:0]   HBURST;

    // APB signals after CDC synchronization (PCLK domain)
    logic         PENABLE;
    logic         PWRITE;
    logic [2:0]   PSELX;
    logic [31:0]  PADDR;
    logic [31:0]  PWDATA;
    logic [31:0]  PRDATA;    // Driven into DUT by APB slave model

    // APB intent tapped before CDC (HCLK domain)
    // Sample with HCLK CB to avoid CDC sampling ambiguity
    logic         PENABLE_HCLK;
    logic         PWRITE_HCLK;
    logic [2:0]   PSELX_HCLK;
    logic [31:0]  PADDR_HCLK;
    logic [31:0]  PWDATA_HCLK;

    clocking ahb_driver_cb @(posedge hclk);
        default input #1 output #1;
        output HRESETn;
        output HADDR;
        output HTRANS;
        output HWRITE;
        output HWDATA;
        output HSELAHB;
        input  HREADY;
    endclocking

    clocking ahb_monitor_cb @(posedge hclk);
        default input #1 output #1;
        input HRESETn;
        input HADDR;
        input HTRANS;
        input HWRITE;
        input HWDATA;
        input HSELAHB;
        input HRDATA;
        input HREADY;
        input HRESP;
        input HSIZE;
        input HBURST;
    endclocking

    clocking apb_monitor_cb @(posedge pclk);
        default input #1 output #1;
        input  PENABLE;
        input  PWRITE;
        input  PSELX;
        input  PADDR;
        input  PWDATA;
        input  PRDATA;
    endclocking

    // HCLK-domain APB monitor CB
    clocking apb_hclk_cb @(posedge hclk);
        default input #1 output #1;
        input PENABLE_HCLK;
        input PWRITE_HCLK;
        input PSELX_HCLK;
        input PADDR_HCLK;
        input PWDATA_HCLK;
    endclocking

    // APB slave modport uses direct signals (no clocking block)
    // Slave model samples with @(posedge pclk) #1
    modport APB_SLAVE (
        input  pclk,
        input  PSELX, PENABLE, PWRITE, PADDR, PWDATA,
        output PRDATA
    );

    modport AHB_DRIVER       (clocking ahb_driver_cb,  input hclk);
    modport AHB_MONITOR      (clocking ahb_monitor_cb, input hclk);
    modport APB_MONITOR      (clocking apb_monitor_cb, input pclk);
    modport APB_HCLK_MONITOR (clocking apb_hclk_cb,   input hclk);

endinterface
