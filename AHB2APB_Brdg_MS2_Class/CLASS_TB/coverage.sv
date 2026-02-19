// coverage module for AHB2APB Bridge
module coverage_collector(
    input wire Hclk,
    input wire Pclk,
    input wire Hresetn,
    
    // AHB Interface
    input wire [31:0] Haddr,
    input wire [31:0] Hwdata,
    input wire [31:0] Hrdata,
    input wire [1:0]  Htrans,
    input wire        Hwrite,
    input wire        Hreadyin,
    input wire        Hreadyout,
    input wire [1:0]  Hresp,
    input wire [2:0]  Hsize,
    input wire [2:0]  Hburst,
    
    // APB Interface
    input wire [31:0] Paddr,
    input wire [31:0] Pwdata,
    input wire [31:0] Prdata,
    input wire [2:0]  Pselx,
    input wire        Penable,
    input wire        Pwrite,
    
    input wire [2:0]  fsm_state,
    input wire        valid
);

// FSM state definitions
typedef enum bit [2:0] {
    ST_IDLE     = 3'b000,
    ST_WWAIT    = 3'b001,
    ST_READ     = 3'b010,
    ST_WRITE    = 3'b011,
    ST_WRITEP   = 3'b100,
    ST_RENABLE  = 3'b101,
    ST_WENABLE  = 3'b110,
    ST_WENABLEP = 3'b111
} fsm_state_t;

typedef enum bit [1:0] {
    IDLE   = 2'b00,
    BUSY   = 2'b01,
    NONSEQ = 2'b10,
    SEQ    = 2'b11
} htrans_type_t;

