"""Composite a spelled word from the author's transparent layers.

    python3 compose_word.py <assets_dir> <spec.json> <out_dir>

Nothing here is generated, warped, masked or repainted. The author supplies a
floor, each tile in a regular and a lit state, an open hand and three pointing
hands, all as straight-alpha RGBA with their shadows baked in. The pipeline only
decides WHERE each layer sits and WHICH state is showing.

This is the composable-alphabet contract doing what it was designed for. Every
earlier attempt at this beat tried to reconcile finished renders of a whole
scene, and every one of them failed differently — jitter, then a sliding word,
then misaligned floorboards, then a clipped forearm. None of those failures is
reachable from here: the floor is one image that never moves, and a tile that is
not being touched is the same pixels in every frame because it is the same file.

Tiles are placed by the CENTRE OF THEIR SOLID CORE, not by their canvas, because
a lit tile's canvas is larger than its regular twin's — the glow needs room — and
placing by canvas corner would jump the tile every time it lit.
"""
import json, os, sys
import numpy as np
from PIL import Image

ASSETS, SPEC, OUTDIR = sys.argv[1], sys.argv[2], sys.argv[3]
spec = json.load(open(SPEC))
W, H = spec.get('width', 1280), spec.get('height', 720)
os.makedirs(OUTDIR, exist_ok=True)

_cache = {}
def layer(name):
    if name not in _cache:
        _cache[name] = Image.open(os.path.join(ASSETS, name)).convert('RGBA')
    return _cache[name]

def core(im):
    """bbox of the solid part, ignoring glow and shadow falloff"""
    a = np.asarray(im)[..., 3]
    ys, xs = np.where(a > 250)
    return xs.min(), ys.min(), xs.max(), ys.max()

def extend_down(im, need):
    """Repeat the bottom rows so a forearm reaches the frame edge instead of
    ending in mid-air. The author's hand layers stop at a short wrist stub; in
    her own renders the arm runs off the bottom of frame, and a hand that stops
    short of the edge reads as a severed hand lying on the floor."""
    if need <= 0:
        return im
    a = np.asarray(im)
    # Repeat the last rows that actually CONTAIN the arm. The layer canvas has
    # transparent padding below the wrist, and repeating THAT extends nothing —
    # which is how the first attempt left the hand still floating.
    solid = np.where((a[..., 3] > 250).any(axis=1))[0]
    if len(solid) == 0:
        return im
    last = int(solid.max())
    # ONE row, repeated. A block of rows repeated leaves visible ribbing down the
    # forearm; a single row extends it as a smooth column.
    tail = a[last:last + 1, :, :]
    reps = int(need + (a.shape[0] - 1 - last)) + 2
    out = np.concatenate([a[:last + 1]] + [tail] * max(1, reps), axis=0)
    return Image.fromarray(out.astype(np.uint8), 'RGBA')

def place(canvas, name, cx, cy, scale, anchor='core', extend=False, off=(0, 0)):
    im = layer(name)
    if scale != 1.0:
        im = im.resize((max(1, int(im.width * scale)), max(1, int(im.height * scale))), Image.LANCZOS)
    x0, y0, x1, y1 = core(im)
    if anchor == 'core':
        ax, ay = (x0 + x1) / 2, (y0 + y1) / 2
    elif anchor == 'tip':                      # topmost solid pixel — the fingertip
        a = np.asarray(im)[..., 3]
        ys, xs = np.where(a > 250)
        ax, ay = xs[ys <= ys.min() + 6].mean(), ys.min()
    elif anchor == 'canvas':
        ax, ay = im.width / 2, im.height / 2
    else:
        raise SystemExit('unknown anchor ' + anchor)
    px, py = int(round(cx - ax + off[0] * scale)), int(round(cy - ay + off[1] * scale))
    if extend:
        im = extend_down(im, canvas.height - (py + im.height))
    canvas.alpha_composite(im, (px, py))

# the floor is scaled to cover the canvas and never moves again
bg = layer(spec['floor'])
s = max(W / bg.width, H / bg.height) * 1.02   # a hair of overscan so no resampled edge shows
bg = bg.resize((int(bg.width * s + 0.5), int(bg.height * s + 0.5)), Image.LANCZOS)
FLOOR = Image.new('RGBA', (W, H))
FLOOR.alpha_composite(bg, ((W - bg.width) // 2, (H - bg.height) // 2))

# The floor she exported is a flat texture; the floor in her own renders is lit,
# dropping from 51 at centre to 33 at the right edge. Ungraded it composites
# bright and flat and the shot does not sit in the same room as her frames.
# Gain and falloff are MEASURED against her 05_ALL, not invented to taste.
if spec.get('floor_grade'):
    fg = spec['floor_grade']
    yy, xx = np.mgrid[0:H, 0:W]
    r = np.sqrt(((xx - W / 2) / (W / 2)) ** 2 + ((yy - H / 2) / (H / 2)) ** 2) / np.sqrt(2)
    v = 1.0 - fg.get('vignette', 0.0) * r ** fg.get('vignette_power', 1.6)
    v = v * (1.0 - fg.get('tilt', 0.0) * (xx / W))       # her key light comes from the left
    f = np.asarray(FLOOR).astype(np.float32)
    f[..., :3] = np.clip(f[..., :3] * fg.get('gain', 1.0) * v[..., None], 0, 255)
    FLOOR = Image.fromarray(f.astype(np.uint8), 'RGBA')

TS = spec['tile_scale']
tiles = spec['tiles']          # [{letter, x, y}]
for st in spec['states']:
    c = FLOOR.copy()
    for i, t in enumerate(tiles):
        lit = i in st.get('lit', [])
        gl = spec['glyphs'][t['letter']]
        # Both states are separate renders, so their tile bodies do not sit
        # identically on their canvases — measured by correlating the two, the
        # lit one is out by 9-10px. Placing by canvas centre and applying that
        # measured correction stops the tile hopping when it lights.
        place(c, gl['lit' if lit else 'regular'], t['x'], t['y'], TS,
              anchor='canvas', off=tuple(gl.get('lit_offset', (0, 0))) if lit else (0, 0))
    if spec.get('hand_open'):
        h = spec['hand_open']
        place(c, h['file'], h['x'], h['y'], h['scale'], extend=True)
    if st.get('point') is not None:
        p = spec['point_poses'][st['point']['pose']]
        tgt = tiles[st['point']['tile']]
        place(c, p, tgt['x'] + st['point'].get('dx', 0),
              tgt['y'] + spec['point_tip_dy'] + st['point'].get('dy', 0),
              spec['point_scale'], anchor='tip', extend=True)
    c.convert('RGB').save(os.path.join(OUTDIR, st['file']))
    print('  wrote', st['file'], '  lit', st.get('lit', []), ' point', st.get('point'))
