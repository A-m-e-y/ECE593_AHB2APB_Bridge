
module CDC_Handler(
    // Clock and Reset
    input Hclk, Pclk, Hresetn,
    
    // APB outputs from FSM (HCLK domain)
    input Penable_hclk, Pwrite_hclk,
    input [2:0] Pselx_hclk,
    input [31:0] Paddr_hclk, Pwdata_hclk,
    
    // APB outputs to APB bus (PCLK domain)
    output Penable_pclk, Pwrite_pclk,
    output [2:0] Pselx_pclk,
    output [31:0] Paddr_pclk, Pwdata_pclk,
    
    // APB input from APB bus (PCLK domain)
    input [31:0] Prdata_pclk,
    
    // APB input to AHB side (HCLK domain)
    output [31:0] Prdata_hclk
);

// 2-FF Synchronizers: HCLK -> PCLK (APB control/data signals)
reg Penable_sync1, Penable_sync2;
reg Pwrite_sync1, Pwrite_sync2;
reg [2:0] Pselx_sync1, Pselx_sync2;
reg [31:0] Paddr_sync1, Paddr_sync2;
reg [31:0] Pwdata_sync1, Pwdata_sync2;

// 2-FF Synchronizer: PCLK -> HCLK (Prdata)
reg [31:0] Prdata_sync1, Prdata_sync2;

// HCLK to PCLK synchronizers (APB outputs)
always @(posedge Pclk) begin
    if (~Hresetn) begin
        // First stage
        Penable_sync1 <= 0;
        Pwrite_sync1 <= 0;
        Pselx_sync1 <= 0;
        Paddr_sync1 <= 0;
        Pwdata_sync1 <= 0;
        
        // Second stage
        Penable_sync2 <= 0;
        Pwrite_sync2 <= 0;
        Pselx_sync2 <= 0;
        Paddr_sync2 <= 0;
        Pwdata_sync2 <= 0;
    end
    else begin
        // First stage
        Penable_sync1 <= Penable_hclk;
        Pwrite_sync1 <= Pwrite_hclk;
        Pselx_sync1 <= Pselx_hclk;
        Paddr_sync1 <= Paddr_hclk;
        Pwdata_sync1 <= Pwdata_hclk;
        
        // Second stage
        Penable_sync2 <= Penable_sync1;
        Pwrite_sync2 <= Pwrite_sync1;
        Pselx_sync2 <= Pselx_sync1;
        Paddr_sync2 <= Paddr_sync1;
        Pwdata_sync2 <= Pwdata_sync1;
    end
end

// Output to PCLK domain (APB bus)
assign Penable_pclk = Penable_sync2;
assign Pwrite_pclk = Pwrite_sync2;
assign Pselx_pclk = Pselx_sync2;
assign Paddr_pclk = Paddr_sync2;
assign Pwdata_pclk = Pwdata_sync2;

// PCLK to HCLK synchronizer (Prdata from APB)
always @(posedge Hclk) begin
    if (~Hresetn) begin
        Prdata_sync1 <= 0;
        Prdata_sync2 <= 0;
    end
    else begin
        Prdata_sync1 <= Prdata_pclk;
        Prdata_sync2 <= Prdata_sync1;
    end
end

// Output to HCLK domain
assign Prdata_hclk = Prdata_sync2;

endmodule
