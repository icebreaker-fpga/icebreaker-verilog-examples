/* ****************************************************************************
-- (C) Copyright 2013 Kevin M. Hubbard @ Black Mesa Labs - All rights reserved.
-- Source file: vga_timing.v         
-- Date:        April 20, 2013
-- Author:      khubbard
-- Description: Generate Analog VGA Timing signals
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
-- Binary              
--      --------  2.5V  ----------  4V          Node
--     |  FPGA  |----->| 74ACT245 |----[220ohm]--+--[100ohm]-GND : Red  0,0.7V
--     |        |----->|          |----[220ohm]--+--[100ohm]-GND : Grn  0,0.7V
--     |        |----->|          |----[220ohm]--+--[100ohm]-GND : Blu  0,0.7V
--     |        |----->|          |------------------------------> HSYNC   
--     |        |----->|  VCC=5V  |------------------------------> VSYNC   
--      --------        ----------              
--
-- 2 Shades
--           R(0)----->| 74ACT245 |----[560ohm]--+--[100ohm]-GND : Red at +
--           R(1)----->|          |----[560ohm]--+               : Grn at +
--
-- Note: Monitor has 75 termination for all signals, so the resistor divider
--       was adjusted to get 0.7V Max on the line. Assert R(0) and R(1) for
--       bright Red, or just one for a dimmer Red.
--
-- Video Timing:
--                |-BP-|Active Video|-FP|   
--       SYNC __/ \_____________________/ \_
--
--                       HSYNC BP   H    FP  Htotal  VSYNC BP  V    FP Vtotal
-- 800x600    40MHz 60Hz 128   88  800   40  1056    4     23 600   1  628
-- 1024x768   65MHz 60Hz 136   160 1024  24  1344    6     29 768   3  806 
-- 1280x1024 108MHz 60Hz 112   248 1280  48  1688    3     38 1024  1  1066
--  640x1024  54MHz 60Hz  56   124  640  24   844    3     38 1024  1  1066
--
-- Odd - Does this work ??
-- 800x480    40MHz 45Hz 128   88  800  127  1143    128   32 480  127 767
--
-- Note: 40 / 10 = 4 x 27 = 108
-- 
-- ----------------------------------------------------------------------------
-- The pinout for a standard 15-pin VGA-out connector Monitor side (male plug):
-- 
-- /----------------------------------------------\
-- \        1      2      3      4      5         /
--  \                                            /
--   \   6     7      8      9      10          /
--    \                                        /
--     \   11     12     13     14     15     /
--      \------------------------------------/
--
-- 1:  Red Video    0 - 0.7V
-- 2:  Green Video  0 - 0.7V
-- 3:  Blue Video   0 - 0.7V
-- 4:  Monitor ID 2 (To video card from monitor)
-- 5:  TTL Ground (Monitor self-test, used for testing purposes only)
--
-- 6:  Red Analog Ground
-- 7:  Green Analog Ground
-- 8:  Blue Analog Ground
-- 9:  Key (Plugged hole, not used for electronic signals)
-- 10: Sync Ground (For both sync pins)
--
-- 11: Monitor ID 0 (To video card from monitor)
-- 12: Monitor ID 1 (To video card from monitor)
-- 13: Horizontal Sync (To monitor from video card) 0 or 5.0V
-- 14: Vertical Sync (To monitor from video card)   0 or 5.0V
-- 15: Monitor ID 3 (To video card from monitor)
--
--
-- vid_active    ___/     \_____/     \____/     \______/  ....   / \___/ \___
-- vid_new_frame _/ \___________________________________________________/ \___
-- vid_new_line  _/ \________/ \_________/ \_________/ \__ .... / \_____/ \___
--                 0          1           2           3        1023
--
-- VGA to HDMI Converter $25 from Amazon
-- IO Crest VGA to HDMI Convertor with Audio support (SY-ADA31025). 
-- Supports Resolutions:
--   800x600   
--  1024x768 1280x720 1280x800 1280x960 1280x1024
--  1360x768
--  1600x900 1600x1200 1680x1050
--  1920x1080
--
-- Lilliput 7" 669GL LCD Display
-- Native Resolution 800x480. Accepts HDMI 1920x1080
--
-- Revision History:
-- Ver#  When      Who      What
-- ----  --------  -------- ---------------------------------------------------
-- 0.1   06.20.08  khubbard Creation
-- ***************************************************************************/
`default_nettype none // Strictly enforce all nets to be declared


module vga_timing
 (
   input  wire         reset,
   input  wire         clk_dot,
   output reg          vid_new_frame,
   output reg          vid_new_line,
   output reg          vid_active,  
   output reg          vga_hsync,
   output reg          vga_vsync
 );// module vga_timing

// 800x600 40MHz 60Hz
`define def_h_sync     16'd128
`define def_h_bp       16'd88 
`define def_h_actv     16'd800
`define def_h_fp       16'd40
`define def_h_total    16'd1056
`define def_v_sync     16'd4  
`define def_v_bp       16'd23 
`define def_v_actv     16'd600
`define def_v_fp       16'd1 
`define def_v_total    16'd628 

// 1280x1024 108MHz 60Hz
/*
`define def_h_sync     16'd112
`define def_h_bp       16'd248
`define def_h_actv     16'd1280
`define def_h_fp       16'd48
`define def_h_total    16'd1688
`define def_v_sync     16'd3  
`define def_v_bp       16'd38 
`define def_v_actv     16'd1024
`define def_v_fp       16'd1 
`define def_v_total    16'd1066
*/

/* Attempt at 480p with 27.7MHz 60 Hz */
/* From http://www.3dexpress.de/displayconfigx/timings.html */
/*
`define def_h_sync     16'd40 
`define def_h_bp       16'd96 
`define def_h_actv     16'd720
`define def_h_fp       16'd24
`define def_h_total    16'd880 

