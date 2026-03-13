class ahb_apb_base_test extends uvm_test;
    `uvm_component_utils (ahb_apb_base_test)
     bit agent_enabled;
     bit scoreboard_enabled;
     int log_fd;
    ahb_apb_env env;

    function new(string name = "ahb_apb_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("BASE_TEST","Inside build_phase",UVM_DEBUG)
       
        agent_enabled  = 1;
        //scoreboard_enabled = 1;

        env = ahb_apb_env::type_id::create("env", this);

// dump everything to a log file too
    log_fd = $fopen("uvm_log.txt", "w");

    if (log_fd == 0)
      `uvm_fatal("LOGFILE", "Failed to open log file!")

    uvm_root::get().set_report_default_file(log_fd);
    endfunction

    function void final_phase(uvm_phase phase);
    super.final_phase(phase);
    if (log_fd)
        $fclose(log_fd);
    endfunction
endclass

//-----------------------------------------------------------------------------------------------------------
class ahb_apb_single_write_test extends ahb_apb_base_test;
    `uvm_component_utils(ahb_apb_single_write_test)

    ahb_single_write_sequence ahb_seq_h;

    function new(string name = "ahb_apb_single_write_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ahb_seq_h = ahb_single_write_sequence::type_id::create("ahb_seq_h");
    endfunction

    // Run Phase: Start the single write sequences on the respective sequencers
    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("SEQ", "sequence started: ahb_single_write_sequence", UVM_MEDIUM)
        ahb_seq_h.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_single_write_sequence", UVM_MEDIUM)
        // wait a bit so APB side (after CDC) and slave model can flush
        phase.phase_done.set_drain_time(this, 300);
        phase.drop_objection(this);
    endtask
endclass

//  this test focuses on the burst write test sequence 
class ahb_apb_burst_write_test extends ahb_apb_base_test;
    `uvm_component_utils(ahb_apb_burst_write_test)

    ahb_burst_write_sequence ahb_seq_h;

    function new(string name = "ahb_apb_burst_write_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ahb_seq_h = ahb_burst_write_sequence::type_id::create("ahb_seq_h");
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("SEQ", "sequence started: ahb_burst_write_sequence", UVM_MEDIUM)
        ahb_seq_h.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_burst_write_sequence", UVM_MEDIUM)
        phase.phase_done.set_drain_time(this, 2000);
        phase.drop_objection(this);
    endtask
endclass

class ahb_apb_single_read_test extends ahb_apb_base_test;
    `uvm_component_utils(ahb_apb_single_read_test)

    ahb_single_read_sequence ahb_seq_h;

    function new(string name = "ahb_apb_single_read_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ahb_seq_h = ahb_single_read_sequence::type_id::create("ahb_seq_h");
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("SEQ", "sequence started: ahb_single_read_sequence", UVM_MEDIUM)
        ahb_seq_h.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_single_read_sequence", UVM_MEDIUM)
        phase.phase_done.set_drain_time(this, 300);
        phase.drop_objection(this);
    endtask
endclass

class ahb_apb_burst_read_test extends ahb_apb_base_test;
    `uvm_component_utils(ahb_apb_burst_read_test)

    ahb_burst_read_sequence ahb_seq_h;

    function new(string name = "ahb_apb_burst_read_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ahb_seq_h = ahb_burst_read_sequence::type_id::create("ahb_seq_h");
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("SEQ", "sequence started: ahb_burst_read_sequence", UVM_MEDIUM)
        ahb_seq_h.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_burst_read_sequence", UVM_MEDIUM)
        phase.phase_done.set_drain_time(this, 2000);
        phase.drop_objection(this);
    endtask
endclass

class ahb_apb_full_rw_test extends ahb_apb_base_test;
    `uvm_component_utils(ahb_apb_full_rw_test)

    ahb_single_write_sequence single_wr_seq;
    ahb_single_read_sequence  single_rd_seq;
    ahb_burst_write_sequence  burst_wr_seq;
    ahb_burst_read_sequence   burst_rd_seq;

    function new(string name = "ahb_apb_full_rw_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        single_wr_seq = ahb_single_write_sequence::type_id::create("single_wr_seq");
        single_rd_seq = ahb_single_read_sequence::type_id::create("single_rd_seq");
        burst_wr_seq  = ahb_burst_write_sequence::type_id::create("burst_wr_seq");
        burst_rd_seq  = ahb_burst_read_sequence::type_id::create("burst_rd_seq");
    endfunction

    task run_phase(uvm_phase phase);
        int i;
        phase.raise_objection(this);

        `uvm_info("SEQ", "sequence started: ahb_single_write_sequence batch x10", UVM_MEDIUM)
        for (i = 0; i < 10; i++)
            single_wr_seq.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_single_write_sequence batch x10", UVM_MEDIUM)

        `uvm_info("SEQ", "sequence started: ahb_single_read_sequence batch x10", UVM_MEDIUM)
        for (i = 0; i < 10; i++)
            single_rd_seq.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_single_read_sequence batch x10", UVM_MEDIUM)

        burst_wr_seq.N_TXN = 500;
        `uvm_info("SEQ", "sequence started: ahb_burst_write_sequence (N_TXN=500)", UVM_MEDIUM)
        burst_wr_seq.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_burst_write_sequence (N_TXN=500)", UVM_MEDIUM)

        burst_rd_seq.N_TXN = 500;
        `uvm_info("SEQ", "sequence started: ahb_burst_read_sequence (N_TXN=500)", UVM_MEDIUM)
        burst_rd_seq.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_burst_read_sequence (N_TXN=500)", UVM_MEDIUM)

        phase.phase_done.set_drain_time(this, 3000);
        phase.drop_objection(this);
    endtask
endclass

class ahb_apb_cov_boundary_test extends ahb_apb_base_test;
    `uvm_component_utils(ahb_apb_cov_boundary_test)

    ahb_cov_boundary_sequence cov_seq_h;

    function new(string name = "ahb_apb_cov_boundary_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cov_seq_h = ahb_cov_boundary_sequence::type_id::create("cov_seq_h");
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("SEQ", "sequence started: ahb_cov_boundary_sequence", UVM_MEDIUM)
        cov_seq_h.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_cov_boundary_sequence", UVM_MEDIUM)
        phase.phase_done.set_drain_time(this, 1500);
        phase.drop_objection(this);
    endtask
endclass

class ahb_apb_cov_code_stress_test extends ahb_apb_base_test;
    `uvm_component_utils(ahb_apb_cov_code_stress_test)

    ahb_cov_boundary_sequence    boundary_seq_h;
    ahb_cov_code_stress_sequence stress_seq_h;

    function new(string name = "ahb_apb_cov_code_stress_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        boundary_seq_h = ahb_cov_boundary_sequence::type_id::create("boundary_seq_h");
        stress_seq_h   = ahb_cov_code_stress_sequence::type_id::create("stress_seq_h");
        stress_seq_h.N_TXN = 1500;
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("SEQ", "sequence started: ahb_cov_boundary_sequence (warmup)", UVM_MEDIUM)
        boundary_seq_h.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_cov_boundary_sequence (warmup)", UVM_MEDIUM)

        `uvm_info("SEQ", "sequence started: ahb_cov_code_stress_sequence (N_TXN=1500)", UVM_MEDIUM)
        stress_seq_h.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_cov_code_stress_sequence (N_TXN=1500)", UVM_MEDIUM)

        phase.phase_done.set_drain_time(this, 6000);
        phase.drop_objection(this);
    endtask
endclass

class ahb_apb_full_final_test extends ahb_apb_base_test;
    `uvm_component_utils(ahb_apb_full_final_test)

    ahb_single_write_sequence      single_wr_seq;
    ahb_single_read_sequence       single_rd_seq;
    ahb_burst_write_sequence       burst_wr_seq;
    ahb_burst_read_sequence        burst_rd_seq;
    ahb_cov_boundary_sequence      boundary_seq_h;
    ahb_cov_code_stress_sequence   stress_seq_h;

    function new(string name = "ahb_apb_full_final_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        single_wr_seq = ahb_single_write_sequence::type_id::create("single_wr_seq");
        single_rd_seq = ahb_single_read_sequence::type_id::create("single_rd_seq");
        burst_wr_seq  = ahb_burst_write_sequence::type_id::create("burst_wr_seq");
        burst_rd_seq  = ahb_burst_read_sequence::type_id::create("burst_rd_seq");
        boundary_seq_h = ahb_cov_boundary_sequence::type_id::create("boundary_seq_h");
        stress_seq_h   = ahb_cov_code_stress_sequence::type_id::create("stress_seq_h");
        stress_seq_h.N_TXN = 1500;
    endfunction

    task run_phase(uvm_phase phase);
        int i;
        phase.raise_objection(this);

        // 1) original full-rw flow
        `uvm_info("SEQ", "final test stage started: full_rw", UVM_MEDIUM)

        `uvm_info("SEQ", "sequence started: ahb_single_write_sequence batch x10", UVM_MEDIUM)
        for (i = 0; i < 10; i++)
            single_wr_seq.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_single_write_sequence batch x10", UVM_MEDIUM)

        `uvm_info("SEQ", "sequence started: ahb_single_read_sequence batch x10", UVM_MEDIUM)
        for (i = 0; i < 10; i++)
            single_rd_seq.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_single_read_sequence batch x10", UVM_MEDIUM)

        burst_wr_seq.N_TXN = 500;
        `uvm_info("SEQ", "sequence started: ahb_burst_write_sequence (N_TXN=500)", UVM_MEDIUM)
        burst_wr_seq.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_burst_write_sequence (N_TXN=500)", UVM_MEDIUM)

        burst_rd_seq.N_TXN = 500;
        `uvm_info("SEQ", "sequence started: ahb_burst_read_sequence (N_TXN=500)", UVM_MEDIUM)
        burst_rd_seq.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_burst_read_sequence (N_TXN=500)", UVM_MEDIUM)

        `uvm_info("SEQ", "final test stage ended: full_rw", UVM_MEDIUM)

        // 2) dedicated coverage sequences
        `uvm_info("SEQ", "final test stage started: coverage_boundary", UVM_MEDIUM)
        `uvm_info("SEQ", "sequence started: ahb_cov_boundary_sequence", UVM_MEDIUM)
        boundary_seq_h.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_cov_boundary_sequence", UVM_MEDIUM)
        `uvm_info("SEQ", "final test stage ended: coverage_boundary", UVM_MEDIUM)

        `uvm_info("SEQ", "final test stage started: coverage_stress", UVM_MEDIUM)
        `uvm_info("SEQ", "sequence started: ahb_cov_code_stress_sequence (N_TXN=1500)", UVM_MEDIUM)
        stress_seq_h.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_cov_code_stress_sequence (N_TXN=1500)", UVM_MEDIUM)
        `uvm_info("SEQ", "final test stage ended: coverage_stress", UVM_MEDIUM)

        phase.phase_done.set_drain_time(this, 10000);
        phase.drop_objection(this);
    endtask
endclass
