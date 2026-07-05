"""AMAL Ep1 v2.1 ENGLISH — assemble: title → per scene [English card → frame], timed to ep1_v2en_timing.json,
muxed to ep1_v2en.mp3 with a LEAD of silence. -> amal_ep1_v2en.mp4"""
import os, sys, json, subprocess
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import backends as bk

D = "/Users/dusty/dev/brehon-law/stories/amal"
C, F, W = f"{D}/cards_v2en", f"{D}/frames_v2en", f"{D}/_assemble_v2en"
os.makedirs(W, exist_ok=True)
ff = lambda a: subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y"] + a, check=True)
LEAD = 4.0

man = json.load(open(f"{D}/ep1_v2en_timing.json", encoding="utf-8"))
segs, VD = man["segments"], man["voices_dur"]
order = sorted({s["scene"] for s in segs})
first = {sc: min(s["start"] for s in segs if s["scene"] == sc) for sc in order}
dur = {sc: (first[order[i + 1]] if i + 1 < len(order) else VD) - first[sc] for i, sc in enumerate(order)}

missing = [sc for sc in order if not os.path.exists(f"{F}/sc{sc:02d}.png")]
if missing:
    sys.exit(f"frames not ready: {missing}")


def fit(src, dst):
    if not os.path.exists(dst):
        ff(["-i", src, "-vf", "scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,setsar=1", dst])


fit(f"{C}/title.png", f"{W}/p_title.png")
seq = [(f"{W}/p_title.png", LEAD)]
for sc in order:
    pc, pf = f"{W}/p_card{sc:02d}.png", f"{W}/p_sc{sc:02d}.png"
    fit(f"{C}/card{sc:02d}.png", pc)
    fit(f"{F}/sc{sc:02d}.png", pf)
    cd = min(1.8, dur[sc] * 0.28)
    seq += [(pc, cd), (pf, dur[sc] - cd)]

with open(f"{W}/list.txt", "w") as fh:
    for img, d in seq:
        fh.write(f"file '{os.path.abspath(img)}'\nduration {d:.3f}\n")
    fh.write(f"file '{os.path.abspath(seq[-1][0])}'\n")

sil = bk.silence(int(LEAD * 1000), W)
open(f"{W}/al.txt", "w").write(f"file '{os.path.abspath(sil)}'\nfile '{os.path.abspath(D + '/ep1_v2en.mp3')}'\n")
ff(["-f", "concat", "-safe", "0", "-i", f"{W}/al.txt", "-c:a", "libmp3lame", "-b:a", "192k", f"{W}/audio.mp3"])
ff(["-f", "concat", "-safe", "0", "-i", f"{W}/list.txt", "-i", f"{W}/audio.mp3",
    "-c:v", "libx264", "-pix_fmt", "yuv420p", "-r", "25", "-c:a", "aac", "-b:a", "192k",
    "-shortest", f"{D}/amal_ep1_v2en.mp4"])
print(f"DONE -> amal_ep1_v2en.mp4 ({bk.duration(D + '/amal_ep1_v2en.mp4')/60:.1f} min)", flush=True)
