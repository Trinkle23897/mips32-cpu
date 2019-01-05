#!/usr/bin/python
# Usage: python pic2bin.py input_png output_bin
# e.g. python pic2bin.py 1920x1080.png pic.bin

import os, sys, cv2
import numpy as np

def down(img, maxpix):
    img = img / img.max() * maxpix
    return np.round(img).astype(np.uint8)

filename = sys.argv[-2] #'1920x1080.png'
output = sys.argv[-1] #'pic.bin'
img = cv2.imread(filename)
h, w = img.shape[:2]
if 3 * w > 4 * h: # crop w
    w_ = 4 * h // 3
    pad = (w - w_) // 2
    img = img[:, pad:-pad]
else: # crop h
    h_ = 3 * w // 4
    pad = (h - h_) // 2
    img = img[pad:-pad]
img = cv2.resize(img, (800, 600))
b = down(img[..., 0], 3)
g = down(img[..., 1], 7)
r = down(img[..., 2], 7)
with open(output, 'wb') as f:
    for i in range(img.shape[0]):
        for j in range(img.shape[1]):
            pix = ((b[i,j]<<6)|(g[i,j]<<3)|r[i,j])
            f.write(pix.astype(np.uint8))
