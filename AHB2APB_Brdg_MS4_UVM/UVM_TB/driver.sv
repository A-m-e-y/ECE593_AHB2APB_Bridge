class ahb_driver extends uvm_driver #(ahb_sequence_item);
    `uvm_component_utils(ahb_driver)

    // AHB Driver interface
    virtual intf.AHB_DRIVER vif;

    // Sequence item for driver to DUT communication
    sequence_item tx;

    // Configuration handle for environment setup
    //ahb_apb_env_config env_config_h;

    // Temporary storage for data during Write operations
    static bit [31:0] Hwdata_t; 

    // for pending wr operation 
    static int wr_pending;

    // Constructor
    function new (string name = "ahb_driver",uvm_component parent);
        super.new (name, parent);
    endfunction


    // Build Phase: Fetch the configuration settings from the environment
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
       // if(!uvm_config_db #(ahb_apb_env_config)::get (this,"","ahb_apb_env_config",env_config_h))
       //     `uvm_fatal ("config", "can't get config from uvm_config_db")
       if(!uvm_config_db#(virtual intf.AHB_DRIVER)::get(this,"","vif",vif)) begin
	        `uvm_error("CONFIG_DB","Not able to get virtual handle")
	end
    endfunction

    // Run Phase: Get the sequence item from the sequencer and drive it onto the interface
    task run_phase (uvm_phase phase);
        forever
        begin
            seq_item_port.get_next_item(req);
            drive_tx(req);
            seq_item_port.item_done();    
        end
    endtask

    // Send the transfers on the interface
    virtual task drive_tx (ahb_sequence_item tx);
        @(posedge vif.clk)
        while(!(vif.ahb_driver_cb.HREADY))
             @(vif.ahb_driver_cb);
            tx.HREADY = vif.ahb_driver_cb.HREADY;

        if(tx.HTRANS != 2'b01)  //BUSY
        begin      

            reset();
            vif.ahb_driver_cb.HSELAHB <=  tx.HSELAHB;
            vif.ahb_driver_cb.HADDR   <=  tx.HADDR;
            vif.ahb_driver_cb.HTRANS  <=  tx.HTRANS;
            vif.ahb_driver_cb.HWRITE  <=  tx.HWRITE;

            if(tx.HWRITE == 1'b0)  // READ
                vif.ahb_driver_cb.HWDATA  <=  32'hxxxx_xxxx; 
            else
            begin //WRITE
                if(tx.HTRANS == 2'b10)  // NONSEQ
                begin
                    Hwdata_t  <=  tx.HWDATA;
                    wr_pending <= 1;
                end

                else if (tx.HTRANS == 2'b11)  // SEQ
                begin
                    Hwdata_t  <= tx.HWDATA;
                    vif.ahb_driver_cb.HWDATA   <= Hwdata_t;
                    wr_pending <= 1;
                end
                
                else if (tx.HTRANS == 2'b00)  //T_IDLE
                begin
                    if(wr_pending == 1)
                    begin
                        vif.ahb_driver_cb.HWDATA   <= Hwdata_t;
                        wr_pending   <= 0;
                    end
                end
            end 
        end
        `uvm_info(get_type_name,$sformatf("AHB driver Delivered Tx: \n%s" ,tx.sprint()),UVM_MEDIUM)
    endtask

    task reset();
        vif.ahb_driver_cb.HRESETn <= 0;
        @(vif.ahb_driver_cb); //add 5cycles if 1 doesn't work
        vif.ahb_driver_cb.HRESETn <= 1;
    endtask
endclass