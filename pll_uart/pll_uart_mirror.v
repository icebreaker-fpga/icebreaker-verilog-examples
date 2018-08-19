/*
 *  icebreaker examples - Async uart mirror using pll
 *
 *  Copyright (C) 2018 Piotr Esden-Tempski <piotr@esden.net>
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

`include "uart_rx.v"
`include "uart_tx.v"

module top (
	input  CLK,
	input RX,
  	output TX,
	output LEDR_N,
	output LEDG_N
);

wire clk_60mhz;
//assign clk_60mhz = CLK;
////SB_PLL40_CORE #(
SB_PLL40_PAD #(
  .DIVR(4'b0000),
  // 60MHz
  .DIVF(7'b1001111),
  .DIVQ(3'b100),
  // 81MHz
  //.DIVF(7'b0110101),
  //.DIVQ(3'b011),
  .FILTER_RANGE(3'b001),
  .FEEDBACK_PATH("SIMPLE"),
  .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
  .FDA_FEEDBACK(4'b0000),
  .DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
  .FDA_RELATIVE(4'b0000),
  .SHIFTREG_DIV_MODE(2'b00),
  .PLLOUT_SELECT("GENCLK"),
  .ENABLE_ICEGATE(1'b0)
) usb_pll_inst (
  //.REFERENCECLK(pin_clk),
  .PACKAGEPIN(CLK),
  .PLLOUTCORE(clk_60mhz),
  .PLLOUTGLOBAL(),
  .EXTFEEDBACK(),
  .DYNAMICDELAY(),
  .RESETB(1'b1),
  .BYPASS(1'b0),
  .LATCHINPUTVALUE(),
  .LOCK(),
  .SDI(),
  .SDO(),
  .SCLK()
);

/* local parameters */
//localparam clk_freq = 12000000; // 12MHz
localparam clk_freq = 60000000; // 60MHz
//localparam baud = 115200;
localparam baud = 57600;


/* instantiate the rx1 module */
wire reg rx1_ready;
wire reg [7:0] rx1_data;
uart_rx #(clk_freq, baud) urx1 (
	.clk(clk_60mhz),
	.rx(RX),
	.rx_ready(rx1_ready),
	.rx_data(rx1_data),
);

/* instantiate the tx1 module */
wire reg tx1_start;
wire reg [7:0] tx1_data;
wire reg tx1_busy;
uart_tx #(clk_freq, baud) utx1 (
	.clk(clk_60mhz),
	.tx_start(tx1_start),
	.tx_data(tx1_data),
	.tx(TX),
	.tx_busy(tx1_busy)
);

//assign tx1_start = rx1_ready;
//assign tx1_data = rx1_data;

always @(posedge clk_60mhz) begin
	if(rx1_ready) begin
		tx1_data <= rx1_data;
		tx1_start <= 1'b1;
		LEDR_N <= ~rx1_data[0];
		LEDG_N <= ~rx1_data[1];
	end else
		tx1_start <= 1'b0;
end

//assign TX = RX;

endmodule
