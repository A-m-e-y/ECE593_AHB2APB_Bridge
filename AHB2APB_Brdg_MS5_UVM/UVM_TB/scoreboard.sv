// scoreboard has two sections:
//   AHB side  - gets sequence_item from AHB monitor, checks HRESP
//   APB side  - gets apb_transaction from slave model, counts responses
// both sections print in report_phase
`uvm_analysis_imp_decl(_ahb)
`uvm_analysis_imp_decl(_apb)

class ahb_apb_scoreboard extends uvm_component;
    `uvm_component_utils(ahb_apb_scoreboard)

    uvm_analysis_imp_ahb #(sequence_item,    ahb_apb_scoreboard) ahb_export;
    uvm_analysis_imp_apb #(apb_transaction,  ahb_apb_scoreboard) apb_export;

    int total_ahb_txns;
    int hresp_errors;

    int total_apb_writes;
    int total_apb_reads;

    function new(string name = "ahb_apb_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ahb_export = new("ahb_export", this);
        apb_export = new("apb_export", this);
    endfunction

    function void write_ahb(sequence_item tx);
        total_ahb_txns++;
        if (tx.HRESP !== 2'b00) begin
            hresp_errors++;
            `uvm_error("SCB", $sformatf(
                "HRESP ERROR [AHB txn %0d]: expected OKAY got 2'b%02b | HADDR=0x%08h",
                total_ahb_txns, tx.HRESP, tx.HADDR))
        end else begin
            `uvm_info("SCB", $sformatf(
                "[AHB txn %0d] HADDR=0x%08h HWRITE=%0b HWDATA=0x%08h — HRESP=OKAY",
                total_ahb_txns, tx.HADDR, tx.HWRITE, tx.HWDATA), UVM_HIGH)
        end
    endfunction

    function void write_apb(apb_transaction tx);
        if (tx.PWRITE) begin
            total_apb_writes++;
            `uvm_info("SCB", $sformatf(
                "[APB write %0d] PSELX=3'b%03b PADDR=0x%08h PWDATA=0x%08h",
                total_apb_writes, tx.PSELX, tx.PADDR, tx.PWDATA), UVM_HIGH)
        end else begin
            total_apb_reads++;
            `uvm_info("SCB", $sformatf(
                "[APB read  %0d] PSELX=3'b%03b PADDR=0x%08h PRDATA=0x%08h",
                total_apb_reads, tx.PSELX, tx.PADDR, tx.PRDATA), UVM_HIGH)
        end
    endfunction

    function void report_phase(uvm_phase phase);
        int total_apb = total_apb_writes + total_apb_reads;
        bit ahb_ok    = (hresp_errors == 0 && total_ahb_txns > 0);
        bit apb_ok    = (total_apb == total_ahb_txns);
        string result = (ahb_ok && apb_ok) ? "** PASSED **" : "** FAILED **";

        `uvm_info("SCB", $sformatf({
            "\n======================================\n",
            " Scoreboard Report\n",
            "======================================\n",
            " --- AHB Side (monitor) ---\n",
            " AHB Transactions : %0d\n",
            " HRESP Errors     : %0d\n",
            " --- APB Side (slave model) ---\n",
            " APB Writes       : %0d\n",
            " APB Reads        : %0d\n",
            " APB Total        : %0d\n",
            "======================================\n",
            " Result: %s\n",
            "======================================"
            },
            total_ahb_txns, hresp_errors,
            total_apb_writes, total_apb_reads, total_apb,
            result),
            UVM_NONE)

        if (hresp_errors > 0)
            `uvm_error("SCB", $sformatf("%0d HRESP error(s) detected", hresp_errors))
        if (!apb_ok)
            `uvm_error("SCB", $sformatf(
                "APB/AHB count mismatch: AHB=%0d APB=%0d",
                total_ahb_txns, total_apb))
    endfunction

endclass
