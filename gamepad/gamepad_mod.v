/*
 *  icebreaker examples - read (S)NES gamepad data module
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

`default_nettype none

module gamepads #(
	parameter integer N_DIV = 42000,            // clock divider
	parameter integer LOG_N_DIV = $clog2(N_DIV)

)(
	
	// Gamepad Interface Pads
	output wire gp_clk,
	output wire gp_latch,
	input  wire gp_d0,
	input  wire gp_d1,
	input  wire gp_d2,
	input  wire gp_d3,

	// User Interface
	output wire [15:0] gp1,
	output wire [15:0] gp2,
	output wire [15:0] gp3,
	output wire [15:0] gp4,
	output wire gp_data_ready,

	// Clock and reset
	input clk,
	input rst
);

/* Generate strobe */
reg strobe;
reg [LOG_N_DIV:0] clk_div = N_DIV - 1;
always @(posedge clk) begin
	if (rst) begin
		clk_div <= N_DIV;
		strobe <= 0;
	end else
		if (clk_div[LOG_N_DIV]) begin
			clk_div <= N_DIV - 1;
			strobe <= 1;
		end else begin
			clk_div <= clk_div - 1;
			strobe <= 0;
		end
end

/* Gamepad read out state machine */
localparam
	GPS_IDLE  = 0,
	GPS_LATCH = 1,
	GPS_DATA  = 2,
	GPS_CLOCK = 3;

reg [15:0] gp1reg;
reg [15:0] gp2reg;
reg [15:0] gp3reg;
reg [15:0] gp4reg;

reg [1:0] state = GPS_IDLE;
reg [4:0] read_cnt = 15;
reg gp_latch_reg = 0;
reg gp_clk_reg = 0;
reg gp_data_ready_reg = 0;
always @(posedge clk) begin
  if (rst) begin
  	state <= GPS_IDLE;
  	gp_latch_reg <= 0;
  	gp_clk_reg <= 0;
  	gp1reg <= 0;
  	gp2reg <= 0;
  	gp3reg <= 0;
  	gp4reg <= 0;
  	gp_data_ready_reg <= 0;
  end else if (strobe) begin
    if (state == GPS_IDLE) begin
      gp_latch_reg <= 1;
      gp_clk_reg <= 0;
      state <= GPS_LATCH;
    end
    if (state == GPS_LATCH) begin
      gp_latch_reg <= 0;
      gp_clk_reg <= 0;
      gp1reg <= 0;
      gp2reg <= 0;
      gp3reg <= 0;
      gp4reg <= 0;
      gp_data_ready_reg <= 0;
      state <= GPS_DATA;
    end
    if (state == GPS_DATA) begin
      gp1reg <= {gp_d0, gp1reg[15:1]};
      gp2reg <= {gp_d1, gp2reg[15:1]};
      gp3reg <= {gp_d2, gp3reg[15:1]};
      gp4reg <= {gp_d3, gp4reg[15:1]};
      gp_clk_reg <= 1;
      state <= GPS_CLOCK;
    end
    if (state == GPS_CLOCK) begin
      gp_clk_reg <= 0;
      if (read_cnt == 0) begin
        read_cnt <= 15;
        gp_data_ready_reg <= 1;
        state <= GPS_IDLE;
      end else begin
        read_cnt <= read_cnt - 1;
        state <= GPS_DATA;
      end
    end
  end
end

assign gp_latch = gp_latch_reg;
assign gp_clk = gp_clk_reg;

assign gp1 = gp1reg;
assign gp2 = gp2reg;
assign gp3 = gp3reg;
assign gp4 = gp4reg;
assign gp_data_ready = gp_data_ready_reg;

endmodule
