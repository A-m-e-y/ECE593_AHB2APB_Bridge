// APB Monitor — HCLK domain, MS3-style trigger
//
// Samples the pre-CDC APB signals (Penable_hclk, Paddr_hclk, Pwdata_hclk …)
// directly from Bridge_Top's internal wires.  Because these are in the HCLK
// domain there is no CDC timing risk: every APB access is observed reliably.
//
// Trigger logic (mirrors MS3 monitor):
//   Fire when PSELX_HCLK != 0 AND PENABLE_HCLK == 1, AND either
//     (a) this is the first PENABLE assertion since it was de-asserted, OR
//     (b) PADDR_HCLK has changed since the last capture.
//   This fires exactly once per distinct APB access even during pipelined
//   bursts where PENABLE_HCLK stays high while PADDR changes at WENABLEP.
class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)

    virtual intf.APB_HCLK_MONITOR apb_vif;

    uvm_analysis_port #(apb_transaction) ap_port;

    function new(string name = "apb_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual intf.APB_HCLK_MONITOR)::get(this, "", "apb_vif", apb_vif))
            `uvm_fatal("APB_MON", "Unable to get APB HCLK monitor interface from config_db")
        ap_port = new("ap_port", this);
    endfunction

    task run_phase(uvm_phase phase);
        apb_transaction tx;
        bit         last_penable = 0;
        bit [31:0]  last_paddr   = '1;   // initialise to invalid sentinel

        @(posedge apb_vif.hclk);  // initial sync
        forever begin
            @(posedge apb_vif.hclk);
            begin
                bit         psel    = (apb_vif.apb_hclk_cb.PSELX_HCLK != 3'b000);
                bit         penable = apb_vif.apb_hclk_cb.PENABLE_HCLK;
                bit [31:0]  paddr   = apb_vif.apb_hclk_cb.PADDR_HCLK;

                if (psel && penable) begin
                    // New access: first assertion OR address changed (pipelined burst)
                    if (!last_penable || paddr !== last_paddr) begin
                        tx        = apb_transaction::type_id::create("tx", this);
                        tx.PWRITE = apb_vif.apb_hclk_cb.PWRITE_HCLK;
                        tx.PSELX  = apb_vif.apb_hclk_cb.PSELX_HCLK;
                        tx.PADDR  = paddr;
                        tx.PWDATA = apb_vif.apb_hclk_cb.PWDATA_HCLK;
                        tx.PRDATA = 32'h0;   // no slave model; reads return 0
                        `uvm_info(get_type_name(),
                            $sformatf("APB monitor captured TX (PENABLE↑ / PADDR chg):\n%s",
                                      tx.sprint()),
                            UVM_MEDIUM)
                        ap_port.write(tx);
                        last_paddr = paddr;
                    end
                end
                last_penable = penable;
            end
        end
    endtask
endclass

