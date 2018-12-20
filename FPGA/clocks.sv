// Generate clocks for the main design and peripheral devices.
// Author: Yibo Cao

module clocks (
	input clk_in, rst_in,
	output clk_main, clk_aud, rst_out
);
	logic lck_main, lck_aud;
	
	// Main: use PLL to generate 98 MHz.
	altera_pll #(
		.reference_clock_frequency("50 MHz"),
		.output_clock_frequency0("98 MHz")
	) pll_main (
		.refclk(clk_in), .rst(rst_in), .fbclk(1'b0),
		.outclk(clk_main), .locked(lck_main), .fboutclk()
	);

	// Audio: use PLL to generate 48 kHz * 384 = 18.432 MHz for WM8731.
	altera_pll #(
		.fractional_vco_multiplier("true"),
		.reference_clock_frequency("50 MHz"),
		.output_clock_frequency0("18.432 MHz")
	) pll_aud (
		.refclk(clk_in), .rst(rst_in), .fbclk(1'b0),
		.outclk(clk_aud), .locked(lck_aud), .fboutclk()
	);

	// Keep resetting until all PLLs are locked.
	sync m1 (
		.clk(clk_main),
		.in(rst_in | ~lck_aud | ~lck_main),
		.out(rst_out));
endmodule
