module fft32#(
    parameter WIDTH = 32,
    parameter HALF = 16
    )(
    input  logic clk,
    input  logic rst,
    input  logic start,
    input  logic signed [WIDTH-1:0] in [0:31],
    output logic signed [WIDTH-1:0] out [0:31],
    output logic done
    );
    
    //twiddle factors w0-w15
    localparam logic [31:0] w_32 [0:15] = '{
        {16'sb0111111111111111, 16'sb0000000000000000}, // w0
        {16'sb0111110110011011, 16'sb1110100100000111}, // w1
        {16'sb0111011001000001, 16'sb1100111000000001}, // w2
        {16'sb0110101001101101, 16'sb1011100011100100}, // w3
        {16'sb0101101010000010, 16'sb1010010101111110}, // w4
        {16'sb0100011100011100, 16'sb1001010110010011}, // w5
        {16'sb0011000011111111, 16'sb1000100110111111}, // w6
        {16'sb0001100011111001, 16'sb1000001001110101}, // w7
        {16'sb0000000000000000, 16'sb1000000000000000}, // w8
        {16'sb1110100100000111, 16'sb1000001001110101}, // w9
        {16'sb1100111000000001, 16'sb1000100110111111}, // w10
        {16'sb1011100011100100, 16'sb1001010110010011}, // w11
        {16'sb1010010101111110, 16'sb1010010101111110}, // w12
        {16'sb1001010110010011, 16'sb1011100011100100}, // w13
        {16'sb1000100110111111, 16'sb1100111000000001}, // w14
        {16'sb1000001001110101, 16'sb1110100100000111}  // w15
    };
    
    //hann window
    localparam logic signed [16:0] hann_coeff [0:31] = '{
        0    , 630  , 2494 , 5522 , 
        9598 , 14563, 20228, 26375, 
        32768, 39161, 45308, 50973, 
        55938, 60014, 63042, 64906, 
        65535, 64906, 63042, 60014, 
        55938, 50973, 45308, 39161, 
        32768, 26375, 20228, 14563, 
        9598 , 5522 , 2494 , 630
    };
    
    function [4:0] reverse_bits (input [4:0] num);
        reverse_bits[0]=num[4];
        reverse_bits[1]=num[3];
        reverse_bits[2]=num[2];
        reverse_bits[3]=num[1];
        reverse_bits[4]=num[0];
    endfunction
    
    logic signed [WIDTH-1:0] hann_window_in [0:31];
    logic signed [WIDTH-1:0] f_a [0:15];
    logic signed [WIDTH-1:0] f_b [0:15];
    logic signed [WIDTH-1:0] f_w [0:15];
    logic signed [WIDTH-1:0] f_apbw [0:15];
    logic signed [WIDTH-1:0] f_ambw [0:15];
    
    typedef enum logic [3:0] {
        RESET,
        ST1_R, ST1_C,
        ST2_R, ST2_C,
        ST3_R, ST3_C,
        ST4_R, ST4_C,
        ST5_R, ST5_C,
        DONE
    } state_t;
    state_t curr, next;
    
        
    always_ff @(posedge clk) begin
        if(rst) begin
            curr<=RESET;
        end else curr<=next;
        
        case(curr)
            RESET: begin
                for(int i=0;i<32;i++) begin
                    automatic logic signed [32:0] temp=((hann_coeff[i]*$signed(in[i][31:16]))>>>16);
                    hann_window_in[i]<={temp[15:0],in[i][15:0]};
                end
                for(int i=0;i<16;i++) begin
                    f_a[i]<=0;
                    f_b[i]<=0;
                    f_w[i]<=0;
                end
                for(int i=0;i<32;i++) begin
                    out[i]<=0;
                end
                done<=0;
            end
            ST1_R: begin
                for(int i=0;i<16;i++) begin
                    f_a[i]<=hann_window_in[reverse_bits(2*i)];
                    f_b[i]<=hann_window_in[reverse_bits(2*i+1)];
                    f_w[i]<=w_32[0];
                end
                for(int i=0;i<32;i++) begin
                    out[i]<=0;
                end
                done<=0;
            end
            ST2_R: begin
                for(int i=0;i<8;i++) begin
                    f_a[2*i]  <=f_apbw[2*i];
                    f_a[2*i+1]<=f_ambw[2*i];
                    
                    f_b[2*i]  <=f_apbw[2*i+1];
                    f_b[2*i+1]<=f_ambw[2*i+1];
                    
                    f_w[2*i]  <=w_32[0];
                    f_w[2*i+1]<=w_32[8];
                end
                for(int i=0;i<32;i++) begin
                    out[i]<=0;
                end
                done<=0;
            end
            ST3_R: begin
                for(int i=0;i<4;i++) begin
                    f_a[4*i]  <=f_apbw[4*i];
                    f_a[4*i+1]<=f_apbw[4*i+1];
                    f_a[4*i+2]<=f_ambw[4*i];
                    f_a[4*i+3]<=f_ambw[4*i+1];
                    
                    f_b[4*i]  <=f_apbw[4*i+2];
                    f_b[4*i+1]<=f_apbw[4*i+3];
                    f_b[4*i+2]<=f_ambw[4*i+2];
                    f_b[4*i+3]<=f_ambw[4*i+3];
                    
                    f_w[4*i]  <=w_32[0];
                    f_w[4*i+1]<=w_32[4];
                    f_w[4*i+2]<=w_32[8];
                    f_w[4*i+3]<=w_32[12];
                    
                end
                for(int i=0;i<32;i++) begin
                    out[i]<=0;
                end
                done<=0;
            end
            ST4_R: begin
                for(int i=0;i<2;i++) begin
                    f_a[8*i]  <=f_apbw[8*i];
                    f_a[8*i+1]<=f_apbw[8*i+1];
                    f_a[8*i+2]<=f_apbw[8*i+2];
                    f_a[8*i+3]<=f_apbw[8*i+3];
                    f_a[8*i+4]<=f_ambw[8*i];
                    f_a[8*i+5]<=f_ambw[8*i+1];
                    f_a[8*i+6]<=f_ambw[8*i+2];
                    f_a[8*i+7]<=f_ambw[8*i+3];
                    
                    f_b[8*i]  <=f_apbw[8*i+4];
                    f_b[8*i+1]<=f_apbw[8*i+5];
                    f_b[8*i+2]<=f_apbw[8*i+6];
                    f_b[8*i+3]<=f_apbw[8*i+7];
                    f_b[8*i+4]<=f_ambw[8*i+4];
                    f_b[8*i+5]<=f_ambw[8*i+5];
                    f_b[8*i+6]<=f_ambw[8*i+6];
                    f_b[8*i+7]<=f_ambw[8*i+7];
                    
                    f_w[8*i]  <=w_32[0];
                    f_w[8*i+1]<=w_32[2];
                    f_w[8*i+2]<=w_32[4];
                    f_w[8*i+3]<=w_32[6];
                    f_w[8*i+4]<=w_32[8];
                    f_w[8*i+5]<=w_32[10];
                    f_w[8*i+6]<=w_32[12];
                    f_w[8*i+7]<=w_32[14];
                end
                for(int i=0;i<32;i++) begin
                    out[i]<=0;
                end
                done<=0;
            end
            ST5_R: begin
                for(int i=0;i<1;i++) begin
                    f_a[16*i]   <=f_apbw[16*i];
                    f_a[16*i+1] <=f_apbw[16*i+1];
                    f_a[16*i+2] <=f_apbw[16*i+2];
                    f_a[16*i+3] <=f_apbw[16*i+3];
                    f_a[16*i+4] <=f_apbw[16*i+4];
                    f_a[16*i+5] <=f_apbw[16*i+5];
                    f_a[16*i+6] <=f_apbw[16*i+6];
                    f_a[16*i+7] <=f_apbw[16*i+7];
                    f_a[16*i+8] <=f_ambw[16*i];
                    f_a[16*i+9] <=f_ambw[16*i+1];
                    f_a[16*i+10]<=f_ambw[16*i+2];
                    f_a[16*i+11]<=f_ambw[16*i+3];
                    f_a[16*i+12]<=f_ambw[16*i+4];
                    f_a[16*i+13]<=f_ambw[16*i+5];
                    f_a[16*i+14]<=f_ambw[16*i+6];
                    f_a[16*i+15]<=f_ambw[16*i+7];
                    
                    f_b[16*i]   <=f_apbw[16*i+8];
                    f_b[16*i+1] <=f_apbw[16*i+9];
                    f_b[16*i+2] <=f_apbw[16*i+10];
                    f_b[16*i+3] <=f_apbw[16*i+11];
                    f_b[16*i+4] <=f_apbw[16*i+12];
                    f_b[16*i+5] <=f_apbw[16*i+13];
                    f_b[16*i+6] <=f_apbw[16*i+14];
                    f_b[16*i+7] <=f_apbw[16*i+15];
                    f_b[16*i+8] <=f_ambw[16*i+8];
                    f_b[16*i+9] <=f_ambw[16*i+9];
                    f_b[16*i+10]<=f_ambw[16*i+10];
                    f_b[16*i+11]<=f_ambw[16*i+11];
                    f_b[16*i+12]<=f_ambw[16*i+12];
                    f_b[16*i+13]<=f_ambw[16*i+13];
                    f_b[16*i+14]<=f_ambw[16*i+14];
                    f_b[16*i+15]<=f_ambw[16*i+15];
                    
                    f_w[16*i]   <=w_32[0];
                    f_w[16*i+1] <=w_32[1];
                    f_w[16*i+2] <=w_32[2];
                    f_w[16*i+3] <=w_32[3];
                    f_w[16*i+4] <=w_32[4];
                    f_w[16*i+5] <=w_32[5];
                    f_w[16*i+6] <=w_32[6];
                    f_w[16*i+7] <=w_32[7];
                    f_w[16*i+8] <=w_32[8];
                    f_w[16*i+9] <=w_32[9];
                    f_w[16*i+10]<=w_32[10];
                    f_w[16*i+11]<=w_32[11];
                    f_w[16*i+12]<=w_32[12];
                    f_w[16*i+13]<=w_32[13];
                    f_w[16*i+14]<=w_32[14];
                    f_w[16*i+15]<=w_32[15];
                end
                for(int i=0;i<32;i++) begin
                    out[i]<=0;
                end
                done<=0;
            end
            DONE: begin
                for(int i=0;i<16;i++) begin
                    out[i]   <=f_apbw[i];
                    out[16+i]<=f_ambw[i];
                end
                done<=1;
            end
        endcase
    end
    
    always_comb begin
        case (curr)
            RESET:  next = start ? ST1_R : RESET;
            
            // Stage 1
            ST1_R: next = ST1_C; 
            ST1_C: next = ST2_R;
            //stage 2
            ST2_R: next = ST2_C;
            ST2_C: next = ST3_R;
            //stage 3
            ST3_R: next = ST3_C;
            ST3_C: next = ST4_R;
            //stage 4
            ST4_R: next = ST4_C;
            ST4_C: next = ST5_R;
            //stage 5
            ST5_R: next = ST5_C;
            ST5_C: next = DONE;
     
            DONE: next = rst ? RESET : DONE;
        endcase
    end
    
    
    
    
    butterfly#(.WIDTH(WIDTH))butterfly0(.clk(clk),.rst(rst),.A(f_a[0]),.B(f_b[0]),.W(f_w[0]),.A_PLUS_BW(f_apbw[0]),.A_MINUS_BW(f_ambw[0]));
    butterfly#(.WIDTH(WIDTH))butterfly1(.clk(clk),.rst(rst),.A(f_a[1]),.B(f_b[1]),.W(f_w[1]),.A_PLUS_BW(f_apbw[1]),.A_MINUS_BW(f_ambw[1]));
    butterfly#(.WIDTH(WIDTH))butterfly2(.clk(clk),.rst(rst),.A(f_a[2]),.B(f_b[2]),.W(f_w[2]),.A_PLUS_BW(f_apbw[2]),.A_MINUS_BW(f_ambw[2]));
    butterfly#(.WIDTH(WIDTH))butterfly3(.clk(clk),.rst(rst),.A(f_a[3]),.B(f_b[3]),.W(f_w[3]),.A_PLUS_BW(f_apbw[3]),.A_MINUS_BW(f_ambw[3]));
    butterfly#(.WIDTH(WIDTH))butterfly4(.clk(clk),.rst(rst),.A(f_a[4]),.B(f_b[4]),.W(f_w[4]),.A_PLUS_BW(f_apbw[4]),.A_MINUS_BW(f_ambw[4]));
    butterfly#(.WIDTH(WIDTH))butterfly5(.clk(clk),.rst(rst),.A(f_a[5]),.B(f_b[5]),.W(f_w[5]),.A_PLUS_BW(f_apbw[5]),.A_MINUS_BW(f_ambw[5]));
    butterfly#(.WIDTH(WIDTH))butterfly6(.clk(clk),.rst(rst),.A(f_a[6]),.B(f_b[6]),.W(f_w[6]),.A_PLUS_BW(f_apbw[6]),.A_MINUS_BW(f_ambw[6]));
    butterfly#(.WIDTH(WIDTH))butterfly7(.clk(clk),.rst(rst),.A(f_a[7]),.B(f_b[7]),.W(f_w[7]),.A_PLUS_BW(f_apbw[7]),.A_MINUS_BW(f_ambw[7]));
    butterfly#(.WIDTH(WIDTH))butterfly8(.clk(clk),.rst(rst),.A(f_a[8]),.B(f_b[8]),.W(f_w[8]),.A_PLUS_BW(f_apbw[8]),.A_MINUS_BW(f_ambw[8]));
    butterfly#(.WIDTH(WIDTH))butterfly9(.clk(clk),.rst(rst),.A(f_a[9]),.B(f_b[9]),.W(f_w[9]),.A_PLUS_BW(f_apbw[9]),.A_MINUS_BW(f_ambw[9]));
    butterfly#(.WIDTH(WIDTH))butterfly10(.clk(clk),.rst(rst),.A(f_a[10]),.B(f_b[10]),.W(f_w[10]),.A_PLUS_BW(f_apbw[10]),.A_MINUS_BW(f_ambw[10]));
    butterfly#(.WIDTH(WIDTH))butterfly11(.clk(clk),.rst(rst),.A(f_a[11]),.B(f_b[11]),.W(f_w[11]),.A_PLUS_BW(f_apbw[11]),.A_MINUS_BW(f_ambw[11]));
    butterfly#(.WIDTH(WIDTH))butterfly12(.clk(clk),.rst(rst),.A(f_a[12]),.B(f_b[12]),.W(f_w[12]),.A_PLUS_BW(f_apbw[12]),.A_MINUS_BW(f_ambw[12]));
    butterfly#(.WIDTH(WIDTH))butterfly13(.clk(clk),.rst(rst),.A(f_a[13]),.B(f_b[13]),.W(f_w[13]),.A_PLUS_BW(f_apbw[13]),.A_MINUS_BW(f_ambw[13]));
    butterfly#(.WIDTH(WIDTH))butterfly14(.clk(clk),.rst(rst),.A(f_a[14]),.B(f_b[14]),.W(f_w[14]),.A_PLUS_BW(f_apbw[14]),.A_MINUS_BW(f_ambw[14]));
    butterfly#(.WIDTH(WIDTH))butterfly15(.clk(clk),.rst(rst),.A(f_a[15]),.B(f_b[15]),.W(f_w[15]),.A_PLUS_BW(f_apbw[15]),.A_MINUS_BW(f_ambw[15]));
        
endmodule
