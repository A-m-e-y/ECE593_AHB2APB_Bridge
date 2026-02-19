
class driver;

    transaction txn;
    mailbox #(transaction) gen2driv;
    mailbox #(transaction) driv2sb;
    virtual ahb_apb_if.master vif;
    int txn_count = 0;

    function new(mailbox #(transaction) gen2driv, mailbox #(transaction) driv2sb, virtual ahb_apb_if.master vif);
        this.gen2driv = gen2driv;  
        this.driv2sb = driv2sb;   
        this.vif = vif;           
    endfunction

    task drive();
        forever begin
            gen2driv.get(txn);
            driv2sb.put(txn);
            txn_count++;
            
            $display("\n[%0t] ========== AHB Transaction #%0d ==========", $time, txn_count);
            $display("[%0t] AHB: %s  Addr=0x%0h  Data=0x%0h", 
                     $time, txn.Hwrite ? "WRITE" : "READ ", txn.Haddr, 
                     txn.Hwrite ? txn.Hwdata : 32'hXXXXXXXX);
            
            // address phase
            wait(vif.Hreadyout == 1'b1);
            @(posedge vif.clk);
            #1;
            vif.Hwrite = txn.Hwrite;
            vif.Htrans = txn.Htrans;
            vif.Hsize  = txn.Hsize;
            vif.Hburst = txn.Hburst;
            vif.Haddr = txn.Haddr;
            vif.Hreadyin = 1'b1;
            
            // data phase
            wait(vif.Hreadyout == 1'b1);
            @(posedge vif.clk);
            #1;
            if (txn.Hwrite) begin
                vif.Hwdata = txn.Hwdata;
            end
            
            // wait for completion
            wait(vif.Hreadyout == 1'b1);
            @(posedge vif.clk);
            #1;
            
            vif.Htrans = 2'b00;  //back to IDLE
        end
    endtask

endclass
