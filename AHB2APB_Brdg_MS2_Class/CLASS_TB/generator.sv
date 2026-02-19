
class generator;

    transaction txn;             
    mailbox #(transaction) gen2driv;
    
    int txn_count = 0;  // Track number of transactions generated

    function new(mailbox #(transaction) gen2driv);
        this.gen2driv = gen2driv;
    endfunction
    
    // ========== DIRECTED TESTS (Original Sanity) ==========
    
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
        txn_count++;
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
        txn_count++;
    endtask

    // Sanity test - matches traditional TB (keep for regression)
    task sanity_test();
        $display("[%0t] GENERATOR: Starting sanity test (4 transactions)\n", $time);
        txn_count = 0;
        
        // Three writes
        write_single(32'h8000_0054, 32'h8000_0054);
        write_single(32'h8000_0058, 32'h8000_0058);
        write_single(32'h8000_005C, 32'h8000_005C);
        
        // One read
        read_single(32'h8000_00AA);
        
        $display("\n[%0t] GENERATOR: Stimulus generation complete (%0d transactions)", $time, txn_count);
    endtask
    
    // ========== RANDOMIZED TESTS WITH CONSTRAINTS ==========
    
    // Generate N random transactions with specific constraint class
    task generate_random_test(int num_txns, string test_type = "BASE");
        transaction rand_txn;
        
        $display("[%0t] GENERATOR: Starting %s random test (%0d transactions)", $time, test_type, num_txns);
        txn_count = 0;
        
        for (int i = 0; i < num_txns; i++) begin
            // Create transaction based on test type (polymorphism/upcasting)
            case (test_type)
                "WRITE_ONLY":    rand_txn = write_txn::new();
                "READ_ONLY":     rand_txn = read_txn::new();
                "BYTE_SIZE":     rand_txn = byte_txn::new();
                "HALFWORD_SIZE": rand_txn = halfword_txn::new();
                "WORD_SIZE":     rand_txn = word_txn::new();
                "INCR_BURST":    rand_txn = incr_burst_txn::new();
                "WRAP4_BURST":   rand_txn = wrap4_burst_txn::new();
                "INCR4_BURST":   rand_txn = incr4_burst_txn::new();
                "SLAVE0":        rand_txn = slave0_txn::new();
                "SLAVE1":        rand_txn = slave1_txn::new();
                "SLAVE2":        rand_txn = slave2_txn::new();
                "SEQ_TRANS":     rand_txn = seq_txn::new();
                "NONSEQ_TRANS":  rand_txn = nonseq_txn::new();
                "BOUNDARY":      rand_txn = boundary_addr_txn::new();
                "PATTERN_DATA":  rand_txn = pattern_data_txn::new();
                default:         rand_txn = transaction::new();  // Base random
            endcase
            
            // Randomize the transaction
            if (!rand_txn.randomize()) begin
                $error("[%0t] GENERATOR: Randomization failed for transaction %0d!", $time, i);
                continue;
            end
            
            // Update transaction type and send
            rand_txn.update_trans_type();
            gen2driv.put(rand_txn);
            txn_count++;
            
            // Debug: Print occasional transactions
            if (i < 3 || i == num_txns-1) begin
                $display("[%0t]   Gen txn[%0d]: %s addr=0x%h size=%0d burst=%0d trans=%0d", 
                         $time, i, rand_txn.trans_type.name(), rand_txn.Haddr, 
                         rand_txn.Hsize, rand_txn.Hburst, rand_txn.Htrans);
            end
        end
        
        $display("\n[%0t] GENERATOR: %s test generation complete (%0d transactions)\n", 
                 $time, test_type, txn_count);
    endtask
    
    // Mixed random test with all slaves
    task generate_multi_slave_test(int num_txns);
        transaction rand_txn;
        slave0_txn s0_txn;
        slave1_txn s1_txn;
        slave2_txn s2_txn;
        
        $display("[%0t] GENERATOR: Starting MULTI-SLAVE random test (%0d transactions)", $time, num_txns);
        txn_count = 0;
        
        for (int i = 0; i < num_txns; i++) begin
            // Distribute evenly across 3 slaves
            case (i % 3)
                0: begin
                    s0_txn = slave0_txn::new();
                    assert(s0_txn.randomize());
                    s0_txn.update_trans_type();
                    gen2driv.put(s0_txn);
                end
                1: begin
                    s1_txn = slave1_txn::new();
                    assert(s1_txn.randomize());
                    s1_txn.update_trans_type();
                    gen2driv.put(s1_txn);
                end
                2: begin
                    s2_txn = slave2_txn::new();
                    assert(s2_txn.randomize());
                    s2_txn.update_trans_type();
                    gen2driv.put(s2_txn);
                end
            endcase
            txn_count++;
        end
        
        $display("\n[%0t] GENERATOR: MULTI-SLAVE test complete (%0d transactions)\n", $time, txn_count);
    endtask
    
    // Directed sequence tests for FSM transition coverage
    task directed_sequences();
        transaction txn;
        
        $display("[%0t] GENERATOR: Starting directed sequences for FSM coverage\n", $time);
        txn_count = 0;
        
        // === Sequence 1: Complete WRITE sequence (IDLE→WWAIT→WRITE→WENABLE→IDLE) ===
        $display("[%0t]   Directed: WRITE sequence", $time);
        txn = new();
        txn.Haddr = 32'h8000_1000;
        txn.Hwrite = 1;
        txn.Hsize = 3'b010;  // Word
        txn.Hburst = 3'b000; // Single
        txn.Htrans = 2'b10;  // NONSEQ
        txn.Hwdata = 32'hDEAD_BEEF;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // === Sequence 2: Complete READ sequence (IDLE→READ→RENABLE→IDLE) ===
        $display("[%0t]   Directed: READ sequence", $time);
        txn = new();
        txn.Haddr = 32'h8000_1004;
        txn.Hwrite = 0;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b000;
        txn.Htrans = 2'b10;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // === Sequence 3: WRITE then READ (wenable_to_read) ===
        $display("[%0t]   Directed: WRITE→READ sequence", $time);
        txn = new();
        txn.Haddr = 32'h8000_2000;
        txn.Hwrite = 1;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b000;
        txn.Htrans = 2'b10;
        txn.Hwdata = 32'h1111_2222;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // Immediately follow with READ
        txn = new();
        txn.Haddr = 32'h8000_2004;
        txn.Hwrite = 0;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b000;
        txn.Htrans = 2'b10;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // === Sequence 4: READ then WRITE (renable_to_wwait) ===
        $display("[%0t]   Directed: READ→WRITE sequence", $time);
        txn = new();
        txn.Haddr = 32'h8000_3000;
        txn.Hwrite = 0;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b000;
        txn.Htrans = 2'b10;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // Immediately follow with WRITE
        txn = new();
        txn.Haddr = 32'h8000_3004;
        txn.Hwrite = 1;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b000;
        txn.Htrans = 2'b10;
        txn.Hwdata = 32'h3333_4444;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // === Sequence 5: WRITE after WRITE (wenable_to_wwait) ===
        $display("[%0t]   Directed: WRITE→WRITE sequence", $time);
        txn = new();
        txn.Haddr = 32'h8000_4000;
        txn.Hwrite = 1;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b000;
        txn.Htrans = 2'b10;
        txn.Hwdata = 32'h5555_6666;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // Another WRITE
        txn = new();
        txn.Haddr = 32'h8000_4004;
        txn.Hwrite = 1;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b000;
        txn.Htrans = 2'b10;
        txn.Hwdata = 32'h7777_8888;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // === Sequence 6: Non-pipelined single WRITE (wwait_to_write) ===
        $display("[%0t]   Directed: Simple WRITE (non-pipelined)", $time);
        txn = new();
        txn.Haddr = 32'h8000_5000;
        txn.Hwrite = 1;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b000;  // SINGLE burst
        txn.Htrans = 2'b10;
        txn.Hwdata = 32'h9999_AAAA;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        $display("\n[%0t] GENERATOR: Directed sequences complete (%0d transactions)\n", $time, txn_count);
    endtask
    
    // New task: FSM transition gap tests (with IDLE cycles to force valid=0)
    task fsm_gap_tests();
        transaction txn;
        
        $display("[%0t] GENERATOR: Starting FSM GAP tests (with IDLE cycles)\n", $time);
        txn_count = 0;
        
        // === Test 1: WWAIT→WRITE (requires valid=0 after WWAIT) ===
        $display("[%0t]   Gap Test: WWAIT→WRITE transition", $time);
        txn = new();
        txn.Haddr = 32'h8000_A000;
        txn.Hwrite = 1;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b000;
        txn.Htrans = 2'b10;  // NONSEQ
        txn.Hwdata = 32'hA000_0001;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // Insert IDLE to force valid=0
        txn = new();
        txn.Htrans = 2'b00;  // IDLE
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // === Test 2: WRITE→WENABLE (requires valid=0) ===
        $display("[%0t]   Gap Test: WRITE→WENABLE transition", $time);
        txn = new();
        txn.Haddr = 32'h8000_B000;
        txn.Hwrite = 1;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b000;
        txn.Htrans = 2'b10;
        txn.Hwdata = 32'hB000_0002;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // Insert IDLE
        txn = new();
        txn.Htrans = 2'b00;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // === Test 3: WENABLE→IDLE (requires valid=0 after write completes) ===
        $display("[%0t]   Gap Test: WENABLE→IDLE transition", $time);
        txn = new();
        txn.Haddr = 32'h8000_C000;
        txn.Hwrite = 1;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b000;
        txn.Htrans = 2'b10;
        txn.Hwdata = 32'hC000_0003;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // Insert multiple IDLEs to ensure WENABLE→IDLE
        txn = new();
        txn.Htrans = 2'b00;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        txn = new();
        txn.Htrans = 2'b00;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // === Test 4: RENABLE→IDLE (requires valid=0 after read completes) ===
        $display("[%0t]   Gap Test: RENABLE→IDLE transition", $time);
        txn = new();
        txn.Haddr = 32'h8000_D000;
        txn.Hwrite = 0;  // READ
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b000;
        txn.Htrans = 2'b10;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // Insert IDLE
        txn = new();
        txn.Htrans = 2'b00;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // === Test 5: WENABLEP→WRITE (valid=0 && Hwritereg) ===
        $display("[%0t]   Gap Test: WENABLEP→WRITE transition", $time);
        // First do a pipelined write to get to WENABLEP
        txn = new();
        txn.Haddr = 32'h8000_E000;
        txn.Hwrite = 1;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b000;
        txn.Htrans = 2'b10;
        txn.Hwdata = 32'hE000_0005;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // Follow with another WRITE (creates WENABLEP)
        txn = new();
        txn.Haddr = 32'h8000_E004;
        txn.Hwrite = 1;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b000;
        txn.Htrans = 2'b10;
        txn.Hwdata = 32'hE000_0006;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // Insert IDLE to force WENABLEP→WRITE
        txn = new();
        txn.Htrans = 2'b00;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // === Test 6: WENABLEP→READ (requires !Hwritereg) ===
        $display("[%0t]   Gap Test: WENABLEP→READ transition", $time);
        // First do a pipelined write
        txn = new();
        txn.Haddr = 32'h8000_F000;
        txn.Hwrite = 1;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b000;
        txn.Htrans = 2'b10;
        txn.Hwdata = 32'hF000_0007;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // Follow with READ (creates WENABLEP, then should go to READ)
        txn = new();
        txn.Haddr = 32'h8000_F004;
        txn.Hwrite = 0;  // READ
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b000;
        txn.Htrans = 2'b10;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        $display("\n[%0t] GENERATOR: FSM GAP tests complete (%0d transactions)\n", $time, txn_count);
    endtask
    
    // New task: Targeted tests for specific missing FSM transitions
    task missing_transition_tests();
        transaction txn;
        
        $display("[%0t] GENERATOR: Starting MISSING TRANSITION tests\n", $time);
        txn_count = 0;
        
        // === Test 1: WENABLE→WWAIT (write completes, immediate new write) ===
        $display("[%0t]   Target: WENABLE→WWAIT (write then write)", $time);
        txn = new();
        txn.Haddr = 32'h8000_1000;
        txn.Hwrite = 1;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b001;  // INCR burst
        txn.Htrans = 2'b10;   // NONSEQ
        txn.Hwdata = 32'h1111_1111;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // SEQ transaction (continues burst - this should catch WENABLE state)
        txn = new();
        txn.Haddr = 32'h8000_1004;
        txn.Hwrite = 1;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b001;
        txn.Htrans = 2'b11;   // SEQ
        txn.Hwdata = 32'h2222_2222;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // === Test 2: WENABLE→READ (write completes, immediate read) ===
        $display("[%0t]   Target: WENABLE→READ (write then read)", $time);
        txn = new();
        txn.Haddr = 32'h8000_2000;
        txn.Hwrite = 1;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b001;  // INCR
        txn.Htrans = 2'b10;
        txn.Hwdata = 32'h3333_3333;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // SEQ read (write→read in burst should catch WENABLE)
        txn = new();
        txn.Haddr = 32'h8000_2004;
        txn.Hwrite = 0;  // READ
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b001;
        txn.Htrans = 2'b11;  // SEQ
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // === Test 3: RENABLE→WWAIT (read completes, immediate write) ===
        $display("[%0t]   Target: RENABLE→WWAIT (read then write)", $time);
        txn = new();
        txn.Haddr = 32'h8000_3000;
        txn.Hwrite = 0;  // READ
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b001;  // INCR
        txn.Htrans = 2'b10;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // SEQ write (read→write in burst should catch RENABLE)
        txn = new();
        txn.Haddr = 32'h8000_3004;
        txn.Hwrite = 1;  // WRITE
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b001;
        txn.Htrans = 2'b11;  // SEQ
        txn.Hwdata = 32'h4444_4444;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // === Test 4: WWAIT→WRITE with BUSY ===
        $display("[%0t]   Target: WWAIT→WRITE (write with BUSY)", $time);
        txn = new();
        txn.Haddr = 32'h8000_4000;
        txn.Hwrite = 1;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b011;  // INCR4
        txn.Htrans = 2'b10;   // NONSEQ
        txn.Hwdata = 32'h5555_5555;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // BUSY transaction (should make valid=0)
        txn = new();
        txn.Htrans = 2'b01;  // BUSY
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // Continue with SEQ
        txn = new();
        txn.Haddr = 32'h8000_4004;
        txn.Hwrite = 1;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b011;
        txn.Htrans = 2'b11;  // SEQ
        txn.Hwdata = 32'h6666_6666;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        $display("\n[%0t] GENERATOR: MISSING TRANSITION tests complete (%0d transactions)\n", $time, txn_count);
    endtask
    
    // New task: Corner case tests for data patterns and boundary addresses
    task corner_case_tests();
        transaction txn;
        
        $display("[%0t] GENERATOR: Starting CORNER CASE tests\n", $time);
        txn_count = 0;
        
        // === Test 1: All zeros data ===
        $display("[%0t]   Corner: All zeros data", $time);
        write_single(32'h8000_1000, 32'h0000_0000);
        
        // === Test 2: All ones data ===
        $display("[%0t]   Corner: All ones data", $time);
        write_single(32'h8000_2000, 32'hFFFF_FFFF);
        
        // === Test 3: Boundary address - Slave 0 min ===
        $display("[%0t]   Corner: Slave 0 minimum address", $time);
        write_single(32'h8000_0000, 32'hAAAA_AAAA);
        
        // === Test 4: Boundary address - Slave 0 max ===
        $display("[%0t]   Corner: Slave 0 maximum address", $time);
        write_single(32'h83FF_FFFF, 32'hBBBB_BBBB);
        
        // === Test 5: Boundary address - Slave 1 min ===
        $display("[%0t]   Corner: Slave 1 minimum address", $time);
        write_single(32'h8400_0000, 32'hCCCC_CCCC);
        
        // === Test 6: Boundary address - Slave 2 min ===
        $display("[%0t]   Corner: Slave 2 minimum address", $time);
        write_single(32'h8800_0000, 32'hDDDD_DDDD);
        
        // === Test 7: SEQ→SEQ sequence (burst continuation) ===
        $display("[%0t]   Corner: SEQ→SEQ sequence", $time);
        txn = new();
        txn.Haddr = 32'h8000_3000;
        txn.Hwrite = 1;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b011;  // INCR4
        txn.Htrans = 2'b10;   // NONSEQ
        txn.Hwdata = 32'h1111_1111;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // First SEQ
        txn = new();
        txn.Haddr = 32'h8000_3004;
        txn.Hwrite = 1;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b011;
        txn.Htrans = 2'b11;   // SEQ
        txn.Hwdata = 32'h2222_2222;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // Second SEQ (creates SEQ→SEQ)
        txn = new();
        txn.Haddr = 32'h8000_3008;
        txn.Hwrite = 1;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b011;
        txn.Htrans = 2'b11;   // SEQ
        txn.Hwdata = 32'h3333_3333;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // === Test 8: SEQ→IDLE sequence ===
        $display("[%0t]   Corner: SEQ→IDLE sequence", $time);
        txn = new();
        txn.Haddr = 32'h8000_4000;
        txn.Hwrite = 1;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b001;  // INCR
        txn.Htrans = 2'b10;   // NONSEQ
        txn.Hwdata = 32'h4444_4444;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // SEQ
        txn = new();
        txn.Haddr = 32'h8000_4004;
        txn.Hwrite = 1;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b001;
        txn.Htrans = 2'b11;   // SEQ
        txn.Hwdata = 32'h5555_5555;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // IDLE (creates SEQ→IDLE)
        txn = new();
        txn.Htrans = 2'b00;   // IDLE
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        $display("\n[%0t] GENERATOR: CORNER CASE tests complete (%0d transactions)\n", $time, txn_count);
    endtask
    
    // ========================================================================
    // DEDICATED CONDITIONAL COVERAGE TESTS
    // ========================================================================
    // These tests target specific unreachable conditions in RTL
    // to improve COND coverage from 54% to 75%+
    // ========================================================================
    
    task generate_cond_coverage_tests();
        transaction txn;
        
        $display("\n[%0t] ========================================", $time);
        $display("[%0t] GENERATOR: Starting COND Coverage Tests", $time);
        $display("[%0t] ========================================\n", $time);
        
        // ====================================================================
        // TEST 1: Simple READ from IDLE
        // Target: Line 129 condition (valid=1, Hwrite=0)
        // This is IDLE→READ transition, should be easy
        // ====================================================================
        $display("[%0t] COND Test 1: READ from IDLE (Line 129)", $time);
        txn = new();
        txn.Hwrite = 0;  // READ
        txn.Haddr = 32'h8000_1000;
        txn.Hsize = 3'b010;  // WORD
        txn.Hburst = 3'b000;  // SINGLE
        txn.Htrans = 2'b10;   // NONSEQ
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // ====================================================================
        // TEST 2: Multiple consecutive READs
        // Target: Line 192 condition in RENABLE output logic
        // Try to catch RENABLE with valid=1, Hwrite=1
        // ====================================================================
        $display("[%0t] COND Test 2: Consecutive READs (Line 192)", $time);
        repeat(5) begin
            txn = new();
            txn.Hwrite = 0;  // READ
            txn.Haddr = $urandom_range(32'h8000_0000, 32'h83FF_FFFF);
            txn.Hsize = 3'b010;
            txn.Hburst = 3'b000;
            txn.Htrans = 2'b10;
            txn.update_trans_type();
            gen2driv.put(txn);
            txn_count++;
        end
        
        // ====================================================================
        // TEST 3: READ followed by WRITE
        // Target: Line 192 - try to get valid=1 Hwrite=1 during RENABLE
        // ====================================================================
        $display("[%0t] COND Test 3: READ→WRITE sequence (Line 192)", $time);
        // READ
        txn = new();
        txn.Hwrite = 0;
        txn.Haddr = 32'h8000_2000;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b000;
        txn.Htrans = 2'b10;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // Immediately followed by WRITE
        txn = new();
        txn.Hwrite = 1;  // WRITE
        txn.Haddr = 32'h8000_2004;
        txn.Hwdata = 32'hAAAA_BBBB;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b000;
        txn.Htrans = 2'b10;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // ====================================================================
        // TEST 4: WENABLEP state variations
        // Target: Lines 94, 96, 218 - various valid/Hwritereg combinations
        // Need pipelined writes to get to WENABLEP
        // ====================================================================
        $display("[%0t] COND Test 4: WENABLEP variations (Lines 94,96,218)", $time);
        
        // Pipelined WRITE sequence to reach WENABLEP
        // Write 1
        txn = new();
        txn.Hwrite = 1;
        txn.Haddr = 32'h8000_3000;
        txn.Hwdata = 32'h1111_1111;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b011;  // INCR4
        txn.Htrans = 2'b10;   // NONSEQ
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // Write 2 (SEQ)
        txn = new();
        txn.Hwrite = 1;
        txn.Haddr = 32'h8000_3004;
        txn.Hwdata = 32'h2222_2222;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b011;
        txn.Htrans = 2'b11;   // SEQ
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // Write 3 (SEQ)
        txn = new();
        txn.Hwrite = 1;
        txn.Haddr = 32'h8000_3008;
        txn.Hwdata = 32'h3333_3333;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b011;
        txn.Htrans = 2'b11;   // SEQ
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // ====================================================================
        // TEST 5: WENABLE state variations
        // Target: Line 241 - (~valid && Hwritereg) condition
        // Single write followed by idle
        // ====================================================================
        $display("[%0t] COND Test 5: WENABLE variations (Line 241)", $time);
        txn = new();
        txn.Hwrite = 1;
        txn.Haddr = 32'h8400_0000;  // SLAVE1
        txn.Hwdata = 32'hDEAD_BEEF;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b000;  // SINGLE
        txn.Htrans = 2'b10;   // NONSEQ
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // ====================================================================
        // TEST 6: Mixed READ/WRITE patterns
        // Try various combinations to hit missing conditions
        // ====================================================================
        $display("[%0t] COND Test 6: Mixed R/W patterns", $time);
        repeat(10) begin
            txn = new();
            txn.Hwrite = $urandom_range(0, 1);
            txn.Haddr = $urandom_range(32'h8000_0000, 32'h8BFF_FFFF);
            if (txn.Hwrite) txn.Hwdata = $urandom();
            txn.Hsize = 3'b010;
            txn.Hburst = 3'b000;
            txn.Htrans = 2'b10;
            txn.update_trans_type();
            gen2driv.put(txn);
            txn_count++;
        end
        
        $display("\n[%0t] COND Coverage tests complete (%0d transactions)\n", $time, txn_count);
    endtask
    
    // Enhanced comprehensive test with directed sequences
    task generate_comprehensive_test_with_sequences(int txns_per_category);
        $display("[%0t] GENERATOR: Starting ENHANCED COMPREHENSIVE coverage test", $time);
        $display("   Testing all sizes, bursts, slaves, transaction types AND directed sequences\n");
        
        // First run all the random tests
        generate_random_test(txns_per_category, "BYTE_SIZE");
        generate_random_test(txns_per_category, "HALFWORD_SIZE");
        generate_random_test(txns_per_category, "WORD_SIZE");
        generate_random_test(txns_per_category, "INCR_BURST");
        generate_random_test(txns_per_category, "WRAP4_BURST");
        generate_random_test(txns_per_category, "INCR4_BURST");
        generate_random_test(txns_per_category, "SLAVE0");
        generate_random_test(txns_per_category, "SLAVE1");
        generate_random_test(txns_per_category, "SLAVE2");
        generate_random_test(txns_per_category, "SEQ_TRANS");
        generate_random_test(txns_per_category/2, "BOUNDARY");
        generate_random_test(txns_per_category/2, "PATTERN_DATA");
        generate_random_test(txns_per_category*2, "BASE");
        
        // NOW add directed sequences for FSM coverage
        directed_sequences();
        
        // Add FSM gap tests for missing transitions
        fsm_gap_tests();
        
        // Add targeted tests for specific missing transitions
        missing_transition_tests();
        
        // Add corner case tests
        corner_case_tests();
        
        // Add COND coverage tests for unreached conditions
        generate_cond_coverage_tests();
        
        $display("\n[%0t] GENERATOR: ENHANCED COMPREHENSIVE test complete\n", $time);
    endtask

endclass
