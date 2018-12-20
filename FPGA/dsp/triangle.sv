// This module generates triangle wave.
// Input range: [0, 48000), which maps to [0, 2*pi)
// Output range: full 24-bit signed
// Author: Yibo Cao

module triangle (
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
	logic negated;
	logic [15:0] x_reg;
	
	enum logic [2:0] { IDLE, X, Y1, Y2, FINISH } state;
	always_ff @(posedge clk)
		if (rst)
			state <= IDLE;
		else case (state)
			IDLE:
				if (start) begin
					if (x < 16'd24000) begin
						negated <= 1'b0;
						x_reg <= x;
					end else begin
						negated <= 1'b1;
						x_reg <= x - 16'd24000;
					end
					state <= X;
				end
			X:
				state <= Y1;
			Y1:
				state <= Y2;
			Y2:
				begin
					y = mult_p[23:0];
					if (negated)
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
			X:
				begin
					mult_a = x_reg < 16'd12000 ? x_reg : (16'd24000 - x_reg);
					mult_b = 699;
				end
			FINISH:
				finish = 1'b1;
		endcase
	end
endmodule
