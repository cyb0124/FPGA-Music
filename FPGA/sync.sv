// 2-DFF synchronizer for clock domain crossing
// Author: Yibo Cao

module sync (input clk, in, output logic out);
	logic buffer;
	always_ff @(posedge clk) begin
		buffer <= in;
		out <= buffer;
	end
endmodule
