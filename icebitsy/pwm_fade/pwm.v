/*
 *  icebreaker examples - pwm demo
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

// This example generates PWM to fade LEDs
// The intended result is opposite pulsating Red and Blue LEDs
// on the iCEBreaker-bitsy. The intended effect is that the two LEDs
// "breathe" in brigtness up and down in opposite directions.

module top (
	inout  USB_P,
	inout  USB_N,
	inout  USB_DET,
	input CLK,
	output LEDG_N,
	input BTN_N,
	output [2:0] LED_RGB,
	output P2, // Debug pins 
	output P3  // 
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

// PWM generator
reg [15:0] pwm_counter = 0;
reg [15:0] pwm_compare = 256;
reg pwm_out;
always @(posedge CLK) begin
	// Divide clock by 65535
	// Results in a 183.11Hz PWM
	pwm_counter <= pwm_counter + 1;

	// Set pwm output according to the compare
	// Set output high when the counter is smaller than the compare value
	// Set output low when the counter is equal or higher than the compare
	// value
	if (pwm_counter < pwm_compare) begin
		pwm_out <= 1;
	end else begin
		pwm_out <= 0;
	end
end

// PWM compare generator
// Fading up and down creating a slow sawtooth output
// The fade up down takes about 11.18 seconds
// Note: You will see that the LEDs spend more time being very bright
// than visibly fading, this is because our vision is non linear. Take a look
// at the pwm_fade_gamma example that fixes this issue. :)
reg [17:0] pwm_inc_counter = 0;
reg [16-7:0] pwm_compare_value = 0;
always @(posedge CLK) begin
	// Divide clock by 131071
	pwm_inc_counter <= pwm_inc_counter + 1;

	// increment/decrement pwm compare value at 91.55Hz
	if (pwm_inc_counter[17]) begin
		pwm_compare_value <= pwm_compare_value + 1;
		pwm_inc_counter <= 0;
	end

	if (pwm_compare_value[16-7])
		pwm_compare <= ~pwm_compare_value << 7;
	else
		pwm_compare <=  pwm_compare_value << 7;
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
	.RGB0PWM(~pwm_out), // Single ON/OFF control that can accept PWM input
	.RGB1PWM(1'b0),
	.RGB2PWM(pwm_out),
	.CURREN(1'b1), // Enable current reference
	.RGB0(LED_RGB[0]),
	.RGB1(LED_RGB[1]),
	.RGB2(LED_RGB[2])
);

assign P2 = pwm_counter[15]; // 50% duty cycle PWM clock out
assign P3 = pwm_out; // PWM output on a GPIO pin

endmodule
