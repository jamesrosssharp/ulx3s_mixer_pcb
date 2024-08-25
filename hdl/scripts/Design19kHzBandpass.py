from scipy import signal
from matplotlib import pyplot as plt
import numpy as np
import cmath
import math

#b, a = signal.iirfilter(1, [19500.0 / 250000.0], btype='highpass',
#                       analog=False, ftype='butter',
#                       output='ba'
#                       )

#print(a)
#print(b)

#alpha = (512.0 - 256.0) / 512.0

#b = (1 - alpha)
#a = [1, -alpha]

r = 0.999
w0 = 0.24

a = [ 1, -2.0*r*math.cos(w0),  r*r ]
b = [ 0.02    , 0  ,  -0.02]

print (a)
print (b)

# [1, -1.9232491902070188, 0.9801]
# [0.02, 0, -0.02]

a = [512, -993, 510] 
b = [2,  0,   -2]

print(a)
print(b)

w, h = signal.freqz(b, a, fs=500000)

#print(w)

fig = plt.figure()

ax = fig.add_subplot(1, 1, 1)

ax.semilogx(w, 20 * np.log10(np.maximum(abs(h), 1e-5)))

ax.set_title('19kHz bandpass frequency response')

ax.set_xlabel('Frequency [Hz]')

ax.set_ylabel('Amplitude [dB]')

ax.axis((10, 250000, -100, 10))

ax.grid(which='both', axis='both')

plt.show()

# Plot poles and zeros

z, p, k = signal.tf2zpk(b, a)

print(z)
print(p)
print(k)

fig, ax = plt.subplots(subplot_kw={'projection': 'polar'})

z1r,z1t = cmath.polar(z[0])
z2r,z2t = cmath.polar(z[1])

p1r,p1t = cmath.polar(p[0])
p2r,p2t = cmath.polar(p[1])

ax.plot(z1t, z1r, 'ko')
ax.plot(z2t, z2r, 'ko')
ax.plot(p1t, p1r, 'kx')
ax.plot(p2t, p2r, 'kx')

ax.set_rmax(1.1)
ax.set_rticks([0.5, 1])  # Less radial ticks
ax.set_rlabel_position(-22.5)  # Move radial labels away from plotted line
ax.grid(True)

ax.set_title("A line plot on a polar axis", va='bottom')
plt.show()
