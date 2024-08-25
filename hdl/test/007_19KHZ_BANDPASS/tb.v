`timescale 1ns / 1ps
module tb;

reg CLK = 1'b0;
reg RSTb = 1'b0;

always #5 CLK <= !CLK; // 100MHz

initial begin 
	#150 RSTb = 1'b1;
end

// Load 1bit_rf.txt into a "memory"

reg [15:0] memory [99999:0];

initial begin
	$display("Loading rom.");
	$readmemh("19KHz_test.txt", memory);
end

reg [9:0] count = 10'd0;
reg [15:0] xin;
reg tick = 1'b0;

reg [16:0] idx = 17'd0;

always @(posedge CLK) begin

	count <= count + 1;
	tick  <= 1'b0;

	if (count == 10'd199)
	begin
		idx <= idx + 1;
		xin <= memory[idx];
		count <= 10'd0;
		tick <= 1'b1;	
	end

end

wire [15:0] yout;
wire  out_tick;

bandpass_19kHz bp0 (
    CLK,
    RSTb,
    xin,
    tick,
    yout,
    out_tick
);

initial begin
	$dumpfile("dump.vcd");
	$dumpvars(0, tb);
	# 20000000 $finish;
end

endmodule;