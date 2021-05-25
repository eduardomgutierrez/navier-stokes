#!/usr/bin/env python
# coding: utf-8

import matplotlib
matplotlib.use('Agg')

import cv2
import numpy as np
import matplotlib.pyplot as plt
import h5py
import glob

h5f = h5py.File("data.h5", "r")
dens = h5f['dens']
u = h5f['u']
v = h5f['v']
Ntimes = dens.shape[0]
Ngrid = dens.shape[1]

x, y = np.meshgrid(np.linspace(-5, 5, Ngrid), np.linspace(-5, 5, Ngrid))

for itime in range(Ntimes):
    fig, ax = plt.subplots(figsize=(7, 7))
    CP = ax.pcolormesh(x, y, dens[itime])
    fig.savefig('plots/plot_' + ("%04d" % (itime,)) + '.png')
    plt.close(fig)


img_array = []
filenames = glob.glob('plots/plot*.png')
filenames.sort()
for filename in filenames:
    img = cv2.imread(filename)
    height, width, layers = img.shape
    size = (width, height)
    img_array.append(img)

out = cv2.VideoWriter('videos/dens.mp4', cv2.VideoWriter_fourcc(*'MP4V'), 20, size)

for img in img_array:
    out.write(img)
out.release()

