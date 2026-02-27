class ahb_apb_env extends uvm_env;
    `uvm_component_utils(ahb_apb_env)

    ahb_agent                   ahb_agent_h;
    ahb_apb_scoreboard          scb;  
    bit agent_enabled, scoreboard_enabled;

    function new(string name = "ahb_apb_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // Build phase: create the components required for your env
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(agent_enabled) ahb_agent_h = ahb_agent::type_id::create("ahb_agent_h", this);

        if(scoreboard_enabled)  scb = ahb_apb_scoreboard::type_id::create("scb", this); 
    endfunction

    function void connect_phase(uvm_phase phase);
        uvm_top.print_topology();
        //mon <-> scb connection
        ahb_agent.mon.ap_port.connect(scb.analysis_export); //---------------------------> update as per need -scb.ahb_fifo.analysis_export
    endfunction
endclass