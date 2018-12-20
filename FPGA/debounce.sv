// debouncer.
// Cooldown is in milliseconds.
// Author: Yibo Cao

module debounce #(parameter COOLDOWN = 50) (
	input clk, rst, in,
	output logic out
);
	logic [22:0] cooldown;
	always_ff @(posedge clk)
		if (rst) begin
			cooldown <= 1'b0;
			out <= 1'b0;
		end else if (!cooldown) begin
			if (in != out)
				cooldown <= 23'(98000 * COOLDOWN - 1);
			out <= in;
		end else
			cooldown <= cooldown - 1'b1;
endmodule
