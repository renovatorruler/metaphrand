import os, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import frames
SH = "/Users/dusty/dev/brehon-law/stories/amal/sheets"
OUT = "/Users/dusty/dev/brehon-law/stories/amal/ep2_frames_v2"; os.makedirs(OUT, exist_ok=True)
def s(*cs): return [f"{SH}/{c}_turnaround.png" for c in cs]

# Approved new look — SUF copied VERBATIM from frame_style_samples.py (STOCK=portra).
SUF = (" Naturalistic available-light cinematography in the grounded realist style of the Indian crime dramas "
 "Kohrra, Delhi Crime and Paatal Lok, shot on KODAK PORTRA 400 colour film — fine organic grain, soft natural "
 "contrast, gentle natural warmth and the flattering true-to-life skin tones and muted-rich colour Portra is "
 "known for (subtle natural warmth; NOT a heavy yellow or amber 'piss-filter', no sepia, no teal-and-orange). "
 "Real locations: the environment and background are clearly "
 "VISIBLE with depth, never swallowed by black; medium and wide framing that places people IN their world, "
 "not isolated close-ups. A PROSPEROUS opium-growing belt with real money in it — ordinary clean functional "
 "places and outright affluence at the big houses (solid concrete/stone houses, SUVs, well-kept land); NOT a "
 "slum, NOT dire poverty, nothing derelict. CLOTHING is clean and matches each person's station — the wealthy "
 "in crisp well-pressed clothes; ordinary people neat and modest; nobody in filthy or threadbare rags. "
 "Every shot is a CANDID, in-the-moment film still — the people are caught in the dramatic action, absorbed "
 "in the scene, NEVER posing for or smiling into the camera, never mugging at the lens. "
 "Grounded prestige-television realism, photoreal. Malwa, Madhya Pradesh, India. No text, no caption, no watermark.")

# Character notes — reused from the two source files; the wealthy updated to clean, crisp, well-pressed kurtas.
R    = "RATAN, a heavy weary 52-year-old Malwa inspector in clean pressed khaki, lined jowly face, grey moustache, bags under his eyes"
RP   = "RATAN, a heavy weary 52-year-old man in neat plain clothes, lined jowly face, grey moustache"  # suspended, out of uniform
RANA = "RANA, a big genial middle-aged Malwa political boss in a crisp white kurta, broad calm well-fed face"
BH   = "BHERULAL, a thickset prosperous Malwa trader-seth about 45, well-fed, in a clean well-pressed kurta with a gold ring"
MI   = "MISHRA, a smooth ageing CBN bureaucrat with a tired reasonable face, in a neat shirt"
DV   = "DEVA, a 24-year-old constable in clean khaki, earnest young face"
SU   = "SUGNA, an ageing woman in a plain clean sari, hard dry-eyed grief"