// AHB protocol coverage
covergroup cg_ahb_protocol @(posedge Hclk);
    option.per_instance = 1;
    option.name = "ahb_protocol_cov";
    
    cp_hwrite: coverpoint Hwrite {
        bins read  = {0};
        bins write = {1};
    }
    
    cp_htrans: coverpoint Htrans {
        bins idle    = {IDLE};
        bins busy    = {BUSY};
        bins nonseq  = {NONSEQ};
        bins seq     = {SEQ};
    }
    
    cp_hsize: coverpoint Hsize {
        bins size_byte     = {3'b000};
        bins size_halfword = {3'b001};
        bins size_word     = {3'b010};
    }
    
    cp_hburst: coverpoint Hburst {
        bins single = {3'b000};
        bins incr   = {3'b001};
        bins wrap4  = {3'b010};
        bins incr4  = {3'b011};
    }
    
    cp_hresp: coverpoint Hresp {
        bins okay  = {2'b00};
    }
    
    cp_valid: coverpoint valid {
        bins asserted   = {1};
        bins deasserted = {0};
    }
    
    cp_hreadyout: coverpoint Hreadyout {
        bins ready    = {1};
        bins not_ready = {0};
    }
    
endgroup

// APB protocol coverage
covergroup cg_apb_protocol @(posedge Pclk);
    option.per_instance = 1;
    option.name = "apb_protocol_cov";
    
    cp_pselx: coverpoint Pselx {
        bins slave0 = {3'b001};
        bins slave1 = {3'b010};
        bins slave2 = {3'b100};
        bins none   = {3'b000};
        bins invalid = default;
    }
    
    cp_penable: coverpoint Penable {
        bins setup  = {0};
        bins access = {1};
    }
    
    cp_pwrite: coverpoint Pwrite {
        bins read  = {0};
        bins write = {1};
    }
    
    cp_apb_phase: coverpoint {Pselx != 0, Penable} {
        bins setup_phase  = {2'b10};
        bins access_phase = {2'b11};
        bins idle_phase   = {2'b00};
    }
    
    cx_slave_rw: cross cp_pselx, cp_pwrite {
        ignore_bins no_slave = binsof(cp_pselx) intersect {3'b000};
    }
    
    cx_slave_enable: cross cp_pselx, cp_penable {
        ignore_bins no_slave = binsof(cp_pselx) intersect {3'b000};
    }
    
endgroup

// FSM state coverage
covergroup cg_fsm_states @(posedge Hclk);
    option.per_instance = 1;
    option.name = "fsm_state_cov";
    
    cp_state: coverpoint fsm_state {
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

// FSM transition coverage
covergroup cg_fsm_transitions @(posedge Hclk);
    option.per_instance = 1;
    option.name = "fsm_transition_cov";
    
    cp_state_trans: coverpoint fsm_state {
        bins idle_to_wwait    = (ST_IDLE => ST_WWAIT);
        bins idle_to_read     = (ST_IDLE => ST_READ);
        bins idle_stay        = (ST_IDLE => ST_IDLE);
        
        bins wwait_to_writep  = (ST_WWAIT => ST_WRITEP);
        
        bins read_to_renable  = (ST_READ => ST_RENABLE);
        
        bins write_to_wenable  = (ST_WRITE => ST_WENABLE);
        bins write_to_wenablep = (ST_WRITE => ST_WENABLEP);
        
        bins writep_to_wenablep = (ST_WRITEP => ST_WENABLEP);
        
        bins renable_to_idle  = (ST_RENABLE => ST_IDLE);
        bins renable_to_read  = (ST_RENABLE => ST_READ);
        
        bins wenable_to_idle  = (ST_WENABLE => ST_IDLE);
        
        bins wenablep_to_write  = (ST_WENABLEP => ST_WRITE);
        bins wenablep_to_writep = (ST_WENABLEP => ST_WRITEP);
        bins wenablep_to_read   = (ST_WENABLEP => ST_READ);
        
        bins pipelined_writes = (ST_IDLE => ST_WWAIT => ST_WRITEP => ST_WENABLEP);
    }
    
endgroup

// address mapping coverage
covergroup cg_address_mapping @(posedge Hclk iff (Htrans == NONSEQ || Htrans == SEQ));
    option.per_instance = 1;
    option.name = "address_mapping_cov";
    
    cp_haddr: coverpoint Haddr {
        bins slave0_range = {[32'h8000_0000 : 32'h83FF_FFFF]};
        bins slave1_range = {[32'h8400_0000 : 32'h87FF_FFFF]};
        bins slave2_range = {[32'h8800_0000 : 32'h8BFF_FFFF]};
        bins other_range  = default;
    }
    
    cp_paddr: coverpoint Paddr {
        bins slave0_range = {[32'h8000_0000 : 32'h83FF_FFFF]};
        bins slave1_range = {[32'h8400_0000 : 32'h87FF_FFFF]};
        bins slave2_range = {[32'h8800_0000 : 32'h8BFF_FFFF]};
        bins other_range  = default;
    }
    
endgroup

// CDC coverage
covergroup cg_cdc @(posedge Pclk);
    option.per_instance = 1;
    option.name = "cdc_coverage";
    
    cp_penable_trans: coverpoint Penable {
        bins low_to_high = (0 => 1);
        bins high_to_low = (1 => 0);
        bins stay_high   = (1 => 1);
        bins stay_low    = (0 => 0);
    }
    
    cp_pselx_change: coverpoint Pselx {
        bins none_to_slave0 = (3'b000 => 3'b001);
        bins none_to_slave1 = (3'b000 => 3'b010);
        bins none_to_slave2 = (3'b000 => 3'b100);
        bins slave_to_none  = ([3'b001:3'b100] => 3'b000);
        bins slave_change   = (3'b001 => 3'b010), (3'b010 => 3'b100), (3'b001 => 3'b100);
    }
    
    cx_penable_pwrite: cross cp_penable_trans, Pwrite;
    
endgroup

// transaction sequences
covergroup cg_transaction_sequences @(posedge Hclk);
    option.per_instance = 1;
    option.name = "transaction_sequences_cov";
    
    cp_htrans_seq: coverpoint Htrans {
        bins nonseq_to_idle   = (NONSEQ => IDLE);
        bins nonseq_to_nonseq = (NONSEQ => NONSEQ);
        bins seq_to_seq       = (SEQ => SEQ);
        bins seq_to_idle      = (SEQ => IDLE);
        bins idle_to_nonseq   = (IDLE => NONSEQ);
    }
    
    cp_rw_seq: coverpoint Hwrite {
        bins write_to_write = (1 => 1);
        bins write_to_read  = (1 => 0);
        bins read_to_write  = (0 => 1);
        bins read_to_read   = (0 => 0);
    }
    
endgroup

// corner cases
covergroup cg_corner_cases @(posedge Hclk);
    option.per_instance = 1;
    option.name = "corner_cases_cov";
    
    cp_reset: coverpoint Hresetn {
        bins reset_inactive = {1};
        bins reset_deassert = (0 => 1);
    }
    
    cp_addr_boundary: coverpoint Haddr {
        bins addr_min       = {32'h8000_0000};
        bins addr_slave0_max = {32'h83FF_FFFF};
        bins addr_slave1_min = {32'h8400_0000};
        bins addr_slave2_min = {32'h8800_0000};
    }
    
    cp_wdata_pattern: coverpoint Hwdata {
        bins all_zeros  = {32'h0000_0000};
        bins all_ones   = {32'hFFFF_FFFF};
    }
    
endgroup

cg_ahb_protocol           ahb_cov;
cg_apb_protocol           apb_cov;
cg_fsm_states             fsm_state_cov;
cg_fsm_transitions        fsm_trans_cov;
cg_address_mapping        addr_map_cov;
cg_cdc                    cdc_cov;
cg_transaction_sequences  trans_seq_cov;
cg_corner_cases           corner_cov;

initial begin
    ahb_cov         = new();
    apb_cov         = new();
    fsm_state_cov   = new();
    fsm_trans_cov   = new();
    addr_map_cov    = new();
    cdc_cov         = new();
    trans_seq_cov   = new();
    corner_cov      = new();
end

function void display_coverage();
    real ahb_coverage, apb_coverage, fsm_coverage, trans_coverage;
    real addr_coverage, cdc_coverage, seq_coverage, corner_coverage;
    real total_coverage;
    
    ahb_coverage    = ahb_cov.get_inst_coverage();
    apb_coverage    = apb_cov.get_inst_coverage();
    fsm_coverage    = fsm_state_cov.get_inst_coverage();
    trans_coverage  = fsm_trans_cov.get_inst_coverage();
    addr_coverage   = addr_map_cov.get_inst_coverage();
    cdc_coverage    = cdc_cov.get_inst_coverage();
    seq_coverage    = trans_seq_cov.get_inst_coverage();
    corner_coverage = corner_cov.get_inst_coverage();
    
    total_coverage = (ahb_coverage + apb_coverage + fsm_coverage + trans_coverage +
                      addr_coverage + cdc_coverage + seq_coverage + corner_coverage) / 8.0;
    
    $display("\n========== DETAILED COVERAGE REPORT ==========");
    $display("AHB Protocol Coverage:       %0.2f%%", ahb_coverage);
    $display("APB Protocol Coverage:       %0.2f%%", apb_coverage);
    $display("FSM State Coverage:          %0.2f%%", fsm_coverage);
    $display("FSM Transition Coverage:     %0.2f%%", trans_coverage);
    $display("Address Mapping Coverage:    %0.2f%%", addr_coverage);
    $display("CDC Coverage:                %0.2f%%", cdc_coverage);
    $display("Transaction Sequence Cov:    %0.2f%%", seq_coverage);
    $display("Corner Case Coverage:        %0.2f%%", corner_coverage);
    $display("----------------------------------------------");
    $display("TOTAL COVERAGE:              %0.2f%%", total_coverage);
    $display("==============================================\n");
endfunction

endmodule

