import os, sys
sys.path.insert(0,"/Users/dusty/dev/brehon-law")
from cinema import frames
OUT="/Users/dusty/dev/brehon-law/stories/amal/title_v4"
DARK=(" Dark cinematic prestige title still, painterly chiaroscuro like a Caravaggio group painting, "
 "near-black, a single warm oil-lamp light, deep shadow; desaturated except warm flame and gold; a FROZEN "
 "INSTANT, every figure perfectly still, petals and banknotes suspended in the dark air. No text. Rural "
 "Malwa, Madhya Pradesh, India.")
p=("A dark Malwa wedding courtyard composed like a Renaissance painting, frozen still and ominous: a "
 "fragile sad young veiled Indian bride in red seated beside a much older fat balding heavy Indian man, "
 "and a hard grief-worn veiled older woman watching helplessly from the shadow, marigold garlands and "
 "banknotes suspended frozen in mid-air, oil lamps, smoke. Anonymous archetypal figures, the moment a "
 "daughter is sold."+DARK)
try: frames.shot(p, f"{OUT}/g_sale_anon.png", refs=[], register="photoreal", pro=True, face_lock=False); print("done g_sale_anon")
except Exception as e: print("FAIL", str(e)[:150])
