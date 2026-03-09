class ahb_apb_env extends uvm_env;
    `uvm_component_utils(ahb_apb_env)

    ahb_agent           ahb_agent_h;
    apb_monitor         apb_mon;
    ahb_apb_scoreboard  scb;

    function new(string name = "ahb_apb_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ahb_agent_h = ahb_agent::type_id::create("ahb_agent_h", this);
        apb_mon     = apb_monitor::type_id::create("apb_mon", this);
        scb         = ahb_apb_scoreboard::type_id::create("scb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        uvm_top.print_topology();
        // Driver → scoreboard: driver is the AHB ground truth (correct HADDR/HWDATA).
        // The AHB monitor is kept active for waveform debug but no longer feeds the SCB.
        ahb_agent_h.drv_ap.connect(scb.drv_export);
        // APB monitor → scoreboard APB export
        apb_mon.ap_port.connect(scb.apb_export);
    endfunction
endclass