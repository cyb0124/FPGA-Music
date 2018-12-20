// Initialization of WM8731 registers via I2C
// Author: Yibo Cao

module audio_init (
	input  clk, rst,
	output logic setup_done,
	inout  sda, scl
);
	// I2C
	logic i2c_start, i2c_stop, i2c_write, i2c_done, i2c_ack;
	logic [7:0] wr_data;
	i2c_host i1 (.start(i2c_start), .stop(i2c_stop), .write(i2c_write),
		.done(i2c_done), .ack(i2c_ack), .read(1'b0), .rd_data(), .*);

	// ROM of register contents
	logic [3:0] rom_addr;
	logic [15:0] rom_data;
	always_comb case (rom_addr)
		4'h0: rom_data = {7'hF, 9'b0_0000_0000}; // Reset
		4'h1: rom_data = {7'h0, 9'b1_0001_0111}; // Microphone 0dB
		4'h2: rom_data = {7'h2, 9'b1_0111_1001}; // Headphone 0dB
		4'h3: rom_data = {7'h4, 9'b0_0001_0100}; // DAC -> Out, Mic -> ADC
		4'h4: rom_data = {7'h5, 9'b0_0000_0000}; // No de-emphasis/soft-mute
		4'h5: rom_data = {7'h6, 9'b0_0000_0000}; // No power-down
		4'h6: rom_data = {7'h7, 9'b0_0100_1001}; // Master-mode, 24-bit, 48kHz, left-justify
		4'h7: rom_data = {7'h8, 9'b0_0000_0010}; // Normal-mode, 384x over-sampling
		4'h8: rom_data = {7'h9, 9'b0_0000_0001}; // Activate
		default: rom_data = 'X;
	endcase

	// Synchronized logic
	enum logic [3:0] {
		START_1, START_2,
		ADDR_1, ADDR_2,
		HI_BYTE_1, HI_BYTE_2,
		LO_BYTE_1, LO_BYTE_2,
		STOP_1, STOP_2, DONE
	} state;
	always_ff @(posedge clk)
		if (rst) begin
			rom_addr <= 1'b0;
			state <= START_1;
		end else case (state)
			START_1:
				state <= START_2;
			START_2:
				if (i2c_done) state <= ADDR_1;
			ADDR_1:
				state <= ADDR_2;
			ADDR_2:
				if (i2c_done) state <= HI_BYTE_1;
			HI_BYTE_1:
				state <= HI_BYTE_2;
			HI_BYTE_2:
				if (i2c_done) state <= LO_BYTE_1;
			LO_BYTE_1:
				state <= LO_BYTE_2;
			LO_BYTE_2:
				if (i2c_done) state <= STOP_1;
			STOP_1:
				state <= STOP_2;
			STOP_2:
				if (i2c_done) begin
					if (i2c_ack)
						rom_addr = rom_addr + 1'b1;
					if (rom_addr == 4'h9)
						state <= DONE;
					else
						state <= START_1;
				end
		endcase

	// Combinational logic
	always_comb begin
		setup_done = 1'b0;
		i2c_start = 1'b0;
		i2c_stop = 1'b0;
		i2c_write = 1'b0;
		wr_data = 'X;
		case (state)
			START_1:
				i2c_start = 1'b1;
			ADDR_1:
				begin
					i2c_write = 1'b1;
					wr_data = 8'h34;
				end
			HI_BYTE_1:
				begin
					i2c_write = 1'b1;
					wr_data = rom_data[15:8];
				end
			LO_BYTE_1:
				begin
					i2c_write = 1'b1;
					wr_data = rom_data[7:0];
				end
			STOP_1:
				i2c_stop = 1'b1;
			DONE:
				setup_done = 1'b1;
		endcase
	end
endmodule
