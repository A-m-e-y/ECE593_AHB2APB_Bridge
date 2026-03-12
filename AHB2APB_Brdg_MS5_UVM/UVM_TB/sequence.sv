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

    int unsigned N_TXN = 2;

    function new(string name = "ahb_b2b_seq_sequence");
        super.new(name);
    endfunction

    virtual task body();
        repeat (N_TXN) begin
            `uvm_do_with(req, { req.HTRANS == 2'b10; req.HWRITE == 1'b1; })
        end
    endtask
endclass

class ahb_single_write_sequence extends uvm_sequence # (sequence_item);
    `uvm_object_utils(ahb_single_write_sequence)

    function new (string name = "ahb_single_write_sequence");
        super.new(name);
    endfunction

    virtual task body();
        req = sequence_item::type_id::create("req");
	//1st wr seq
        start_item(req);
        assert(req.randomize() with {
            req.HRESETn == 1'b0;
            req.HWRITE == 1'b1;
            req.HTRANS == 2'b00;
        });
        finish_item(req);

	//2nd wr seq
        req = sequence_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
            req.HRESETn == 1'b1;
            req.HWRITE == 1'b1;
            req.HSELAHB == 1'b1;
            req.HTRANS == 2'b10;
        });
        finish_item(req);

	//3rd wr seq
        req = sequence_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
            req.HRESETn == 1'b1;
            req.HSELAHB == 1'b1;
            req.HWRITE == 1'b1;
            req.HTRANS == 2'b00;
        });
        finish_item(req);
    endtask
endclass

// AHB Burst Write Sequence class to generate specific burst write transactions.
class ahb_burst_write_sequence extends uvm_sequence # (sequence_item);
    `uvm_object_utils(ahb_burst_write_sequence)

    function new (string name = "ahb_burst_write_sequence");
        super.new(name);
    endfunction

    virtual task body();
        req = sequence_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
            req.HRESETn == 1'b0;
            req.HWRITE == 1'b1;
            req.HTRANS == 2'b00;
        });
        finish_item(req);

        // Generate another burst write sequence with different constraints.
        req = sequence_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
            req.HRESETn == 1'b1;
            req.HWRITE == 1'b1;
            req.HSELAHB == 1'b1;
            req.HTRANS == 2'b10;
        });
        finish_item(req);

        repeat(N_TX) begin
            req = sequence_item::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {
                req.HRESETn == 1'b1;
                req.HWRITE == 1'b1;
                req.HSELAHB == 1'b1;
                req.HTRANS == 2'b11;
            });
            finish_item(req);
        end

        // final burst write sequence
        req = sequence_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
            req.HRESETn == 1'b1;
            req.HSELAHB == 1'b1;
            req.HWRITE == 1'b1;
            req.HTRANS == 2'b00;
        });
        finish_item(req);
    endtask
endclass