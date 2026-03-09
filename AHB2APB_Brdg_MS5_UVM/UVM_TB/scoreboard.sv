// AHB2APB Scoreboard: validates DUT responses on the AHB interface.
// Checks HRESP is always OKAY and tracks transaction statistics.
// Note: APB-side signals are not observable in this TB (no APB agent).
class ahb_apb_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(ahb_apb_scoreboard)

    // Receives transactions from the monitor
    uvm_analysis_imp #(sequence_item, ahb_apb_scoreboard) analysis_export;

    // Transaction counters
    int total_txns;
    int write_txns;
    int read_txns;

    // Error counters
    int hresp_errors;

    function new(string name = "ahb_apb_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export = new("analysis_export", this);
    endfunction

    // Called by monitor for every captured transaction
    function void write(sequence_item tx);
        // Only score active, post-reset, bridge-selected transactions
        if (!tx.HRESETn || !tx.HSELAHB) return;
        if (tx.HTRANS != 2'b10 && tx.HTRANS != 2'b11) return;  // skip IDLE/BUSY

        total_txns++;
        if (tx.HWRITE) write_txns++;
        else           read_txns++;

        // HRESP must always be OKAY (2'b00) — RTL hardcodes Hresp = 2'b00
        if (tx.HRESP !== 2'b00) begin
            hresp_errors++;
            `uvm_error("SCB", $sformatf(
                "HRESP ERROR [txn %0d]: expected OKAY(2'b00), got 2'b%02b | HADDR=0x%08h HWRITE=%0b",
                total_txns, tx.HRESP, tx.HADDR, tx.HWRITE))
        end
    endfunction

    function void report_phase(uvm_phase phase);
        string result = (hresp_errors == 0) ? "** PASSED **" : "** FAILED **";
        `uvm_info("SCB", $sformatf({
            "\n======================================\n",
            " Scoreboard Report\n",
            "======================================\n",
            " Total active transactions : %0d\n",
            "   Write transactions      : %0d\n",
            "   Read  transactions      : %0d\n",
            " HRESP errors              : %0d\n",
            "======================================\n",
            " Result: %s\n",
            "======================================"
            },
            total_txns, write_txns, read_txns, hresp_errors, result),
            UVM_NONE)

        if (hresp_errors > 0)
            `uvm_error("SCB", $sformatf("%0d HRESP error(s) detected", hresp_errors))
    endfunction

endclass