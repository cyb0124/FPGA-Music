// Delay (echo) effect.
// Author: Yibo Cao

module delay #(
	parameter LENGTH = 4800 * 2,
	parameter FEEDBACK = 128 // (-8)
) (
	// Control flow
	input clk, rst, start,
	output logic finish,
	
	// Shared multiplier
	input [63:0] mult_p,
	output logic [31:0] mult_a, mult_b,
	
	// Data
	input [23:0] in,
	output logic [23:0] out
);
	localparam ADDR_WIDTH = $clog2(LENGTH + 1);
	logic wr_en, rd_en;
	logic [23:0] rd_data;
	fifo #(.DATA_WIDTH(24), .ADDR_WIDTH(ADDR_WIDTH)) m1 (
		.*, .wr_data(out), .rd_ready(), .wr_ready());
	
	logic [ADDR_WIDTH-1:0] present_length;
	enum logic [2:0] { IDLE, READ, S_1, S_2, FINISH } state;
	always_ff @(posedge clk)
		if (rst) begin
			present_length <= 1'b0;
			state <= IDLE;
		end else case (state)
			IDLE:
				if (start) begin
					out <= in;
					if (present_length == LENGTH)
						state <= READ;
					else begin
						present_length <= present_length + 1'b1;
						state <= FINISH;
					end
				end
			READ:
				state <= S_1;
			S_1:
				state <= S_2;
			S_2:
				begin
					out <= out + mult_p[31:8];
					state <= FINISH;
				end
			FINISH:
				state <= IDLE;
		endcase
	
	always_comb begin
		mult_a = 32'bX;
		mult_b = 32'bX;
		rd_en = 1'b0;
		wr_en = 1'b0;
		finish = 1'b0;
		
		case (state)
			IDLE:
				if (start && present_length == LENGTH)
					rd_en = 1'b1;
			READ:
				begin
					mult_a = FEEDBACK;
					mult_b = {{8{rd_data[23]}}, rd_data};
				end
			FINISH:
				begin
					wr_en = 1'b1;
					finish = 1'b1;
				end
		endcase
	end
endmodule
