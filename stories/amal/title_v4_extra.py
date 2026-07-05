import os, sys
sys.path.insert(0,"/Users/dusty/dev/brehon-law")
from cinema import frames
OUT="/Users/dusty/dev/brehon-law/stories/amal/title_v4"
JOBS=[
 ("sword_overlay","An ancient curved Rajput talwar sword, old steel notched along the edge, held upright and turning very slowly, the long blade catching a single rim of warm firelight along its edge, everything else pure solid black. Isolated on solid black for a screen-blend compositing overlay. No text."),
 ("fort_inside","Inside the ruined Mandu (Mandavgad) fort of Malwa at dusk: a vast empty hall of weathered Afghan-era stone arches and a great dome receding into soft mist, shafts of fading twilight and a distant warm oil-lamp glow, a single small lone human silhouette far down the long colonnade. Immense, lonely, atmospheric, painterly, desaturated dusk palette, deep depth, cinematic prestige title still. No text. Malwa, Madhya Pradesh, India."),
]
for name,prompt in JOBS:
    out=f"{OUT}/{name}.png"
    if os.path.exists(out): print("skip",name,flush=True); continue
    try: frames.shot(prompt,out,refs=[],register="photoreal",pro=True,face_lock=False); print("done",name,flush=True)
    except Exception as e: print("FAIL",name,str(e)[:140],flush=True)
print("ALL DONE",flush=True)
