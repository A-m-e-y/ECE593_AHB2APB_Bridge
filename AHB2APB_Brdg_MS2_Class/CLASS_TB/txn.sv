
class transaction;

  typedef enum {AHB_READ, AHB_WRITE} trans_type_e;
  trans_type_e trans_type;

  // AHB Input signals (driven by driver)
  randc bit [31:0] Haddr;
  randc bit [31:0] Hwdata;
  randc bit Hwrite;
  randc bit Hreadyin;
  randc bit [1:0] Htrans;
  randc bit [2:0] Hsize;
  randc bit [2:0] Hburst;
  
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
