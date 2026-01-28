// Bridge Top

module Bridge_Top(
	input        Hclk,
	input        Hresetn,
	input        Pclk,
	input        Presetn,
	input        Hwrite,
	input        Hreadyin,
	input [31:0] Hwdata,
	input [31:0] Haddr,
	input [1:0]  Htrans,
	input [31:0] Prdata,
	output       Penable,
	output       Pwrite,
	output [2:0] Pselx,
	output [31:0] Paddr,
	output [31:0] Pwdata,
	output       Hreadyout,
	output [1:0] Hresp,
	output [31:0] Hrdata
);

//////////INTERMEDIATE SIGNALS
wire        h_req_valid;
wire [31:0] h_req_addr;
wire [31:0] h_req_wdata;
wire        h_req_write;
wire [2:0]  h_req_sel;
wire        h_req_ready;
wire        h_buffer_full;

wire        p_req_valid;
wire [31:0] p_req_addr;
wire [31:0] p_req_wdata;
wire        p_req_write;
wire [2:0]  p_req_sel;
wire        p_req_accept;

wire        h_resp_valid;
wire [31:0] h_resp_rdata;
wire [1:0]  h_resp_err;

wire        p_resp_valid;
wire [31:0] p_resp_rdata;
wire [1:0]  p_resp_err;

reg [31:0] Hrdata_reg;
reg [1:0]  Hresp_reg;
reg        h_pending;

//////////MODULE INSTANTIATIONS
AHB_Slave_Interface AHBSlave (
	.Hclk(Hclk),
	.Hresetn(Hresetn),
	.Hwrite(Hwrite),
	.Hreadyin(Hreadyin),
	.Htrans(Htrans),
	.Haddr(Haddr),
	.Hwdata(Hwdata),
	.bridge_ready(h_req_ready),
	.req_valid(h_req_valid),
	.req_addr(h_req_addr),
	.req_wdata(h_req_wdata),
	.req_write(h_req_write),
	.req_sel(h_req_sel),
	.buffer_full(h_buffer_full)
);

cdc_req_rsp_mailbox #(
	.ADDR_W(32),
	.DATA_W(32),
	.SEL_W(3)
) CDC (
	.hclk(Hclk),
	.hresetn(Hresetn),
	.h_req_valid(h_req_valid),
	.h_req_addr(h_req_addr),
	.h_req_wdata(h_req_wdata),
	.h_req_write(h_req_write),
	.h_req_sel(h_req_sel),
	.h_req_ready(h_req_ready),
	.h_resp_valid(h_resp_valid),
	.h_resp_rdata(h_resp_rdata),
	.h_resp_err(h_resp_err),
	.pclk(Pclk),
	.presetn(Presetn),
	.p_req_valid(p_req_valid),
	.p_req_addr(p_req_addr),
	.p_req_wdata(p_req_wdata),
	.p_req_write(p_req_write),
	.p_req_sel(p_req_sel),
	.p_req_accept(p_req_accept),
	.p_resp_valid(p_resp_valid),
	.p_resp_rdata(p_resp_rdata),
	.p_resp_err(p_resp_err)
);

APB_FSM_Controller APBControl (
	.Pclk(Pclk),
	.Presetn(Presetn),
	.p_req_valid(p_req_valid),
	.p_req_addr(p_req_addr),
	.p_req_wdata(p_req_wdata),
	.p_req_write(p_req_write),
	.p_req_sel(p_req_sel),
	.p_req_accept(p_req_accept),
	.Prdata(Prdata),
	.Pwrite(Pwrite),
	.Penable(Penable),
	.Pselx(Pselx),
	.Paddr(Paddr),
	.Pwdata(Pwdata),
	.p_resp_valid(p_resp_valid),
	.p_resp_rdata(p_resp_rdata),
	.p_resp_err(p_resp_err)
);

// HCLK domain response handling
always @(posedge Hclk or negedge Hresetn) begin
	if (!Hresetn) begin
		Hrdata_reg <= 32'b0;
		Hresp_reg  <= 2'b00;
		h_pending  <= 1'b0;
	end else begin
		if (h_req_valid && h_req_ready)
			h_pending <= 1'b1;
		if (h_resp_valid) begin
			h_pending  <= 1'b0;
			Hrdata_reg <= h_resp_rdata;
			Hresp_reg  <= h_resp_err;
		end
	end
end

assign Hrdata    = Hrdata_reg;
assign Hresp     = Hresp_reg;
assign Hreadyout = ~h_pending && ~h_buffer_full;

endmodule
