// CODE IS NOT YET COMPLETED
// I just thought it might be useful for you guys to take a look at it so far

module final_project(SW, KEY, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, CLOCK_50,
VGA_CLK, VGA_HS, VGA_VS, VGA_BLANK_N, VGA_SYNC_N, VGA_R, VGA_G, VGA_B, CLOCK_25, GPIO);

	input [9:0] SW;
	input [3:0] KEY;
	input CLOCK_50;
	input CLOCK_25;
	output [30:0] GPIO;
	output [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
	wire ld_note, ld_chord, play1, play2, play3, play4, play5, play6, play7, play8, clear, clearNote, reset;
	wire [4:0] note;
	wire [2:0] chord;
	assign reset = ~KEY[0];
	
	
	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]

		// Create an Instance of a VGA controller - there can bemodule final_project only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	wire resetn;
	assign resetn = KEY[0];
	wire writeEn;
	assign writeEn = ~KEY[2] || ~KEY[3];
	//colour = 3'b001;
	vga_adapter VGA(
			.resetn(resetn),
			.clock(CLOCK_50),
			.colour(colour),
			.x(x_coord),
			.y(y_coord),
			.plot(writeEn),
			// Signals for the DAC to drive the monitor.
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_BLANK(VGA_BLANK_N),
			.VGA_SYNC(VGA_SYNC_N),
			.VGA_CLK(VGA_CLK));
		defparam VGA.RESOLUTION = "160x120";
		defparam VGA.MONOCHROME = "FALSE";
		defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
		defparam VGA.BACKGROUND_IMAGE = "piano.mif";
	
	// Get the x and y coordinates of the note on the piano
	wire [7:0] y_coord;
	wire [7:0] x_coord;
	
	wire [7:0] prev_y_coord;
	wire [7:0] prev_x_coord;
	
	wire [3:0] curr_note;
	wire [3:0] prev_note;
	
	get_x_coord XC(curr_note, x_coord);
	get_y_coord YC(curr_note, y_coord);
	get_x_coord prevXC(prev_note, prev_x_coord);
	get_y_coord prevYC(prev_note, prev_y_coord);
	
	
	control c0(.clk(CLOCK_50), 
					.enable(~KEY[1]), 
					.make_sound(~KEY[2]),
					.reset(reset), 
					.clear(clear),
					.clearNote(clearNote), 
					.ld_note(ld_note), 
					.ld_chord(ld_chord), 
					.play1(play1),
					.play2(play2),
					.play3(play3),
					.play4(play4),
					.play5(play5),
					.play6(play6),
					.play7(play7),
					.play8(play8));
					
	datapath d0(.in(SW[4:0]),
					.clk(CLOCK_50),
					.ld_note(ld_note), 
					.ld_chord(ld_chord), 
					.reset(reset),
					.clear(clear),
					.note(note), 
					.chord(chord), 
					.hex0(HEX0), 
					.hex1(HEX1), 
					.hex2(HEX2), 
					.hex3(HEX3));
					
	sound s0(.play1(play1),
				.play2(play2), 
				.play3(play3), 
				.play4(play4),
				.play5(play5),
				.play6(play6),
				.play7(play7),
				.play8(play8),
				.note(note), 
				.chord(chord), 
				.clear(clearNote),
				.clk(CLOCK_50), 
				.hex4(HEX4), 
				.hex5(HEX5),
				.currNote(curr_note),
				.prevNote(prev_note));

	// Create the frequency that should be playing the note (we can only hope)
	wire [16:0] max;
	wire [16:0] frequency;
	counter_upper_bound_LUT(curr_note, max);
	up_17_bit_counter count(frequency, 1'b0, CLOCK_25, 1'b0, max);
	//assign GPIO[0] = frequency;
	
	// first create a 16bit binary counter
	reg [15:0] counter;
	always @(posedge CLOCK_25) counter <= counter+1;

	// and use the most significant bit (MSB) of the counter to drive the speaker
	assign GPIO[0] = counter[15];
	
	
	// Calculate the proper colour
	reg [2:0] colour;
	/*always @(*)
	begin
		if ((play5 || play6 || play7 || play8)) begin
			if ((curr_note == 5'b00001) || (curr_note == 5'b00100) || (curr_note == 5'b00110) || (curr_note == 5'b01001) || (curr_note == 5'b01011) || (curr_note == 5'b01101) || (curr_note == 5'b10000) || (curr_note == 5'b10010) || (curr_note == 5'b10101)) begin
				colour <= 3'b000;
			end
			else begin
				colour <= 3'b111;
			end
			colour <= 3'b001;
		end else begin
			colour <= 3'b100;
		end
	end*/
	always @(*)
	begin
		colour <= SW[9:7];
	end
	
