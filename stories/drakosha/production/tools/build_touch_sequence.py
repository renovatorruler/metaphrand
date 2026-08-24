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
from PIL import Image

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
