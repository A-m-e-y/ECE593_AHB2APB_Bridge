
class generator;

    transaction txn;             
    mailbox #(transaction) gen2driv;
    
    int txn_count = 0;

    function new(mailbox #(transaction) gen2driv);
        this.gen2driv = gen2driv;
    endfunction
    
    // simple write
    task write_single(bit [31:0] addr, bit [31:0] data);
        txn = new();
        txn.Haddr = addr;
        txn.Hwrite = 1;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b000;
        txn.Htrans = 2'b10;
        txn.Hwdata = data;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
    endtask

    // simple read
    task read_single(bit [31:0] addr);
        txn = new();
        txn.Haddr = addr;
        txn.Hwrite = 0;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b000;
        txn.Htrans = 2'b10;
        txn.Hreadyin = 1;
        txn.Prdata  = 32'h1234_5678;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
    endtask

    // sanity test
    task sanity_test();
        $display("[%0t] GENERATOR: Starting sanity test (4 transactions)\n", $time);
        txn_count = 0;
        
        write_single(32'h8000_0054, 32'h8000_0054);
        write_single(32'h8000_0058, 32'h8000_0058);
        write_single(32'h8000_005C, 32'h8000_005C);
        read_single(32'h8000_00AA);
        
        $display("\n[%0t] GENERATOR: Stimulus generation complete (%0d transactions)", $time, txn_count);
    endtask
    
    // random test generator
    task generate_random_test(int num_txns, string test_type = "BASE");
        transaction rand_txn;
        
        $display("[%0t] GENERATOR: Starting %s random test (%0d transactions)", $time, test_type, num_txns);
        txn_count = 0;
        
        for (int i = 0; i < num_txns; i++) begin
            // Create transaction based on test type
            case (test_type)
                "WRITE_ONLY":    rand_txn = write_txn::new();
                "READ_ONLY":     rand_txn = read_txn::new();
                "SEQ_TRANS":     rand_txn = seq_txn::new();
                "NONSEQ_TRANS":  rand_txn = nonseq_txn::new();
                default:         rand_txn = transaction::new();
            endcase
            
            if (!rand_txn.randomize()) begin
                $error("[%0t] GENERATOR: Randomization failed for transaction %0d!", $time, i);
                continue;
            end
            
            rand_txn.update_trans_type();
            gen2driv.put(rand_txn);
            txn_count++;
            
            if (i < 3 || i == num_txns-1) begin
                $display("[%0t]   Gen txn[%0d]: %s addr=0x%h size=%0d burst=%0d trans=%0d", 
                         $time, i, rand_txn.trans_type.name(), rand_txn.Haddr, 
                         rand_txn.Hsize, rand_txn.Hburst, rand_txn.Htrans);
            end
        end
        
        $display("\n[%0t] GENERATOR: %s test generation complete (%0d transactions)\n", 
                 $time, test_type, txn_count);
    endtask
    
    // multi-slave test
    task generate_multi_slave_test(int num_txns);
        transaction rand_txn;
        slave0_txn s0_txn;
        slave1_txn s1_txn;
        slave2_txn s2_txn;
        
        $display("[%0t] GENERATOR: Starting MULTI-SLAVE random test (%0d transactions)", $time, num_txns);
        txn_count = 0;
        
        for (int i = 0; i < num_txns; i++) begin
            // round-robin across slaves
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
    
    // directed FSM tests
    task directed_sequences();
        transaction txn;
        
        $display("[%0t] GENERATOR: Starting directed sequences for FSM coverage\n", $time);
        txn_count = 0;
        
        // write seq
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
        
        // read seq
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
        
        // WRITE then READ (wenable_to_read) ===
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
        
        // READ then WRITE (renable_to_wwait) ===
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
        
        // WRITE after WRITE (wenable_to_wwait) ===
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
        
        // Non-pipelined single WRITE (wwait_to_write) ===
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
        
        // WWAIT→WRITE (requires valid=0 after WWAIT) ===
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
        
        
        txn = new();
        txn.Htrans = 2'b00;  // IDLE
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // WRITE→WENABLE (requires valid=0) ===
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
        
        
        txn = new();
        txn.Htrans = 2'b00;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // WENABLE→IDLE (requires valid=0 after write completes) ===
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
        
        // RENABLE→IDLE (requires valid=0 after read completes) ===
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
        
        
        txn = new();
        txn.Htrans = 2'b00;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // WENABLEP→WRITE (valid=0 && Hwritereg) ===
        $display("[%0t]   Gap Test: WENABLEP→WRITE transition", $time);
        
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
        
        
        txn = new();
        txn.Htrans = 2'b00;
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // WENABLEP→READ (requires !Hwritereg) ===
        $display("[%0t]   Gap Test: WENABLEP→READ transition", $time);
        
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
        
        // WENABLE→WWAIT (write completes, immediate new write) ===
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
        
        // WENABLE→READ (write completes, immediate read) ===
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
        
        // RENABLE→WWAIT (read completes, immediate write) ===
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
        
        // WWAIT→WRITE with BUSY ===
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
        
        // All zeros data ===
        $display("[%0t]   Corner: All zeros data", $time);
        write_single(32'h8000_1000, 32'h0000_0000);
        
        // All ones data ===
        $display("[%0t]   Corner: All ones data", $time);
        write_single(32'h8000_2000, 32'hFFFF_FFFF);
        
        // Boundary address - Slave 0 min ===
        $display("[%0t]   Corner: Slave 0 minimum address", $time);
        write_single(32'h8000_0000, 32'hAAAA_AAAA);
        
        // Boundary address - Slave 0 max ===
        $display("[%0t]   Corner: Slave 0 maximum address", $time);
        write_single(32'h83FF_FFFF, 32'hBBBB_BBBB);
        
        // Boundary address - Slave 1 min ===
        $display("[%0t]   Corner: Slave 1 minimum address", $time);
        write_single(32'h8400_0000, 32'hCCCC_CCCC);
        
        // Boundary address - Slave 2 min ===
        $display("[%0t]   Corner: Slave 2 minimum address", $time);
        write_single(32'h8800_0000, 32'hDDDD_DDDD);
        
        // SEQ→SEQ sequence (burst continuation) ===
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
        
        // SEQ→IDLE sequence ===
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
        
        // (creates SEQ→IDLE)
        txn = new();
        txn.Htrans = 2'b00;   // IDLE
        txn.Hreadyin = 1;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        $display("\n[%0t] GENERATOR: CORNER CASE tests complete (%0d transactions)\n", $time, txn_count);
    endtask
    
    
    // conditional coverage tests


    task generate_cond_coverage_tests();
        transaction txn;
        
        $display("\n[%0t] ========================================", $time);
        $display("[%0t] GENERATOR: Starting COND Coverage Tests", $time);
        $display("[%0t] ========================================\n", $time);
        
        
        // Simple READ from IDLE
        
        
        
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
        
        
        // Multiple consecutive READs
        
        
        
        $display("[%0t] COND Test 2: Consecutive READs", $time);
        repeat(8) begin
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
        
        
        // READ followed by WRITE
        
        
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
        
        // followed by WRITE
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
        
        
        // WENABLEP state variations
        // Lines 94, 96, 218 - various valid/Hwritereg combinations
        
        
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
        
        
        // WENABLE state variations
        
        // Single write followed by idle
        
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
        
        
        // Mixed READ/WRITE patterns
        // Try various combinations to hit missing conditions
        // Also add more to stress various FSM states
        
        $display("[%0t] COND Test 6: Mixed R/W patterns + state stress", $time);
        
        // Mix of READs and WRITEs
        repeat(15) begin
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
        
        
        // Consecutive WRITEs to stress WWAIT state
        
        
        $display("[%0t] COND Test 7: Consecutive WRITEs for WWAIT", $time);
        repeat(10) begin
            txn = new();
            txn.Hwrite = 1;
            txn.Haddr = $urandom_range(32'h8000_0000, 32'h83FF_FFFF);
            txn.Hwdata = $urandom();
            txn.Hsize = 3'b010;
            txn.Hburst = 3'b000;
            txn.Htrans = 2'b10;
            txn.update_trans_type();
            gen2driv.put(txn);
            txn_count++;
        end
        
        $display("\n[%0t] COND Coverage tests complete (%0d total transactions)\n", $time, txn_count);
    endtask
    
    // Enhanced comprehensive test with directed sequences
    task generate_comprehensive_test_with_sequences(int txns_per_category);
        $display("[%0t] GENERATOR: Starting ENHANCED COMPREHENSIVE coverage test", $time);
        $display("   Testing directed sequences, FSM gaps, and stress tests\n");
        
        // Add directed sequences for FSM coverage
        directed_sequences();
        
        // Add FSM gap tests for missing transitions
        fsm_gap_tests();
        
        // Add targeted tests for specific missing transitions
        missing_transition_tests();
        
        // Add corner case tests
        corner_case_tests();
        
        // Add COND coverage tests for unreached conditions
        generate_cond_coverage_tests();
        
        // Add targeted tests for specific code coverage gaps
        generate_additional_code_coverage_tests();
        
        // Add extreme stress tests to maximize coverage
        generate_extreme_stress_tests();
        
        $display("\n[%0t] GENERATOR: ENHANCED COMPREHENSIVE test complete\n", $time);
    endtask
    
    
    // more directed tests for code coverage

    task generate_additional_code_coverage_tests();
        transaction txn;
        
        $display("\n[%0t] ========================================", $time);
        $display("[%0t] GENERATOR: Additional Code Coverage Tests", $time);
        $display("[%0t] ========================================\n", $time);
        
        
        // Address boundary testing for all 3 slaves
        // AHB_Slave_Interface lines 65, 75-79
        
        $display("[%0t] GAP Test 1: Address boundary coverage", $time);
        
        // Slave 0 boundaries
        test_address_boundary(32'h8000_0000, "Slave 0 start");
        test_address_boundary(32'h83FF_FFFC, "Slave 0 end");
        
        // Slave 1 boundaries
        test_address_boundary(32'h8400_0000, "Slave 1 start");
        test_address_boundary(32'h87FF_FFFC, "Slave 1 end");
        
        // Slave 2 boundaries
        test_address_boundary(32'h8800_0000, "Slave 2 start");
        test_address_boundary(32'h8BFF_FFFC, "Slave 2 end");
        
        // Just outside valid range (should be ignored but tests condition)
        test_address_boundary(32'h7FFF_FFFC, "Below range");
        test_address_boundary(32'h8C00_0000, "Above range");
        
        
        // Different transfer sizes at boundaries
        // Condition coverage for size-dependent paths
        
        $display("[%0t] GAP Test 2: Size variations at boundaries", $time);
        
        // Byte transfers
        txn = new();
        txn.Hwrite = 1;
        txn.Haddr = 32'h8000_0001;  // Byte aligned
        txn.Hwdata = 32'h000000AA;
        txn.Hsize = 3'b000;  // BYTE
        txn.Hburst = 3'b000;
        txn.Htrans = 2'b10;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // Halfword transfers
        txn = new();
        txn.Hwrite = 0;
        txn.Haddr = 32'h8400_0002;  // Halfword aligned
        txn.Hsize = 3'b001;  // HALFWORD
        txn.Hburst = 3'b000;
        txn.Htrans = 2'b10;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        
        // Rapid READ-WRITE transitions to stress FSM conditions
        // Lines 192, 201 - write after read edge cases
        
        $display("[%0t] GAP Test 3: Rapid R/W transitions", $time);
        
        repeat(10) begin
            // READ
            txn = new();
            txn.Hwrite = 0;
            txn.Haddr = $urandom_range(32'h8000_0000, 32'h8BFF_FFFF) & 32'hFFFF_FFFC;  // Word aligned
            txn.Hsize = 3'b010;
            txn.Hburst = 3'b000;
            txn.Htrans = 2'b10;
            txn.update_trans_type();
            gen2driv.put(txn);
            txn_count++;
            
            // followed by WRITE
            txn = new();
            txn.Hwrite = 1;
            txn.Haddr = $urandom_range(32'h8000_0000, 32'h8BFF_FFFF) & 32'hFFFF_FFFC;
            txn.Hwdata = $urandom();
            txn.Hsize = 3'b010;
            txn.Hburst = 3'b000;
            txn.Htrans = 2'b10;
            txn.update_trans_type();
            gen2driv.put(txn);
            txn_count++;
        end
        
        
        // WENABLEP exit variations
        // Lines 94, 96 - different valid/Hwritereg combinations
        
        $display("[%0t] GAP Test 4: WENABLEP state variations", $time);
        
        // Burst writes to reach WENABLEP, then vary exit paths
        repeat(3) begin
            // Start burst write (NONSEQ)
            txn = new();
            txn.Hwrite = 1;
            txn.Haddr = $urandom_range(32'h8000_0000, 32'h8BFF_FFFF) & 32'hFFFF_FFF0;
            txn.Hwdata = $urandom();
            txn.Hsize = 3'b010;
            txn.Hburst = 3'b011;  // INCR4
            txn.Htrans = 2'b10;   // NONSEQ
            txn.update_trans_type();
            gen2driv.put(txn);
            txn_count++;
            
            
            txn = new();
            txn.Hwrite = 1;
            txn.Haddr += 4;
            txn.Hwdata = $urandom();
            txn.Hsize = 3'b010;
            txn.Hburst = 3'b011;
            txn.Htrans = 2'b11;  // SEQ
            txn.update_trans_type();
            gen2driv.put(txn);
            txn_count++;
            
            
            txn = new();
            txn.Hwrite = 0;
            txn.Haddr = $urandom_range(32'h8000_0000, 32'h8BFF_FFFF) & 32'hFFFF_FFFC;
            txn.Hsize = 3'b010;
            txn.Hburst = 3'b000;
            txn.Htrans = 2'b10;
            txn.update_trans_type();
            gen2driv.put(txn);
            txn_count++;
        end
        
        
        // SEQ transaction after various states
        // Htrans=SEQ coverage in different contexts
        
        $display("[%0t] GAP Test 5: SEQ transaction coverage", $time);
        
        repeat(5) begin
            // NONSEQ start
            txn = new();
            txn.Hwrite = $urandom_range(0, 1);
            txn.Haddr = $urandom_range(32'h8000_0000, 32'h8BFF_FFFF) & 32'hFFFF_FFF0;
            if (txn.Hwrite) txn.Hwdata = $urandom();
            txn.Hsize = 3'b010;
            txn.Hburst = 3'b001;  // INCR
            txn.Htrans = 2'b10;   // NONSEQ
            txn.update_trans_type();
            gen2driv.put(txn);
            txn_count++;
            
            // SEQ continuation
            txn = new();
            txn.Hwrite = $urandom_range(0, 1);
            txn.Haddr += 4;
            if (txn.Hwrite) txn.Hwdata = $urandom();
            txn.Hsize = 3'b010;
            txn.Hburst = 3'b001;
            txn.Htrans = 2'b11;  // SEQ
            txn.update_trans_type();
            gen2driv.put(txn);
            txn_count++;
        end
        
        
        // WRAP4 burst coverage
        // WRAP4 burst type in all states
        
        $display("[%0t] GAP Test 6: WRAP4 burst coverage", $time);
        
        repeat(5) begin
            int base_addr = $urandom_range(32'h8000_0000, 32'h8BFF_FFF0) & 32'hFFFF_FFF0;
            
            for (int i = 0; i < 4; i++) begin
                txn = new();
                txn.Hwrite = $urandom_range(0, 1);
                txn.Haddr = base_addr + (i * 4);
                if (txn.Hwrite) txn.Hwdata = $urandom();
                txn.Hsize = 3'b010;
                txn.Hburst = 3'b010;  // WRAP4
                txn.Htrans = (i == 0) ? 2'b10 : 2'b11;  // NONSEQ then SEQ
                txn.update_trans_type();
                gen2driv.put(txn);
                txn_count++;
            end
        end
        
        $display("\n[%0t] Additional Code Coverage tests complete (%0d transactions)\n", $time, txn_count);
    endtask
    
    // Helper task for address boundary testing
    task test_address_boundary(bit [31:0] addr, string description);
        transaction txn;
        
        // Write to boundary
        txn = new();
        txn.Hwrite = 1;
        txn.Haddr = addr;
        txn.Hwdata = {addr[15:0], addr[31:16]};  // Pattern based on address
        txn.Hsize = 3'b010;  // Word
        txn.Hburst = 3'b000; // Single
        txn.Htrans = 2'b10;  // NONSEQ
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
        
        // Read from same boundary
        txn = new();
        txn.Hwrite = 0;
        txn.Haddr = addr;
        txn.Hsize = 3'b010;
        txn.Hburst = 3'b000;
        txn.Htrans = 2'b10;
        txn.update_trans_type();
        gen2driv.put(txn);
        txn_count++;
    endtask
    
    // stress tests
    task generate_extreme_stress_tests();
        transaction txn;
        
        $display("\n[%0t] ========================================", $time);
        $display("[%0t] GENERATOR: EXTREME Stress Tests for Max Coverage", $time);
        $display("[%0t] ========================================\n", $time);
        
        // Generate 1000 completely random transactions
        $display("[%0t] Stress Test 1: 1000 random transactions", $time);
        for (int i = 0; i < 1000; i++) begin
            txn = new();
            assert(txn.randomize());
            txn.update_trans_type();
            gen2driv.put(txn);
            txn_count++;
        end
        
        // Rapid burst sequences
        $display("[%0t] Stress Test 2: Rapid burst sequences", $time);
        repeat(50) begin
            // Random burst
            int burst_type = $urandom_range(0, 3);
            int num_beats = (burst_type == 3) ? 4 : $urandom_range(2, 8);
            bit is_write = $urandom_range(0, 1);
            bit [31:0] base_addr = $urandom_range(32'h8000_0000, 32'h8BFF_0000) & 32'hFFFF_FFF0;
            
            for (int j = 0; j < num_beats; j++) begin
                txn = new();
                txn.Hwrite = is_write;
                txn.Haddr = base_addr + (j * 4);
                if (is_write) txn.Hwdata = $urandom();
                txn.Hsize = 3'b010;
                txn.Hburst = burst_type;
                txn.Htrans = (j == 0) ? 2'b10 : 2'b11;
                txn.update_trans_type();
                gen2driv.put(txn);
                txn_count++;
            end
        end
        
        // Mixed operations all slaves
        $display("[%0t] Stress Test 3: All slaves with all sizes", $time);
        begin
            bit [31:0] slave_addrs[3] = '{32'h8000_0000, 32'h8400_0000, 32'h8800_0000};
            bit [2:0] sizes[3] = '{3'b000, 3'b001, 3'b010};
            
            for (int i = 0; i < 3; i++) begin
                for (int s = 0; s < 3; s++) begin
                    // Write
                    txn = new();
                    txn.Hwrite = 1;
                    txn.Haddr = slave_addrs[i];
                    txn.Hwdata = $urandom();
                    txn.Hsize = sizes[s];
                    txn.Hburst = 3'b000;
                    txn.Htrans = 2'b10;
                    txn.update_trans_type();
                    gen2driv.put(txn);
                    txn_count++;
                    
                    // Read
                    txn = new();
                    txn.Hwrite = 0;
                    txn.Haddr = slave_addrs[i] + 32;
                    txn.Hsize = sizes[s];
                    txn.Hburst = 3'b000;
                    txn.Htrans = 2'b10;
                    txn.update_trans_type();
                    gen2driv.put(txn);
                    txn_count++;
                end
            end
        end
        
        $display("\n[%0t] EXTREME Stress tests complete (%0d transactions)\n", $time, txn_count);
    endtask

endclass


