/*
 *  icebreaker examples - gamma pwm demo
 *
 *  Copyright (C) 2018 Piotr Esden-Tempski <piotr@esden.net>
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

// This program generates a gamma correction table. This table is then loaded
// into bram of the FPGA to provide a lookup table.

#include <stdio.h>
#include <math.h>

#define GAMMA 2.2

int main()
{
	fprintf(stderr, "Generating the gamma lookup table.\n");

	for (int i = 0; i < 256; i++) {
		double dvalue = pow((1.0 / 255.0) * i, GAMMA);
		long lvalue = 0xFFFFl * dvalue;

		fprintf(stderr, ".");

		if ((i % 8) == 0) {
			printf("@%08x", i);
		}
		printf(" %04lX", lvalue);
		//printf("%f\n", value);
		//printf("%5i | %f\n", i, value);
		if ((i % 8) == 7) {
			printf("\n");
		}
	}

	fprintf(stderr, "\ndone\n");

	return 0;
}
