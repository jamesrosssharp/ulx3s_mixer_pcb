#!/usr/bin/python3

import math

theFile = open("../src/vu_table.v", "w")

theFile.write("module vuTable(input clk, input [9:0] addr, output reg [7:0] data);\n")
theFile.write("reg [15:0] mem [0:1023];\n")


for i in range(0, 1024):
    
    if i < 120:
        vuval = 0x00
    elif i < 200:
        vuval = 0x01
    elif i > 400:
        vuval = 0x03
    elif i > 800:
        vuval = 0x07
    else:
        vuval = 0x0f

    text = "initial mem[%d] = 8'h%x;\n" % (i, int(vuval) & 0xffff)
    theFile.write(text)

theFile.write("always @(posedge clk) begin\n")
theFile.write("\tdata <= mem[addr];\n")
theFile.write("end\n")

theFile.write("endmodule\n")
theFile.close()

