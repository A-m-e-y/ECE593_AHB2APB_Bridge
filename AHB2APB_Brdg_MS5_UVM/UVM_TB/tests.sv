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
class ahb_apb_random_test extends ahb_apb_base_test;
    `uvm_component_utils(ahb_apb_random_test)

    ahb_random_sequence ahb_rand_seq;

    function new(string name = "ahb_apb_random_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("AHB_RANDOM_TEST","Inside build_phase",UVM_DEBUG)
        ahb_rand_seq = ahb_random_sequence::type_id::create("ahb_rand_seq");
    endfunction

    task run_phase (uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("SEQ", "sequence started: ahb_random_sequence", UVM_MEDIUM)
        ahb_rand_seq.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_random_sequence", UVM_MEDIUM)
        phase.phase_done.set_drain_time(this, 200);
	phase.drop_objection(this);
    endtask
endclass
//-----------------------------------------------------------------------------------------------------------

// b2b test - sends 100 consecutive NONSEQ writes and checks scoreboard
class ahb_b2b_test extends ahb_apb_base_test;
    `uvm_component_utils(ahb_b2b_test)

    ahb_b2b_seq_sequence b2b_seq;

    function new(string name = "ahb_b2b_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("AHB_B2B_TEST", "Inside build_phase", UVM_DEBUG)
        b2b_seq = ahb_b2b_seq_sequence::type_id::create("b2b_seq");
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("SEQ", "sequence started: ahb_b2b_seq_sequence", UVM_MEDIUM)
        b2b_seq.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_b2b_seq_sequence", UVM_MEDIUM)
        phase.phase_done.set_drain_time(this, 500); // give bridge time to flush
        phase.drop_objection(this);
    endtask
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
