/*
 *  icebreaker examples - pdm demo
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

// This example is based on the PDM module by Tommy Thorn
// You can find him on GitHub as @tommythorn
// The original is here:
// https://github.com/tommythorn/yari/blob/master/shared/rtl/soclib/pdm.v

// This example generates PDM (Pulse Density Modulation) to fade LEDs
// The intended result is opposite pulsating Red and Green LEDs
// on the iCEBreaker. The intended effect is that the two LED "breathe" in
// brigtness up and down in opposite directions.

module top (
	input CLK,
	output LEDR_N,
	output LEDG_N,
	output P1A1, // Debug pins 
	output P1A2,
	output P1A7,
	output P1A8
);

// PDM generator
/*
 * Pulse Density Modulation for controlling LED intensity.
 * The theory is as follows:
 * given a desired target level 0 <= T <= 1, control the output pdm_out
 * in {1,0}, such that pdm_out on average is T. Do this by integrating the
 * error T - pdm_out over time and switch pdm_out such that the sum of
 * (T - pdm_out) is finite.
 *
 * pdm_sigma = 0, pdm_out = 0
 * forever
 *   pdm_sigma = pdm_sigma + (T - pdm_out)
 *   if (pdm_sigma >= 0)
 *     pdm_out = 1
 *   else
 *     pdm_out = 0
 *
 * Check: T = 0, pdm_out is never turned on; T = 1, pdm_out is olways on;
 *        T = 0.5, pdm_out toggles
 *
 * In fixed point arithmetic this becomes the following (assume N-bit arith)
 * pdm_sigma = pdm_sigma_float * 2^N = pdm_sigma_float << N.
 * As |pdm_sigma| <= 1, N+2 bits is sufficient
 *
 * pdm_sigma = 0, pdm_out = 0
 * forever
 *   D = T + (~pdm_out + 1) << N === T + (pdm_out << N) + (pdm_out << (N+1))
 *   pdm_sigma = pdm_sigma + D
 *   pdm_out = 1 & (pdm_sigma >> (N+1))
 */
reg [16-1:0] pdm_level = 0;
reg [16+1:0] pdm_sigma;
reg pdm_out;
assign pdm_out = ~pdm_sigma[16+1];
always @(posedge CLK) begin
	pdm_sigma <= pdm_sigma + {pdm_out, pdm_out, pdm_level};
end

// PDM level generator
// Fading up and down creating a slow sawtooth output
// The fade up down takes about 11.18 seconds
// Note: You will see that the LEDs spend more time being very bright
// than visibly fading, this is because our vision is non linear. Take a look
// at the pwm_fade_gamma example that fixes this issue. :)
reg [13:0] pdm_inc_counter = 0;
reg [16-2:0] pdm_level_value;
reg pdm_dir = 1;
always @(posedge CLK) begin
	// Divide clock by 8192
	pdm_inc_counter <= pdm_inc_counter + 1;

	// increment/decrement pdm value at 1.5kHz
	if (pdm_inc_counter[13]) begin
		pdm_inc_counter <= 0;
		pdm_level_value <= pdm_level_value + 1;
	end

	if (pdm_level_value[16-2])
		pdm_level <= ~pdm_level_value << 2;
	else
		pdm_level <=  pdm_level_value << 2;
end

assign LEDG_N = ~pdm_out;
assign LEDR_N =  pdm_out;
assign P1A1 = pdm_inc_counter[15]; // 50% duty cycle PDM inc clock
assign P1A2 = pdm_out; // PDM output on a GPIO pin
assign P1A7 = pdm_inc_counter[15]; // 50% duty cycle PDM inc clock
assign P1A8 = pdm_out; // PDM output on a GPIO pin

endmodule