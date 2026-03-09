// AHB Monitor: Monitors the AHB interface and sends transactions to the scoreboard.
class ahb_monitor extends uvm_monitor;
    `uvm_component_utils(ahb_monitor)

    virtual          intf.AHB_MONITOR mon_intf;
    sequence_item    tx;

    // Port to send transactions to the scoreboard
    uvm_analysis_port # (sequence_item) ap_port;

    // Constructor: Initializes the component
    function new (string name = "ahb_monitor", uvm_component parent);
        super.new(name, parent);
    endfunction

    // Build Phase: initializes the monitor port
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), "Inside build_phase", UVM_DEBUG)
        
	if(!uvm_config_db#(virtual intf.AHB_MONITOR)::get(this,"","vif",mon_intf))
   		`uvm_fatal("MON","Unable to get monitor interface")

        // Initialize monitor port
        ap_port = new("ap_port", this);
    endfunction

    // Run Phase: Continuously monitors the interface for transactions
    task run_phase(uvm_phase phase);
        `uvm_info(get_name(), "Inside build_phase", UVM_DEBUG)
        @(posedge mon_intf.clk);
        forever
            monitor_txns();
    endtask

    // Monitor Task: Captures transactions from the AHB interface and sends them to the scoreboard
    task monitor_txns();
        begin
            // Wait for clock edge
            @(posedge mon_intf.clk);
            
            // Create a new transaction item
            tx = sequence_item::type_id::create("tx", this);

            // Capture transaction data from the interface
            tx.HRESETn  = mon_intf.ahb_monitor_cb.HRESETn;
            tx.HADDR    = mon_intf.ahb_monitor_cb.HADDR;
            tx.HTRANS   = mon_intf.ahb_monitor_cb.HTRANS;
            tx.HWRITE   = mon_intf.ahb_monitor_cb.HWRITE;
            tx.HWDATA   = mon_intf.ahb_monitor_cb.HWDATA;
            tx.HSELAHB  = mon_intf.ahb_monitor_cb.HSELAHB;
            tx.HRDATA   = mon_intf.ahb_monitor_cb.HRDATA;
            tx.HREADY   = mon_intf.ahb_monitor_cb.HREADY;
            tx.HRESP    = mon_intf.ahb_monitor_cb.HRESP;

            `uvm_info(get_type_name, $sformatf("AHB monitor captured TX: \n%s", tx.sprint()), UVM_MEDIUM)
            ap_port.write(tx);
        end     
    endtask
endclass