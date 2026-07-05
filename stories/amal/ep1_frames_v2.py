"""AMAL Ep1 v2 — frame generation in the matured cinematic series style.
One "scNN" main shot per Ep1 scene (scenes 1, 3-23; scene 2 is the title card, no frame),
matched to ep1_v2_timing.json. EST shots on each location's first appearance + key recurrences,
A2 closer angles on the longest / most pivotal scenes. Content kept from the existing Ep1 frame
script (amal_v2_frames.py), re-lit and re-framed for the new available-light Portra look.
-> stories/amal/ep1_frames_v2/."""
import os, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import frames
SH = "/Users/dusty/dev/brehon-law/stories/amal/sheets"
OUT = "/Users/dusty/dev/brehon-law/stories/amal/ep1_frames_v2"; os.makedirs(OUT, exist_ok=True)
def s(*cs): return [f"{SH}/{c}_turnaround.png" for c in cs]

# Approved new look — SUF copied VERBATIM from the brief.
SUF = (" Naturalistic available-light cinematography in the grounded realist style of the Indian crime dramas "
 "Kohrra, Delhi Crime and Paatal Lok, shot on KODAK PORTRA 400 colour film — fine organic grain, soft natural "
 "contrast, gentle natural warmth and true-to-life skin tones (subtle natural warmth; NOT a heavy yellow or "
 "amber 'piss-filter', no sepia). Shot on ANAMORPHIC lenses with shallow depth of field where it suits the "
 "shot — subjects sharp, backgrounds soft with gentle bokeh and the occasional subtle horizontal flare; a real "
 "sense of ATMOSPHERE (haze, dust, smoke, raking light) where it fits. Real locations, the environment and "
 "background VISIBLE with depth, never swallowed by black. A PROSPEROUS opium belt with real money — clean "
 "functional places, affluence at the big houses, NOT poverty, nothing derelict. CLEAN station-appropriate "
 "clothing — the wealthy in crisp pressed kurtas, ordinary people neat. Every shot a CANDID in-the-moment film "
 "still — caught in the dramatic action, never posing for or smiling into the camera. Grounded prestige-"
 "television realism, photoreal. Malwa, Madhya Pradesh, India. No text, no caption, no watermark.")

# Character notes — the wealthy clean and crisply pressed; Ratan in uniform unless noted plain.
R    = ("RATAN, a heavy weary 52-year-old Malwa CBN inspector in soft baggy clean khaki, a lined jowly face, "
        "grey moustache, bags under his eyes, a bare pale band on his ring finger where a ring used to be")
RP   = ("RATAN, the same heavy weary 52-year-old man at home in plain clothes, lined jowly face, grey moustache, "
        "the pale band on his bare ring finger")
DV   = "DEVA, a 24-year-old constable in crisp new khaki, an earnest open young face"
CH   = ("CHARAN, a very old Malwa bard, one eye gone milky-white, in a clean simple kurta and a faded turban, "
        "spare and unhurried")
KAN  = "KANTA, Ratan's tired sixtyish wife in a plain clean cotton sari, hair greying, quiet"
MI   = ("MISHRA, a smooth ageing CBN superintendent with a tired reasonable face, in a crisp pressed khaki "
        "uniform")
AM   = "AMMA, a warm plump ageing mother in a clean printed cotton sari"
MJ   = "MANJU, a quiet pretty eighteen-year-old girl in a simple clean salwar-kameez, eyes lowered"
SU   = ("SUGNA, a hard grief-worn fiftyish woman in a clean cotton sari, dry-eyed, a closed face")
# Bherulal redesigned to a PROSPEROUS bania trader-seth (NOT a white kurta — that is Rana).
BH   = ("BHERULAL, a prosperous paunchy balding bania trader-seth about 45, a cream kurta under a dark brown "
        "Nehru waistcoat (bandi), gold-rimmed glasses, a gold chain at his throat, a gold ring, calculating")

