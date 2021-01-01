/* ****************************************************************************
-- (C) Copyright 2017 Kevin M. Hubbard @ Black Mess Labs - All rights reserved.
-- Source file: top.v (now vga-12bit.v)
-- Date:        December 2017
-- Author:      khubbard
-- Description: Spartan3 Test Design 
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
--
-- 12b Digilent VGA Module - Facing module pins
--      -----------------------------       -----------------------------
--     | 1-R0 2-R1 3-R2  4-R3 GND 3V |     | 1-G0 2-G1 3-G2  4-G3 GND 3V |
--     | 7-B0 8-B1 9-B2 10-B3 GND 3V |     | 7-HS 8-VS 9-NC 10-NC GND 3V |
--  ___|_____________________________|_____|_____________________________|_
-- |       BML HDMI 12b color PMOD board                                   |
--  -----------------------------------------------------------------------
--       pmod_*_*<1> = r[0]                    pmod_*_*<1> = g[0]
--       pmod_*_*<2> = r[1]                    pmod_*_*<2> = g[1]
--       pmod_*_*<3> = r[2]                    pmod_*_*<3> = g[2]
--       pmod_*_*<4> = r[3]                    pmod_*_*<4> = g[3]
--       pmod_*_*<7> = b[0]                    pmod_*_*<7> = hs
--       pmod_*_*<8> = b[1]                    pmod_*_*<8> = vs
--       pmod_*_*<9> = b[2]                    pmod_*_*<9> = nc
--       pmod_*_*<10> = b[3]                   pmod_*_*<10> = nc
--
-- Revision History:
-- Ver#  When      Who      What
-- ----  --------  -------- ---------------------------------------------------
-- 0.1   12.14.17  khubbard Creation
-- 0.2   12.31.20  tcal-x   Modified for VGA PMOD
-- ***************************************************************************/
`default_nettype none // Strictly enforce all nets to be declared
                                                                                
module top
(
  input  CLK,

  output LEDR_N, // on board red
  output LEDG_N, // on board green
  input  BTN_N,  // user button aka reset

  output P1A1, P1A2, P1A3, P1A4, P1A7, P1A8, P1A9, P1A10,
  output P1B1, P1B2, P1B3, P1B4, P1B7, P1B8, P1B9, P1B10


);// module top


  wire          reset_loc;
  wire          clk_40m_tree;
  reg  [29:0]   led_cnt;
  wire          vga_de;
  wire          vga_ck;
  wire          vga_hs;
  wire          vga_vs;
  wire [23:0]   vga_rgb;
  reg  [31:0]   random_num;
  wire [7:0]    r;
  wire [7:0]    g;
  wire [7:0]    b;
  reg           mode_bit;
  wire          ok_led_loc;


  assign reset_loc  = ~BTN_N;

//-----------------------------------------------------------------------------
// PLL.
//-----------------------------------------------------------------------------
SB_PLL40_PAD #(
  .DIVR(4'b0000),
  // 40MHz ish to be exact it is 39.750MHz
  //.DIVF(7'b0110111), // 42MHz
  .DIVF(7'b0110101), // 39.750MHz
  .DIVQ(3'b100),
  .FILTER_RANGE(3'b001),
  .FEEDBACK_PATH("SIMPLE"),
  .DELAY_ADJUSTMENT_MODE_FEEDBACK("FIXED"),
  .FDA_FEEDBACK(4'b0000),
  .DELAY_ADJUSTMENT_MODE_RELATIVE("FIXED"),
  .FDA_RELATIVE(4'b0000),
  .SHIFTREG_DIV_MODE(2'b00),
  .PLLOUT_SELECT("GENCLK"),
  .ENABLE_ICEGATE(1'b0)
) usb_pll_inst (
  .PACKAGEPIN(CLK),
  .PLLOUTCORE(clk_40m_tree),
  //.PLLOUTGLOBAL(),
  .EXTFEEDBACK(),
  .DYNAMICDELAY(),
  .RESETB(1'b1),
  .BYPASS(1'b0),
  .LATCHINPUTVALUE(),
  //.LOCK(),
  //.SDI(),
  //.SDO(),
  //.SCLK()
);

//-----------------------------------------------------------------------------
// Flash an LED. Also control the VGA demos, toggle between color pattern and
// either a bouncing ball or moving lines.
//-----------------------------------------------------------------------------
always @ ( posedge clk_40m_tree or posedge reset_loc ) begin : proc_led 
 if ( reset_loc == 1 ) begin
   random_num   <= 32'd0;
   led_cnt      <= 30'd0;
   ok_led_loc   <= 0;
   mode_bit     <= 0;
 end else begin
   random_num   <= random_num + 3;
   ok_led_loc   <= 0;
   led_cnt      <= led_cnt + 1;
   if ( led_cnt[24] == 1 ) begin
     ok_led_loc <= 1;
   end
   if ( led_cnt[29:27] == 3'd0 ) begin
     mode_bit <= 0;
   end else begin
     mode_bit <= 1;
   end 

 end // clk+reset
end // proc_led

assign LEDG_N = ok_led_loc;
assign LEDR_N = ~reset_loc;

// ----------------------------------------------------------------------------
// VGA Timing Generator
// ----------------------------------------------------------------------------
vga_core u_vga_core
(
  .reset             ( reset_loc           ),
  .random_num        ( random_num[31:0]    ),
  .color_3b          ( 1'b0                ),
  .mode_bit          ( mode_bit            ),
  .clk_dot           ( clk_40m_tree        ),
  .vga_active        ( vga_de              ),
  .vga_hsync         ( vga_hs              ),
  .vga_vsync         ( vga_vs              ),
  .vga_pixel_rgb     ( vga_rgb[23:0]       )
);
  assign r = vga_rgb[23:16];
  assign g = vga_rgb[15:8];
  assign b = vga_rgb[7:0];


// ----------------------------------------------------------------------------
// Assign the PMOD(s) for either 3b or 12b HDMI Module from Black Mesa Labs
// DDR Flop to Mirror pixel clock to TFP410 
// ----------------------------------------------------------------------------
//FDDRCPE u1_FDDRCPE
//(
//  .C0  ( clk_40m_tree   ), .C1  ( ~ clk_40m_tree   ),
//  .CE  ( 1'b1           ),
//  .CLR ( 1'b0           ), .PRE ( 1'b0      ),
//  .D0  ( 1'b1           ), .D1  ( 1'b0      ),
//  .Q   ( vga_ck         ) 
//);

assign vga_ck = clk_40m_tree;

// 3b for single-PMOD
//assign {P1A1,   P1A2,   P1A3,   P1A4,   P1A7,   P1A8,   P1A9,   P1A10} = 
//       {g[7],   vga_ck, vga_hs, 1'b0,   r[7],   b[7],   vga_de, vga_vs};


// 12b for dual-PMOD
//assign {P1A1,   P1A2,   P1A3,   P1A4,   P1A7,   P1A8,   P1A9,   P1A10} = 
//       {r[7],   r[5],   g[7],   g[5],   r[6],   r[4],   g[6],   g[4]};
//assign {P1B1,   P1B2,   P1B3,   P1B4,   P1B7,   P1B8,   P1B9,   P1B10} = 
//       {b[7],   vga_ck, b[4],   vga_hs, b[6],   b[5],   vga_de, vga_vs};

// 12b for dual-PMOD digilent VGA
assign {P1A1,   P1A2,   P1A3,   P1A4,   P1A7,   P1A8,   P1A9,   P1A10} = 
       {r[4],   r[5],   r[6],   r[7],   b[4],   b[5],   b[6],   b[7]};
assign {P1B1,   P1B2,   P1B3,   P1B4,   P1B7,   P1B8,   P1B9,   P1B10} = 
       {g[4],   g[5],   g[6],   g[7],   vga_hs, vga_vs, 1'b0,   1'b0};

endmodule // top.v
