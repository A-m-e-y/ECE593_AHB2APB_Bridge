class ahb_agent extends uvm_agent;
    `uvm_component_utils(ahb_agent)

    // Declarations for AHB driver, sequencer, monitor and environment configuration
    ahb_driver           drv;
    ahb_seqr       	 seqr;
    ahb_monitor          mon;

    // Expose the driver's analysis port so the environment can connect it to
    // the scoreboard without the environment needing to know the driver directly.
    uvm_analysis_port #(sequence_item) drv_ap;

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
        // Expose driver analysis port at agent boundary
        drv_ap = drv.drv_ap;
    endfunction
endclass