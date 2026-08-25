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

def place(canvas, name, cx, cy, scale, anchor='core'):
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
    else:
        raise SystemExit('unknown anchor ' + anchor)
    canvas.alpha_composite(im, (int(round(cx - ax)), int(round(cy - ay))))

# the floor is scaled to cover the canvas and never moves again
bg = layer(spec['floor'])
s = max(W / bg.width, H / bg.height) * 1.02   # a hair of overscan so no resampled edge shows
bg = bg.resize((int(bg.width * s + 0.5), int(bg.height * s + 0.5)), Image.LANCZOS)
FLOOR = Image.new('RGBA', (W, H))
FLOOR.alpha_composite(bg, ((W - bg.width) // 2, (H - bg.height) // 2))

TS = spec['tile_scale']
tiles = spec['tiles']          # [{letter, x, y}]
for st in spec['states']:
    c = FLOOR.copy()
    for i, t in enumerate(tiles):
        lit = i in st.get('lit', [])
        c and place(c, spec['glyphs'][t['letter']]['lit' if lit else 'regular'],
                    t['x'], t['y'], TS)
    if spec.get('hand_open'):
        h = spec['hand_open']
        place(c, h['file'], h['x'], h['y'], h['scale'])
    if st.get('point') is not None:
        p = spec['point_poses'][st['point']['pose']]
        tgt = tiles[st['point']['tile']]
        place(c, p, tgt['x'] + st['point'].get('dx', 0),
              tgt['y'] + spec['point_tip_dy'] + st['point'].get('dy', 0),
              spec['point_scale'], anchor='tip')
    c.convert('RGB').save(os.path.join(OUTDIR, st['file']))
    print('  wrote', st['file'], '  lit', st.get('lit', []), ' point', st.get('point'))
