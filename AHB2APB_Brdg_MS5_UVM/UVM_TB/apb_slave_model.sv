class apb_slave_model extends uvm_component;
    `uvm_component_utils(apb_slave_model)

    // sample APB intent in HCLK domain (before CDC)
    virtual intf.APB_HCLK_MONITOR apb_vif;
    virtual intf                  full_vif;

    uvm_analysis_port #(apb_transaction) ap_port;
    uvm_tlm_analysis_fifo #(sequence_item) ahb_exp_fifo;

    logic [31:0] mem [bit[31:0]];

    int write_count;
    int read_count;
    int protocol_errors;
    int range_errors;
    bit last_apb_valid;
    bit last_apb_write;
    bit [31:0] last_apb_addr;
    bit [31:0] last_apb_wdata;

    function new(string name = "apb_slave_model", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_port = new("ap_port", this);
        ahb_exp_fifo = new("ahb_exp_fifo", this);

        if (!uvm_config_db#(virtual intf.APB_HCLK_MONITOR)::get(this, "", "apb_vif", apb_vif))
            `uvm_fatal("SLAVE", "Cannot get apb_vif from config_db")

        if (!uvm_config_db#(virtual intf)::get(this, "", "full_vif", full_vif))
            `uvm_fatal("SLAVE", "Cannot get full_vif from config_db")
    endfunction

    task run_phase(uvm_phase phase);
        bit [2:0]  pselx;
        bit        penable;
        bit        pwrite;
        bit [31:0] paddr;
        bit [31:0] pwdata;
        bit        prev_penable = 0;
        bit        setup_seen = 0;
        bit [2:0]  setup_pselx;
        bit        setup_pwrite;
        bit [31:0] setup_paddr;
        bit [31:0] setup_pwdata;

        wait (full_vif.HRESETn === 1'b1);
        @(posedge full_vif.hclk);

        forever begin
            @(posedge full_vif.hclk);
            pselx   = full_vif.PSELX_HCLK;
            penable = full_vif.PENABLE_HCLK;
            pwrite  = full_vif.PWRITE_HCLK;
            paddr   = full_vif.PADDR_HCLK;
            pwdata  = full_vif.PWDATA_HCLK;

            if (!penable && (pselx != 3'b000)) begin
                setup_seen   = 1;
                setup_pselx  = pselx;
                setup_pwrite = pwrite;
                setup_paddr  = paddr;
                setup_pwdata = pwdata;
            end

            // one transfer per PENABLE rising edge; use setup payload for stability
            if (penable && !prev_penable) begin
                if (setup_seen) begin
                    process_candidate(setup_pselx, setup_pwrite, setup_paddr, setup_pwdata);
                    setup_seen = 0;
                end else if (pselx != 3'b000) begin
                    process_candidate(pselx, pwrite, paddr, pwdata);
                end
            end

            if (!penable && prev_penable)
                full_vif.PRDATA = 32'h0;

            prev_penable = penable;
        end
    endtask

    task process_candidate(bit [2:0] pselx, bit pwrite, bit [31:0] paddr, bit [31:0] pwdata);
        sequence_item ahb_exp;
        bit queue_head_matches;

        queue_head_matches = 0;
        if (ahb_exp_fifo.try_peek(ahb_exp)) begin
            queue_head_matches =
                (ahb_exp.HWRITE === pwrite) &&
                (ahb_exp.HADDR  === paddr)  &&
                (!pwrite || (ahb_exp.HWDATA === pwdata));
        end

        // Drop stale duplicate APB samples unless they match the next expected AHB txn.
        if (last_apb_valid &&
            (last_apb_write === pwrite) &&
            (last_apb_addr  === paddr)  &&
            (!pwrite || (last_apb_wdata === pwdata)) &&
            !queue_head_matches) begin
            return;
        end

        if (!queue_head_matches) begin
            last_apb_valid = 1;
            last_apb_write = pwrite;
            last_apb_addr  = paddr;
            last_apb_wdata = pwdata;
            return;
        end

        if (!ahb_exp_fifo.try_get(ahb_exp))
            return;
        handle_txn(pselx, pwrite, paddr, pwdata, ahb_exp);

        last_apb_valid = 1;
        last_apb_write = pwrite;
        last_apb_addr  = paddr;
        last_apb_wdata = pwdata;
    endtask

    task handle_txn(bit [2:0] pselx, bit pwrite, bit [31:0] paddr, bit [31:0] pwdata, sequence_item ahb_exp);
        apb_transaction tx;

        if (!valid_addr(paddr)) begin
            `uvm_warning("SLAVE",
                $sformatf("ADDR OUT OF RANGE: PADDR=0x%08h PSELX=3'b%03b", paddr, pselx))
            range_errors++;
            return;
        end

        if (!is_onehot(pselx)) begin
            `uvm_warning("SLAVE",
                $sformatf("PSELX not one-hot: 3'b%03b PADDR=0x%08h", pselx, paddr))
            protocol_errors++;
            return;
        end

        tx = apb_transaction::type_id::create("tx", this);
        tx.PWRITE = pwrite;
        tx.PSELX  = pselx;
        tx.PADDR  = paddr;
        tx.PWDATA = pwdata;

        if (pwrite) begin
            mem[paddr] = pwdata;
            write_count++;
            tx.PRDATA = 32'h0;
            `uvm_info("SLAVE",
                $sformatf("WRITE PSELX=3'b%03b PADDR=0x%08h PWDATA=0x%08h",
                pselx, paddr, pwdata), UVM_DEBUG)
        end else begin
            mem[paddr] = ahb_exp.HRDATA;
            tx.PRDATA = ahb_exp.HRDATA;
            full_vif.PRDATA = tx.PRDATA;
            read_count++;
            `uvm_info("SLAVE",
                $sformatf("READ  PSELX=3'b%03b PADDR=0x%08h PRDATA=0x%08h EXP=0x%08h",
                pselx, paddr, tx.PRDATA, ahb_exp.HRDATA), UVM_DEBUG)
        end

        ap_port.write(tx);
    endtask

    function bit valid_addr(bit [31:0] addr);
        return ((addr >= 32'h8000_0000 && addr <= 32'h83FF_FFFF) ||
                (addr >= 32'h8400_0000 && addr <= 32'h87FF_FFFF) ||
                (addr >= 32'h8800_0000 && addr <= 32'h8BFF_FFFF));
    endfunction

    function bit is_onehot(bit [2:0] pselx);
        return (pselx == 3'b001 || pselx == 3'b010 || pselx == 3'b100);
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SLAVE", $sformatf({
            "\n========================================\n",
            " APB Slave Model Report\n",
            "========================================\n",
            " Writes completed  : %0d\n",
            " Reads completed   : %0d\n",
            " Protocol errors   : %0d\n",
            " Range errors      : %0d\n",
            "========================================"
            },
            write_count, read_count, protocol_errors, range_errors),
            UVM_NONE)

        if (protocol_errors > 0)
            `uvm_warning("SLAVE", $sformatf("%0d APB protocol violation(s)", protocol_errors))
        if (range_errors > 0)
            `uvm_warning("SLAVE", $sformatf("%0d APB address range error(s)", range_errors))
    endfunction

endclass
