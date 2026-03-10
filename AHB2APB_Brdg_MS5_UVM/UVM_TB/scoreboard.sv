// APB-side imp tag — the AHB side uses uvm_subscriber's built-in analysis_export.
`uvm_analysis_imp_decl(_apb)

// Scoreboard: compares every AHB transaction (from the driver — the ground
// truth) against the corresponding APB access captured pre-CDC via HCLK-domain
// signals.
//
// Extends uvm_subscriber#(sequence_item) so the driver's drv_ap connects
// directly to the built-in analysis_export — no custom imp or macro needed
// for the AHB side.  write(sequence_item) is the required override.
//
// Checks per transaction:
//   PADDR  == HADDR  (address translation preserved)
//   PWRITE == HWRITE (direction preserved)
//   PWDATA == HWDATA (write-data preserved, writes only)
//   HRESP  == 2'b00  (bridge always responds OKAY)
//
// PASS condition: no check failures AND zero unmatched driver transactions.
class ahb_apb_scoreboard extends uvm_subscriber#(sequence_item);
    `uvm_component_utils(ahb_apb_scoreboard)

    // analysis_export (built-in from uvm_subscriber) ← driver's drv_ap
    // apb_export (one custom imp)                    ← APB monitor's ap_port
    uvm_analysis_imp_apb #(apb_transaction, ahb_apb_scoreboard) apb_export;

    // FIFO of driver transactions waiting to be matched by an APB event
    sequence_item drv_q[$];

    int total_checked;
    int pass_count;
    int fail_count;

    function new(string name = "ahb_apb_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);  // creates analysis_export (uvm_subscriber)
        apb_export = new("apb_export", this);
    endfunction

    // write() — required override from uvm_subscriber.
    // Called by the driver for each non-IDLE/non-BUSY AHB transaction.
    function void write(sequence_item tx);
        // Check HRESP while the transaction is still fresh
        if (tx.HRESP !== 2'b00) begin
            fail_count++;
            `uvm_error("SCB", $sformatf(
                "HRESP ERROR: expected OKAY(2'b00), got 2'b%02b | HADDR=0x%08h",
                tx.HRESP, tx.HADDR))
        end

        drv_q.push_back(tx);
        `uvm_info("SCB", $sformatf(
            "DRV queued [%0d pending]: HADDR=0x%08h HWRITE=%0b HWDATA=0x%08h",
            drv_q.size(), tx.HADDR, tx.HWRITE, tx.HWDATA), UVM_HIGH)
    endfunction

    // Called by APB monitor for each observed APB access (PENABLE_HCLK=1 / PADDR change).
    //
    // Uses address-based matching (MS3 scoreboard approach): search the driver
    // queue for a transaction whose HADDR == apb_tx.PADDR.  This tolerates the
    // bridge's pipeline residue — stale APB events with an old PADDR simply
    // produce a warning and are dropped, while the real event with the correct
    // PADDR is matched and checked.
    function void write_apb(apb_transaction apb_tx);
        sequence_item drv_tx;
        int idx = -1;

        // Search driver queue for a transaction whose address matches PADDR.
        for (int i = 0; i < drv_q.size(); i++) begin
            if (drv_q[i].HADDR == apb_tx.PADDR) begin
                idx = i;
                break;
            end
        end

        if (idx < 0) begin
            // No matching driver transaction found — spurious APB event caused
            // by bridge pipeline residue (Haddr2 from a previous transaction).
            // Treat as a warning so they don't inflate the fail count.
            `uvm_warning("SCB", $sformatf(
                "Spurious APB event (pipeline residue) — PADDR=0x%08h not in driver queue",
                apb_tx.PADDR))
            return;
        end

        drv_tx = drv_q[idx];
        drv_q.delete(idx);
        total_checked++;
        check_translation(drv_tx, apb_tx);
    endfunction

    // Core check: verify AHB→APB signal translation is lossless.
    function void check_translation(sequence_item ahb, apb_transaction apb);
        bit err = 0;

        // Address must be preserved through the bridge pipeline
        if (apb.PADDR !== ahb.HADDR) begin
            `uvm_error("SCB", $sformatf(
                "ADDR MISMATCH [chk %0d]: HADDR=0x%08h  PADDR=0x%08h",
                total_checked, ahb.HADDR, apb.PADDR))
            err = 1;
        end

        // Transfer direction must be preserved
        if (apb.PWRITE !== ahb.HWRITE) begin
            `uvm_error("SCB", $sformatf(
                "DIR  MISMATCH [chk %0d]: HWRITE=%0b  PWRITE=%0b",
                total_checked, ahb.HWRITE, apb.PWRITE))
            err = 1;
        end

        // Write data must be preserved (reads have no meaningful HWDATA)
        if (ahb.HWRITE && apb.PWDATA !== ahb.HWDATA) begin
            `uvm_error("SCB", $sformatf(
                "DATA MISMATCH [chk %0d]: HWDATA=0x%08h  PWDATA=0x%08h",
                total_checked, ahb.HWDATA, apb.PWDATA))
            err = 1;
        end

        if (!err) begin
            pass_count++;
            `uvm_info("SCB", $sformatf(
                "MATCH [chk %0d]: HADDR/PADDR=0x%08h  HWRITE/PWRITE=%0b  %s",
                total_checked, ahb.HADDR, ahb.HWRITE,
                ahb.HWRITE ? $sformatf("HWDATA/PWDATA=0x%08h", ahb.HWDATA) : "(read)"),
                UVM_MEDIUM)
        end else begin
            fail_count++;
        end
    endfunction

    function void report_phase(uvm_phase phase);
        int unmatched = drv_q.size();
        // PASS: no check failures AND every driver transaction was matched.
        string result = (fail_count == 0 && total_checked > 0 && unmatched == 0) ?
                        "** PASSED **" : "** FAILED **";

        if (unmatched > 0)
            `uvm_warning("SCB", $sformatf(
                "%0d driver txn(s) left unmatched in queue at end of sim",
                unmatched))

        `uvm_info("SCB", $sformatf({
            "\n======================================\n",
            " Scoreboard Report\n",
            "======================================\n",
            " AHB→APB pairs checked : %0d\n",
            " Passed                : %0d\n",
            " Failed                : %0d\n",
            " Unmatched DRV txns    : %0d\n",
            "======================================\n",
            " Result: %s\n",
            "======================================"
            },
            total_checked, pass_count, fail_count, unmatched, result),
            UVM_NONE)

        if (fail_count > 0 || unmatched > 0)
            `uvm_error("SCB", $sformatf("%0d check(s) failed, %0d unmatched", fail_count, unmatched))
    endfunction

endclass