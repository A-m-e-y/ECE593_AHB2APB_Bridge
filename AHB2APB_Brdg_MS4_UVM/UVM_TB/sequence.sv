class ahb_sequence extends uvm_sequence # (ahb_sequence_item);
    `uvm_object_utils(ahb_sequence)

    function new (string name = "ahb_sequence");
        super.new(name);
    endfunction

    // Main sequence body to generate random AHB transactions.
    task body();
        /*
        repeat(TRANSFER)  begin
            req = ahb_sequence_item::type_id::create("req");
            start_item(req);
            if (!req.randomize()) `uvm_error(get_type_name(), "Randomization failed")
            assert(req.randomize());
            finish_item(req);
        end */
        repeat (TRANSFER) begin
            `uvm_do(req)
        end
    endtask
endclass

// AHB Random Sequence class that generates specific AHB transactions based on HTRANS values.
class ahb_random_sequence extends uvm_sequence # (ahb_sequence_item);
    `uvm_object_utils(ahb_random_sequence)

    // Constructor to initialize the sequence with a name.
    function new (string name = "ahb_random_sequence");
        super.new(name);
    endfunction

    // Main sequence body to generate specific AHB transactions.
    virtual task body();
        // Generate sequence with HTRANS=00
        `uvm_do_with(req, { req.HTRANS == 2'b00; })
        /*
        req = ahb_sequence_item::type_id::create("req");
        start_item(req);
        assert(req.randomize() with { req.HTRANS == 2'b00; });
        finish_item(req); */

        // Generate sequence with HTRANS=10
        `uvm_do_with (req, { req.HTRANS == 2'b10; });

        // Repeatedly generate sequences with alternating HTRANS values.
        repeat(TRANSFER) begin
            `uvm_do_with (req, { req.HTRANS == 2'b11; });

            `uvm_do_with (req, { req.HTRANS == 2'b00; });
            /*
            req = ahb_sequence_item::type_id::create("req");
            start_item(req);
            assert(req.randomize() with { req.HTRANS == 2'b00; });
            finish_item(req);

            */
        end
    endtask
endclass