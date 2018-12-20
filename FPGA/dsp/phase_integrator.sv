// This module integrates frequency into phase in the range [0, 48000),
// which can be used to generate periodic signals. The last 8 bits of
// frequency and phase initialization inputs are fractional bits.
// Author: Yibo Cao

module phase_integrator (
	input clk, rst, en,
	input [23:0] init, freq,
	output logic [15:0] phase
);
	logic [23:0] phase_fine;
	logic [24:0] phase_next;
	always_comb begin
		phase_next = {1'b0, phase_fine} + freq;
		if (phase_next > 25'(48000 * 256))
			phase_next = phase_next - 25'(48000 * 256);
		phase = phase_fine[23:8];
	end

	always_ff @(posedge clk)
		if (rst)
			phase_fine <= init;
		else if (en)
			phase_fine <= phase_next[23:0];
endmodule
