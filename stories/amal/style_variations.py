"""Gemini style variations of one render — same subject + pose, different stylization,
so we can pick the visual language. -> <render>_<style>.png for each.
  python style_variations.py <render.png>
"""
import sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import backends as bk

KEEP = (" Keep the man's EXACT likeness and the EXACT same head angle and pose as the reference — a heavy "
        "jowly older man, grey moustache, short grey hair, a plain uniform shirt collar. No colour, monochrome.")

STYLES = {
 "woodcut": ("Reinterpret this portrait as a bold black-and-white WOODCUT / linocut relief print: thick carved "
             "black masses, very high contrast, angular gouged white lines cutting through the black, limited "
             "flat detail, the look of a hand-printed relief block on cream paper."),
 "charcoal": ("Reinterpret this portrait as a soft CHARCOAL life drawing on textured paper: smudgy tonal "
              "shading, grainy expressive strokes, deep blacks and soft greys, blended midtones, loose and "
              "atmospheric, edges dissolving into the paper."),
 "engraving": ("Reinterpret this portrait as a fine CROSS-HATCH ENGRAVING / etching: every tone built from "
               "dense parallel hatching and stipple dots, like a 19th-century banknote portrait or book-plate "
               "illustration, precise black ink on white, intricate."),
 "brush": ("Reinterpret this portrait as an expressive BRUSH-AND-INK / sumi-e painting: bold confident "
           "varied-weight black brushstrokes, a little grey ink wash in the shadows, generous white space, the "
           "spontaneity of a single-breath brush portrait."),
}

src = sys.argv[1]; base = src.rsplit(".", 1)[0]
for name, prompt in STYLES.items():
    out = f"{base}_{name}.png"
    bk.save_png(out, bk.image(prompt + KEEP, refs=[src], pro=True))
    print("style", name, out, flush=True)
print("STYLES DONE", flush=True)
