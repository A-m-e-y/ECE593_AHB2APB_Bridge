interface intf (input logic hclk, input logic pclk);

    // AHB signals
    logic         HRESETn;
    logic [31:0]  HADDR;
    logic [31:0]  HWDATA;
    logic [31:0]  HRDATA;
    logic [1:0]   HTRANS;
    logic         HWRITE;
    logic         HSELAHB;   // TB-internal bridge select (not a DUT port)
    logic         HREADY;    // Hreadyout from DUT
    logic [1:0]   HRESP;     // 2-bit per AHB spec
    logic [2:0]   HSIZE;
    logic [2:0]   HBURST;

    // APB signals (outputs from DUT, observable by APB monitor)
    logic         PENABLE;
    logic         PWRITE;
    logic [2:0]   PSELX;
    logic [31:0]  PADDR;
    logic [31:0]  PWDATA;
    logic [31:0]  PRDATA;    // driven into DUT as APB slave read-data

    // AHB Driver Clocking Block (HCLK domain)
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

    // AHB Monitor Clocking Block (HCLK domain)
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

    // APB Monitor Clocking Block (PCLK domain)
    clocking apb_monitor_cb @(posedge pclk);
        default input #1 output #1;
        input  PENABLE;
        input  PWRITE;
        input  PSELX;
        input  PADDR;
        input  PWDATA;
        output PRDATA;   // APB slave drives read-data back through this port
    endclocking

    // MODPORTS
    modport AHB_DRIVER  (clocking ahb_driver_cb,  input hclk);
    modport AHB_MONITOR (clocking ahb_monitor_cb, input hclk);
    modport APB_MONITOR (clocking apb_monitor_cb, input pclk);

endinterface