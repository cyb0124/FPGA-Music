// This module manages the start / stop events and
// 	the mixing of all synthesizers.
// Author: Yibo Cao

module synthesizers (
	input clk, rst, next_sample,
	input [5:0] key_status_wr_addr,
	input [7:0] key_status_wr_data,
	output logic [23:0] wave_out
);
	logic [31:0] mixed;
	assign wave_out = mixed[24:1];

	// Shared DSP modules.
	logic [31:0] mult_a, mult_b;
	logic [47:0] div_n, div_d, div_q;
	logic [63:0] mult_p;
	shared_mult m1 (.*, .a(mult_a), .b(mult_b), .p(mult_p));
	shared_div m2 (.*, .n(div_n), .d(div_d), .q(div_q));

	// Key press / release detection.
	logic [5:0] pitch;
	logic [23:0] freq;
	logic [7:0] key_states[0:48], old_insts, new_insts;
	logic [7:0] key_presses, key_releases, tonal_presses, tonal_releases;
	always_ff @(posedge clk)
		if (rst) begin
			old_insts <= 8'b0;
			new_insts <= 8'b0;
		end else begin
			pitch <= key_status_wr_addr;
			old_insts <= key_states[key_status_wr_addr];
			new_insts <= key_status_wr_data;
			key_states[key_status_wr_addr] <= key_status_wr_data;
		end
	freq_table m3 (.*, .pitch(key_status_wr_addr));
	assign key_presses = new_insts & ~old_insts;
	assign key_releases = old_insts & ~new_insts;
	assign tonal_presses = (pitch == 6'd48) ? 8'b0 : key_presses;
	assign tonal_releases = (pitch == 6'd48) ? 8'b0 : key_releases;
	
	// Drum synthesizer instances.
	logic kick_start, kick_finish, kick_trigger, kick_trigger_reg;
	logic [1:0] kick_mode, kick_mode_reg;
	logic [31:0] kick_mult_a, kick_mult_b;
	logic [23:0] kick_wave;
	kick_drum drum_1 (.*, .start(kick_start), .finish(kick_finish), .trigger(kick_trigger_reg),
		.mode(kick_mode_reg), .mult_a(kick_mult_a), .mult_b(kick_mult_b), .wave_out(kick_wave));

	logic snare_start, snare_finish, snare_trigger, snare_trigger_reg;
	logic [31:0] snare_mult_a, snare_mult_b;
	logic [47:0] snare_div_n, snare_div_d;
	logic [23:0] snare_wave;
	snare_drum drum_2 (.*, .start(snare_start), .finish(snare_finish), .trigger(snare_trigger_reg),
		.mult_a(snare_mult_a), .mult_b(snare_mult_b), .wave_out(snare_wave),
		.div_n(snare_div_n), .div_d(snare_div_d));
	
	logic hat_start, hat_finish, hat_trigger, hat_trigger_reg;
	logic [31:0] hat_mult_a, hat_mult_b;
	logic [23:0] hat_wave;
	hi_hat drum_3 (.*, .start(hat_start), .finish(hat_finish), .trigger(hat_trigger_reg),
		.mult_a(hat_mult_a), .mult_b(hat_mult_b), .wave_out(hat_wave));
	
	// Tonal synthesizer instances.
	logic saw_start, saw_finish;
	logic [31:0] saw_mult_a, saw_mult_b;
	logic [47:0] saw_div_n, saw_div_d;
	logic [23:0] saw_wave;
	saw_lead_poly tonal_1 (.*, .start(saw_start), .finish(saw_finish),
		.key_press(tonal_presses[0]), .key_release(tonal_releases[0]), .wave_out(saw_wave),
		.mult_a(saw_mult_a), .mult_b(saw_mult_b), .div_n(saw_div_n), .div_d(saw_div_d));
		
	logic super_start, super_finish;
	logic [31:0] super_mult_a, super_mult_b;
	logic [23:0] super_wave;
	super_saw_poly tonal_2 (.*, .start(super_start), .finish(super_finish),
		.key_press(tonal_presses[1]), .key_release(tonal_releases[1]), .wave_out(super_wave),
		.mult_a(super_mult_a), .mult_b(super_mult_b));
		
	logic bass_start, bass_finish;
	logic [31:0] bass_mult_a, bass_mult_b;
	logic [47:0] bass_div_n, bass_div_d;
	logic [23:0] bass_wave;
	saw_bass_mono tonal_3 (.*, .start(bass_start), .finish(bass_finish),
		.key_press(tonal_presses[2]), .key_release(tonal_releases[2]), .wave_out(bass_wave),
		.mult_a(bass_mult_a), .mult_b(bass_mult_b), .div_n(bass_div_n), .div_d(bass_div_d));
		
	logic squ_start, squ_finish;
	logic [31:0] squ_mult_a, squ_mult_b;
	logic [47:0] squ_div_n, squ_div_d;
	logic [23:0] squ_wave;
	square_delay_poly tonal_4 (.*, .start(squ_start), .finish(squ_finish),
		.key_press(tonal_presses[3]), .key_release(tonal_releases[3]), .wave_out(squ_wave),
		.mult_a(squ_mult_a), .mult_b(squ_mult_b), .div_n(squ_div_n), .div_d(squ_div_d));

	// Main state machine.
	enum logic [3:0] {
		IDLE, KICK,
		SNARE, SNARE_BUBBLE, SNARE_MIX,
		HAT, HAT_BUBBLE, HAT_MIX,
		SAW, SUPER, BASS, SQU
	} state;
	always_ff @(posedge clk)
		if (rst) begin
			mixed <= 0;
			kick_mode <= 2'd0;
			kick_trigger <= 1'b0;
			snare_trigger <= 1'b0;
			hat_trigger <= 1'b0;
			state <= IDLE;
		end else begin
			case (state)
				IDLE:
					if (next_sample) begin
						kick_mode_reg <= kick_mode;
						kick_trigger_reg <= kick_trigger;
						snare_trigger_reg <= snare_trigger;
						hat_trigger_reg <= hat_trigger;
						kick_trigger <= 1'b0;
						snare_trigger <= 1'b0;
						hat_trigger <= 1'b0;
						state <= KICK;
					end
				KICK:
					if (kick_finish) begin
						mixed <= {{9{kick_wave[23]}}, kick_wave[23:1]};
						state <= SNARE;
					end
				SNARE:
					if (snare_finish)
						state <= SNARE_BUBBLE;
				SNARE_BUBBLE:
					state <= SNARE_MIX;
				SNARE_MIX:
					begin
						mixed <= mixed + mult_p[39:8];
						state <= HAT;
					end
				HAT:
					if (hat_finish)
						state <= HAT_BUBBLE;
				HAT_BUBBLE:
					state <= HAT_MIX;
				HAT_MIX:
					begin
						mixed <= mixed + mult_p[39:8];
						state <= SAW;
					end
				SAW:
					if (saw_finish) begin
						mixed <= {mixed[31], mixed[31:1]} + {{9{saw_wave[23]}}, saw_wave[23:1]};
						state <= SUPER;
					end
				SUPER:
					if (super_finish) begin
						mixed <= mixed + {{8{super_wave[23]}}, super_wave};
						state <= BASS;
					end
				BASS:
					if (bass_finish) begin
						mixed <= mixed + {{8{bass_wave[23]}}, bass_wave};
						state <= SQU;
					end
				SQU:
					if (squ_finish) begin
						mixed <= mixed + {{8{squ_wave[23]}}, squ_wave};
						state <= IDLE;
					end
			endcase
			
			// Generate drum triggers.
			if (pitch == 6'd48) begin
				for (int i = 0; i < 4; ++i)
					if (key_presses[i]) begin
						kick_trigger <= 1'b1;
						kick_mode <= 2'(i);
					end
				if (key_presses[4])
					snare_trigger <= 1'b1;
				if (key_presses[5])
					hat_trigger <= 1'b1;
			end
		end
	
	always_comb begin
		mult_a = 32'bX;
		mult_b = 32'bX;
		div_n = 48'bX;
		div_d = 48'bX;
		kick_start = 1'b0;
		snare_start = 1'b0;
		hat_start = 1'b0;
		saw_start = 1'b0;
		super_start = 1'b0;
		bass_start = 1'b0;
		squ_start = 1'b0;
		
		case (state)
			KICK:
				begin
					kick_start = 1'b1;
					mult_a = kick_mult_a;
					mult_b = kick_mult_b;
				end
			SNARE:
				if (snare_finish) begin
					mult_a = 154;
					mult_b = {{8{snare_wave[23]}}, snare_wave};
				end else begin
					snare_start = 1'b1;
					mult_a = snare_mult_a;
					mult_b = snare_mult_b;
					div_n = snare_div_n;
					div_d = snare_div_d;
				end
			HAT:
				if (hat_finish) begin
					mult_a = 51;
					mult_b = {{8{hat_wave[23]}}, hat_wave};
				end else begin
					hat_start = 1'b1;
					mult_a = hat_mult_a;
					mult_b = hat_mult_b;
				end
			SAW:
				begin
					saw_start = 1'b1;
					mult_a = saw_mult_a;
					mult_b = saw_mult_b;
					div_n = saw_div_n;
					div_d = saw_div_d;
				end
			SUPER:
				begin
					super_start = 1'b1;
					mult_a = super_mult_a;
					mult_b = super_mult_b;
				end
			BASS:
				begin
					bass_start = 1'b1;
					mult_a = bass_mult_a;
					mult_b = bass_mult_b;
					div_n = bass_div_n;
					div_d = bass_div_d;
				end
			SQU:
				begin
					squ_start = 1'b1;
					mult_a = squ_mult_a;
					mult_b = squ_mult_b;
					div_n = squ_div_n;
					div_d = squ_div_d;
				end
		endcase
	end
endmodule
