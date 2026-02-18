
class driver;

    transaction txn;
    mailbox #(transaction) gen2driv;
    mailbox #(transaction) driv2sb;
    virtual ahb_apb_if.master vif;

    function new(mailbox #(transaction) gen2driv, mailbox #(transaction) driv2sb, virtual ahb_apb_if.master vif);
        this.gen2driv = gen2driv;  
        this.driv2sb = driv2sb;   
        this.vif = vif;           
    endfunction

    task drive();
        forever begin
            gen2driv.get(txn);
            driv2sb.put(txn);
            
            $display("[%0t] DRIVER: Driving transaction - Haddr=0x%0h Hwrite=%0b Htrans=%0b", 
                     $time, txn.Haddr, txn.Hwrite, txn.Htrans);
            
            // Wait for DUT ready before driving address phase
            wait(vif.Hreadyout == 1'b1);
            @(posedge vif.clk);
            #1;  // Small delta delay after clock edge
            
            vif.Haddr = txn.Haddr;
            vif.Hwrite = txn.Hwrite;
            vif.Htrans = txn.Htrans;
            vif.Hreadyin = 1'b1;
            
            if (txn.Hwrite) begin
                // Write operation: drive data phase
                wait(vif.Hreadyout == 1'b1);
                @(posedge vif.clk);
                #1;
                vif.Hwdata = txn.Hwdata;
            end else begin
                // Read operation: simulate APB slave response
                // Wait for APB side to initiate read
                wait(vif.Paddr == txn.Haddr && vif.Pwrite == 1'b0);
                #1;
                // Drive Prdata to simulate APB slave returning data
                vif.Prdata = $urandom();  // Random data for now
                $display("[%0t] DRIVER: Simulating APB slave - Prdata=0x%0h", $time, vif.Prdata);
            end
            
            // Wait for transaction to complete
            wait(vif.Hreadyout == 1'b1);
            @(posedge vif.clk);
        end
    endtask

endclass
