/* vim: set et ts=4 sw=4: */

/*
	ULX3S Mixer

dpll.v: Digital phase locked loop

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

module dpll (

    input CLK,              /* 100MHz clock */
    input RSTb,             /* Reset line   */

    input sigin,            /* The input digital signal to lock to */

    input [2:0] m,          /* The divider in the feedback path */
    input [1:0] n,          /* The postscaler */

    output [15:0] sigout,    /* The sinusoidal output, phase locked to input */

    output digout            /* The digital output, phase locked to a multiple of input */

);

reg [34:0] count        = 35'd0;   /* NCO Count - we include for additional bits 
                                      in the count for postscaler */ 
reg [31:0] phase_incr   = 32'd6000; /* NCO phase increment will run from
                                        6000 = 35kHz to
                                        10000 = 59kHz */
always @(posedge CLK) 
begin
    if (RSTb == 1'b0) begin
        count <= 36'd0;
    end
    else
        count <= count + {3'd0, phase_incr};

end

// Divider in feedback path

reg prev_count_31 = 1'b0;

reg [2:0] divide_count = 3'd0;

reg divide_out = 1'b0;

always @(posedge CLK)
begin
    prev_count_31 <= count[31];

    if (count[31] != prev_count_31) begin
        divide_count <= divide_count + 1;
   
        if (divide_count == m) begin
            divide_count <= 3'd0;
            divide_out <= ! divide_out;
        end
    end
end

// Phase error detector 

reg up   = 1'b0;
reg down = 1'b0;

reg in_del = 1'b0;
reg div_del = 1'b0;

wire in_up  = (sigin == 1'b1        && in_del  == 1'b0);
wire div_up = (divide_out == 1'b1   && div_del == 1'b0);

always @(posedge CLK)
begin
    in_del  <= sigin;
    div_del <= divide_out;

    case ({in_up, div_up, up, down})
        4'b0000:
            {up, down} <= {1'b0, 1'b0};
        4'b0001:
            {up, down} <= {1'b0, 1'b1};
        4'b0010:
            {up, down} <= {1'b1, 1'b0};
        4'b0011:
            {up, down} <= {1'b0, 1'b0};
        4'b0100:
            {up, down} <= {1'b0, 1'b1};
        4'b0101:
            {up, down} <= {1'b0, 1'b1};
        4'b0110:
            {up, down} <= {1'b0, 1'b0};
        4'b0111:
            {up, down} <= {1'b0, 1'b0};
        4'b1000:
            {up, down} <= {1'b1, 1'b0};
        4'b1001:
            {up, down} <= {1'b0, 1'b0};
        4'b1010:
            {up, down} <= {1'b1, 1'b0};
        4'b1011:
            {up, down} <= {1'b0, 1'b0};
        4'b1100:
            {up, down} <= {1'b0, 1'b0};
        4'b1101:
            {up, down} <= {1'b0, 1'b0};
        4'b1110:
            {up, down} <= {1'b0, 1'b0};
        4'b1111:
            {up, down} <= {1'b0, 1'b0};
    endcase
end

reg [31:0] phase_err = 32'd0;
reg [45:0] phase_filter = 46'd0;

always @(posedge CLK)
begin

    if (up == 1'b1)
        phase_err <= 32'd1675037;   // 39kHz
    else if (down == 1'b1)
        phase_err <= 32'd1589137;   // 37kHz
//    else 
//        phase_err <= phase_incr;

    phase_filter <= phase_filter - {14'd0, phase_filter[45:14]} + phase_err;
    phase_incr <= phase_filter[45:14];

end

// Implement post divider

reg [31:0] count_out;

always @(posedge CLK)
begin
    case (n)
        2'b00:
            count_out <= count[31:0];
        2'b01:
            count_out <= count[32:1];
        2'b10:
            count_out <= count[33:2];
        2'b11:
            count_out <= count[34:3];
    endcase
end

cosTable c0(CLK, count_out[31:22], sigout);

assign digout = !count_out[31];

endmodule
