// APB-side imp tag — the AHB side uses uvm_subscriber's built-in analysis_export.
`uvm_analysis_imp_decl(_cov_apb)

// Functional coverage subscriber for the AHB2APB bridge.
//
// Extends uvm_subscriber#(sequence_item) so the driver's drv_ap connects
// directly to the built-in analysis_export — no custom imp or macro needed
// for the AHB side.  write(sequence_item) is the required override.
//
// The APB monitor's ap_port connects to cov_apb_export (one custom imp).
//
// Both analysis_export and cov_apb_export are wired in env so scoreboard
// and coverage receive the same data simultaneously from each monitor.
//
// Covergroups ported from MS3 coverage_collector, adapted for transaction-based
// sampling.  FSM-state groups are omitted (FSM state not observable through txns).

class ahb_apb_coverage extends uvm_subscriber#(sequence_item);
    `uvm_component_utils(ahb_apb_coverage)

    // analysis_export (built-in from uvm_subscriber) ← driver's drv_ap
    // cov_apb_export (one custom imp)                ← APB monitor's ap_port
    uvm_analysis_imp_cov_apb #(apb_transaction, ahb_apb_coverage) cov_apb_export;

    // ------------------------------------------------------------------
    // Sampled state — set immediately before each covergroup.sample() call
    // ------------------------------------------------------------------
    bit        m_hwrite;
    bit [1:0]  m_htrans;
    bit [1:0]  m_hresp;
    bit        m_hready;
    bit [31:0] m_haddr;
    bit [31:0] m_hwdata;
    bit        m_hresetn;

    bit        m_pwrite;
    bit [2:0]  m_pselx;
    bit [31:0] m_paddr;

    // ------------------------------------------------------------------
    // AHB Protocol coverage — sampled per driver transaction
    // Covers transfer direction, type, bridge response, and ready signal.
    // ------------------------------------------------------------------
    covergroup cg_ahb_protocol;
        option.per_instance = 1;
        option.name = "ahb_protocol_cov";

        cp_hwrite: coverpoint m_hwrite {
            bins read  = {0};
            bins write = {1};
        }
        cp_htrans: coverpoint m_htrans {
            bins idle   = {2'b00};
            bins busy   = {2'b01};
            bins nonseq = {2'b10};
            bins seq    = {2'b11};
        }
        cp_hresp: coverpoint m_hresp {
            bins okay = {2'b00};
        }
        cp_hready: coverpoint m_hready {
            bins ready     = {1};
            bins not_ready = {0};
        }
        // Useful cross: which transfer types are exercised as reads vs writes
        cx_htrans_hwrite: cross cp_htrans, cp_hwrite;
    endgroup

    // ------------------------------------------------------------------
    // APB Protocol coverage — sampled per APB monitor transaction
    // Covers which slave is selected, transfer direction, and their cross.
    // ------------------------------------------------------------------
    covergroup cg_apb_protocol;
        option.per_instance = 1;
        option.name = "apb_protocol_cov";

        cp_pselx: coverpoint m_pselx {
            bins slave0  = {3'b001};
            bins slave1  = {3'b010};
            bins slave2  = {3'b100};
            bins none    = {3'b000};
            bins invalid = default;
        }
        cp_pwrite: coverpoint m_pwrite {
            bins read  = {0};
            bins write = {1};
        }
        cx_slave_rw: cross cp_pselx, cp_pwrite {
            ignore_bins no_slave = binsof(cp_pselx) intersect {3'b000};
        }
    endgroup

    // ------------------------------------------------------------------
    // AHB address-range coverage — sampled per AHB transaction
    // Verifies all three slave address regions are exercised on the AHB side.
    // ------------------------------------------------------------------
    covergroup cg_ahb_addr_mapping;
        option.per_instance = 1;
        option.name = "ahb_address_mapping_cov";

        cp_haddr: coverpoint m_haddr {
            bins slave0_range = {[32'h8000_0000 : 32'h83FF_FFFF]};
            bins slave1_range = {[32'h8400_0000 : 32'h87FF_FFFF]};
            bins slave2_range = {[32'h8800_0000 : 32'h8BFF_FFFF]};
            bins other_range  = default;
        }
    endgroup

    // ------------------------------------------------------------------
    // APB address-range coverage — sampled per APB transaction
    // Verifies address is correctly passed through the bridge to each slave.
    // ------------------------------------------------------------------
    covergroup cg_apb_addr_mapping;
        option.per_instance = 1;
        option.name = "apb_address_mapping_cov";

        cp_paddr: coverpoint m_paddr {
            bins slave0_range = {[32'h8000_0000 : 32'h83FF_FFFF]};
            bins slave1_range = {[32'h8400_0000 : 32'h87FF_FFFF]};
            bins slave2_range = {[32'h8800_0000 : 32'h8BFF_FFFF]};
            bins other_range  = default;
        }
    endgroup

    // ------------------------------------------------------------------
    // Transaction sequence coverage — sampled per AHB transaction
    // Transition bins automatically track the previous sampled value.
    // Covers back-to-back patterns, NONSEQ→IDLE, read→write, etc.
    // ------------------------------------------------------------------
    covergroup cg_transaction_sequences;
        option.per_instance = 1;
        option.name = "transaction_sequences_cov";

        cp_htrans_seq: coverpoint m_htrans {
            bins idle_to_nonseq   = (2'b00 => 2'b10);
            bins nonseq_to_nonseq = (2'b10 => 2'b10);
            bins nonseq_to_idle   = (2'b10 => 2'b00);
            bins seq_to_seq       = (2'b11 => 2'b11);
            bins seq_to_idle      = (2'b11 => 2'b00);
        }
        cp_rw_seq: coverpoint m_hwrite {
            bins write_to_write = (1 => 1);
            bins write_to_read  = (1 => 0);
            bins read_to_write  = (0 => 1);
            bins read_to_read   = (0 => 0);
        }
    endgroup

    // ------------------------------------------------------------------
    // Corner-case coverage — sampled per AHB transaction
    // Covers reset handling, slave boundary addresses, and HWDATA patterns.
    // ------------------------------------------------------------------
    covergroup cg_corner_cases;
        option.per_instance = 1;
        option.name = "corner_cases_cov";

        cp_reset: coverpoint m_hresetn {
            bins reset_inactive = {1};
            bins reset_deassert = (0 => 1);
        }
        cp_addr_boundary: coverpoint m_haddr {
            bins addr_slave0_min = {32'h8000_0000};
            bins addr_slave0_max = {32'h83FF_FFFF};
            bins addr_slave1_min = {32'h8400_0000};
            bins addr_slave2_min = {32'h8800_0000};
        }
        cp_wdata_pattern: coverpoint m_hwdata {
            bins all_zeros = {32'h0000_0000};
            bins all_ones  = {32'hFFFF_FFFF};
        }
    endgroup

    // ------------------------------------------------------------------
    function new(string name = "ahb_apb_coverage", uvm_component parent = null);
        super.new(name, parent);
        // Covergroups must be constructed in new() so they are ready before
        // the first sample() call during build/connect phases.
        cg_ahb_protocol          = new();
        cg_apb_protocol          = new();
        cg_ahb_addr_mapping      = new();
        cg_apb_addr_mapping      = new();
        cg_transaction_sequences = new();
        cg_corner_cases          = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);  // creates analysis_export (uvm_subscriber)
        cov_apb_export = new("cov_apb_export", this);
    endfunction

    // write() — required override from uvm_subscriber.
    // Called by the driver's drv_ap for each non-IDLE AHB transaction.
    function void write(sequence_item tx);
        m_hwrite  = tx.HWRITE;
        m_htrans  = tx.HTRANS;
        m_hresp   = tx.HRESP;
        m_hready  = tx.HREADY;
        m_haddr   = tx.HADDR;
        m_hwdata  = tx.HWDATA;
        m_hresetn = tx.HRESETn;

        cg_ahb_protocol.sample();
        cg_ahb_addr_mapping.sample();
        cg_corner_cases.sample();
        cg_transaction_sequences.sample();  // transition bins track history automatically
    endfunction

    // Called by the APB monitor's ap_port for each observed APB access.
    function void write_cov_apb(apb_transaction tx);
        m_pwrite = tx.PWRITE;
        m_pselx  = tx.PSELX;
        m_paddr  = tx.PADDR;

        cg_apb_protocol.sample();
        cg_apb_addr_mapping.sample();
    endfunction

    // ------------------------------------------------------------------
    function void report_phase(uvm_phase phase);
        real ahb_prot, apb_prot, ahb_addr, apb_addr, tx_seq, corner, total;

        ahb_prot = cg_ahb_protocol.get_inst_coverage();
        apb_prot = cg_apb_protocol.get_inst_coverage();
        ahb_addr = cg_ahb_addr_mapping.get_inst_coverage();
        apb_addr = cg_apb_addr_mapping.get_inst_coverage();
        tx_seq   = cg_transaction_sequences.get_inst_coverage();
        corner   = cg_corner_cases.get_inst_coverage();
        total    = (ahb_prot + apb_prot + ahb_addr + apb_addr + tx_seq + corner) / 6.0;

        `uvm_info("COV", $sformatf({
            "\n========================================\n",
            " Functional Coverage Report\n",
            "========================================\n",
            " AHB Protocol    : %0.2f%%\n",
            " APB Protocol    : %0.2f%%\n",
            " AHB Addr Ranges : %0.2f%%\n",
            " APB Addr Ranges : %0.2f%%\n",
            " TX Sequences    : %0.2f%%\n",
            " Corner Cases    : %0.2f%%\n",
            "----------------------------------------\n",
            " TOTAL (avg)     : %0.2f%%\n",
            "========================================"
            },
            ahb_prot, apb_prot, ahb_addr, apb_addr, tx_seq, corner, total),
            UVM_NONE)
    endfunction

endclass
