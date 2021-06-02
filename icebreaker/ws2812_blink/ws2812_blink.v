/* Small test design for the WS2812 "Ear" on the iCEBreaker dev board. */

module top (
	input  CLK,

	output LED_RED_N
);

	localparam BITS = 5;
	localparam LOG2DELAY = 22;

	reg [BITS+LOG2DELAY-1:0] counter = 0;
	reg [BITS-1:0] outcnt;

	always @(posedge CLK) begin
		counter <= counter + 1;
		outcnt <= counter >> LOG2DELAY;
	end

	// Generate a ws2812 stream for blinking upto 64 GBR LEDs with a cyclic color
	// pattern of Magenta, Cyan. Yellow, and White.
	// For an RGBW string it just blinks all LEDs with a light Magenta (Magenta + White)
	wire [7:0] byteno = counter[14:7]; // count bytes (3 per pixel)
	wire [2:0] bitno  = counter[6:4];  // count bits in a byte
	wire onbyte = (byteno[1:0] != 0);  // turn off every 4th byte to create color cycle
	wire onbits = (bitno == 6);        // smaller bitno == brighter LED, or MSB to LSB order
	wire blink  = outcnt[1];           // approx 1 Hz
	wire led_red_n;
	reg wsbit;
	// Output a single WS2812 bit:
	//   high for 1 of 4 time slots for a 0 bit
	//   high for 2 of 4 time slots for a 1 bit
	// Using counter[3:2] gives us a time slot frequency
	// of 12Mhz/4 or 3Mhz (or a 0.333uS slot length).
	// This gives an overall bit period of 1.333uS or a bit frequency of 750KHz.
	always @(posedge CLK) begin
		case	(counter[3:2])
			0: wsbit <= 1'b1;
			1: wsbit <= blink && onbits && onbyte ? 1'b1 : 1'b0;
			default: wsbit <= 1'b0;
		endcase
	end
	// Since the WS2812 "Ear" has an inverting output transistor,
	// we have to invert the output logic here.
	// Note that the default off time between blinks is assumed to
	// satisfy the WS2812 reset condition.
	assign led_red_n = byteno < 64*3 ? ~wsbit : 1'b1;

	SB_IO    #(.PIN_TYPE({4'b1010, 2'b01})) io_led_red_n( // PIN_OUTPUT_TRISTATE, PIN_INPUT
			.PACKAGE_PIN(LED_RED_N),
			.OUTPUT_ENABLE(1'b1),
			.D_OUT_0(led_red_n)
	);

endmodule
