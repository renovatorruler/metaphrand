"""AMAL Ep1 v2.1 — frames for the reordered episode. Most frames are reused from frames_v2/ (content
unchanged, only renumbered); the two recast scenes (11 the pawnshop→Charan-tells-Deva, 15 the informant→
old man) are regenerated. -> frames_v2en/."""
import os, sys, shutil
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import frames

D = "/Users/dusty/dev/brehon-law/stories/amal"
SH, OLD, OUT = f"{D}/sheets", f"{D}/frames_v2", f"{D}/frames_v2en"
os.makedirs(OUT, exist_ok=True)
tr = lambda *cs: [p for c in cs if os.path.exists(p := f"{SH}/{c}_turnaround.png")]

# new scene -> old frame number (content match). 11 and 15 are regenerated, not copied.
REMAP = {1: 1, 3: 3, 4: 4, 5: 6, 6: 7, 7: 8, 8: 9, 9: 10, 10: 11, 12: 12, 13: 13, 14: 14,
         16: 16, 17: 17, 18: 18, 19: 19, 20: 20, 21: 21, 22: 22, 23: 23}
for new, old in REMAP.items():
    src, dst = f"{OLD}/sc{old:02d}.png", f"{OUT}/sc{new:02d}.png"
    if os.path.exists(src) and not os.path.exists(dst):
        shutil.copy2(src, dst)

RECAST = [
 (11, "Outside a narrow Malwa pawnshop, day, rural India: a young Indian police constable in crisp khaki stands by a CBN jeep, listening to a very old Indian bard — one eye milky-white — sitting on the step shelling peanuts; through the dim shop doorway behind them, an old inspector and a moneylender at the back counter. Dusty light, a quiet handing-down.", tr("deva", "charan")),
 (15, "A dusty Malwa village lane, day, shuttered doors: a bitter, nosy old Indian man sitting on a cot outside a shop talks, leaning in and relishing it, to a heavy old Indian inspector and a young Indian constable; the lane wary and shut around them. Hard light, gossip.", tr("ratan", "deva")),
]
for num, prompt, refs in RECAST:
    out = f"{OUT}/sc{num:02d}.png"
    if not os.path.exists(out):
        frames.shot(prompt, out, refs=refs or None, register="photoreal", pro=True, face_lock=bool(refs))
        print(f"  regenerated sc{num}", flush=True)

have = sorted(int(f[2:4]) for f in os.listdir(OUT) if f.startswith("sc"))
print(f"FRAMES: {len(have)} present -> {OUT}  ({have})", flush=True)
