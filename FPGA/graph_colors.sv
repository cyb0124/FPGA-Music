// This module defines color of each instrument.
// Author: Yibo Cao

module graph_colors (
	input [2:0] inst,
	output logic [23:0] color
);
	always_comb case (inst)
		8'h0: color = 24'hFFCF70; // LtOrange
		8'h1: color = 24'h77FF70; // LtGreen
		8'h2: color = 24'hF44141; // Red
		8'h3: color = 24'h4286F4; // Blue
		8'h4: color = 24'hB241F4; // Purple
		8'h5: color = 24'hF49741; // Orange
		8'h6: color = 24'h41F4F4; // Cyan
		8'h7: color = 24'h09BA00; // Green
	endcase
endmodule
