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
// AHB Back-to-Back Sequential Burst Sequence
//
// Modelled on the MS3 generator's approach: send a proper AHB burst with no
// IDLE gaps between transfers, so every transaction makes it through the
// bridge's pipelined WRITEP→WENABLEP→WRITEP... path.
//
// Structure on the AHB bus:
//   IDLE  →  NONSEQ (WRITE)  →  SEQ×N_SEQ (WRITE)  →  IDLE (flush)
//
// The scoreboard expects (1 + N_SEQ) matched pairs.  Default N_SEQ=4 gives
// 5 total AHB→APB translations to check.
// ─────────────────────────────────────────────────────────────────────────────
class ahb_b2b_seq_sequence extends uvm_sequence #(sequence_item);
    sequence_item req;
    `uvm_object_utils(ahb_b2b_seq_sequence)

    // Number of SEQ transactions after the opening NONSEQ.
    // Total scoreboard pairs = 1 + N_SEQ.
    int unsigned N_SEQ = 4;

    function new(string name = "ahb_b2b_seq_sequence");
        super.new(name);
    endfunction

    virtual task body();
        // Initial IDLE — cleans up any leftover bus state from reset
        `uvm_do_with(req, { req.HTRANS == 2'b00; req.HWRITE == 1'b1; })

        // Opening NONSEQ WRITE — marks the start of the burst
        `uvm_do_with(req, { req.HTRANS == 2'b10; req.HWRITE == 1'b1; })

        // Back-to-back SEQ WRITEs — no IDLE between them (true pipelined burst)
        repeat (N_SEQ) begin
            `uvm_do_with(req, { req.HTRANS == 2'b11; req.HWRITE == 1'b1; })
        end

        // Trailing IDLE WRITE — flushes the last data word through the AHB
        // data pipeline (Hwdata_t → HWDATA bus) so the bridge captures it.
        `uvm_do_with(req, { req.HTRANS == 2'b00; req.HWRITE == 1'b1; })
    endtask
endclass