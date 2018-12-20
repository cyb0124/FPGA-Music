// Main graphics module.
// Author: Yibo Cao

module graph_main (
	input clk, rst, new_col, new_row, new_frame,
	input [3:0] subtile_scroll, grid_scroll,
	input [2:0] active_octave, active_inst,
	input [5:0] key_status_wr_addr,
	input [7:0] key_status_wr_data,
	input [5:0] content_tile_offset,
	input [23:0] content_wr_data,
	input [11:0] content_wr_addr,
	output logic [23:0] color
);
	// Height of each type of track.
	localparam HEI_WHITE     = 4'd11;
	localparam HEI_BLACK     = 4'd9;
	localparam HEI_DRUM      = 4'd7;

	// Length of each segment.
	localparam LEN_WHITE     = 7'd80;
	localparam LEN_BWGAP     = 7'd33;
	localparam LEN_BLACK     = 7'd47;
	localparam LEN_OCTAVE    = 7'd8;
	localparam LEN_TILE      = 7'd15;
	
	// Colors.
	localparam CLR_WHITE_KEY = 24'hFFFFFF;
	localparam CLR_BLACK_KEY = 24'h000000;
	localparam CLR_DRUM_KEY  = 24'h1E1400;
	localparam CLR_SEPARATOR = 24'h444444;
	localparam CLR_TRACK_W   = 24'h202020;
	localparam CLR_TRACK_B   = 24'h171717;
	localparam CLR_TRACK_D   = 24'h2B1C00;
	localparam CLR_16TH      = 24'h303030;
	localparam CLR_4TH       = 24'h70757F;
	localparam CLR_WHOLE     = 24'hFFFFFF;
	localparam CLR_CURSOR    = 24'h20FF20;
	localparam CLR_DRUM_TILE = 24'hEFAE45;
	localparam CLR_EMPTY     = 24'h000000;
	localparam CLR_TILE_BDR  = 24'hFFFFFF;
	
	// States.
	logic [5:0] track;    // Current track number.
	logic [2:0] octave;   // Current octave number.
	logic [3:0] key;      // Current key number.
	logic [3:0] hei_ctr;  // Height counter.
	logic [3:0] hei_now;  // Height of the current track.
	logic [6:0] wid_ctr;  // Width counter.
	logic [9:0] abs_ctr;  // Absolute width counter.
	logic [5:0] tile_ctr; // Tile counter.
	logic [5:0] scrolled_tile_ctr;
	logic [23:0] clr_active_inst;
	logic is_black;       // Whether the current track is a black track.
	logic is_drum;        // Whether the current track is a drum track.
	logic is_prev_black;  // Whether the previous track is a black track.
	logic at_cursor, key_active, tile_active;
	logic tile_bdr_bottom, tile_bdr_top, tile_bdr_side;
	logic [2:0] key_inst, tile_inst;
	logic [23:0] key_active_clr, tile_active_clr;
	enum logic [2:0] {
		S_OCTAVE,    // The octave indicator below keys.
		S_SEPARATOR, // Separator between tracks.
		S_CONTENT,   // Main content of the sequencer.
		S_WHITE_KEY, // White piano key.
		S_BLACK_KEY, // Black piano key.
		S_DRUM_KEY  // Drum key.
	} state;
	
	graph_colors m1 (.inst(active_inst), .color(clr_active_inst));
	graph_key_status m2 (.*, .drum_key(key[2:0]),
		.wr_addr(key_status_wr_addr), .wr_data(key_status_wr_data),
		.out_active(key_active), .out_inst(key_inst));
	graph_colors m3 (.inst(key_inst), .color(key_active_clr));
	graph_content m4 (.*, .drum_key(key[2:0]),
		.tile_offset(content_tile_offset),
		.wr_addr(content_wr_addr), .wr_data(content_wr_data),
		.out_active(tile_active), .out_inst(tile_inst),
		.out_bdr_bottom(tile_bdr_bottom),
		.out_bdr_top(tile_bdr_top),
		.out_bdr_side(tile_bdr_side));
	graph_colors m5 (.inst(tile_inst), .color(tile_active_clr));
	
	// Combinational logic
	always_comb begin
		case (key)
			4'd1:    is_black = 1'b1;
			4'd3:    is_black = 1'b1;
			4'd6:    is_black = 1'b1;
			4'd8:    is_black = 1'b1;
			4'd10:   is_black = 1'b1;
			default: is_black = 1'b0;
		endcase
		
		is_drum = octave == 3'd4;
		hei_now = is_drum ? HEI_DRUM : is_black ? HEI_BLACK : HEI_WHITE;
		scrolled_tile_ctr = tile_ctr + grid_scroll;
		at_cursor = abs_ctr - (LEN_WHITE + LEN_TILE * 10'd8 - 1'b1) < 2'd3;
		
		case (state)
			S_WHITE_KEY:
				if (is_black & hei_ctr == (HEI_BLACK + 1'b1) >> 1)
					color = CLR_SEPARATOR;
				else
					color = (key_active & ~is_black) ? key_active_clr : CLR_WHITE_KEY;
			S_BLACK_KEY:
				color = key_active ? key_active_clr : CLR_BLACK_KEY;
			S_DRUM_KEY:
				color = (wid_ctr == LEN_OCTAVE | wid_ctr == LEN_WHITE - 1'b1)
					? CLR_SEPARATOR : key_active ? CLR_DRUM_TILE : CLR_DRUM_KEY;
			S_SEPARATOR:
				color = at_cursor ? CLR_CURSOR : CLR_SEPARATOR;
			S_CONTENT:
				if (at_cursor)
					color = CLR_CURSOR;
				else if (tile_active)
					if (tile_bdr_bottom & wid_ctr < 2
							| tile_bdr_top & wid_ctr >= LEN_TILE - 2
							| tile_bdr_side & (
								hei_ctr <= 2 | hei_ctr > hei_now - 2))
						color = CLR_TILE_BDR;
					else
						color = tile_active_clr;
				else if (wid_ctr == LEN_TILE - 1'b1)
					if (&scrolled_tile_ctr[1:0])
						if (&scrolled_tile_ctr[3:2])
							color = CLR_WHOLE;
						else
							color = CLR_4TH;
					else
						color = CLR_16TH;
				else
					color = is_drum ? CLR_TRACK_D :
						is_black ? CLR_TRACK_B : CLR_TRACK_W;
			S_OCTAVE:
				if (wid_ctr == LEN_OCTAVE - 1'b1)
					color = CLR_SEPARATOR;
				else if (octave == active_octave)
					color = is_drum ? CLR_DRUM_TILE : clr_active_inst;
				else
					color = CLR_EMPTY;
		endcase
	end

	// Update logic
	always_ff @(posedge clk)
		if (rst | new_frame) begin
			state <= S_SEPARATOR;
			track <= 1'b0;
			octave <= 1'b0;
			key <= 1'b0;
			is_prev_black <= 1'b0;
		end else if (new_row) begin
			wid_ctr <= 1'b0;
			abs_ctr <= 1'b0;
			tile_ctr <= 1'b0;
			case (state)
				S_SEPARATOR:
					begin
						hei_ctr <= 1'b1;
						state <= S_OCTAVE;
					end
				S_CONTENT:
					begin
						if (hei_ctr != hei_now) begin
							hei_ctr <= hei_ctr + 1'b1;
							state <= S_OCTAVE;
						end else begin
							hei_ctr <= 1'b0;
							track <= track + 1'b1;
							is_prev_black <= is_black;
							if (key == 4'd11) begin
								key <= 1'b0;
								octave <= octave + 1'b1;
								state <= S_SEPARATOR;
							end else begin
								key <= key + 1'b1;
								state <= S_OCTAVE;
							end
						end
					end
			endcase
		end else if (new_col) begin
			wid_ctr <= wid_ctr + 1'b1;
			abs_ctr <= abs_ctr + 1'b1;
			case (state)
				S_OCTAVE:
					if (wid_ctr == LEN_OCTAVE - 1'b1)
						if (is_drum)
							state <= hei_ctr ? S_DRUM_KEY : S_SEPARATOR;
						else
							state <= (hei_ctr | is_black | is_prev_black)
								? S_WHITE_KEY : S_SEPARATOR;
				S_WHITE_KEY:
					if (wid_ctr == LEN_WHITE - 1'b1) begin
						state <= hei_ctr ? S_CONTENT : S_SEPARATOR;
						wid_ctr <= subtile_scroll;
					end else if (is_black) begin
						if (wid_ctr == LEN_BWGAP - 1'b1) begin
							state <= S_BLACK_KEY;
							wid_ctr <= 1'b0;
						end
					end
				S_BLACK_KEY:
					if (wid_ctr == LEN_BLACK - 1'b1) begin
						state <= hei_ctr ? S_CONTENT : S_SEPARATOR;
						wid_ctr <= subtile_scroll;
					end
				S_DRUM_KEY:
					if (wid_ctr == LEN_WHITE - 1'b1) begin
						state <= S_CONTENT;
						wid_ctr <= subtile_scroll;
					end
				S_CONTENT:
					if (wid_ctr == LEN_TILE - 1'b1) begin
						wid_ctr <= 1'b0;
						tile_ctr <= tile_ctr + 1'b1;
					end
			endcase
		end
endmodule
