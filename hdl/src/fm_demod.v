/* vim: set et ts=4 sw=4: */

/*
 *  (C) 2024 J. R. Sharp
 *
 *  Based on https://hackaday.io/project/170916-fpga-3-r-1-c-mw-and-sw-sdr-receiver by
 *  Alberto Garlassi
 *
 *  See LICENSE.txt for software license
 */

module fm_demod #(
    parameter BITS_IN = 5,
    parameter BITS_OUT = 16,
)
(
    input CLK,
    input RSTb,

    input signed [BITS_IN - 1 : 0] I_in,
    input signed [BITS_IN - 1 : 0] Q_in,
    input load_tick,    /* tick should go high when new sample is ready */

    output reg signed [BITS_OUT - 1:0] demod_out,
    output reg out_tick /* tick will go high when the new FM demodulated sample is ready */

);

reg signed [BITS_IN - 1 : 0] I_in_a;
reg signed [BITS_IN - 1 : 0] Q_in_a;

reg signed [BITS_IN - 1 : 0] I_in_b;
reg signed [BITS_IN - 1 : 0] Q_in_b;

always @(posedge CLK)
begin
    if (load_tick == 1'b1) begin
        I_in_a <= I_in;
        I_in_b <= I_in_a;
        Q_in_a <= Q_in;
        Q_in_b <= Q_in_a;
    end 

end 

// Compute x[n] * x'[n - 1]

localparam state_idle = 2'b00;
localparam state_mult = 2'b01;
localparam state_add  = 2'b10;
localparam state_quad = 2'b11;

reg [1:0] state = state_idle;

always @(posedge CLK)
begin
    case (state)
        state_idle:
            if (load_tick == 1'b1)
                state <= state_mult;
        state_mult:
            state <= state_add;
        state_add:
            state <= state_quad; 
        state_quad:
            state <= state_idle;       
    endcase
end

reg signed [BITS_IN * 2 - 1 : 0] a;
reg signed [BITS_IN * 2 - 1 : 0] b;
reg signed [BITS_IN * 2 - 1 : 0] c;
reg signed [BITS_IN * 2 - 1 : 0] d;

reg signed [BITS_IN*2 - 1 : 0] r;
reg signed [BITS_IN*2 - 1 : 0] i;

wire signed [BITS_OUT - 1:0] data;

wire [9:0] arg_idx = {r[BITS_IN * 2 - 1 : BITS_IN], i[BITS_IN * 2 - 1 : BITS_IN]};

argTable arg0(CLK, arg_idx, data);


always @(posedge CLK)
begin
    out_tick <= 1'b0;
    case (state)
        state_idle: ;
        
        state_mult: begin
            a <= I_in_a * I_in_b;
            b <= Q_in_a * Q_in_b;
            c <= I_in_b * Q_in_a;
            d <= I_in_a * Q_in_b;
        end
        state_add: begin
            r <= a + b;
            i <= c - d; 
            demod_out <= data;
            out_tick <= 1'b1;
        end
        state_quad:     ;
   endcase
end

endmodule
