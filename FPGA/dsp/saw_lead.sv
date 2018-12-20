// A lead instrument based on sawtooth wave.
// Author: Yibo Cao

module saw_lead (
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
	logic [15:0] phase;
	logic [23:0] amp;          // unsigned -24
	logic [23:0] cutoff;       // unsigned -8
	logic [23:0] saw_wave;     // signed -24
	logic [31:0] saw_filtered; // signed -24

	logic phase_en;
	phase_integrator m1 (.*, .en(phase_en), .init(0));
	
	logic saw_start, saw_finish;
	logic [31:0] saw_mult_a, saw_mult_b;
	saw m2 (.*, .start(saw_start), .finish(saw_finish), .x(phase), .y(saw_wave),
		.mult_a(saw_mult_a), .mult_b(saw_mult_b));
	
	logic lpf_start, lpf_finish;
	logic [31:0] lpf_mult_a, lpf_mult_b;
	lowpass_2 m3 (.*, .start(lpf_start), .finish(lpf_finish),
		.x({{8{saw_wave[23]}}, saw_wave}), .y(saw_filtered), .resonance(98304),
		.mult_a(lpf_mult_a), .mult_b(lpf_mult_b));

	enum logic [2:0] {
		IDLE, OSCS, SAW, LPF, BUBBLE, AMP, FINISH
	} state;
	always_ff @(posedge clk)
		if (rst) begin
			amp <= 24'd0;
			cutoff <= 24'(24000 * 256);
			state <= IDLE;
		end else case (state)
			IDLE:
				if (start) begin
					if (trigger) begin
						amp <= 24'd16777215;
						cutoff <= 24'(12000 * 256);
					end else begin
						if (gate)
							amp <= amp - ((amp - 24'd8388608) >> 11);
						else
							amp <= amp - (amp >> 12);
						cutoff <= cutoff - ((cutoff - 24'(600 * 256)) >> 14);
					end
					state <= OSCS;
				end
			OSCS:
				state <= SAW;
			SAW:
				if (saw_finish)
					state <= LPF;
			LPF:
				if (lpf_finish)
					state <= BUBBLE;
			BUBBLE:
				state <= AMP;
			AMP:
				begin
					wave_out <= mult_p[50:27];
					state <= FINISH;
				end
			FINISH:
				state <= IDLE;
		endcase
	
	always_comb begin
		finish = 1'b0;
		mult_a = 32'bX;
		mult_b = 32'bX;
		phase_en = 1'b0;
		saw_start = 1'b0;
		lpf_start = 1'b0;
		
		case (state)
			OSCS:
				phase_en = 1'b1;
			SAW:
				begin
					saw_start = 1'b1;
					mult_a = saw_mult_a;
					mult_b = saw_mult_b;
				end
			LPF:
				if (lpf_finish) begin
					mult_a = saw_filtered;
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
