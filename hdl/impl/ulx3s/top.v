/*
 *	(C) 2022 J. R. Sharp
 *
 *	Top level for ulx3s board
 *
 *	See LICENSE.txt for software license
 */

//`define TEST_GENERATOR

module top (
	input        clk_25mhz,
	input  [6:0] btn,
	output [7:0] led,

	input  gp21,  // RF in
	output gn24, // RF out

`ifdef TEST_GENERATOR
	output gp11, // Test RF out
`endif
	/* i2s audio */
	output       gp20,
  	output       gp19,
  	output       gp18,
  	output       gp17,

	/* vco pwm */
	output	     gp23,

	output       gn7,
	output	     gn8
);


wire clk_locked;
wire [3:0] clocks;
wire pll_clk_100   = clocks[0];
wire pll_clk_25    = clocks[1];
ecp5pll #(
	.in_hz(25000000),
	.out0_hz(100000000),
	.out1_hz( 25000000)
	)
	ecp5pll_inst
	(
		.clk_i(clk_25mhz),
		.clk_o(clocks),
		.locked(clk_locked)
	);

//assign led[0] = clk_locked;
//assign led[7:3] = {7{1'b0}};


/* some blinking leds */

reg [23:0] counter1;
reg [23:0] counter2;

always @(posedge pll_clk_100) counter1 <= counter1 + 1;
always @(posedge pll_clk_25) counter2 <= counter2 + 1;

//assign led[1] = counter1[23];
//assign led[2] = counter2[23];

/* tuning buttons */

