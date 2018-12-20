// This module manages the content display.
// Author: Yibo Cao

module graph_content (
	input clk, is_drum,
	input [2:0] active_inst,
	input [2:0] drum_key,
	input [5:0] track,
	input [5:0] tile_ctr, tile_offset,
	input [23:0] wr_data,
	input [11:0] wr_addr,
	output logic out_active,
	output logic out_bdr_bottom,
	output logic out_bdr_top,
	output logic out_bdr_side,
	output logic [2:0] out_inst
);
	logic [23:0] data[0:49*64-1], rd_data;
	logic [11:0] rd_addr;
	always_ff @(posedge clk) begin
		data[wr_addr] <= wr_data;
		rd_data <= data[rd_addr];
	end
	
	always_comb begin
		rd_addr = (tile_ctr + tile_offset & 63) * 49 + (is_drum ? 48 : track);
		out_inst = 3'bX;
		out_bdr_bottom = 1'b0;
		out_bdr_top = 1'b0;
		out_bdr_side = 1'b0;
		if (is_drum) begin
			out_active = rd_data[drum_key * 3];
			out_bdr_bottom = rd_data[drum_key * 3 + 1];
			out_bdr_top = rd_data[drum_key * 3 + 2];
			out_bdr_side = 1'b1;
		end else begin
			out_active = rd_data[active_inst * 3];
			if (out_active) begin
				out_inst = active_inst;
				out_bdr_bottom = rd_data[active_inst * 3 + 1];
				out_bdr_top = rd_data[active_inst * 3 + 2];
				out_bdr_side = 1'b1;
			end else for (int i = 0; i < 8; ++i) begin
				if (rd_data[i * 3]) begin
					out_active = 1'b1;
					out_inst = i;
					break;
				end
			end
		end
	end
endmodule
