
module AHB_Slave_Interface(
	input        Hclk,
	input        Hresetn,
	input        Hwrite,
	input        Hreadyin,
	input [1:0]  Htrans,
	input [31:0] Haddr,
	input [31:0] Hwdata,
	input        bridge_ready,
  output       req_valid,
	output reg [31:0] req_addr,
	output reg [31:0] req_wdata,
	output reg   req_write,
	output reg [2:0] req_sel,
  output       buffer_full
);



  reg valid_int;
  reg [2:0] tempselx;

  // Valid transfer detection
  always @(*) begin
    valid_int = 1'b0;
    if (Hresetn && Hreadyin && (Haddr >= 32'h8000_0000 && Haddr < 32'h8C00_0000) && (Htrans == 2'b10 || Htrans == 2'b11))
      valid_int = 1'b1;
  end

  // APB slave select decode from current address phase
  always @(*) begin
    tempselx = 3'b000;
    if (Hresetn && Haddr >= 32'h8000_0000 && Haddr < 32'h8400_0000)
      tempselx = 3'b001;
    else if (Hresetn && Haddr >= 32'h8400_0000 && Haddr < 32'h8800_0000)
      tempselx = 3'b010;
    else if (Hresetn && Haddr >= 32'h8800_0000 && Haddr < 32'h8C00_0000)
      tempselx = 3'b100;
  end

  reg pending_req;
  reg addr_phase;
  
  // First buffer (next)
  reg [31:0] next_addr;
  reg [31:0] next_wdata;
  reg        next_write;
  reg [2:0]  next_sel;
  reg        next_addr_phase;
  
  // Second buffer (next2) for deeper pipelining
  reg [31:0] next2_addr;
  reg [31:0] next2_wdata;
  reg        next2_write;
  reg [2:0]  next2_sel;
  reg        next2_addr_phase;
  
  wire req_fire = pending_req && bridge_ready;

  assign req_valid = req_fire;
  // Buffer is full when both next and next2 slots are occupied
  assign buffer_full = pending_req && next_addr_phase && next2_addr_phase;

  // Latch request: address phase captures addr/write/sel, data phase captures wdata
  // Support deep pipelining with 2-level buffering (next + next2)
  always @(posedge Hclk or negedge Hresetn) begin
    if (!Hresetn) begin
      req_addr        <= 32'b0;
      req_wdata       <= 32'b0;
      req_write       <= 1'b0;
      req_sel         <= 3'b000;
      pending_req     <= 1'b0;
      addr_phase      <= 1'b0;
      next_addr       <= 32'b0;
      next_wdata      <= 32'b0;
      next_write      <= 1'b0;
      next_sel        <= 3'b000;
      next_addr_phase <= 1'b0;
      next2_addr      <= 32'b0;
      next2_wdata     <= 32'b0;
      next2_write     <= 1'b0;
      next2_sel       <= 3'b000;
      next2_addr_phase<= 1'b0;
    end else begin
      // Capture data phase for current transaction
      if (addr_phase && !req_fire) begin
        req_wdata   <= Hwdata;
        pending_req <= 1'b1;
        addr_phase  <= 1'b0;
        // Check if there's a new address phase in the same cycle (pipelined)
        if (valid_int && !next_addr_phase) begin
          next_addr       <= Haddr;
          next_write      <= Hwrite;
          next_sel        <= tempselx;
          next_addr_phase <= 1'b1;
        end else if (valid_int && next_addr_phase && !next2_addr_phase) begin
          next2_addr       <= Haddr;
          next2_write      <= Hwrite;
          next2_sel        <= tempselx;
          next2_addr_phase <= 1'b1;
        end
      end
      // Capture data phase for next
      else if (next_addr_phase && !req_fire && !addr_phase && !next2_addr_phase) begin
        next_wdata <= Hwdata;
      end
      // Capture data phase for next2
      else if (next2_addr_phase && !req_fire && !addr_phase && !next_addr_phase) begin
        next2_wdata <= Hwdata;
      end
      
      // Handle firing of current pending request
      if (req_fire) begin
        pending_req <= 1'b0;
        // If we have buffered transactions, shift the pipeline
        if (next_addr_phase) begin
          // Move next to current (capture data from current Hwdata if available)
          req_addr        <= next_addr;
          req_wdata       <= Hwdata;  // Hwdata contains next's data in pipelined mode
          req_write       <= next_write;
          req_sel         <= next_sel;
          pending_req     <= 1'b1;
          addr_phase      <= 1'b0;
          
          // Move next2 to next (if exists)
          if (next2_addr_phase) begin
            next_addr       <= next2_addr;
            next_wdata      <= Hwdata;  // Can also capture next2's data if pipelined
            next_write      <= next2_write;
            next_sel        <= next2_sel;
            next_addr_phase <= 1'b1;
            next2_addr_phase<= 1'b0;
            
            // Capture new transaction into next2 if present
            if (valid_int && (Haddr != next2_addr)) begin
              next2_addr       <= Haddr;
              next2_write      <= Hwrite;
              next2_sel        <= tempselx;
              next2_addr_phase <= 1'b1;
            end
          end else begin
            // No next2, so next becomes empty
            next_addr_phase <= 1'b0;
            // Capture new transaction into next if present
            if (valid_int && (Haddr != next_addr)) begin
              next_addr       <= Haddr;
              next_write      <= Hwrite;
              next_sel        <= tempselx;
              next_addr_phase <= 1'b1;
            end
          end
        end
        // No buffered transaction, check for new one
        else if (valid_int) begin
          req_addr    <= Haddr;
          req_write   <= Hwrite;
          req_sel     <= tempselx;
          addr_phase  <= 1'b1;
        end
        else begin
          addr_phase <= 1'b0;
        end
      end
      // Capture new address phase when no pending request
      else if (!pending_req && !addr_phase && valid_int) begin
        req_addr    <= Haddr;
        req_write   <= Hwrite;
        req_sel     <= tempselx;
        addr_phase  <= 1'b1;
      end
      // Buffer into next if we're pending and see a new valid transfer
      else if (pending_req && valid_int && !next_addr_phase && !addr_phase && (Haddr != req_addr)) begin
        next_addr       <= Haddr;
        next_write      <= Hwrite;
        next_sel        <= tempselx;
        next_addr_phase <= 1'b1;
      end
      // Buffer into next2 if next is occupied
      else if (pending_req && valid_int && next_addr_phase && !next2_addr_phase && !addr_phase && (Haddr != req_addr) && (Haddr != next_addr)) begin
        next2_addr       <= Haddr;
        next2_write      <= Hwrite;
        next2_sel        <= tempselx;
        next2_addr_phase <= 1'b1;
      end
    end
  end

endmodule
