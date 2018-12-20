// A divider to be serialized and shared by many module instances.
// Pipeline latency: 30 cycles.
// Author: Yibo Cao

module shared_div (
	input clk,
	input [47:0] n, d,
	output [47:0] q
);
	lpm_divide #(
		.lpm_pipeline(30),
		.lpm_widthn(48),
		.lpm_widthd(48),
		.lpm_hint("LPM_REMAINDERPOSITIVE=FALSE")
	) m1 (.clock(clk), .numer(n), .denom(d),
		.quotient(q), .remain(), .aclr(1'b0), .clken(1'b1));
endmodule
