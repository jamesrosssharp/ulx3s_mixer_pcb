/* vim: set et ts=4 sw=4: */

/*
	ULX3S Mixer

deemph.v: FM deemphasis filter

License: MIT License

Copyright 2023 J.R.Sharp

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

/* This filter will run after FM demod, at rate 100MHz / 200 = 500kHz */

/* Filter formula:
*
*   512 * yn+1 = (512 - 4 - 1) yn + (4 + 1) xn
*
*/

module deemph (
    input  CLK,
    input  RSTb,
    input  [15:0] xin,
    input  in_tick,
    output [15:0] yout,
    output reg out_tick
);

reg [24:0] a = 25'd0;
reg [24:0] b = 25'd0;
reg [24:0] c = 25'd0;

localparam state_idle = 2'b00;
localparam state_add1 = 2'b01;
localparam state_add2 = 2'b10;
localparam state_out = 2'b11;

reg [1:0] state = state_idle;

always @(posedge CLK)
begin
    case (state)
        state_idle:
            if (in_tick == 1'b1)
                state <= state_add1;
        state_add1:
            state <= state_add2;
        state_add2:
            state <= state_out;
        state_out:
            state <= state_idle;
    endcase        
end

always @(posedge CLK)
begin
    out_tick <= 1'b0;

    if (RSTb == 1'b0) begin

        a <= 25'd0;
        b <= 25'd0;
        c <= 25'd0;

    end else begin

        case (state)
            state_idle: ;
            state_add1: begin 
                a <= c - {7'd0, c[24:7]} - {9'd0, c[24:9]};
                b <= {7'd0, xin, 2'd0} + {9'd0, xin};
            end
            state_add2: begin
               c <= a + b;
            end
            state_out: begin
                out_tick <= 1'b1;
            end
        endcase     

    end
end

assign yout = c[24:9];

endmodule
