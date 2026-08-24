"""Composite the author's alphabet letters onto a dubbed plate, igniting on the voice.

    python3 ignite_word.py <src.mp4> <out.mp4> <spec.json>

The spec is the record. vfx_ignite_word.py hardcoded САЛАТ's timings in its own
source, so when МАК was rendered the file was edited in place and САЛАТ's numbers
were the only ones left on disk — the МАК timings survived nowhere but inside the
rendered mp4, and had to be recovered by diffing frames (2026-08-23). A word's
letter times ARE production data. They live in a spec file, next to the clip.

    {
      "word": "МАК",
      "clip": "2026-08-23_S8_MAK",
      "height": 120,
      "letters": [ {"ch": "М", "t": 3.58, "x": 100, "y": 100}, ... ],
      "pulse": [5.85, 6.35],
      "voice": "each t is the VOICED ONSET of that letter in the dub, measured
                from the recording's envelope — never the frame the pencil moves."
    }
"""
import subprocess, os, sys, json
from PIL import Image, ImageEnhance

SRC, OUT, SPEC = sys.argv[1], sys.argv[2], sys.argv[3]
ALPHA = '/Users/dusty/dev/metaphrand/stories/drakosha/production/alphabet/frosya/assets'
FPS = 24

spec = json.load(open(SPEC))
H_L = spec.get('height', 120)
LET = [(l['ch'], float(l['t']), (int(l['x']), int(l['y']))) for l in spec['letters']]
PULSE_T, PULSE_END = spec.get('pulse', [1e9, 1e9])

def load(ch, h):
    im = Image.open(f'{ALPHA}/magic/{ch}.png').convert('RGBA')
    im = im.crop(im.getbbox())
    return im.resize((int(h * im.width / im.height), h), Image.LANCZOS)

MAGIC  = {ch: load(ch, H_L) for ch, _, _ in LET}
BRIGHT = {ch: ImageEnhance.Brightness(MAGIC[ch]).enhance(1.4) for ch, _, _ in LET}

pd = '/tmp/sb8/ignite'
os.makedirs(pd, exist_ok=True)
for f in os.listdir(pd):
    os.remove(os.path.join(pd, f))
subprocess.run(['ffmpeg', '-v', 'error', '-i', SRC, '-vsync', '0', f'{pd}/f%04d.png'], check=True)

for i, fn in enumerate(sorted(os.listdir(pd))):
    t = i / FPS
    im = Image.open(os.path.join(pd, fn)).convert('RGBA')
    for ch, t0, (x, y) in LET:
        if t < t0:
            continue
        a = min(1.0, (t - t0) / 0.22)
        src = BRIGHT[ch] if PULSE_T <= t <= PULSE_END else MAGIC[ch]
        L = src if a >= 1.0 else Image.blend(Image.new('RGBA', src.size, (0, 0, 0, 0)), src, a)
        im.alpha_composite(L, (x, y))
    im.convert('RGB').save(os.path.join(pd, fn))

subprocess.run(['ffmpeg', '-v', 'error', '-y', '-framerate', str(FPS), '-i', f'{pd}/f%04d.png',
                '-i', SRC, '-map', '0:v', '-map', '1:a', '-c:v', 'libx264', '-pix_fmt', 'yuv420p',
                '-crf', '18', '-c:a', 'copy', OUT], check=True)
print('wrote', OUT, 'from', SPEC)
