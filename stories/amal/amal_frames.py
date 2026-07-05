"""AMAL Ep1 — one live-action frame per scene, conditioned on the cast turnarounds (faces hold).
Scene 2 is the title card (no frame). Digest-skip: existing frames are not re-rendered."""
import os, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import frames

D = "/Users/dusty/dev/brehon-law/stories/amal"
SH, OUT = f"{D}/sheets", f"{D}/frames"
os.makedirs(OUT, exist_ok=True)
tr = lambda *cs: [f"{SH}/{c}_turnaround.png" for c in cs]

SHOTS = [
 (1, "Extreme close-up, firelit night: a scarred old hand slick with blood grips the worn hilt of an ancient talwar nicked a hundred times, a heavy worn gold signet ring on one finger. Behind, soft-focus, an old warrior on his feet on dark ground, blood to the elbow, saffron smoke, shadowy men closing in. Brutal and mythic, the face unseen.", []),
 (3, "A low dust-coloured government police post in a small Malwa town, paint flaking off the board, a CBN jeep up on bricks with a wheel missing. A young earnest new police constable in crisp khaki stands holding a steel trunk on his shoulder, looking at the place. Harsh morning light, dust.", tr("deva")),
 (4, "Inside a government opium weighment shed: a poor farmer watches a steel scale as an officer counts a thin pittance of government notes; a black-market fixer's fat fist of cash waits nearby. Dim, institutional, the cruelty of the trade.", []),
 (5, "Night, a dirt track behind poppy fields: two trucks with lights off, men loading sacks under a tarp by torchlight, an older fixer with a ledger. A heavy tired police inspector and a young constable stand by a jeep watching. Clandestine, tense.", tr("ratan","deva")),
 (6, "A dirt turnout off a field road, harsh day: a man's body in the dust under a bent cycle, flies. A heavy worn old police inspector in soft baggy khaki crouches over it with a clipboard, not really looking; a young constable a step behind. A white Bolero idling, a folded banknote in the dust.", tr("ratan","deva")),
 (7, "A CBN jeep on a Malwa field road, scored poppy fields to the horizon, workers scraping grey opium gum. At a bazaar tea stall a fifteen-year-old boy in a pressed shirt peels a note off a fat roll of cash. The inspector and the young constable in the jeep. Sun, dust.", tr("ratan","deva")),
 (8, "A roadside Malwa tea stall, midday: a heavy old police inspector sits on a bench drinking a cloudy grey poppy-husk water; a hollowed-out old opium addict slumped against the stall's leg; a young constable standing apart. Worn, human.", tr("ratan","deva")),
 (9, "A roadside dhaba, day: a heavy tired old police inspector and a young earnest constable sit on a charpai with two plates of dal-bafla between them, mid-conversation, the inspector eating, the young man troubled. Naturalistic dusty light.", tr("ratan","deva")),
 (10, "A cramped Malwa pawnshop, barred window, shelves of pawned brass and bangles and a stilled sewing machine. A soft careful fifties pawnbroker pours tea across a glass counter to a heavy old police inspector, who looks away. Dim, a secret debt.", tr("ratan")),
 (11, "A clean air-conditioned office behind a grain-trading front, a garlanded photo of a heavy politician on the wall. A manager counts notes at a desk; a heavy old police inspector stands, no chair offered; through a glass partition a heavy smiling politician in a white kurta on a phone. Power and humiliation.", tr("ratan","rana")),
 (12, "A small plain Malwa house, evening, warm low light: a heavy old man sits cross-legged on the floor sharpening an old family sword with a whetstone, a small shrine of a goddess with a lit diya in the corner. A tired sixtyish woman watches from the doorway with a steel plate.", tr("ratan","kanta")),
 (13, "A dark plain house at night, one low light: a heavy old man alone mixes dark poppy husk into water in a brass tumbler with two fingers, eyes half shut. On a shelf a small goddess idol; on pegs above, a sharp old sword. Lonely, addicted, still.", tr("ratan")),
 (14, "Dusk at a rough vermilion-smeared stone shrine under a neem at the edge of poppy fields. A very old bard, blind in one eye, sits by the stone with a small boy; a heavy old police inspector stands apart. Beyond the fields, the lights of a big walled compound coming on. Melancholy, mythic.", tr("ratan","charan")),
 (15, "Night, a fierce Kaal Bhairav shrine aarti: drums, a black vermilion-smeared idol with silver-foil eyes, men pressed in incense smoke, a swinging flame. A heavy old police inspector stands at the back, out of the press, hands joined. Intense, shadowed.", tr("ratan")),
 (16, "A shabby CBN government office, day, yellowed files and a slow fan, a framed minister: a neat fifties police superintendent at a desk slides a file; a heavy old inspector reads it, his eye caught. Bureaucratic, flat light.", tr("ratan","mishra")),
 (17, "Inside a busy small CBN post, morning: a farmer with a tin of opium gum and an envelope; a munshi weighing with a thumb on the scale; another constable pocketing cash at the door. A young constable by the wall watching the whole machine, dismayed.", tr("deva")),
 (18, "A small poor Hindu cremation ground, day, a pyre burning, only a handful of mourners. A heavy old police inspector in plain clothes stands at the edge beside another old man, watching the fire. Smoke, grey, forgotten.", tr("ratan")),
 (19, "Dusk at a cremation ground, the pyre down to embers, mourners gone. A heavy old police inspector sits alone in a parked jeep, not starting it, looking at thin grey smoke, folded bribe notes in his hand. Hollow, heavy.", tr("ratan")),
 (20, "A small warm Malwa home at night, a hand-pump in the yard, a murmuring TV: a plump warm mother kneading dough, a father on a charpai, an eighteen-year-old daughter moving with food, a young constable in uniform coming in. Affection, lamplight.", tr("deva","amma","manju")),
 (21, "Night, the back step of a modest home under a low light: a young constable and his eighteen-year-old sister sit together, she stitching cloth, he half in uniform, a quiet sad conversation. Intimate, warm shadow.", tr("deva","manju")),
 (22, "A modest village house yard, day: a sharp-eyed sixteen-year-old girl grinds masala on a stone, an open schoolbook on a ledge; her hard mother hangs washing; a worn anxious father stands. Tension under ordinary life.", tr("leela","sugna","bherulal")),
 (23, "FLASHBACK, twenty years earlier: a bigger older Malwa house being emptied, men carrying furniture out, papers signed at a door table. A younger version of the inspector (late thirties) in a crisp police uniform stands apart, not stopping it; a fierce younger woman with a baby on her hip confronts him. Betrayal, period, dust.", tr("ratan","sugna")),
 (24, "Night, a small village Devi temple aarti, only women pressed in incense and bells before a fierce little goddess. One young mother with a bruise under her eye in trance, head back, possessed, other women holding her. Raw, female, devotional.", []),
 (25, "Dusk at a poor farmstead: a thug, almost gentle, crouches by a fallen grower while two men hold the man down and a third holds back his screaming young son. Off on the road, a police jeep slows. Quiet menace, gritty.", []),
 (26, "Day, a modest home receiving a groom's family for an arranged match, tea and good plates: an eighteen-year-old girl in a good sari brought out with a tray, eyes down, the groom's mother lifting her chin to inspect her; a young constable watching helplessly from a corner.", tr("manju","deva","amma")),
 (27, "A poppy field at cold dawn, breath visible, scrapers at the rows: a sixteen-year-old girl lying dead on her side in the dirt, a slipper off in the furrow. A heavy old inspector crouched and recognizing; a wrecked father nearby; a young constable behind. Grief, dread.", tr("ratan","deva","bherulal","leela")),
 (28, "Dawn poppy field: a heavy old inspector crouched, examining a dead girl's hand closely; a local constable holding out a register and pen; a desperate father hovering. The inspector refusing the easy paperwork. Forensic, tense.", tr("ratan","bherulal")),
 (29, "A dim inner room of a mourning house, day, women keening: a hard grief-worn fiftyish woman sits on the floor with a dead girl's folded clothes in her lap, looking up; a heavy old inspector stands stricken in the doorway. Devastating, intimate.", tr("ratan","sugna")),
 (30, "A moneyed grower's house, a roaring window cooler: a soft heavy sleazy sixtyish man with gold rings sits expansive; a fourteen-year-old servant girl leaving with a tray; a heavy old inspector standing across, disgusted. Cold opulence.", tr("ratan","dhanraj")),
 (31, "A CBN office, day: a neat fifties superintendent behind a desk leaning in, half-threat half-plea; a heavy old inspector standing, resisting, a paper between them. Tense two-hander, flat office light.", tr("ratan","mishra")),
 (32, "A big walled new-money compound, day, a cream Fortuner, idle young toughs; near the gate under a neem an old vermilion stone shrine. A heavy old police inspector kept waiting in the forecourt, a fist at his side, eyes on the stone. Humiliation.", tr("ratan")),
 (33, "Night behind a police post, a generator humming: a heavy old inspector grips a young constable's collar and pins him against a wall, low and hard, warning him off; the young man wounded. Dark, charged.", tr("ratan","deva")),
 (34, "Night, a plain house, one lamp: a heavy old man alone at a table, an untouched brass tumbler of poppy water, a girl's school photo in his hand, a sharp old sword on the wall behind. The edge of a choice. Still, heavy.", tr("ratan")),
 (35, "Night, an empty CBN office, a single desk lamp: a heavy old inspector at a desk, a thin file open with a girl's school photo clipped to it, a half-filled form, a pen hovering and not coming down; a young constable in the doorway with two glasses of tea. Held breath.", tr("ratan","deva")),
 (36, "Intercut feel: by lamplight a young woman turns a wedding bangle to the light among fussing women; elsewhere a grieving mother on the floor as an aunt folds a dead girl's clothes into a bundle. Two fates rhyming, warm against cold.", tr("manju","sugna")),
 (37, "Night, a CBN office desk: a heavy old inspector caps a pen, takes out a fresh requisition form and writes, signing his own name; a young constable frozen in the doorway with cold teas. The door of no return. Quiet, grave.", tr("ratan","deva")),
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