FR = [
 # ---- Scene 1 — district hospital / morgue at dawn ----
 ("sc01_est", [],
  "Wide establishing exterior of an ordinary district government hospital at first light: a plain functional "
  "two-storey concrete building, a portico, a few parked motorcycles and an ambulance, a low boundary wall, a "
  "neem tree, the town waking behind it. Soft clear dawn, clean and ordinary, fully visible with depth."),
 ("sc01", s("ratan","bherulal"),
  f"Interior of a clean district-hospital morgue outbuilding at dawn, the tin door open to the soft morning "
  f"light, the room and a steel trolley clearly visible. Bherulal's flat-eyed man lays a banded brick of cash "
  f"on an open register held by a nervous young compounder; back near the doorway {R} stands quietly watching, "
  f"unnoticed. Medium-wide, the whole room reads."),

 # ---- Scene 3 — Rana's farmhouse durbar ----
 ("sc03_est", [],
  "Wide establishing shot of a prosperous, well-kept Malwa farmhouse compound at mid-morning: a high green "
  "gate, a watered green lawn, a swept courtyard, two clean white SUVs parked, tended poppy fields stretching "
  "behind. Visible rural wealth, ordinary and affluent, bright clear daylight, deep landscape."),
 ("sc03", s("rana"),
  f"Wide daytime shot of the farmhouse verandah durbar. {RANA} reclines on a carved wooden swing-seat; before "
  f"him stands KISHAN, an old straight-backed farmer with white stubble in a clean homespun kurta, not bowing; "
  f"a line of neatly dressed petitioners with folded hands waits to one side. The well-kept verandah and green "
  f"compound visible behind. Natural daylight."),

 # ---- Scene 4 — morgue doorway, Ratan & Sugna ----
 ("sc04", s("ratan","sugna"),
  f"Medium-wide shot in the open doorway of the clean morgue, soft daylight, the corridor and a wrapped body "
  f"on a trolley visible behind. {R} faces {SU} across a low threshold, a cold quiet confrontation; the room "
  f"and its depth read clearly around them."),
 ("sc04_a2", s("ratan","sugna"),
  f"Closer two-shot across the morgue threshold: {R} and {SU} face to face, the cold confrontation between "
  f"them, jaws set; the soft-lit corridor still visible behind, never black. Natural light."),

 # ---- Scene 5 — Deva's family house, night ----
 ("sc05_est", [],
  "Wide establishing shot of a modest, neat village family house at night: a plain single-storey concrete "
  "house on an ordinary lane, one warm lit window, a clean swept yard, a parked motorcycle. Ordinary and "
  "well-kept, not poor, the lane and house clearly visible in the soft night light."),
 ("sc05", s("amma","manju","deva"),
  f"Interior of a small, tidy, warmly-lit family room at night, the modest clean room visible with depth. "
  f"AMMA, a warm ageing mother in a clean sari, holds up a glowing phone photo; MANJU, her teenage daughter, "
  f"sits with her eyes down; {DV} stands in the doorway, the day heavy on him. Medium-wide, soft warm light."),

 # ---- Scene 6 — CBN office ----
 ("sc06_est", [],
  "Wide establishing exterior of an ordinary CBN (Central Bureau of Narcotics) office compound in a Malwa "
  "town, mid-morning: a plain functional government building, a board and flagpole, a boundary wall, a couple "
  "of white government jeeps parked, staff motorcycles. Clean, official, ordinary; fully visible, clear daylight."),
 ("sc06", s("ratan","deva"),
  f"Interior of a plain, functional CBN office, daylight through a window, the whole room and its files "
  f"visible. {R} at a wooden desk pushes a fold of banknotes back across the desk with one finger; a stunned "
  f"farmer in a clean kurta stands before him; {DV} watches from a side table. Medium-wide, natural office light."),

 # ---- Scene 7 — Mishra & Ratan, bureaucrat's room ----
 ("sc07", s("mishra","ratan"),
  f"Medium-wide shot in a tidy bureaucrat's office, a bright window behind, the room visible. {MI} and {R} sit "
  f"across a wooden desk in a tense, reasonable argument; both clearly placed in the lived-in official room. "
  f"Soft natural daylight."),

 # ---- Scene 8 — Bherulal's big house, counting cash ----
 ("sc08_est", [],
  "Establishing exterior of a wealthy Malwa trader's house: a large solid two-storey concrete house with a "
  "high compound wall and gate, a clean white SUV and a tractor parked inside, a water tank and satellite "
  "dish on the roof — clearly the richest house on an ordinary village lane, green fields behind it. Bright "
  "clear daylight, the affluence plainly visible."),
 ("sc08", s("bherulal","sugna"),
  f"Wide interior of the wealthy trader's house — a large cool room, a big colour TV on, a deep-freeze, a new "
  f"tractor's registration papers on the table. {BH} sits at a low table banding tall stacks of banknotes like "
  f"a man counting grain; his flat-eyed enforcer waits; in an inner doorway {SU} pauses with a steel tumbler, "
  f"watching. The affluent room and its depth clearly visible."),
 ("sc08_a2", s("bherulal","sugna"),
  f"Closer shot inside the same affluent room: {BH}'s hands banding a thick brick of banknotes on the low "
  f"table, the casual obscene cash plain; behind him, soft-focus but visible, {SU} watches from the inner "
  f"doorway with the steel tumbler. The room still reads, natural light."),

 # ---- Scene 9 — outside CBN post, Bherulal's false warmth ----
 ("sc09", s("bherulal","ratan"),
  f"Medium-wide exterior outside a CBN post in daylight, a clean white SUV parked, the road and building "
  f"visible. {BH}, all false warmth, drops an arm around the shoulder of {R}; a flat-eyed enforcer a step "
  f"behind. Bright natural daylight, the scene placed fully in its world."),

 # ---- Scene 10 — hospital office counter ----
 ("sc10", s("ratan","deva"),
  f"Medium-wide interior at a hospital office counter, ordinary institutional room, fully visible. {R} and "
  f"{DV} stand before a sorry, immovable clerk behind the counter who will not release a vehicle. Plain natural "
  f"daylight through a window."),

 # ---- Scene 11 — riverside cremation ground ----
 ("sc11_est", [],
  "Wide establishing shot of a riverside cremation ground at grey dawn: a stepped ghat by a calm river, a "
  "single unlit funeral pyre built and waiting with no body on it, the far bank and trees beyond. Clean, "
  "ordinary, solemn; the whole ghat and the river visible with depth, soft early light."),
 ("sc11", s("ratan","sugna"),
  f"Wide shot of the riverside cremation ground at grey dawn, the river and ghat visible behind. A built, "
  f"unlit pyre waits with no body; a ring of mourning women in clean saris stands around it, {SU} dry-eyed at "
  f"the centre; {R} stops on the path, the crowd quietly against him. Soft grey morning light."),

 # ---- Scene 12 — night transport stand ----
 ("sc12", s("ratan","deva"),
  f"Medium-wide shot at a night transport stand, a string of bulbs over parked tempos and a tea stall, the "
  f"yard visible. {RP} talks to a wary tempo driver; {DV} watches from a few steps back. Ordinary working "
  f"night scene, warm practical lights, the place fully readable."),

 # ---- Scene 13 — arrival at Rana's gate, twilight ----
 ("sc13", s("ratan","deva"),
  f"Wide shot at twilight: a high green gate and a paved drive into a well-kept compound with a green lawn, "
  f"poppy fields around; {R} and {DV} arrive in a dusty borrowed jeep, a couple of Rana's men loitering by "
  f"the gate. Soft blue twilight, the prosperous compound and the land visible with depth."),

 # ---- Scene 14 — verandah welcome, Ratan refuses ----
 ("sc14", s("rana","ratan"),
  f"Medium-wide shot on the well-kept farmhouse verandah, the green compound visible behind. {RANA} rises from "
  f"the carved swing-seat with open arms in welcome; {R} stands stiff and cold, refusing it. Warm natural "
  f"evening light, the verandah and durbar setting fully visible."),
 ("sc14_a2", s("rana","ratan"),
  f"Closer shot on the verandah: a cupped brass bowl of kasumba (opium-water) being prepared on a low table, "
  f"{RANA}'s big calm hand near it, {R} watching warily at the edge of frame. The verandah still reads behind, "
  f"warm natural light, never black."),

 # ---- Scene 15 — the kasumba offered ----
 ("sc15", s("rana","ratan"),
  f"Medium shot on the verandah, the durbar setting visible. {RANA} holds out a cupped palm of opium-water "
  f"(kasumba) toward {R}, the old courtesy that cannot be refused; {R} hesitates. Warm natural light, the "
  f"room and depth clear."),
 ("sc15_a2", s("rana","ratan"),
  f"Closer two-shot of the kasumba offer: {RANA}'s open cupped palm of opium-water held out and {R}'s hesitating "
  f"face, the ritual courtesy between them; the lit verandah soft behind. Natural warm light."),

 # ---- Scene 16 — the soft offer ----
 ("sc16", s("rana","ratan"),
  f"Medium shot on the verandah, the setting visible. {RANA} leans in close making a soft offer; {R} watches "
  f"him, guarded; {DV} at the edge of frame. Intimate but fully lit, warm natural light, the world around "
  f"them readable."),
 ("sc16_a2", s("rana","ratan"),
  f"Closer two-shot of the bribe being offered: {RANA} murmuring his soft offer and {R}'s guarded, unmoving "
  f"face, the two men close; the warm-lit verandah soft behind them, never swallowed by black. Natural light."),

 # ---- Scene 17 — refusal, the mask drops ----
 ("sc17", s("ratan","rana"),
  f"Medium shot on the verandah, the durbar setting visible. {R} stands to leave, having said no; for one "
  f"instant {RANA}'s warm mask is gone and something cold looks out of his face. Warm natural light, the "
  f"setting still clearly around them."),
 ("sc17_a2", s("ratan","rana"),
  f"Closer shot on {RANA}'s face as the genial mask drops and a cold hardness shows, {R}'s back half in frame "
  f"as he turns to leave; the lit verandah soft behind. Natural warm light, never black."),

 # ---- Scene 18 — jeep leaving on field road ----
 ("sc18", s("deva","ratan"),
  f"Wide shot of a jeep on a field road in hard low afternoon sun, the green farmhouse gate shrinking behind, "
  f"tended poppy fields all around. {DV} drives; {R} stares out at the fields. The open prosperous landscape "
  f"clearly visible with depth."),

 # ---- Scene 19 — the tempo ambush, night highway ----
 ("sc19", s("ratan","deva"),
  f"Wide shot on an empty pre-dawn highway: a tempo van carrying a wrapped body in the back; ahead a "
  f"tractor-trolley is slewed across a culvert blocking the road, a Bolero's headlights closing behind. {R} "
  f"and {DV} tense inside the cab. Cool blue pre-dawn light, the road and fields readable, lit by headlamps "
  f"and the coming dawn, not black."),

 # ---- Scene 20 — Mishra on the phone ----
 ("sc20", s("mishra"),
  f"Medium shot in a tidy office, daylight through a window, the room visible. {MI} on a desk telephone, his "
  f"smooth confidence flickering as the call goes wrong. Natural office light, the lived-in room around him."),

 # ---- Scene 21 — city district hospital ----
 ("sc21_est", [],
  "Wide establishing exterior of a larger city district hospital by day: a bigger multi-storey concrete "
  "building with a busy portico, ambulances, autorickshaws, people coming and going, a signboard and parked "
  "vehicles. Ordinary urban India, busy and functional, fully visible with depth, clear daylight."),
 ("sc21", s("ratan"),
  f"Medium-wide shot in a cool hospital corridor, the corridor and doors visible. A rumpled tired forensic "
  f"doctor in his fifties (KHARE) in a clean coat with a clipboard meets {R}, who carries one end of a wrapped "
  f"body; no one helps. Plain institutional daylight, the space fully readable."),

 # ---- Scene 22 — the autopsy ----
 ("sc22", s("ratan","deva"),
  f"Wide shot of a clean, plain morgue autopsy room, a steel table and a floor drain, tiled walls visible. A "
  f"doctor begins an autopsy on a covered young body; {R} stands grimly at the head, {DV} grey-faced against "
  f"the wall. Even institutional light, the whole room readable, clinical not black."),
 ("sc22_a2", s("ratan","deva"),
  f"Closer shot in the autopsy room: {R} grim at the head of the steel table and {DV} grey-faced beside it, "
  f"the covered body between them; the tiled morgue still visible behind. Even clinical light."),

 # ---- Scene 23 — Khare's verdict ----
 ("sc23", s("ratan"),
  f"Medium shot in the cool morgue, the room and steel visible behind. The doctor (KHARE, fifties, rumpled, "
  f"clean coat) dries his hands and speaks flatly to {R}, delivering a grave finding. Even clinical light, the "
  f"space fully readable."),
 ("sc23_a2", s("ratan"),
  f"Closer two-shot of the verdict: KHARE's flat tired face as he speaks and {R} taking it in, the morgue "
  f"steel soft behind them. Even clinical light, never black."),

 # ---- Scene 24 — outside the hospital, after ----
 ("sc24", s("ratan","deva"),
  f"Medium-wide exterior outside the hospital in bright day after the dark, the building and forecourt "
  f"visible. {DV} sits wrung-out on a step; {R} comes out holding a folded report; the doctor lights a "
  f"cigarette nearby. Bright natural daylight, long soft shadows, the place fully readable."),

 # ---- Scene 25 — village post office ----
 ("sc25", s("ratan","deva"),
  f"Medium-wide shot at a small village post office counter, the modest office visible. {R} seals an envelope "
  f"addressed to himself and posts it, a registered slip on the counter; {DV} beside him, not understanding. "
  f"Dusty afternoon daylight, the ordinary room readable."),

 # ---- Scene 26 — Deva and Manju, night room ----
 ("sc26", s("deva","manju"),
  f"Medium shot in a tidy, warmly-lit family room at night, the modest room visible. {DV} sits across from his "
  f"teenage sister MANJU; he asks her something gently, she has no answer, eyes down. Soft warm light, the "
  f"room and depth clear."),

 # ---- Scene 27 — Amma tells Deva ----
 ("sc27", s("amma","deva"),
  f"Medium shot in a small, neat night room, the room visible. AMMA, an anxious ageing mother in a clean sari, "
  f"tells {DV} a hard thing, a worry under her brightness. Soft warm light, the modest room fully readable."),

 # ---- Scene 28 — Ganga the addict, behind the liquor shop ----
 ("sc28", s("ratan"),
  f"Medium-wide shot behind an ordinary country-liquor shop at dusk, crates and a back lane visible. {R} "
  f"crouches by GANGA, a gaunt shaking doda addict in worn but not filthy clothes, folded against a wall, "
  f"wrecked and hollow-eyed. Soft last grey-blue daylight, the lane and shop readable, not black."),

 # ---- Scene 29 — late night, Ratan working the case ----
 ("sc29", s("ratan","deva"),
  f"Medium shot in the CBN office late at night, a desk lamp and overhead light on, the room and files "
  f"visible. {R} at his desk with a copied report works the case out half to {DV} and half to himself. Warm "
  f"practical light, the office still readable around them, not swallowed by black."),

 # ---- Scene 30 — Ratan alone with the one name ----
 ("sc30", s("ratan"),
  f"Medium shot of {R} alone at his desk deep in the night, a desk lamp lit, the office visible behind. He "
  f"stares at a page on which a single name is written and the rest is empty; doubt on his lined face. Warm "
  f"low practical light, the room still readable, not black."),

 # ---- Scene 31 — the munshi and the file ----
 ("sc31", s("deva"),
  f"Medium-wide shot in the CBN office by day, the room and files visible. A sly munshi in a neat shirt slides "
  f"a file with a fold of cash across to {DV}, who signs but leaves the money; the daily machinery. Flat "
  f"natural office daylight, the place fully readable."),

 # ---- Scene 32 — Govind by the river ----
 ("sc32", s("ratan"),
  f"Wide shot on stone steps by a river at evening, the broad calm river and far bank visible. An old friend "
  f"(GOVIND, an ageing man in a clean kurta) sits beside {R} at the water's edge, a hand on his shoulder. Soft "
  f"golden dusk over the river, the open landscape clearly visible."),

 # ---- Scene 33 — the parting at the fork ----
 ("sc33", s("ratan","deva"),
  f"Wide shot on a quiet night lane lit by a couple of streetlamps, the lane and houses visible. {RP} and {DV} "
  f"walk together; at a fork they part, {R} not looking at the boy. Soft practical night light, the street "
  f"readable, not black."),

 # ---- Scene 34 — Rana, the songbird, Bherulal pleads ----
 ("sc34", s("rana","bherulal"),
  f"Medium-wide shot on the well-kept verandah, the green compound visible behind. {RANA} on the swing-seat "
  f"feeds a caged songbird while {BH}, anxious for once, pleads before him. Warm natural evening light, the "
  f"verandah and durbar setting fully visible."),

 # ---- Scene 35 — the suspension ----
 ("sc35", s("mishra","ratan"),
  f"Medium shot in the tidy office, the room visible. {MI} gently sets a suspension order on the desk; {RP} "
  f"unclips his police badge and lays it down beside a holstered revolver. Tired, sorrowful, soft natural "
  f"daylight, the room fully readable."),

 # ---- Scene 36 — Ratan's own house, the kitchen thaw ----
 ("sc36_est", [],
  "Wide establishing shot of Ratan's own modest, neat house at night: a plain single-storey concrete house on "
  "an ordinary lane, a warm lit kitchen window, a clean small yard. Ordinary and well-kept, not poor; the "
  "house and lane clearly visible in soft night light."),
 ("sc36", s("ratan","kanta"),
  f"Medium-wide shot in a plain, clean home kitchen at night, the modest kitchen visible with depth. {RP} sits "
  f"over a steel plate; his ageing wife KANTA in a plain clean sari sits down across from him for the first "
  f"time in years and pushes the plate closer; pension papers on the table. Warm soft kitchen light, the room "
  f"readable, a quiet thaw."),
 ("sc36_a2", s("ratan","kanta"),
  f"Closer two-shot at the kitchen table: KANTA sitting down across from {RP} and pushing the steel plate "
  f"closer toward him, the pension papers beside it, the small wordless thaw between them; the warm kitchen "
  f"soft behind. Natural warm light, never black."),

 # ---- Scene 37 — the senior officer's anteroom ----
 ("sc37", s("ratan"),
  f"Medium-wide shot in a senior officer's anteroom, the corridor and a closed office door visible. {RP}, an "
  f"old man in neat plain clothes with a folder on his knee, sits on a bench while a PA turns him away. Plain "
  f"cool institutional daylight, the space fully readable."),

 # ---- Scene 38 — the lit haveli across the field ----
 ("sc38", s("ratan","deva"),
  f"Wide shot across an open field at night, a big lit haveli glowing warm at the far end, the field and sky "
  f"visible. {RP} and {DV}, out of uniform, stand in the soft-lit foreground watching it. Soft moonlit night, "
  f"the landscape and the distant house clearly readable, not a black void."),

 # ---- Scene 39 — the lone walk toward the lit house ----
 ("sc39", s("ratan"),
  f"Wide shot of a lone old man (RATAN, neat plain clothes, a folder under his arm) walking a quiet empty road "
  f"through the sleeping poppy belt at night toward a single lit house far ahead, the fields and sky visible. "
  f"Soft moonlit night, one warm distant light, the open landscape clearly readable with depth, not a black void."),
]

