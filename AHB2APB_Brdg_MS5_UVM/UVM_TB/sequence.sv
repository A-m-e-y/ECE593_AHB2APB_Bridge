class ahb_sequence extends uvm_sequence # (sequence_item);
sequence_item req;
    `uvm_object_utils(ahb_sequence)

    function new (string name = "ahb_sequence");
        super.new(name);
    endfunction

    // Main sequence body to generate random AHB transactions.
    task body();
        repeat (TRANSFER) begin
            `uvm_do(req)
        end
    endtask
endclass

// AHB Random Sequence class that generates specific AHB transactions based on HTRANS values.
class ahb_random_sequence extends uvm_sequence # (sequence_item);
sequence_item req;
    `uvm_object_utils(ahb_random_sequence)

    // Constructor to initialize the sequence with a name.
    function new (string name = "ahb_random_sequence");
        super.new(name);
    endfunction

    virtual task body();
        // Generate sequence with HTRANS=00
        `uvm_do_with(req, { req.HTRANS == 2'b00; })

        // Generate sequence with HTRANS=10
        `uvm_do_with (req, { req.HTRANS == 2'b10; });

        // sequences with alternating HTRANS values.
        repeat(TRANSFER) begin
            `uvm_do_with (req, { req.HTRANS == 2'b11; });

            `uvm_do_with (req, { req.HTRANS == 2'b00; });
            
        end
    endtask
endclass

// ─────────────────────────────────────────────────────────────────────────────
// AHB Back-to-Back Sequence (MS3-style)
//
// Sends N_TXN independent NONSEQ WRITE transactions.  The driver (MS3-style
// 3-phase handshake) takes care of the data phase and the trailing IDLE after
// each transaction, so no manual IDLE or SEQ items are needed here.
//
// Expected scoreboard: N_TXN pairs checked, all matched.
// ─────────────────────────────────────────────────────────────────────────────
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