endmodule

module control(clk, enable, make_sound, reset, clear, clearNote, ld_note, ld_chord, play1, play2, play3, play4, play5, play6, play7, play8);

	input clk, enable, make_sound, reset;
	reg [3:0] curr, next;
	output reg ld_note, ld_chord, play1, play2, play3, play4, play5, play6, play7, play8, clear, clearNote;
	
	// States for FSM
	localparam S_WAIT_N = 5'b00000;
	localparam S_LOAD_N = 5'b00001;
	localparam S_WAIT_C = 5'b00010;
	localparam S_LOAD_C = 5'b00011;
	localparam S_WAIT_1 = 5'b00100;
	localparam S_SOUND_1 =5'b00101;
	localparam S_WAIT_2 = 5'b00110;
	localparam S_SOUND_2 =5'b00111;
	localparam S_WAIT_3 = 5'b01000;
	localparam S_SOUND_3 =5'b01001;
	localparam S_WAIT_4 = 5'b01010;
	localparam S_SOUND_4 =5'b01011;
	localparam S_WAIT_S4 =5'b01100;
	localparam S_CLEAR_5 =5'b01101;
	localparam S_WAIT_5 = 5'b01110;
	localparam S_CLEAR_6 =5'b01111;
	localparam S_WAIT_6 = 5'b10001;
	localparam S_CLEAR_7 =5'b10010;
	localparam S_WAIT_7 = 5'b10011;
	localparam S_CLEAR_8 =5'b10100;
	localparam S_WAIT_8 = 5'b10101;
	//localparam S_WAIT_S3 = 4'b1110;
	
	// Implementation of FSM
	always @(*)
	begin: state_table
		case(curr)
			S_WAIT_N: next = enable ? S_LOAD_N : S_WAIT_N;
			S_LOAD_N: next = enable ? S_LOAD_N : S_WAIT_C;
			S_WAIT_C: next = enable ? S_LOAD_C : S_WAIT_C;
			S_LOAD_C: next = enable ? S_LOAD_C : S_WAIT_1;
			S_WAIT_1: next = make_sound ? S_SOUND_1 : S_WAIT_1;
			S_SOUND_1: next = make_sound ? S_SOUND_1 : S_WAIT_2;
			S_WAIT_2: next = make_sound ? S_SOUND_2 : S_WAIT_2;
			S_SOUND_2: next = make_sound ? S_SOUND_2 : S_WAIT_3;
			S_WAIT_3: next = make_sound ? S_SOUND_3 : S_WAIT_3;
			S_SOUND_3 : next = make_sound ? S_SOUND_3 : S_WAIT_4;
			S_WAIT_4: next = make_sound ? S_SOUND_4 : S_WAIT_4;
			S_SOUND_4: next = make_sound ? S_SOUND_4 : S_WAIT_S4;
			S_WAIT_S4: next = make_sound ? S_WAIT_N : S_WAIT_S4;
			
			S_WAIT_5: next = make_sound ? S_CLEAR_5 : S_WAIT_5;
			S_CLEAR_5: next = make_sound ? S_CLEAR_5 : S_WAIT_6;
			S_WAIT_6: next = make_sound ? S_CLEAR_6 : S_WAIT_6;
			S_CLEAR_6: next = make_sound ? S_CLEAR_6 : S_WAIT_7;
			S_WAIT_7: next = make_sound ? S_CLEAR_7 : S_WAIT_7;
			S_CLEAR_7: next = make_sound ? S_CLEAR_7 : S_WAIT_8;
			S_WAIT_8: next = make_sound ? S_CLEAR_8 : S_WAIT_8;
			S_CLEAR_8: next = make_sound ? S_CLEAR_8 : S_WAIT_S4;
			
			
			default: next = S_WAIT_N;//
		endcase
	end

	// What signals to send to datapath
	always @(*)
	begin: enable_signals
		ld_note <= 1'b0;
		ld_chord <= 1'b0;
		play1 <= 1'b0;
		play2 <= 1'b0;
		play3 <= 1'b0;
		play4 <= 1'b0;
		play5 <= 1'b0;
		play6 <= 1'b0;
		play7 <= 1'b0;
		play8 <= 1'b0;
		clear <= 1'b1;
		clear <= 1'b1;
		case(curr)
			S_WAIT_N: begin clear <= 1'b1; clearNote <= 1'b1; end
			S_LOAD_N: begin clear <= 1'b1; clearNote <= 1'b1; ld_note <= 1'b1; end// Everything should still be clear
			S_LOAD_C: ld_chord <= 1'b1;
			S_WAIT_1: clear <= 1'b0; // Only the chord should be displayed
			S_SOUND_2:
			begin
				play2 <= 1'b1;
				clear <= 1'b0;
				clearNote <= 1'b0;
			end
			S_SOUND_3:
			begin
				play3 <= 1'b1;
				clear <= 1'b0;
				clearNote <= 1'b0;
			end
			S_SOUND_4:
			begin
				play4 <= 1'b1;
				clear <= 1'b0;
				clearNote <= 1'b0;
			end
			S_CLEAR_5:
			begin
				play4 <= 1'b0;
				play5 <= 1'b1;
				clear <= 1'b0;
				clearNote <= 1'b0;
			end
			S_CLEAR_6:
			begin
				play5 <= 1'b0;
				play6 <= 1'b1;
				clear <= 1'b0;
				clearNote <= 1'b0;
			end
			S_CLEAR_7:
			begin
				play6 <= 1'b0;
				play7 <= 1'b1;
				clear <= 1'b0;
				clearNote <= 1'b0;
			end
			S_CLEAR_8:
			begin
				play7 <= 1'b0;
				play8 <= 1'b1;
				clear <= 1'b0;
				clearNote <= 1'b0;
			end
			S_SOUND_1:
			begin
				play1 <= 1'b1;
				clear <= 1'b0;
				clearNote <= 1'b0;
			end
			S_WAIT_2:
			begin
				play1 <= 1'b1;
				clear <= 1'b0;
				clearNote <= 1'b0;
			end
			S_WAIT_3:
			begin
				play2 <= 1'b1;
				clear <= 1'b0;
				//play4 <= 1'b1;
				//clear <= 1'b0;
				clearNote <= 1'b0;
			end
			S_WAIT_4:
			begin
				play3 <= 1'b1;
				clear <= 1'b0;
				clearNote <= 1'b0;
			end
			S_WAIT_5:
			begin
				play4 <= 1'b1;
				clear <= 1'b1;
				clearNote <= 1'b1;
			end
			S_WAIT_6:
			begin
				play5 <= 1'b1;
				clear <= 1'b1;
				clearNote <= 1'b1;
			end
			S_WAIT_7:
			begin
				play6 <= 1'b1;
				clear <= 1'b1;
				clearNote <= 1'b1;
			end
			S_WAIT_8:
			begin
				play7 <= 1'b1;
				clear <= 1'b1;
				clearNote <= 1'b1;
			end
				
			S_WAIT_S4:
			begin
				play8 <= 1'b1;
				clear <= 1'b0;
				clearNote <= 1'b0;
			end
		endcase
	end
	
	always @(posedge clk)
	begin: states
		if (reset)
			curr <= S_WAIT_N;
		else
			curr <= next;
	end
