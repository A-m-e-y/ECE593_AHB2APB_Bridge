// Functional coverage on AHB-observed transactions.
// Samples sequence_item via uvm_subscriber write().
class ahb_apb_coverage extends uvm_subscriber#(sequence_item);
    `uvm_component_utils(ahb_apb_coverage)

    bit        m_hwrite;
    bit [1:0]  m_htrans;
    bit [1:0]  m_hresp;
    bit        m_hready;
    bit [31:0] m_haddr;
    bit [31:0] m_hwdata;
    bit [31:0] m_hrdata;
    bit        m_hresetn;

    covergroup cg_ahb_protocol;
        option.per_instance = 1;
        option.name = "ahb_protocol_cov";

        cp_hwrite: coverpoint m_hwrite {
            bins read  = {0};
            bins write = {1};
        }
        cp_htrans: coverpoint m_htrans {
            bins nonseq = {2'b10};
            bins seq    = {2'b11};
            ignore_bins idle_busy = {2'b00, 2'b01};
        }
        cp_hresp: coverpoint m_hresp {
            bins okay     = {2'b00};
            bins not_okay = default;
        }
        cp_hready: coverpoint m_hready {
            bins ready = {1};
            ignore_bins not_ready = {0};
        }
        cx_htrans_hwrite: cross cp_htrans, cp_hwrite;
    endgroup

    covergroup cg_addr_decode;
        option.per_instance = 1;
        option.name = "ahb_addr_decode_cov";

        cp_haddr: coverpoint m_haddr {
            bins slave1_range  = {[32'h8000_0000 : 32'h83FF_FFFF]};
            bins slave2_range  = {[32'h8400_0000 : 32'h87FF_FFFF]};
            bins slave3_range  = {[32'h8800_0000 : 32'h8BFF_FFFF]};
        }
        cx_rw_addr: cross cp_haddr, m_hwrite;
    endgroup

    covergroup cg_transfer_sequences;
        option.per_instance = 1;
        option.name = "transfer_sequences_cov";

        cp_htrans_seq: coverpoint m_htrans {
            bins nonseq_to_nonseq = (2'b10 => 2'b10);
            bins nonseq_to_seq    = (2'b10 => 2'b11);
            bins seq_to_seq       = (2'b11 => 2'b11);
            bins seq_to_nonseq    = (2'b11 => 2'b10);
        }
        cp_rw_seq: coverpoint m_hwrite {
            bins write_to_write = (1 => 1);
            bins write_to_read  = (1 => 0);
            bins read_to_write  = (0 => 1);
            bins read_to_read   = (0 => 0);
        }
    endgroup

    covergroup cg_data_boundary;
        option.per_instance = 1;
        option.name = "data_boundary_cov";

        cp_reset: coverpoint m_hresetn {
            bins reset_inactive = {1};
            ignore_bins reset_active = {0};
        }
        cp_addr_boundary: coverpoint m_haddr {
            bins s1_min = {32'h8000_0000};
            bins s1_max = {32'h83FF_FFFC};
            bins s2_min = {32'h8400_0000};
            bins s2_max = {32'h87FF_FFFC};
            bins s3_min = {32'h8800_0000};
            bins s3_max = {32'h8BFF_FFFC};
        }
        cp_wdata_pattern: coverpoint m_hwdata iff (m_hwrite) {
            bins all_zeros = {32'h0000_0000};
            bins all_ones  = {32'hFFFF_FFFF};
            bins a5_prefix = {[32'hA5A5_0000:32'hA5A5_FFFF]};
            bins other     = default;
        }
        cp_rdata_pattern: coverpoint m_hrdata iff (!m_hwrite) {
            bins all_zeros = {32'h0000_0000};
            bins all_ones  = {32'hFFFF_FFFF};
            bins d00d_data = {[32'hD00D_0000:32'hD00D_FFFF]};
            bins other     = default;
        }
    endgroup

    function new(string name = "ahb_apb_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_ahb_protocol          = new();
        cg_addr_decode           = new();
        cg_transfer_sequences    = new();
        cg_data_boundary         = new();
    endfunction

    function void write(sequence_item t);
        m_hwrite  = t.HWRITE;
        m_htrans  = t.HTRANS;
        m_hresp   = t.HRESP;
        m_hready  = t.HREADY;
        m_haddr   = t.HADDR;
        m_hwdata  = t.HWDATA;
        m_hrdata  = t.HRDATA;
        m_hresetn = t.HRESETn;

        cg_ahb_protocol.sample();
        cg_addr_decode.sample();
        cg_data_boundary.sample();
        cg_transfer_sequences.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        real ahb_prot, ahb_addr, tx_seq, data_bound, total;

        ahb_prot = cg_ahb_protocol.get_inst_coverage();
        ahb_addr = cg_addr_decode.get_inst_coverage();
        tx_seq   = cg_transfer_sequences.get_inst_coverage();
        data_bound = cg_data_boundary.get_inst_coverage();
        total      = (ahb_prot + ahb_addr + tx_seq + data_bound) / 4.0;

        `uvm_info("COV", $sformatf({
            "\n========================================\n",
            " AHB Functional Coverage Report\n",
            "========================================\n",
            " AHB Protocol    : %0.2f%%\n",
            " Addr Decode     : %0.2f%%\n",
            " Transfer Seq    : %0.2f%%\n",
            " Data/Boundary   : %0.2f%%\n",
            "----------------------------------------\n",
            " TOTAL (avg)     : %0.2f%%\n",
            "========================================"
            },
            ahb_prot, ahb_addr, tx_seq, data_bound, total),
            UVM_NONE)
    endfunction

endclass
