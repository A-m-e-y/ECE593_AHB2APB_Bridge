// MS3-style functional coverage adapted for UVM component sampling.
// AHB/APB/FSM/CDC groups are sampled from virtual interface activity.
// Data-boundary bins are sampled from monitor transactions.
class ahb_apb_coverage extends uvm_subscriber#(sequence_item);
    `uvm_component_utils(ahb_apb_coverage)

    localparam bit [2:0] ST_IDLE     = 3'b000;
    localparam bit [2:0] ST_WWAIT    = 3'b001;
    localparam bit [2:0] ST_READ     = 3'b010;
    localparam bit [2:0] ST_WRITE    = 3'b011;
    localparam bit [2:0] ST_WRITEP   = 3'b100;
    localparam bit [2:0] ST_RENABLE  = 3'b101;
    localparam bit [2:0] ST_WENABLE  = 3'b110;
    localparam bit [2:0] ST_WENABLEP = 3'b111;

    localparam bit [1:0] IDLE   = 2'b00;
    localparam bit [1:0] BUSY   = 2'b01;
    localparam bit [1:0] NONSEQ = 2'b10;
    localparam bit [1:0] SEQ    = 2'b11;

    virtual intf full_vif;

    // Transaction-level samples from AHB monitor.
    bit        m_hwrite_tx;
    bit [1:0]  m_htrans_tx;
    bit [1:0]  m_hresp_tx;
    bit        m_hready_tx;
    bit [31:0] m_haddr_tx;
    bit [31:0] m_hwdata_tx;
    bit [31:0] m_hrdata_tx;
    bit        m_hresetn_tx;

    // Bus-level samples from virtual interface.
    bit        m_hwrite_bus;
    bit [1:0]  m_htrans_bus;
    bit [2:0]  m_hsize_bus;
    bit [2:0]  m_hburst_bus;
    bit [1:0]  m_hresp_bus;
    bit        m_hready_bus;
    bit [31:0] m_haddr_bus;
    bit        m_hresetn_bus;

    bit        m_valid_hclk;
    bit [2:0]  m_pselx_hclk;
    bit        m_penable_hclk;
    bit        m_pwrite_hclk;
    bit [31:0] m_paddr_hclk;
    bit [2:0]  m_fsm_state_hclk;

    bit [2:0]  m_pselx_pclk;
    bit        m_penable_pclk;
    bit        m_pwrite_pclk;

    function automatic bit is_valid_htrans(bit [1:0] htrans);
        return (htrans == NONSEQ) || (htrans == SEQ);
    endfunction

    covergroup cg_ahb_protocol;
        option.per_instance = 1;
        option.name = "ahb_protocol_cov";

        cp_hwrite: coverpoint m_hwrite_bus iff (m_hresetn_bus) {
            bins read  = {0};
            bins write = {1};
        }
        cp_htrans: coverpoint m_htrans_bus iff (m_hresetn_bus) {
            bins idle   = {IDLE};
            bins busy   = {BUSY};
            bins nonseq = {NONSEQ};
            bins seq    = {SEQ};
        }
        cp_hsize: coverpoint m_hsize_bus iff (m_hresetn_bus) {
            bins size_word = {3'b010};
            ignore_bins non_word = {3'b000, 3'b001, 3'b011, 3'b100, 3'b101, 3'b110, 3'b111};
        }
        cp_hburst: coverpoint m_hburst_bus iff (m_hresetn_bus) {
            bins single = {3'b000};
            ignore_bins non_single = {3'b001, 3'b010, 3'b011, 3'b100, 3'b101, 3'b110, 3'b111};
        }
        cp_hresp: coverpoint m_hresp_bus iff (m_hresetn_bus) {
            bins okay  = {2'b00};
            bins error = {2'b01};
            ignore_bins others = {2'b10, 2'b11};
        }
        cp_valid: coverpoint m_valid_hclk iff (m_hresetn_bus) {
            bins asserted   = {1};
            bins deasserted = {0};
        }
        cp_hready: coverpoint m_hready_bus iff (m_hresetn_bus) {
            bins ready     = {1};
            bins not_ready = {0};
        }
        cx_htrans_hwrite: cross cp_htrans, cp_hwrite {
            ignore_bins idle_busy =
                binsof(cp_htrans) intersect {IDLE, BUSY};
        }
    endgroup

    covergroup cg_apb_protocol;
        option.per_instance = 1;
        option.name = "apb_protocol_cov";

        cp_pselx: coverpoint m_pselx_hclk iff (m_hresetn_bus) {
            bins none   = {3'b000};
            bins slave1 = {3'b001};
            bins slave2 = {3'b010};
            bins slave3 = {3'b100};
            ignore_bins invalid = {3'b011, 3'b101, 3'b110, 3'b111};
        }
        cp_penable: coverpoint m_penable_hclk iff (m_hresetn_bus) {
            bins setup  = {0};
            bins access = {1};
        }
        cp_pwrite: coverpoint m_pwrite_hclk iff (m_hresetn_bus) {
            bins read  = {0};
            bins write = {1};
        }
        cp_apb_phase: coverpoint {m_pselx_hclk != 3'b000, m_penable_hclk} iff (m_hresetn_bus) {
            bins setup_phase  = {2'b10};
            bins access_phase = {2'b11};
            bins idle_phase   = {2'b00};
            ignore_bins invalid_phase = {2'b01};
        }
        cx_slave_rw: cross cp_pselx, cp_pwrite {
            ignore_bins no_slave = binsof(cp_pselx) intersect {3'b000};
        }
        cx_slave_enable: cross cp_pselx, cp_penable {
            ignore_bins no_slave = binsof(cp_pselx) intersect {3'b000};
        }
    endgroup

    covergroup cg_fsm_states;
        option.per_instance = 1;
        option.name = "fsm_state_cov";

        cp_state: coverpoint m_fsm_state_hclk iff (m_hresetn_bus) {
            bins idle     = {ST_IDLE};
            bins wwait    = {ST_WWAIT};
            bins read     = {ST_READ};
            bins write    = {ST_WRITE};
            bins writep   = {ST_WRITEP};
            bins renable  = {ST_RENABLE};
            bins wenable  = {ST_WENABLE};
            bins wenablep = {ST_WENABLEP};
        }
    endgroup

    covergroup cg_fsm_transitions;
        option.per_instance = 1;
        option.name = "fsm_transition_cov";

        cp_state_trans: coverpoint m_fsm_state_hclk iff (m_hresetn_bus) {
            bins idle_to_wwait    = (ST_IDLE => ST_WWAIT);
            bins idle_to_read     = (ST_IDLE => ST_READ);
            bins idle_stay        = (ST_IDLE => ST_IDLE);

            bins wwait_to_writep  = (ST_WWAIT => ST_WRITEP);

            bins read_to_renable  = (ST_READ => ST_RENABLE);

            bins write_to_wenable  = (ST_WRITE => ST_WENABLE);

            bins writep_to_wenablep = (ST_WRITEP => ST_WENABLEP);

            bins renable_to_idle  = (ST_RENABLE => ST_IDLE);
            bins renable_to_read  = (ST_RENABLE => ST_READ);

            bins wenablep_to_write  = (ST_WENABLEP => ST_WRITE);
            bins wenablep_to_writep = (ST_WENABLEP => ST_WRITEP);
            bins wenablep_to_read   = (ST_WENABLEP => ST_READ);

            bins pipelined_writes = (ST_IDLE => ST_WWAIT => ST_WRITEP => ST_WENABLEP);

            // Mark architecturally unreachable transitions as ignored.
            ignore_bins unreachable = (ST_WWAIT   => ST_WRITE),
                                      (ST_WRITE   => ST_WENABLEP),
                                      (ST_RENABLE => ST_WWAIT),
                                      (ST_WENABLE => ST_IDLE),
                                      (ST_WENABLE => ST_WWAIT),
                                      (ST_WENABLE => ST_READ);
        }
    endgroup

    covergroup cg_address_mapping;
        option.per_instance = 1;
        option.name = "address_mapping_cov";

        cp_haddr: coverpoint m_haddr_bus iff (m_hresetn_bus && is_valid_htrans(m_htrans_bus)) {
            bins slave1_range = {[32'h8000_0000:32'h83FF_FFFF]};
            bins slave2_range = {[32'h8400_0000:32'h87FF_FFFF]};
            bins slave3_range = {[32'h8800_0000:32'h8BFF_FFFF]};
        }
        cp_paddr: coverpoint m_paddr_hclk iff (m_hresetn_bus && (m_pselx_hclk != 3'b000)) {
            bins slave1_range = {[32'h8000_0000:32'h83FF_FFFF]};
            bins slave2_range = {[32'h8400_0000:32'h87FF_FFFF]};
            bins slave3_range = {[32'h8800_0000:32'h8BFF_FFFF]};
        }
    endgroup

    covergroup cg_cdc;
        option.per_instance = 1;
        option.name = "cdc_coverage";

        cp_penable_trans: coverpoint m_penable_pclk iff (m_hresetn_bus) {
            bins low_to_high = (0 => 1);
            bins high_to_low = (1 => 0);
            bins stay_high   = (1 => 1);
            bins stay_low    = (0 => 0);
        }
        cp_pselx_change: coverpoint m_pselx_pclk iff (m_hresetn_bus) {
            bins none_to_slave1 = (3'b000 => 3'b001);
            bins none_to_slave2 = (3'b000 => 3'b010);
            bins none_to_slave3 = (3'b000 => 3'b100);
            bins slave1_to_none = (3'b001 => 3'b000);
            bins slave2_to_none = (3'b010 => 3'b000);
            bins slave3_to_none = (3'b100 => 3'b000);
            bins slave_change = (3'b001 => 3'b010), (3'b010 => 3'b100), (3'b001 => 3'b100),
                                (3'b010 => 3'b001), (3'b100 => 3'b010), (3'b100 => 3'b001);
        }
        cp_pwrite: coverpoint m_pwrite_pclk iff (m_hresetn_bus) {
            bins read  = {0};
            bins write = {1};
        }
        cx_penable_pwrite: cross cp_penable_trans, cp_pwrite;
    endgroup

    covergroup cg_transfer_sequences;
        option.per_instance = 1;
        option.name = "transfer_sequences_cov";

        cp_htrans_seq: coverpoint m_htrans_bus iff (m_hresetn_bus) {
            bins nonseq_to_idle   = (NONSEQ => IDLE);
            bins nonseq_to_nonseq = (NONSEQ => NONSEQ);
            bins nonseq_to_seq    = (NONSEQ => SEQ);
            bins seq_to_seq       = (SEQ => SEQ);
            bins seq_to_idle      = (SEQ => IDLE);
            bins seq_to_nonseq    = (SEQ => NONSEQ);
            bins idle_to_nonseq   = (IDLE => NONSEQ);
        }
        cp_rw_seq: coverpoint m_hwrite_bus iff (m_hresetn_bus && is_valid_htrans(m_htrans_bus)) {
            bins write_to_write = (1 => 1);
            bins write_to_read  = (1 => 0);
            bins read_to_write  = (0 => 1);
            bins read_to_read   = (0 => 0);
        }
    endgroup

    covergroup cg_data_boundary;
        option.per_instance = 1;
        option.name = "data_boundary_cov";

        cp_reset: coverpoint m_hresetn_tx {
            bins reset_inactive = {1};
            ignore_bins reset_active = {0};
            // write() samples completed transactions, so reset deassert edge is not observable here
            ignore_bins reset_deassert = (0 => 1);
        }
        cp_addr_boundary: coverpoint m_haddr_tx {
            bins s1_min = {32'h8000_0000};
            bins s1_max = {32'h83FF_FFFC};
            bins s2_min = {32'h8400_0000};
            bins s2_max = {32'h87FF_FFFC};
            bins s3_min = {32'h8800_0000};
            bins s3_max = {32'h8BFF_FFFC};
        }
        cp_wdata_pattern: coverpoint m_hwdata_tx iff (m_hwrite_tx) {
            bins all_zeros = {32'h0000_0000};
            bins all_ones  = {32'hFFFF_FFFF};
            bins a5_prefix = {[32'hA5A5_0000:32'hA5A5_FFFF]};
            bins other     = default;
        }
        cp_rdata_pattern: coverpoint m_hrdata_tx iff (!m_hwrite_tx) {
            bins all_zeros = {32'h0000_0000};
            bins all_ones  = {32'hFFFF_FFFF};
            bins d00d_data = {[32'hD00D_0000:32'hD00D_FFFF]};
            bins other     = default;
        }
    endgroup

    function new(string name = "ahb_apb_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_ahb_protocol       = new();
        cg_apb_protocol       = new();
        cg_fsm_states         = new();
        cg_fsm_transitions    = new();
        cg_address_mapping    = new();
        cg_cdc                = new();
        cg_transfer_sequences = new();
        cg_data_boundary      = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual intf)::get(this, "", "full_vif", full_vif))
            `uvm_fatal("COV", "Unable to get full_vif from config_db")
    endfunction

    task run_phase(uvm_phase phase);
        fork
            begin : sample_hclk_cov
                forever begin
                    @(posedge full_vif.hclk);
                    m_hresetn_bus   = full_vif.HRESETn;
                    m_hwrite_bus    = full_vif.HWRITE;
                    m_htrans_bus    = full_vif.HTRANS;
                    m_hsize_bus     = full_vif.HSIZE;
                    m_hburst_bus    = full_vif.HBURST;
                    m_hresp_bus     = full_vif.HRESP;
                    m_hready_bus    = full_vif.HREADY;
                    m_haddr_bus     = full_vif.HADDR;

                    m_valid_hclk    = full_vif.VALID_HCLK;
                    m_pselx_hclk    = full_vif.PSELX_HCLK;
                    m_penable_hclk  = full_vif.PENABLE_HCLK;
                    m_pwrite_hclk   = full_vif.PWRITE_HCLK;
                    m_paddr_hclk    = full_vif.PADDR_HCLK;
                    m_fsm_state_hclk = full_vif.FSM_STATE_HCLK;

                    cg_ahb_protocol.sample();
                    cg_apb_protocol.sample();
                    cg_fsm_states.sample();
                    cg_fsm_transitions.sample();
                    cg_address_mapping.sample();
                    cg_transfer_sequences.sample();
                end
            end
            begin : sample_pclk_cov
                forever begin
                    @(posedge full_vif.pclk);
                    m_hresetn_bus  = full_vif.HRESETn;
                    m_pselx_pclk   = full_vif.PSELX;
                    m_penable_pclk = full_vif.PENABLE;
                    m_pwrite_pclk  = full_vif.PWRITE;
                    cg_cdc.sample();
                end
            end
        join
    endtask

    function void write(sequence_item t);
        m_hwrite_tx  = t.HWRITE;
        m_htrans_tx  = t.HTRANS;
        m_hresp_tx   = t.HRESP;
        m_hready_tx  = t.HREADY;
        m_haddr_tx   = t.HADDR;
        m_hwdata_tx  = t.HWDATA;
        m_hrdata_tx  = t.HRDATA;
        m_hresetn_tx = t.HRESETn;

        cg_data_boundary.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        real ahb_prot;
        real apb_prot;
        real fsm_state;
        real fsm_trans;
        real addr_map;
        real cdc_cov;
        real tx_seq;
        real data_bound;
        real total;

        ahb_prot  = cg_ahb_protocol.get_inst_coverage();
        apb_prot  = cg_apb_protocol.get_inst_coverage();
        fsm_state = cg_fsm_states.get_inst_coverage();
        fsm_trans = cg_fsm_transitions.get_inst_coverage();
        addr_map  = cg_address_mapping.get_inst_coverage();
        cdc_cov   = cg_cdc.get_inst_coverage();
        tx_seq    = cg_transfer_sequences.get_inst_coverage();
        data_bound = cg_data_boundary.get_inst_coverage();
        total = (ahb_prot + apb_prot + fsm_state + fsm_trans +
                 addr_map + cdc_cov + tx_seq + data_bound) / 8.0;

        `uvm_info("COV", $sformatf({
            "\n========================================\n",
            " AHB2APB Functional Coverage Report\n",
            "========================================\n",
            " AHB Protocol    : %0.2f%%\n",
            " APB Protocol    : %0.2f%%\n",
            " FSM States      : %0.2f%%\n",
            " FSM Transitions : %0.2f%%\n",
            " Addr Mapping    : %0.2f%%\n",
            " CDC             : %0.2f%%\n",
            " Transfer Seq    : %0.2f%%\n",
            " Data/Boundary   : %0.2f%%\n",
            "----------------------------------------\n",
            " TOTAL (avg)     : %0.2f%%\n",
            "========================================"
            },
            ahb_prot, apb_prot, fsm_state, fsm_trans,
            addr_map, cdc_cov, tx_seq, data_bound, total),
            UVM_NONE)
    endfunction

endclass
