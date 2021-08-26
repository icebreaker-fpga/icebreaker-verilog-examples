`timescale 1ns / 1ps

module top(
    input CLK,
    output P2_1, P2_2, P2_3, P2_4, P2_7, P2_8, P2_9, P2_10
  );

  localparam CLK_FREQUENCY = 12E6;
  localparam COUNTER_MAX = $rtoi(CLK_FREQUENCY/1000);

  wire [7:0] pmodmap;
  reg [31:0] milliseconds = 0;
  reg [$clog2(COUNTER_MAX)-1:0] counter;

  // Count milliseconds
  always @(posedge CLK)
  begin
    if (counter < COUNTER_MAX)
      counter <= counter + 1;
    else
    begin
      counter <= 0;
      milliseconds <= milliseconds + 1;
    end
  end

  // map output pins of pmodcharlie module to pins on iCEBreaker
  assign pmodmap[0] = P2_1;
  assign pmodmap[1] = P2_8;
  assign pmodmap[2] = P2_4;
  assign pmodmap[3] = P2_10;
  assign pmodmap[4] = P2_9;
  assign pmodmap[5] = P2_2;
  assign pmodmap[6] = P2_7;
  assign pmodmap[7] = P2_3;

  pmodcharlie pmodCharlieA(
    .clk(CLK),
    .pins(pmodmap),
    .display_data(milliseconds)
  );

endmodule

module pmodcharlie
  #(
    parameter CLK_FREQUENCY = 12E6,
    parameter DISPLAY_FREQUENCY = 1E3
  )
  (
    input wire clk,
    input wire [31:0] display_data,
    output wire [7:0] pins
  );

  localparam NUMBER_OF_DIGITS = 8;
  reg [$clog2(NUMBER_OF_DIGITS)-1:0] current_digit;
  localparam NUMBER_OF_SEGMENTS = 7;
  reg [$clog2(NUMBER_OF_SEGMENTS)-1:0] current_segment;
  reg [$clog2(NUMBER_OF_DIGITS)-1:0] current_segment2;

  reg [7:0] tristate_pins;
  reg [7:0] output_pins;
  reg [6:0] segments;
  reg [3:0] digit_data;

  localparam SEGMENT_TIMER_MAX = $rtoi($ceil(CLK_FREQUENCY / (DISPLAY_FREQUENCY * (NUMBER_OF_DIGITS*NUMBER_OF_SEGMENTS))));
  reg [$clog2(SEGMENT_TIMER_MAX)-1:0] segment_timer;
  reg [$clog2(NUMBER_OF_SEGMENTS)-1:0] segment_counter;

  // Get current active segment and digit depending on clk
  always @(posedge clk)
  begin
    if (segment_timer != 0)
      segment_timer = segment_timer - 1;
    else
    begin
      if (current_segment < NUMBER_OF_SEGMENTS-1)
        current_segment <= current_segment + 1;
      else
        current_segment <= 0;

      segment_timer <= SEGMENT_TIMER_MAX;
      if (segment_counter != 0)
        segment_counter <= segment_counter - 1;
      else
      begin
        if (current_digit < NUMBER_OF_DIGITS-1)
          current_digit <= current_digit + 1;
        else
          current_digit <= 0;
        segment_counter <= NUMBER_OF_SEGMENTS;
      end
    end
  end

  // Map display_data to digit_data depening on current active digit
  always @(*)
  begin
    case (current_digit) // current_digit
      0: digit_data = display_data[3:0];
      1: digit_data = display_data[7:4];
      2: digit_data = display_data[11:8];
      3: digit_data = display_data[15:12];
      4: digit_data = display_data[19:16];
      5: digit_data = display_data[23:20];
      6: digit_data = display_data[27:24];
      7: digit_data = display_data[31:28];
      default: digit_data = 4'b0000;
    endcase
  end

  // Map digit_data to segments
  always @(*) begin
    case (digit_data)
      'h0: segments = 'b0111111;
      'h1: segments = 'b0000110;
      'h2: segments = 'b1011011;
      'h3: segments = 'b1001111;
      'h4: segments = 'b1100110;
      'h5: segments = 'b1101101;
      'h6: segments = 'b1111101;
      'h7: segments = 'b0000111;
      'h8: segments = 'b1111111;
      'h9: segments = 'b1101111;
      'hA: segments = 'b1110111;
      'hB: segments = 'b1111100;
      'hC: segments = 'b0111001;
      'hD: segments = 'b1011110;
      'hE: segments = 'b1111001;
      'hF: segments = 'b1110001;
      default: segments = 7'b0000000;
    endcase
  end

  // Configure pins depending on current active digit & segment
  always @(posedge clk) begin
    output_pins <= 'h0;
    output_pins[current_digit] <= 1;

    if (current_segment < current_digit)
      current_segment2 <= current_segment;
    else
      current_segment2 <= current_segment+1;

    tristate_pins <= 'h0;
    tristate_pins[current_digit] <= 1;
    tristate_pins[current_segment2] <= segments[current_segment];
  end

  SB_IO #(
    .PIN_TYPE(6'b 1010_01),
    .PULLUP(1'b 0)
  ) led_io[7:0] (
    .PACKAGE_PIN(pins),
    .OUTPUT_ENABLE(tristate_pins),
    .D_OUT_0(output_pins),
  );

endmodule
