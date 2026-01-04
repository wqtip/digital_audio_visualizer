module clk_div#(
    parameter DIVISOR=10000
    )(
    input logic clk,
    input logic rst,
    output logic o_clock_en
    );
    
    logic [31:0] counter;
    assign o_clock_en=(counter==DIVISOR-1);
    
    always_ff @(posedge clk) begin
        if(rst) counter<=0;
        else counter<=(counter<DIVISOR-1)?counter+1:0;
    end
    
endmodule
