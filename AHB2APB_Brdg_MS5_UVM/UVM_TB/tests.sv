class ahb_apb_base_test extends uvm_test;
    `uvm_component_utils (ahb_apb_base_test)
     bit agent_enabled;
     bit scoreboard_enabled;
     int log_fd;
    ahb_apb_env env;

    function new(string name = "ahb_apb_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info("BASE_TEST","Inside build_phase",UVM_DEBUG)
       
        agent_enabled  = 1;
        //scoreboard_enabled = 1;

        env = ahb_apb_env::type_id::create("env", this);

// dump everything to a log file too
    log_fd = $fopen("uvm_log.txt", "w");

    if (log_fd == 0)
      `uvm_fatal("LOGFILE", "Failed to open log file!")

    uvm_root::get().set_report_default_file(log_fd);
    endfunction

    // char_art_row: maps a char + row index (0-4) to a 5-char wide ASCII block glyph
    // supports A-Z (lowercased), 0-9, space, hyphen, underscore
    function string char_art_row(byte c, int unsigned row);
        byte       uc;
        logic [10:0] key;
        uc  = (c >= 97 && c <= 122) ? c - 32 : c;
        key = {uc, row[2:0]};
        case (key)
            // space
            {8'd32,3'd0},{8'd32,3'd1},{8'd32,3'd2},
            {8'd32,3'd3},{8'd32,3'd4}: return "     ";
            // hyphen
            {8'd45,3'd0},{8'd45,3'd1}:              return "     ";
            {8'd45,3'd2}:                            return "#### ";
            {8'd45,3'd3},{8'd45,3'd4}:              return "     ";
            // 0-9
            {8'd48,3'd0}: return " ### "; {8'd48,3'd1}: return "#   #";
            {8'd48,3'd2}: return "#   #"; {8'd48,3'd3}: return "#   #";
            {8'd48,3'd4}: return " ### ";

            {8'd49,3'd0}: return "  #  "; {8'd49,3'd1}: return " ##  ";
            {8'd49,3'd2}: return "  #  "; {8'd49,3'd3}: return "  #  ";
            {8'd49,3'd4}: return " ### ";

            {8'd50,3'd0}: return " ### "; {8'd50,3'd1}: return "    #";
            {8'd50,3'd2}: return " ### "; {8'd50,3'd3}: return "#    ";
            {8'd50,3'd4}: return "#####";

            {8'd51,3'd0}: return "#### "; {8'd51,3'd1}: return "    #";
            {8'd51,3'd2}: return " ### "; {8'd51,3'd3}: return "    #";
            {8'd51,3'd4}: return "#### ";

            {8'd52,3'd0}: return "#   #"; {8'd52,3'd1}: return "#   #";
            {8'd52,3'd2}: return "#####"; {8'd52,3'd3}: return "    #";
            {8'd52,3'd4}: return "    #";

            {8'd53,3'd0}: return "#####"; {8'd53,3'd1}: return "#    ";
            {8'd53,3'd2}: return "#### "; {8'd53,3'd3}: return "    #";
            {8'd53,3'd4}: return "#### ";

            {8'd54,3'd0}: return " ### "; {8'd54,3'd1}: return "#    ";
            {8'd54,3'd2}: return "#### "; {8'd54,3'd3}: return "#   #";
            {8'd54,3'd4}: return " ### ";

            {8'd55,3'd0}: return "#####"; {8'd55,3'd1}: return "    #";
            {8'd55,3'd2}: return "   # "; {8'd55,3'd3}: return "  #  ";
            {8'd55,3'd4}: return "  #  ";

            {8'd56,3'd0}: return " ### "; {8'd56,3'd1}: return "#   #";
            {8'd56,3'd2}: return " ### "; {8'd56,3'd3}: return "#   #";
            {8'd56,3'd4}: return " ### ";

            {8'd57,3'd0}: return " ### "; {8'd57,3'd1}: return "#   #";
            {8'd57,3'd2}: return " ####"; {8'd57,3'd3}: return "    #";
            {8'd57,3'd4}: return " ### ";
            // A-Z
            {8'd65,3'd0}: return "  #  "; {8'd65,3'd1}: return " # # ";
            {8'd65,3'd2}: return "#   #"; {8'd65,3'd3}: return "#####";
            {8'd65,3'd4}: return "#   #";

            {8'd66,3'd0}: return "#### "; {8'd66,3'd1}: return "#   #";
            {8'd66,3'd2}: return "#### "; {8'd66,3'd3}: return "#   #";
            {8'd66,3'd4}: return "#### ";

            {8'd67,3'd0}: return " ####"; {8'd67,3'd1}: return "#    ";
            {8'd67,3'd2}: return "#    "; {8'd67,3'd3}: return "#    ";
            {8'd67,3'd4}: return " ####";

            {8'd68,3'd0}: return "#### "; {8'd68,3'd1}: return "#   #";
            {8'd68,3'd2}: return "#   #"; {8'd68,3'd3}: return "#   #";
            {8'd68,3'd4}: return "#### ";

            {8'd69,3'd0}: return "#####"; {8'd69,3'd1}: return "#    ";
            {8'd69,3'd2}: return "###  "; {8'd69,3'd3}: return "#    ";
            {8'd69,3'd4}: return "#####";

            {8'd70,3'd0}: return "#####"; {8'd70,3'd1}: return "#    ";
            {8'd70,3'd2}: return "###  "; {8'd70,3'd3}: return "#    ";
            {8'd70,3'd4}: return "#    ";

            {8'd71,3'd0}: return " ####"; {8'd71,3'd1}: return "#    ";
            {8'd71,3'd2}: return "# ###"; {8'd71,3'd3}: return "#   #";
            {8'd71,3'd4}: return " ####";

            {8'd72,3'd0}: return "#   #"; {8'd72,3'd1}: return "#   #";
            {8'd72,3'd2}: return "#####"; {8'd72,3'd3}: return "#   #";
            {8'd72,3'd4}: return "#   #";

            {8'd73,3'd0}: return "#####"; {8'd73,3'd1}: return "  #  ";
            {8'd73,3'd2}: return "  #  "; {8'd73,3'd3}: return "  #  ";
            {8'd73,3'd4}: return "#####";

            {8'd74,3'd0}: return "  ###"; {8'd74,3'd1}: return "   # ";
            {8'd74,3'd2}: return "   # "; {8'd74,3'd3}: return "#  # ";
            {8'd74,3'd4}: return " ##  ";

            {8'd75,3'd0}: return "#   #"; {8'd75,3'd1}: return "#  # ";
            {8'd75,3'd2}: return "###  "; {8'd75,3'd3}: return "#  # ";
            {8'd75,3'd4}: return "#   #";

            {8'd76,3'd0}: return "#    "; {8'd76,3'd1}: return "#    ";
            {8'd76,3'd2}: return "#    "; {8'd76,3'd3}: return "#    ";
            {8'd76,3'd4}: return "#####";

            {8'd77,3'd0}: return "#   #"; {8'd77,3'd1}: return "## ##";
            {8'd77,3'd2}: return "# # #"; {8'd77,3'd3}: return "#   #";
            {8'd77,3'd4}: return "#   #";

            {8'd78,3'd0}: return "#   #"; {8'd78,3'd1}: return "##  #";
            {8'd78,3'd2}: return "# # #"; {8'd78,3'd3}: return "#  ##";
            {8'd78,3'd4}: return "#   #";

            {8'd79,3'd0}: return " ### "; {8'd79,3'd1}: return "#   #";
            {8'd79,3'd2}: return "#   #"; {8'd79,3'd3}: return "#   #";
            {8'd79,3'd4}: return " ### ";

            {8'd80,3'd0}: return "#### "; {8'd80,3'd1}: return "#   #";
            {8'd80,3'd2}: return "#### "; {8'd80,3'd3}: return "#    ";
            {8'd80,3'd4}: return "#    ";

            {8'd81,3'd0}: return " ### "; {8'd81,3'd1}: return "#   #";
            {8'd81,3'd2}: return "# # #"; {8'd81,3'd3}: return "#  ##";
            {8'd81,3'd4}: return " ####";

            {8'd82,3'd0}: return "#### "; {8'd82,3'd1}: return "#   #";
            {8'd82,3'd2}: return "#### "; {8'd82,3'd3}: return "#  # ";
            {8'd82,3'd4}: return "#   #";

            {8'd83,3'd0}: return " ####"; {8'd83,3'd1}: return "#    ";
            {8'd83,3'd2}: return " ### "; {8'd83,3'd3}: return "    #";
            {8'd83,3'd4}: return "#### ";

            {8'd84,3'd0}: return "#####"; {8'd84,3'd1}: return "  #  ";
            {8'd84,3'd2}: return "  #  "; {8'd84,3'd3}: return "  #  ";
            {8'd84,3'd4}: return "  #  ";

            {8'd85,3'd0}: return "#   #"; {8'd85,3'd1}: return "#   #";
            {8'd85,3'd2}: return "#   #"; {8'd85,3'd3}: return "#   #";
            {8'd85,3'd4}: return " ### ";

            {8'd86,3'd0}: return "#   #"; {8'd86,3'd1}: return "#   #";
            {8'd86,3'd2}: return "#   #"; {8'd86,3'd3}: return " # # ";
            {8'd86,3'd4}: return "  #  ";

            {8'd87,3'd0}: return "#   #"; {8'd87,3'd1}: return "#   #";
            {8'd87,3'd2}: return "# # #"; {8'd87,3'd3}: return "## ##";
            {8'd87,3'd4}: return "#   #";

            {8'd88,3'd0}: return "#   #"; {8'd88,3'd1}: return " # # ";
            {8'd88,3'd2}: return "  #  "; {8'd88,3'd3}: return " # # ";
            {8'd88,3'd4}: return "#   #";

            {8'd89,3'd0}: return "#   #"; {8'd89,3'd1}: return " # # ";
            {8'd89,3'd2}: return "  #  "; {8'd89,3'd3}: return "  #  ";
            {8'd89,3'd4}: return "  #  ";

            {8'd90,3'd0}: return "#####"; {8'd90,3'd1}: return "   # ";
            {8'd90,3'd2}: return " ### "; {8'd90,3'd3}: return "#    ";
            {8'd90,3'd4}: return "#####";
            // underscore
            {8'd95,3'd0},{8'd95,3'd1},{8'd95,3'd2},
            {8'd95,3'd3}: return "     ";
            {8'd95,3'd4}: return "#####";

            default: return "???? ";
        endcase
    endfunction

    // builds banner string row by row and emits via uvm_info
    function void print_ascii_art(string msg);
        string banner, line;
        banner = "\n";
        for (int row = 0; row < 5; row++) begin
            line = "  ";
            for (int i = 0; i < msg.len(); i++)
                line = {line, char_art_row(msg[i], row), " "};
            banner = {banner, line, "\n"};
        end
        `uvm_info("ASCII", banner, UVM_NONE)
    endfunction

    function void start_of_simulation_phase(uvm_phase phase);
        super.start_of_simulation_phase(phase);
        print_ascii_art("ECE - 593");
    endfunction

    function void final_phase(uvm_phase phase);
    super.final_phase(phase);
    if (log_fd)
        $fclose(log_fd);
    endfunction
endclass

//-----------------------------------------------------------------------------------------------------------
class ahb_apb_single_write_test extends ahb_apb_base_test;
    `uvm_component_utils(ahb_apb_single_write_test)

    ahb_single_write_sequence ahb_seq_h;

    function new(string name = "ahb_apb_single_write_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ahb_seq_h = ahb_single_write_sequence::type_id::create("ahb_seq_h");
    endfunction

    // Run Phase: Start the single write sequences on the respective sequencers
    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("SEQ", "sequence started: ahb_single_write_sequence", UVM_MEDIUM)
        ahb_seq_h.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_single_write_sequence", UVM_MEDIUM)
        // wait a bit so APB side (after CDC) and slave model can flush
        phase.phase_done.set_drain_time(this, 300);
        phase.drop_objection(this);
    endtask
endclass

//  this test focuses on the burst write test sequence 
class ahb_apb_burst_write_test extends ahb_apb_base_test;
    `uvm_component_utils(ahb_apb_burst_write_test)

    ahb_burst_write_sequence ahb_seq_h;

    function new(string name = "ahb_apb_burst_write_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ahb_seq_h = ahb_burst_write_sequence::type_id::create("ahb_seq_h");
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("SEQ", "sequence started: ahb_burst_write_sequence", UVM_MEDIUM)
        ahb_seq_h.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_burst_write_sequence", UVM_MEDIUM)
        phase.phase_done.set_drain_time(this, 2000);
        phase.drop_objection(this);
    endtask
endclass

class ahb_apb_single_read_test extends ahb_apb_base_test;
    `uvm_component_utils(ahb_apb_single_read_test)

    ahb_single_read_sequence ahb_seq_h;

    function new(string name = "ahb_apb_single_read_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ahb_seq_h = ahb_single_read_sequence::type_id::create("ahb_seq_h");
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("SEQ", "sequence started: ahb_single_read_sequence", UVM_MEDIUM)
        ahb_seq_h.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_single_read_sequence", UVM_MEDIUM)
        phase.phase_done.set_drain_time(this, 300);
        phase.drop_objection(this);
    endtask
endclass

class ahb_apb_burst_read_test extends ahb_apb_base_test;
    `uvm_component_utils(ahb_apb_burst_read_test)

    ahb_burst_read_sequence ahb_seq_h;

    function new(string name = "ahb_apb_burst_read_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ahb_seq_h = ahb_burst_read_sequence::type_id::create("ahb_seq_h");
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("SEQ", "sequence started: ahb_burst_read_sequence", UVM_MEDIUM)
        ahb_seq_h.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_burst_read_sequence", UVM_MEDIUM)
        phase.phase_done.set_drain_time(this, 2000);
        phase.drop_objection(this);
    endtask
endclass

class ahb_apb_full_rw_test extends ahb_apb_base_test;
    `uvm_component_utils(ahb_apb_full_rw_test)

    ahb_single_write_sequence single_wr_seq;
    ahb_single_read_sequence  single_rd_seq;
    ahb_burst_write_sequence  burst_wr_seq;
    ahb_burst_read_sequence   burst_rd_seq;

    function new(string name = "ahb_apb_full_rw_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        single_wr_seq = ahb_single_write_sequence::type_id::create("single_wr_seq");
        single_rd_seq = ahb_single_read_sequence::type_id::create("single_rd_seq");
        burst_wr_seq  = ahb_burst_write_sequence::type_id::create("burst_wr_seq");
        burst_rd_seq  = ahb_burst_read_sequence::type_id::create("burst_rd_seq");
    endfunction

    task run_phase(uvm_phase phase);
        int i;
        phase.raise_objection(this);

        `uvm_info("SEQ", "sequence started: ahb_single_write_sequence batch x10", UVM_MEDIUM)
        for (i = 0; i < 10; i++)
            single_wr_seq.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_single_write_sequence batch x10", UVM_MEDIUM)

        `uvm_info("SEQ", "sequence started: ahb_single_read_sequence batch x10", UVM_MEDIUM)
        for (i = 0; i < 10; i++)
            single_rd_seq.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_single_read_sequence batch x10", UVM_MEDIUM)

        burst_wr_seq.N_TXN = 500;
        `uvm_info("SEQ", "sequence started: ahb_burst_write_sequence (N_TXN=500)", UVM_MEDIUM)
        burst_wr_seq.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_burst_write_sequence (N_TXN=500)", UVM_MEDIUM)

        burst_rd_seq.N_TXN = 500;
        `uvm_info("SEQ", "sequence started: ahb_burst_read_sequence (N_TXN=500)", UVM_MEDIUM)
        burst_rd_seq.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_burst_read_sequence (N_TXN=500)", UVM_MEDIUM)

        phase.phase_done.set_drain_time(this, 3000);
        phase.drop_objection(this);
    endtask
endclass

class ahb_apb_cov_boundary_test extends ahb_apb_base_test;
    `uvm_component_utils(ahb_apb_cov_boundary_test)

    ahb_cov_boundary_sequence cov_seq_h;

    function new(string name = "ahb_apb_cov_boundary_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cov_seq_h = ahb_cov_boundary_sequence::type_id::create("cov_seq_h");
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("SEQ", "sequence started: ahb_cov_boundary_sequence", UVM_MEDIUM)
        cov_seq_h.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_cov_boundary_sequence", UVM_MEDIUM)
        phase.phase_done.set_drain_time(this, 1500);
        phase.drop_objection(this);
    endtask
endclass

class ahb_apb_cov_code_stress_test extends ahb_apb_base_test;
    `uvm_component_utils(ahb_apb_cov_code_stress_test)

    ahb_cov_boundary_sequence    boundary_seq_h;
    ahb_cov_code_stress_sequence stress_seq_h;

    function new(string name = "ahb_apb_cov_code_stress_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        boundary_seq_h = ahb_cov_boundary_sequence::type_id::create("boundary_seq_h");
        stress_seq_h   = ahb_cov_code_stress_sequence::type_id::create("stress_seq_h");
        stress_seq_h.N_TXN = 1500;
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("SEQ", "sequence started: ahb_cov_boundary_sequence (warmup)", UVM_MEDIUM)
        boundary_seq_h.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_cov_boundary_sequence (warmup)", UVM_MEDIUM)

        `uvm_info("SEQ", "sequence started: ahb_cov_code_stress_sequence (N_TXN=1500)", UVM_MEDIUM)
        stress_seq_h.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_cov_code_stress_sequence (N_TXN=1500)", UVM_MEDIUM)

        phase.phase_done.set_drain_time(this, 6000);
        phase.drop_objection(this);
    endtask
endclass

class ahb_apb_full_final_test extends ahb_apb_base_test;
    `uvm_component_utils(ahb_apb_full_final_test)

    ahb_single_write_sequence      single_wr_seq;
    ahb_single_read_sequence       single_rd_seq;
    ahb_burst_write_sequence       burst_wr_seq;
    ahb_burst_read_sequence        burst_rd_seq;
    ahb_cov_boundary_sequence      boundary_seq_h;
    ahb_cov_code_stress_sequence   stress_seq_h;

    function new(string name = "ahb_apb_full_final_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        single_wr_seq = ahb_single_write_sequence::type_id::create("single_wr_seq");
        single_rd_seq = ahb_single_read_sequence::type_id::create("single_rd_seq");
        burst_wr_seq  = ahb_burst_write_sequence::type_id::create("burst_wr_seq");
        burst_rd_seq  = ahb_burst_read_sequence::type_id::create("burst_rd_seq");
        boundary_seq_h = ahb_cov_boundary_sequence::type_id::create("boundary_seq_h");
        stress_seq_h   = ahb_cov_code_stress_sequence::type_id::create("stress_seq_h");
        stress_seq_h.N_TXN = 1500;
    endfunction

    task run_phase(uvm_phase phase);
        int i;
        phase.raise_objection(this);

        // 1) original full-rw flow
        `uvm_info("SEQ", "final test stage started: full_rw", UVM_MEDIUM)

        `uvm_info("SEQ", "sequence started: ahb_single_write_sequence batch x10", UVM_MEDIUM)
        for (i = 0; i < 10; i++)
            single_wr_seq.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_single_write_sequence batch x10", UVM_MEDIUM)

        `uvm_info("SEQ", "sequence started: ahb_single_read_sequence batch x10", UVM_MEDIUM)
        for (i = 0; i < 10; i++)
            single_rd_seq.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_single_read_sequence batch x10", UVM_MEDIUM)

        burst_wr_seq.N_TXN = 500;
        `uvm_info("SEQ", "sequence started: ahb_burst_write_sequence (N_TXN=500)", UVM_MEDIUM)
        burst_wr_seq.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_burst_write_sequence (N_TXN=500)", UVM_MEDIUM)

        burst_rd_seq.N_TXN = 500;
        `uvm_info("SEQ", "sequence started: ahb_burst_read_sequence (N_TXN=500)", UVM_MEDIUM)
        burst_rd_seq.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_burst_read_sequence (N_TXN=500)", UVM_MEDIUM)

        `uvm_info("SEQ", "final test stage ended: full_rw", UVM_MEDIUM)

        // 2) dedicated coverage sequences
        `uvm_info("SEQ", "final test stage started: coverage_boundary", UVM_MEDIUM)
        `uvm_info("SEQ", "sequence started: ahb_cov_boundary_sequence", UVM_MEDIUM)
        boundary_seq_h.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_cov_boundary_sequence", UVM_MEDIUM)
        `uvm_info("SEQ", "final test stage ended: coverage_boundary", UVM_MEDIUM)

        `uvm_info("SEQ", "final test stage started: coverage_stress", UVM_MEDIUM)
        `uvm_info("SEQ", "sequence started: ahb_cov_code_stress_sequence (N_TXN=1500)", UVM_MEDIUM)
        stress_seq_h.start(env.ahb_agent_h.seqr);
        `uvm_info("SEQ", "sequence ended: ahb_cov_code_stress_sequence (N_TXN=1500)", UVM_MEDIUM)
        `uvm_info("SEQ", "final test stage ended: coverage_stress", UVM_MEDIUM)

        phase.phase_done.set_drain_time(this, 10000);
        phase.drop_objection(this);
    endtask
endclass
