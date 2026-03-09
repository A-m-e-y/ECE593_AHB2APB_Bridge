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

    // APB signals — PCLK domain (post-CDC, from Bridge_Top output ports)
    logic         PENABLE;
    logic         PWRITE;
    logic [2:0]   PSELX;
    logic [31:0]  PADDR;
    logic [31:0]  PWDATA;
    logic [31:0]  PRDATA;    // driven into DUT as APB slave read-data

    // APB signals — HCLK domain (pre-CDC, tapped from Bridge_Top internal wires)
    // These are the registered outputs of APB_FSM_Controller, before the 2-FF
    // CDC synchronizer.  Because they live in the HCLK domain we can observe
    // them reliably with an HCLK clocking block — no CDC timing risk.
    logic         PENABLE_HCLK;
    logic         PWRITE_HCLK;
    logic [2:0]   PSELX_HCLK;
    logic [31:0]  PADDR_HCLK;
    logic [31:0]  PWDATA_HCLK;

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

    // APB Monitor Clocking Block (PCLK domain — kept for waveform visibility)
    clocking apb_monitor_cb @(posedge pclk);
        default input #1 output #1;
        input  PENABLE;
        input  PWRITE;
        input  PSELX;
        input  PADDR;
        input  PWDATA;
        input  PRDATA;   // driven into DUT externally (assign in top.sv)
    endclocking

    // APB HCLK Monitor Clocking Block (HCLK domain, pre-CDC)
    // Used by apb_monitor to observe each APB access without CDC timing risk.
    clocking apb_hclk_cb @(posedge hclk);
        default input #1 output #1;
        input PENABLE_HCLK;
        input PWRITE_HCLK;
        input PSELX_HCLK;
        input PADDR_HCLK;
        input PWDATA_HCLK;
    endclocking

    // MODPORTS
    modport AHB_DRIVER       (clocking ahb_driver_cb,  input hclk);
    modport AHB_MONITOR      (clocking ahb_monitor_cb, input hclk);
    modport APB_MONITOR      (clocking apb_monitor_cb, input pclk);          // legacy/waveform
    modport APB_HCLK_MONITOR (clocking apb_hclk_cb,   input hclk);          // used by apb_monitor

endinterface