// functional coverage for AHB side
// gets sequence_item from monitor via built-in analysis_export (uvm_subscriber)
class ahb_apb_coverage extends uvm_subscriber#(sequence_item);
    `uvm_component_utils(ahb_apb_coverage)

    bit        m_hwrite;
    bit [1:0]  m_htrans;
    bit [1:0]  m_hresp;
    bit        m_hready;
    bit [31:0] m_haddr;
    bit [31:0] m_hwdata;
    bit        m_hresetn;

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
        cx_htrans_hwrite: cross cp_htrans, cp_hwrite;
    endgroup

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

    function new(string name = "ahb_apb_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_ahb_protocol          = new();
        cg_ahb_addr_mapping      = new();
        cg_transaction_sequences = new();
        cg_corner_cases          = new();
    endfunction

    function void write(sequence_item t);
        m_hwrite  = t.HWRITE;
        m_htrans  = t.HTRANS;
        m_hresp   = t.HRESP;
        m_hready  = t.HREADY;
        m_haddr   = t.HADDR;
        m_hwdata  = t.HWDATA;
        m_hresetn = t.HRESETn;

        cg_ahb_protocol.sample();
        cg_ahb_addr_mapping.sample();
        cg_corner_cases.sample();
        cg_transaction_sequences.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        real ahb_prot, ahb_addr, tx_seq, corner, total;

        ahb_prot = cg_ahb_protocol.get_inst_coverage();
        ahb_addr = cg_ahb_addr_mapping.get_inst_coverage();
        tx_seq   = cg_transaction_sequences.get_inst_coverage();
        corner   = cg_corner_cases.get_inst_coverage();
        total    = (ahb_prot + ahb_addr + tx_seq + corner) / 4.0;

        `uvm_info("COV", $sformatf({
            "\n========================================\n",
            " AHB Functional Coverage Report\n",
            "========================================\n",
            " AHB Protocol    : %0.2f%%\n",
            " AHB Addr Ranges : %0.2f%%\n",
            " TX Sequences    : %0.2f%%\n",
            " Corner Cases    : %0.2f%%\n",
            "----------------------------------------\n",
            " TOTAL (avg)     : %0.2f%%\n",
            "========================================"
            },
            ahb_prot, ahb_addr, tx_seq, corner, total),
            UVM_NONE)
    endfunction

endclass
