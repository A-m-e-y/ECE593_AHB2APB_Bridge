
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
            
            // Detect new APB transaction when:
            // 1. PENABLE is high and PSEL is active, AND
            // 2. Either PENABLE just went high (0→1), OR address changed
            if (vif.Pselx != 3'b000 && vif.Penable) begin
                // New transaction if PENABLE rising edge OR address changed
                if (!last_penable || (vif.Paddr != last_paddr)) begin
                    
                    // Skip write→read transitions at same address (spurious glitch)
                    if (!(vif.Paddr == last_paddr && last_pwrite == 1'b1 && vif.Pwrite == 1'b0)) begin
                        // Wait one more Pclk for signals to stabilize
                        @(posedge vif.Pclk);
                        
                        txn = new();
                        
                        // Capture APB side signals during ACCESS phase
                        txn.Paddr = vif.Paddr;
                        txn.Pwdata = vif.Pwdata;
                        txn.Pwrite = vif.Pwrite;
                        txn.Pselx = vif.Pselx;
                        txn.Penable = vif.Penable;
                        txn.Prdata = vif.Prdata;
                        
                        // Capture corresponding AHB signals
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
