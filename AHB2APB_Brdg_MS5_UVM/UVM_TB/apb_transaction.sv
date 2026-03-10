// APB transaction item - one APB access (PENABLE=1, PSELX!=0)
class apb_transaction extends uvm_sequence_item;
    `uvm_object_utils_begin(apb_transaction)
        `uvm_field_int(PWRITE,  UVM_DEFAULT)
        `uvm_field_int(PSELX,   UVM_DEFAULT)
        `uvm_field_int(PADDR,   UVM_HEX)
        `uvm_field_int(PWDATA,  UVM_HEX)
        `uvm_field_int(PRDATA,  UVM_HEX)
    `uvm_object_utils_end

    bit        PWRITE;
    bit [2:0]  PSELX;
    bit [31:0] PADDR;
    bit [31:0] PWDATA;
    bit [31:0] PRDATA;

    function new(string name = "apb_transaction");
        super.new(name);
    endfunction
endclass
