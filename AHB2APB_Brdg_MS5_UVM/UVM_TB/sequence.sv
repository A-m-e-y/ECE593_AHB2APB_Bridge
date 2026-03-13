class ahb_sequence extends uvm_sequence # (sequence_item);
sequence_item req;
    `uvm_object_utils(ahb_sequence)

    int unsigned N_TXN = 2;

    function new (string name = "ahb_sequence");
        super.new(name);
    endfunction

    task body();
        repeat (N_TXN) begin
            `uvm_do(req)
        end
    endtask
endclass

// sends IDLE -> NONSEQ -> (SEQ+IDLE) x N_TXN
class ahb_random_sequence extends uvm_sequence # (sequence_item);
sequence_item req;
    `uvm_object_utils(ahb_random_sequence)

    int unsigned N_TXN = 100;

    function new (string name = "ahb_random_sequence");
        super.new(name);
    endfunction

    virtual task body();
        `uvm_do_with(req, { req.HTRANS == 2'b00; req.HSELAHB == 1'b0; req.HWRITE == 1'b0;
                            req.HADDR == 32'h8000_0000; req.HWDATA == 32'h0; })
        `uvm_do_with (req, { req.HTRANS == 2'b10; });

        repeat(N_TXN) begin
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

class ahb_single_read_sequence extends uvm_sequence # (sequence_item);
    `uvm_object_utils(ahb_single_read_sequence)

    function new (string name = "ahb_single_read_sequence");
        super.new(name);
    endfunction

    virtual task body();
        bit [31:0] exp_read_data;
        exp_read_data = 32'h1BAD_B002;

        req = sequence_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
            req.HRESETn == 1'b1;
            req.HSELAHB == 1'b1;
            req.HWRITE  == 1'b0;
            req.HTRANS  == 2'b10;
            req.HADDR   == 32'h8400_0100;
        });
        req.HWDATA = 32'h0;
        req.HRDATA = exp_read_data;
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
        req.HRDATA = 32'h0;
        finish_item(req);
    endtask
endclass

class ahb_burst_read_sequence extends uvm_sequence # (sequence_item);
    `uvm_object_utils(ahb_burst_read_sequence)

    int unsigned N_TXN = 1000;

    function new (string name = "ahb_burst_read_sequence");
        super.new(name);
    endfunction

    virtual task body();
        int unsigned i;

        req = sequence_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
            req.HRESETn == 1'b1;
            req.HWRITE  == 1'b0;
            req.HSELAHB == 1'b1;
            req.HTRANS  == 2'b10;
        });
        req.HWDATA = 32'h0;
        req.HRDATA = $urandom;
        finish_item(req);

        for (i = 1; i < N_TXN; i++) begin
            req = sequence_item::type_id::create($sformatf("req_%0d", i));
            start_item(req);
            assert(req.randomize() with {
                req.HRESETn == 1'b1;
                req.HWRITE  == 1'b0;
                req.HSELAHB == 1'b1;
                req.HTRANS  == 2'b11;
            });
            req.HWDATA = 32'h0;
            req.HRDATA = $urandom;
            finish_item(req);
        end

        req = sequence_item::type_id::create("req_idle");
        start_item(req);
        assert(req.randomize() with {
            req.HRESETn == 1'b1;
            req.HSELAHB == 1'b0;
            req.HWRITE  == 1'b0;
            req.HTRANS  == 2'b00;
            req.HADDR   == 32'h8000_0000;
            req.HWDATA  == 32'h0;
        });
        req.HRDATA = 32'h0;
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
        int unsigned i;

        // first beat: NONSEQ
        req = sequence_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
            req.HRESETn == 1'b1;
            req.HWRITE  == 1'b1;
            req.HSELAHB == 1'b1;
            req.HTRANS  == 2'b10;
        });
        finish_item(req);

        // remaining beats: SEQ
        for (i = 1; i < N_TXN; i++) begin
            req = sequence_item::type_id::create("req");
            start_item(req);
            assert(req.randomize() with {
                req.HRESETn == 1'b1;
                req.HWRITE  == 1'b1;
                req.HSELAHB == 1'b1;
                req.HTRANS  == 2'b11;
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
