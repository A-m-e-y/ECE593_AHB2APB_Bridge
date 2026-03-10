import uvm_pkg::*;
`include "uvm_macros.svh"

class sequence_item extends uvm_sequence_item;

    `uvm_object_utils_begin(sequence_item)
        `uvm_field_int(HRESETn,  UVM_DEFAULT)
        `uvm_field_int(HADDR,    UVM_HEX)
        `uvm_field_int(HTRANS,   UVM_DEFAULT)
        `uvm_field_int(HWRITE,   UVM_DEFAULT)
        `uvm_field_int(HWDATA,   UVM_HEX)
        `uvm_field_int(HSELAHB,  UVM_DEFAULT)
        `uvm_field_int(HREADY,   UVM_DEFAULT)
    `uvm_object_utils_end

    rand bit                   HRESETn;
    rand bit [31:0]            HADDR;
    rand bit [1:0]             HTRANS;
    rand bit                   HWRITE;
    rand bit [31:0]            HWDATA;
    rand bit                   HSELAHB;

    // not randomized - driven by DUT
    bit [31:0]                 HRDATA;
    bit                        HREADY;
    bit [1:0]                  HRESP;

    static int ahb_no_of_transaction;

    function new(string name = "sequence_item");
        super.new(name);
    endfunction

    // keep reset mostly deasserted, address in valid APB range, bridge usually selected
    constraint LOW_RESET     {HRESETn dist {1:=9, 0:=1};}
    constraint VALID_ADDRESS {HADDR inside {[32'h8000_0000:32'h8BFF_FFFF]};}
    constraint SELECT_BRIDGE {HSELAHB dist {1:=99, 0:=1};}

    function void post_randomize();
        ahb_no_of_transaction++;
        `uvm_info("AHB_SEQUENCE_ITEM", $sformatf("Transaction [%0d]: %s",
            ahb_no_of_transaction, this.sprint()), UVM_MEDIUM)
    endfunction

endclass
