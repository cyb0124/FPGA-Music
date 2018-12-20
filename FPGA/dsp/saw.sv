// This module generates sawtooth wave.
// Input range: [0, 48000), which maps to [0, 2*pi)
// Output range: full 24-bit signed
// Author: Yibo Cao

module saw (
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
	logic shifted;
	logic [15:0] x_reg;

	enum logic [2:0] { IDLE, X, Y1, Y2, FINISH } state;
	always_ff @(posedge clk)
		if (rst)
			state <= IDLE;
		else case (state)
			IDLE:
				if (start) begin
					shifted = x >= 16'd24000;
					x_reg <= shifted ? x - 16'd24000 : x;
					state <= X;
				end
			X:
				state <= Y1;
			Y1:
				state <= Y2;
			Y2:
				begin
					y = mult_p[32:9];
					if (shifted)
						y = y - 24'd8388608;
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
			X:
				begin
					mult_a = x_reg;
					mult_b = 178956;
				end
			FINISH:
				finish = 1'b1;
		endcase
	end
endmodule
