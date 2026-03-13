// AHB monitor - two state FSM to capture one txn at a time
//
// The 3-phase driver keeps HTRANS=NONSEQ on the bus for both address and
// data phases, so a simple while loop double-counts. Using awaiting_data
// flag to know whether we're looking for address vs waiting for data.
class ahb_monitor extends uvm_monitor;
    `uvm_component_utils(ahb_monitor)

    virtual          intf.AHB_MONITOR mon_intf;
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
        sequence_item tx;
        bit awaiting_data = 0;

        `uvm_info(get_name(), "Inside run_phase", UVM_DEBUG)
        @(posedge mon_intf.hclk);

        forever begin
            @(posedge mon_intf.hclk);

            if (!awaiting_data) begin
                // looking for address phase: NONSEQ/SEQ with HREADY=1
                if (mon_intf.ahb_monitor_cb.HRESETn &&
                    mon_intf.ahb_monitor_cb.HREADY   &&
                    (mon_intf.ahb_monitor_cb.HTRANS == 2'b10 ||
                     mon_intf.ahb_monitor_cb.HTRANS == 2'b11)) begin

                    tx = sequence_item::type_id::create("tx", this);
                    tx.HRESETn  = mon_intf.ahb_monitor_cb.HRESETn;
                    tx.HADDR    = mon_intf.ahb_monitor_cb.HADDR;
                    tx.HTRANS   = mon_intf.ahb_monitor_cb.HTRANS;
                    tx.HWRITE   = mon_intf.ahb_monitor_cb.HWRITE;
                    tx.HSELAHB  = mon_intf.ahb_monitor_cb.HSELAHB;
                    tx.HREADY   = mon_intf.ahb_monitor_cb.HREADY;
                    tx.HRESP    = mon_intf.ahb_monitor_cb.HRESP;
                    awaiting_data = 1;
                end

            end else begin
                // waiting for data phase - fires when bridge re-asserts HREADY
                if (mon_intf.ahb_monitor_cb.HREADY) begin
                    tx.HREADY = mon_intf.ahb_monitor_cb.HREADY;
                    tx.HRESP  = mon_intf.ahb_monitor_cb.HRESP;
                    if (tx.HWRITE)
                        tx.HWDATA = mon_intf.ahb_monitor_cb.HWDATA;
                    else
                        tx.HRDATA = mon_intf.ahb_monitor_cb.HRDATA;

                    `uvm_info(get_type_name(),
                        $sformatf("AHB monitor captured TX:\n%s", tx.sprint()), UVM_DEBUG)
                    ap_port.write(tx);
                    awaiting_data = 0;
                end
            end

        end
    endtask
endclass
