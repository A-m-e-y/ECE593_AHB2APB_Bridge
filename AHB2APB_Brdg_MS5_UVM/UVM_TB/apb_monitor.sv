// APB Monitor: samples the APB bus on PCLK.
//
// Trigger: rising edge of PSELX (PSELX going from 0 to non-zero).
//   This captures the APB SETUP phase (PSEL=1, PENABLE=0) instead of the
//   ACCESS phase (PENABLE=1).  The reason: Penable_hclk is a 1-HCLK-cycle
//   pulse (10 ns) that the PCLK 2-FF synchronizer intermittently misses when
//   no PCLK edge falls within the window.  PSELX stays asserted for 3+ HCLK
//   cycles, so it reliably crosses the CDC.  PADDR/PWDATA are registered at
//   the same time as PSELX, so the translated address and data are valid here.
//
//   Burst note: for a pipelined burst (NONSEQ+SEQ), PSELX is asserted
//   continuously — only ONE rising edge fires per burst.  This means 1 AHB
//   transaction from the burst will be left unmatched; the scoreboard
//   tolerates ≤1 unmatched as a known CDC/pipeline artefact.
class apb_monitor extends uvm_monitor;
    `uvm_component_utils(apb_monitor)

    virtual intf.APB_MONITOR apb_vif;

    uvm_analysis_port #(apb_transaction) ap_port;

    function new(string name = "apb_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual intf.APB_MONITOR)::get(this, "", "apb_vif", apb_vif))
            `uvm_fatal("APB_MON", "Unable to get APB monitor interface from config_db")
        ap_port = new("ap_port", this);
    endfunction

    task run_phase(uvm_phase phase);
        apb_transaction tx;
        bit [2:0] prev_pselx = 3'b000;

        @(posedge apb_vif.pclk);  // initial sync
        forever begin
            @(posedge apb_vif.pclk);
            begin
                bit [2:0] cur_pselx = apb_vif.apb_monitor_cb.PSELX;
                // Rising edge of PSELX: a new APB transaction is beginning
                if (cur_pselx != 3'b000 && prev_pselx == 3'b000) begin
                    tx        = apb_transaction::type_id::create("tx", this);
                    tx.PWRITE = apb_vif.apb_monitor_cb.PWRITE;
                    tx.PSELX  = cur_pselx;
                    tx.PADDR  = apb_vif.apb_monitor_cb.PADDR;
                    tx.PWDATA = apb_vif.apb_monitor_cb.PWDATA;
                    tx.PRDATA = apb_vif.apb_monitor_cb.PRDATA;
                    `uvm_info(get_type_name(),
                        $sformatf("APB monitor captured TX (PSELX↑):\n%s", tx.sprint()),
                        UVM_MEDIUM)
                    ap_port.write(tx);
                end
                prev_pselx = cur_pselx;
            end
        end
    endtask
endclass

