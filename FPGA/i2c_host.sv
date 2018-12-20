// An I2C host with clock-stretching support
// Author: Yibo Cao

module i2c_host (
	input  clk, rst, start, stop, write, read,
	input  [7:0] wr_data,
	output logic [7:0] rd_data,
	output logic done, ack,
	inout  sda, scl
);
	// I/O
	logic sda_in, sda_out;
	logic scl_in, scl_out;
	sync i1 (.clk, .in(sda), .out(sda_in));
	sync i2 (.clk, .in(scl), .out(scl_in));
	assign sda = sda_out ? 1'bZ : 1'b0;
	assign scl = scl_out ? 1'bZ : 1'b0;

	// Clock generator
	localparam QUARTER_PERIOD = 8'd245;
	enum logic [2:0] {
		CG_HIGH, CG_DOWN_1, CG_DOWN_2,
		CG_LOW, CG_UP_1, CG_UP_2
	} cg_state;
	logic cg_transit, cg_done;
	logic [7:0] cg_ctr;
	always_ff @(posedge clk)
		if (rst) begin
			cg_state <= CG_HIGH;
			cg_done <= 1'b0;
			cg_ctr <= 1'b0;
			scl_out <= 1'b1;
		end else case (cg_state)
			CG_HIGH:
				begin
					cg_done <= 1'b0;
					if (cg_transit) cg_state <= CG_DOWN_1;
				end
			CG_DOWN_1:
				if (cg_ctr == QUARTER_PERIOD - 1'b1) begin
					scl_out <= 1'b0;
					cg_state <= CG_DOWN_2;
					cg_ctr <= 1'b0;
				end else 
					cg_ctr <= cg_ctr + 1'b1;
			CG_DOWN_2:
				if (cg_ctr == QUARTER_PERIOD - 1'b1) begin
					cg_state <= CG_LOW;
					cg_done <= 1'b1;
					cg_ctr <= 1'b0;
				end else 
					cg_ctr <= cg_ctr + 1'b1;
			CG_LOW:
				begin
					cg_done <= 1'b0;
					if (cg_transit) cg_state <= CG_UP_1;
				end
			CG_UP_1:
				if (cg_ctr == QUARTER_PERIOD - 1'b1) begin
					scl_out <= 1'b1;
					cg_state <= CG_UP_2;
					cg_ctr <= 1'b0;
				end else 
					cg_ctr <= cg_ctr + 1'b1;
			CG_UP_2:
				if (scl_in)
					if (cg_ctr == QUARTER_PERIOD - 1'b1) begin
						cg_state <= CG_HIGH;
						cg_done <= 1'b1;
						cg_ctr <= 1'b0;
					end else 
						cg_ctr <= cg_ctr + 1'b1;
		endcase

	// Controller
	enum logic [3:0] {
		C_IDLE, C_START_1, C_START_2, C_STOP_1, C_STOP_2,
		C_WRITE_1, C_WRITE_2, C_WRITE_3, C_READ_1, C_READ_2, C_READ_3
	} c_state;
	logic [6:0] c_ctr;
	logic [7:0] c_data;
	always_ff @(posedge clk)
		if (rst) begin
			c_state <= C_IDLE;
			c_ctr <= 1'b0;
			sda_out <= 1'b1;
			done <= 1'b0;
		end else case (c_state)
			C_IDLE:
				begin
					done <= 1'b0;
					if (start) c_state <= C_START_1;
					if (stop) begin
						c_state <= C_STOP_1;
						cg_transit <= 1'b1;
						sda_out <= 1'b0;
					end
					if (write) begin
						c_state <= C_WRITE_1;
						c_data <= wr_data;
					end
					if (read) begin
						c_state <= C_READ_1;
						sda_out <= 1'b1;
					end
				end
			C_START_1:
				begin
					c_ctr <= c_ctr + 1'b1;
					if (c_ctr == 7'h7F) begin
						c_state <= C_START_2;
						cg_transit <= 1'b1;
						sda_out <= 1'b0;
					end
				end
			C_START_2:
				begin
					cg_transit <= 1'b0;
					if (cg_done) begin
						c_state <= C_IDLE;
						done <= 1'b1;
					end
				end
			C_STOP_1:
				begin
					cg_transit <= 1'b0;
					if (cg_done) begin
						c_state <= C_STOP_2;
						sda_out <= 1'b1;
					end
				end
			C_STOP_2:
				begin
					c_ctr <= c_ctr + 1'b1;
					if (c_ctr == 7'h7F) begin
						c_state <= C_IDLE;
						done <= 1'b1;
					end
				end
			C_WRITE_1:
				begin
					sda_out <= c_data[7];
					c_data <= {c_data[6:0], 1'b1};
					c_ctr <= c_ctr + 1'b1;
					cg_transit <= 1'b1;
					c_state <= C_WRITE_2;
				end
			C_WRITE_2:
				if (cg_done) begin
					cg_transit <= 1'b1;
					c_state <= C_WRITE_3;
					if (c_ctr == 7'h9)
						ack <= ~sda_in;
				end else
					cg_transit <= 1'b0;
			C_WRITE_3:
				begin
					cg_transit <= 1'b0;
					if (cg_done)
						if (c_ctr == 7'h9) begin
							c_ctr <= 1'b0;
							done <= 1'b1;
							c_state <= C_IDLE;
						end else
							c_state <= C_WRITE_1;
				end
			C_READ_1:
				begin
					c_ctr <= c_ctr + 1'b1;
					cg_transit <= 1'b1;
					c_state <= C_READ_2;
				end
			C_READ_2:
				if (cg_done) begin
					if (c_ctr == 7'h9)
						ack <= ~sda_in;
					else
						rd_data <= {sda_in, rd_data[7:1]};
					cg_transit <= 1'b1;
					c_state <= C_READ_3;
				end else
					cg_transit <= 1'b0;
			C_READ_3:
				begin
					cg_transit <= 1'b0;
					if (cg_done)
						if (c_ctr == 7'h9) begin
							c_ctr <= 1'b0;
							done <= 1'b1;
							c_state <= C_IDLE;
						end else
							c_state <= C_READ_1;
				end
		endcase
endmodule
