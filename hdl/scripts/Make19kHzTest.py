#!/usr/bin/python3

import numpy as np
from matplotlib import pyplot as plt
import math

# Generate 19kHz tone, 5kHz tone, and 30kHz @ 500kHz sample rate
# Generate 100,000 samples

sampleRate = 500e3

x = np.arange(0, 0.2, 1.0/sampleRate)

y1 = np.cos(x * 2*math.pi * 19000)
y2 = np.cos(x * 2*math.pi * 5000)
y3 = np.cos(x * 2*math.pi * 30000)

y = y1 + y2 + y3

#plt.plot(x, y)
#plt.show()

outfile = open("19KHz_test.txt", "w")

for yy in y:
    outfile.write("%04x\n" % (int(yy * 1000.0) & 0xffff))
