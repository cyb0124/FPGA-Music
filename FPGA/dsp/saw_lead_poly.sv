// 4-voice polyphony controller for saw_lead.
// Author: Yibo Cao

module saw_lead_poly (
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
	logic [5:0] voice_pitch[0:3];
	logic [23:0] voice_wave[0:3];
	logic [23:0] voice_freq[0:3], voice_freq_reg[0:3];
	logic voice_gate[0:3], voice_gate_reg[0:3],
		voice_trigger[0:3], voice_trigger_reg[0:3],
		voice_start[0:3], voice_finish[0:3];
	logic [31:0] voice_mult_a[0:3], voice_mult_b[0:3];
	logic [47:0] voice_div_n[0:3], voice_div_d[0:3];
	saw_lead m1[0:3] (.*, .start(voice_start), .finish(voice_finish),
		.gate(voice_gate_reg), .freq(voice_freq_reg),
		.trigger(voice_trigger_reg), .wave_out(voice_wave),
		.mult_a(voice_mult_a), .mult_b(voice_mult_b),
		.div_n(voice_div_n), .div_d(voice_div_d));
		
	enum logic [1:0] { IDLE, VOICE, FINISH } state;
	logic [1:0] counter;
	always_ff @(posedge clk) begin
		if (rst) begin
			for (int i = 0; i < 4; ++i) begin
				voice_pitch[i] <= 6'd0;
				voice_freq[i] <= 24'd0;
				voice_gate[i] <= 1'b0;
				voice_trigger[i] <= 1'b0;
			end
			state <= IDLE;
		end else begin
			case (state)
				IDLE:
					if (start) begin
						wave_out <= 24'd0;
						voice_freq_reg <= voice_freq;
						voice_gate_reg <= voice_gate;
						voice_trigger_reg <= voice_trigger;
						for (int i = 0; i < 4; ++i)
							voice_trigger[i] <= 1'b0;
						counter <= 2'd0;
						state <= VOICE;
					end
				VOICE:
					if (voice_finish[counter]) begin
						wave_out <= wave_out + voice_wave[counter];
						if (counter == 2'd3)
							state <= FINISH;
						else
							counter <= counter + 2'd1;
					end
				FINISH:
					state <= IDLE;
			endcase
	
			// Handle key presses/releases.
			if (key_press) begin
				for (int i = 0; i < 4; ++i)
					if (~voice_gate[i]) begin
						voice_pitch[i] <= pitch;
						voice_freq[i] <= freq;
						voice_trigger[i] <= 1'b1;
						voice_gate[i] <= 1'b1;
						break;
					end
			end else if (key_release)
				for (int i = 0; i < 4; ++i)
					if (voice_pitch[i] == pitch)
						voice_gate[i] <= 1'b0;
		end
	end
	
	always_comb begin
		finish = state == FINISH;
		mult_a = voice_mult_a[counter];
		mult_b = voice_mult_b[counter];
		div_n = voice_div_n[counter];
		div_d = voice_div_d[counter];
		for (int i = 0; i < 4; ++i)
			voice_start[i] = (state == VOICE) && (counter == 2'(i));
	end
endmodule
