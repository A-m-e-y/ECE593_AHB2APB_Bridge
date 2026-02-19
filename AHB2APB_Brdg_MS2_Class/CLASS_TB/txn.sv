// Base transaction class with randomization
class transaction;

  typedef enum {AHB_READ, AHB_WRITE} trans_type_e;
  trans_type_e trans_type;

  // AHB signals - inputs driven by driver
  rand bit [31:0] Haddr;
  rand bit [31:0] Hwdata;
  rand bit Hwrite;
  rand bit [1:0] Htrans;
  rand bit [2:0] Hsize;
  rand bit [2:0] Hburst;
  bit Hreadyin;
  
  // outputs from DUT
  bit [31:0] Hrdata;
  bit [1:0] Hresp;
  bit Hreadyout;
  
  // APB outputs
  bit [31:0] Paddr;
  bit [31:0] Pwdata;
  bit Pwrite;
  bit [2:0] Pselx;
  bit Penable;
  bit [31:0] Prdata;

  // address range for APB slaves
  constraint valid_addr_c {
    Haddr inside {[32'h8000_0000 : 32'h8BFF_FFFF]};
  }
  
  constraint valid_size_c {
    Hsize inside {3'b000, 3'b001, 3'b010};  //byte, halfword, word
  }
  
  constraint valid_burst_c {
    Hburst inside {3'b000, 3'b001, 3'b010, 3'b011};
  }
  
  // IDLE, NONSEQ, SEQ only
  constraint valid_trans_c {
    Htrans inside {2'b00, 2'b10, 2'b11};
  }
  
  constraint rw_dist_c {
    Hwrite dist {0 := 50, 1 := 50};
  }
  
  // mostly nonseq transactions
  constraint trans_dist_c {
    Htrans dist {2'b10 := 80, 2'b11 := 15, 2'b00 := 5};
  }
  
  // alignment based on size
  constraint addr_align_c {
    if (Hsize == 3'b000) Haddr[1:0] == 2'b00;
    if (Hsize == 3'b001) Haddr[1:0] inside {2'b00, 2'b10};
    if (Hsize == 3'b010) Haddr[1:0] == 2'b00;
  }

  function new();
    Hreadyin = 1;
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


// extended classes for specific test scenarios

class write_txn extends transaction;
  constraint write_only_c {
    Hwrite == 1;
  }
endclass

class read_txn extends transaction;
  constraint read_only_c {
    Hwrite == 0;
  }
endclass

// slave-specific addresses
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

