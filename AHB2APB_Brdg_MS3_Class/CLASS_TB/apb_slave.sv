
class apb_slave;

    virtual ahb_apb_if.master vif;
    
    // memory model
    bit [31:0] memory [bit [31:0]];
    
    // stats
    int write_count;
    int read_count;
    int protocol_errors;
    
    bit [2:0] prev_psel;
    bit prev_penable;
    
    function new(virtual ahb_apb_if.master vif);
        this.vif = vif;
        this.write_count = 0;
        this.read_count = 0;
        this.protocol_errors = 0;
        this.prev_psel = 0;
        this.prev_penable = 0;
    endfunction
    
    task run();
        fork
            monitor_apb();
            respond_to_reads();
        join_none
    endtask
    
    task monitor_apb();
        bit [31:0] last_paddr = 32'hFFFFFFFF;
        bit last_pwrite = 1'bx;
        bit last_penable = 0;
        
        forever begin
            @(posedge vif.Pclk);
            
            if (vif.Pselx != 0) begin
                
                if (vif.Penable) begin
                    // process when address changes or PENABLE rise
                    if (!last_penable || (vif.Paddr != last_paddr)) begin
                        
                        // skip glitch from write->read
                        if (!(vif.Paddr == last_paddr && last_pwrite == 1'b1 && vif.Pwrite == 1'b0)) begin
                            
                            if (vif.Pwrite) begin
                                handle_write(vif.Paddr, vif.Pwdata);
                            end
                            else begin
                                handle_read(vif.Paddr);
                            end
                        end
                        
                        last_paddr = vif.Paddr;
                        last_pwrite = vif.Pwrite;
                    end
                    
                    if (vif.Pselx == 0) begin
                        $display("[%0t] APB_SLAVE ERROR: PSEL de-asserted during ACCESS phase!", $time);
                        protocol_errors++;
                    end
                end
            end
            
            last_penable = vif.Penable;
        end
    endtask
    
    task handle_write(bit [31:0] addr, bit [31:0] data);
        memory[addr] = data;
        write_count++;
        $display("[%0t]   APB Slave: Stored Write  Addr=0x%0h  Data=0x%0h", $time, addr, data);
    endtask
    
    task handle_read(bit [31:0] addr);
        bit [31:0] read_data;
        
        if (memory.exists(addr)) begin
            read_data = memory[addr];
            $display("[%0t]   APB Slave: Read (HIT)    Addr=0x%0h  Data=0x%0h", $time, addr, read_data);
        end
        else begin
            read_data = {addr[15:0], ~addr[15:0]};
            $display("[%0t]   APB Slave: Read (MISS)   Addr=0x%0h  Data=0x%0h [generated]", $time, addr, read_data);
        end
        
        read_count++;
    endtask
    
    task respond_to_reads();
        forever begin
            @(posedge vif.Pclk);
            
            if (vif.Pselx != 0 && vif.Penable && !vif.Pwrite) begin
                bit [31:0] addr = vif.Paddr;
                bit [31:0] read_data;
                
                if (memory.exists(addr)) begin
                    read_data = memory[addr];
                end
                else begin
                    read_data = {addr[15:0], ~addr[15:0]};
                end
                
                vif.Prdata = read_data;
            end
        end
    endtask
    
    function int get_slave_index(bit [2:0] pselx);
        case (pselx)
            3'b001: return 0;
            3'b010: return 1;
            3'b100: return 2;
            default: return -1;
        endcase
    endfunction
    
    task display_stats();
        $display("\n========== APB SLAVE STATISTICS ==========");
        $display("Total Writes:       %0d", write_count);
        $display("Total Reads:        %0d", read_count);
        $display("Protocol Errors:    %0d", protocol_errors);
        $display("Memory Entries:     %0d", memory.size());
        $display("==========================================\n");
    endtask
    
    function bit check_memory(bit [31:0] addr, bit [31:0] expected_data);
        if (memory.exists(addr)) begin
            if (memory[addr] == expected_data) begin
                $display("[%0t] APB_SLAVE: Memory check PASSED for addr=0x%0h", $time, addr);
                return 1;
            end
            else begin
                $display("[%0t] APB_SLAVE ERROR: Memory check FAILED for addr=0x%0h. Expected=0x%0h, Got=0x%0h", 
                         $time, addr, expected_data, memory[addr]);
                return 0;
            end
        end
        else begin
            $display("[%0t] APB_SLAVE ERROR: Address 0x%0h was never written!", $time, addr);
            return 0;
        end
    endfunction

endclass
