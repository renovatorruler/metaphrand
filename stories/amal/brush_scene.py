"""Brush-ink a whole SCENE frame (all figures + environment) via Gemini img2img.
  python brush_scene.py <frame.png> [...]   ->  <frame>_brush.png
"""
import sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import backends as bk

PROMPT = (
 "Reinterpret this entire cinematic film still as an expressive BRUSH-AND-INK / sumi-e illustration — every "
 "figure, the architecture, and the whole environment. Bold confident varied-weight black brushstrokes, grey "
 "ink wash for shadow and depth, generous white space, the spontaneity of brush painting. Keep the EXACT "
 "composition — every figure in their exact position, pose and expression, the setting and the staging all "
 "unchanged. Monochrome black ink on white paper, no colour."
)

for f in sys.argv[1:]:
    out = f.rsplit(".", 1)[0] + "_brush.png"
    bk.save_png(out, bk.image(PROMPT, refs=[f], pro=True))
    print("brush", out, flush=True)
