class ahb_apb_env extends uvm_env;
    `uvm_component_utils(ahb_apb_env)

    ahb_agent           ahb_agent_h;
    apb_monitor         apb_mon;   // waveform visibility only
    ahb_apb_scoreboard  scb;
    ahb_apb_coverage    cov;
    apb_slave_model     apb_slave;

    function new(string name = "ahb_apb_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ahb_agent_h = ahb_agent::type_id::create("ahb_agent_h", this);
        apb_mon     = apb_monitor::type_id::create("apb_mon", this);
        scb         = ahb_apb_scoreboard::type_id::create("scb", this);
        cov         = ahb_apb_coverage::type_id::create("cov", this);
        apb_slave   = apb_slave_model::type_id::create("apb_slave", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        uvm_top.print_topology();
        // Expected stream comes from driver output.
        ahb_agent_h.drv_ap.connect(scb.ahb_export);
        ahb_agent_h.drv_ap.connect(apb_slave.ahb_exp_fifo.analysis_export);
        // Coverage samples monitor-side behavior.
        ahb_agent_h.mon_ap.connect(cov.analysis_export);
        // Slave model publishes APB transactions to scoreboard.
        apb_slave.ap_port.connect(scb.apb_export);
        // apb_mon.ap_port intentionally left unconnected for waveform debug.
    endfunction
endclass
