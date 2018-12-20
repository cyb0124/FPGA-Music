// White noise generator (xorshift128)
// Author: Yibo Cao

module white_noise (
	input clk, rst, en,
	input [127:0] seed,
	output logic [23:0] wave_out
);
	logic [127:0] state, state_next;
	assign wave_out = state[23:0];
	
	always_ff @(posedge clk)
		if (rst)
			state <= seed;
		else if (en)
			state <= state_next;
	
	logic [63:0] a, b;
	always_comb begin
		{b, a} = state;
		a ^= a << 23;
		a ^= a >> 18;
		a ^= b;
		a ^= b >> 5;
		state_next = {a, b};
	end
endmodule
