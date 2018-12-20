// Top level module.
// Author: Yibo Cao

module top (
	input  CLOCK_50,
	// HPS
	output [14:0] HPS_DDR3_ADDR,
	output [2:0]  HPS_DDR3_BA,
	output        HPS_DDR3_CAS_N,
	output        HPS_DDR3_CKE,
	output        HPS_DDR3_CK_N,
	output        HPS_DDR3_CK_P,
	output        HPS_DDR3_CS_N,
	output [3:0]  HPS_DDR3_DM,
	inout  [31:0] HPS_DDR3_DQ,
	inout  [3:0]  HPS_DDR3_DQS_N,
	inout  [3:0]  HPS_DDR3_DQS_P,
	output        HPS_DDR3_ODT,
	output        HPS_DDR3_RAS_N,
	output        HPS_DDR3_RESET_N,
	input         HPS_DDR3_RZQ,
	output        HPS_DDR3_WE_N,
	// Inputs
	input [3:0]   KEY,
	input [1:0]   SW,
	input [35:0]  GPIO_1,
	// I2C
	inout  FPGA_I2C_SDAT, FPGA_I2C_SCLK,
	// Audio
	output AUD_XCK, AUD_DACDAT,
	input  AUD_DACLRCK, AUD_ADCLRCK, AUD_BCLK, AUD_ADCDAT,
	// Video
	output [7:0] VGA_R, VGA_G, VGA_B,
	output VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N
);
	// Clocks, I/O mapping and synchronization
	logic clk, rst, h2f_rst_n;
	logic [11:0] keyboard_bouncy;
	logic [1:0] sw_bouncy;
	logic [31:0] inputs;
	clocks i1 (.clk_in(CLOCK_50), .clk_main(clk), .clk_aud(AUD_XCK),
		.rst_in(~h2f_rst_n), .rst_out(rst));
	sync i2[3:0] (.*, .in(KEY), .out(inputs[3:0]));
	sync i3[1:0] (.*, .in(SW), .out(sw_bouncy));
	sync i4[11:0] (.*, .in({
		GPIO_1[1:0], GPIO_1[3:2], GPIO_1[5:4],
		GPIO_1[30], GPIO_1[31], GPIO_1[32],
		GPIO_1[33], GPIO_1[34], GPIO_1[35]
	}), .out(keyboard_bouncy));
	debounce i5[1:0] (.*, .in(sw_bouncy), .out(inputs[5:4]));
	debounce i6[11:0] (.*, .in(keyboard_bouncy), .out(inputs[17:6]));

	// HPS
	logic [31:0] view_ctrl, content_ctrl_1, content_ctrl_2;
	logic [5:0] key_status_wr_addr;
	logic [7:0] key_status_wr_data;
	hps i7 (
		.clk_clk(clk), .rst_reset(rst),
		.h2f_rst_reset_n(h2f_rst_n),
		.memory_mem_a(HPS_DDR3_ADDR),
      .memory_mem_ba(HPS_DDR3_BA),
      .memory_mem_ck(HPS_DDR3_CK_P),
      .memory_mem_ck_n(HPS_DDR3_CK_N),
      .memory_mem_cke(HPS_DDR3_CKE),
      .memory_mem_cs_n(HPS_DDR3_CS_N),
      .memory_mem_ras_n(HPS_DDR3_RAS_N),
      .memory_mem_cas_n(HPS_DDR3_CAS_N),
      .memory_mem_we_n(HPS_DDR3_WE_N),
      .memory_mem_reset_n(HPS_DDR3_RESET_N),
      .memory_mem_dq(HPS_DDR3_DQ),
      .memory_mem_dqs(HPS_DDR3_DQS_P),
      .memory_mem_dqs_n(HPS_DDR3_DQS_N),
      .memory_mem_odt(HPS_DDR3_ODT),
      .memory_mem_dm(HPS_DDR3_DM),
      .memory_oct_rzqin(HPS_DDR3_RZQ),
		.view_ctrl_export(view_ctrl),
		.content_ctrl_1_export(content_ctrl_1),
		.content_ctrl_2_export(content_ctrl_2),
		.inputs_export(inputs)
	);
	assign key_status_wr_addr = view_ctrl[19:14];
	assign key_status_wr_data = view_ctrl[27:20];

	// Video processing
	logic new_col, new_row, new_frame;
	logic [23:0] color;
	vga_driver m1 (.*);
	graph_main m2 (.*,
		.subtile_scroll(view_ctrl[3:0]), .grid_scroll(view_ctrl[7:4]),
		.active_octave(view_ctrl[10:8]), .active_inst(view_ctrl[13:11]),
		.content_tile_offset(content_ctrl_1[5:0]), .content_wr_addr(content_ctrl_1[17:6]),
		.content_wr_data(content_ctrl_2[23:0]));

	// Audio processing
	logic setup_done, rd_ready, wr_ready;
	logic [23:0] wave_out;
	synthesizers m3 (.*, .next_sample(wr_ready));
	
	// Use audio sample count as the time base used by HPS.
	logic [13:0] sample_counter;
	always_ff @(posedge clk)
		if (wr_ready) sample_counter <= rst ? 0 : sample_counter + 1;
	assign inputs[31:18] = sample_counter;
	
	// Audio driver
	audio_init m5 (.*, .sda(FPGA_I2C_SDAT), .scl(FPGA_I2C_SCLK));
	audio_buffer m6 (.*, .wr_en(wr_ready), .rd_en(rd_ready),
		.wr_data_l(wave_out), .wr_data_r(wave_out),
		.rd_data_l(), .rd_data_r());
endmodule
