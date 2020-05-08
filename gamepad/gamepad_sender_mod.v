/*
 *  icebreaker examples - Generate hex data out of gamepad registers
 *
 *  Copyright (C) 2020 Piotr Esden-Tempski <piotr@esden.net>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

module gamepad_sender (
	// Gamepad input
	input wire gp_data_ready_strobe,
	input wire [15:0] gp1,
	input wire [15:0] gp2,
	input wire [15:0] gp3,
	input wire [15:0] gp4,

	// Serial tx
	output reg tx_start,
	output reg [7:0] tx_data,
	input wire tx_busy,

	// Clock and reset
	input clk,
	input rst
);

/* Sender FSM states. */
localparam
	GPXS_IDLE       = 0,
	GPXS_SEND_START = 1,
	GPXS_WAIT_START = 2,
	GPXS_SEND_GP_ID = 3,
	GPXS_WAIT_GP_ID = 4,
	GPXS_SEND_GP    = 5,
	GPXS_WAIT_GP    = 6,
	GPXS_SEND_CR    = 7,
	GPXS_WAIT_CR    = 8,
	GPXS_SEND_NL    = 9,
	GPXS_WAIT_NL    = 10;

/* 4 bit to ascii hex lut */
wire [7:0] ahex [0:15];

assign ahex[0]  = "0";
assign ahex[1]  = "1";
assign ahex[2]  = "2";
assign ahex[3]  = "3";
assign ahex[4]  = "4";
assign ahex[5]  = "5";
assign ahex[6]  = "6";
assign ahex[7]  = "7";
assign ahex[8]  = "8";
assign ahex[9]  = "9";
assign ahex[10] = "A";
assign ahex[11] = "B";
assign ahex[12] = "C";
assign ahex[13] = "D";
assign ahex[14] = "E";
assign ahex[15] = "F";

/* Start escape sequence for the terminal. */
wire [7:0] start_seq [0:3];

/* Move cursor 4 lines up. Terminal escape sequence. */
assign start_seq[3]  = "\033";
assign start_seq[2]  = "[";
assign start_seq[1]  = "4";
assign start_seq[0]  = "A";

/* Implementation of the FSM. */
reg [3:0] gpx_reg[0:15];
reg [3:0] gpx_state = GPXS_IDLE;
reg [1:0] start_cnt;
reg [4:0] gpx_cnt;
always @(posedge clk) begin
	case (gpx_state)
		GPXS_IDLE: if(gp_data_ready_strobe) begin
			gpx_reg[0]  <= gp4[3:0];
			gpx_reg[1]  <= gp4[7:4];
			gpx_reg[2]  <= gp4[11:8];
			gpx_reg[3]  <= gp4[15:12];
			gpx_reg[4]  <= gp3[3:0];
			gpx_reg[5]  <= gp3[7:4];
			gpx_reg[6]  <= gp3[11:8];
			gpx_reg[7]  <= gp3[15:12];
			gpx_reg[8]  <= gp2[3:0];
			gpx_reg[9]  <= gp2[7:4];
			gpx_reg[10] <= gp2[11:8];
			gpx_reg[11] <= gp2[15:12];
			gpx_reg[12] <= gp1[3:0];
			gpx_reg[13] <= gp1[7:4];
			gpx_reg[14] <= gp1[11:8];
			gpx_reg[15] <= gp1[15:12];
			tx_data <= start_seq[3];
			tx_start <= 1;
			gpx_state <= GPXS_SEND_START;
			gpx_cnt <= 15;
			start_cnt <= 2; 
		end
		GPXS_SEND_START: if(tx_busy) begin
			tx_start <= 0;
			gpx_state <= GPXS_WAIT_START;
		end
		GPXS_WAIT_START: if(~tx_busy) begin
			if (start_cnt == 2'b11) begin
				tx_data <= "1";
				tx_start <= 1;
				gpx_state <= GPXS_SEND_GP_ID;
			end else begin
				tx_data <= start_seq[start_cnt];
				tx_start <= 1;
				gpx_state <= GPXS_SEND_START;
				start_cnt <= start_cnt - 1;
			end
		end
		GPXS_SEND_GP_ID: if(tx_busy) begin
			tx_start <= 0;
			gpx_state <= GPXS_WAIT_GP_ID;
		end
		GPXS_WAIT_GP_ID: if(~tx_busy) begin
			tx_data <= ahex[gpx_reg[gpx_cnt]];
			tx_start <= 1;
			gpx_state <= GPXS_SEND_GP;
			gpx_cnt <= gpx_cnt - 1;
		end
		GPXS_SEND_GP: if(tx_busy) begin
			tx_start <= 0;
			gpx_state <= GPXS_WAIT_GP;
		end
		GPXS_WAIT_GP: if(~tx_busy) begin
			if (gpx_cnt[1:0] == 2'b11) begin
				tx_data <= "\r";
				tx_start <= 1;
				gpx_state <= GPXS_SEND_CR;
			end else begin
				tx_data <= ahex[gpx_reg[gpx_cnt]];
				tx_start <= 1;
				gpx_state <= GPXS_SEND_GP;
				gpx_cnt <= gpx_cnt - 1;
			end
		end
		GPXS_SEND_CR: if(tx_busy) begin
			tx_start <= 0;
			gpx_state <= GPXS_WAIT_CR;
		end
		GPXS_WAIT_CR: if(~tx_busy) begin
			tx_data <= "\n";
			tx_start <= 1;
			gpx_state <= GPXS_SEND_NL;
		end
		GPXS_SEND_NL: if(tx_busy) begin
			tx_start <= 0;
			gpx_state <= GPXS_WAIT_NL;
		end
		GPXS_WAIT_NL: if(~tx_busy) begin
			if (gpx_cnt[3:2] == 2'b11) begin
				gpx_state <= GPXS_IDLE;
			end else begin
				tx_data <= "4" - gpx_cnt[3:2];
				tx_start <= 1;
				gpx_state <= GPXS_SEND_GP_ID;
			end
		end
	endcase
end

endmodule