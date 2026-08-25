"""Cut a sequence of author stills onto a voice — the PLATE glyph strategy.

    python3 build_touch_sequence.py <frames_dir> <audio.mp3> <out.mp4> <spec.json>

Nothing here is generated and nothing is repainted: the author's frames ARE the
picture, and the pipeline only decides when each one is on screen. That is the
whole reason this beat is safe — scene 7 lost every letter shot to Cyrillic the
model cannot draw, and a frame the author drew cannot be drawn wrong.

The spec lists states with the time each comes up, measured from the recording's
own envelope:

    { "fps": 24, "dissolve": 0.08, "duration": 4.15,
      "states": [ {"file": "00_rest.png", "at": 0.00}, ... ] }
"""
import subprocess, os, sys, json
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage

FRAMES, AUDIO, OUT, SPEC = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
spec = json.load(open(SPEC))
FPS = spec.get('fps', 24)
DIS = spec.get('dissolve', 0.08)
DUR = spec['duration']
states = spec['states']

imgs = [Image.open(os.path.join(FRAMES, s['file'])).convert('RGB') for s in states]
W0, H0 = imgs[0].size
for im in imgs:
    if im.size != (W0, H0):
        raise SystemExit(f'frames differ in size: {im.size} vs {W0}x{H0}')

# The author renders at 1672x941. h264 refuses an odd dimension, and every other
# shot in the cut is 1280x720, so the sequence is delivered at the cut's size.
# The two aspect ratios agree to within a thousandth, so nothing is cropped.
W, H = spec.get('width', 1280), spec.get('height', 720)
if abs(W0 / H0 - W / H) > 0.01:
    raise SystemExit(f'aspect mismatch: source {W0}x{H0}, target {W}x{H} — would crop')
imgs = [im.resize((W, H), Image.LANCZOS) for im in imgs]