`define def_v_sync     16'd3  
`define def_v_bp       16'd32 
`define def_v_actv     16'd480
`define def_v_fp       16'd10
`define def_v_total    16'd525 
*/

`define state_h_sync   2'd0
`define state_h_bp     2'd1
`define state_h_actv   2'd2
`define state_h_fp     2'd3

`define state_v_sync   2'd0
`define state_v_bp     2'd1
`define state_v_actv   2'd2
`define state_v_fp     2'd3

 reg  [15:0]   cnt_h;
 reg  [15:0]   cnt_v;
 reg  [1:0]    fsm_h;
 reg  [1:0]    fsm_v;
 reg           hsync_loc;
 reg           vsync_loc;
 reg           vsync_loc_p1;
 reg           h_rollover;


//-----------------------------------------------------------------------------
// Flop the outputs
//-----------------------------------------------------------------------------
always @ (posedge clk_dot  or posedge reset ) begin : proc_dout
 if ( reset == 1 ) begin
   vga_hsync    <= 1'b0;
   vga_vsync    <= 1'b0;
   vsync_loc_p1 <= 1'b0;
 end else begin
   vga_hsync    <= hsync_loc;
   vga_vsync    <= vsync_loc;
   vsync_loc_p1 <= vsync_loc;
 end
end

                                                                                
//-----------------------------------------------------------------------------
// VGA State Machine for Horizontal Timing
//-----------------------------------------------------------------------------
always @ (posedge clk_dot  or posedge reset ) begin : proc_vga_h
 if ( reset == 1 ) begin
   hsync_loc     <= 1'b0;
   vid_new_line  <= 1'b0;
   vid_new_frame <= 1'b0;
   vid_active    <= 1'b0;
   cnt_h         <= 16'd1;
   fsm_h         <= `state_h_sync;
   h_rollover    <= 1'b1;
 end else begin
   h_rollover    <= 1'b0;
   vid_new_line  <= 1'b0;
   vid_new_frame <= 1'b0;
   vid_active    <= 1'b0;
   hsync_loc     <= 1'b0;          // Default to HSYNC OFF
   cnt_h         <= cnt_h + 16'd1; // Default to counting

   if ( fsm_h == `state_h_sync ) begin
     hsync_loc  <= 1'b1;
   end
   if ( fsm_h == `state_h_actv && fsm_v == `state_v_actv ) begin
     vid_active   <= 1'b1;
   end

   if ( fsm_h == `state_h_sync && cnt_h == `def_h_sync ) begin
     cnt_h        <= 16'd1;
     fsm_h        <= fsm_h + 2'd1;
   end
   if ( fsm_h == `state_h_bp   && cnt_h == `def_h_bp   ) begin
     cnt_h        <= 16'd1;
     fsm_h        <= fsm_h + 2'd1;
     vid_new_line <= 1'b1;
     if ( fsm_v == `state_v_actv && cnt_v == 16'd2 ) begin
       vid_new_frame <= 1'b1;
     end
   end
   if ( fsm_h == `state_h_actv   && cnt_h == `def_h_actv ) begin
     cnt_h        <= 16'd1;
     fsm_h        <= fsm_h + 2'd1;
   end
   if ( fsm_h == `state_h_fp     && cnt_h == `def_h_fp   ) begin
     cnt_h        <= 16'd1;
     fsm_h        <= fsm_h + 2'd1;
     h_rollover   <= 1'b1;
   end
 end
end // proc_vga_h   


//-----------------------------------------------------------------------------
// VGA State Machine for Vertical Timing
//-----------------------------------------------------------------------------
always @ (posedge clk_dot  or posedge reset ) begin : proc_vga_v
 if ( reset == 1 ) begin
   cnt_v      <= 16'd1;
   vsync_loc  <= 1'b0;
   fsm_v      <= `state_v_fp;
 end else begin
   if ( h_rollover == 1'b1 ) begin
     cnt_v     <= cnt_v + 16'd1; // Default to counting
     vsync_loc <= 1'b0;          // Default to VSYNC OFF
     if ( fsm_v == `state_v_sync && cnt_v == `def_v_sync ) begin
       cnt_v <= 16'd1;
       fsm_v <= fsm_v + 2'd1;
     end
     if ( fsm_v == `state_v_bp   && cnt_v == `def_v_bp   ) begin
       cnt_v <= 16'd1;
       fsm_v <= fsm_v + 2'd1;
     end
     if ( fsm_v == `state_v_actv && cnt_v == `def_v_actv ) begin
       cnt_v <= 16'd1;
       fsm_v <= fsm_v + 2'd1;
     end
     if ( fsm_v == `state_v_fp   && cnt_v == `def_v_fp ) begin
       cnt_v      <= 16'd1;
       fsm_v      <= fsm_v + 2'd1;
       vsync_loc  <= 1'b1;
     end

     if ( fsm_v == `state_v_sync && cnt_v != `def_v_sync ) begin
       vsync_loc  <= 1'b1;
     end
   end
 end
end // proc_vga_v   
                                                                                

endmodule // vga_timing
