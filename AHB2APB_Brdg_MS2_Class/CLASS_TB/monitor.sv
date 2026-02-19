
class monitor;

    transaction txn;
    mailbox #(transaction) mon2sb;
    virtual ahb_apb_if.slave vif;

    function new(mailbox #(transaction) mon2sb, virtual ahb_apb_if.slave vif);
        this.mon2sb = mon2sb;
        this.vif = vif;
    endfunction

    task monitor_ahb_apb();
        bit [31:0] last_paddr = 32'hFFFFFFFF;
        bit last_pwrite = 1'bx;
        bit last_penable = 0;
        
        forever begin
            @(posedge vif.Pclk);
            
            // new APB txn when PENABLE high and PSEL active
            if (vif.Pselx != 3'b000 && vif.Penable) begin
                if (!last_penable || (vif.Paddr != last_paddr)) begin
                    
                    // skip glitches from write->read at same addr
                    if (!(vif.Paddr == last_paddr && last_pwrite == 1'b1 && vif.Pwrite == 1'b0)) begin
                        @(posedge vif.Pclk);  //let signals stabilize
                        
                        txn = new();
                        
                        // capture APB signals
                        txn.Paddr = vif.Paddr;
                        txn.Pwdata = vif.Pwdata;
                        txn.Pwrite = vif.Pwrite;
                        txn.Pselx = vif.Pselx;
                        txn.Penable = vif.Penable;
                        txn.Prdata = vif.Prdata;
                        
                        // capture AHB signals
                        txn.Haddr = vif.Haddr;
                        txn.Hwdata = vif.Hwdata;
                        txn.Hwrite = vif.Hwrite;
                        txn.Htrans = vif.Htrans;
                        txn.Hresp = vif.Hresp;
                        txn.Hrdata = vif.Hrdata;
                        txn.Hreadyout = vif.Hreadyout;
                        
                        mon2sb.put(txn);
                    end
                    
                    last_paddr = vif.Paddr;
                    last_pwrite = vif.Pwrite;
                end
            end
            
            last_penable = vif.Penable;
        end
    endtask

endclass
