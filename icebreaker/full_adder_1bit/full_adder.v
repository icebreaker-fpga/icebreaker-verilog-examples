/*
 *  icebreaker examples - 1-bit full adder
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

// Pressing the buttons 1-3 (or not) in various combinations
// will represent the two-bit binary numbers 00, 01, 10 and 11
// by enabling some of the built-in LEDs.

module top(BTN1, BTN2, BTN3, LED1, LED2);
   input BTN1, BTN2, BTN3;
   output LED1, LED2;
   wire [1:0] Sum;
   wire   A, B, Cin;
   assign   BTN1 = A, BTN2 = B, BTN3 = Cin;
   assign {LED1, LED2} = Sum;
   assign Sum = A + B + Cin;
endmodule
