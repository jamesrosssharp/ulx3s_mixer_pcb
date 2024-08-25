/* vim: set et ts=4 sw=4: */

/*
	ULX3S Mixer

bandpass_19khz.v: 19kHz bandpass filter

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
 *   512 * yn = 984 yn-1 - 501 yn-2 + 10 xn - 10 xn-2
 *
 */

module bandpass_19kHz (
    input  CLK,
    input  RSTb,
    input  signed [15:0] xin,
    input  in_tick,
    output signed [15:0] yout,
    output reg out_tick
);

reg signed [15:0] yn   = 16'd0;
reg signed [15:0] yn_1 = 16'd0;
reg signed [15:0] yn_2 = 16'd0;
reg signed [15:0] xn_0 = 16'd0;
reg signed [15:0] xn_1 = 16'd0;
reg signed [15:0] xn_2 = 16'd0;

reg signed [24:0] a = 25'd0;
reg signed [24:0] b = 25'd0;


localparam state_idle  = 3'b000;
localparam state_shift = 3'b001;
localparam state_mul   = 3'b010;
localparam state_add   = 3'b011;
localparam state_out   = 3'b100;

reg [2:0] state = state_idle;

always @(posedge CLK)
begin
    case (state)
        state_idle:
            if (in_tick == 1'b1)
                state <= state_shift;
        state_shift:
            state <= state_mul;
        state_mul:
            state <= state_add;
        state_add:
            state <= state_out;
        state_out:
            state <= state_idle;
    endcase        
end

wire signed [24:0] sum = a + b;

always @(posedge CLK)
begin
    out_tick <= 1'b0;

    if (RSTb == 1'b0) begin

        yn   <= 16'd0;
        yn_1 <= 16'd0;
        yn_2 <= 16'd0;
        xn_1 <= 16'd0;
        xn_2 <= 16'd0;
        xn_0 <= 16'd0;

    end else begin

        case (state)
            state_idle: ;
            state_shift: begin 
                xn_0 <= xin;
                xn_1 <= xn_0;
                xn_2 <= xn_1;

                yn_1 <= yn;
                yn_2 <= yn_1;
            end
            state_mul: begin
                /*   512 * yn = 984 yn-1 - 501 yn-2 + 10 xn - 10 xn-2 */
                a <= (16'sd993 * yn_1) - (26'sd510 * yn_2);            
                b <= (24'sd2 *  xn_0) - (24'sd2 * xn_2);
            end
            state_add: begin
                yn <= sum[24:9];
            end
            state_out:
                out_tick <= 1'b1;
        endcase     

    end
end

assign yout = yn[15:0];

endmodule


