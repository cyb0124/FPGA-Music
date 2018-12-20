// Square wave with 3x unison detuning, octave doubling and delay effect.
// Author: Yibo Cao

module square_delay (
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
	input gate, trigger,
	input [23:0] freq,
	output logic [23:0] wave_out
);
	logic [2:0] counter;
	logic [23:0] amp;
	logic [23:0] squ_wave, wave_low;

	// Phase integrator for each square.
	logic phase_en[0:5];
	logic [15:0] phase[0:5];
	logic [23:0] phase_init[0:5];
	phase_integrator m1[0:5] (.*, .en(phase_en), .init(phase_init), .freq(mult_p[39:16]));
	assign phase_init[0] = 24'd5482;
	assign phase_init[1] = 24'd8102;
	assign phase_init[2] = 24'd25481;
	assign phase_init[3] = 24'd11293;
	assign phase_init[4] = 24'd19533;
	assign phase_init[5] = 24'd33246;
	
	// Detuning of each square (-16).
	logic [23:0] detuning[0:5];
	assign detuning[0] = 24'd64896;
	assign detuning[1] = 24'd65536;
	assign detuning[2] = 24'd66221;
	assign detuning[3] = 24'd129732;
	assign detuning[4] = 24'd131072;
	assign detuning[5] = 24'd132446;
	
	// Mixing of each square (-24).
	logic [23:0] mixing[0:5];
	assign mixing[0] = 24'd699051;
	assign mixing[1] = 24'd1165084;
	assign mixing[2] = 24'd699051;
	assign mixing[3] = 24'd466034;
	assign mixing[4] = 24'd699051;
	assign mixing[5] = 24'd466034;
	
	logic lpf_start, lpf_finish;
	logic [31:0] lpf_mult_a, lpf_mult_b, lpf_out;
	lowpass_2 m2 (.*, .start(lpf_start), .finish(lpf_finish),
		.x({{8{wave_low[23]}}, wave_low}), .y(lpf_out), .resonance(32768),
		.cutoff(24'(425 * 256)), .mult_a(lpf_mult_a), .mult_b(lpf_mult_b));

	enum logic [3:0] {
		IDLE, S_1, DETUNE, SQU_1, SQU_2,
		S_2, MIX, LPF, S_3, AMP, FINISH
	} state;
	always_ff @(posedge clk)
		if (rst) begin
			amp <= 24'd0;
			state <= IDLE;
		end else case (state)
			IDLE:
				if (start) begin
					if (trigger)
						amp <= 24'd16777215;
					else if (gate)
						amp <= amp - ((amp - 24'd4194304) >> 11);
					else
						amp <= amp - (amp >> 12);
					counter <= 3'd0;
					state <= S_1;
					wave_low <= 24'd0;
					wave_out <= 24'd0;
				end
			S_1:
				state <= DETUNE;
			DETUNE:
				if (counter == 3'd5) begin
					counter <= 3'd0;
					state <= SQU_1;
				end else
					counter <= counter + 3'd1;
			SQU_1:
				begin
					squ_wave <= phase[counter] < 16'd24000 ? 24'd16000000 : -24'd16000000;
					state <= SQU_2;
				end
			SQU_2:
				state <= S_2;
			S_2:
				state <= MIX;
			MIX:
				begin
					if (counter < 3'd3)
						wave_low <= wave_low + mult_p[47:24];
					else
						wave_out <= wave_out + mult_p[47:24];
					if (counter == 3'd5)
						state <= LPF;
					else
						state <= SQU_1;
					counter <= counter + 3'd1;
				end
			LPF:
				if (lpf_finish)
					state <= S_3;
			S_3:
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
		mult_a = 32'bX;
		mult_b = 32'bX;
		lpf_start = 1'b0;
		finish = 1'b0;
		for (int i = 0; i < 6; ++i)
			phase_en[i] = 1'b0;
		
		case (state)
			IDLE:
				begin
					mult_a = freq;
					mult_b = detuning[0];
				end
			S_1:
				begin
					mult_a = freq;
					mult_b = detuning[1];
				end
			DETUNE:
				begin
					phase_en[counter] = 1'b1;
					mult_a = freq;
					mult_b = detuning[counter + 3'd2];
				end
			SQU_2:
				begin
					mult_a = squ_wave;
					mult_b = mixing[counter];
				end
			LPF:
				if (lpf_finish) begin
					mult_a = lpf_out + {{8{wave_out[23]}}, wave_out};
					mult_b = amp;
				end else begin
					lpf_start = 1'b1;
					mult_a = lpf_mult_a;
					mult_b = lpf_mult_b;
				end
			FINISH:
				finish = 1'b1;
		endcase
	end
endmodule
