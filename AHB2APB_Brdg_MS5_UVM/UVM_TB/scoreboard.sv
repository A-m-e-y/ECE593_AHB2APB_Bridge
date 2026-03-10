// scoreboard has two sections:
//   AHB side  - queues incoming AHB txns from monitor
//   APB side  - matches each APB txn against the queued AHB txn and compares
//               addr (HADDR==PADDR) and write-data (HWDATA==PWDATA for writes)
`uvm_analysis_imp_decl(_ahb)
`uvm_analysis_imp_decl(_apb)

class ahb_apb_scoreboard extends uvm_component;
    `uvm_component_utils(ahb_apb_scoreboard)

    uvm_analysis_imp_ahb #(sequence_item,   ahb_apb_scoreboard) ahb_export;
    uvm_analysis_imp_apb #(apb_transaction, ahb_apb_scoreboard) apb_export;

    // pending AHB txns waiting to be matched with an APB response
    sequence_item ahb_queue[$];

    int total_ahb_txns;
    int hresp_errors;

    int total_apb_writes;
    int total_apb_reads;
    int addr_mismatches;
    int data_mismatches;

    function new(string name = "ahb_apb_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ahb_export = new("ahb_export", this);
        apb_export = new("apb_export", this);
    endfunction

    // just push into queue; the actual check happens when APB side comes in
    function void write_ahb(sequence_item tx);
        sequence_item copy;
        copy = sequence_item::type_id::create("ahb_copy");
        copy.HADDR  = tx.HADDR;
        copy.HWDATA = tx.HWDATA;
        copy.HWRITE = tx.HWRITE;
        copy.HRESP  = tx.HRESP;
        copy.HTRANS = tx.HTRANS;
        ahb_queue.push_back(copy);
        total_ahb_txns++;

        if (tx.HRESP !== 2'b00) begin
            hresp_errors++;
            `uvm_error("SCB", $sformatf(
                "HRESP ERROR [txn %0d]: got 2'b%02b | HADDR=0x%08h",
                total_ahb_txns, tx.HRESP, tx.HADDR))
        end else
            `uvm_info("SCB", $sformatf(
                "[AHB txn %0d] HADDR=0x%08h HWRITE=%0b HWDATA=0x%08h",
                total_ahb_txns, tx.HADDR, tx.HWRITE, tx.HWDATA), UVM_HIGH)
    endfunction

    function void write_apb(apb_transaction apb_tx);
        sequence_item ahb_tx;
        bit addr_ok, data_ok;

        if (ahb_queue.size() == 0) begin
            `uvm_error("SCB", "APB txn arrived but AHB queue is empty — unmatched APB!")
            return;
        end

        ahb_tx = ahb_queue.pop_front();

        if (apb_tx.PWRITE) total_apb_writes++;
        else                total_apb_reads++;

        // address should pass straight through AHB→APB
        addr_ok = (ahb_tx.HADDR === apb_tx.PADDR);
        if (!addr_ok) begin
            addr_mismatches++;
            `uvm_error("SCB", $sformatf(
                "ADDR MISMATCH: AHB HADDR=0x%08h  APB PADDR=0x%08h",
                ahb_tx.HADDR, apb_tx.PADDR))
        end

        // data check only makes sense for writes
        if (apb_tx.PWRITE) begin
            data_ok = (ahb_tx.HWDATA === apb_tx.PWDATA);
            if (!data_ok) begin
                data_mismatches++;
                `uvm_error("SCB", $sformatf(
                    "DATA MISMATCH: AHB HWDATA=0x%08h  APB PWDATA=0x%08h  (PADDR=0x%08h)",
                    ahb_tx.HWDATA, apb_tx.PWDATA, apb_tx.PADDR))
            end else
                `uvm_info("SCB", $sformatf(
                    "[APB write] PADDR=0x%08h PWDATA=0x%08h — addr/data OK",
                    apb_tx.PADDR, apb_tx.PWDATA), UVM_HIGH)
        end else begin
            `uvm_info("SCB", $sformatf(
                "[APB read ] PADDR=0x%08h PRDATA=0x%08h — addr OK",
                apb_tx.PADDR, apb_tx.PRDATA), UVM_HIGH)
        end
    endfunction

    function void report_phase(uvm_phase phase);
        int total_apb = total_apb_writes + total_apb_reads;
        bit passed    = (hresp_errors   == 0 &&
                         addr_mismatches == 0 &&
                         data_mismatches == 0 &&
                         total_ahb_txns  > 0  &&
                         total_apb       == total_ahb_txns);
        string result = passed ? "** PASSED **" : "** FAILED **";

        `uvm_info("SCB", $sformatf({
            "\n======================================\n",
            " Scoreboard Report\n",
            "======================================\n",
            " AHB Transactions : %0d\n",
            " HRESP Errors     : %0d\n",
            " APB Writes       : %0d\n",
            " APB Reads        : %0d\n",
            " APB Total        : %0d\n",
            " Addr Mismatches  : %0d\n",
            " Data Mismatches  : %0d\n",
            "======================================\n",
            " Result: %s\n",
            "======================================"
            },
            total_ahb_txns,  hresp_errors,
            total_apb_writes, total_apb_reads, total_apb,
            addr_mismatches, data_mismatches,
            result),
            UVM_NONE)

        if (!passed) begin
            if (hresp_errors    > 0) `uvm_error("SCB", $sformatf("%0d HRESP error(s)", hresp_errors))
            if (addr_mismatches > 0) `uvm_error("SCB", $sformatf("%0d addr mismatch(es)", addr_mismatches))
            if (data_mismatches > 0) `uvm_error("SCB", $sformatf("%0d data mismatch(es)", data_mismatches))
            if (total_apb != total_ahb_txns)
                `uvm_error("SCB", $sformatf("count mismatch: AHB=%0d APB=%0d", total_ahb_txns, total_apb))
        end
    endfunction

endclass