FR = [
 # ---- Scene 1 — THE SAKA (broken ground, 1305) ----
 # SAKA RULE (series-wide): the warrior's FACE IS NEVER SHOWN; render him as a DARK SILHOUETTE so it is not
 # obviously Ratan (the face is the held card; recognise it and the audience knows). Get the silhouette from a
 # TWILIGHT / DAWN SKY + battle-haze backlight — NOT a fire: a big fire behind a man reads as a funeral PYRE
 # (off-concept battlefield, and culturally loaded). Bareheaded to match sheets/saka_turnaround.png. The RING is
 # the only link; only the heavy BUILD reads in outline + a glint of blade/ring. Revealed only when earned.
 ("sc01", s("saka"),
  "The cold grey half-light just before dawn on a broken battlefield in rural Malwa, 1305 — a lone HEAVY-BUILT "
  "Rajput warrior in the near foreground, seen from BEHIND, a DARK SILHOUETTE against a pale, smoky dawn sky. "
  "NO fire, NO bonfire, NO flames anywhere — the backlight is only the pale dawn and drifting battle-haze; his "
  "form is dropped into shadow, identity unreadable, only the heavy shape of his shoulders and back. Bareheaded, "
  "his head a dark shape. He grips a lowered notched talwar, a thin edge of dawn light on the blade and on the "
  "worn gold signet ring; blood-dark on his sword-arm. Across the field beyond, shadowy attackers advance "
  "through the haze, thin columns of smoke rising far off on the horizon. The field, haze and advancing men read "
  "with depth in the low dawn light — only the warrior himself is black. He does not go down. Mythic, grounded, "
  "anonymous."),

 # ---- Scene 3 — DEVA ARRIVES (Amargarh CBN post) — FIRST appearance: EST ----
 ("sc03_est", [],
  "Wide establishing shot of a small dust-coloured CBN (Central Bureau of Narcotics) police post in a Malwa "
  "town at mid-morning: a low functional government building, paint flaking on the board outside, a CBN jeep "
  "up on bricks with one wheel missing in the yard, a boundary wall, a couple of motorcycles, the small town "
  "behind. Clean ordinary daylight, dust in the air, the whole compound visible with depth."),
 ("sc03", s("deva"),
  f"Medium-wide shot at the dusty CBN post yard, morning light, the flaking board and the bricked-up jeep "
  f"visible behind. {DV} steps down from a shared tempo with an iron trunk on his shoulder, his crisp new "
  f"uniform still creased from the shop, taking the place in — and it is not what he pictured. Dust, clear "
  f"morning light, the compound reading with depth."),

 # ---- Scene 4 — THE TEACHER (CBN post interior) ----
 ("sc04", s("ratan","deva"),
  f"Medium-wide interior of the plain functional CBN post, flat daylight through a barred window, the desk and "
  f"shelves of files visible. {R} sits heavy behind the wooden desk and slides a small fold of banknotes under "
  f"the blotter with two fingers without looking; a grieving farmer in a clean kurta turns his cap before him; "
  f"{DV} stands stiff and troubled to one side, having watched it. The whole room reads, institutional light."),
 ("sc04_a2", s("ratan","deva"),
  f"Closer two-shot across the desk: {R} caps a pen over a thin signed file, weary and incurious; {DV} a step "
  f"behind him, the open young face working over what he just saw. The lived-in post still visible soft behind "
  f"them, never black. Natural daylight."),

 # ---- Scene 5 — THE SIGNET (Sahukar's pawnshop) — FIRST appearance: EST ----
 ("sc05_est", [],
  "Wide establishing exterior of a narrow Malwa pawnshop on a small busy bazaar lane at midday: a barred shop "
  "window, a hanging board, brass vessels and oddments visible inside the open shutter, a dusty parked jeep at "
  "the kerb, a few people passing. Ordinary modest commerce, clean and functional, clear daylight, the lane "
  "visible with depth."),
 ("sc05", s("charan","deva"),
  f"Medium-wide shot at the front step of the cramped pawnshop, daylight, the barred window and the dusty "
  f"parked jeep visible. {CH} sits on the step shelling peanuts into his lap, his good eye turned to {DV}, who "
  f"waits by the jeep in his new uniform, listening. The bazaar lane reads soft behind them, natural light."),
 ("sc05_a2", s("charan","deva"),
  f"Closer two-shot on the pawnshop step: {CH}, the milky eye and the spare lined face, telling the boy "
  f"something old; {DV} half-turned to him, caught between listening and watching the shop doorway. The lane "
  f"soft behind, never black. Natural daylight."),

 # ---- Scene 6 — THE FILE (CBN post interior) ----
 ("sc06", s("ratan","deva"),
  f"Medium-wide interior of the CBN post, daylight, the desk and the day's pile of files visible. A dust-"
  f"covered sipahi (one-off, knees grey with road dust, plain khaki) lays a single thin one-page file on the "
  f"desk before {R}, who does not open it; {DV} beside him looks down at the closed cover. The room reads with "
  f"depth, flat natural light."),

 # ---- Scene 7 — SHE FELL (CBN post, evening) ----
 ("sc07", s("ratan","deva"),
  f"Medium-wide interior of the CBN post in the late-afternoon, warm raking light through the window across "
  f"the desk, the room still fully visible — warm, not amber-filtered, not black. {R} caps his pen over the "
  f"closed thin file and tucks the day's fold of banknotes into his breast pocket; {DV} stands silent and "
  f"troubled, holding something back. The lived-in post reads with depth."),

 # ---- Scene 8 — TWO MORE YEARS (Ratan's house, night) — FIRST appearance: EST ----
 ("sc08_est", [],
  "Wide establishing shot of Ratan's modest, neat house at night: a plain well-kept single-storey concrete "
  "house on an ordinary lane, one warm lit window, a clean swept yard, a parked motorcycle. Ordinary and "
  "cared-for, not poor; the house and lane clearly visible in the soft night light, a streetlamp down the "
  "lane, not a black void."),
 ("sc08", s("ratan","kanta"),
  f"Medium-wide interior of a small, kept, warmly-lit home at night, everything in its place, the modest room "
  f"visible with depth. {RP} sits before a steel plate of food, turning his hand over to look at the bare pale "
  f"band on his ring finger, not yet eating; {KAN} stands by, a hand on her back; an opened government "
  f"envelope on a side table. Soft warm tube-light, a grown quiet distance between them."),

 # ---- Scene 9 — THE PYRE (cremation ground, day) — FIRST appearance: EST ----
 ("sc09_est", [],
  "Wide establishing shot of a small Hindu cremation ground at the edge of a rural Malwa town by day: a few "
  "raised cremation platforms, a single pyre built and burning, a low wall, trees and open ground beyond, only "
  "a thin grey column of smoke rising. Solemn, ordinary, clear daylight, the whole ground and its depth "
  "visible, not swallowed by black."),
 ("sc09", s("ratan"),
  f"Wide shot at the cremation ground by day, the burning pyre and the open ground visible. {RP} stands at the "
  f"edge in plain clothes, hands behind his back, beside GOVIND (a one-off, an ageing man his own size in a "
  f"clean kurta) who watches the fire instead of the body; only a handful of old mourners and a son with a "
  f"freshly shaved head nearby; grey smoke going up. Soft grey daylight, the scene placed fully in its world."),

 # ---- Scene 10 — WHAT YOU WERE (cremation ground, later) ----
 ("sc10", s("ratan"),
  f"Wide shot at the cremation ground at dusk, the pyre down to glowing embers, the mourners gone, the open "
  f"ground and a soft dusk sky visible. {RP} stands as if he means to leave and does not; GOVIND (the same "
  f"ageing one-off in a clean kurta) crouches and feeds a last stick into the embers, talking low. Soft last "
  f"light, the embers warm, the whole ground readable with depth, not black."),
 ("sc10_a2", s("ratan"),
  f"Closer two-shot by the embers at dusk: GOVIND looking up from his crouch as he says the thing, {RP} "
  f"standing over him looking down at his own hands; the dying pyre glowing warm between them. The dusk ground "
  f"soft behind, never black. Natural low light."),

 # ---- Scene 11 — THE FIELD (Koteshwar field's edge, day) — FIRST appearance: EST ----
 ("sc11_est", [],
  "Wide establishing shot of the edge of a poppy-and-wheat field outside a prosperous Malwa village by day: "
  "tended green-and-tan fields under a hard bright sky, a knee-high mud field-bund (medh) running along the "
  "edge, a well across the field, a few figures working, the village roofs beyond. Dry hard earth, clear "
  "daylight, the open landscape visible with depth."),
 ("sc11", s("ratan"),
  f"Wide daytime shot at the field's edge, the tended fields and the distant well visible with depth. {R} "
  f"crouches low at the knee-high mud bund, hand flat on top of it, reading the trampled ground — sandal-"
  f"prints, a tractor's tread, a dragged smear; a wary young herder hangs back, a few uneasy villagers watch "
  f"from their work. The detective waking. Hard bright light, dust, the scene fully in its world."),
 ("sc11_a2", s("ratan"),
  f"Closer shot at the bund: {R} crouched, his weathered hand laid flat on the knee-high mud, his lined face "
  f"intent on the dry hard earth and the dragged smear, working a scene for the first time in years. The "
  f"sunlit field soft behind him with shallow depth, never black. Hard natural daylight."),

 # ---- Scene 12 — THE PEN, UNCAPPED (CBN post) ----
 ("sc12", s("ratan","deva"),
  f"Medium-wide interior of the CBN post by day, the desk and a munshi's register visible, the room reading "
  f"with depth. {R} pulls the thin file back off the closed pile and writes an order across a fresh "
  f"requisition form, signing it; a startled munshi (one-off, neat shirt) half-rises over his register; {DV} "
  f"against the wall watches the man amend his own signature, something coming back into his face. Flat "
  f"natural daylight."),

 # ---- Scene 13 — A CLOSED FILE (Mishra's room) ----
 ("sc13", s("mishra","ratan"),
  f"Medium-wide shot in a neat superintendent's office, a clean desk, a bright window behind, a framed "
  f"portrait on the wall, a glass of water — the tidy room fully visible. {MI} sits behind the clean desk "
  f"waving {R} toward a chair with easy warmth; {R} stands heavy and unmoved before him. Soft natural "
  f"daylight, the lived-in official room reading with depth."),
 ("sc13_a2", s("mishra","ratan"),
  f"Closer two-shot across the clean desk: {MI} leaning back with a fond reasonable smile that does the work a "
  f"threat would do, {R} standing stiff and refusing it, his jowly face shut. The bright tidy office soft "
  f"behind, never black. Natural daylight."),

 # ---- Scene 14 — THE GOD WHO DRINKS (Kaal Bhairav shrine) — distinctive location: EST ----
 ("sc14_est", [],
  "Wide establishing shot of a small fierce roadside Kaal Bhairav shrine in rural Malwa by day: a black-stone "
  "deity heaped with marigold garlands and silver foil, smeared with vermilion, a shallow silver dish set "
  "below, a stepped plinth, a tree and the lane behind. Intense and devotional but fully daylit and visible "
  "with depth, vivid marigold orange and silver, not black."),
 ("sc14", s("ratan","deva"),
  f"Medium-wide shot at the Kaal Bhairav shrine by day, the heaped marigolds and silver foil and the vermilion-"
  f"smeared black-stone face clearly visible. A priest (one-off, bare-chested with a sacred thread, dhoti) "
  f"pours country liquor into the shallow silver dish at the god's mouth; {R} stands looking long at the god; "
  f"{DV} a step back, astonished. Daylight, intense colour, the shrine fully readable with depth."),

 # ---- Scene 15 — STANDING, NOT AGE (Koteshwar village lane) ----
 ("sc15", s("ratan","deva"),
  f"Medium-wide shot in a dusty Malwa village lane by day, neat mud-and-concrete houses and closing doors "
  f"visible with depth, the lane wary and shutting around them. {R} and {DV} stand before an old woman (one-"
  f"off, a clean cotton sari, white hair) sweeping a doorstep, the one person old enough to talk; a man down "
  f"the lane turns away. Hard bright daylight, dust, the lane reading fully."),
 ("sc15_a2", s("ratan","deva"),
  f"Closer shot in the lane: {R} gone still — the particular stillness of a man into whom one piece has just "
  f"slid against another — as he takes in what the old woman has said; {DV} half-turned to him, the wrongness "
  f"of it on his young face. The shut lane soft behind, never black. Hard natural daylight."),

 # ---- Scene 16 — MANJU (Deva's house, night) — FIRST appearance: EST ----
 ("sc16_est", [],
  "Wide establishing shot of Deva's modest, neat family house at night: a plain well-kept single-storey "
  "concrete house on an ordinary village lane, one warm lit window glowing, a clean swept yard, a parked "
  "motorcycle. Ordinary and cared-for, not poor; the house and lane clearly visible in soft night light, not "
  "a black void."),
 ("sc16", s("amma","deva","manju"),
  f"Medium-wide interior of a small, warm, plain family room at night lit by one tube-light, the tidy room "
  f"visible with depth. {AM} presses a second roti onto a steel plate before the first is gone; {DV} sits at "
  f"the meal, the day heavy on him, looking at his sister; {MJ} sits to the side, eyes lowered, a girl being "
  f"discussed. Soft warm tube-light, affection in the room, the depth reading."),

 # ---- Scene 17 — CLEAN (CBN post) ----
 ("sc17", s("ratan"),
  f"Medium-wide interior of the CBN post by day, the desk and files and a register visible, the room reading "
  f"with depth. {R} stands holding a typed, stamped postmortem report, not putting it down, a hard knowing "
  f"settling on his lined face; an apologetic munshi (one-off, neat shirt) at the register behind. Flat "
  f"natural daylight, a realization."),

 # ---- Scene 18 — GO HOME, PAWAR SAHIB (Dr. Bhanwar's room) ----
 ("sc18", s("ratan"),
  f"Medium-wide shot in a district-hospital doctor's room by day, yellowed files and a steel cabinet and a "
  f"window visible, the institutional room reading with depth. DR. BHANWAR (a one-off, a tired clean-shaven "
  f"Rajput of Ratan's own age in a crisp pressed shirt) sits flat and immovable behind the desk; {R} stands "
  f"across from him, a cold mirror between them. Plain natural daylight, the room fully visible."),

 # ---- Scene 19 — OFF THE BOOKS (Koteshwar fields, dusk) ----
 ("sc19", s("ratan"),
  f"Wide shot at the edge of the poppy-and-wheat fields at dusk, the tended fields and a soft dusk sky "
  f"visible, a big prosperous lit house glowing far across the darkening land. {R}, on foot, off the books, "
  f"questions a wary field labourer (one-off, a plain kurta, coiling rope) who gives him little. Soft blue-grey "
  f"dusk, the open landscape and the distant lit house clearly readable with depth, not a black void."),

 # ---- Scene 20 — THE HOUSE (Bherulal's house, night) — FIRST appearance: EST ----
 ("sc20_est", [],
  "Wide establishing shot of a prosperous Malwa grower's house at night: a large solid two-storey concrete "
  "house with a high compound wall and gate, gold-coloured light at the doorway, a clean white SUV and a "
  "tractor parked inside, a water tank on the roof, green fields behind — clearly the richest house on the "
  "lane. Soft night light, the affluence plainly visible with depth, a generator-lit glow, not a black void."),
 ("sc20", s("ratan","sugna","bherulal"),
  f"Medium-wide shot in the lit, gold-trimmed doorway of the prosperous house at night, a dim mourning house "
  f"visible behind with depth — people sitting in the heavy quiet after a death, a dead girl's school things "
  f"(a bag, a comb, a folded dupatta) set on a shelf by the door. {SU} stands in the open doorway facing {R}, "
  f"who holds his cap in his hands; behind her {BH} fills the inner doorway, heavy and still. Warm interior "
  f"light spilling out, devastating and charged, the house readable, never black."),
 ("sc20_a2", s("ratan","sugna"),
  f"Closer two-shot across the threshold of the lit doorway: {SU}'s hard closed dry-eyed face and {R} with the "
  f"cap turning in his hands, twenty-five years between them, the moment the name lands. The warm-lit mourning "
  f"house soft behind her, never black. Natural warm light."),

 # ---- Scene 21 — THE BIKE THAT SLIPPED (Bherulal's side room) ----
 ("sc21", s("ratan","bherulal"),
  f"Medium-wide shot in a side room of the prosperous house at night, away from the mourners — a cool well-"
  f"appointed room, a ceiling fan, the wealth quietly visible with depth. {BH} sits across a low table from "
  f"{R}, calculating, laying out terms; a flat-faced henchman (one-off, a plain shirt) waits by the door. "
  f"Warm even interior light, cold quiet menace, the affluent room reading fully."),
 ("sc21_a2", s("ratan","bherulal"),
  f"Closer two-shot across the low table: {BH}, gold-rimmed glasses and the brown waistcoat, working out a "
  f"problem with no grief on his face, and {R} seated heavy and silent opposite, taking it. The cool room soft "
  f"behind them, never black. Warm interior light."),

 # ---- Scene 22 — THE PEN, ALL NIGHT (Ratan's house, night) ----
 ("sc22", s("ratan","kanta"),
  f"Medium-wide interior of the plain, kept home at night, one warm lamp, the modest room visible with depth — "
  f"warm low light, the surrounding room legible, never a lone lamp in a black void. {RP} sits alone at a table with two papers "
  f"before him — a typed report and a blank requisition form — a brass tumbler of grey poppy-water going cold "
  f"at his elbow, the pale band on his bare ring finger white in the light; {KAN} watches from a doorway in "
  f"her nightclothes. The edge of a choice, the room reading."),
 ("sc22_a2", s("ratan"),
  f"Closer shot at the table: {RP}'s weathered hands and the two papers — the clean report and the blank "
  f"requisition — the brass tumbler of cold poppy-water beside them, his bare ring finger pale in the warm "
  f"lamplight. The kept home soft behind, warm and readable, never black. Natural low light."),

 # ---- Scene 23 — HIS OWN NAME (CBN post, dawn) ----
 ("sc23", s("ratan","deva"),
  f"Medium-wide interior of the empty CBN post at grey dawn, the ceiling fan still, the desk and files visible "
  f"in the soft first light with depth — grey and legible, not a black void. {R} sits at the desk signing his "
  f"own full name to a hand-written requisition, grave and decided; {DV} stopped in the doorway with the grey "
  f"dawn behind him, seeing what it is, standing a little straighter. Soft cold first light, the post reading "
  f"fully."),
]

# Per-scene play order: EST first, then the main shot, then any A2 angles.
SHOTS = {
 1:  ["sc01"],
 3:  ["sc03_est", "sc03"],
 4:  ["sc04", "sc04_a2"],
 5:  ["sc05_est", "sc05", "sc05_a2"],
 6:  ["sc06"],
 7:  ["sc07"],
 8:  ["sc08_est", "sc08"],
 9:  ["sc09_est", "sc09"],
 10: ["sc10", "sc10_a2"],
 11: ["sc11_est", "sc11", "sc11_a2"],
 12: ["sc12"],
 13: ["sc13", "sc13_a2"],
 14: ["sc14_est", "sc14"],
 15: ["sc15", "sc15_a2"],
 16: ["sc16_est", "sc16"],
 17: ["sc17"],
 18: ["sc18"],
 19: ["sc19"],
 20: ["sc20_est", "sc20", "sc20_a2"],
 21: ["sc21", "sc21_a2"],
 22: ["sc22", "sc22_a2"],
 23: ["sc23"],
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
