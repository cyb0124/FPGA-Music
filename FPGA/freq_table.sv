// Frequency to pitch lookup table.
// This can be inferred as ROM.
// Author: Yibo Cao

module freq_table (
	input clk,
	input [5:0] pitch,
	output logic [23:0] freq
);
	always_ff @(posedge clk) case (pitch)
		0: freq <= 33488;
		1: freq <= 35479;
		2: freq <= 37589;
		3: freq <= 39824;
		4: freq <= 42192;
		5: freq <= 44701;
		6: freq <= 47359;
		7: freq <= 50175;
		8: freq <= 53159;
		9: freq <= 56320;
		10: freq <= 59669;
		11: freq <= 63217;
		12: freq <= 66976;
		13: freq <= 70959;
		14: freq <= 75178;
		15: freq <= 79649;
		16: freq <= 84385;
		17: freq <= 89402;
		18: freq <= 94719;
		19: freq <= 100351;
		20: freq <= 106318;
		21: freq <= 112640;
		22: freq <= 119338;
		23: freq <= 126434;
		24: freq <= 133952;
		25: freq <= 141918;
		26: freq <= 150356;
		27: freq <= 159297;
		28: freq <= 168769;
		29: freq <= 178805;
		30: freq <= 189437;
		31: freq <= 200702;
		32: freq <= 212636;
		33: freq <= 225280;
		34: freq <= 238676;
		35: freq <= 252868;
		36: freq <= 267905;
		37: freq <= 283835;
		38: freq <= 300713;
		39: freq <= 318594;
		40: freq <= 337539;
		41: freq <= 357610;
		42: freq <= 378874;
		43: freq <= 401403;
		44: freq <= 425272;
		45: freq <= 450560;
		46: freq <= 477352;
		47: freq <= 505737;
		default: freq <= 24'bX;
	endcase
endmodule
