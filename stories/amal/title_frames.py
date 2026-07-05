"""AMAL title sequence — 9 symbolic textless frames (the moral economy / the scale).
No characters, no plot, no text (अमल added later as a Pillow overlay). -> stories/amal/title_frames/"""
import os, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import frames
OUT = "/Users/dusty/dev/brehon-law/stories/amal/title_frames"
os.makedirs(OUT, exist_ok=True)
LOOK = (" Desaturated dusty cinematic prestige-noir still; muted palette of black cotton soil, khaki and "
        "grey dawn; the only colour the poppy's white-and-purple and the gold of brass and currency. "
        "Absolutely no text, no letters, no captions, no watermark. Rural Malwa, Madhya Pradesh, India.")
SHOTS = [
 ("01_weight", "Extreme macro: a single old brass weight resting on the worn brass pan of an antique hand-scale, deep shadow behind, one shaft of hard low light. Still and ominous." + LOOK),
 ("02_belt_dawn", "Low wide: vast white-and-purple opium poppy fields under grey pre-dawn mist, black cotton soil cracked open in the foreground, no people, silent and still." + LOOK),
 ("03_the_cut", "Extreme macro: a small curved blade scores the green skin of a poppy pod; white latex beads along the cut and bleeds slowly down. Beautiful, like a wound." + LOOK),
 ("04_scale_opium", "An antique brass weighment scale on a wooden table; a dark lump of raw opium gum on one pan, small brass weights on the other; weathered dark Indian farmer hands steadying it. Dim shed light." + LOOK),
 ("05_scale_cash", "The same antique brass scale; a thick banded brick of Indian rupee notes on one brass pan, the other pan empty and high. Cold and matter-of-fact." + LOOK),
 ("06_scale_bride", "An antique brass scale: on one pan a heap of red bridal glass bangles and a red wedding veil, on the other a single stamped folded government licence document; the document side hangs lower, the bangles raised. Symbolic, no people." + LOOK),
 ("07_thumbprint", "Macro: a weathered dark Indian hand presses an inked thumbprint onto an official government form; beside it a folded wad of banknotes half-tucked under a desk blotter. Flat institutional light." + LOOK),
 ("08_dry_well", "A cracked dry stone well at the edge of a poppy field under a hard white sky, dust lifting off the black soil, a single kite bird circling high. Beautiful and exhausted, no people." + LOOK),
 ("09_veiled", "A rural Indian woman seen only from the eyes up, head covered by a dusty veil, eyes downcast and anonymous, deep shadow across the rest, no identifiable face." + LOOK),
]
for name, prompt in SHOTS:
    out = f"{OUT}/{name}.png"
    if os.path.exists(out):
        print("skip", name, flush=True); continue
    try:
        frames.shot(prompt, out, register="photoreal", pro=True); print("done", name, flush=True)
    except Exception as e:
        print("FAIL", name, str(e)[:200], flush=True)
print("ALL DONE", flush=True)
