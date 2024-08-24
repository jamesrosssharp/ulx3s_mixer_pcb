from scipy import signal
from matplotlib import pyplot as plt
import numpy as np

b, a = signal.iirfilter(1, [18500.0 / 250000.0, 19500.0 / 250000.0], btype='bandpass',
                       analog=False, ftype='butter',
                       output='ba'
                       )

print(a)
print(b)

#[ 1.         -1.93116778  0.98751193]
#[ 0.00624404  0.         -0.00624404]

a = [ 512.0, -988,  505 ]
b = [ 3    , 0  ,  -3]


a = np.array(a) / 512.0
b = np.array(b) / 512.0


#alpha = (512.0 - 5.0) / 512.0

#b = 1 - alpha
#a = [1, -alpha]

w, h = signal.freqz(b, a, fs=500000)

#print(w)

fig = plt.figure()

ax = fig.add_subplot(1, 1, 1)

ax.semilogx(w, 20 * np.log10(np.maximum(abs(h), 1e-5)))

ax.set_title('19kHz bandpass frequency response')

ax.set_xlabel('Frequency [Hz]')

ax.set_ylabel('Amplitude [dB]')

#ax.axis((10, 250000, -100, 10))

ax.grid(which='both', axis='both')

plt.show()