# ---- STABILISE ---------------------------------------------------------------
# The author renders each state separately, so the parts that are supposed to be
# identical are not: measured across the МАМА set, the top planks drifted 9-13 of
# 255 between frames and her LEFT HAND — which never moves — drifted up to 29. Cut
# together, that is not a finger moving between tiles, it is the whole picture
# jumping every time we cut, which is what the author saw.
#
# So one frame is the master and supplies everything, and each state contributes
# ONLY the pixels that genuinely changed: the arm and the glow. Two rules do it.
# A region outside which nothing may ever change (`allowed`), because the left
# hand really does shift pose between renders and no brightness threshold can
# tell that from intent. And inside it, a threshold — jitter runs about 10/255,
# an arm on wood or a lit tile runs far higher — dilated and feathered so edges
# do not crawl. The master's own arm disappears for free: where it stands, the
# state frame shows floor, the difference is large, and the floor is taken.
if spec.get('stabilise'):
    st = spec['stabilise']

    # ---- ALIGN THE ROW ------------------------------------------------------
    # Pinning the background was not enough: inside the working region each state
    # still brought its own tiles, and they are not the same tiles. Measured on
    # the МАМА set, the gap between tile centres ran 176px in one frame and 219
    # in another, and the first tile sat 86px apart between the extremes — so the
    # word slid and breathed on every cut, which is what the author saw after the
    # first fix.
    #
    # The cause is not tiles moving independently. Fit a uniform scale and shift
    # to the UNLIT tile centres and the residual falls under 4px, so the renders
    # differ by camera distance and nothing else: one state is 11% closer, another
    # 6% further. That means the whole frame can be warped by that one transform
    # and everything — tiles, arm, finger — lands together, with the finger still
    # on the tile it is touching. Fitting on the LIT tile too would poison it: its
    # glow inflates the blob and drags the centroid ten pixels or more.
    if st.get('align_row'):
        ar = st['align_row']
        by0, by1, bx0, bx1 = [int(v * H / H0) if i < 2 else int(v * W / W0)
                              for i, v in enumerate(ar['band'])]
        thr_t = float(ar.get('threshold', 115))
        minsz = int(ar.get('min_size', 60) * W / W0)

        def tiles(im):
            a = np.asarray(im.convert('L')).astype(np.float32)[by0:by1, bx0:bx1]
            lab, _ = ndimage.label(a > thr_t)
            out = []
            for sl in ndimage.find_objects(lab):
                h_, w_ = sl[0].stop - sl[0].start, sl[1].stop - sl[1].start
                if w_ > minsz and h_ > minsz:
                    out.append(((sl[1].start + sl[1].stop) / 2 + bx0,
                                (sl[0].start + sl[0].stop) / 2 + by0,
                                float(a[sl].mean())))
            out.sort()
            return np.array(out)

        ref = tiles(imgs[st.get('master', 0)])
        aligned = []
        for k, im in enumerate(imgs):
            C = tiles(im)
            if len(C) != len(ref) or len(ref) < 2:
                aligned.append(im)
                print(f'  frame {k}: found {len(C)} tiles, expected {len(ref)} — left unaligned')
                continue
            lit = C[:, 2] > C[:, 2].mean() + 0.5 * C[:, 2].std()
            keep = ~lit if (~lit).sum() >= 2 else np.ones(len(C), bool)
            P, Q = C[keep][:, :2], ref[keep][:, :2]
            Pm, Qm = P.mean(0), Q.mean(0)
            sc = (((P - Pm) * (Q - Qm)).sum()) / (((P - Pm) ** 2).sum())
            tr = Qm - sc * Pm
            if abs(sc - 1) < 1e-4 and abs(tr).max() < 0.5:
                aligned.append(im)
                continue
            aligned.append(im.transform((W, H), Image.AFFINE,
                                        (1 / sc, 0, -tr[0] / sc, 0, 1 / sc, -tr[1] / sc),
                                        resample=Image.BICUBIC))
            res = np.linalg.norm(sc * P + tr - Q, axis=1).max()
            print(f'  frame {k}: scale {sc:.4f} shift ({tr[0]:+.1f},{tr[1]:+.1f}) fit residual {res:.1f}px')
        imgs = aligned
    mi_idx = st.get('master', 0)
    T = float(st.get('threshold', 35))
    x0, y0 = int(st.get('x0', 0) * W / W0), int(st.get('y0', 0) * H / H0)
    arr = [np.asarray(im).astype(np.float32) for im in imgs]
    master = arr[mi_idx]
    allowed = np.zeros((H, W), np.float32)
    allowed[y0:, x0:] = 1.0
    allowed = np.asarray(
        Image.fromarray((allowed * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(6))
    ).astype(np.float32) / 255.0
    # THE FLOOR IS NEVER TAKEN FROM A STATE FRAME. Warping a frame to line the
    # tiles up drags its floorboards along, and the planks then meet the master's
    # planks at an angle — the author saw it immediately. But the floor is much
    # darker than anything we actually want: measured on this set, floorboards sit
    # at luminance ~42, the arm at 81-103, the tiles at 95 and a lit tile at 146.
    # So a brightness floor separates them outright.
    #
    # A pixel is taken from the state only where it differs AND either side is
    # bright: bright in the state means an arm or a glow arriving, bright in the
    # master means the master's own arm has to be erased — and that erasure is why
    # no second arm appears. Where both are dark it is floor against floor, and the
    # master keeps it, so the planks never move.
    # An arm carries a contact shadow, and the shadow is DARKER than the floor,
    # so the brightness rule alone refuses to move it: erasing the master's arm
    # left its shadow sitting on the boards like a stain. So each bright region
    # is grown before it is used, far enough to take its own shadow with it.
    FLOOR = float(st.get('floor_luma', 62))
    GROW = int(st.get('shadow_grow', 31))
    def grow(mask2d):
        im = Image.fromarray((mask2d * 255).astype(np.uint8))
        return np.asarray(im.filter(ImageFilter.MaxFilter(GROW))).astype(np.float32) / 255.0 > 0.5
    mlum = master.mean(axis=2)
    m_bright = grow(mlum > FLOOR)
    fixed = []
    for a in arr:
        d = np.abs(a - master).max(axis=2)
        alum = a.mean(axis=2)
        keep = (d > T) & (grow(alum > FLOOR) | m_bright)
        m = Image.fromarray((keep * 255).astype(np.uint8))
        m = m.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.GaussianBlur(4))
        al = (np.asarray(m).astype(np.float32) / 255.0) * allowed
        fixed.append(Image.fromarray((master * (1 - al[..., None]) + a * al[..., None]).astype(np.uint8)))
    imgs = fixed
    print(f'stabilised against frame {mi_idx}: threshold {T}, change allowed below y={y0}, right of x={x0}')

work = '/tmp/sb8/touchseq'
os.makedirs(work, exist_ok=True)
for f in os.listdir(work):
    os.remove(os.path.join(work, f))

n = int(round(DUR * FPS))
for i in range(n):
    t = i / FPS
    # the state in force, and the one before it, for the dissolve
    k = 0
    for j, s in enumerate(states):
        if t >= s['at']:
            k = j
    cur = imgs[k]
    since = t - states[k]['at']
    if k > 0 and since < DIS:
        a = since / DIS
        frame = Image.blend(imgs[k - 1], cur, a)
    else:
        frame = cur
    frame.save(f'{work}/f{i:04d}.png')

subprocess.run(['ffmpeg', '-v', 'error', '-y', '-framerate', str(FPS), '-i', f'{work}/f%04d.png',
                '-i', AUDIO, '-map', '0:v', '-map', '1:a', '-c:v', 'libx264', '-pix_fmt', 'yuv420p',
                '-crf', '17', '-c:a', 'aac', '-b:a', '192k', '-shortest', OUT], check=True)
print('wrote', OUT, f'{n} frames at {FPS}fps')
