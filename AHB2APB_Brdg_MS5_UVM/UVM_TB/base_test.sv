class ahb_apb_base_test extends uvm_test;
    `uvm_component_utils (ahb_apb_base_test)
     bit agent_enabled;
     bit scoreboard_enabled;
     int log_fd;
     // Handle to the main testbench environment
    ahb_apb_env env;

    // Constructor
    function new(string name = "ahb_apb_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Build Phase: Setting up the environment and agents
    function void build_phase(uvm_phase phase);
	super.build_phase(phase);
        `uvm_info("BASE_TEST","Inside build_phase",UVM_DEBUG)
       
        // Configure  agents and scoreboard to be active for this test
        agent_enabled  = 1;
        //scoreboard_enabled = 1;

        // Instantiate the main testbench environment
        env = ahb_apb_env::type_id::create("env", this);

	// Open log file
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

// This is a random test derived from the base test for the testbench
class ahb_apb_random_test extends ahb_apb_base_test;
    `uvm_component_utils(ahb_apb_random_test)

    // Sequence handle to generate random traffic on AHB
    ahb_random_sequence ahb_rand_seq;

    // Constructor
    function new(string name = "ahb_apb_random_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    // Build Phase: Instantiate the random sequences
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("AHB_RANDOM_TEST","Inside build_phase",UVM_DEBUG)
        ahb_rand_seq = ahb_random_sequence::type_id::create("ahb_rand_seq");
    endfunction

    task run_phase (uvm_phase phase);
        phase.raise_objection(this);
        ahb_rand_seq.start(env.ahb_agent_h.seqr);
	phase.phase_done.set_drain_time(this, 200);
	phase.drop_objection(this);
    endtask
endclass

// ─────────────────────────────────────────────────────────────────────────────
// Back-to-Back Sequential Burst Test
//
// Uses ahb_b2b_seq_sequence: IDLE → NONSEQ → 4×SEQ → trailing IDLE.
// All transactions are WRITEs so address+data are fully checkable.
// Expected scoreboard result: 5 pairs checked, 0 failed, 0 unmatched.
//
// Drain time is 500 ns to give the bridge FSM plenty of time to flush the
// entire pipelined burst (WWAIT + WRITEP + 4×WENABLEP→WRITEP cycles ≈ 110 ns;
// 500 ns adds comfortable margin for any clock-domain latency).
// ─────────────────────────────────────────────────────────────────────────────
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
        b2b_seq.start(env.ahb_agent_h.seqr);
        phase.phase_done.set_drain_time(this, 500);
        phase.drop_objection(this);
    endtask
endclass