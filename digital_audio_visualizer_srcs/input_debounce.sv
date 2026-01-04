module input_debounce #(
    parameter integer STABLE_COUNT = 100000  // 1 ms at 100 MHz
)(
    input  logic clk,
    input  logic rst,
    input  logic noisy_in,        // raw button
    output logic debounced_out    // clean button
);

    
    logic sync_0, sync_1;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_0 <= 0;
            sync_1 <= 0;
        end else begin
            sync_0 <= noisy_in;
            sync_1 <= sync_0;
        end
    end


    logic [$clog2(STABLE_COUNT):0] counter;
    logic stable_state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 0;
            stable_state <= 0;
        end else begin
            //has input changed
            if (sync_1 != stable_state) begin
                counter <= counter + 1;


                if (counter >= STABLE_COUNT) begin
                    stable_state <= sync_1;  //accept new state
                    counter <= 0;
                end
            end else begin
                counter <= 0;  //reset counter when stable
            end
        end
    end

    assign debounced_out = stable_state;

endmodule

