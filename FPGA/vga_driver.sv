// VGA driver.
// Author: Yibo Cao

module vga_driver (
	input clk, rst,
	input [23:0] color,
	output logic new_col, new_row, new_frame,
	// Outputs to the VGA port.
	output logic [7:0] VGA_R, VGA_G, VGA_B,
	output logic VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N
);
	// Constants for VGA timing.
	// The screen is a non-standard 1024x600 screen.
	// These values are found by trial and error.
	localparam HPX = 11'd1024, HFP = 11'd15, HSP = 11'd104, HBP = 11'd169;
	localparam VLN = 10'd600,  VFP = 10'd0,  VSP = 10'd1,   VBP = 10'd22;
	localparam HTOTAL = HPX + HFP + HSP + HBP;
	localparam VTOTAL = VLN + VFP + VSP + VBP;

	// Generate the clock
	always_ff @(posedge clk)
		if (rst) VGA_CLK <= 1'b0;
		else VGA_CLK <= ~VGA_CLK;

	// Horizontal counter.
	logic [10:0] h_count;
	logic end_of_line;
	assign end_of_line = h_count == HTOTAL - 1'b1;
	always_ff @(posedge clk)
		if (rst) h_count <= 1'b0;
		else if (VGA_CLK)
			if (end_of_line) h_count <= 1'b0;
			else h_count <= h_count + 1'b1;

	// Vertical counter
	logic [9:0] v_count;
	logic end_of_field;
	assign end_of_field = v_count == VTOTAL - 1'b1;
	always_ff @(posedge clk)
		if (rst)
			v_count <= 1'b0;
		else if (VGA_CLK & end_of_line)
			if (end_of_field)
				v_count <= 1'b0;
			else
				v_count <= v_count + 1'b1;

	// Sync signals.
	logic blank, h_sync, v_sync;
	assign blank = h_count >= HPX || v_count >= VLN;
	assign h_sync = h_count - (HPX + HFP) < HSP;
	assign v_sync = v_count - (VLN + VFP) < VSP;
	assign VGA_SYNC_N = 1; // Unused by VGA
	always_ff @(posedge clk)
		if (VGA_CLK) begin
			VGA_HS <= ~h_sync;
			VGA_VS <= v_sync;
			VGA_BLANK_N <= ~blank;
		end

	// Status signals.
	assign new_col = VGA_CLK;
	assign new_row = new_col & end_of_line;
	assign new_frame = new_row & end_of_field;

	// Data signals.
	always_ff @(posedge clk)
		if (VGA_CLK) {VGA_R, VGA_G, VGA_B} <= color;
endmodule
