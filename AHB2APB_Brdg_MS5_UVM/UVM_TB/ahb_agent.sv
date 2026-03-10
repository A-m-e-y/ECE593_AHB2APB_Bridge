class ahb_agent extends uvm_agent;
    `uvm_component_utils(ahb_agent)

    ahb_driver           drv;
    ahb_seqr        seqr;
    ahb_monitor          mon;

    // expose both ports at agent boundary so env can pick what it needs
    uvm_analysis_port #(sequence_item) drv_ap;
    uvm_analysis_port #(sequence_item) mon_ap;

    function new(string name = "ahb_agent", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv = ahb_driver::type_id::create("drv", this);
        seqr = ahb_seqr::type_id::create("seqr", this);
        mon = ahb_monitor::type_id::create("mon", this); 
    endfunction

   function void connect_phase(uvm_phase phase);
        drv.seq_item_port.connect(seqr.seq_item_export);
        drv_ap = drv.drv_ap;
        mon_ap = mon.ap_port;
    endfunction
endclass
