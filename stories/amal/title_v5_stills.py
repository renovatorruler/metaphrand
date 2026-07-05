import os, sys
sys.path.insert(0,"/Users/dusty/dev/brehon-law")
from cinema import frames
SH="/Users/dusty/dev/brehon-law/stories/amal/sheets"
OUT="/Users/dusty/dev/brehon-law/stories/amal/title_v5"; os.makedirs(OUT,exist_ok=True)
def s(n): return f"{SH}/{n}_turnaround.png"
SUF=(" Old-master oil-painting chiaroscuro in the manner of Caravaggio and Rembrandt: extreme tenebrism, "
 "a single warm low light source, deep impenetrable black shadow, figures and faces modeled out of the "
 "darkness, painterly skin and fabric, strong asymmetric staging with clear focal hierarchy and deep "
 "depth. Photoreal but lit and composed like an old-master painting, desaturated warm palette, prestige "
 "cinematic main-title still, fine film grain. Malwa, Madhya Pradesh, India. No text, no caption, no "
 "watermark, no border, no frame.")
JOBS=[
("rana_court_v2a",[s("rana"),s("bherulal"),s("mishra")],
 "A powerful rural Malwa political boss sits in a heavy carved wooden chair in a darkened hall, lit only "
 "by a single brass oil-lamp on the low table before him; half his face is warm light, half is deep "
 "shadow; he is calm, heavy, absolute, one ringed hand resting on a thick leather ledger. Behind his "
 "shoulder a thin accountant in near-silhouette clutches a register; on the other side a thickset enforcer "
 "looms half-swallowed by black. In the dark foreground, the bowed back and folded hands of a kneeling "
 "farmer catch a sliver of the lamplight. Strong diagonal staging, deep depth; the only brightness is the "
 "lamp and what it touches."),
("rana_court_v2b",[s("rana"),s("mishra")],
 "Seen low from the shadowed floor, over a kneeling farmer's bowed silhouette in the foreground: across a "
 "single guttering oil-lamp sits a heavy Malwa political boss reclined in a carved chair on a low dais, "
 "robed in white, his lined face modeled by the warm flame against total blackness, regarding the "
 "supplicant without mercy or anger. Two shadowed retainers flank him, barely lit — a register, a lathi. "
 "Vast black negative space above. One light source, deep depth, oppressive stillness."),
("deva_family_v2",[s("deva"),s("amma"),s("manju")],
 "A young Malwa farm labourer stands in a dark mud-walled room, a single oil-lamp modeling one side of his "
 "tense young face, the rest falling to black; below him his ageing mother sits on the floor clutching a "
 "steel tumbler, her worried lined face warm in the lamplight, a hand reaching to his sleeve; his teenage "
 "sister huddles against the mother's shoulder, half her face caught, half in shadow. A close protective "
 "triangle of three bodies pressed together in a pool of warm light surrounded by darkness. Dignity and dread."),
("sale_v2",[],
 "A Caravaggio tableau in deep tenebrism: a veiled young bride in red sits utterly still, only her lowered "
 "eyes and hennaed hands lit by a single warm lamp, the rest of her dissolving into black; on the low table "
 "before her an old man's weathered hand presses flat on a stamped folded government document, hard-lit; "
 "behind, a woman's grieving face floats half-seen in the deep shadow, looking away. No celebration, no "
 "jewels glinting — only the document and the bride in the light. The weight of a transaction. Deep depth."),
("ratan_desk_v2",[s("ratan")],
 "A heavy, weary 52-year-old Malwa police inspector in a worn khaki uniform sits alone at a wooden desk in "
 "a dark room, a single oil-lamp on the desk carving his lined jowly face out of total blackness, deep bags "
 "under his eyes; he stares down at an open register, pen still in his thick hand, not writing. Bidi smoke "
 "curls through the lamplight. Everything beyond the small pool of warm light is black. The loneliness of a "
 "compromised man."),
("ratan_kanta_v2",[s("ratan"),s("kanta")],
 "A dark bare kitchen lit by one low oil-lamp: a heavy ageing police inspector sits hunched on the floor "
 "over a steel plate, eating alone, his face shadowed; across the room near the black doorway his ageing "
 "wife stands turned half away, a steel tumbler in her hands, not looking at him, her tired face just "
 "catching the lamplight. A wide cold gap of darkness between the two figures — two small pools of warm "
 "light separated by black. The silence of a dead marriage. Deep depth."),
]
for name,refs,prompt in JOBS:
    out=f"{OUT}/{name}.png"
    if os.path.exists(out): print("skip",name,flush=True); continue
    try:
        frames.shot(prompt+SUF,out,refs=refs,register="photoreal",pro=True,face_lock=False)
        print("done",name,flush=True)
    except Exception as e:
        print("FAIL",name,str(e)[:160],flush=True)
print("STILLS DONE",flush=True)
