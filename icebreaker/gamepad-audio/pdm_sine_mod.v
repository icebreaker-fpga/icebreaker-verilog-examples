/*
 *  icebreaker examples - PDM sine wave generator
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

module pdm_sine #(
	parameter integer N_DIV = 42000, // clock divider
	parameter integer LOG_N_DIV = $clog2(N_DIV)
)(

	// The pdm signal output pad
	output wire pdm_pad,

	/* Advance essentially the clock divider.
	 * Fixed point value with 10.10 bit split.
	 * The value of b0000000001_0000000000
	 * will result in a 1.024kHz signal
	 */
	input [19:0] adv,

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

/* The Sine value lookup table is meant to cover a 1024 value range
 * But we only need to store 1/4 of the values. The remaining ones
 * are easy to calculate by simple order reversal and sign change.
 * For 1024 values we need 10 bits. For 1/4th we need 8 bits as input.
 * The output values are signed 32 bits, but we only need to store half
 * of that range so the stored values cover 31 bits.
 */

// LUT input bit width
localparam SIN_I_BW = 8;
localparam SIN_O_BW = 32;

// Load the sine value lookup table
reg [(SIN_O_BW - 1):0] sin_lut [0:((1 << (SIN_I_BW)) - 1)];
initial $readmemh("sin_table.hex", sin_lut);

// Convert input value to LUT output value
wire [SIN_I_BW + 1:0] lut_in;
wire [SIN_O_BW - 1:0] lut_out;
wire [SIN_I_BW - 1:0] lut_raddr;
reg  [SIN_O_BW - 1:0] lut_rdata;
reg                   lut_inv;

assign lut_raddr = lut_in[SIN_I_BW] ? ~lut_in[SIN_I_BW - 1:0] : lut_in[SIN_I_BW - 1:0];

always @(posedge clk)
	lut_rdata <=  sin_lut[lut_raddr];

always @(posedge clk)
	lut_inv <= lut_in[SIN_I_BW + 1];

assign lut_out = lut_inv ? ~lut_rdata : lut_rdata;

// Generate input to the LUT signal generator
reg [19:0] sin_counter;
always @(posedge clk) begin
	if (rst) begin
		sin_counter <= 0;
	end
	if (strobe) begin
		sin_counter <= sin_counter + adv;
	end
end

assign lut_in = sin_counter[19:10];

// PDM signal generator
localparam G_OW = SIN_O_BW;

reg [G_OW - 1:0] pdm_level;
reg [G_OW + 1:0] pdm_sigma;
wire pdm_out;
reg pdm_strobe = 0;
assign pdm_out = ~pdm_sigma[G_OW + 1];
always @(posedge clk) begin
		if (rst) begin
			pdm_level <= 0;
			pdm_sigma <= 0;
			pdm_strobe <= 0;
		end else begin
			if(strobe) begin
				pdm_level <= lut_out + ((1 << (G_OW - 1)));
				pdm_strobe <= 1;
			end else if (pdm_strobe) begin
				pdm_strobe <= 0;
	        	pdm_sigma <= pdm_sigma + {pdm_out, pdm_out, pdm_level};
	    	end
	    end
end

assign pdm_pad = pdm_out;

endmodule