import os, sys
sys.path.insert(0,"/Users/dusty/dev/brehon-law")
from cinema import frames
OUT="/Users/dusty/dev/brehon-law/stories/amal/title_v5/lancing_v2.png"
PROMPT=("Extreme macro at first light: a single green opium poppy pod, freshly scored with three fine "
 "vertical cuts, a fat bead of milky white latex swelling and bleeding from the incision and running "
 "down the skin; a thin curved lancing blade rests against it. Everything else falls into deep black; "
 "one cold sliver of dawn light rakes across the pod. Beauty and a wound in one frame. "
 "Old-master chiaroscuro tenebrism, single light source, deep black background, painterly, shallow "
 "depth of field, photoreal but lit like a Caravaggio still life, fine film grain, prestige cinematic "
 "main-title still. Malwa opium belt, India. No text, no caption, no watermark.")
if os.path.exists(OUT): print("skip"); 
else:
    try: frames.shot(PROMPT,OUT,refs=[],register="photoreal",pro=True,face_lock=False); print("done lancing")
    except Exception as e: print("FAIL",str(e)[:160])
