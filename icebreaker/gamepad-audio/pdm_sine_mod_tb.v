/*
 *  icebreaker examples - PDM sine wave generator test bench
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
 */

`default_nettype none
`timescale 1ns / 100ps

module pdm_sine_tb;

	// Signals
	reg rst = 1;
	reg clk = 1;

	wire pdm_out;

	reg [19:0] signal_advance = 20'b00000_00001_00000_00000;

	// Setup Recording
	initial begin
		$dumpfile("pdm_sine_mod_tb.vcd");
		$dumpvars(0,pdm_sine_tb);
	end

	// Reset Pulse
	initial begin
		# 31 rst = 0;
		# 20000 $finish;
	end

	// Clock
	always #5 clk = !clk;

	pdm_sine #(
		.N_DIV(1)
	) dut_I (
		.pdm_pad(pdm_out),
		.adv(signal_advance),
		.clk(clk),
		.rst(rst)
	);

endmodule