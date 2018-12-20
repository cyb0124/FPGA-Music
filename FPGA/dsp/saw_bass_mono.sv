// monophony controller for saw_bass.
// Author: Yibo Cao

module saw_bass_mono (
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
	input key_press, key_release,
	input [5:0] pitch,
	input [23:0] freq,
	output logic [23:0] wave_out
);
	logic [5:0] voice_pitch;
	logic [23:0] voice_freq, voice_freq_reg;
	logic voice_gate, voice_gate_reg,
		voice_trigger, voice_trigger_reg, voice_start;
	saw_bass m1 (.*, .start(voice_start),
		.gate(voice_gate_reg), .freq(voice_freq_reg),
		.trigger(voice_trigger_reg));
	
	enum logic [0:0] { IDLE, VOICE } state;
	always_ff @(posedge clk) begin
		if (rst) begin
			voice_pitch <= 6'd0;
			voice_freq <= 24'd0;
			voice_gate <= 1'b0;
			voice_trigger <= 1'b0;
			state <= IDLE;
		end else begin
			case (state)
				IDLE:
					if (start) begin
						voice_freq_reg <= voice_freq;
						voice_gate_reg <= voice_gate;
						voice_trigger_reg <= voice_trigger;
						voice_trigger <= 1'b0;
						state <= VOICE;
					end
				VOICE:
					if (finish)
						state <= IDLE;
			endcase
	
			// Handle key presses/releases.
			if (key_press) begin
				voice_pitch <= pitch;
				voice_freq <= freq;
				if (~voice_gate) begin
					voice_gate <= 1'b1;
					voice_trigger <= 1'b1;
				end
			end else if (key_release)
				if (voice_pitch == pitch)
					voice_gate <= 1'b0;
		end
	end
	
	always_comb
		voice_start = state == VOICE;
endmodule
