
class scoreboard;

    transaction txn_drv;
    transaction txn_mon;
    transaction txn_queue[$];
    mailbox #(transaction) driv2sb;
    mailbox #(transaction) mon2sb;
    
    int write_count = 0;
    int read_count = 0;
    int total_count = 0;

    // functional coverage
    covergroup cov_cg;
        Hwrite_cp: coverpoint txn_drv.Hwrite {
            bins read  = {1'b0};
            bins write = {1'b1};
        }
        Htrans_cp: coverpoint txn_drv.Htrans {
            bins non_seq = {2'b10};
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
        fork
            // collect driver txns
            forever begin
                driv2sb.get(txn_drv);
                
                // skip IDLE - DUT ignores them
                if (txn_drv.Htrans != 2'b00) begin
                    cov_cg.sample();
                    txn_queue.push_back(txn_drv);
                end
            end
            
            // match with monitor
            forever begin
                transaction matched_txn;
                int found = 0;
                
                mon2sb.get(txn_mon);
                
                // find matching addr
                for (int i = 0; i < txn_queue.size(); i++) begin
                    if (txn_queue[i].Haddr == txn_mon.Paddr) begin
                        matched_txn = txn_queue[i];
                        txn_queue.delete(i);
                        found = 1;
                        break;
                    end
                end
                
                if (!found) begin
                    $display("[%0t]   FAIL - Checker ERROR: No matching AHB transaction for APB addr(0x%0h)", 
                             $time, txn_mon.Paddr);
                    continue;
                end
                
                txn_drv = matched_txn;
                total_count++;
                
                if (txn_drv.Hwrite) begin
                    write_count++;
                    
                    if (txn_drv.Haddr == txn_mon.Paddr && txn_drv.Hwdata == txn_mon.Pwdata) begin
                        $display("[%0t]   PASS - Checker: AHB→APB translation OK", $time);
                    end else begin
                        $display("[%0t]   FAIL - Checker ERROR: AHB(0x%0h/0x%0h) != APB(0x%0h/0x%0h)", 
                                 $time, txn_drv.Haddr, txn_drv.Hwdata, txn_mon.Paddr, txn_mon.Pwdata);
                    end
                end else begin
                    read_count++;
                    
                    if (txn_drv.Haddr == txn_mon.Paddr) begin
                        $display("[%0t]   PASS - Checker: AHB→APB addr OK, APB Read Data=0x%0h", 
                                 $time, txn_mon.Prdata);
                    end else begin
                        $display("[%0t]   FAIL - Checker ERROR: AHB addr(0x%0h) != APB addr(0x%0h)", 
                                 $time, txn_drv.Haddr, txn_mon.Paddr);
                    end
                end
            end
        join_none
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
