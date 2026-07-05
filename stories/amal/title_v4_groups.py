import os, sys
sys.path.insert(0,"/Users/dusty/dev/brehon-law")
from cinema import frames
D="/Users/dusty/dev/brehon-law/stories/amal"; OUT=f"{D}/title_v4"; SH=f"{D}/sheets"
DARK=(" Dark cinematic prestige title still, painterly chiaroscuro like a Rembrandt or Caravaggio group "
 "painting, near-black, a single warm oil-lamp light, deep shadow; desaturated except warm flame and gold; "
 "a FROZEN INSTANT, every figure caught perfectly still, embers and smoke suspended in the dark air. "
 "No text. Rural Malwa, Madhya Pradesh, India.")
r=lambda *cs:[f"{SH}/{c}_turnaround.png" for c in cs]
JOBS=[
 ("g_deva_family","Three Indian figures composed together like a Rembrandt group painting in a small dark lamplit room, frozen perfectly still: a young earnest police constable in khaki standing tall (the young man from the first reference), and his elderly mother and his shy young sister huddled close together seated below him (the older woman from the second reference, the young woman from the third reference), his hand resting on his mother's shoulder, one warm oil lamp."+DARK, r("deva","amma","manju")),
 ("g_rana_court","A grand dark haveli durbar hall composed like a baroque painting, frozen still: a powerful smiling heavyset politician in white enthroned high on a cushioned gaddi (the man from the first reference), and below him a prosperous heavy grower (the man from the second reference) and a neat uniformed police officer (the man from the third reference) standing among a crowd of bowed supplicants, banknotes suspended falling in the air, oil lamps and fire."+DARK, r("rana","bherulal","mishra")),
 ("g_sale","A dark Malwa wedding courtyard composed like a Renaissance painting, frozen still and ominous: a fragile sad young veiled bride in red seated (the girl from the first reference) beside a much older fat balding heavy man (the man from the second reference), and a hard grief-worn veiled mother watching helplessly from the shadow (the woman from the third reference), marigold garlands and banknotes suspended frozen in the air, oil lamps, smoke."+DARK, r("leela","dhanraj","sugna")),
 ("g_ratan_kanta","A small bare dark Malwa kitchen composed like a quiet painting, frozen still: a heavy weary old police inspector (the man from the first reference) sitting alone at a low table over a steel plate, and his ageing tired wife in a plain sari (the woman from the second reference) standing apart by the doorway, not looking at him, a cold silent distance between them, one oil lamp."+DARK, r("ratan","kanta")),
]
for name,prompt,refs in JOBS:
    out=f"{OUT}/{name}.png"
    if os.path.exists(out): print("skip",name,flush=True); continue
    try: frames.shot(prompt,out,refs=refs,register="photoreal",pro=True,face_lock=False); print("done",name,flush=True)
    except Exception as e: print("FAIL",name,str(e)[:140],flush=True)
print("ALL DONE",flush=True)