always @(posedge pll_clk_100)
begin
	if (counter1 == 24'd0) begin
		if (btn[5] == 1'b1)	/* left */
			phase_inc <= phase_inc + 40'h110c6f7; // 1600 Hz
		if (btn[6] == 1'b1)	/* right */
			phase_inc <= phase_inc - 40'h110c6f7; // 1600 Hz
		
		if (btn[3] == 1'b1)	/* up */
			phase_inc <= phase_inc + 40'h1346dc5d; // 35kHz
		if (btn[4] == 1'b1)	/* down */
			phase_inc <= phase_inc - 40'h1346dc5d; // 35kHz
	end
end


/* AM demodulation */

wire CLK = pll_clk_100;
wire RSTb = 1'b1;

reg [39:0] phase_inc = 40'h2656abde3; // 936 kHz ABC Hobart
//reg [39:0] phase_inc = 40'h41fc8f323; // 1611 kHz
//reg [39:0] phase_inc = 40'h25edd0529; // 926 kHz
//reg [39:0] phase_inc = 40'h1e98dcdb3; // 747 kHz
//reg [39:0] phase_inc = 40'h42b94d940; // 1629kHz
//reg [39:0] phase_inc = 40'h17f62b6ae; // 585kHz
//reg [39:0] phase_inc = 40'h11eb851eb8; // 40m band (7MHz)
//reg [39:0] phase_inc = 40'h23d70a3d70; // 20m band (14 MHz)
//reg [39:0] phase_inc = 40'h47ae147ae1; // 10m (28 MHz)

wire [15:0] sin;
wire [15:0] cos;

nco nco0
(
	CLK,
	RSTb,

	phase_inc,

	sin,
	cos
);

wire RF_out;
assign gn24 = RF_out;

wire RF_in = gp21;

wire [15:0] I_out;
wire [15:0] Q_out;

mixer mix0 
(
	CLK,
	RSTb,

	RF_in,
	RF_out,

	sin,
	cos,

	I_out,
	Q_out	
);

// Instantiate CIC

wire [15:0] xI_out;
wire [15:0] xQ_out;
wire out_tickI;
wire out_tickQ;

wire gain = 8'b000000;

cic cic0
(
	CLK,
	RSTb,
	I_out,
	gain,
	xI_out,
	out_tickI
);

cic cic1
(
	CLK,
	RSTb,
	Q_out,
	gain,
	xQ_out,
	out_tickQ
);

wire out_tick;
wire signed [15:0] demod_out_a;

fm_demod fm0 
(
	CLK,
	RSTb,

	xI_out[15:11],
	xQ_out[15:11],
	out_tickI,	/* tick should go high when new sample is ready */

	demod_out_a,
	out_tick	/* tick will go high when the new FM demodulated sample is ready */

);

/* Extract the 19kHz pilot tone */

wire out_tick_19kHz;
wire signed [15:0] yout_19kHz;

bandpass_19kHz bp0 (
    CLK,
    RSTb,
    demod_out_a,
    out_tick,
    yout_19kHz,
    out_tick_19kHz
);

//assign gn7 = (yout_19kHz > 16'sd0);

// Hysteresis for 19kHz tone 

reg up_down = 1'b0;

assign gn7 = up_down;

always @(posedge CLK)
begin
	if (up_down == 1'b0) begin
		if (yout_19kHz > 16'sd200) begin 
			up_down <= 1'b1;
		end	
	end else begin
		if (yout_19kHz < -16'sd200) begin 
			up_down <= 1'b0;
		end	
	end
end


// DPLL

wire signed [15:0] sigout;
wire digout;

dpll dpll0 (

    CLK,
    RSTb,

    up_down,

    3'd1,       /* Multiply by 2 */
    3'd0,       /* Divide by 1   */

    sigout,
    digout

);

assign gn8 = digout;

// Mix down the stereo multiplex

reg signed [15:0] sigout2;
wire signed [31:0] stereo = sigout2 * demod_out_a;

reg signed [15:0] stereo_r;
reg signed [15:0] demod_left;
reg signed [15:0] demod_right;

reg tick_a;
reg tick_b;

always @(posedge CLK)
begin
	sigout2 <= sigout;
	stereo_r <= stereo[31:16];
	demod_left  <= demod_out_a + stereo_r;
	demod_right <= demod_out_a - stereo_r;
	tick_a <= out_tick;
	tick_b <= tick_a;
end

wire out_tick_d_left;
wire signed [15:0] demod_out_d_left;

deemph d0 (
    CLK,
    RSTb,
    demod_left,
    tick_b,
    demod_out_d_left,
    out_tick_d_left
);

wire out_tick_d_right;
wire signed [15:0] demod_out_d_right;

deemph d1 (
    CLK,
    RSTb,
    demod_right,
    tick_b,
    demod_out_d_right,
    out_tick_d_right
);

wire [15:0] left_audio;
wire out_tickA_left;

aud_cic cic2
(
	CLK,
	RSTb,
	out_tick_d_left,
	demod_out_d_left,
	8'h0,
	left_audio,
	out_tickA_left
);

wire [15:0] right_audio;
wire out_tickA_right;

aud_cic cic3
(
	CLK,
	RSTb,
	out_tick_d_right,
	demod_out_d_right,
	8'h0,
	right_audio,
	out_tickA_right
);


//assign led[3] = demod_out[0];

/* i2s audio */

wire mclk;
wire lr_clk;
wire sclk;
wire sdat;

audio aud0
(
	pll_clk_25,	
	RSTb,

	left_audio,
	right_audio,

	mclk,
	lr_clk,
	sclk,
	sdat	
);

assign gp17 = mclk;
assign gp18 = lr_clk;
assign gp19 = sclk;
assign gp20 = sdat;

/* test pattern generator */

`ifdef TEST_GENERATOR

wire one_bit_rf;

assign gp11 = one_bit_rf;

am_gen gen0
(
	CLK,
	RSTb,
	one_bit_rf
);

`endif

/* Get amplitude and filter for cheesy VU meter */

wire [15:0] VU_out;
wire vu_out_tick;

am_demod am1
(
        CLK,
        RSTb,

        left_audio,
        right_audio,
        out_tickA_left, 

        VU_out,
        vu_out_tick

);

reg [7:0] vu_meter;
reg [7:0] vu_meter_target;
wire [7:0] vu_decode;

vuTable vu0 (CLK, VU_out[15:6], vu_decode);

always @(posedge CLK)
begin
	if (vu_out_tick == 1'b1)
	begin
		vu_meter_target <= vu_decode;
	end	

end

reg [22:0] count_vu = 23'h000000;

always @(posedge CLK)
begin
	count_vu <= count_vu + 1;

	if (count_vu == 23'h000000)
	begin
		if (vu_meter_target > vu_meter) begin
			if (vu_meter == 8'h00)
				vu_meter <= 8'h01;
			else
				vu_meter <= (vu_meter << 1) | 8'h1;	
		end	

		if (vu_meter_target < vu_meter) begin
			vu_meter <= (vu_meter >> 1);
		end		
	end

end

assign led[0] = vu_meter[3];
assign led[1] = vu_meter[2];
assign led[2] = vu_meter[1];
assign led[3] = vu_meter[0];

assign led[4] = vu_meter[3];
assign led[5] = vu_meter[2];
assign led[6] = vu_meter[1];
assign led[7] = vu_meter[0];

reg [15:0] pwm = 16'd0;

always @(posedge CLK)
begin
	if (counter1 == 24'd0) begin
		if (btn[1] == 1'b1)
			pwm <= pwm + 16'h0100; 
		if (btn[2] == 1'b1)
			pwm <= pwm - 16'h0100; 
	end	
end

assign gp23 = (counter1[15:0] < pwm) ? 1'b1 : 1'b0; 

endmodule 
