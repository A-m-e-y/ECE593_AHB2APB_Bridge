
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
            
            // EXACT pattern from traditional TB
            // Address Phase
            wait(vif.Hreadyout == 1'b1);
            @(posedge vif.clk);
            #1;
            vif.Hwrite = txn.Hwrite;
            vif.Htrans = txn.Htrans;
            vif.Haddr = txn.Haddr;
            vif.Hreadyin = 1'b1;
            
            // Data Phase
            wait(vif.Hreadyout == 1'b1);
            @(posedge vif.clk);
            #1;
            if (txn.Hwrite) begin
                vif.Hwdata = txn.Hwdata;
                // Wait for APB transaction to complete  
                wait(vif.Hreadyout == 1'b1);
                @(posedge vif.clk);
                #1;
                // De-assert Htrans to IDLE to allow FSM to cycle
                vif.Htrans = 2'b00;
                // Extra Hclk cycles for CDC - ensures Penable_hclk stays low long enough
                // (80ns) to accommodate 3-FF synchronizer delay (60ns) for pipelined transactions
                @(posedge vif.clk);
                @(posedge vif.clk);
                @(posedge vif.clk);
                @(posedge vif.clk);
                @(posedge vif.clk);
                @(posedge vif.clk);
                @(posedge vif.clk);
                @(posedge vif.clk);
            end else begin
                // For reads, wait for APB transaction and provide Prdata
                wait(vif.Paddr == txn.Haddr && vif.Pwrite == 1'b0);
                vif.Prdata = $urandom();
                $display("[%0t] DRIVER: Providing Prdata=0x%0h for read", $time, vif.Prdata);
                // Extra Hclk cycles for CDC after read (80ns for 3-FF synchronizer)
                @(posedge vif.clk);
                @(posedge vif.clk);
                @(posedge vif.clk);
                @(posedge vif.clk);
                @(posedge vif.clk);
                @(posedge vif.clk);
                @(posedge vif.clk);
                @(posedge vif.clk);
            end
        end
    endtask

endclass
