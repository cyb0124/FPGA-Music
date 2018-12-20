// Generate the clock for WM8731.
// Author: Yibo Cao

module audio_clock (
	input clk_in, rst_in,
	output clk_aud, rst_out
);
	logic lck_aud;

	// 48 kHz * 384 = 18.432 MHz
	altera_pll #(
		.fractional_vco_multiplier("true"),
		.reference_clock_frequency("50 MHz"),
		.output_clock_frequency0("18.432 MHz")
	) pll_aud (
		.refclk(clk_in), .rst(rst_in), .fbclk(1'b0),
		.outclk(clk_aud), .locked(lck_aud), .fboutclk()
	);

	// Keep resetting until PLL is locked.
	sync m1 (.clk(clk_in), .in(rst_in | ~lck_aud), .out(rst_out));
endmodule
