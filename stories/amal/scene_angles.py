"""Generate N ORBIT angles around the middle-class Deva's-house base via Gemini.

Reference handling FIXED after a failure flood: the model dies past ~3-4 reference images,
and each full-res PNG inlined into the request blew the payload. So we (a) CAP refs at BASE
+ the last 2 angles and (b) DOWNSCALE them to ~1 MP. The backend already retries transient
blips internally, so there is NO extra retry loop here (that was multiplying failures).
Resumes from whatever already exists.  -> scene_deva_house/mc/
"""
import os, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from PIL import Image
from cinema import backends as bk

BASE = "/Users/dusty/dev/brehon-law/stories/amal/scene_deva_house/deva_base_mc.png"
OUT = "/Users/dusty/dev/brehon-law/stories/amal/scene_deva_house/mc"
os.makedirs(OUT, exist_ok=True)
SMALL = "/tmp/devaref"; os.makedirs(SMALL, exist_ok=True)


def small(path):
    """Downscaled JPEG copy of a reference so the request payload stays tiny."""
    sp = f"{SMALL}/{os.path.basename(path)}.jpg"
    if not os.path.exists(sp):
        im = Image.open(path).convert("RGB")
        s = min(1.0, 1024 / max(im.size))
        im.resize((int(im.width * s), int(im.height * s))).save(sp, quality=85)
    return sp


SCENE = (
 "the EXACT SAME middle-class village house as the reference images — Deva's house at dusk: smoothly plastered "
 "ochre-painted walls with cream trim, a tiled roof with a stainless water tank, a low painted compound wall "
 "and metal gate, a small veranda with potted plants, lit windows glowing warm, a parked motorcycle and a "
 "small car, an ordinary lane, soft cool dusk light, Kodak Portra film look. The architecture, colours, the "
 "vehicles, the plants and the lighting stay IDENTICAL — ONLY the camera position changes, as if walking "
 "around the same house at the same moment."
)

ANGLES = [
 ("a_corner_right", "Camera moved RIGHT around the building's corner — now seeing more of the SIDE wall and the lane running alongside it."),
 ("b_front_left",   "Camera moved LEFT, square onto the gate and the front face with the veranda and the lit windows."),
 ("c_closer_gate",  "Camera moved CLOSER — a tighter view of the gate, the veranda with potted plants and the warm lit window."),
 ("d_down_lane",    "Camera moved a good distance DOWN THE LANE, looking back at the whole house on its corner plot."),
 ("e_wide",         "A WIDER pulled-back establishing view: the full house and compound, the car and motorcycle, the lane and neighbouring houses."),
 ("f_high",         "A HIGHER vantage looking gently DOWN over the house — the tiled roof, the water tank, the yard and lane from above."),
 ("g_far_side",     "Camera moved around to the FAR SIDE of the house, looking back toward the lit front from beyond the side wall."),
]

done = []
for tag, view in ANGLES:
    out = f"{OUT}/deva_mc_{tag}.png"
    if os.path.exists(out):
        done.append(out); print(f"skip {tag} (exists)", flush=True); continue
    ref_list = [BASE] + done[-2:]                  # cap: base + the last 2 angles only
    prompt = (f"Generate another photographic view of {SCENE}\nNEW CAMERA: {view}\n"
              f"Match the architecture, colours, vehicles and dusk lighting of the reference images exactly. "
              f"Photorealistic, deep three-dimensional space, no people.")
    bk.save_png(out, bk.image(prompt, refs=[small(p) for p in ref_list], pro=True))
    print(f"OK {tag} (refs={len(ref_list)})", flush=True)
    done.append(out)

print("DONE", len([a for a in ANGLES]), "->", OUT, flush=True)
