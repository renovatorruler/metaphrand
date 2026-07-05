"""AMAL title v3 — frozen dramatic tableaux of the moral economy (Hernán register). -> title_culture/"""
import os, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import frames
OUT = "/Users/dusty/dev/brehon-law/stories/amal/title_culture"; os.makedirs(OUT, exist_ok=True)
LOOK = (" Dark cinematic prestige title-sequence still, painterly chiaroscuro, near-black background, "
        "single warm lamp light, deep shadow; desaturated except warm flame, vermilion and gold. A FROZEN "
        "INSTANT, bullet-time: figures caught perfectly still mid-gesture, debris suspended in mid-air. "
        "Absolutely no text or captions. Malwa, Madhya Pradesh, India.")
SHOTS = [
 ("d_darbar", "A grand dark Malwa haveli hall: a single powerful Indian man in white seated high on a gaddi throne, a crowd of supplicants frozen mid-bow before him, hundreds of banknotes suspended in the air falling slowly like leaves, oil lamps, deep shadow." + LOOK),
 ("d_wedding", "A dark Malwa courtyard at night: a veiled young Indian bride in red beside a much older heavy Indian man, marigold garlands and banknotes hanging frozen in the air around them, the wedding family caught still mid-gesture, oil lamps, smoke, ominous." + LOOK),
 ("d_scale", "A dark void with one shaft of light: a huge antique brass balance scale frozen mid-tip; on one pan the small still silhouette of a child, on the other a heavy stack of stamped government documents tied with string, the documents sinking lower; shadowy figures frozen around it, dust suspended in the air, symbolic." + LOOK),
 ("d_pen", "A dark Malwa office: an Indian official at a wooden desk frozen with a pen pressed to a document under a single lamp; around him in the shadows faint human figures frozen as if falling, loose papers and a fold of banknotes suspended in mid-air, ominous." + LOOK),
 ("d_grounddown", "A dark field at dusk: a row of weary Indian farm labourers and veiled women frozen perfectly still, heads bowed, suspended dust hanging in lamplight, deep shadow, a single warm light, the weight of the powerless." + LOOK),
 ("d_title", "A grand wide dark Malwa tableau: frozen dramatic figures on worn stone temple steps in lamplight and smoke, suspended embers and marigold petals hanging in the air, deep shadow, operatic and grand, generous empty dark space across the top of the frame." + LOOK),
]
for name, prompt in SHOTS:
    out = f"{OUT}/{name}.png"
    if os.path.exists(out): print("skip", name, flush=True); continue
    try: frames.shot(prompt, out, register="photoreal", pro=True); print("done", name, flush=True)
    except Exception as e: print("FAIL", name, str(e)[:150], flush=True)
print("ALL DONE", flush=True)