endmodule

module datapath(in, clk, ld_note, ld_chord, reset, clear, note, chord, hex0, hex1, hex2, hex3);
	input [4:0] in;
	input ld_note, ld_chord, clk, reset, clear;
	output reg [4:0] note;
	output reg [2:0] chord;
	output [6:0] hex0, hex1, hex2, hex3;
	wire [3:0] c_type1, c_type2, letter, acc;
	reg [3:0] t1, t2, l, a;

	always @(posedge clk)
	begin
		if (reset) 
		begin
			note <= 5'b11111;
			chord <= 3'b000;
		end
		else
		begin
			if (ld_note)
				note <= in;
			else if (ld_chord)
				chord <= in[2:0];
		end
		if (clear)
		begin
			l <= 4'b1111;
			a <= 4'b1111;
			t1 <= 4'b1111;
			t2 <= 4'b1111;
		end
		else
		begin
			t1 <= c_type1;
			t2 <= c_type2;
			l <= letter;
			a <= acc;
		end
	end
	
	// For hex decoder
	convertNote cn( .note(note), .flat(2'b11), .letter(letter), .acc(acc));
	convertChord cc(.chord(chord), .type1(c_type1), .type2(c_type2));
	
	//mux2to1 mLetter(.x(letter), .y(4'b1111), .s(clear), .m(l));
	//mux2to1 mAcc(.x(acc), .y(4'b1111), .s(clear), .m(a));
	//mux2to1 mType1(.x(c_type1), .y(4'b1111), .s(clear), .m(t1));
	//mux2to1 mType2(.x(c_type2), .y(4'b1111), .s(clear), .m(t2));
	
	hex_decoder h3(l, hex3);
	hex_decoder h2(a, hex2);
	hex_decoder h1(t1, hex1);
	hex_decoder h0(t2, hex0);	
	
endmodule

module sound(play1, play2, play3, play4, play5, play6, play7, play8, note, chord, clear, clk, hex4, hex5, currNote, prevNote);
	input play1, play2, play3, play4, play5, play6, play7, play8, clear, clk;
	input [4:0] note;
	input [2:0] chord;
	output [6:0] hex4, hex5;
	output reg [3:0] currNote;
	output reg [3:0] prevNote;
	reg frequency;
	reg [4:0] dist1, dist2, dist3;
	wire [3:0] letter, acc;
	reg [3:0] l, a;
	reg [1:0] flat, flat1, flat3, flat5, flat7;

	// What the inputs should be for chords
	localparam MAJOR = 3'b000;
	localparam MINOR = 3'b001;
	localparam AUG = 3'b010;
	localparam DIM = 3'b011;
	localparam DOM7 = 3'b100;
	localparam DIM7 = 3'b101;
	localparam MAJ7 = 3'b110;
	localparam MIN7 = 3'b111;
	
	always @(*)
	begin
		// Same types of chords have the same distance in semitones between each note
		// flat* variables are for proper spelling of the chord (ignoring double flats and double sharps cuz those are hard :^) )
		case (chord)
			MAJOR:
			begin
				dist1 <= 5'b00100;
				dist2 <= 5'b00111;
				dist3 <= 5'b00000;
				flat1 <= 2'b11;
				flat3 <= 2'b00;
				if (note == 5'b01001)
					flat5 <= 2'b00;
				else
					flat5 <= 2'b11;
				flat7 <= 2'b11;
			end
			MINOR:
			begin
				dist1 <= 5'b00011;
				dist2 <= 5'b00111;
				dist3 <= 5'b00000;
				flat1 <= 2'b11;
				flat3 <= 2'b01;
				if (note == 5'b01001)
					flat5 <= 2'b00;
				else
					flat5 <= 2'b11;
				flat7 <= 2'b11;
			end
			AUG:
			begin
				dist1 <= 5'b00100;
				dist2 <= 5'b01000;
				dist3 <= 5'b00000;
				flat1 <= 2'b11;
				flat3 <= 2'b00;
				flat5 <= 2'b00;
				flat7 <= 2'b11;
			end
			DIM:
			begin
				dist1 <= 5'b00011;
				dist2 <= 5'b00110;
				dist3 <= 5'b00000;
				flat1 <= 2'b11;
				flat3 <= 2'b01;
				flat5 <= 2'b01;
				flat7 <= 2'b11;
			end
			DOM7:
			begin
				dist1 <= 5'b00100;
				dist2 <= 5'b00111;					
				dist3 <= 5'b01010;
				flat1 <= 2'b11;
				flat3 <= 2'b00;
				if (note == 5'b01001)
				begin
					flat5 <= 2'b00;
					flat7 <= 2'b11;
				end
				else
				begin
					flat5 <= 2'b11;
					flat7 <= 2'b01;
				end
			end
			DIM7:
			begin
				dist1 <= 5'b00011;
				dist2 <= 5'b00110;
				dist3 <= 5'b01001;
				flat1 <= 2'b11;
				flat3 <= 2'b01;
				flat5 <= 2'b01;
				flat7 <= 2'b10;
			end
			MAJ7:
			begin
				dist1 <= 5'b00100;
				dist2 <= 5'b00111;
				dist3 <= 5'b01011;
				flat1 <= 2'b11;
				flat3 <= 2'b00;
				if (note == 5'b01001)
					flat5 <= 2'b00;
				else
					flat5 <= 2'b11;
				if (note == 5'b00100)
					flat7 <= 2'b01;
				else
					flat7 <= 2'b00;
			end
			MIN7:
			begin
				dist1 <= 5'b00011;
				dist2 <= 5'b00111;
				dist3 <= 5'b01010;
				flat1 <= 2'b11;
				flat3 <= 2'b01;
				if (note == 5'b01001)
				begin
					flat5 <= 2'b00;
					flat7 <= 2'b11;
				end
				else
				begin
					flat5 <= 2'b11;
					flat7 <= 2'b01;
				end
			end
			default:
			begin
				dist1 <= 5'b0;
				dist2 <= 5'b0;
				dist3 <= 5'b0;
				flat1 <= 2'b11;
				flat3 <= 2'b11;
				flat5 <= 2'b11;
				flat7 <= 2'b11;
			end
		endcase
	end

	always @(*)
	begin
		currNote <= 5'b11111;
		if (play1) // plays first note
		begin
			currNote <= note;
			flat <= flat1;
		end
		else if (play2) // plays second note
		begin
			currNote <= note + dist1;
			flat <= flat3;
		end
		else if (play3) // plays third note
		begin
			currNote <= note + dist2;
			flat <= flat5;
		end
		else if (play4) // plays 4th note (if there is one)
		begin
			currNote <= note + dist3;
			flat <= flat7;
		end
		else if (play5) // plays (in reality, clears) the 5th note (4th note)
		begin
			currNote <= note;
			flat <= flat7;
		end
		else if (play6) // plays (in reality, clears) the 6th note (3rd note)
		begin
			currNote <= note + dist1;
			flat <= flat5;
		end
		else if (play7)
		begin
			currNote <= note + dist2;
			flat <= flat3;
		end
		else if (play8)
		begin
			currNote <= note + dist3;
			flat <= flat1;
		end
			
	end

	//wave_maker wm(.note(currNote), .clk(clk), .reset_n(reset), .wave(frequency));
	// send this frequency to the soundOut

	convertNote cn( .note(currNote), .flat(flat), .letter(letter), .acc(acc));
	
	always @(*)
	begin
		if (clear) begin
			l <= 4'b1111;
			a <= 4'b1111;
		end else begin
			l <= letter;
			a <= acc;
		end
	end
	//mux2to1 mLetter(.x(letter), .y(4'b1111), .s(clear), .m(l));
	//mux2to1 mAcc(.x(acc), .y(4'b1111), .s(clear), .m(a));
		
	hex_decoder h5(l, hex5);
	hex_decoder h4(a, hex4);
	
endmodule

module convertNote(note, flat, letter, acc); // This is for the hex decoder
	input [4:0] note;
	input [1:0] flat;
	output reg [3:0] letter, acc;
	reg [4:0] newNote;

	always @(note)
	begin
		if (note >= 5'b01100)
			newNote <= note - 5'b01100;
		else
			newNote <= note;
		case(newNote)
			5'b00000: // A
			begin
				letter <= 4'b0000;
				acc <= 4'b1000;
			end
			5'b00001: // Bb or A#
			begin
				case (flat)
					2'b00:
					begin
						letter <= 4'b0000;
						acc <= 4'b0111;
					end
					default:
					begin
						letter <= 4'b0001;
						acc <= 4'b0001;
					end
				endcase
					
			end
			5'b00010: // B or Cb
			begin
				case (flat)
					2'b01:
					begin
						letter <= 4'b0010;
						acc <= 4'b0001;
					end
					default
					begin
						letter <= 4'b0001;
						acc <= 4'b1000;
					end
				endcase
			end
			5'b00011: // C or B#
			begin
				case (flat)
					2'b00:
					begin
						letter <= 4'b0001;
						acc <= 4'b0111;
					end
					default:
					begin
						letter <= 4'b0010;
						acc <= 4'b1000;
					end
				endcase
			end
			5'b00100: // Db or C#
			begin
				case (flat)
					2'b00:
					begin
						letter <= 4'b0010;
						acc <= 4'b0111;
					end
					default:
					begin
						letter <= 4'b0011;
						acc <= 4'b0001;
					end
				endcase
			end
			5'b00101: // D
			begin
				letter <= 4'b0011;
				acc <= 4'b1000;
			end
			5'b00110: // Eb or D#
			begin
				case (flat)
					2'b00:
					begin
						letter <= 4'b0011;
						acc <= 4'b0111;
					end
					default:
					begin
						letter <= 4'b0100;
						acc <= 4'b0001;
					end
				endcase
			end
			5'b00111: // E or Fb
			begin
				case (flat)
					2'b01:
					begin
						letter <= 4'b0101;
						acc <= 4'b0001;
					end
					default:
						begin
						letter <= 4'b0100;
						acc <= 4'b1000;
					end
				endcase
			end
			5'b01000: // F or E#
			begin
				case (flat)
					2'b00:
					begin
						letter <= 4'b0100;
						acc <= 4'b0111;
					end
					default:
					begin
						letter <= 4'b0101;
						acc <= 4'b1000;
					end
				endcase
			end
			5'b01001: // F# or Gb
			begin
				case (flat)
					2'b01:
					begin
						letter <= 4'b0110;
						acc <= 4'b0001;
					end
					default:
					begin
						letter <= 4'b0101;
						acc <= 4'b0111;
					end
				endcase
			end
			5'b01010: // G
			begin
				letter <= 4'b0110;
				acc <= 4'b1000;
			end
			5'b01011: // Ab or G#
			begin
				case (flat)
					2'b00:
					begin
						letter <= 4'b0110;
						acc <= 4'b0111;
					end
					default:
					begin
						letter <= 4'b0000;
						acc <= 4'b0001;
					end
				endcase
			end

			default:
			begin
				letter <= 4'b1111;
				acc <= 4'b1111;
			end
		endcase
	end

	
endmodule

module convertChord(chord, type1, type2); // For hex decoder
	input [2:0] chord;
	output reg [3:0] type1, type2;

	localparam MAJOR = 3'b000;
	localparam MINOR = 3'b001;
	localparam AUG = 3'b010;
	localparam DIM = 3'b011;
	localparam DOM7 = 3'b100;
	localparam DIM7 = 3'b101;
	localparam MAJ7 = 3'b110;
	localparam MIN7 = 3'b111;

	always @(chord)
	begin
		case(chord)
			MAJOR: 
			begin
				type1 <= 4'b1000;
				type2 <= 4'b1000;
			end
			MINOR:
			begin
				type1 <= 4'b1001;
				type2 <= 4'b1000;
			end
			AUG:
			begin
				type1 <= 4'b0000;
				type2 <= 4'b1000;
			end
				
			DIM:
			begin
				type1 <= 4'b1010;
				type2 <= 4'b1000;
			end
			DOM7:
			begin
				type1 <= 4'b0011;
				type2 <= 4'b1011;
			end
			DIM7:
			begin
				type1 <= 4'b1010;
				type2 <= 4'b1011;
			end
			MAJ7:
			begin
				type1 <= 4'b1000;
				type2 <= 4'b1011;
			end
			MIN7:
			begin
				type1 <= 4'b1001;
				type2 <= 4'b1011;
			end

			default:
			begin
				type1 <= 4'b1111;
				type2 <= 4'b1111;
			end
		endcase
	end


endmodule

module mux2to1(x, y, s, m);
    input [3:0] x; //selected when s is 0
    input [3:0] y; //selected when s is 1
    input s; //select signal
    output [3:0] m; //output
  
    assign m = s & y | ~s & x;
    // OR
    // assign m = s ? y : x;

endmodule

module hex_decoder(IN, OUT);
    input [3:0] IN;
	 output reg [7:0] OUT;
	 
	 always @(*)
	 begin
		case(IN[3:0])
			4'b0000: OUT = 7'b000_1000; // A (note and augmented)
			4'b0001: OUT = 7'b000_0011; // b (note and flat)
			4'b0010: OUT = 7'b100_0110; // C 
			4'b0011: OUT = 7'b010_0001; // d (note and dominant)
			4'b0100: OUT = 7'b000_0110; // E
			4'b0101: OUT = 7'b000_1110; // F
			4'b0110: OUT = 7'b001_0000; // g
			4'b0111: OUT = 7'b001_0010; // S (sharp)
			4'b1000: OUT = 7'b111_1111; //   (natural and major)
			4'b1001: OUT = 7'b011_1111; // - (minor)
			4'b1010: OUT = 7'b001_1100; // o (diminished)
			4'b1011: OUT = 7'b111_1000; // 7
			4'b1111: OUT = 7'b111_1111;
			default: OUT = 7'b111_1111;
		endcase

	end
endmodule

module up_17_bit_counter(out, enable, clk, reset, max);
	// Output port: 
	output [16:0] out;
	// Input ports:
	input enable, clk, reset;
	input [16:0] max;
	// Internal variables
	reg [16:0] out;

	always @(posedge clk)
	if (reset) begin
		out <= 17'b0;
	end else if (enable) begin
		out <= out + 1;
	end else if (out == max + 1) begin
		out <= 17'b0;
	end
endmodule

module counter_upper_bound_LUT(note, upper_bound);
	input [4:0] note;
	output reg [16:0] upper_bound;
	
	always @(*)
	begin
		case (note[4:0])
			5'b00000: upper_bound = 17'b11011101111100100; // A3
			5'b00001: upper_bound = 17'b11011010111101100; // A#3 / Bb3
			5'b00010: upper_bound = 17'b11000101101011111; // B3
			5'b00011: upper_bound = 17'b10111010010111100; // C4
			5'b00100: upper_bound = 17'b10110000010001101; // C#4 / Db4
			5'b00101: upper_bound = 17'b10100110000101010; // D4
			5'b00110: upper_bound = 17'b10011101000000010; // D#4 / Eb4
			5'b00111: upper_bound = 17'b10010011111101110; // E4
			5'b01000: upper_bound = 17'b10001011111010001; // F4
			5'b01001: upper_bound = 17'b10000011111110000; // F#4 / Gb4
			5'b01010: upper_bound = 17'b01111100100100000; // G4
			5'b01011: upper_bound = 17'b01110101101010001; // G#4 / Ab4
			5'b01100: upper_bound = 17'b01101110111110010; // A4
			5'b01101: upper_bound = 17'b01101000110010000; // A#4 / Bb4
			5'b01110: upper_bound = 17'b01100010110101111; // B4
			5'b01111: upper_bound = 17'b01011101010111001; // C5
			5'b10000: upper_bound = 17'b01011000001000110; // C#5 / Db5
			5'b10001: upper_bound = 17'b01010011001011101; // D5
			5'b10010: upper_bound = 17'b01001110100000001; // D#5 / Eb5
			5'b10011: upper_bound = 17'b01001010000110000; // E5
			5'b10100: upper_bound = 17'b01000101111101001; // F5
			5'b10101: upper_bound = 17'b01000001111111000; // F#5 / Gb5
			5'b10110: upper_bound = 17'b00111110010010000; // G5
			default: upper_bound =  17'b00001000000000000; // Something inaudibly high
		endcase
	end
endmodule


// Given an arbitrary 5-bit integer representing a note, returns the X-coordinate
// of the box to draw on the right key.
module get_x_coord(NUM, XCOORD);
	input [4:0] NUM;
	output reg [7:0] XCOORD;
	
	always @(*)
	begin
		case (NUM[4:0])
			5'b00000: XCOORD = 8'd9; // A3
			5'b00001: XCOORD = 8'd19; // A#3 / Bb3
			5'b00010: XCOORD = 8'd29; // B3
			5'b00011: XCOORD = 8'd49; // C4
			5'b00100: XCOORD = 8'd59; // C#4 / Db4
			5'b00101: XCOORD = 8'd69; // D4
			5'b00110: XCOORD = 8'd79; // D#4 / Eb4
			5'b00111: XCOORD = 8'd89; // E4
			5'b01000: XCOORD = 8'd109; // F4
			5'b01001: XCOORD = 8'd119; // F#4 / Gb4
			5'b01010: XCOORD = 8'd129; // G4
			5'b01011: XCOORD = 8'd139; // G#4 / Ab4
			5'b01100: XCOORD = 8'd149; // A4
			5'b01101: XCOORD = 8'd19; // A#4 / Bb4
			5'b01110: XCOORD = 8'd29; // B4
			5'b01111: XCOORD = 8'd49; // C5
			5'b10000: XCOORD = 8'd59; // C#5 / Db5
			5'b10001: XCOORD = 8'd69; // D5
			5'b10010: XCOORD = 8'd79; // D#5 / Eb5
			5'b10011: XCOORD = 8'd89; // E5
			5'b10100: XCOORD = 8'd109; // F5
			5'b10101: XCOORD = 8'd119; // F#5 / Gb5
			5'b11111: XCOORD = 8'd1;
			default: XCOORD = 8'd0; // C0
		endcase
	end
endmodule

// Given an arbitrary 5-bit integer representing a note, returns the Y-coordinate
// of the box to draw on the right key
module get_y_coord(NUM, YCOORD);
	input [4:0] NUM;
	output reg [7:0] YCOORD;
	
	always @(*)
	begin
	if ((NUM == 5'b00001) || (NUM == 5'b00100) || (NUM == 5'b00110) || (NUM == 5'b01001) || (NUM == 5'b01011) || (NUM == 5'b01101) || (NUM == 5'b10000) || (NUM == 5'b10010) || (NUM == 5'b10101))
		YCOORD = 8'd30;
	else
		YCOORD = 8'd90;
	end
endmodule 