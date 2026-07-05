"""Stylize a Blender render into confident pen-and-ink via Gemini (img2img). Blender fixes
the angle/pose; Gemini draws the ink and keeps the likeness. -> <img>_gink.png beside input.
  python ink_gemini.py <render.png> [...]
"""
import sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import backends as bk

PROMPT = (
 "Redraw this image as a clean black-ink PEN LINE DRAWING — an editorial portrait sketch on plain white "
 "paper. Confident continuous ink contour lines with light cross-hatching only in the shadow areas; pure "
 "black ink on white, NO grey wash, NO colour. Keep the man's EXACT likeness and the EXACT same head angle "
 "and pose as the reference: a heavy jowly older man, grey moustache, short grey hair, a plain uniform shirt "
 "collar. Hand-drawn ink illustration, bold and legible."
)

for f in sys.argv[1:]:
    out = f.rsplit(".", 1)[0] + "_gink.png"
    bk.save_png(out, bk.image(PROMPT, refs=[f], pro=True))
    print("gink", out, flush=True)
