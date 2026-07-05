import os, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import backends as bk

F = "/Users/dusty/dev/brehon-law/stories/sky-king/frames"
CL = "/Users/dusty/dev/brehon-law/stories/sky-king/clips"
os.makedirs(CL, exist_ok=True)

# Only the no-character / no-dialogue flying beats get motion (Seedance).
JOBS = [
    ("s1a_sky", 10, False,
     "The small white turboprop flies slowly across the vast gold dusk sky, soft clouds "
     "drifting past, golden light shimmering on the wings, a gentle slow aerial drift. "
     "Dreamy, calm, cinematic, anamorphic 35mm film look, subtle film grain."),
    ("s2e_jet_climb", 10, False,
     "The jet climbs away off the runway into low cloud and the last gold of the day, its "
     "lights slowly receding; rain falls through the floodlights; the small figure on the "
     "dark wet ramp watches it go. Slow, melancholy, film grain."),
    ("s1c_mountain", 5, True,
     "Out the cockpit windscreen at dusk: the pink-topped snow mountain, slow drifting "
     "clouds, the last light shifting gently across the snow, a subtle aircraft sway. "
     "Dreamy, golden, anamorphic film look."),
]

for name, secs, fixed, prompt in JOBS:
    out = f"{CL}/{name}.mp4"
    if os.path.exists(out):
        print("skip", name, flush=True); continue
    data = bk.image_to_video(f"{F}/{name}.png", prompt, seconds=secs, camera_fixed=fixed)
    open(out, "wb").write(data)
    print("animated", name, "->", out, f"{len(data)/1e6:.1f}MB", flush=True)
print("MOTION DONE", flush=True)
