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
        `uvm_do_with(req, { req.HTRANS == 2'b00; req.HSELAHB == 1'b0; req.HWRITE == 1'b0;
                            req.HADDR == 32'h8000_0000; req.HWDATA == 32'h0; })
        `uvm_do_with (req, { req.HTRANS == 2'b10; });

        repeat(TRANSFER) begin
            `uvm_do_with (req, { req.HTRANS == 2'b11; });
            `uvm_do_with (req, { req.HTRANS == 2'b00; req.HSELAHB == 1'b0; req.HWRITE == 1'b0;
                                 req.HADDR == 32'h8000_0000; req.HWDATA == 32'h0; });
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
            `uvm_do_with(req, {
                req.HTRANS  == 2'b10;
                req.HWRITE  == 1'b1;
                req.HSELAHB == 1'b1;
                req.HADDR inside {[32'h8400_0000:32'h87FF_FFFC]};
            })
        end
        `uvm_do_with(req, { req.HTRANS == 2'b00; req.HSELAHB == 1'b0; req.HWRITE == 1'b0;
                            req.HADDR == 32'h8000_0000; req.HWDATA == 32'h0; })
    endtask
endclass

class ahb_single_write_sequence extends uvm_sequence # (sequence_item);
    `uvm_object_utils(ahb_single_write_sequence)

    function new (string name = "ahb_single_write_sequence");
        super.new(name);
    endfunction

    virtual task body();
        req = sequence_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
            req.HRESETn == 1'b1;
            req.HSELAHB == 1'b1;
            req.HWRITE == 1'b1;
            req.HTRANS == 2'b10;
        });
        finish_item(req);

        req = sequence_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
            req.HRESETn == 1'b1;
            req.HSELAHB == 1'b0;
            req.HWRITE  == 1'b0;
            req.HTRANS  == 2'b00;
            req.HADDR   == 32'h8000_0000;
            req.HWDATA  == 32'h0;
        });
        finish_item(req);
    endtask
endclass

// AHB Burst Write Sequence class to generate specific burst write transactions.
class ahb_burst_write_sequence extends uvm_sequence # (sequence_item);
    `uvm_object_utils(ahb_burst_write_sequence)

    int unsigned N_TXN = 1000;
    
    function new (string name = "ahb_burst_write_sequence");
        super.new(name);
    endfunction

    virtual task body();
        bit [31:0] base_addr = 32'h8000_1000;
        int unsigned i;

        // first beat: NONSEQ
        req = sequence_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
            req.HRESETn == 1'b1;
            req.HWRITE  == 1'b1;
            req.HSELAHB == 1'b1;
            req.HTRANS  == 2'b10;
            req.HADDR   == base_addr;
            req.HWDATA  == 32'hA5A5_0000;
        });
        finish_item(req);

        // remaining beats: SEQ with incrementing address
        for (i = 1; i < N_TXN; i++) begin
            req = sequence_item::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {
                req.HRESETn == 1'b1;
                req.HWRITE  == 1'b1;
                req.HSELAHB == 1'b1;
                req.HTRANS  == 2'b11;
                // req.HADDR   == (base_addr + (i * 4));
                // req.HWDATA  == (32'hA5A5_0000 + i);
            });
            finish_item(req);
        end

        // end burst with IDLE
        req = sequence_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
            req.HRESETn == 1'b1;
            req.HSELAHB == 1'b0;
            req.HWRITE == 1'b1;
            req.HTRANS == 2'b00;
            req.HADDR  == 32'h8000_0000;
            req.HWDATA == 32'h0;
        });
        finish_item(req);
    endtask
endclass
