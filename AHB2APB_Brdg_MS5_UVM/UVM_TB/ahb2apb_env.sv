class ahb_apb_env extends uvm_env;
    `uvm_component_utils(ahb_apb_env)

    ahb_agent           ahb_agent_h;
    apb_monitor         apb_mon;
    ahb_apb_scoreboard  scb;
    ahb_apb_coverage    cov;

    function new(string name = "ahb_apb_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ahb_agent_h = ahb_agent::type_id::create("ahb_agent_h", this);
        apb_mon     = apb_monitor::type_id::create("apb_mon", this);
        scb         = ahb_apb_scoreboard::type_id::create("scb", this);
        cov         = ahb_apb_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        uvm_top.print_topology();
        // driver analysis port fans out to scoreboard AND coverage via their
        // built-in uvm_subscriber analysis_export — no custom handle needed.
        ahb_agent_h.drv_ap.connect(scb.analysis_export);
        ahb_agent_h.drv_ap.connect(cov.analysis_export);
        // APB monitor fans out to scoreboard AND coverage via one custom imp each.
        apb_mon.ap_port.connect(scb.apb_export);
        apb_mon.ap_port.connect(cov.cov_apb_export);
    endfunction
endclass