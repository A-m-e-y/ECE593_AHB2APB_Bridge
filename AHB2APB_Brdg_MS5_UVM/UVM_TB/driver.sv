// AHB driver - one beat per sequence item
// sequence controls IDLE insertion explicitly
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
        bit valid_transfer;
        valid_transfer = (tx.HTRANS == 2'b10 || tx.HTRANS == 2'b11);

        // address phase
        @(vif.ahb_driver_cb);
        while (!vif.ahb_driver_cb.HREADY) @(vif.ahb_driver_cb);

        vif.ahb_driver_cb.HSELAHB <= tx.HSELAHB;
        vif.ahb_driver_cb.HADDR   <= tx.HADDR;
        vif.ahb_driver_cb.HTRANS  <= tx.HTRANS;
        vif.ahb_driver_cb.HWRITE  <= tx.HWRITE;

        // only real transfers go to scoreboard stream
        if (valid_transfer)
            drv_ap.write(tx);

        // data phase
        @(vif.ahb_driver_cb);
        while (!vif.ahb_driver_cb.HREADY) @(vif.ahb_driver_cb);

        if (valid_transfer && tx.HWRITE)
            vif.ahb_driver_cb.HWDATA <= tx.HWDATA;

        if (valid_transfer)
            `uvm_info(get_type_name(),
                $sformatf("Driven Tx:\n%s", tx.sprint()), UVM_MEDIUM)
        else
            `uvm_info(get_type_name(),
                $sformatf("IDLE/BUSY driven (HTRANS=%2b)", tx.HTRANS), UVM_HIGH)
    endtask

    task reset();
        vif.ahb_driver_cb.HRESETn <= 0;
        vif.ahb_driver_cb.HSELAHB <= 0;
        vif.ahb_driver_cb.HTRANS  <= 2'b00;
        vif.ahb_driver_cb.HWRITE  <= 0;
        vif.ahb_driver_cb.HADDR   <= 32'h0;
        vif.ahb_driver_cb.HWDATA  <= 32'h0;
        @(vif.ahb_driver_cb);
        vif.ahb_driver_cb.HRESETn <= 1;
    endtask
endclass
