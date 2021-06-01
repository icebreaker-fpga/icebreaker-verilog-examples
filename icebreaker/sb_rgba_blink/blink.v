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
	output wire [2:0] LED_RGB,
);

	reg [27:0] cnt;
	wire rgb_pwm[2:0];
	wire clk;

	SB_HFOSC osc_I (
		.CLKHFPU(1'b1),
		.CLKHFEN(1'b1),
		.CLKHF(clk)
	);

	always @(posedge clk)
		cnt <= cnt + 1;

	assign rgb_pwm[0] = cnt[27] & (cnt[2:0] == 3'b000);
	assign rgb_pwm[1] = cnt[26] & (cnt[2:0] == 3'b000);
	assign rgb_pwm[2] = cnt[25] & (cnt[2:0] == 3'b000);

	SB_RGBA_DRV #(
		.CURRENT_MODE("0b1"),
		.RGB0_CURRENT("0b000001"),
		.RGB1_CURRENT("0b000001"),
		.RGB2_CURRENT("0b000001")
	) rgb_drv_I (
		.RGBLEDEN(1'b1),
		.RGB0PWM(rgb_pwm[0]),
		.RGB1PWM(rgb_pwm[1]),
		.RGB2PWM(rgb_pwm[2]),
		.CURREN(1'b1),
		.RGB0(LED_RGB[0]),
		.RGB1(LED_RGB[1]),
		.RGB2(LED_RGB[2])
	);

endmodule // blink

