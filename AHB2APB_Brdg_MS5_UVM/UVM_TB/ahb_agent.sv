class ahb_agent extends uvm_agent;
    `uvm_component_utils(ahb_agent)

    // Declarations for AHB driver, sequencer, monitor and environment configuration
    ahb_driver           drv;
    ahb_seqr       	 seqr;
    ahb_monitor          mon;

    // Constructor for the agent
    function new(string name = "ahb_agent", uvm_component parent=null);
        super.new(name, parent);
    endfunction

    // Build phase: Instantiate the driver, sequencer, and monitor
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv = ahb_driver::type_id::create("drv", this);
        seqr = ahb_seqr::type_id::create("seqr", this);
        mon = ahb_monitor::type_id::create("mon", this); 
    endfunction

    // Connect phase: Connect the driver to the sequencer  
   function void connect_phase(uvm_phase phase);
        drv.seq_item_port.connect(seqr.seq_item_export);
    endfunction
endclass