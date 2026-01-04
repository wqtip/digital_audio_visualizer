module mic_sample#(
    parameter WIDTH=16,
    parameter SAMPLES_FOR_DC_OFFSET_AVG=32768
    )(
    input  logic clk,         
    input  logic rst,           
    input  logic vauxp6,       
    input  logic vauxn6,        
    output logic signed [11:0] mic_out     // mic sample output (5000 samples per sec)
    );
    

    logic [15:0] adc_raw_data;
    logic adc_data_ready;
    logic adc_busy;
    logic adc_eoc; 
    logic [4:0] channel_out;
    
    logic [31:0] dc_offset_avg_acc;
    logic [31:0] dc_offset_avg_counter;
    logic [31:0] dc_offset_avg;

    always_ff @(posedge clk) begin
        if(rst) begin
            dc_offset_avg_counter<=0;
            dc_offset_avg_acc<=0;
            dc_offset_avg<=2048;
        end else if(adc_data_ready) begin
            dc_offset_avg_counter <= (dc_offset_avg_counter>=SAMPLES_FOR_DC_OFFSET_AVG) ? 0 : dc_offset_avg_counter + 1;
            dc_offset_avg_acc     <= (dc_offset_avg_counter>=SAMPLES_FOR_DC_OFFSET_AVG) ? 0 : dc_offset_avg_acc + (adc_raw_data >> 4);
            if(dc_offset_avg_counter >= SAMPLES_FOR_DC_OFFSET_AVG) dc_offset_avg <= (dc_offset_avg_acc >> 15);
        end
    end
    
    always_ff @(posedge clk) begin
        if(rst) mic_out<=12'b0;
        else if(adc_data_ready) begin
            automatic logic signed [12:0] diff = $signed((adc_raw_data>>4))-$signed(dc_offset_avg);
            if(diff<-2048) mic_out<=-2048;
            else if(diff>2047) mic_out<=2047;
            else mic_out<=diff;
        end
    end
    
    
    mic_xadc XADC_INST (
        .daddr_in(7'h16),     
        .dclk_in(clk),         
        .reset_in(rst),
        .den_in(adc_eoc),      
        .di_in(16'h0),
        .dwe_in(1'b0),
        .vauxp6(vauxp6),
        .vauxn6(vauxn6),
        .busy_out(adc_busy),
        .channel_out(channel_out),
        .do_out(adc_raw_data), 
        .drdy_out(adc_data_ready), 
        .eoc_out(adc_eoc),         
        .eos_out(), 
        .alarm_out(),
        .vp_in(1'b0),
        .vn_in(1'b0)
    );

endmodule