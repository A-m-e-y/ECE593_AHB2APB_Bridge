
class scoreboard;

    transaction txn_drv;
    transaction txn_mon;
    mailbox #(transaction) driv2sb;
    mailbox #(transaction) mon2sb;
    
    int write_count = 0;
    int read_count = 0;
    int total_count = 0;

    // Coverage group for functional coverage
    covergroup cov_cg;
        Hwrite_cp: coverpoint txn_drv.Hwrite {
            bins read  = {1'b0};
            bins write = {1'b1};
        }
        Htrans_cp: coverpoint txn_drv.Htrans {
            bins non_seq = {2'b10};
            bins idle    = {2'b00};
            bins seq     = {2'b11};
        }
        Hsize_cp: coverpoint txn_drv.Hsize {
            bins size_byte     = {3'b000};
            bins size_halfword = {3'b001};
            bins size_word     = {3'b010};
        }
        Hburst_cp: coverpoint txn_drv.Hburst {
            bins single = {3'b000};
            bins incr   = {3'b001};
            bins wrap4  = {3'b010};
            bins incr4  = {3'b011};
        }
        Hwrite_x_htrans: cross Hwrite_cp, Htrans_cp;
        Hwrite_x_hsize: cross Hwrite_cp, Hsize_cp;
        Hwrite_x_hburst: cross Hwrite_cp, Hburst_cp;
    endgroup

    function new(mailbox #(transaction) driv2sb, mailbox #(transaction) mon2sb);
        this.driv2sb = driv2sb;
        this.mon2sb = mon2sb;
        cov_cg = new();
    endfunction

    task check_data();
        forever begin
            driv2sb.get(txn_drv);
            mon2sb.get(txn_mon);
            
            // Sample coverage
            cov_cg.sample();
            
            total_count++;
            
            if (txn_drv.Hwrite) begin
                write_count++;
                $display("[%0t] SCOREBOARD: Write - Haddr=0x%0h Hwdata=0x%0h | Paddr=0x%0h Pwdata=0x%0h", 
                         $time, txn_drv.Haddr, txn_drv.Hwdata, txn_mon.Paddr, txn_mon.Pwdata);
            end else begin
                read_count++;
                $display("[%0t] SCOREBOARD: Read  - Haddr=0x%0h | Paddr=0x%0h Prdata=0x%0h Hrdata=0x%0h", 
                         $time, txn_drv.Haddr, txn_mon.Paddr, txn_mon.Prdata, txn_mon.Hrdata);
            end
        end
    endtask

    function void report();
        $display("\n========== SCOREBOARD REPORT ==========");
        $display("Total Transactions: %0d", total_count);
        $display("  Writes: %0d", write_count);
        $display("  Reads:  %0d", read_count);
        $display("\n========== COVERAGE REPORT ============");
        $display("Functional Coverage: %.2f%%", $get_coverage());
        $display("=======================================\n");
    endfunction

endclass
