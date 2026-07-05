import os, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import assemble

BASE = "/Users/dusty/dev/brehon-law/stories/sky-king"
F = f"{BASE}/frames"
CL = f"{BASE}/clips"
TEST = f"{BASE}/test_birdy_cockpit_v1.png"
AUDIO = f"{BASE}/scored.mp3"
OUT = f"{BASE}/sky_king_act1_v2.mp4"

# v2: the three no-character flying beats are now MOTION clips ("video").
SHOTS = [
    (f"{CL}/s1a_sky.mp4",         "video",  10),   # COLD OPEN — the plane flying in gold (motion)
    (TEST,                        "kb_in",  11),   # Birdy in the cockpit
    (f"{CL}/s1c_mountain.mp4",    "video",   7),   # the pink mountain out the glass (motion)
    (f"{F}/s1d_birdy_shadow.png", "kb_in",  11),   # his face into shadow / "Okay"
    (f"{F}/s2a_ramp.png",         "kb_out",  8),   # RAMP
    (f"{F}/s2b_birdy_bags.png",   "kb_in",  11),
    (f"{F}/s2c_dez.png",          "static", 10),
    (f"{F}/s2d_marshal.png",      "kb_in",  11),
    (f"{CL}/s2e_jet_climb.mp4",   "video",  10),   # the jet climbs away (motion)
    (f"{F}/s3a_supper.png",       "kb_in",  10),   # HOME
    (f"{F}/s3c_maya_asks.png",    "static",  9),
    (f"{F}/s3d_birdy_chair.png",  "kb_in",  10),
    (f"{F}/s4a_birdy_alive.png",  "kb_in",   9),   # SIM
    (f"{F}/s4b_maya_door.png",    "static",  6),
    (f"{F}/s4c_frozen.png",       "kb_in",  14),
]

missing = [s for s, *_ in SHOTS if not os.path.exists(s)]
if missing:
    print("MISSING:", missing); sys.exit(1)

assemble.assemble(SHOTS, AUDIO, OUT, res=(1920, 1080), fps=30, xfade=0.6)
print("VIDEO v2 ->", OUT)
