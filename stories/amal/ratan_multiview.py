"""Gemini -> a clean 4-view orthographic turnaround of Ratan, for Tripo multiview_to_model.
One horizontal row (front | left | back | right) on flat white, identical framing, so it
splits into 4 even panels. Conditioned on the existing portrait + turnaround for identity.
-> stories/amal/tripo3d/ratan_multiview.png
"""
import sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import backends as bk

SH = "/Users/dusty/dev/brehon-law/stories/amal/sheets"
OUT = "/Users/dusty/dev/brehon-law/stories/amal/tripo3d/ratan_multiview.png"

PROMPT = (
 "A clean orthographic CHARACTER TURNAROUND model sheet of the SAME man as the reference images — a heavy, "
 "jowly ~52-year-old Malwa man, grey hair and a thick grey moustache, bags under his eyes, wearing a clean "
 "khaki uniform shirt. Show his HEAD-AND-SHOULDERS bust in exactly FOUR views in a single evenly-spaced "
 "horizontal row, left to right, on a PURE FLAT WHITE seamless background: "
 "(1) straight FRONT view, (2) exact LEFT-side profile (facing left), (3) BACK of the head and shoulders, "
 "(4) exact RIGHT-side profile (facing right). "
 "All four at the IDENTICAL scale, height, vertical centre and framing, evenly spaced with clear white gaps "
 "between them, neutral expression, perfectly even flat shadowless studio lighting, no props, no text. "
 "Photorealistic, with consistent identity, hair, moustache and uniform across all four views."
)

bk.save_png(OUT, bk.image(PROMPT, refs=[f"{SH}/ratan.png", f"{SH}/ratan_turnaround.png"], pro=True))
print("saved", OUT)
