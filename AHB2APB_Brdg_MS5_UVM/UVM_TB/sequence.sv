class ahb_sequence extends uvm_sequence # (sequence_item);
sequence_item req;
    `uvm_object_utils(ahb_sequence)

    function new (string name = "ahb_sequence");
        super.new(name);
    endfunction

    task body();
        repeat (TRANSFER) begin
            `uvm_do(req)
        end
    endtask
endclass

// sends IDLE -> NONSEQ -> (SEQ+IDLE) x TRANSFER
class ahb_random_sequence extends uvm_sequence # (sequence_item);
sequence_item req;
    `uvm_object_utils(ahb_random_sequence)

    function new (string name = "ahb_random_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_do_with(req, { req.HTRANS == 2'b00; })
        `uvm_do_with (req, { req.HTRANS == 2'b10; });

        repeat(TRANSFER) begin
            `uvm_do_with (req, { req.HTRANS == 2'b11; });
            `uvm_do_with (req, { req.HTRANS == 2'b00; });
        end
    endtask
endclass

// fires N_TXN back-to-back NONSEQ writes - driver handles the IDLE gap
class ahb_b2b_seq_sequence extends uvm_sequence #(sequence_item);
    sequence_item req;
    `uvm_object_utils(ahb_b2b_seq_sequence)

    int unsigned N_TXN = 100;

    function new(string name = "ahb_b2b_seq_sequence");
        super.new(name);
    endfunction

    virtual task body();
        repeat (N_TXN) begin
            `uvm_do_with(req, { req.HTRANS == 2'b10; req.HWRITE == 1'b1; })
        end
    endtask
endclass
