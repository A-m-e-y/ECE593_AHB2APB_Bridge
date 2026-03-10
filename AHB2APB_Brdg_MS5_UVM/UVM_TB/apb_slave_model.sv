// behavioral APB slave - acts as memory for the 3 address ranges
// detects transactions using PENABLE rising edge or PADDR change during b2b bursts
// valid writes go into associative memory, reads return stored value (or DEAD_BEEF)
// broadcasts each valid txn to scoreboard via ap_port
//
// address ranges (match Bridge_Top decode):
//   slave1: 0x8000_0000 - 0x83FF_FFFF
//   slave2: 0x8400_0000 - 0x87FF_FFFF
//   slave3: 0x8800_0000 - 0x8BFF_FFFF

class apb_slave_model extends uvm_component;
    `uvm_component_utils(apb_slave_model)

    virtual intf vif;   // need full intf for reliable @(posedge pclk)

    uvm_analysis_port #(apb_transaction) ap_port;

    logic [31:0] mem [bit[31:0]];   // associative memory

    int write_count;
    int read_count;
    int protocol_errors;
    int range_errors;

    function new(string name = "apb_slave_model", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_port = new("ap_port", this);
        if (!uvm_config_db#(virtual intf)::get(this, "", "full_vif", vif))
            `uvm_fatal("SLAVE", "Cannot get full_vif from config_db")
    endfunction

    task run_phase(uvm_phase phase);
        bit [2:0]  pselx;
        bit        penable;
        bit        pwrite;
        bit [31:0] paddr;
        bit [31:0] pwdata;
        bit [31:0] prev_paddr;
        bit        prev_penable;

        repeat(4) @(posedge vif.pclk);
        prev_penable = 1'b0;
        prev_paddr   = 32'hFFFF_FFFF;

        forever begin
            @(posedge vif.pclk); #1;
            pselx   = vif.PSELX;
            penable = vif.PENABLE;
            pwrite  = vif.PWRITE;
            paddr   = vif.PADDR;
            pwdata  = vif.PWDATA;

            // new txn = PENABLE rising edge OR paddr changed in b2b burst
            if (penable && pselx != 3'b000) begin
                if (!prev_penable || paddr !== prev_paddr) begin
                    handle_txn(pselx, pwrite, paddr, pwdata);
                end
            end else if (penable && pselx == 3'b000 && !prev_penable) begin
                `uvm_error("SLAVE", "PENABLE asserted without PSELX")
                protocol_errors++;
            end

            if (!penable && prev_penable)
                vif.PRDATA = 32'h0;

            prev_penable = penable;
            prev_paddr   = paddr;
        end
    endtask

    task handle_txn(bit [2:0] pselx, bit pwrite, bit [31:0] paddr, bit [31:0] pwdata);
        apb_transaction tx;

        if (!valid_addr(paddr)) begin
            `uvm_error("SLAVE",
                $sformatf("ADDR OUT OF RANGE: PADDR=0x%08h PSELX=3'b%03b", paddr, pselx))
            range_errors++;
            return;
        end

        if (!is_onehot(pselx)) begin
            `uvm_error("SLAVE",
                $sformatf("PSELX not one-hot: 3'b%03b PADDR=0x%08h", pselx, paddr))
            protocol_errors++;
            return;
        end

        if (!valid_pselx(pselx, paddr)) begin
            `uvm_error("SLAVE",
                $sformatf("PSELX mismatch: PADDR=0x%08h vs PSELX=3'b%03b", paddr, pselx))
            protocol_errors++;
            return;
        end

        tx = apb_transaction::type_id::create("tx", this);
        tx.PWRITE = pwrite;
        tx.PSELX  = pselx;
        tx.PADDR  = paddr;
        tx.PWDATA = pwdata;

        if (pwrite) begin
            mem[paddr] = pwdata;
            write_count++;
            tx.PRDATA = 32'h0;
            `uvm_info("SLAVE",
                $sformatf("WRITE PSELX=3'b%03b PADDR=0x%08h PWDATA=0x%08h",
                pselx, paddr, pwdata), UVM_MEDIUM)
        end else begin
            tx.PRDATA = mem.exists(paddr) ? mem[paddr] : 32'hDEAD_BEEF;
            vif.PRDATA = tx.PRDATA;
            read_count++;
            `uvm_info("SLAVE",
                $sformatf("READ  PSELX=3'b%03b PADDR=0x%08h PRDATA=0x%08h",
                pselx, paddr, tx.PRDATA), UVM_MEDIUM)
        end

        ap_port.write(tx);
    endtask

    function bit valid_addr(bit [31:0] addr);
        return (addr >= 32'h8000_0000 && addr <= 32'h8BFF_FFFF);
    endfunction

    function bit is_onehot(bit [2:0] pselx);
        return (pselx == 3'b001 || pselx == 3'b010 || pselx == 3'b100);
    endfunction

    function bit valid_pselx(bit [2:0] pselx, bit [31:0] addr);
        case (pselx)
            3'b001: return (addr >= 32'h8000_0000 && addr <= 32'h83FF_FFFF);
            3'b010: return (addr >= 32'h8400_0000 && addr <= 32'h87FF_FFFF);
            3'b100: return (addr >= 32'h8800_0000 && addr <= 32'h8BFF_FFFF);
            default: return 0;
        endcase
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SLAVE", $sformatf({
            "\n========================================\n",
            " APB Slave Model Report\n",
            "========================================\n",
            " Writes completed  : %0d\n",
            " Reads completed   : %0d\n",
            " Protocol errors   : %0d\n",
            " Range errors      : %0d\n",
            "========================================"
            },
            write_count, read_count, protocol_errors, range_errors),
            UVM_NONE)

        if (protocol_errors > 0)
            `uvm_error("SLAVE", $sformatf("%0d APB protocol violation(s)", protocol_errors))
        if (range_errors > 0)
            `uvm_error("SLAVE", $sformatf("%0d APB address range error(s)", range_errors))
    endfunction

endclass
