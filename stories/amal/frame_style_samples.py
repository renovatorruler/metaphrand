import os, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import frames
SH = "/Users/dusty/dev/brehon-law/stories/amal/sheets"
OUT = "/Users/dusty/dev/brehon-law/stories/amal/frame_samples"; os.makedirs(OUT, exist_ok=True)
def s(*cs): return [f"{SH}/{c}_turnaround.png" for c in cs]

# film-stock emulation is a swappable knob; everything else (realism, prosperity, clean clothes) held constant
STOCK = sys.argv[1] if len(sys.argv) > 1 else "portra"
FILM = {
 "portra": "shot on KODAK PORTRA 400 colour film — fine organic grain, soft natural contrast, gentle natural "
           "warmth and the flattering true-to-life skin tones and muted-rich colour Portra is known for "
           "(subtle natural warmth; NOT a heavy yellow or amber 'piss-filter', no sepia, no teal-and-orange)",
 "400h":  "shot on FUJIFILM PRO 400H colour film — the soft, airy, pastel look beloved of film and wedding "
           "photographers: gentle low contrast, clean fresh minty-green and soft cyan tones, delicate pastel "
           "skin tones, a light, bright, airy, slightly dreamy quality, fine grain (cool and airy, never a "
           "warm amber wash)",
}[STOCK]
SUF = (f" Naturalistic available-light cinematography in the grounded realist style of the Indian crime dramas "
 f"Kohrra, Delhi Crime and Paatal Lok, {FILM}. Real locations: the environment and background are clearly "
 "VISIBLE with depth, never swallowed by black; medium and wide framing that places people IN their world, "
 "not isolated close-ups. A PROSPEROUS opium-growing belt with real money in it — ordinary clean functional "
 "places and outright affluence at the big houses (solid concrete/stone houses, SUVs, well-kept land); NOT a "
 "slum, NOT dire poverty, nothing derelict. CLOTHING is clean and matches each person's station — the wealthy "
 "in crisp well-pressed clothes; ordinary people neat and modest; nobody in filthy or threadbare rags. "
 "Every shot is a CANDID, in-the-moment film still — people caught in the dramatic action, absorbed in the "
 "scene, NEVER posing for or smiling into the camera, never mugging at the lens. "
 "Grounded prestige-television realism, photoreal. Malwa, Madhya Pradesh, India. No text, no caption, no watermark.")

RANA = "a big genial middle-aged Malwa political boss in a crisp white kurta, broad calm well-fed face"
BH = "a thickset prosperous Malwa trader-seth about 45, well-fed, in a clean well-pressed kurta with a gold ring"
SU = "an ageing woman in a plain clean sari, hard dry-eyed"

SAMP = [
 ("rana_portra", s("rana"),
  f"Wide daytime shot of a prosperous, well-kept Malwa farmhouse — a solid stone-and-concrete house, a swept "
  f"courtyard, a parked white SUV, tended green fields beyond. {RANA} reclines on a carved wooden swing-seat, "
  f"a big well-fed man of money and power; a line of neatly-dressed petitioners with folded hands waits; "
  f"standing apart, straight-backed with white stubble, is KISHAN, a farmer-elder. Visible rural wealth."),
 ("bherulal_interior", s("bherulal", "sugna"),
  f"Wide interior of a wealthy Malwa trader's house — a large cool room, a big colour TV on, a deep-freeze, a "
  f"new tractor's registration papers on the table. {BH} sits at a low table banding a tall stack of "
  f"banknotes, like a man counting grain. His flat-eyed enforcer waits. In an inner doorway {SU} pauses with "
  f"a steel tumbler, watching. The affluent room and its depth clearly visible."),
 ("bherulal_home_establishing", [],
  f"Establishing exterior shot of a wealthy Malwa trader's house: a large solid two-storey concrete house "
  f"with a high compound wall and gate, a white SUV and a tractor parked inside, a water tank and satellite "
  f"dish on the roof — clearly the richest house on an ordinary village lane, green fields behind it."),
]
sfx = "" if STOCK == "portra" else f"_{STOCK}"
for name, refs, p in SAMP:
    frames.shot(p + SUF, f"{OUT}/{name}{sfx}.png", refs=[r for r in refs if os.path.exists(r)],
                register="photoreal", pro=True, face_lock=False)
    print(f"rendered {name} [{STOCK}]", flush=True)
print("DONE", flush=True)
