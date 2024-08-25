#!/usr/bin/python3

import numpy as np
from matplotlib import pyplot as plt
import math

# Generate 19kHz tone, 5kHz tone, and 30kHz @ 500kHz sample rate
# Generate 100,000 samples

sampleRate = 500e3

x = np.arange(0, 1.0, 1.0/sampleRate)

y1 = np.cos(x * 2*math.pi * 19000)

#plt.plot(x, y)
#plt.show()

outfile = open("19KHz_test2.txt", "w")

for yy in y1:
    if (yy > 0.0):
        outfile.write("1\n")
    else:
        outfile.write("0\n")