# Per-scene play order: EST first, then the main shot, then any A2 angles.
SHOTS = {
 1:  ["sc01_est", "sc01"],
 3:  ["sc03_est", "sc03"],
 4:  ["sc04", "sc04_a2"],
 5:  ["sc05_est", "sc05"],
 6:  ["sc06_est", "sc06"],
 7:  ["sc07"],
 8:  ["sc08_est", "sc08", "sc08_a2"],
 9:  ["sc09"],
 10: ["sc10"],
 11: ["sc11_est", "sc11"],
 12: ["sc12"],
 13: ["sc13"],
 14: ["sc14", "sc14_a2"],
 15: ["sc15", "sc15_a2"],
 16: ["sc16", "sc16_a2"],
 17: ["sc17", "sc17_a2"],
 18: ["sc18"],
 19: ["sc19"],
 20: ["sc20"],
 21: ["sc21_est", "sc21"],
 22: ["sc22", "sc22_a2"],
 23: ["sc23", "sc23_a2"],
 24: ["sc24"],
 25: ["sc25"],
 26: ["sc26"],
 27: ["sc27"],
 28: ["sc28"],
 29: ["sc29"],
 30: ["sc30"],
 31: ["sc31"],
 32: ["sc32"],
 33: ["sc33"],
 34: ["sc34"],
 35: ["sc35"],
 36: ["sc36_est", "sc36", "sc36_a2"],
 37: ["sc37"],
 38: ["sc38"],
 39: ["sc39"],
}

if __name__ == "__main__":
    only = set(sys.argv[1:])   # optional: render only these shot names
    todo = [(n, r, p) for (n, r, p) in FR if (not only or n in only) and not os.path.exists(f"{OUT}/{n}.png")]
    print(f"{len(FR)} shots, {len(todo)} to render", flush=True)
    for n, r, p in todo:
        try:
            frames.shot(p + SUF, f"{OUT}/{n}.png", refs=[x for x in r if os.path.exists(x)], register="photoreal", pro=True, face_lock=False)
            print("  done", n, flush=True)
        except Exception as e:
            print("  FAIL", n, str(e)[:120], flush=True)
    print("FRAMES DONE", flush=True)
