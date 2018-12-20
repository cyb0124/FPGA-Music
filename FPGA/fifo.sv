// Standard (non-FWFT) FIFO queue
// Author: Yibo Cao

module fifo #(
	parameter DATA_WIDTH,
	parameter ADDR_WIDTH
) (
	input clk, rst, wr_en, rd_en,
	input [DATA_WIDTH-1:0] wr_data,
	output logic [DATA_WIDTH-1:0] rd_data,
	output wr_ready, rd_ready
);
	logic [DATA_WIDTH-1:0] data[0:2**ADDR_WIDTH-1];
	logic [ADDR_WIDTH-1:0] wr_addr, rd_addr;
	logic full;
	
	// Status logic
	assign wr_ready = ~full;
	assign rd_ready = full | (wr_addr != rd_addr);
	
	// Update logic
	always_ff @(posedge clk)
		if (rst) begin
			wr_addr <= 1'b0;
			rd_addr <= 1'b0;
			rd_data <= 1'b0;
			full <= 1'b0;
		end else begin
			if (wr_en) begin
				data[wr_addr] <= wr_data;
				wr_addr = wr_addr + 1'b1;
				if (wr_addr == rd_addr)
					full <= 1'b1;
			end
			if (rd_en) begin
				rd_data <= data[rd_addr];
				rd_addr <= rd_addr + 1'b1;
				full <= 1'b0;
			end
		end
endmodule
