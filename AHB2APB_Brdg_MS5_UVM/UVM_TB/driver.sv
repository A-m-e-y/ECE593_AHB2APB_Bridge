// AHB driver - ported from MS3 class-based TB
// uses same 3-phase approach: address -> data -> completion
// each phase waits for HREADY before proceeding
class ahb_driver extends uvm_driver #(sequence_item);
    `uvm_component_utils(ahb_driver)

    virtual intf.AHB_DRIVER vif;

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

    virtual task drive_tx(sequence_item tx);

        // phase 1: put address on bus, wait for bridge ready
        @(vif.ahb_driver_cb);
        while (!vif.ahb_driver_cb.HREADY) @(vif.ahb_driver_cb);

        vif.ahb_driver_cb.HSELAHB <= tx.HSELAHB;
        vif.ahb_driver_cb.HADDR   <= tx.HADDR;
        vif.ahb_driver_cb.HTRANS  <= tx.HTRANS;
        vif.ahb_driver_cb.HWRITE  <= tx.HWRITE;

        // skip data/completion for IDLE or BUSY
        if (tx.HTRANS == 2'b00 || tx.HTRANS == 2'b01) begin
            `uvm_info(get_type_name(),
                $sformatf("IDLE/BUSY driven (HTRANS=%2b)", tx.HTRANS), UVM_HIGH)
            return;
        end

        // notify scoreboard now - APB PENABLE comes a few cycles later so queue is ready
        drv_ap.write(tx);

        // phase 2: drive write data
        @(vif.ahb_driver_cb);
        while (!vif.ahb_driver_cb.HREADY) @(vif.ahb_driver_cb);

        if (tx.HWRITE)
            vif.ahb_driver_cb.HWDATA <= tx.HWDATA;

        // phase 3: wait for bridge to finish, return to IDLE
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
