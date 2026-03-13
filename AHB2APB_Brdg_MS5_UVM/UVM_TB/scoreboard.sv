`uvm_analysis_imp_decl(_ahb)
`uvm_analysis_imp_decl(_apb)

class ahb_apb_scoreboard extends uvm_component;
    `uvm_component_utils(ahb_apb_scoreboard)

    uvm_analysis_imp_ahb #(sequence_item,   ahb_apb_scoreboard) ahb_export;
    uvm_analysis_imp_apb #(apb_transaction, ahb_apb_scoreboard) apb_export;

    // Expected stream from driver, preserved in-order.
    sequence_item ahb_queue[$];

    int total_ahb_txns;
    int total_apb_writes;
    int total_apb_reads;
    int unmatched_apb_txns;
    int type_mismatches;
    int addr_mismatches;
    int data_mismatches;
    bit last_apb_valid;
    bit last_apb_write;
    bit [31:0] last_apb_addr;
    bit [31:0] last_apb_wdata;

    function new(string name = "ahb_apb_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ahb_export = new("ahb_export", this);
        apb_export = new("apb_export", this);
    endfunction

    function void write_ahb(sequence_item tx);
        sequence_item copy;
        copy = sequence_item::type_id::create("ahb_copy");
        copy.HADDR  = tx.HADDR;
        copy.HWDATA = tx.HWDATA;
        copy.HRDATA = tx.HRDATA;
        copy.HWRITE = tx.HWRITE;
        copy.HTRANS = tx.HTRANS;
        ahb_queue.push_back(copy);
        total_ahb_txns++;

        `uvm_info("SCB", $sformatf(
            "[AHB txn %0d] HADDR=0x%08h HWRITE=%0b HWDATA=0x%08h",
            total_ahb_txns, tx.HADDR, tx.HWRITE, tx.HWDATA), UVM_HIGH)
    endfunction

    function void write_apb(apb_transaction apb_tx);
        sequence_item ahb_tx;
        bit queue_head_matches = 0;

        if (ahb_queue.size() > 0) begin
            queue_head_matches =
                (ahb_queue[0].HADDR  === apb_tx.PADDR) &&
                (ahb_queue[0].HWRITE === apb_tx.PWRITE) &&
                (!apb_tx.PWRITE || (ahb_queue[0].HWDATA === apb_tx.PWDATA));
        end

        // Ignore duplicate APB samples unless queue head matches the duplicate.
        if (last_apb_valid &&
            last_apb_write === apb_tx.PWRITE &&
            last_apb_addr  === apb_tx.PADDR  &&
            (!apb_tx.PWRITE || (last_apb_wdata === apb_tx.PWDATA)) &&
            !queue_head_matches) begin
            `uvm_info("SCB", $sformatf(
                "Duplicate APB sample ignored: PWRITE=%0b PADDR=0x%08h PWDATA=0x%08h",
                apb_tx.PWRITE, apb_tx.PADDR, apb_tx.PWDATA), UVM_HIGH)
            return;
        end

        if (apb_tx.PWRITE)
            total_apb_writes++;
        else
            total_apb_reads++;

        if (ahb_queue.size() == 0) begin
            unmatched_apb_txns++;
            `uvm_error("SCB", $sformatf(
                "APB txn without expected AHB: PWRITE=%0b PADDR=0x%08h PWDATA=0x%08h",
                apb_tx.PWRITE, apb_tx.PADDR, apb_tx.PWDATA))
            last_apb_valid = 1;
            last_apb_write = apb_tx.PWRITE;
            last_apb_addr  = apb_tx.PADDR;
            last_apb_wdata = apb_tx.PWDATA;
            return;
        end

        ahb_tx = ahb_queue.pop_front();

        if (ahb_tx.HWRITE !== apb_tx.PWRITE) begin
            type_mismatches++;
            `uvm_error("SCB", $sformatf(
                "TYPE MISMATCH: AHB HWRITE=%0b APB PWRITE=%0b (HADDR=0x%08h PADDR=0x%08h)",
                ahb_tx.HWRITE, apb_tx.PWRITE, ahb_tx.HADDR, apb_tx.PADDR))
        end

        if (ahb_tx.HADDR !== apb_tx.PADDR) begin
            addr_mismatches++;
            `uvm_error("SCB", $sformatf(
                "ADDR MISMATCH: AHB HADDR=0x%08h APB PADDR=0x%08h",
                ahb_tx.HADDR, apb_tx.PADDR))
        end

        if (apb_tx.PWRITE && (ahb_tx.HWDATA !== apb_tx.PWDATA)) begin
            data_mismatches++;
            `uvm_error("SCB", $sformatf(
                "DATA MISMATCH: AHB HWDATA=0x%08h APB PWDATA=0x%08h (PADDR=0x%08h)",
                ahb_tx.HWDATA, apb_tx.PWDATA, apb_tx.PADDR))
        end
        if (!apb_tx.PWRITE && (ahb_tx.HRDATA !== apb_tx.PRDATA)) begin
            data_mismatches++;
            `uvm_error("SCB", $sformatf(
                "READ DATA MISMATCH: EXP HRDATA=0x%08h APB PRDATA=0x%08h (PADDR=0x%08h)",
                ahb_tx.HRDATA, apb_tx.PRDATA, apb_tx.PADDR))
        end

        if (ahb_tx.HADDR === apb_tx.PADDR &&
            ahb_tx.HWRITE === apb_tx.PWRITE &&
            (apb_tx.PWRITE ? (ahb_tx.HWDATA === apb_tx.PWDATA)
                           : (ahb_tx.HRDATA === apb_tx.PRDATA))) begin
            if (apb_tx.PWRITE)
                `uvm_info("SCB", $sformatf(
                    "[APB write] PADDR=0x%08h PWDATA=0x%08h - addr/data OK",
                    apb_tx.PADDR, apb_tx.PWDATA), UVM_HIGH)
            else
                `uvm_info("SCB", $sformatf(
                    "[APB read ] PADDR=0x%08h PRDATA=0x%08h - addr OK",
                    apb_tx.PADDR, apb_tx.PRDATA), UVM_HIGH)
        end

        last_apb_valid = 1;
        last_apb_write = apb_tx.PWRITE;
        last_apb_addr  = apb_tx.PADDR;
        last_apb_wdata = apb_tx.PWDATA;
    endfunction

    function void report_phase(uvm_phase phase);
        int total_apb     = total_apb_writes + total_apb_reads;
        int unmatched_ahb = ahb_queue.size();
        bit passed        = (total_ahb_txns > 0 &&
                             total_apb == total_ahb_txns &&
                             unmatched_ahb == 0 &&
                             unmatched_apb_txns == 0 &&
                             type_mismatches == 0 &&
                             addr_mismatches == 0 &&
                             data_mismatches == 0);
        string result = passed ? "** PASSED **" : "** FAILED **";

        `uvm_info("SCB", $sformatf({
            "\n======================================\n",
            " Scoreboard Report\n",
            "======================================\n",
            " AHB Transactions : %0d\n",
            " APB Writes       : %0d\n",
            " APB Reads        : %0d\n",
            " APB Total        : %0d\n",
            " Unmatched AHB    : %0d\n",
            " Unmatched APB    : %0d\n",
            " Type Mismatches  : %0d\n",
            " Addr Mismatches  : %0d\n",
            " Data Mismatches  : %0d\n",
            "======================================\n",
            " Result: %s\n",
            "======================================"
            },
            total_ahb_txns,
            total_apb_writes, total_apb_reads, total_apb,
            unmatched_ahb, unmatched_apb_txns,
            type_mismatches, addr_mismatches, data_mismatches,
            result),
            UVM_NONE)

        if (!passed) begin
            if (type_mismatches > 0) `uvm_error("SCB", $sformatf("%0d type mismatch(es)", type_mismatches))
            if (addr_mismatches > 0) `uvm_error("SCB", $sformatf("%0d addr mismatch(es)", addr_mismatches))
            if (data_mismatches > 0) `uvm_error("SCB", $sformatf("%0d data mismatch(es)", data_mismatches))
            if (unmatched_apb_txns > 0)
                `uvm_error("SCB", $sformatf("Unmatched APB txns seen: %0d", unmatched_apb_txns))
            if (total_apb != total_ahb_txns)
                `uvm_error("SCB", $sformatf("count mismatch: AHB=%0d APB=%0d", total_ahb_txns, total_apb))
            if (unmatched_ahb > 0)
                `uvm_error("SCB", $sformatf("Unmatched AHB txns remaining: %0d", unmatched_ahb))
        end
    endfunction

endclass
