
class generator;

    transaction txn;             
    mailbox #(transaction) gen2driv;

    function new(mailbox #(transaction) gen2driv);
        this.gen2driv = gen2driv;
    endfunction
    
    // Simple write transaction
    task write_single(bit [31:0] addr, bit [31:0] data);
        txn = new();
        txn.Haddr = addr;
        txn.Hwrite = 1;
        txn.Hsize = 3'b010;  // Word
        txn.Hburst = 3'b000; // Single
        txn.Htrans = 2'b10;  // NONSEQ
        txn.Hwdata = data;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
    endtask

    // Simple read transaction
    task read_single(bit [31:0] addr);
        txn = new();
        txn.Haddr = addr;
        txn.Hwrite = 0;
        txn.Hsize = 3'b010;  // Word
        txn.Hburst = 3'b000; // Single
        txn.Htrans = 2'b10;  // NONSEQ
        txn.Hreadyin = 1;
        txn.Prdata  = 32'h1234_5678; // read data
        txn.update_trans_type();
        gen2driv.put(txn);
    endtask

    // Sanity test - matches traditional TB
    task sanity_test();
        $display("[%0t] GENERATOR: Starting sanity test (4 transactions)\n", $time);
        
        // Three writes
        write_single(32'h8000_0054, 32'h8000_0054);
        write_single(32'h8000_0058, 32'h8000_0058);
        write_single(32'h8000_005C, 32'h8000_005C);
        
        // One read
        read_single(32'h8000_00AA);
        
        $display("\n[%0t] GENERATOR: Stimulus generation complete", $time);
    endtask

endclass
