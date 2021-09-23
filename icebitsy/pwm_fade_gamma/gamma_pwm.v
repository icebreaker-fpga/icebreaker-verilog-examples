/*
 *  icebreaker examples - gamma pwm demo 
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

// This example generates PWM with gamma correction
// The intended result is opposite pulsating Red and Green LEDs
// on the iCEBreaker. The intended effect is that the two LED "breathe" evenly
// and don't stay at a perceptable brightness level longer than others.
//
// For more information about gamma correction:
// https://en.wikipedia.org/wiki/Gamma_correction

module top (
	inout  USB_P,
	inout  USB_N,
	inout  USB_DET,
	input CLK,
	output LEDG_N,
	input BTN_N,
	output [2:0] LED_RGB,
	output P2, // Debug pins 
	output P3, // 
	output P4  //
);

// Reset to DFU bootloader with a long button press
wire will_reboot;
dfu_helper #(
	.BTN_MODE(3)
) dfu_helper_I (
	.usb_dp   (USB_P),
	.usb_dn   (USB_N),
	.usb_pu   (USB_DET),
	.boot_sel (2'b00),
	.boot_now (1'b0),
	.btn_in   (BTN_N),
	.btn_tick (),
	.btn_val  (),
	.btn_press(),
	.will_reboot(will_reboot),
	.clk      (CLK),
	.rst      (0)
);
// Indicate when the button was pressed for long enough to trigger a
// reboot into the DFU bootloader.
// (LED turns off when the condition matches)
assign LEDG_N = will_reboot;

// Gamma value lookup table parameters
parameter G_PW = 8; // Number of input bits
parameter G_OW = 16; // Number of output bits

// Load the gamma value lookup table
reg [(G_OW-1):0] gamma_lut [0:((1<<(G_PW))-1)];
initial $readmemh("gamma_table.hex", gamma_lut);

// Very simple dual output PWM generator
// We need two outputs as we can't just invert the gamma corrected PWM output,
// as this would also invert the gamma curve.
reg [15:0] pwm_counter = 0;
reg [15:0] pwm_compare_0;
reg [15:0] pwm_compare_1;
reg pwm_out_0;
reg pwm_out_1;
always @(posedge CLK) begin
	pwm_counter <= pwm_counter + 1;

	if (pwm_counter < pwm_compare_0) begin
		pwm_out_0 <= 1;
	end else begin
		pwm_out_0 <= 0;
	end

	if (pwm_counter < pwm_compare_1) begin
		pwm_out_1 <= 1;
	end else begin
		pwm_out_1 <= 0;
	end
end

// PWM compare value generator
// Fade through the values using the gamma correction
reg [17:0] pwm_inc_counter = 0;
reg [G_PW:0] pwm_value = 0;
always @(posedge CLK) begin
	// Divide clock by 131071
	pwm_inc_counter <= pwm_inc_counter + 1;

	// increment/decrement the index
	if (pwm_inc_counter[17]) begin
		pwm_inc_counter <= 0;
		pwm_value <= pwm_value + 1;
	end

	// Assign the compare value
	// The MSB bit of pwm_value determines the direction of the count
	// It is less expensive on an FPGA than doing an up down counter with dir variable
	pwm_compare_0 <= gamma_lut[pwm_value[G_PW] ?  pwm_value[G_PW-1:0] : ~pwm_value[G_PW-1:0]];
	pwm_compare_1 <= gamma_lut[pwm_value[G_PW] ? ~pwm_value[G_PW-1:0] :  pwm_value[G_PW-1:0]];
end

SB_RGBA_DRV #(
	.CURRENT_MODE("0b1"), // 0: Normal; 1: Half
	// Set current to: 4mA
	// According to the datasheet the only accepted values are:
	// 0b000001, 0b000011, 0b000111, 0b001111, 0b011111, 0b111111
	// Each enabled bit increases the current by 4mA in normal CURRENT_MODE
	// and 2mA in half CURRENT_MODE.
	.RGB0_CURRENT("0b000001"),
	.RGB1_CURRENT("0b000001"),
	.RGB2_CURRENT("0b000001")
) rgb_drv_I (
	.RGBLEDEN(1'b1), // Global ON/OFF control
	.RGB0PWM(pwm_out_0), // Single ON/OFF control that can accept PWM input
	.RGB1PWM(1'b0),
	.RGB2PWM(pwm_out_1),
	.CURREN(1'b1), // Enable current reference
	.RGB0(LED_RGB[0]),
	.RGB1(LED_RGB[1]),
	.RGB2(LED_RGB[2])
);

assign P2 = pwm_counter[15];
assign P3 = pwm_out_0;
assign P4 = pwm_out_1;

endmodule
