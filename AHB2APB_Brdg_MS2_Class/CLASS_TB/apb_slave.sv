
class apb_slave;

    virtual ahb_apb_if.master vif;
    
    // Simple memory model - associative array for sparse address space
    bit [31:0] memory [bit [31:0]];
    
    // Statistics
    int write_count;
    int read_count;
    int protocol_errors;
    
    // Previous state for protocol checking
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
    
    // Main task to monitor and respond to APB transactions
    task run();
        fork
            monitor_apb();
            respond_to_reads();
        join_none
    endtask
    
    // Monitor APB signals and check protocol
    task monitor_apb();
        bit [31:0] last_paddr = 32'hFFFFFFFF;
        bit last_pwrite = 1'bx;
        bit last_penable = 0;
        
        forever begin
            @(posedge vif.Pclk);
            
            // Check if any slave is selected
            if (vif.Pselx != 0) begin
                
                if (vif.Penable) begin
                    // ACCESS phase - detect new transaction
                    // Only process when address changes or PENABLE rising edge
                    if (!last_penable || (vif.Paddr != last_paddr)) begin
                        
                        // Skip spurious write→read transitions at same address
                        if (!(vif.Paddr == last_paddr && last_pwrite == 1'b1 && vif.Pwrite == 1'b0)) begin
                            
                            if (vif.Pwrite) begin
                                // Write transaction
                                handle_write(vif.Paddr, vif.Pwdata);
                            end
                            else begin
                                // Read transaction
                                handle_read(vif.Paddr);
                            end
                        end
                        
                        last_paddr = vif.Paddr;
                        last_pwrite = vif.Pwrite;
                    end
                    
                    // Protocol check: PSEL should remain asserted during ACCESS
                    if (vif.Pselx == 0) begin
                        $display("[%0t] APB_SLAVE ERROR: PSEL de-asserted during ACCESS phase!", $time);
                        protocol_errors++;
                    end
                end
                else begin
                    // PSEL high but PENABLE low
                    // In standard APB, this would be SETUP phase
                    // In our design, this shouldn't happen (both go high together)
                    // But if it does, just wait for next cycle
                end
            end
            
            last_penable = vif.Penable;
        end
    endtask
    
    // Handle write transactions
    task handle_write(bit [31:0] addr, bit [31:0] data);
        memory[addr] = data;
        write_count++;
        $display("[%0t]   APB Slave: Stored Write  Addr=0x%0h  Data=0x%0h", $time, addr, data);
    endtask
    
    // Handle read transactions
    task handle_read(bit [31:0] addr);
        bit [31:0] read_data;
        
        // If address was previously written, return that data
        // Otherwise return a default pattern based on address
        if (memory.exists(addr)) begin
            read_data = memory[addr];
            $display("[%0t]   APB Slave: Read (HIT)    Addr=0x%0h  Data=0x%0h", $time, addr, read_data);
        end
        else begin
            // Generate pseudo-random but deterministic data based on address
            read_data = {addr[15:0], ~addr[15:0]};
            $display("[%0t]   APB Slave: Read (MISS)   Addr=0x%0h  Data=0x%0h [generated]", $time, addr, read_data);
        end
        
        read_count++;
    endtask
    
    // Respond to reads by driving Prdata
    task respond_to_reads();
        forever begin
            @(posedge vif.Pclk);
            
            // If this is a read transaction (PSEL=1, PENABLE=1, PWRITE=0)
            if (vif.Pselx != 0 && vif.Penable && !vif.Pwrite) begin
                bit [31:0] addr = vif.Paddr;
                bit [31:0] read_data;
                
                // Get data from memory or generate default
                if (memory.exists(addr)) begin
                    read_data = memory[addr];
                end
                else begin
                    read_data = {addr[15:0], ~addr[15:0]};
                end
                
                // Drive Prdata (combinational response in same cycle)
                vif.Prdata = read_data;
            end
        end
    endtask
    
    // Helper function to get slave index from Pselx
    function int get_slave_index(bit [2:0] pselx);
        case (pselx)
            3'b001: return 0;
            3'b010: return 1;
            3'b100: return 2;
            default: return -1;
        endcase
    endfunction
    
    // Display statistics
    task display_stats();
        $display("\n========== APB SLAVE STATISTICS ==========");
        $display("Total Writes:       %0d", write_count);
        $display("Total Reads:        %0d", read_count);
        $display("Protocol Errors:    %0d", protocol_errors);
        $display("Memory Entries:     %0d", memory.size());
        $display("==========================================\n");
    endtask
    
    // Check memory coherency (read-after-write)
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
