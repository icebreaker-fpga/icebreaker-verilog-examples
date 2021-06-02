/*
 *  icebreaker examples - read (S)NES gamepad data module test bench
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
`timescale 1ns / 100ps

module gamepad_tb;

	// Signals
	reg rst = 1;
	reg clk = 1;

	wire phy_clk;
	wire phy_latch;
	reg phy_d0 = 1;
	reg phy_d1 = 0;
	reg phy_d2 = 1;
	reg phy_d3 = 0;

	wire [15:0] gp1;
	wire [15:0] gp2;
	wire [15:0] gp3;
	wire [15:0] gp4;
	wire gp_data_ready;

	// Setup Recording
	initial begin
		$dumpfile("gamepad_mod_tb.vcd");
		$dumpvars(0,gamepad_tb);
	end

	// Reset Pulse
	initial begin
		# 31 rst = 0;
		# 20000 $finish;
	end

	// Clock
	always #5 clk = !clk;

	gamepads #(
		.N_DIV(0)
	) dut_I (
		.gp_clk(phy_clk),
		.gp_latch(phy_latch),
		.gp_d0(phy_d0),
		.gp_d1(phy_d1),
		.gp_d2(phy_d2),
		.gp_d3(phy_d3),
		.gp1(gp1),
		.gp2(gp2),
		.gp3(gp3),
		.gp4(gp4),
		.gp_data_ready(gp_data_ready),
		.clk(clk),
		.rst(rst)
	);

endmodule