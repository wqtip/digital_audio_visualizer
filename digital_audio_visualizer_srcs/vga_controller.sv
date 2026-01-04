module vga_controller(
		input logic clk,
		input logic reset,
		output logic hsync,
		output logic vsync,
		output logic video_on,
		output logic signed [10:0] x,
		output logic signed [10:0] y
	);
	
	// vga parameters
	localparam HPIXELS = 640; // horizontal display area
	localparam HBP = 48; // horizontal left border
	localparam HFP = 16; // horizontal right border
	localparam HPULSE = 96; // horizontal retrace
	
	localparam VPIXELS = 480; // vertical display area
	localparam VFP = 10; // vertical top border
	localparam VBP = 33; // vertical bottom border
	localparam VPULSE = 2; // vertical retrace
	
	// 25 mhz clock enable
	logic [1:0] pixel_reg;
	logic ce_25mhz;
	
	always @(posedge clk, posedge reset)
		if(reset)
		  pixel_reg <= 0;
		else
		  pixel_reg <= pixel_reg+1;
		
	assign ce_25mhz = (pixel_reg == 0); // assert tick 1/4 of the time
	
	// registers to keep track of current pixel location
	logic signed [10:0] h_count_reg, h_count_next, v_count_reg, v_count_next;
	
	// next states for hsync and vsync
	logic vsync_next, hsync_next;
 
	// infer registers
	always_ff @(posedge clk) begin
	   if(reset) begin
	       v_count_reg <= 0;
	       h_count_reg <= 0;
	       vsync <= 0;
	       hsync <= 0;
	   end else if(ce_25mhz) begin
	       v_count_reg <= v_count_next;
	       h_count_reg <= h_count_next;
	       vsync <= vsync_next;
	       hsync <= hsync_next;
	   end
	end
	
	// next logic
	always_comb begin
	   h_count_next = (h_count_reg == $signed(HPIXELS + HFP + HBP + HPULSE - 1)) ? 0 : h_count_reg + 1;
	   v_count_next = (h_count_reg == $signed(HPIXELS + HFP + HBP + HPULSE - 1)) ? (v_count_reg == VPIXELS + VFP + VBP + VPULSE - 1 ? 0 : v_count_reg + 1) : v_count_reg;
	end
	
	assign hsync_next = (h_count_next >= HPIXELS + HFP && h_count_next <= HPIXELS + HFP + HPULSE - 1);
	assign vsync_next = (v_count_next >= VPIXELS + VFP && v_count_next <= VPIXELS + VFP + VPULSE - 1);
	
	assign video_on = (h_count_reg < HPIXELS && v_count_reg < VPIXELS);
    assign x = h_count_reg;
    assign y = v_count_reg;
endmodule