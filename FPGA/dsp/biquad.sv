// Biquad IIR filter.
// All numbers are signed and have exponent of -24.
// Author: Yibo Cao

module biquad (
	// Control flow
	input clk, rst, start,
	output logic finish,
	
	// Shared multiplier
	input [63:0] mult_p,
	output logic [31:0] mult_a, mult_b,
	
	// Data
	input [31:0] x, u, v, a, b, c,
	output logic [31:0] y
);
	logic [31:0] w1, w2;
	logic [63:0] s1, s2;
	
	enum logic [2:0] { IDLE, BUBBLE, W1, W2, W3Y1, Y2, Y3, FINISH } state;
	always_ff @(posedge clk)
		if (rst) begin
			w1 <= 32'd0;
			w2 <= 32'd0;
			state <= IDLE;
		end else case (state)
			IDLE:
				if (start)
					state <= BUBBLE;
			BUBBLE:
				state <= W1;
			W1:
				begin
					s1 <= mult_p;
					state <= W2;
				end
			W2:
				begin
					s1 <= s1 + mult_p;
					state <= W3Y1;
				end
			W3Y1:
				begin
					w2 <= w1;
					w1 <= x - s1[55:24];
					s2 <= mult_p;
					state <= Y2;
				end
			Y2:
				begin
					s2 <= s2 + mult_p;
					state <= Y3;
				end
			Y3:
				begin
					s2 <= s2 + mult_p;
					state <= FINISH;
				end
			FINISH:
				state <= IDLE;
		endcase
	
	always_comb begin
		mult_a = 32'bX;
		mult_b = 32'bX;
		finish = 1'b0;
		y = s2[55:24];
		
		case (state)
			IDLE:
				begin
					mult_a = u;
					mult_b = w1;
				end
			BUBBLE:
				begin
					mult_a = v;
					mult_b = w2;
				end
			W1:
				begin
					mult_a = b;
					mult_b = w1;
				end
			W2:
				begin
					mult_a = c;
					mult_b = w2;
				end
			W3Y1:
				begin
					mult_a = a;
					mult_b = x - s1[55:24];
				end
			FINISH:
				finish = 1'b1;
		endcase
	end
endmodule
