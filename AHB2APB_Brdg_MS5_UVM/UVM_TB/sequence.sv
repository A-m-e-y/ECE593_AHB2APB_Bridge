
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

// targeted sequence for cg_data_boundary coverage closure
class ahb_cov_boundary_sequence extends uvm_sequence # (sequence_item);
    `uvm_object_utils(ahb_cov_boundary_sequence)

    function new (string name = "ahb_cov_boundary_sequence");
        super.new(name);
    endfunction

    task automatic send_tx(
        bit        hwrite,
        bit [1:0]  htrans,
        bit [31:0] haddr,
        bit [31:0] hwdata,
        bit [31:0] hrdata,
        bit        hsel   = 1'b1,
        bit        hreset = 1'b1
    );
        req = sequence_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
            req.HRESETn == hreset;
            req.HSELAHB == hsel;
            req.HWRITE  == hwrite;
            req.HTRANS  == htrans;
            req.HADDR   == haddr;
        });
        req.HWDATA = hwrite ? hwdata : 32'h0;
        req.HRDATA = hwrite ? 32'h0   : hrdata;
        finish_item(req);
    endtask

    task automatic send_idle(bit hreset = 1'b1);
        send_tx(1'b0, 2'b00, 32'h8000_0000, 32'h0, 32'h0, 1'b0, hreset);
    endtask

    virtual task body();
        // hold reset low across multiple HCLK/PCLK edges for reset branch coverage
        repeat (4) send_idle(1'b0);
        repeat (2) send_idle(1'b1);

        // write data bins: zero, ones, a5_prefix, other
        send_tx(1'b1, 2'b10, 32'h8000_0000, 32'h0000_0000, 32'h0);
        send_tx(1'b1, 2'b10, 32'h83FF_FFFC, 32'hFFFF_FFFF, 32'h0);
        send_tx(1'b1, 2'b10, 32'h8400_0000, 32'hA5A5_1234, 32'h0);
        send_tx(1'b1, 2'b10, 32'h87FF_FFFC, 32'h1357_9BDF, 32'h0);

        // read data bins: zero, ones, d00d_data, other
        send_tx(1'b0, 2'b10, 32'h8800_0000, 32'h0, 32'h0000_0000);
        send_tx(1'b0, 2'b10, 32'h8BFF_FFFC, 32'h0, 32'hFFFF_FFFF);
        send_tx(1'b0, 2'b10, 32'h8000_0000, 32'h0, 32'hD00D_00AA);
        send_tx(1'b0, 2'b10, 32'h8400_0000, 32'h0, 32'h2468_ACE0);

        send_idle(1'b1);
    endtask
endclass

// mixed traffic to improve code coverage (FSM/branch/toggle) without touching DUT
class ahb_cov_code_stress_sequence extends uvm_sequence # (sequence_item);
    `uvm_object_utils(ahb_cov_code_stress_sequence)

    int unsigned N_TXN = 1200;

    function new (string name = "ahb_cov_code_stress_sequence");
        super.new(name);
    endfunction

    function automatic bit [31:0] pick_addr(int unsigned idx);
        bit [31:0] base;
        case (idx % 3)
            0: base = 32'h8000_0000;
            1: base = 32'h8400_0000;
            default: base = 32'h8800_0000;
        endcase
        return (base + ({$urandom} & 32'h03FF_FFFC));
    endfunction

    function automatic bit [31:0] pick_wdata(int unsigned idx);
        case (idx % 5)
            0: return 32'h0000_0000;
            1: return 32'hFFFF_FFFF;
            2: return (32'hA5A5_0000 | (idx & 32'h0000_FFFF));
            3: return (32'h5555_AAAA ^ idx);
            default: return $urandom;
        endcase
    endfunction

    function automatic bit [31:0] pick_rdata(int unsigned idx);
        case (idx % 5)
            0: return 32'h0000_0000;
            1: return 32'hFFFF_FFFF;
            2: return (32'hD00D_0000 | (idx & 32'h0000_FFFF));
            3: return (32'hC0DE_0000 | (idx & 32'h0000_FFFF));
            default: return $urandom;
        endcase
    endfunction

    task automatic send_tx(
        bit        hwrite,
        bit [1:0]  htrans,
        bit [31:0] haddr,
        bit [31:0] hwdata,
        bit [31:0] hrdata,
        bit        hsel   = 1'b1,
        bit        hreset = 1'b1
    );
        req = sequence_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with {
            req.HRESETn == hreset;
            req.HSELAHB == hsel;
            req.HWRITE  == hwrite;
            req.HTRANS  == htrans;
            req.HADDR   == haddr;
        });
        req.HWDATA = hwrite ? hwdata : 32'h0;
        req.HRDATA = hwrite ? 32'h0   : hrdata;
        finish_item(req);
    endtask

    task automatic send_idle(bit hreset = 1'b1);
        send_tx(1'b0, 2'b00, 32'h8000_0000, 32'h0, 32'h0, 1'b0, hreset);
    endtask

    virtual task body();
        int unsigned i;
        bit          is_write;
        bit [31:0]   addr;
        bit [1:0]    htrans;

        // keep reset asserted long enough to hit reset logic in both clock domains
        repeat (4) send_idle(1'b0);
        repeat (2) send_idle(1'b1);

        // force write->idle->write pattern to encourage ST_WRITE -> ST_WENABLEP path
        send_tx(1'b1, 2'b10, 32'h8000_0010, 32'hAAAA_0001, 32'h0);
        send_idle(1'b1);
        send_tx(1'b1, 2'b10, 32'h8000_0020, 32'hAAAA_0002, 32'h0);

        for (i = 0; i < N_TXN; i++) begin
            is_write = ((i % 4) != 0);
            addr     = pick_addr(i);
            htrans   = ((i == 0) || (i % 13 == 0)) ? 2'b10 : 2'b11;

            // occasionally inject BUSY to hit non-valid transfer handling
            if (i % 29 == 28)
                send_tx(1'b0, 2'b01, addr, 32'h0, 32'h0, 1'b1, 1'b1);

            send_tx(
                is_write,
                htrans,
                addr,
                pick_wdata(i),
                pick_rdata(i),
                1'b1,
                1'b1
            );

            // periodic IDLE forces valid deassert and exercises extra FSM transitions
            if (i % 17 == 16)
                send_idle(1'b1);

            // mid-run reset pulse improves reset branch observability in RTL modules
            if (i == (N_TXN/2)) begin
                repeat (4) send_idle(1'b0);
                repeat (2) send_idle(1'b1);
            end
        end

        send_idle(1'b1);
    endtask
endclass
