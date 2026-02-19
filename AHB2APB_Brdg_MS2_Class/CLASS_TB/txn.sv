// ============================================================================
// Base Transaction Class - Randomized with Constraints
// ============================================================================

class transaction;

  typedef enum {AHB_READ, AHB_WRITE} trans_type_e;
  trans_type_e trans_type;

  // AHB Input signals (driven by driver) - RANDOMIZED
  rand bit [31:0] Haddr;
  rand bit [31:0] Hwdata;
  rand bit Hwrite;
  rand bit [1:0] Htrans;
  rand bit [2:0] Hsize;
  rand bit [2:0] Hburst;
  bit Hreadyin;  // Always 1 for normal operation
  
  // AHB Output signals (from DUT, captured by monitor)
  bit [31:0] Hrdata;
  bit [1:0] Hresp;
  bit Hreadyout;
  
  // APB Output signals (from DUT, captured by monitor)
  bit [31:0] Paddr;
  bit [31:0] Pwdata;
  bit Pwrite;
  bit [2:0] Pselx;
  bit Penable;
  bit [31:0] Prdata;

  // ========== CONSTRAINTS FOR VALID AHB TRANSACTIONS ==========
  
  // Address must be in valid APB slave range (0x8000_0000 to 0x8BFF_FFFF)
  constraint valid_addr_c {
    Haddr inside {[32'h8000_0000 : 32'h8BFF_FFFF]};
  }
  
  // Size: byte(000), halfword(001), word(010)
  constraint valid_size_c {
    Hsize inside {3'b000, 3'b001, 3'b010};
  }
  
  // Burst: SINGLE(000), INCR(001), WRAP4(010), INCR4(011)
  constraint valid_burst_c {
    Hburst inside {3'b000, 3'b001, 3'b010, 3'b011};
  }
  
  // Htrans: IDLE(00), NONSEQ(10), SEQ(11)  [BUSY not used in this design]
  constraint valid_trans_c {
    Htrans inside {2'b00, 2'b10, 2'b11};
  }
  
  // Read/Write distribution
  constraint rw_dist_c {
    Hwrite dist {0 := 50, 1 := 50};  // 50% read, 50% write
  }
  
  // Realistic distribution for Htrans (mostly NONSEQ)
  constraint trans_dist_c {
    Htrans dist {2'b10 := 80, 2'b11 := 15, 2'b00 := 5};
  }
  
  // Word-aligned addresses based on size
  constraint addr_align_c {
    if (Hsize == 3'b000) Haddr[1:0] == 2'b00;  // Byte (no alignment needed but keep word)
    if (Hsize == 3'b001) Haddr[1:0] inside {2'b00, 2'b10};  // Halfword (2-byte aligned)
    if (Hsize == 3'b010) Haddr[1:0] == 2'b00;  // Word (4-byte aligned)
  }

  // Constructor
  function new();
    Hreadyin = 1;  // Always ready
  endfunction

  function void update_trans_type();
    if (Hwrite == 1) 
      trans_type = AHB_WRITE;
    else
      trans_type = AHB_READ;
  endfunction

  function void print_transaction();
    $display("Transaction Details:");
    $display("-------------------");
    $display("Transaction Type: %s", trans_type.name());
    $display("Haddr: 0x%0h", Haddr);
    $display("Hwdata: 0x%0h", Hwdata);
    $display("Hwrite: %0b", Hwrite);
    $display("Htrans: %0b", Htrans);
    $display("Hsize: %0b", Hsize);
    $display("Hburst: %0b", Hburst);
    $display("Hreadyin: %0b", Hreadyin);
    $display("Hrdata: 0x%0h", Hrdata);
    $display("Hreadyout: %0b", Hreadyout);
    $display("Hresp: %0b", Hresp);
    $display("Paddr: 0x%0h", Paddr);
    $display("Pwdata: 0x%0h", Pwdata);
    $display("Pwrite: %0b", Pwrite);
    $display("Pselx: %0b", Pselx);
    $display("Penable: %0b", Penable);
    $display("Prdata: 0x%0h", Prdata);
  endfunction

endclass


// ============================================================================
// EXTENDED TRANSACTION CLASSES - Specific Test Scenarios
// ============================================================================

// Write-only transactions
class write_txn extends transaction;
  constraint write_only_c {
    Hwrite == 1;
  }
endclass

// Read-only transactions
class read_txn extends transaction;
  constraint read_only_c {
    Hwrite == 0;
  }
endclass

// Different sizes (focus on byte and halfword)
class byte_txn extends transaction;
  constraint byte_size_c {
    Hsize == 3'b000;
  }
endclass

class halfword_txn extends transaction;
  constraint halfword_size_c {
    Hsize == 3'b001;
  }
endclass

class word_txn extends transaction;
  constraint word_size_c {
    Hsize == 3'b010;
  }
endclass

// Different bursts
class incr_burst_txn extends transaction;
  constraint incr_c {
    Hburst == 3'b001;
  }
endclass

class wrap4_burst_txn extends transaction;
  constraint wrap4_c {
    Hburst == 3'b010;
  }
endclass

class incr4_burst_txn extends transaction;
  constraint incr4_c {
    Hburst == 3'b011;
  }
endclass

// Target specific APB slaves
class slave0_txn extends transaction;
  constraint slave0_c {
    Haddr inside {[32'h8000_0000 : 32'h83FF_FFFF]};
  }
endclass

class slave1_txn extends transaction;
  constraint slave1_c {
    Haddr inside {[32'h8400_0000 : 32'h87FF_FFFF]};
  }
endclass

class slave2_txn extends transaction;
  constraint slave2_c {
    Haddr inside {[32'h8800_0000 : 32'h8BFF_FFFF]};
  }
endclass

// Sequential transfers (for pipelined scenarios)
class seq_txn extends transaction;
  constraint seq_trans_c {
    Htrans == 2'b11;
  }
endclass

class nonseq_txn extends transaction;
  constraint nonseq_trans_c {
    Htrans == 2'b10;
  }
endclass

// Corner case - boundary addresses
class boundary_addr_txn extends transaction;
  constraint boundary_c {
    Haddr inside {
      32'h8000_0000, 32'h83FF_FFFC,  // Slave 0 boundaries
      32'h8400_0000, 32'h87FF_FFFC,  // Slave 1 boundaries
      32'h8800_0000, 32'h8BFF_FFFC   // Slave 2 boundaries
    };
  }
endclass

// Special data patterns
class pattern_data_txn extends transaction;
  constraint data_patterns_c {
    Hwdata inside {
      32'h0000_0000,
      32'hFFFF_FFFF,
      32'hAAAA_AAAA,
      32'h5555_5555,
      32'hDEAD_BEEF,
      32'hCAFE_BABE
    };
  }
endclass
