module top(
    input logic clk,
    input logic rst,
    input logic switch_mode,
    input logic vauxp6,
    input logic vauxn6,
    output logic hsync,
    output logic vsync,
    output logic [3:0] red,
    output logic [3:0] green,
    output logic [3:0] blue
    );
    
    logic signed [11:0] mic_out;
    logic video_on;
    logic signed [10:0] x;
    logic signed [10:0] y;
    logic switch_mode_debounced;
    logic sm_prev, sm_curr;
    logic switch_mode_debounced_posedge;
    logic ce_5khz;
    logic display_all_bars;
    logic ce_8hz;
    logic fft_done;
    logic fft_rst;
    logic signed [31:0] fft_in [0:31];
    logic signed [31:0] fft_out [0:31];
    logic signed [9:0] display_bar_heights [0:31];

    
        
    // Add a register to store magnitudes after they are calculated
    logic signed [17:0] fft_magnitudes_reg [0:31];
    
    assign switch_mode_debounced_posedge=~sm_prev && sm_curr;
    always_ff @(posedge clk) begin
        if(rst) begin
            sm_prev<=0;
            sm_curr<=0;
        end else begin
            sm_prev<=sm_curr;
            sm_curr<=switch_mode_debounced;
        end
    end
    
    //display all(32) or half(16) bars;
    always_ff @(posedge clk) begin
        if(rst) display_all_bars<=0;
        else if(switch_mode_debounced_posedge) display_all_bars<=~display_all_bars;
    end
    
    
    always_ff @(posedge clk) begin
        if (rst) begin
            for(int i = 0; i < 32; i++) fft_magnitudes_reg[i] <= 0;
        end else if(fft_done) begin
            if(display_all_bars) begin
                for(int i = 0; i < 32; i++) begin
                    automatic logic signed [15:0] re=$signed(fft_out[i][31:16]);
                    automatic logic signed [15:0] im=$signed(fft_out[i][15:0]);
                    if(re<0 && im<0) fft_magnitudes_reg[i]<=-re-im;
                    else if(re<0 && im>=0) fft_magnitudes_reg[i]<=im-re;
                    else if(re>=0 && im<0) fft_magnitudes_reg[i]<=re-im;
                    else fft_magnitudes_reg[i]<=re+im;
                end
            end else begin
                for(int i = 0; i < 16; i++) begin
                    automatic logic signed [15:0] re=$signed(fft_out[i][31:16]);
                    automatic logic signed [15:0] im=$signed(fft_out[i][15:0]);
                    if(re<0 && im<0) fft_magnitudes_reg[i]<=-re-im;
                    else if(re<0 && im>=0) fft_magnitudes_reg[i]<=im-re;
                    else if(re>=0 && im<0) fft_magnitudes_reg[i]<=re-im;
                    else fft_magnitudes_reg[i]<=re+im;
                end
            end
        end
    end
    
    always_ff @(posedge clk) begin
        if(rst) begin
            for(int i=0; i<32; i++) display_bar_heights[i] <= 0;
        end else if(fft_done && ce_8hz) begin
            if(display_all_bars) begin
                for(int i=0; i<32; i++) begin
                    display_bar_heights[i] <= fft_magnitudes_reg[i][16:7];
                end
            end else begin
                for(int i=0; i<16; i++) begin
                    display_bar_heights[i] <= fft_magnitudes_reg[i][16:7];
                end
            end
        end
    end
    
    //reset the fft when vsync goes low
    always_ff @(posedge clk) begin
        if(rst) fft_rst<=0;
        else fft_rst<=(y==490);
    end
    
    //always maintain a 32 length window of mic output
    always_ff @(posedge clk) begin
        if(ce_5khz) begin
            fft_in[0] <= {mic_out, 20'b0}; 
            for(int i=1;i<32;i++) begin
                fft_in[i]<=fft_in[i-1];
            end
        end
    end
    
    
    
    logic signed [11:0] dist_from_center;
    logic [3:0] gradient_val;
    //render
    always_comb begin
        if (x < 320) 
            dist_from_center = 320 - x;
        else 
            dist_from_center = x - 320;
    
        if (dist_from_center > 320) 
            gradient_val = 0;
        else 
            gradient_val = (320 - dist_from_center) / 22; 
        if(display_all_bars) begin
            if(video_on && y>480-display_bar_heights[x/20]) begin
                red=gradient_val;
                green=(15-gradient_val);
                blue=15;
            end else begin
                red=0;
                green=0;
                blue=0;
            end
        end else begin
            if(video_on && y>480-display_bar_heights[x/40]) begin
                red=gradient_val;
                green=(15-gradient_val);
                blue=15;
            end else begin
                red=0;
                green=0;
                blue=0;
            end
        end
    end
    
    
    
    mic_sample#(
        .WIDTH(16)
    )mic_sample_inst(
        .clk(clk),
        .rst(rst),
        .vauxp6(vauxp6),
        .vauxn6(vauxn6),
        .mic_out(mic_out)
    );
    vga_controller vga_inst(
		.clk(clk),
		.reset(rst),
		.hsync(hsync),
		.vsync(vsync),
		.video_on(video_on),
		.x(x),
		.y(y)
	);
	
	fft32 fft_inst(
        .clk(clk),
        .rst(fft_rst),
        .start(vsync),
        .in(fft_in),
        .out(fft_out),
        .done(fft_done)
    );
    
    //5khz clock enable for mic sampling
    clk_div#(.DIVISOR(20000))clk_div_5khz(.clk(clk),.rst(rst),.o_clock_en(ce_5khz));
    //8hz clock enable for drawing
    clk_div#(.DIVISOR(12_500_000))clk_div_8hz(.clk(clk),.rst(rst),.o_clock_en(ce_8hz));
    input_debounce (.clk(clk),.rst(rst),.noisy_in(switch_mode),.debounced_out(switch_mode_debounced));
    
endmodule
