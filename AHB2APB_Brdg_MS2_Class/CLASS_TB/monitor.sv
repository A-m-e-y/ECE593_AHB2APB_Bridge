
class monitor;

    transaction txn;
    mailbox #(transaction) mon2sb;
    virtual ahb_apb_if.slave vif;

    function new(mailbox #(transaction) mon2sb, virtual ahb_apb_if.slave vif);
        this.mon2sb = mon2sb;
        this.vif = vif;
    endfunction

    task monitor_ahb_apb();
        forever begin
            txn = new();
            
            @(posedge vif.clk);
            
            // Capture AHB side signals
            txn.Haddr = vif.Haddr;
            txn.Hwdata = vif.Hwdata;
            txn.Hwrite = vif.Hwrite;
            txn.Htrans = vif.Htrans;
            txn.Hrdata = vif.Hrdata;
            txn.Hreadyout = vif.Hreadyout;
            txn.Hresp = vif.Hresp;
            
            // Capture APB side signals
            txn.Paddr = vif.Paddr;
            txn.Pwdata = vif.Pwdata;
            txn.Pwrite = vif.Pwrite;
            txn.Pselx = vif.Pselx;
            txn.Penable = vif.Penable;
            txn.Prdata = vif.Prdata;
            
            // Only send to scoreboard when valid transaction occurs
            if (txn.Htrans == 2'b10 || txn.Htrans == 2'b11) begin
                $display("[%0t] MONITOR: Haddr=0x%0h Hwrite=%0b Paddr=0x%0h Pwrite=%0b Pselx=%0b Penable=%0b", 
                         $time, txn.Haddr, txn.Hwrite, txn.Paddr, txn.Pwrite, txn.Pselx, txn.Penable);
                mon2sb.put(txn);
            end
        end
    endtask

endclass
