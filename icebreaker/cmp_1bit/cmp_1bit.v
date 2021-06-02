/*
 *  icebreaker examples - 1-bit comparator
 *
 *  Copyright (C) 2019 Albin Söderqvist <albin@fripost.org>
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

// Pressing button 1 (A) and/or 2 (B) will compare the two signals
// and enable one of the built-in LEDs:
//      A < B: L2
//      A = B: L1
//      A > B: L3

module top(BTN1, BTN2, CLK, LED1, LED2, LED3);
   input BTN1, BTN2, CLK;
   output LED1, LED2, LED3;
   wire   A, B;
   reg [2:0] out;
   assign {LED2, LED1, LED3} = out;
   assign BTN1 = A;
   assign BTN2 = B;

   always @ (posedge CLK)
     if (A < B)
       out <= 3'b100;
     else if (A == B)
       out <= 3'b010;
     else
       out <= 3'b001;
endmodule
