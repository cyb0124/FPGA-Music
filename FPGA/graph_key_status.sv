// This module manages the key status display.
// Author: Yibo Cao

module graph_key_status (
	input clk, is_drum,
	input [2:0] active_inst,
	input [2:0] drum_key,
	input [5:0] wr_addr, track,
	input [7:0] wr_data,
	output logic out_active,
	output logic [2:0] out_inst
);
	logic [7:0] data[0:48], rd_data;
	
	always_ff @(posedge clk) begin
		data[wr_addr] <= wr_data;
		rd_data <= data[is_drum ? 6'd48 : track];
	end
	
	always_comb begin
		if (is_drum) begin
			out_active = rd_data[drum_key];
			out_inst = 3'bX;
		end else begin
			out_active = |rd_data;
			if (rd_data[active_inst])
				out_inst = active_inst;
			else for (int i = 0; i < 8; ++i) begin
				out_inst = i;
				if (rd_data[i]) break;
			end
		end
	end
endmodule
