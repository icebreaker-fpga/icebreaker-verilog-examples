/* Small test design actuating all IO on the iCEBreaker-bitsy dev board. */

module top (
	inout  USB_P,
	inout  USB_N,
	inout  USB_DET,

	input  CLK,

	input  BTN_N,

	output LEDG_N,

	output P0,  P1,  P2,  P3,  P4,  P5,  P6,  P7,
	output P8,  P9,  P10, P11, P12, P13, P14, P15,
	output P16, P17, P18, P19, P20, P21, P22, P23
);
	localparam BITS = 24;
	localparam LOG2DELAY = 20;

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

	// Delay counter with strobe
	// The highest significant bit at position LOG2DELAY will only be
	// 'hot' (=1) for one cycle until it is reset to 0 again.
	// While the highest significant bit is not hot (0) the counter increments
	// with every clock cycle.
	reg [LOG2DELAY:0] counter = 0;
	always @(posedge CLK) begin
		if (counter[LOG2DELAY])
			counter <= 0;
		else
			counter <= counter + 1;
	end

	// Create a bitfield that has one bit high and all the remaining bits low.
	// The one bit is rotating through the field.
	reg [BITS-1:0] outbitfield = 1 << BITS-1;
	always @(posedge CLK) begin
		if (counter[LOG2DELAY])
			// Assign the lowest significant bit to the highest significant bit
			// assign the remaining bits one bit lower than they were.
			// This results in the bit rotating through the field from highest significant bit
			// to the lowest significant bit.
			outbitfield <= {outbitfield[0], outbitfield[BITS-1:1]};
	end

	assign {P0,  P1,  P2,  P3,  P4,  P5,  P6,  P7,
		P8,  P9,  P10, P11, P12, P13, P14, P15,
		P16, P17, P18, P19, P20, P21, P22, P23} = outbitfield;
endmodule
