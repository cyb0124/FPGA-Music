// Snare drum synthesizer.
// Author: Yibo Cao

module snare_drum (
	// Control flow
	input clk, rst, start,
	output logic finish,
	
	// Shared multiplier
	input [63:0] mult_p,
	output logic [31:0] mult_a, mult_b,

	// Shared divider
	input [47:0] div_q,
	output logic [47:0] div_n, div_d,

	// Data
	input trigger,
	output logic [23:0] wave_out
);
	logic [15:0] phase;
	logic [23:0] freq, cutoff;
	logic [23:0] amp_tri, amp_noise;
	logic [23:0] wave_tri, wave_noise;
	logic [31:0] wave_noise_filtered;
	logic [63:0] mix;
	enum logic [1:0] {ATTACK, HOLD, DECAY} tri_region;
	logic [9:0] hold_counter;
	logic noise_attack;
	
	logic phase_en;
	phase_integrator m1 (.*, .en(phase_en), .init(0));
	
	logic tri_start, tri_finish;
	logic [31:0] tri_mult_a, tri_mult_b;
	triangle m2 (.*, .start(tri_start), .finish(tri_finish), .x(phase), .y(wave_tri),
		.mult_a(tri_mult_a), .mult_b(tri_mult_b));
	
	logic noise_en;
	white_noise m3 (.*, .en(noise_en),
		.seed(128'h1701D6F0C7735EC8D340A50F64125AD6), .wave_out(wave_noise));
	
	logic lpf_start, lpf_finish;
	logic [31:0] lpf_mult_a, lpf_mult_b;
	lowpass_1 m4 (.*, .start(lpf_start), .finish(lpf_finish),
		.mult_a(lpf_mult_a), .mult_b(lpf_mult_b),
		.x({{8{wave_noise[23]}}, wave_noise}), .y(wave_noise_filtered));
	
	enum logic [3:0] {
		IDLE, BUBBLE_1, ENV_TRI, ENV_NOISE,
		OSCS, TRI, FILTER, BUBBLE_2,
		TRI_AMP, NOISE_AMP, FINISH
	} state;
	always_ff @(posedge clk)
		if (rst) begin
			freq <= 24'd0;
			cutoff  <= 24'(400 * 256);
			amp_tri <= 24'd0;
			amp_noise <= 24'd0;
			tri_region <= DECAY;
			noise_attack <= 1'b0;
			state <= IDLE;
		end else case (state)
			IDLE:
				if (start) begin
					if (trigger) begin
						freq <= 24'(9000 * 256);
						cutoff <= 24'(20000 * 256);
						amp_tri <= 24'd8388;
						amp_noise <= 24'd8388;
						tri_region <= ATTACK;
						hold_counter <= 10'd0;
						noise_attack <= 1'b1;
						state <= OSCS;
					end else begin
						// Frequency of the triangle wave.
						if (freq > 24'(800 * 256))
							freq <= freq - 24'd4373;
						else if (freq > 24'(200 * 256))
							freq <= freq - 24'd160;
						else
							freq <= 24'(200 * 256);
						
						// Cutoff frequency of the filter.
						if (cutoff > 24'(10000 * 256))
							cutoff <= cutoff - 24'd533;
						else if (cutoff > 24'(8000 * 256))
							cutoff <= cutoff - 24'd107;
						else if (cutoff > 24'(400 * 256))
							cutoff <= cutoff - 24'd405;
						else
							cutoff <= 24'(400 * 256);
						
						state <= BUBBLE_1;
					end
				end
			BUBBLE_1:
				state <= ENV_TRI;
			ENV_TRI:
				begin
					case (tri_region)
						ATTACK:
							begin
								tri_region <= (amp_tri <= 24'd8388608) ? ATTACK : HOLD;
								amp_tri <= mult_p[47:24];
							end
						HOLD:
							begin
								if (hold_counter == 10'd960) tri_region <= DECAY;
								hold_counter <= hold_counter + 10'd1;
								amp_tri <= 24'd8388608;
							end
						DECAY:
							begin
								if (amp_tri > 24'd83886)
									amp_tri <= mult_p[47:24];
								else
									amp_tri <= 10'd0;
							end
					endcase
					state <= ENV_NOISE;
				end
			ENV_NOISE:
				begin
					if (noise_attack) begin
						if (amp_noise > 24'd8388608)
							noise_attack <= 1'b0;
						amp_noise <= mult_p[47:24];
					end else begin
						amp_noise <= amp_noise > 24'd8388 ? mult_p[47:24] : 24'd0;
					end
					state <= OSCS;
				end
			OSCS:
				state <= TRI;
			TRI:
				if (tri_finish)
					state <= FILTER;
			FILTER:
				if (lpf_finish)
					state <= BUBBLE_2;
			BUBBLE_2:
				state <= TRI_AMP;
			TRI_AMP:
				begin
					mix <= mult_p;
					state <= NOISE_AMP;
				end
			NOISE_AMP:
				begin
					mix <= mix + mult_p;
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
		phase_en = 1'b0;
		tri_start = 1'b0;
		lpf_start = 1'b0;
		wave_out = mix[48:25];
		
		case (state)
			IDLE:
				begin
					mult_a = tri_region == ATTACK ? 17020404 : 16763808;
					mult_b = amp_tri;
				end
			BUBBLE_1:
				begin
					if (noise_attack)
						mult_a = amp_noise < 24'd3339565 ? 16882168 : 16793320;
					else
						mult_a = amp_noise > 24'd265271 ? 16769673 : 16765148;
					mult_b = amp_noise;
				end
			OSCS:
				begin
					noise_en = 1'b1;
					phase_en = 1'b1;
				end
			TRI:
				begin
					mult_a = tri_mult_a;
					mult_b = tri_mult_b;
					tri_start = 1'b1;
				end
			FILTER:
				if (lpf_finish) begin
					mult_a = {{8{wave_tri[23]}}, wave_tri};
					mult_b = amp_tri;
				end else begin
					mult_a = lpf_mult_a;
					mult_b = lpf_mult_b;
					lpf_start = 1'b1;
				end
			BUBBLE_2:
				begin
					mult_a = wave_noise_filtered;
					mult_b = amp_noise;
				end
			FINISH:
				finish = 1'b1;
		endcase
	end
endmodule
