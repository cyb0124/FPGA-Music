// Hi-hat synthesizer.
// Author: Yibo Cao

module hi_hat (
	// Control flow
	input clk, rst, start,
	output logic finish,
	
	// Shared multiplier
	input [63:0] mult_p,
	output logic [31:0] mult_a, mult_b,

	// Data
	input trigger,
	output logic [23:0] wave_out
);
	logic is_attacking;
	logic [23:0] amp;
	logic [23:0] wave_noise;
	logic [31:0] filtered_noise;
	
	logic noise_en;
	white_noise m1 (.*, .en(noise_en),
		.seed(128'h96735746D6A3617A8442880131974785), .wave_out(wave_noise));

	logic biquad_start, biquad_finish;
	logic [31:0] biquad_mult_a, biquad_mult_b;
	biquad m2 (.*, .start(biquad_start), .finish(biquad_finish),
		.mult_a(biquad_mult_a), .mult_b(biquad_mult_b),
		.x({{8{wave_noise[23]}}, wave_noise}), .y(filtered_noise),
		.u(-21234402), .v(9988162), .a(11999945), .b(-23999890), .c(11999945));
	
	enum logic [2:0] { IDLE, BUBBLE_1, ENV, FILTER, BUBBLE_2, AMP, FINISH } state;
	always_ff @(posedge clk)
		if (rst) begin
			is_attacking <= 1'b0;
			amp <= 24'd0;
			state <= IDLE;
		end else case (state)
			IDLE:
				if (start) begin
					if (trigger) begin
						is_attacking <= 1'b1;
						amp <= 24'd8388;
						state <= FILTER;
					end else begin
						state <= BUBBLE_1;
					end
				end
			BUBBLE_1:
				state <= ENV;
			ENV:
				begin
					if (is_attacking) begin
						if (amp > 24'd8388608)
							is_attacking <= 1'b0;
						amp <= mult_p[47:24];
					end else
						amp <= amp > 24'd8388 ? mult_p[47:24] : 24'd0;
					state <= FILTER;
				end
			FILTER:
				if (biquad_finish)
					state <= BUBBLE_2;
			BUBBLE_2:
				state <= AMP;
			AMP:
				begin
					wave_out <= mult_p[47:24];
					state <= FINISH;
				end
			FINISH:
				state <= IDLE;
		endcase

	always_comb begin
		finish = 1'b0;
		mult_a = 32'bX;
		mult_b = 32'bX;
		noise_en = 1'b0;
		biquad_start = 1'b0;
		
		case (state)
			IDLE:
				if (start) begin
					noise_en = 1'b1;
					if (is_attacking)
						mult_a = 17020405;
					else
						mult_a = amp > 24'd83886 ? 16767750 : 16776556;
					mult_b = amp;
				end
			FILTER:
				if (biquad_finish) begin
					mult_a = filtered_noise;
					mult_b = amp;
				end else begin
					mult_a = biquad_mult_a;
					mult_b = biquad_mult_b;
					biquad_start = 1'b1;
				end
			FINISH:
				finish = 1'b1;
		endcase
	end
endmodule
