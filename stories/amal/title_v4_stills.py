import os, sys
sys.path.insert(0,"/Users/dusty/dev/brehon-law")
from cinema import frames
D="/Users/dusty/dev/brehon-law/stories/amal"; OUT=f"{D}/title_v4"; SH=f"{D}/sheets"; os.makedirs(OUT,exist_ok=True)
DARK=(" Dark cinematic prestige title still, painterly chiaroscuro, near-black, a single warm oil-lamp "
 "light, deep shadow; desaturated except warm flame and gold; a FROZEN INSTANT, figure caught perfectly "
 "still, embers and smoke suspended in the dark air. No text. Rural Malwa, Madhya Pradesh, India.")
TWI=(" Cinematic prestige title still, desaturated dusk twilight, soft mist, muted cool palette with a "
 "faint warm horizon, atmospheric, painterly, deep depth. No text. Malwa, Madhya Pradesh, India.")
OVR=" on a pure solid black background, nothing else, slow, for compositing. No text."
ref=lambda c:[f"{SH}/{c}_turnaround.png"]
JOBS=[
 ("ratan_desk","The man from the reference image, a heavy weary ageing Indian police inspector in worn loose khaki, frozen perfectly still at a wooden desk under one oil lamp, a pen in his hand on an open file, head slightly bowed."+DARK, ref("ratan"), True),
 ("rana_darbar","The man from the reference image, a powerful genial heavyset Indian politician in immaculate white, frozen seated high on a cushioned gaddi throne in a grand dark haveli hall, a crowd of supplicants bowed low before him, banknotes suspended falling through the air like leaves, oil lamps."+DARK, ref("rana"), True),
 ("bherulal_cash","The man from the reference image, a heavy prosperous hard Indian opium grower, frozen still mid-count of a thick banded brick of banknotes by lamplight, loose notes suspended in the air around him."+DARK, ref("bherulal"), True),
 ("sugna_veil","The woman from the reference image, a hard grief-worn middle-aged Indian woman with her head covered in a dark veil, frozen perfectly still in deep shadow, a single oil-lamp glow on her stone face, thin smoke drifting."+DARK, ref("sugna"), True),
 ("deva_watch","The young man from the reference image, a young earnest Indian police constable in khaki, frozen still half in shadow watching intently, lamplight on one side of his face."+DARK, ref("deva"), True),
 ("fort_mandu","The great Mandu Mandavgad fort of Malwa at twilight, vast ancient Afghan-Malwa stone domes arches and ramparts on a high plateau, the Jahaz Mahal silhouette over still water, dusk mist, a tiny lone human silhouette on the rampart, immense and lonely."+TWI, [], False),
 ("river_crowd","A vast sea of anonymous pilgrim silhouettes at a wide river's ghats at dawn, soft heavy mist, an ocean of people and a few faint columns of smoke rising, abstracted, no idols, no temple, just the multitude and the river and the dawn light."+TWI, [], False),
 ("fire_overlay","Soft orange flames and floating glowing embers rising slowly"+OVR, [], False),
 ("smoke_overlay","Thin wisps of pale grey smoke curling and drifting slowly"+OVR, [], False),
]
for name,prompt,refs,fl in JOBS:
    out=f"{OUT}/{name}.png"
    if os.path.exists(out): print("skip",name,flush=True); continue
    try: frames.shot(prompt,out,refs=refs,register="photoreal",pro=True,face_lock=fl); print("done",name,flush=True)
    except Exception as e: print("FAIL",name,str(e)[:140],flush=True)
print("ALL DONE",flush=True)
