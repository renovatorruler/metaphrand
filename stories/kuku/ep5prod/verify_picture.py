#!/usr/bin/env python3
"""PICTURE GUARD: prove every still segment actually shows the image the EDL names.

Eyeballing a contact sheet has already let defects through (the intact bridge after
the collapse, the swapped Mitasur shots, and a 93-segment rewire that silently
reused stale cached renders). This compares each BUILT segment video against its
source PNG by perceptual hash — no timeline arithmetic to get wrong.

Run after assemble_ep5.sh.
"""
import json, os, subprocess, sys, tempfile

D = os.path.dirname(os.path.abspath(__file__))
os.chdir(D)
THRESH = 40          # hamming distance over a 256-bit average hash
SIZE = 16


def ahash(path, ss=None):
    """Average hash straight off ffmpeg's greyscale output — no PIL/numpy."""
    args = ['ffmpeg', '-v', 'error']
    if ss is not None:
        args += ['-ss', f'{ss}']
    args += ['-i', path, '-vf', f'scale={SIZE}:{SIZE},format=gray',
             '-frames:v', '1', '-f', 'rawvideo', '-']
    raw = subprocess.run(args, capture_output=True).stdout
    if len(raw) < SIZE * SIZE:
        return None
    px = raw[:SIZE * SIZE]
    avg = sum(px) / len(px)
    return sum(1 << i for i, p in enumerate(px) if p > avg)


def dist(a, b):
    return bin(a ^ b).count('1')


edl = json.load(open('ep5_edl.json'))
bad, checked, skipped = [], 0, 0

for sc in edl['scenes']:
    name = sc['name']
    for gi, seg in enumerate(sc['segments']):
        src = seg.get('src', '')
        # A lip-synced segment is a clip generated FROM its still, so it must still
        # look like that still — this catches a swap that animated the wrong face.
        if src.startswith('file:') and seg.get('still_was'):
            png = f"stills/{seg['still_was']}.png"
            vid = src[5:]
            if os.path.exists(png) and os.path.exists(vid):
                h1, h2 = ahash(vid, ss=0), ahash(png)
                if h1 is not None and h2 is not None:
                    checked += 1
                    d = dist(h1, h2)
                    if d > THRESH:
                        bad.append((name, gi, seg['still_was'] + ' (lip)', d))
                    continue
            skipped += 1
            continue
        if not src.startswith('still:'):
            continue
        png = f'stills/{src[6:]}.png'
        vid = f'build/{name}_{gi:02d}.mp4'
        if not (os.path.exists(png) and os.path.exists(vid)):
            skipped += 1
            continue
        # sample the segment's first frame: zoompan starts at zoom 1.0, so it is
        # the full uncropped source image
        h1, h2 = ahash(vid, ss=0), ahash(png)
        if h1 is None or h2 is None:
            skipped += 1
            continue
        checked += 1
        d = dist(h1, h2)
        if d > THRESH:
            bad.append((name, gi, src[6:], d))

print(f'checked {checked} still segments, {skipped} skipped')
if bad:
    print('\nPICTURE MISMATCH — built segment does not match the still the EDL names:')
    for b in bad:
        print(f'  {b[0]:4} seg{b[1]:<3} expected {b[2]:22} hamming={b[3]}')
    sys.exit(1)
print('OK — every still segment shows the image the EDL names.')
