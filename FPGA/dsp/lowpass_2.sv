// 2-pole (-12 dB/oct) lowpass IIR filter.
// Cutoff is unsigned and has exponent of -8.
// Resonance is unsigned and has exponent of -16.
// x and y are signed and have exponent of -24.
// Author: Yibo Cao

`timescale 1ns/1ns

module lowpass_2 (
	// Control flow
	input clk, rst, start,
	output logic finish,
	
	// Shared multiplier
	input [63:0] mult_p,
	output logic [31:0] mult_a, mult_b,

	// Shared divider
	input [47:0] div_q,
	output logic [47:0] div_n, div_d,
	
	// Data
	input [23:0] cutoff,
	input [31:0] resonance, x,
	output logic [31:0] y
);
	logic [31:0] cutoff_radian; // unsigned -8
	logic [31:0] cutoff_square; // unsigned +4
	logic [31:0] term_v;        // unsigned +4
	logic [31:0] inv_scale;     // unsigned -52
	logic [63:0] c1, c2, c3;    // signed -48
	logic biquad_start;
	logic [31:0] biquad_mult_a, biquad_mult_b;
	biquad m1 (.*, .start(biquad_start),
		.mult_a(biquad_mult_a), .mult_b(biquad_mult_b),
		.u(c2[54:23]), .v(c3[55:24]), .a(c1[55:24]), .b(c1[54:23]), .c(c1[55:24]));

	enum logic [3:0] {
		IDLE, BUBBLE_1, RADIAN, BUBBLE_2, TWO_FS, SQUARE,
		WAIT_DIV_1, WAIT_DIV_2, BUBBLE_3, C1, C2, C3, BIQUAD
	} state;
	logic [4:0] counter;
	always_ff @(posedge clk)
		if (rst)
			state <= IDLE;
		else case (state)
			IDLE:
				if (start)
					state <= BUBBLE_1;
			BUBBLE_1:
				state <= RADIAN;
			RADIAN:
				begin
					cutoff_radian <= mult_p[59:28];
					state <= BUBBLE_2;
				end
			BUBBLE_2:
				state <= TWO_FS;
			TWO_FS:
				state <= SQUARE;
			SQUARE:
				begin
					cutoff_square <= mult_p[51:20];
					state <= WAIT_DIV_1;
					counter <= 5'd28;
				end
			WAIT_DIV_1:
				begin
					if (!counter) begin
						term_v <= div_q[31:0];
						state <= WAIT_DIV_2;
						counter <= 5'd29;
					end else
						counter <= counter - 5'd1;
				end
			WAIT_DIV_2:
				begin
					if (!counter) begin
						inv_scale <= div_q[31:0];
						state <= BUBBLE_3;
					end else
						counter <= counter - 4'd1;
				end
			BUBBLE_3:
				state <= C1;
			C1:
				begin
					c1 <= mult_p;
					state <= C2;
				end
			C2:
				begin
					c2 <= mult_p;
					state <= C3;
				end
			C3:
				begin
					c3 <= mult_p;
					state <= BIQUAD;
				end
			BIQUAD:
				if (finish)
					state <= IDLE;
		endcase

	always_comb begin
		mult_a = 32'bX;
		mult_b = 32'bX;
		div_n = 48'bX;
		div_d = 48'bX;
		biquad_start = 1'b0;
		
		case (state)
			IDLE:
				begin
					mult_a = cutoff;
					mult_b = 1686629713; // 2 * pi
				end
			RADIAN:
				begin
					mult_a = mult_p[59:28];
					mult_b = 48000 * 2;
				end
			BUBBLE_2:
				begin
					mult_a = cutoff_radian;
					mult_b = cutoff_radian;
				end
			TWO_FS:
				begin
					div_n = {mult_p[43:12], 16'b0};
					div_d = resonance;
				end
			WAIT_DIV_1:
				begin
					div_n = 48'hFFFFFFFFFFFF;
					div_d = 576000000 + div_q[31:0] + cutoff_square;
				end
			WAIT_DIV_2:
				begin
					mult_a = div_q[31:0];
					mult_b = cutoff_square;
				end
			BUBBLE_3:
				begin
					mult_a = inv_scale;
					mult_b = cutoff_square - 576000000;
				end
			C1:
				begin
					mult_a = inv_scale;
					mult_b = cutoff_square + 576000000 - term_v;
				end
			BIQUAD:
				begin
					biquad_start = 1'b1;
					mult_a = biquad_mult_a;
					mult_b = biquad_mult_b;
				end
		endcase
	end
endmodule

module lowpass_2_testbench ();
	logic clk, rst, start, finish;
	logic [63:0] mult_p;
	logic [31:0] mult_a, mult_b;
	logic [47:0] div_q, div_n, div_d;
	logic [23:0] cutoff;
	logic [31:0] resonance, x, y, y_reg;
	
	shared_mult m1 (.*, .a(mult_a), .b(mult_b), .p(mult_p));
	shared_div m2 (.*, .n(div_n), .d(div_d), .q(div_q));
	lowpass_2 dut (.*);
	
	// Clock
	initial clk = 1'b0;
	always begin #10; clk <= ~clk; end
	
	// Testing
	assign resonance = 2 << 16;
	initial begin
		rst = 1'b1;
		start = 1'b0;
		@(negedge clk);
		rst = 1'b0;
		
		for (int i = 0; i < 48000; ++i) begin
			x = (i % 100) < 50 ? 1048576 : -1048576;
			cutoff = 24'((200 + i / 3) * 256);
			start = 1'b1;
			while (!finish)
				@(negedge clk);
			y_reg <= y;
			start = 1'b0;
			@(negedge clk);
		end
		$stop;
	end
endmodule
