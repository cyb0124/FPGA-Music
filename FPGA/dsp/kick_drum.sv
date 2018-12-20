// Kick/tom drum synthesizer.
// Mode: 2'b00 = Kick
//       2'b01 = Low Tom
//       2'b10 = Middle Tom
//       2'b11 = High Tom
// Author: Yibo Cao

module kick_drum (
	// Control flow
	input clk, rst, start,
	output logic finish,
	
	// Shared multiplier
	input [63:0] mult_p,
	output logic [31:0] mult_a, mult_b,

	// Data
	input trigger,
	input [1:0] mode,
	output logic [23:0] wave_out
);
	logic [15:0] phase;
	logic [23:0] freq;
	logic [23:0] amp_sine, amp_noise;
	logic [23:0] wave_sine, wave_noise;
	logic [63:0] mix;
	
	logic phase_en;
	phase_integrator m1 (.*, .en(phase_en), .freq(mult_p[47:24]), .init(0));
	
	logic sine_start, sine_finish;
	logic [31:0] sine_mult_a, sine_mult_b;
	sine m2 (.*, .start(sine_start), .finish(sine_finish),
		.mult_a(sine_mult_a), .mult_b(sine_mult_b), .x(phase), .y(wave_sine));
	
	logic noise_en;
	white_noise m3 (.*, .en(noise_en),
		.seed(128'h76CD57BAAD420E080542114FD1BBD9B8), .wave_out(wave_noise));

	enum logic [3:0] {
		IDLE, BUBBLE_1, ENV_SINE, ENV_NOISE,
		OSCS, BUBBLE_2, FREQ_SCALE, BUBBLE_3, AMP_NOISE,
		SINE, BUBBLE_4, AMP_SINE, FINISH
	} state;
	always_ff @(posedge clk)
		if (rst) begin
			freq <= 24'd0;
			amp_sine <= 24'd0;
			amp_noise <= 24'd0;
			state <= IDLE;
		end else case (state)
			IDLE:
				if (start) begin
					if (trigger) begin
						freq <= 24'(1200 * 256);
						amp_sine <= 24'd16246673;
						amp_noise <= 24'd530542;
						state <= OSCS;
					end else begin
						if (freq > 24'(180 * 256))
							freq <= freq - 24'd544;
						else if (freq > 24'(80 * 256))
							freq <= freq - 24'd13;
						else if (freq > 24'(40 * 256))
							freq <= freq - 24'd21;
						state <= BUBBLE_1;
					end
				end
			BUBBLE_1:
				state <= ENV_SINE;
			ENV_SINE:
				begin
					amp_sine <= amp_sine > 24'd167772 ? mult_p[47:24] : 24'd0;
					state <= ENV_NOISE;
				end
			ENV_NOISE:
				begin
					amp_noise <= amp_noise > 24'd16777 ? mult_p[47:24] : 24'd0;
					state <= OSCS;
				end
			OSCS:
				state <= BUBBLE_2;
			BUBBLE_2:
				state <= FREQ_SCALE;
			FREQ_SCALE:
				state <= BUBBLE_3;
			BUBBLE_3:
				state <= AMP_NOISE;
			AMP_NOISE:
				begin
					mix <= mult_p;
					state <= SINE;
				end
			SINE:
				if (sine_finish)
					state <= BUBBLE_4;
			BUBBLE_4:
				state <= AMP_SINE;
			AMP_SINE:
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
		sine_start = 1'b0;
		wave_out = mix[47:24];
		
		case (state)
			IDLE:
				begin
					mult_a = 16775606;
					mult_b = amp_sine;
				end
			BUBBLE_1:
				begin
					mult_a = 16757107;
					mult_b = amp_noise;
				end
			OSCS:
				begin
					noise_en = 1'b1;
					mult_a = freq;
					case (mode)
						2'b00: mult_b = 16777216;
						2'b01: mult_b = 27962027;
						2'b10: mult_b = 39146837;
						2'b11: mult_b = 50331648;
					endcase
				end
			FREQ_SCALE:
				begin
					phase_en = 1'b1;
					mult_a = {{8{wave_noise[23]}}, wave_noise};
					mult_b = amp_noise;
				end
			SINE:
				if (sine_finish) begin
					mult_a = {{8{wave_sine[23]}}, wave_sine};
					mult_b = amp_sine;
				end else begin
					sine_start = 1'b1;
					mult_a = sine_mult_a;
					mult_b = sine_mult_b;
				end
			FINISH:
				finish = 1'b1;
		endcase
	end
endmodule
