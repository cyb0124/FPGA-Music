// Circular buffer of ADC/DAC data for WM8731
// Author: Yibo Cao

module audio_buffer (
	input  clk, rst, setup_done, wr_en, rd_en,
	input  [23:0] wr_data_l, wr_data_r,
	output [23:0] rd_data_l, rd_data_r,
	output wr_ready, rd_ready,
	output logic  AUD_DACDAT,
	input  AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT
);
	logic dac_ready, dac_en, adc_ready, adc_en;
	logic [23:0] dac_l, dac_r, dac_now, adc_l, adc_r;

	// FIFO instances
	localparam ADDR_WIDTH = 3;
	fifo #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(48)) fifo_dac (.clk, .rst,
		.rd_ready(dac_ready), .rd_en(dac_en), .rd_data({dac_l, dac_r}),
		.wr_ready, .wr_en, .wr_data({wr_data_l, wr_data_r})); 
	fifo #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(48)) fifo_adc (.clk, .rst,
		.wr_ready(adc_ready), .wr_en(adc_en), .wr_data({adc_l, adc_r}),
		.rd_ready, .rd_en, .rd_data({rd_data_l, rd_data_r}));

	// Synchronization of the inputs.
	logic bclk, dac_lr, adc_lr, adc_bit;
	sync i1 (.clk, .in(AUD_BCLK), .out(bclk));
	sync i2 (.clk, .in(AUD_DACLRCK), .out(dac_lr));
	sync i3 (.clk, .in(AUD_ADCLRCK), .out(adc_lr));
	sync i4 (.clk, .in(AUD_ADCDAT), .out(adc_bit));

	// DAC Serial Transmitter (ASMD chart attached in the report)
	logic [3:0] dac_state;
	logic [4:0] dac_ctr;
	always_ff @(posedge clk)
		if (rst) begin
			dac_en <= 1'b0;
			dac_state <= 1'b0;
			AUD_DACDAT <= 1'b0;
		end else case (dac_state)
			default:
				if (~dac_lr & setup_done)
					dac_state <= 4'h1;
			4'h1:
				if (dac_lr)
					if (dac_ready) begin
						dac_en <= 1'b1;
						dac_state <= 4'h2;
					end else
						dac_state <= 4'h3;
			4'h2:
				begin
					dac_en <= 1'b0;
					dac_state <= 4'h3;
				end
			4'h3:
				begin
					dac_now <= dac_l;
					dac_ctr <= 1'b0;
					if (~bclk) dac_state <= 4'h4;
				end
			4'h4:
				begin
					dac_now <= {dac_now[22:0], 1'bX};
					AUD_DACDAT <= dac_now[23];
					dac_ctr <= dac_ctr + 1'b1;
					dac_state <= 4'h5;
				end
			4'h5:
				if (bclk) dac_state <= 4'h6;
			4'h6:
				if (~bclk)
					if (dac_ctr == 5'd24)
						dac_state <= 4'h7;
					else
						dac_state <= 4'h4;
			4'h7:
				begin
					dac_now <= dac_r;
					dac_ctr <= 1'b0;
					if (~dac_lr) dac_state <= 4'h8;
				end
			4'h8:
				if (~bclk) dac_state <= 4'h9;
			4'h9:
				begin
					dac_now <= {dac_now[22:0], 1'bX};
					AUD_DACDAT <= dac_now[23];
					dac_ctr <= dac_ctr + 1'b1;
					dac_state <= 4'hA;
				end
			4'hA:
				if (bclk) dac_state <= 4'hB;
			4'hB:
				if (~bclk)
					if (dac_ctr == 5'd24)
						dac_state <= 4'h1;
					else
						dac_state <= 4'h9;
		endcase

	// ADC Serial Receiver (ASMD chart attached in the report)
	logic [2:0] adc_state;
	logic [4:0] adc_ctr;
	always_ff @(posedge clk)
		if (rst) begin
			adc_en <= 1'b0;
			adc_state <= 1'b0;
		end else case (adc_state)
			default:
				if (~adc_lr & setup_done)
					adc_state <= 3'h1;
			3'h1:
				begin
					adc_ctr <= 1'b0;
					adc_en <= 1'b0;
					if (adc_lr) adc_state <= 3'h2;
				end
			3'h2:
				if (~bclk) adc_state <= 3'h3;
			3'h3:
				if (bclk) begin
					adc_ctr <= adc_ctr + 1'b1;
					adc_l <= {adc_l[22:0], adc_bit};
					if (adc_ctr == 5'd23)
						adc_state <= 3'h4;
					else
						adc_state <= 3'h2;
				end
			3'h4:
				begin
					adc_ctr <= 1'b0;
					if (~adc_lr) adc_state <= 3'h5;
				end
			3'h5:
				if (~bclk) adc_state <= 3'h6;
			3'h6:
				if (bclk) begin
					adc_ctr <= adc_ctr + 1'b1;
					adc_r <= {adc_r[22:0], adc_bit};
					if (adc_ctr == 5'd23) begin
						adc_state <= 3'h1;
						if (adc_ready) adc_en <= 1'b1;
					end else
						adc_state <= 3'h5;
				end
		endcase
endmodule
