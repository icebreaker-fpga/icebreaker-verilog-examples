/*
 * blink.v
 *
 * CC0 1.0 Universal - See LICENSE in this directory
 *
 * Copyright (C) 2018  Sylvain Munaut
 *
 * vim: ts=4 sw=4
 */

`default_nettype none

module top (
	inout  wire USB_P,
	inout  wire USB_N,
	inout  wire USB_DET,
	output wire [2:0] LED_RGB,
	input  wire BTN_N,
	output wire LEDG_N,
);

	reg [27:0] cnt;
	wire rgb_pwm[2:0];
	wire clk;

	// Instantiate the internal oscillator
	// 48MHz
	SB_HFOSC osc_I (
		.CLKHFPU(1'b1),
		.CLKHFEN(1'b1),
		.CLKHF(clk)
	);

	// Reset to DFU bootloader with a long button press
	wire will_reboot;
	dfu_helper #(
		.BTN_MODE(3),
		.LONG_TW(19)
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
		.clk      (clk),
		.rst      (0)
	);
	// Indicate when the button was pressed for long enough to trigger a
	// reboot into the DFU bootloader.
	// (LED turns off when the condition matches)
	assign LEDG_N = will_reboot;

	// Upcount the counter ;)
	always @(posedge clk)
		cnt <= cnt + 1;

	// Generate PWM for each RGB led depending on the status of counter bits
	// cnt[27:25]. When the corresponding cnt bit is high generate a PWM where
	// PWM signal is high when cnt[2:0] is equal to 0 and low when it is not
	// equal to 0. This results in a PWM duty cycle of 1/8.
	assign rgb_pwm[0] = cnt[27] & (cnt[2:0] == 3'b000);
	assign rgb_pwm[1] = cnt[26] & (cnt[2:0] == 3'b000);
	assign rgb_pwm[2] = cnt[25] & (cnt[2:0] == 3'b000);

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
		.RGB0PWM(rgb_pwm[0]), // Single ON/OFF control that can accept PWM input
		.RGB1PWM(rgb_pwm[1]),
		.RGB2PWM(rgb_pwm[2]),
		.CURREN(1'b1), // Enable current reference
		.RGB0(LED_RGB[0]),
		.RGB1(LED_RGB[1]),
		.RGB2(LED_RGB[2])
	);

endmodule // blink

