import os, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import frames
SH = "/Users/dusty/dev/brehon-law/stories/amal/sheets"
OUT = "/Users/dusty/dev/brehon-law/stories/amal/frame_samples"; os.makedirs(OUT, exist_ok=True)
def s(*cs): return [f"{SH}/{c}_turnaround.png" for c in cs]

SUF = (" Naturalistic available-light cinematography in the grounded realist style of the Indian crime dramas "
 "Kohrra, Delhi Crime and Paatal Lok, shot on KODAK PORTRA 400 colour film — fine organic grain, soft natural "
 "contrast, gentle natural warmth and true-to-life skin tones (subtle natural warmth; NOT a heavy yellow or "
 "amber 'piss-filter', no sepia). Real locations, backgrounds VISIBLE with depth, never black. A PROSPEROUS "
 "opium belt with real money — clean functional places, affluence at the big houses, NOT poverty. CLEAN "
 "station-appropriate clothing. Every shot a CANDID in-the-moment film still — caught in the action, never "
 "posing or smiling into the camera. Grounded prestige-television realism, photoreal. Malwa, Madhya Pradesh, "
 "India. No text, no caption, no watermark.")

R    = "RATAN, a heavy weary 52-year-old Malwa inspector in clean pressed khaki, lined jowly face, grey moustache"
RP   = "RATAN, a heavy weary 52-year-old man in neat plain clothes, lined jowly face, grey moustache"
RANA = "RANA, a big genial middle-aged Malwa political boss in a crisp white kurta, broad calm well-fed face"
DV   = "DEVA, a 24-year-old constable in clean khaki, earnest young face"

CINE = [
 ("cine_sc06", s("ratan", "deva"),
  f"Interior of a plain functional CBN office; dusty shafts of daylight slant through a window, fine haze and "
  f"dust motes in the air; the room and its files visible with depth. Anamorphic lens, shallow focus — {R} and "
  f"the fold of banknotes sharp at his wooden desk, the background files and window soft and out of focus with "
  f"gentle bokeh. {R} pushes the banknotes back across the desk with one finger; a stunned farmer in a clean "
  f"kurta stands before him; {DV} watches from a side table. Composed in depth, a soft out-of-focus foreground."),
 ("cine_sc38", s("ratan", "deva"),
  f"Dusk over an open field, the last grey-blue light, low haze hanging over the land. Wide anamorphic "
  f"composition with deep cinematic depth: in the soft-focus foreground {RP} and {DV} stand in the dark furrows "
  f"watching; across the field a big lit haveli glows warm in sharp focus at the far end, a faint anamorphic "
  f"flare off its windows. Atmospheric dusk mist, the land and distance readable."),
 ("cine_sc16", s("rana", "ratan"),
  f"Closer anamorphic two-shot on the warm-lit farmhouse verandah, shallow focus — {RANA} leaning in murmuring "
  f"his soft offer and {R}'s guarded face both sharp, the green compound behind melting into soft bokeh. Low "
  f"warm evening light raking across their faces, a faint haze in the air, candid and intimate, nobody looking "
  f"at the camera."),
]
for n, r, p in CINE:
    frames.shot(p + SUF, f"{OUT}/{n}.png", refs=[x for x in r if os.path.exists(x)], register="photoreal", pro=True, face_lock=False)
    print("done", n, flush=True)
print("CINE FRAMES DONE", flush=True)
