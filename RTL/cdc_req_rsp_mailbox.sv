module cdc_req_rsp_mailbox #(
  parameter ADDR_W = 32,
  parameter DATA_W = 32,
  parameter SEL_W  = 3
) (
  // HCLK domain
  input                   hclk,
  input                   hresetn,
  input                   h_req_valid,
  input  [ADDR_W-1:0]     h_req_addr,
  input  [DATA_W-1:0]     h_req_wdata,
  input                   h_req_write,
  input  [SEL_W-1:0]      h_req_sel,
  output                  h_req_ready,
  output reg              h_resp_valid,
  output reg [DATA_W-1:0] h_resp_rdata,
  output reg [1:0]        h_resp_err,

  // PCLK domain
  input                   pclk,
  input                   presetn,
  output                  p_req_valid,
  output reg [ADDR_W-1:0] p_req_addr,
  output reg [DATA_W-1:0] p_req_wdata,
  output reg              p_req_write,
  output reg [SEL_W-1:0]  p_req_sel,
  input                   p_req_accept,
  input                   p_resp_valid,
  input  [DATA_W-1:0]     p_resp_rdata,
  input  [1:0]            p_resp_err
);

  // Request toggle + payload (HCLK -> PCLK)
  reg req_tgl;
  reg [ADDR_W-1:0] req_addr_reg;
  reg [DATA_W-1:0] req_wdata_reg;
  reg req_write_reg;
  reg [SEL_W-1:0]  req_sel_reg;

  // Ack toggle sync (PCLK -> HCLK)
  reg ack_tgl_sync1, ack_tgl_sync2;

  // Response toggle + payload (PCLK -> HCLK)
  reg resp_tgl;
  reg [DATA_W-1:0] resp_rdata_reg;
  reg [1:0]        resp_err_reg;

  // Response ack toggle sync (HCLK -> PCLK)
  reg resp_ack_tgl;
  reg resp_ack_sync1, resp_ack_sync2;

  // Request toggle sync (HCLK -> PCLK)
  reg req_tgl_sync1, req_tgl_sync2;
  reg req_tgl_seen;

  // Response toggle sync (PCLK -> HCLK)
  reg resp_tgl_sync1, resp_tgl_sync2;
  reg resp_tgl_seen;

  assign h_req_ready = (req_tgl == ack_tgl_sync2);

  // HCLK domain: capture request payload and toggle req_tgl
  always @(posedge hclk or negedge hresetn) begin
    if (!hresetn) begin
      req_tgl      <= 1'b0;
      req_addr_reg <= {ADDR_W{1'b0}};
      req_wdata_reg<= {DATA_W{1'b0}};
      req_write_reg<= 1'b0;
      req_sel_reg  <= {SEL_W{1'b0}};
    end else if (h_req_valid && h_req_ready) begin
      req_addr_reg <= h_req_addr;
      req_wdata_reg<= h_req_wdata;
      req_write_reg<= h_req_write;
      req_sel_reg  <= h_req_sel;
      req_tgl      <= ~req_tgl;
    end
  end

  // HCLK domain: sync ack_tgl
  always @(posedge hclk or negedge hresetn) begin
    if (!hresetn) begin
      ack_tgl_sync1 <= 1'b0;
      ack_tgl_sync2 <= 1'b0;
    end else begin
      ack_tgl_sync1 <= ack_tgl;
      ack_tgl_sync2 <= ack_tgl_sync1;
    end
  end

  // HCLK domain: sync response toggle and latch response payload
  always @(posedge hclk or negedge hresetn) begin
    if (!hresetn) begin
      resp_tgl_sync1 <= 1'b0;
      resp_tgl_sync2 <= 1'b0;
      resp_tgl_seen  <= 1'b0;
      h_resp_valid   <= 1'b0;
      h_resp_rdata   <= {DATA_W{1'b0}};
      h_resp_err     <= 2'b00;
      resp_ack_tgl   <= 1'b0;
    end else begin
      resp_tgl_sync1 <= resp_tgl;
      resp_tgl_sync2 <= resp_tgl_sync1;
      h_resp_valid   <= 1'b0;

      if (resp_tgl_sync2 != resp_tgl_seen) begin
        resp_tgl_seen <= resp_tgl_sync2;
        h_resp_rdata  <= resp_rdata_reg;
        h_resp_err    <= resp_err_reg;
        h_resp_valid  <= 1'b1;
        resp_ack_tgl  <= ~resp_ack_tgl;
      end
    end
  end

  // PCLK domain: sync req_tgl
  always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      req_tgl_sync1 <= 1'b0;
      req_tgl_sync2 <= 1'b0;
      req_tgl_seen  <= 1'b0;
    end else begin
      req_tgl_sync1 <= req_tgl;
      req_tgl_sync2 <= req_tgl_sync1;
      if (p_req_accept && (req_tgl_sync2 != req_tgl_seen)) begin
        req_tgl_seen <= req_tgl_sync2;
      end
    end
  end

  assign p_req_valid = (req_tgl_sync2 != req_tgl_seen);

  // PCLK domain: capture payload when accepting request, then toggle ack
  reg ack_tgl;
  always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      ack_tgl     <= 1'b0;
      p_req_addr  <= {ADDR_W{1'b0}};
      p_req_wdata <= {DATA_W{1'b0}};
      p_req_write <= 1'b0;
      p_req_sel   <= {SEL_W{1'b0}};
    end else if (p_req_accept && p_req_valid) begin
      p_req_addr  <= req_addr_reg;
      p_req_wdata <= req_wdata_reg;
      p_req_write <= req_write_reg;
      p_req_sel   <= req_sel_reg;
      ack_tgl     <= ~ack_tgl;
    end
  end

  // PCLK domain: sync resp_ack_tgl
  always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      resp_ack_sync1 <= 1'b0;
      resp_ack_sync2 <= 1'b0;
    end else begin
      resp_ack_sync1 <= resp_ack_tgl;
      resp_ack_sync2 <= resp_ack_sync1;
    end
  end

  // PCLK domain: send response toggle when APB completes
  always @(posedge pclk or negedge presetn) begin
    if (!presetn) begin
      resp_tgl       <= 1'b0;
      resp_rdata_reg <= {DATA_W{1'b0}};
      resp_err_reg   <= 2'b00;
    end else if (p_resp_valid && (resp_tgl == resp_ack_sync2)) begin
      resp_rdata_reg <= p_resp_rdata;
      resp_err_reg   <= p_resp_err;
      resp_tgl       <= ~resp_tgl;
    end
  end

endmodule
