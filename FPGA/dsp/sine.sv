// This module approximates sine wave using parabola.
// Input range: [0, 48000), which maps to [0, 2*pi)
// Output range: full 24-bit signed
// Author: Yibo Cao

module sine (
	// Control flow
	input clk, rst, start,
	output logic finish,
	
	// Shared multiplier
	input [63:0] mult_p,
	output logic [31:0] mult_a, mult_b,
	
	// Data
	input [15:0] x,
	output logic [23:0] y
);
	logic should_negate;
	logic [15:0] x_internal;
	
	enum logic [2:0] { IDLE, X1, X2, X3, Y1, Y2, FINISH } state;
	always_ff @(posedge clk)
		if (rst)
			state <= IDLE;
		else case (state)
			IDLE:
				if (start) begin
					should_negate = x >= 16'd24000;
					x_internal <= should_negate ? x - 16'd24000 : x;
					state <= X1;
				end
			X1:
				state <= X2;
			X2:
				state <= X3;
			X3:
				state <= Y1;
			Y1:
				state <= Y2;
			Y2:
				begin
					y = mult_p[55:32];
					if (should_negate)
						y = -y;
					state <= FINISH;
				end
			FINISH:
				state <= IDLE;
		endcase
	
	always_comb begin
		mult_a = 32'bX;
		mult_b = 32'bX;
		finish = 1'b0;
		
		case (state)
			X1:
				begin
					mult_a = x_internal;
					mult_b = 16'd24000 - x_internal;
				end
			X3:
				begin
					mult_a = mult_p[31:0];
					mult_b = 250199950;
				end
			FINISH:
				finish = 1'b1;
		endcase
	end
endmodule
