module APB_FSM_Controller(
	input        Pclk,
	input        Presetn,
	input        p_req_valid,
	input [31:0] p_req_addr,
	input [31:0] p_req_wdata,
	input        p_req_write,
	input [2:0]  p_req_sel,
	output reg   p_req_accept,
	input [31:0] Prdata,
	output reg   Pwrite,
	output reg   Penable,
	output reg [2:0] Pselx,
	output reg [31:0] Paddr,
	output reg [31:0] Pwdata,
	output reg   p_resp_valid,
	output reg [31:0] p_resp_rdata,
	output reg [1:0]  p_resp_err
);

	localparam ST_IDLE   = 2'b00;
	localparam ST_SETUP  = 2'b01;
	localparam ST_ACCESS = 2'b10;

	reg [1:0] state, next_state;
	always @(posedge Pclk or negedge Presetn) begin
		if (!Presetn) begin
			state       <= ST_IDLE;
		end else begin
			state <= next_state;
		end
	end

	always @(*) begin
		next_state = state;
		case (state)
			ST_IDLE: begin
				if (p_req_valid)
					next_state = ST_SETUP;
			end
			ST_SETUP: begin
				next_state = ST_ACCESS;
			end
			ST_ACCESS: begin
				next_state = ST_IDLE;
			end
			default: begin
				next_state = ST_IDLE;
			end
		endcase
	end

	always @(*) begin
		p_req_accept  = 1'b0;
		Pwrite        = 1'b0;
		Penable       = 1'b0;
		Pselx         = 3'b000;
		Paddr         = 32'b0;
		Pwdata        = 32'b0;
		p_resp_valid  = 1'b0;
		p_resp_rdata  = 32'b0;
		p_resp_err    = 2'b00;

		case (state)
			ST_IDLE: begin
				if (p_req_valid) begin
					p_req_accept = 1'b1;
				end
			end

			ST_SETUP: begin
				Pwrite  = p_req_write;
				Pselx   = p_req_sel;
				Paddr   = p_req_addr;
				Pwdata  = p_req_wdata;
				Penable = 1'b0;
			end

			ST_ACCESS: begin
				Pwrite  = p_req_write;
				Pselx   = p_req_sel;
				Paddr   = p_req_addr;
				Pwdata  = p_req_wdata;
				Penable = 1'b1;
				p_resp_valid = 1'b1;
				if (!p_req_write)
					p_resp_rdata = Prdata;
			end
		endcase
	end

endmodule
