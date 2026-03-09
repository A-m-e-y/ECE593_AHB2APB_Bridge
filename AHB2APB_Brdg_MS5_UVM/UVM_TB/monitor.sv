// AHB Monitor: captures complete AHB transactions (address phase + data phase
// paired together) and broadcasts each one to the scoreboard.
//
// Key burst-handling design:
//   After capturing the data phase of one transfer, the monitor re-checks the
//   same clock edge for a new address phase (NONSEQ/SEQ). This correctly
//   handles back-to-back bursts where the data phase of transfer N coincides
//   with the address phase of transfer N+1.
class ahb_monitor extends uvm_monitor;
    `uvm_component_utils(ahb_monitor)

    virtual          intf.AHB_MONITOR mon_intf;
    sequence_item    tx;

    uvm_analysis_port # (sequence_item) ap_port;

    function new (string name = "ahb_monitor", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), "Inside build_phase", UVM_DEBUG)

        if(!uvm_config_db#(virtual intf.AHB_MONITOR)::get(this,"","vif",mon_intf))
            `uvm_fatal("MON","Unable to get monitor interface")

        ap_port = new("ap_port", this);
    endfunction

    task run_phase(uvm_phase phase);
        `uvm_info(get_name(), "Inside run_phase", UVM_DEBUG)
        @(posedge mon_intf.hclk);  // initial sync

        forever begin
            @(posedge mon_intf.hclk);

            // Inner while: handles back-to-back bursts by re-checking the
            // same clock after each data phase without advancing the clock.
            while (mon_intf.ahb_monitor_cb.HRESETn &&
                   mon_intf.ahb_monitor_cb.HREADY   &&
                   (mon_intf.ahb_monitor_cb.HTRANS == 2'b10 ||
                    mon_intf.ahb_monitor_cb.HTRANS == 2'b11)) begin

                tx = sequence_item::type_id::create("tx", this);

                // --- Address phase (current clock) ---
                tx.HRESETn  = mon_intf.ahb_monitor_cb.HRESETn;
                tx.HADDR    = mon_intf.ahb_monitor_cb.HADDR;
                tx.HTRANS   = mon_intf.ahb_monitor_cb.HTRANS;
                tx.HWRITE   = mon_intf.ahb_monitor_cb.HWRITE;
                tx.HSELAHB  = mon_intf.ahb_monitor_cb.HSELAHB;
                tx.HREADY   = mon_intf.ahb_monitor_cb.HREADY;
                tx.HRESP    = mon_intf.ahb_monitor_cb.HRESP;

                // --- Data phase (next clock) ---
                @(posedge mon_intf.hclk);
                if (tx.HWRITE)
                    tx.HWDATA = mon_intf.ahb_monitor_cb.HWDATA;

                `uvm_info(get_type_name(),
                    $sformatf("AHB monitor captured TX:\n%s", tx.sprint()), UVM_MEDIUM)
                ap_port.write(tx);

                // Loop back: if the data-phase clock also has an address
                // phase (burst), capture it without another @(posedge).
            end
        end
    endtask
endclass