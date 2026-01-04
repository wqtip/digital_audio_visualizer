module butterfly#(
    parameter WIDTH = 32
    )(
    input  logic clk,         
    input  logic rst,       
    input  logic signed [WIDTH-1:0] A,
    input  logic signed [WIDTH-1:0] B,
    input  logic signed [WIDTH-1:0] W,
    output logic signed [WIDTH-1:0] A_PLUS_BW,
    output logic signed [WIDTH-1:0] A_MINUS_BW
    );
    
    localparam HALF = WIDTH/2;
    

    logic signed [HALF-1:0] A_RE, A_IM, B_RE, B_IM, W_RE, W_IM;
    assign A_RE = A[WIDTH-1:HALF];
    assign A_IM = A[HALF-1:0];
    assign B_RE = B[WIDTH-1:HALF];
    assign B_IM = B[HALF-1:0];
    assign W_RE = W[WIDTH-1:HALF];
    assign W_IM = W[HALF-1:0];


    logic signed [WIDTH-1:0] BW_RE_reg, BW_IM_reg;
    logic signed [HALF-1:0]  A_RE_delayed, A_IM_delayed;

    always_ff @(posedge clk) begin
        if (rst) begin
            BW_RE_reg    <= '0;
            BW_IM_reg    <= '0;
            A_RE_delayed <= '0;
            A_IM_delayed <= '0;
        end else begin
            BW_RE_reg <= (B_RE * W_RE) - (B_IM * W_IM);
            BW_IM_reg <= (B_RE * W_IM) + (B_IM * W_RE);
            
            A_RE_delayed <= A_RE;
            A_IM_delayed <= A_IM;
        end
    end
    
    logic signed [HALF-1:0] BW_RE_scaled, BW_IM_scaled;
    logic signed [HALF-1:0] A_PBW_RE, A_PBW_IM, A_MBW_RE, A_MBW_IM;
    
    assign BW_RE_scaled = BW_RE_reg[WIDTH-2:HALF-1];
    assign BW_IM_scaled = BW_IM_reg[WIDTH-2:HALF-1];
    
    assign A_PBW_RE = A_RE_delayed + BW_RE_scaled;
    assign A_PBW_IM = A_IM_delayed + BW_IM_scaled;
    assign A_MBW_RE = A_RE_delayed - BW_RE_scaled;
    assign A_MBW_IM = A_IM_delayed - BW_IM_scaled;
    
    assign A_PLUS_BW  = {A_PBW_RE, A_PBW_IM};
    assign A_MINUS_BW = {A_MBW_RE, A_MBW_IM};
    
endmodule