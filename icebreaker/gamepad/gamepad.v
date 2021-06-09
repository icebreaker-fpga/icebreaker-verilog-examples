/*
 *  icebreaker examples - read (S)NES gamepad and send over UART
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

module top (
	input  CLK,
	input RX,
	output TX,
	output LEDR_N,
	output LEDG_N,
	output P1A1,  // CLK
	input  P1A2,  // GPD0
	input  P1A3,  // GPD2
	//output P1A4,  // AudioL
	output P1A7,  // LATCH
	input  P1A8,  // GPD1
	input  P1A9,  // GPD3
	//output P1A10, // Audio R
	output LED1,
	output LED2,
	output LED3,
	output LED4,
	output LED5
);

/* Gamepad Pmod pin decoding */
wire gp_clk;
wire gp_latch;
wire gp_d0;
wire gp_d1;
wire gp_d2;
wire gp_d3;
//wire audio_l;
//wire audio_r;

assign P1A1 = gp_clk;
assign P1A7 = gp_latch;
assign {gp_d0, gp_d1, gp_d2, gp_d3} = {P1A2, P1A8, P1A3, P1A9};
//assign P1A4 = audio_l;
//assign P1A10 = audio_r;

/* PLL block instantiation */
wire clk_42mhz;
//assign clk_42mhz = CLK;
SB_PLL40_PAD #(
	.DIVR(4'b0000),
	// 42MHz
	.DIVF(7'b0110111),
	.DIVQ(3'b100),
	.FILTER_RANGE(3'b001),
	.FEEDBACK_PATH("SIMPLE"),
	.DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
	.FDA_FEEDBACK(4'b0000),
	.DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
	.FDA_RELATIVE(4'b0000),
	.SHIFTREG_DIV_MODE(2'b00),
	.PLLOUT_SELECT("GENCLK"),
	.ENABLE_ICEGATE(1'b0)
) pll_inst (
	.PACKAGEPIN(CLK),
	.PLLOUTCORE(),
	.PLLOUTGLOBAL(clk_42mhz),
	.EXTFEEDBACK(),
	.DYNAMICDELAY(),
	.RESETB(1'b1),
	.BYPASS(1'b0),
	.LATCHINPUTVALUE(),
	//.LOCK(),
	//.SDI(),
	//.SDO(),
	//.SCLK()
);

/* Generate reset signal */
reg [15:0] rst_cnt = 16'h0000;
wire rst;
always @(posedge clk_42mhz) begin
	if (rst_cnt[15] == 0) begin
		rst_cnt <= rst_cnt + 1;
	end
end
assign rst = ~rst_cnt[15];

/* Gamepad read module instance. */
wire [15:0] gp1;
wire [15:0] gp2;
wire [15:0] gp3;
wire [15:0] gp4;
wire gp_data_ready;
gamepads #(
	.N_DIV(21) // 21 -> 1MHz shift clock
) gp_I (
	.gp_clk(gp_clk),
	.gp_latch(gp_latch),
	.gp_d0(gp_d0),
	.gp_d1(gp_d1),
	.gp_d2(gp_d2),
	.gp_d3(gp_d3),
	.gp1(gp1),
	.gp2(gp2),
	.gp3(gp3),
	.gp4(gp4),
	.gp_data_ready(gp_data_ready),
	.clk(clk_42mhz),
	.rst(rst)
);

/* Generate gp_data_ready_strobe. */
reg gp_old_data_ready = 0;
wire gp_data_ready_strobe;
assign gp_data_ready_strobe = gp_data_ready &&
							  (gp_data_ready != gp_old_data_ready);
always @(posedge clk_42mhz) begin
	if (gp_data_ready_strobe) begin
		gp_old_data_ready <= 1;
	end else if (!gp_data_ready) begin
		gp_old_data_ready <= 0;
	end
end

/* Store data to display on LEDs. */
reg [15:0] gp1_reg = 0;
reg [15:0] gp2_reg = 0;
reg [15:0] gp3_reg = 0;
reg [15:0] gp4_reg = 0;
always @(posedge clk_42mhz) begin
	if (gp_data_ready_strobe) begin
		gp1_reg <= gp1;
		gp2_reg <= gp2;
		gp3_reg <= gp3;
		gp4_reg <= gp4;
	end
end

assign {LEDG_N, LEDR_N, LED5, LED4, LED3, LED2, LED1} = gp1_reg[6:0];

/* Instantiate the tx1 module.
 * This module will send out hex values representing the
 * gamepad values.
 */
reg tx1_start;
reg [7:0] tx1_data;
wire tx1_busy;
uart_tx #(42000000, 115200) utx1 (
	.clk(clk_42mhz),
	.tx_start(tx1_start),
	.tx_data(tx1_data),
	.tx(TX),
	.tx_busy(tx1_busy)
);

/* Instantiate the gamepad send module.
 * This module will take the gamepad
 * registers and convert them to a character string
 * sequence.
 */
gamepad_sender gp_sender1 (
	.gp_data_ready_strobe(gp_data_ready_strobe),
	.gp1(gp1),
	.gp2(gp2),
	.gp3(gp3),
	.gp4(gp4),
	.tx_start(tx1_start),
	.tx_data(tx1_data),
	.tx_busy(tx1_busy),
	.clk(clk_42mhz),
	.rst(rst)
);

endmodule
