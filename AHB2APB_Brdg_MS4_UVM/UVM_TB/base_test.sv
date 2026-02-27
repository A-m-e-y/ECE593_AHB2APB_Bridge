class ahb_apb_base_test extends uvm_test;
    `uvm_component_utils (ahb_apb_base_test)

    // Configuration handle for environment setup
    //ahb_apb_env_config env_config_h;
    // Handle to the main testbench environment
    ahb_apb_env env;

    // Constructor
    function new(string name = "ahb_apb_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Build Phase: Setting up the environment and agents
    function void build_phase(uvm_phase phase);
        // Create environment configuration object
        //env_config_h = ahb_apb_env_config::type_id::create("env_config_h");
        
        // Set configuration object for child components to access
        //uvm_config_db #(ahb_apb_env_config)::set(this, "*", "ahb_apb_env_config", env_config_h);

        // Fetch the AHB interface from configuration
        //if(!uvm_config_db #(virtual intf)::get(this, "", "ahb_vif", env_config_h.ahb_vif))
        //    `uvm_fatal (get_type_name, "can't get ahb_intf from config_db");
        
        `uvm_info("BASE_TEST","Inside build_phase",UVM_DEBUG)
       
        if(!uvm_config_db#(virtual intf.AHB_DRIVER)::get(this,"","vif",vif)) 
	        `uvm_error("CONFIG_DB","Not able to get virtual handle")

        // Fetch the APB interface from configuration
        //if(!uvm_config_db #(virtual apb_intf)::get(this, "", "apb_vif", env_config_h.apb_vif))
        //    `uvm_fatal (get_type_name, "can't get apb_intf from config_db");

        // Configure the agents and scoreboard to be active for this test
        ahb_agent_enabled  = 1;
        //apb_agent_enabled  = 1;
        scoreboard_enabled = 1;

        // Set AHB and APB agents to active mode
        //env_config_h.ahb_agent_is_active = UVM_ACTIVE;
        //env_config_h.apb_agent_is_active = UVM_ACTIVE;

        // Instantiate the main testbench environment
        env = ahb_apb_env::type_id::create("env", this);
    endfunction
endclass

// This is a random test derived from the base test for the ahb_apb testbench
class ahb_apb_random_test extends ahb_apb_base_test;
    `uvm_component_utils(ahb_apb_random_test)

    // Sequence handles to generate random traffic on AHB and APB
    ahb_random_sequence ahb_rand_seq;
    //apb_random_sequence apb_rand_seq_h;

    // Constructor
    function new(string name = "ahb_apb_random_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    // Build Phase: Instantiate the random sequences
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("AHB_RANDOM_TEST","Inside build_phase",UVM_DEBUG)
        ahb_rand_seq = ahb_random_sequence::type_id::create("ahb_rand_seq");
        //apb_rand_seq_h = apb_random_sequence::type_id::create("apb_rand_seq_h");
    endfunction

    // Run Phase: Start the random sequences on the respective sequencers
    task run_phase (uvm_phase phase);
        phase.raise_objection(this);
        ahb_rand_seq.start(env.ahb_agent_h.seqr);
        /*
        fork
            apb_rand_seq_h.start(env.apb_agent_h.sequencer_h);
            apb_rand_seq_h.start(env.apb_agent_h.sequencer_h);
        join
        */
        phase.drop_objection(this);
        phase.phase_done.set_drain_time(this, 50);
    endtask
endclass