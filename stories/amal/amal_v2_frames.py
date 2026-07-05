"""AMAL Ep1 v2 — one live-action frame per scene (23 scenes; scene 2 is the title, no frame),
conditioned on the cast turnarounds where they exist. Every prompt enforces INDIAN / rural Malwa.
Digest-skip: existing frames are not re-rendered. -> stories/amal/frames_v2/."""
import os, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import frames

D = "/Users/dusty/dev/brehon-law/stories/amal"
SH, OUT = f"{D}/sheets", f"{D}/frames_v2"
os.makedirs(OUT, exist_ok=True)
tr = lambda *cs: [p for c in cs if os.path.exists(p := f"{SH}/{c}_turnaround.png")]  # only existing sheets

SHOTS = [
 (1, "Extreme close-up, firelit night, rural India circa 1305: a scarred old Indian hand slick with blood grips the worn hilt of an ancient Rajput talwar nicked a hundred times, a heavy worn gold signet ring on one finger. Behind, soft-focus, an old Rajput warrior on his feet on dark ground, blood to the elbow, saffron smoke, shadowy attackers closing in. Brutal and mythic, the face unseen.", []),
 (3, "A low dust-coloured CBN government police post in a small Malwa town, rural India, paint flaking off the board, a CBN jeep up on bricks with a wheel missing. A young earnest Indian police constable in crisp new khaki stands holding a steel trunk on his shoulder, taking the place in. Harsh morning light, dust.", tr("deva")),
 (4, "Inside a small dusty Malwa CBN police post, day: a heavy tired old Indian police inspector in soft baggy khaki at a wooden desk signs a file without reading it, a folded banknote sliding under the blotter; a grieving Indian farmer turning his cap; a young earnest Indian constable watching, troubled. Flat institutional light.", tr("ratan", "deva")),
 (5, "A cramped Malwa pawnshop, rural India, barred window, shelves of pawned brass and bangles. An old Indian moneylender behind a low counter with a small cloth bundle; a very old Indian bard blind in one eye on a stool; a heavy old Indian police inspector standing, looking away, his ring finger bare. Dim, a secret shame.", tr("ratan", "charan")),
 (6, "Inside a dusty Malwa CBN police post, day: a dust-covered Indian constable hands a thin one-page file across a desk to a heavy tired old Indian inspector; a young Indian constable beside him looks at the file. Flat light.", tr("ratan", "deva")),
 (7, "Inside a Malwa CBN police post, amber evening light, rural India: a heavy old Indian inspector at a desk caps a pen over a closed thin file, a fold of banknotes going into his breast pocket; a young Indian constable stands silent and troubled. Worn.", tr("ratan", "deva")),
 (8, "A small kept Malwa home at night, warm low light, rural India: a heavy old Indian man sits before a steel plate of food looking at his bare ring finger; a tired sixtyish Indian wife in a plain sari stands by; an opened government envelope on a side table. Quiet, a grown distance.", tr("ratan", "kanta")),
 (9, "A small poor Hindu cremation ground in rural Malwa, day, a pyre burning, only a handful of Indian mourners. A heavy old Indian police inspector in plain clothes stands at the edge beside another Indian man his own age, both watching the fire. Grey smoke, forgotten.", tr("ratan")),
 (10, "Dusk at a rural Malwa cremation ground, the pyre down to embers, mourners gone. A heavy old Indian inspector and an old Indian friend his age, by the embers, a quiet hard conversation. Hollow, grey, intimate.", tr("ratan")),
 (11, "A poppy and wheat field's edge in rural Malwa, harsh day: a heavy old Indian police inspector crouched low at a knee-high mud bund, reading the trampled ground; a wary young Indian herder hanging back; a few uneasy Indian villagers watching. The detective waking. Dust, hard light.", tr("ratan")),
 (12, "Inside a Malwa CBN police post, day: a heavy old Indian inspector pulls a closed thin file back open and writes an order on a form, signing; a startled Indian munshi clerk over a register; a young Indian constable by the wall, hope returning to his face.", tr("ratan", "deva")),
 (13, "A neat Indian police superintendent's office, day, a clean desk, a framed minister, a glass of water: a calm fiftyish Indian superintendent in pressed uniform gestures warmly to a chair; a heavy old Indian inspector stands, unmoved. Smooth, institutional.", tr("ratan", "mishra")),
 (14, "A fierce black-stone Kaal Bhairav shrine in rural Malwa, day, heaped marigolds and silver foil, smeared vermilion: an Indian priest pours country liquor into a silver dish at the idol's mouth; a heavy old Indian inspector looks at the god; a young Indian constable a step back, astonished. Intense, shadowed.", tr("ratan", "deva")),
 (15, "A dusty Malwa village lane, day, doors closing: an old Indian woman sweeping a doorstep talks to a heavy old Indian inspector and a young Indian constable; the lane wary and shut around them. Hard light, dust.", tr("ratan", "deva")),
 (16, "A small warm plain Malwa home at night, one tube-light, rural India: a plump warm Indian mother presses a roti onto a plate; a young Indian constable in uniform; a quiet pretty eighteen-year-old Indian sister sitting to the side, eyes down, being talked about. Affection, lamplight.", tr("deva", "amma", "manju")),
 (17, "Inside a Malwa CBN police post, day: a heavy old Indian inspector stands holding a typed stamped postmortem report, not putting it down, a hard knowing on his face; an apologetic Indian munshi at a register. Flat light, a realization.", tr("ratan")),
 (18, "A district hospital doctor's room in rural India, day, phenyl smell, yellowed papers: a tired clean-shaven fiftyish Indian government doctor seated, flat and clinical; a heavy old Indian inspector stands across the desk. A cold mirror. Institutional.", tr("ratan")),
 (19, "Dusk over poppy and wheat fields in rural Malwa: a heavy old Indian inspector on foot questions a wary Indian field labourer coiling rope; the labourer gives little; a big lit house far across the darkening fields. Off-the-books, quiet, tense.", tr("ratan")),
 (20, "A prosperous Malwa grower's house at night, gold at the doorway, rural India: a hard grief-worn fiftyish Indian woman stands in the open doorway facing a heavy old Indian inspector with his cap in his hands; behind her a dim mourning house, a dead girl's school things on a shelf; a heavy still Indian man fills the inner doorway. Devastating, charged.", tr("ratan", "sugna", "bherulal")),
 (21, "A side room of a prosperous Malwa house at night, rural India: a heavy prosperous Indian grower seated, calculating, talks terms to a heavy old Indian inspector seated across; a flat-faced Indian henchman by the door. Cold, quiet menace.", tr("ratan", "bherulal")),
 (22, "A plain Malwa house at night, one oil lamp, rural India: a heavy old Indian man alone at a table with two papers — a report and a blank form — a brass tumbler of grey poppy water going cold; his bare ring finger pale in the light; a tired Indian wife watching from a doorway. The edge of a choice.", tr("ratan", "kanta")),
 (23, "An empty Malwa CBN police post at grey dawn, the fan still, rural India: a heavy old Indian inspector at a desk signs his own name to a hand-written requisition; a young Indian constable stopped in the doorway, seeing it, standing straighter. Quiet, grave, first light.", tr("ratan", "deva")),
]

done = 0
for num, prompt, refs in SHOTS:
    out = f"{OUT}/sc{num:02d}.png"
    if os.path.exists(out):
        done += 1; continue
    frames.shot(prompt, out, refs=refs or None, register="photoreal", pro=True, face_lock=bool(refs))
    done += 1
    print(f"  [{done}/{len(SHOTS)}] sc{num}", flush=True)
print(f"FRAMES DONE: {done} shots -> {OUT}", flush=True)
