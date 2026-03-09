class ahb_driver extends uvm_driver #(sequence_item);
    `uvm_component_utils(ahb_driver)

    virtual intf.AHB_DRIVER vif;

    // Sequence item for driver to DUT communication
    sequence_item tx;

    // Temporary storage for data during Write operations
    static bit [31:0] Hwdata_t; 

    // for pending wr operation 
    static int wr_pending;

    // Analysis port: sends every non-IDLE/non-BUSY transaction to the scoreboard.
    // The driver is the ground truth for AHB transactions (correct HADDR/HWDATA).
    uvm_analysis_port #(sequence_item) drv_ap;

    // Constructor
    function new (string name = "ahb_driver",uvm_component parent);
        super.new (name, parent);
    endfunction


    // Build Phase: Fetch the configuration settings from the environment
    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        drv_ap = new("drv_ap", this);

       if(!uvm_config_db#(virtual intf.AHB_DRIVER)::get(this,"","vif",vif)) begin
	        `uvm_error("CONFIG_DB","Not able to get virtual handle")
	end
    endfunction

    // Run Phase: Get the sequence item from the sequencer and drive it onto the interface
    task run_phase (uvm_phase phase);
	reset();

        forever
        begin
            seq_item_port.get_next_item(req);
            drive_tx(req);
            seq_item_port.item_done();    
        end
    endtask

    // Drive the transfers on the interface
    virtual task drive_tx (sequence_item tx);
        @(posedge vif.hclk)
        while(!(vif.ahb_driver_cb.HREADY))
             @(vif.ahb_driver_cb);
            tx.HREADY = vif.ahb_driver_cb.HREADY;

        if(tx.HTRANS != 2'b01)  //BUSY
        begin      

            vif.ahb_driver_cb.HSELAHB <=  tx.HSELAHB;
            vif.ahb_driver_cb.HADDR   <=  tx.HADDR;
            vif.ahb_driver_cb.HTRANS  <=  tx.HTRANS;
            vif.ahb_driver_cb.HWRITE  <=  tx.HWRITE;

            if(tx.HWRITE == 1'b0)  // READ
            begin
                // AHB protocol: HWDATA at cycle N+1 carries the write data for
                // a WRITE at cycle N, regardless of whether cycle N+1 is a read.
                // If there is a pending NONSEQ write whose data hasn't been driven yet,
                // flush it now before accepting this READ's (undefined) data.
                if (wr_pending)
                begin
                    vif.ahb_driver_cb.HWDATA <= Hwdata_t;
                    wr_pending <= 0;
                end
                else
                    vif.ahb_driver_cb.HWDATA <= 32'hxxxx_xxxx;
            end
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

        // Send non-IDLE/BUSY transactions to scoreboard as ground truth.
        if (tx.HTRANS != 2'b00 && tx.HTRANS != 2'b01)
            drv_ap.write(tx);
    endtask

    task reset();
        vif.ahb_driver_cb.HRESETn <= 0;
        @(vif.ahb_driver_cb); //add 5cycles if 1 doesn't work
        vif.ahb_driver_cb.HRESETn <= 1;
    endtask
endclass