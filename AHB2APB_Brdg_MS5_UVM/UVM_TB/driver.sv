// UVM AHB Driver — MS3-faithful 3-phase approach
//
// Each non-IDLE transaction follows the same 3-phase hand-shake as the MS3
// class-based driver:
//
//   Phase 1 — ADDRESS:    wait HREADY, drive HADDR/HTRANS/HWRITE/HSELAHB
//   Phase 2 — DATA:       wait HREADY, drive HWDATA (writes only)
//   Phase 3 — COMPLETION: wait HREADY, then assert HTRANS=IDLE
//
// Because each transaction is self-contained the driver never needs to
// carry state (Hwdata_t / wr_pending) between calls.  The sequence just
// sends NONSEQ items; SEQ and IDLE interleaving is not required.
//
// The scoreboard is notified (drv_ap.write) right after the address phase —
// well before the corresponding APB PENABLE asserts — so the queue is always
// populated in time.
class ahb_driver extends uvm_driver #(sequence_item);
    `uvm_component_utils(ahb_driver)

    virtual intf.AHB_DRIVER vif;

    // Analysis port: one write per non-IDLE/non-BUSY transaction → scoreboard.
    uvm_analysis_port #(sequence_item) drv_ap;

    function new(string name = "ahb_driver", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv_ap = new("drv_ap", this);
        if (!uvm_config_db#(virtual intf.AHB_DRIVER)::get(this, "", "vif", vif))
            `uvm_error("CONFIG_DB", "Not able to get virtual handle")
    endfunction

    task run_phase(uvm_phase phase);
        reset();
        forever begin
            seq_item_port.get_next_item(req);
            drive_tx(req);
            seq_item_port.item_done();
        end
    endtask

    // ── drive_tx ────────────────────────────────────────────────────────────
    // MS3-style: three explicit HREADY waits per active transaction.
    // IDLE/BUSY items are driven but skip the data and completion phases.
    virtual task drive_tx(sequence_item tx);

        // ── PHASE 1: ADDRESS ──────────────────────────────────────────────
        // Wait for bridge to be ready (Hreadyout=1) before placing address.
        @(vif.ahb_driver_cb);
        while (!vif.ahb_driver_cb.HREADY) @(vif.ahb_driver_cb);

        vif.ahb_driver_cb.HSELAHB <= tx.HSELAHB;
        vif.ahb_driver_cb.HADDR   <= tx.HADDR;
        vif.ahb_driver_cb.HTRANS  <= tx.HTRANS;
        vif.ahb_driver_cb.HWRITE  <= tx.HWRITE;

        // IDLE / BUSY: address-only drive; no APB transaction generated.
        if (tx.HTRANS == 2'b00 || tx.HTRANS == 2'b01) begin
            `uvm_info(get_type_name(),
                $sformatf("IDLE/BUSY driven (HTRANS=%2b)", tx.HTRANS), UVM_HIGH)
            return;
        end

        // Tell the scoreboard about this transaction now.
        // The APB PENABLE arrives several HCLK cycles later, so the queue
        // will always be populated before write_apb() tries to pop it.
        drv_ap.write(tx);

        // ── PHASE 2: DATA ─────────────────────────────────────────────────
        // Wait for bridge ready, then put write data on the bus.
        @(vif.ahb_driver_cb);
        while (!vif.ahb_driver_cb.HREADY) @(vif.ahb_driver_cb);

        if (tx.HWRITE)
            vif.ahb_driver_cb.HWDATA <= tx.HWDATA;

        // ── PHASE 3: COMPLETION ───────────────────────────────────────────
        // Wait for the bridge to finish the APB cycle (Hreadyout re-asserts),
        // then return the bus to IDLE so the next item starts cleanly.
        @(vif.ahb_driver_cb);
        while (!vif.ahb_driver_cb.HREADY) @(vif.ahb_driver_cb);

        vif.ahb_driver_cb.HTRANS <= 2'b00;

        `uvm_info(get_type_name(),
            $sformatf("Driven Tx:\n%s", tx.sprint()), UVM_MEDIUM)
    endtask

    task reset();
        vif.ahb_driver_cb.HRESETn <= 0;
        @(vif.ahb_driver_cb);
        vif.ahb_driver_cb.HRESETn <= 1;
    endtask
endclass