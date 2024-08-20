#!/usr/bin/python3

import math

theFile = open("../src/arg_table.v", "w")

theFile.write("module argTable(input clk, input [9:0] addr, output reg [15:0] data);\n")
theFile.write("reg [15:0] mem [0:1023];\n")


for i in range(0, 1024):
        
    re = ((i & 0x3e0) >> 5)

    if (re & 0x10):
        re = re - 32

    im = (i & 0x1f)

    if (im & 0x10):
        im = im - 32

    argval = (math.atan2(im, re) / (math.pi / 2)) * 32767.0

    text = "initial mem[%d] = 16'h%x;\n" % (i, int(argval) & 0xffff)
    theFile.write(text)

theFile.write("always @(posedge clk) begin\n")
theFile.write("\tdata <= mem[addr];\n")
theFile.write("end\n")

theFile.write("endmodule\n")
theFile.close()

