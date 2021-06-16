/* ****************************************************************************
-- (C) Copyright 2017 Kevin M. Hubbard @ Black Mesa Labs - All rights reserved.
-- Source file: vga_core.v           
-- Date:        12.14.2017     
-- Author:      khubbard
-- Description: Test design for VGA core.
-- Language:    Verilog-2001 and VHDL-1993
-- Simulation:  Mentor-Modelsim 
-- Synthesis:   Xilinst-XST 
-- License:     This project is licensed with the CERN Open Hardware Licence
--              v1.2.  You may redistribute and modify this project under the
--              terms of the CERN OHL v.1.2. (http://ohwr.org/cernohl).
--              This project is distributed WITHOUT ANY EXPRESS OR IMPLIED
--              WARRANTY, INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY
--              AND FITNESS FOR A PARTICULAR PURPOSE. Please see the CERN OHL
--              v.1.2 for applicable Conditions.
--
-- Revision History:
-- Ver#  When      Who      What
-- ----  --------  -------- ---------------------------------------------------
-- 0.1   12.14.17  khubbard Creation
-- ***************************************************************************/
`default_nettype none // Strictly enforce all nets to be declared

module vga_core
(
  input  wire         reset,
  input  wire         color_3b,      // 0 for 12b color, 1 for 3b color
  input  wire         mode_bit,      // 0 for test pattern, 1 for demos
  input  wire         clk_dot,       // 40 MHz dot clock
  input  wire  [31:0] random_num,    // seed for color and direction changes
  output wire  [23:0] vga_pixel_rgb, // Output pixel in Red,Green,Blue
  output wire         vga_active,    // aka DE
  output wire         vga_hsync,     // aka HS
  output wire         vga_vsync      // aka VS
);

  reg  [15:0]   u0_pel_x;
  reg  [15:0]   u0_pel_y;
  reg  [23:0]   vga_rgb_tp;
  wire [23:0]   vga_rgb_ball;
  reg  [23:0]   vga_rgb_line;
  reg  [23:0]   vga_rgb;
  wire [7:0]    ramp;

  reg  [15:0]   ball_x_dir;
  reg  [15:0]   ball_y_dir;
  reg  [23:0]   ball_x_pos;
  reg  [23:0]   ball_y_pos;
  wire [11:0]   ball_x_diff;
  wire [11:0]   ball_y_diff;
  reg           ball_x_match;
  reg           ball_y_match;

  reg  [3:0]    dir_chg_sr;
  reg  [23:0]   ball_rgb;
  reg  [3:0]    demo_mode;
  reg           mode_bit_p1;
  reg  [15:0]   line_x0_pos;
  reg  [15:0]   line_x1_pos;
  reg  [15:0]   line_y0_pos;
  reg  [15:0]   line_y1_pos;
  reg  [23:0]   line_rgb;


  wire          u0_vid_new_frame;
  wire          u0_vid_new_line;
  wire          u0_vid_active;
  wire          u0_vga_hsync;
  wire          u0_vga_vsync;

  assign vga_active    = u0_vid_active;
  assign vga_hsync     = u0_vga_hsync;
  assign vga_vsync     = u0_vga_vsync;
  assign vga_pixel_rgb = vga_rgb[23:0];
  assign ramp          = { u0_pel_x[6:0], 1'b0 };


// ----------------------------------------------------------------------------
// RGB Output Mux: Drive RGB with Either Test Pattern or one of two demos
// ----------------------------------------------------------------------------
always @ ( posedge clk_dot ) begin : proc_out_mux 
 begin
  mode_bit_p1 <= mode_bit;
  if ( color_3b == 0 ) begin
    if ( mode_bit == 0 ) begin
      vga_rgb <= vga_rgb_tp[23:0];
    end else begin
      if ( mode_bit_p1 == 0 ) begin
        demo_mode <= ~demo_mode[3:0];
      end
        if ( demo_mode[0] == 0 ) begin
        vga_rgb <= vga_rgb_ball[23:0];
      end else begin
        vga_rgb <= vga_rgb_line[23:0];
      end 
    end 
  end else begin
    if ( mode_bit == 0 ) begin
      vga_rgb[23:16] <= ( vga_rgb_tp[23:16] >= 8'd128 ) ? 8'hFF : 8'h00;
      vga_rgb[15:8 ] <= ( vga_rgb_tp[15:8 ] >= 8'd128 ) ? 8'hFF : 8'h00;
      vga_rgb[7:0  ] <= ( vga_rgb_tp[7:0  ] >= 8'd128 ) ? 8'hFF : 8'h00;
    end else begin
      if ( mode_bit_p1 == 0 ) begin
        demo_mode <= ~demo_mode[3:0];
      end
        if ( demo_mode[0] == 0 ) begin
        vga_rgb[23:16] <= ( vga_rgb_ball[23:16] >= 8'd128 ) ? 8'hFF : 8'h00;
        vga_rgb[15:8 ] <= ( vga_rgb_ball[15:8 ] >= 8'd128 ) ? 8'hFF : 8'h00;
        vga_rgb[7:0  ] <= ( vga_rgb_ball[7:0  ] >= 8'd128 ) ? 8'hFF : 8'h00;
      end else begin
        vga_rgb[23:16] <= ( vga_rgb_line[23:16] >= 8'd128 ) ? 8'hFF : 8'h00;
        vga_rgb[15:8 ] <= ( vga_rgb_line[15:8 ] >= 8'd128 ) ? 8'hFF : 8'h00;
        vga_rgb[7:0  ] <= ( vga_rgb_line[7:0  ] >= 8'd128 ) ? 8'hFF : 8'h00;
      end 
    end 
  end
 end
end // proc_out_mux


// ----------------------------------------------------------------------------
// Moving Lines 
// ----------------------------------------------------------------------------
always @ ( posedge clk_dot ) begin : proc_line
 begin
  if ( mode_bit == 0 ) begin
    line_x0_pos <= 16'd0;
    line_x1_pos <= 16'd799;
    line_y0_pos <= 16'd0;
    line_y1_pos <= 16'd599;
    line_rgb    <= random_num[23:0];// Change color
  end else begin
    if ( u0_vid_new_frame == 1 ) begin
      line_x0_pos <= line_x0_pos + 1;
	  line_x1_pos <= line_x1_pos - 1;
      line_y0_pos <= line_y0_pos + 1;
      line_y1_pos <= line_y1_pos - 1;
      if ( line_x0_pos == 16'd400 || line_y0_pos == 16'd300 ) begin
		line_x0_pos <= 16'd0;
		line_x1_pos <= 16'd799;
        line_y0_pos <= 16'd0;
        line_y1_pos <= 16'd599;
        line_rgb    <= random_num[23:0];// Change color
      end
    end
    vga_rgb_line[23:0] <= { 8'd0, 8'd0, 8'd0 };
    if ( u0_pel_x == line_x0_pos[15:0] ||
         u0_pel_x == line_x1_pos[15:0] ||
         u0_pel_y == line_y0_pos[15:0] ||
         u0_pel_y == line_y1_pos[15:0]    ) begin
      vga_rgb_line[23:0] <= { 1'b1, line_rgb[22:0] };
    end
  end
 end // clk+reset
end // proc_line


// ----------------------------------------------------------------------------
// Bouncing Ball
// ----------------------------------------------------------------------------

// Diff between current pos and ball center (limit to 12 bits, it's enough
// for the range and helps timing)
assign ball_x_diff = {1'b0, u0_pel_x[10:0]} - {1'b0, ball_x_pos[18:8]};
assign ball_y_diff = {1'b0, u0_pel_y[10:0]} - {1'b0, ball_y_pos[18:8]};

always @ ( posedge clk_dot ) begin : proc_ball
 begin
  if ( mode_bit == 0 ) begin
    ball_x_pos <= {16'd400, 8'd0 };       // Start in center of 800x600
    ball_y_pos <= {16'd300, 8'd0 };
    ball_rgb   <= random_num[23:0];            // Get a random RGB Ball color
    ball_x_dir <= { 2'b01, random_num[11:2]  };// 4bit int,8bit fract direction
    ball_y_dir <= { 2'b01, random_num[23:14] };// 4bit int,8bit fract direction
  end else begin
    // Move the ball every VSYNC and check for out of bounds.
    // If out of bounds this VSYNC, but not previous VSYNC then invert the 
    // direction vectors. This effectively bounces a ball off perimeter wall
    if ( u0_vid_new_frame == 1 ) begin
      dir_chg_sr <= { dir_chg_sr[2:0], 1'b0 };
      ball_x_pos <= ball_x_pos + { {12{ball_x_dir[11]}}, ball_x_dir[11:0] };
      ball_y_pos <= ball_y_pos + { {12{ball_y_dir[11]}}, ball_y_dir[11:0] };
      
      if          ( ball_x_pos[23:8] <  32 && dir_chg_sr == 4'd0 ) begin
        ball_x_dir    <= ~ ball_x_dir[11:0];
        dir_chg_sr[0] <= 1;
      end else if ( ball_x_pos[23:8] > 768 && dir_chg_sr == 4'd0 ) begin
        ball_x_dir    <= ~ ball_x_dir[11:0];
        dir_chg_sr[0] <= 1;
      end
      if          ( ball_y_pos[23:8] <  32 && dir_chg_sr == 4'd0 ) begin
        ball_y_dir    <= ~ ball_y_dir[11:0];
        dir_chg_sr[0] <= 1;
      end else if ( ball_y_pos[23:8] > 550 && dir_chg_sr == 4'd0 ) begin
        ball_y_dir    <= ~ ball_y_dir[11:0];
        dir_chg_sr[0] <= 1;
      end
      if ( dir_chg_sr[0] == 1 ) begin
        ball_rgb   <= random_num[23:0];// Change ball color every bounce
      end
    end

    // Bounding box -8 to 7 around each axis
    ball_x_match <= {8{ball_x_diff[11]}} == ball_x_diff[10:3];
    ball_y_match <= {8{ball_y_diff[11]}} == ball_y_diff[10:3];
  end
 end // clk+reset
end // proc_ball

assign vga_rgb_ball = (ball_x_match && ball_y_match) ? { 1'b1, ball_rgb[22:0] } : { 8'h00, 8'h00, 8'h00 };


// ----------------------------------------------------------------------------
// Test Pattern 
// ----------------------------------------------------------------------------
always @ ( posedge clk_dot ) begin : proc_test_pattern 
 begin
  //             Red  Green  Blue
  if          ( u0_pel_x[9:7] == 3'd6 ) begin
    vga_rgb_tp <= { ramp, ramp, ramp };// White
  end else if ( u0_pel_x[9:7] == 3'd5 ) begin
    vga_rgb_tp <= { ramp, ramp, 8'd0 };// Yellow
  end else if ( u0_pel_x[9:7] == 3'd4 ) begin
    vga_rgb_tp <= { 8'd0, ramp, ramp };// Cyan 
  end else if ( u0_pel_x[9:7] == 3'd3 ) begin
    vga_rgb_tp <= { 8'd0, ramp, 8'd0 };// Green
  end else if ( u0_pel_x[9:7] == 3'd2 ) begin
    vga_rgb_tp <= { ramp, 8'd0, ramp };// Magenta
  end else if ( u0_pel_x[9:7] == 3'd1 ) begin
    vga_rgb_tp <= { ramp, 8'd0, 8'd0 };// Red    
  end else if ( u0_pel_x[9:7] == 3'd0 ) begin
    vga_rgb_tp <= { 8'd0, 8'd0, ramp };// Blue   
  end

 end // clk+reset
end // proc_test_pattern


// ----------------------------------------------------------------------------
// Raster Counters. Count the Pixel Location in X and Y
// ----------------------------------------------------------------------------
always @ ( posedge clk_dot ) begin : proc_u0_raster_cnt
 begin
  if ( u0_vid_new_frame == 1 ) begin
    u0_pel_y <= 16'd0;
  end else if ( u0_vid_new_line == 1 ) begin
    if ( u0_pel_y == 16'hFFFF ) begin
      u0_pel_y <= 16'hFFFF;// Prevent rollover
    end else begin
      u0_pel_y <= u0_pel_y + 1;
    end
  end // if ( vid_new_frame == 1 ) begin

  if ( u0_vid_new_line == 1 ) begin
    u0_pel_x <= 16'd0;
  end else begin
    if ( u0_pel_x == 16'hFFFF ) begin
      u0_pel_x <= 16'hFFFF;// Prevent rollover
    end else begin
      u0_pel_x <= u0_pel_x + 1;
    end
  end  // if ( vid_new_line  == 1 ) begin

 end // clk+reset
end // proc_u0_raster_cnt


// ----------------------------------------------------------------------------
// VGA Timing Generator
// ----------------------------------------------------------------------------
vga_timing u0_vga_timing
(
  .reset                           ( reset             ),
  .clk_dot                         ( clk_dot           ),
  .vid_new_frame                   ( u0_vid_new_frame  ),
  .vid_new_line                    ( u0_vid_new_line   ),
  .vid_active                      ( u0_vid_active     ),
  .vga_hsync                       ( u0_vga_hsync      ),
  .vga_vsync                       ( u0_vga_vsync      )
);


endmodule // vga_core
