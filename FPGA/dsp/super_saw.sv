// Sawtooth wave with 7x unison detuning.
// Author: Yibo Cao

module super_saw (
	// Control flow
	input clk, rst, start,
	output logic finish,
	
	// Shared multiplier
	input [63:0] mult_p,
	output logic [31:0] mult_a, mult_b,

	// Data
	input gate, trigger,
	input [23:0] freq,
	output logic [23:0] wave_out
);
	logic [2:0] counter;
	logic [23:0] amp;

	// Phase integrator for each sawtooth.
	logic phase_en[0:6];
	logic [15:0] phase[0:6];
	logic [23:0] phase_init[0:6];
	phase_integrator m1[0:6] (.*, .en(phase_en), .init(phase_init), .freq(mult_p[39:16]));
	assign phase_init[0] = 24'd11237;
	assign phase_init[1] = 24'd9182;
	assign phase_init[2] = 24'd28532;
	assign phase_init[3] = 24'd13285;
	assign phase_init[4] = 24'd18604;
	assign phase_init[5] = 24'd33356;
	assign phase_init[6] = 24'd321;
	
	// Detuning of each sawtooth (-16).
	logic [23:0] detuning[0:6];
	assign detuning[0] = 24'd64596;
	assign detuning[1] = 24'd64896;
	assign detuning[2] = 24'd65347;
	assign detuning[3] = 24'd65536;
	assign detuning[4] = 24'd65764;
	assign detuning[5] = 24'd66221;
	assign detuning[6] = 24'd66451;
	
	// Mixing of each sawtooth (-24).
	logic [23:0] mixing[0:6];
	assign mixing[0] = 24'd199729;
	assign mixing[1] = 24'd249661;
	assign mixing[2] = 24'd349525;
	assign mixing[3] = 24'd499322;
	assign mixing[4] = 24'd349525;
	assign mixing[5] = 24'd249661;
	assign mixing[6] = 24'd199729;
	
	// Oscillator
	logic saw_start, saw_finish;
	logic [31:0] saw_mult_a, saw_mult_b;
	logic [23:0] saw_wave;
	saw m2 (.*, .start(saw_start), .finish(saw_finish),
		.x(phase[counter]), .y(saw_wave),
		.mult_a(saw_mult_a), .mult_b(saw_mult_b));

	enum logic [3:0] {
		IDLE, S_1, DETUNE, SAW, S_2, MIX,
		S_3, S_4, AMP, FINISH
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
						amp <= amp - ((amp - 24'd8388608) >> 11);
					else
						amp <= amp - (amp >> 12);
					counter <= 3'd0;
					state <= S_1;
					wave_out <= 24'd0;
				end
			S_1:
				state <= DETUNE;
			DETUNE:
				if (counter == 3'd6) begin
					counter <= 3'd0;
					state <= SAW;
				end else
					counter <= counter + 3'd1;
			SAW:
				if (saw_finish)
					state <= S_2;
			S_2:
				state <= MIX;
			MIX:
				begin
					wave_out <= wave_out + mult_p[47:24];
					if (counter == 3'd6)
						state <= S_3;
					else
						state <= SAW;
					counter <= counter + 3'd1;
				end
			S_3:
				state <= S_4;
			S_4:
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
		saw_start = 1'b0;
		finish = 1'b0;
		for (int i = 0; i < 7; ++i)
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
			SAW:
				if (saw_finish) begin
					mult_a = saw_wave;
					mult_b = mixing[counter];
				end else begin
					saw_start = 1'b1;
					mult_a = saw_mult_a;
					mult_b = saw_mult_b;
				end
			S_3:
				begin
					mult_a = wave_out;
					mult_b = amp;
				end
			FINISH:
				finish = 1'b1;
		endcase
	end
endmodule
