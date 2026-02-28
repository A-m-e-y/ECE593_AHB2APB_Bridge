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

    // Randomizable transaction fields
    rand bit                   HRESETn;    // Reset signal
    rand bit [31:0]            HADDR;      // Address
    rand bit [1:0]             HTRANS;     // Transaction type
    rand bit                   HWRITE;     // Write enable flag
    rand bit [31:0]            HWDATA;     // Data to be written
    rand bit                   HSELAHB;    // AHB bridge select signal

    // Non-randomizable fields
    bit [31:0]                 HRDATA;     // Data read
    bit                        HREADY;     // Ready signal
    bit                        HRESP;      // Response signal

    // Tracks number of transactions
    static int ahb_no_of_transaction;

    // Constructor: Initializes the uvm_sequence_item
    function new(string name = "sequence_item");
        super.new(name);
    endfunction

    // Constraints to guide randomization
    constraint LOW_RESET        {HRESETn dist   {1:=9, 0:=1};}
    constraint VALID_ADDRESS    {HADDR   inside {[32'h0:32'h7ff]}; }
    constraint SELECT_BRIDGE    {HSELAHB dist   {1:=99, 0:=1};}

    // Function called after each randomization to update transaction count and print details
    function void post_randomize();
        ahb_no_of_transaction++;
        `uvm_info("AHB_SEQUENCE_ITEM", $sformatf("Transaction [%0d]: %s", ahb_no_of_transaction, this.sprint()), UVM_MEDIUM)
    endfunction

endclass