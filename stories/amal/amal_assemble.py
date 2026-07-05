"""AMAL Ep1 — assemble the table-read film: title card → per scene [Hindi heading card → live-action
frame], image track timed to ep1_timing.json, muxed to the 41-min audio. No drawtext needed."""
import os, sys, json, subprocess
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import backends as bk

D = "/Users/dusty/dev/brehon-law/stories/amal"
F, C, W = f"{D}/frames", f"{D}/cards", f"{D}/_assemble"
os.makedirs(W, exist_ok=True)
ff = lambda a: subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y"] + a, check=True)
LEAD = 4.0

man = json.load(open(f"{D}/ep1_timing.json"))["scenes"]
missing = [m["scene"] for m in man if not os.path.exists(f"{F}/sc{m['scene']:02d}.png")]
if missing:
    sys.exit(f"frames not ready: {missing}")

def fit(src, dst):
    if os.path.exists(dst):
        return
    ff(["-i", src, "-vf", "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,setsar=1", dst])

fit(f"{C}/title.png", f"{W}/p_title.png")
seq = [(f"{W}/p_title.png", LEAD)]
for m in man:
    n, dur = m["scene"], m["dur"]
    pc, pf = f"{W}/p_card{n:02d}.png", f"{W}/p_sc{n:02d}.png"
    fit(f"{C}/card{n:02d}.png", pc)
    fit(f"{F}/sc{n:02d}.png", pf)
    cd = min(1.8, dur * 0.28)
    seq += [(pc, cd), (pf, dur - cd)]

with open(f"{W}/list.txt", "w") as fh:
    for img, d in seq:
        fh.write(f"file '{os.path.abspath(img)}'\nduration {d:.3f}\n")
    fh.write(f"file '{os.path.abspath(seq[-1][0])}'\n")

sil = bk.silence(int(LEAD * 1000), W)
open(f"{W}/al.txt", "w").write(
    f"file '{os.path.abspath(sil)}'\nfile '{os.path.abspath(D + '/ep1_hindi_tableread.mp3')}'\n")
ff(["-f", "concat", "-safe", "0", "-i", f"{W}/al.txt", "-c:a", "libmp3lame", "-b:a", "192k", f"{W}/audio.mp3"])

ff(["-f", "concat", "-safe", "0", "-i", f"{W}/list.txt", "-i", f"{W}/audio.mp3",
    "-c:v", "libx264", "-pix_fmt", "yuv420p", "-r", "25",
    "-c:a", "aac", "-b:a", "192k", "-shortest", f"{D}/amal_ep1_tableread.mp4"])
print(f"DONE -> amal_ep1_tableread.mp4 ({bk.duration(D + '/amal_ep1_tableread.mp4')/60:.1f} min)", flush=True)
