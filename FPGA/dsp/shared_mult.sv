// A multiplier to be serialized and shared by many module instances.
// Pipeline latency: 2 cycles.
// Author: Yibo Cao

module shared_mult (
	input clk,
	input [31:0] a, b,
	output [63:0] p
);
	lpm_mult #(
		.lpm_pipeline(2),
		.lpm_widtha(32),
		.lpm_widthb(32),
		.lpm_widthp(64),
		.lpm_representation("SIGNED"),
		.lpm_hint("MAXIMIZE_SPEED=9")
	) m (.clock(clk), .dataa(a), .datab(b), .result(p),
		.aclr(1'b0), .clken(1'b1), .sclr(1'b0), .sum(1'b0));
endmodule
