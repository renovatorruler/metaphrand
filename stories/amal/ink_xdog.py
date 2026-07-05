"""XDoG ink-line stylization of rendered frames — TEXTURE-AWARE, so it catches the painted
face features (eyes, moustache, lips) that geometry-only Freestyle misses on a Tripo mesh.
  python ink_xdog.py <img.png> [...]   ->  <img>_ink.png beside each input
"""
import sys
import numpy as np
from PIL import Image, ImageFilter, ImageOps


def xdog(im_l, sigma=1.0, k=1.6, tau=0.99, eps=-0.04, phi=16.0):
    g1 = np.asarray(im_l.filter(ImageFilter.GaussianBlur(sigma)), dtype=np.float32) / 255.0
    g2 = np.asarray(im_l.filter(ImageFilter.GaussianBlur(sigma * k)), dtype=np.float32) / 255.0
    s = g1 - tau * g2
    t = np.where(s >= eps, 1.0, 1.0 + np.tanh(phi * (s - eps)))
    return np.clip(t, 0, 1)


for f in sys.argv[1:]:
    im = ImageOps.autocontrast(Image.open(f).convert("L"), cutoff=1)
    ink = (xdog(im) * 255).astype(np.uint8)
    out = f.rsplit(".", 1)[0] + "_ink.png"
    Image.fromarray(ink).save(out)
    print("ink", out, flush=True)
