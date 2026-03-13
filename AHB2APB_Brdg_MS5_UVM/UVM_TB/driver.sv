// AHB driver processes one sequence item per beat.
// The sequence controls IDLE/BUSY insertion.
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
        bit expected_apb_transfer;
        valid_transfer = (tx.HTRANS == 2'b10 || tx.HTRANS == 2'b11);
        expected_apb_transfer = valid_transfer && tx.HSELAHB && is_decodable_addr(tx.HADDR);

        // Address phase
        @(vif.ahb_driver_cb);
        while (!vif.ahb_driver_cb.HREADY) @(vif.ahb_driver_cb);

        vif.ahb_driver_cb.HSELAHB <= tx.HSELAHB;
        vif.ahb_driver_cb.HADDR   <= tx.HADDR;
        vif.ahb_driver_cb.HTRANS  <= tx.HTRANS;
        vif.ahb_driver_cb.HWRITE  <= tx.HWRITE;

        // Push only decodable transfers into expected APB stream.
        if (expected_apb_transfer)
            drv_ap.write(tx);

        // Data phase
        @(vif.ahb_driver_cb);
        while (!vif.ahb_driver_cb.HREADY) @(vif.ahb_driver_cb);

        if (valid_transfer) begin
            if (tx.HWRITE)
                vif.ahb_driver_cb.HWDATA <= tx.HWDATA;
            else
                vif.ahb_driver_cb.HWDATA <= 32'h0;
        end

        if (valid_transfer)
            `uvm_info(get_type_name(),
                $sformatf("Driven Tx:\n%s", tx.sprint()), UVM_DEBUG)
        else
            `uvm_info(get_type_name(),
                $sformatf("IDLE/BUSY driven (HTRANS=%2b)", tx.HTRANS), UVM_DEBUG)
    endtask

    task reset();
        vif.ahb_driver_cb.HRESETn <= 0;
        vif.ahb_driver_cb.HSELAHB <= 0;
        vif.ahb_driver_cb.HTRANS  <= 2'b00;
        vif.ahb_driver_cb.HWRITE  <= 0;
        vif.ahb_driver_cb.HADDR   <= 32'h0;
        vif.ahb_driver_cb.HWDATA  <= 32'h0;
        // Hold reset for multiple HCLK cycles to cover reset logic
        // in both HCLK and slower PCLK domains.
        repeat (4) @(vif.ahb_driver_cb);
        vif.ahb_driver_cb.HRESETn <= 1;
    endtask

    function bit is_decodable_addr(bit [31:0] addr);
        return ((addr >= 32'h8000_0000 && addr <= 32'h83FF_FFFF) ||
                (addr >= 32'h8400_0000 && addr <= 32'h87FF_FFFF) ||
                (addr >= 32'h8800_0000 && addr <= 32'h8BFF_FFFF));
    endfunction
endclass
