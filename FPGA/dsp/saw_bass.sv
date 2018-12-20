// Bass instrument based on sawtooth wave.
// Author: Yibo Cao

`timescale 1ns/1ns

module saw_bass (
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
	logic [23:0] freq_porta, freq_porta_next;
	logic [15:0] phase;
	logic [23:0] amp;          // unsigned -24
	logic [23:0] cutoff;       // unsigned -8
	logic [23:0] saw_wave;     // signed -24
	logic [31:0] saw_filtered; // signed -24

	logic phase_en;
	phase_integrator m1 (.*, .en(phase_en), .init(0), .freq(freq_porta >> 2));
	
	logic saw_start, saw_finish;
	logic [31:0] saw_mult_a, saw_mult_b;
	saw m2 (.*, .start(saw_start), .finish(saw_finish), .x(phase), .y(saw_wave),
		.mult_a(saw_mult_a), .mult_b(saw_mult_b));
	
	logic lpf_start, lpf_finish;
	logic [31:0] lpf_mult_a, lpf_mult_b;
	lowpass_2 m3 (.*, .start(lpf_start), .finish(lpf_finish),
		.x({{12{saw_wave[23]}}, saw_wave[23:4]}), .y(saw_filtered), .resonance(78643),
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
						cutoff <= 24'(5000 * 256);
						freq_porta <= freq;
					end else begin
						cutoff <= cutoff - ((cutoff - 24'(400 * 256)) >> 12);
						freq_porta <= freq_porta_next;
					end
					if (gate)
						amp <= amp + ((24'd16777215 - amp) >> 9);
					else
						amp <= amp - (amp >> 12);
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
					wave_out <= mult_p[47:24];
					state <= FINISH;
				end
			FINISH:
				state <= IDLE;
		endcase
	
	always_comb begin
		if (freq > freq_porta) begin
			freq_porta_next = freq_porta + ((freq - freq_porta) >> 12);
			if (freq_porta_next == freq_porta)
				freq_porta_next = freq_porta + 24'd1;
		end else begin
			freq_porta_next = freq_porta - ((freq_porta - freq) >> 12);
			if (freq_porta_next == freq_porta)
				freq_porta_next = freq_porta - 24'd1;
		end
		
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

module saw_bass_testbench ();
	logic clk, rst, start, finish, gate, trigger;
	logic [63:0] mult_p;
	logic [31:0] mult_a, mult_b;
	logic [47:0] div_q, div_n, div_d;
	logic [23:0] freq, wave_out, wave_reg;
	
	shared_mult m1 (.*, .a(mult_a), .b(mult_b), .p(mult_p));
	shared_div m2 (.*, .n(div_n), .d(div_d), .q(div_q));
	saw_bass dut (.*);
	
	// Clock
	initial clk = 1'b0;
	always begin #10; clk <= ~clk; end
	
	// Testing
	initial begin
		rst = 1'b1;
		start = 1'b0;
		@(negedge clk);
		rst = 1'b0;
		gate = 1'b1;
		trigger = 1'b1;
		freq = 24'(440 * 256);
		
		for (int i = 0; i < 96000; ++i) begin
			start = 1'b1;
			while (!finish)
				@(negedge clk);
			wave_reg <= wave_out;
			start = 1'b0;
			@(negedge clk);
			trigger = 1'b0;
			if (i == 48000)
				gate = 1'b0;
		end
		$stop;
	end
endmodule
