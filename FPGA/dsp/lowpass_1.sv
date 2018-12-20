// 1-pole (-6 dB/oct) lowpass IIR filter.
// Cutoff is unsigned and has exponent of -8.
// x and y are signed and have exponent of -24.
// Author: Yibo Cao

module lowpass_1 (
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
	input [31:0] x,
	output logic [31:0] y
);
	logic [31:0] cutoff_radian; // unsigned -8
	logic [31:0] inv_scale;     // unsigned -40
	logic [63:0] c1, c2;        // signed -48
	logic biquad_start;
	logic [31:0] biquad_mult_a, biquad_mult_b;
	biquad m1 (.*, .start(biquad_start),
		.mult_a(biquad_mult_a), .mult_b(biquad_mult_b),
		.u(c1[54:23]), .v(c2[55:24]), .a(c1[55:24]), .b(c1[54:23]), .c(c1[55:24]));
	
	enum logic [3:0] {
		IDLE, BUBBLE_1, RADIAN, RECIP_1, RECIP_2, BUBBLE_2, C1, C2, BIQUAD
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
					state <= RECIP_1;
				end
			RECIP_1:
				begin
					counter <= 5'd29;
					state <= RECIP_2;
				end
			RECIP_2:
				begin
					if (!counter) begin
						inv_scale <= div_q[31:0];
						state <= BUBBLE_2;
					end
					counter <= counter - 5'd1;
				end
			BUBBLE_2:
				state <= C1;
			C1:
				begin
					c1 <= mult_p;
					state <= C2;
				end
			C2:
				begin
					c2 <= mult_p;
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
			RECIP_1:
				begin
					div_n = 48'hFFFFFFFFFFFF;
					div_d = cutoff_radian + 32'(48000 * 2 * 256);
				end
			RECIP_2:
				if (!counter) begin
					mult_a = cutoff_radian;
					mult_b = div_q[31:0];
				end
			BUBBLE_2:
				begin
					mult_a = cutoff_radian - 32'(48000 * 2 * 256);
					mult_b = inv_scale;
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
