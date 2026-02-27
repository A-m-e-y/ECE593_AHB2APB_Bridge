// AHB Monitor: Monitors the AHB interface and sends transactions to the scoreboard.
class ahb_monitor extends uvm_monitor;
    `uvm_component_utils(ahb_monitor)

    // Monitor interface and configuration objects
    virtual          intf.ahb_monitor mon_intf;
    sequence_item    tx;
    //ahb_apb_env_config   env_config_h;

    // Port to send transactions to the scoreboard
    uvm_analysis_port # (ahb_sequence_item) ap_port;

    // Constructor: Initializes the component
    function new (string name = "ahb_monitor", uvm_component parent);
        super.new(name, parent);
    endfunction

    // Build Phase: Retrieves the configuration object and initializes the monitor port
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), "Inside build_phase", UVM_DEBUG)
        // Retrieve environment configuration
        if(!uvm_config_db # (ahb_apb_env_config) :: get(this, "", "ahb_apb_env_config", env_config_h))
            `uvm_fatal(get_type_name, "can't retrieve env_config from uvm_config_db")
        
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
            tx = ahb_sequence_item::type_id::create("tx", this);

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

            // Log transaction details and send to the scoreboard
            `uvm_info(get_type_name, $sformatf("AHB monitor captured TX: \n%s", tx.sprint()), UVM_MEDIUM)
            ap_port.write(tx);
        end     
    endtask
endclass