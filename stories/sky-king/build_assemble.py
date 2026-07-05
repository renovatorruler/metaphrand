import os, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import assemble

BASE = "/Users/dusty/dev/brehon-law/stories/sky-king"
F = f"{BASE}/frames"
TEST = f"{BASE}/test_birdy_cockpit_v1.png"
AUDIO = f"{BASE}/scored.mp3"
OUT = f"{BASE}/sky_king_act1.mp4"

# (src, kind, weight≈seconds) — ordered to the four scenes; weights match the
# manifest (cold open 31s, ramp 49s, home 29s, sim+close 28s) + a 6s music open.
SHOTS = [
    (f"{F}/s1a_sky.png",          "kb_out",  8),   # COLD OPEN — the plane tiny in gold
    (TEST,                        "kb_in",  11),   # Birdy in the cockpit (the approved frame)
    (f"{F}/s1c_mountain.png",     "kb_in",   8),   # the pink mountain out the glass
    (f"{F}/s1d_birdy_shadow.png", "kb_in",  11),   # his face going to shadow / "Okay"
    (f"{F}/s2a_ramp.png",         "kb_out",  8),   # RAMP — the rainy floodlit world
    (f"{F}/s2b_birdy_bags.png",   "kb_in",  11),   # the invisible grind
    (f"{F}/s2c_dez.png",          "static", 10),   # Dez pushing him
    (f"{F}/s2d_marshal.png",      "kb_in",  11),   # marshalling the jet, wands up
    (f"{F}/s2e_jet_climb.png",    "kb_out", 10),   # the jet climbs away; he watches
    (f"{F}/s3a_supper.png",       "kb_in",  10),   # HOME — supper in silence
    (f"{F}/s3c_maya_asks.png",    "static",  9),   # "the real one"
    (f"{F}/s3d_birdy_chair.png",  "kb_in",  10),   # the father's armchair, TV light
    (f"{F}/s4a_birdy_alive.png",  "kb_in",   9),   # SIM — alive, the real smile
    (f"{F}/s4b_maya_door.png",    "static",  6),   # Maya watching from the dark
    (f"{F}/s4c_frozen.png",       "kb_in",  14),   # the frozen plane, the close
]

missing = [s for s, *_ in SHOTS if not os.path.exists(s)]
if missing:
    print("MISSING FRAMES:", missing); sys.exit(1)

assemble.assemble(SHOTS, AUDIO, OUT, res=(1920, 1080), fps=30, xfade=0.6)
print("VIDEO ->", OUT)
