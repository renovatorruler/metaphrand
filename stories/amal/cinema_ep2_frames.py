import os, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import frames
SH = "/Users/dusty/dev/brehon-law/stories/amal/sheets"
OUT = "/Users/dusty/dev/brehon-law/stories/amal/ep2_frames"; os.makedirs(OUT, exist_ok=True)
def s(*cs): return [f"{SH}/{c}_turnaround.png" for c in cs]
SUF = (" Old-master oil-painting chiaroscuro in the manner of Caravaggio and Rembrandt: extreme tenebrism, "
 "a single warm low light source, deep impenetrable black shadow, figures and faces modeled out of the "
 "darkness, painterly. Photoreal but lit like an old-master painting, desaturated warm palette, prestige "
 "cinematic film still, fine film grain. Malwa, Madhya Pradesh, India. No text, no caption, no watermark.")

# quick character notes folded into prompts
R="a heavy weary 52-year-old Malwa inspector in worn khaki, lined jowly face, grey moustache, bags under his eyes"
RP="a heavy weary 52-year-old man in plain clothes, lined jowly face, grey moustache"  # suspended
RANA="a big genial Malwa political boss in a white kurta, broad calm face"
BH="a thickset Malwa trader-seth, about 45"
MI="a smooth ageing CBN bureaucrat with a tired reasonable face"
DV="a 24-year-old constable in khaki, earnest young face"
SU="an ageing woman in a plain sari, hard dry-eyed grief"

FR = [
 (1,  s("ratan","bherulal"), f"A morgue outbuilding at dawn, a tin door. Bherulal's flat-eyed man lays a banded brick of cash on an open register held by a frightened compounder; in the deep shadow of the doorway {R} stands watching, unseen, an oil lamp the only light."),
 (3,  s("rana"),  f"A farmhouse verandah durbar. {RANA} reclines on a carved swing-seat; before him stands KISHAN, an old straight-backed farmer with white stubble, not bowing. A single brass lamp, petitioners as shadows."),
 (4,  s("ratan","sugna"), f"In a dark morgue doorway, {R} faces {SU} across a low threshold, a cold confrontation, one lamp between them, a wrapped body sensed in the black behind."),
 (5,  s("amma","manju","deva"), f"A small lamp-lit room. AMMA, a warm ageing mother, holds up a phone photo, glowing; MANJU, her teenage daughter, sits with eyes down; {DV} stands in the doorway, the day heavy on him."),
 (6,  s("ratan","deva"), f"A CBN office. {R} at a wooden desk pushes a fold of banknotes back across it with one finger; a stunned farmer, and {DV} watching from a side table. One overhead bulb."),
 (7,  s("mishra","ratan"), f"{MI} and {R} sit across a desk in a bureaucrat's room, a window behind, a tense reasonable argument, warm low light."),
 (8,  s("bherulal","sugna"), f"{BH} bands bricks of cash at a low table like a man counting grain; in a dark inner doorway {SU} stands with a steel tumbler, watching. One lamp."),
 (9,  s("bherulal","ratan"), f"Outside a CBN post by a white SUV, {BH}, all false warmth, drops an arm around the shoulder of {R}; a flat-eyed enforcer a step behind. Hard daylight, deep shadow."),
 (10, s("ratan","deva"), f"A hospital office counter. {R} and {DV} stand before a sorry, immovable clerk who will not give a vehicle. Dim, institutional."),
 (11, s("ratan","sugna"), f"A riverside cremation ground: an unlit pyre built and waiting, no body. A ring of mourning women, {SU} dry-eyed at the centre; {R} stops on the path, the crowd against him. Grey dawn, dust."),
 (12, s("ratan","deva"), f"A night transport stand, one bare bulb over parked tempos. {RP} talks to a wary tempo driver; {DV} watches from the dark. Deep night."),
 (13, s("ratan","deva"), f"A high green gate and a paved drive, a lawn kept green amid dry cracked land; {R} and {DV} arrive in a dusty borrowed jeep, armed men loitering. Twilight."),
 (14, s("rana","ratan"), f"A wide verandah; {RANA} rises from a swing-seat with open arms; {R} stands stiff and cold, refusing the welcome. Warm lamps, deep shadow."),
 (15, s("rana","ratan"), f"{RANA} holds out a cupped palm of opium-water (kasumba) toward {R}, the old courtesy that cannot be refused; {R} hesitates. One warm light."),
 (16, s("rana","ratan"), f"{RANA} leans in close, making a soft offer; {R} watches him, guarded; a young constable at the edge in shadow. Intimate, warm, ominous."),
 (17, s("ratan","rana"), f"{R} stands to leave, having said no; for one instant {RANA}'s warm mask is gone and something cold looks out. Lamp light, black around them."),
 (18, s("deva","ratan"), f"A jeep on a dry field road, a green farmhouse gate shrinking behind. {DV} drives; {R} stares out at the parched fields. Hard low sun."),
 (19, s("ratan","deva"), f"A tempo van runs an empty pre-dawn highway, a wrapped body in the back; ahead a tractor-trolley slewed across a culvert blocks the road, a Bolero's headlights closing behind. {R} and {DV} inside, tense. Blue-black night."),
 (20, s("mishra"), f"{MI} on a desk telephone, the smooth confidence flickering as the call goes wrong. A dim office, one lamp."),
 (21, s("ratan"), f"A harder city hospital. A rumpled tired forensic doctor in his fifties (KHARE) with a clipboard meets {R}, who carries one end of a wrapped body; no one helps. Cold corridor light."),
 (22, s("ratan","deva"), f"A cold morgue, a steel table, a drain in the floor. A doctor begins an autopsy on a covered young body; {R} stands grimly at the head, {DV} grey-faced against the wall. One hard overhead light, deep shadow."),
 (23, s("ratan"), f"A doctor (KHARE, fifties, rumpled) dries his hands and speaks flatly to {R} in a cold morgue, delivering a grave finding. Single light, steel and shadow."),
 (24, s("ratan","deva"), f"Outside a hospital, too-bright day after the dark. {DV} sits wrung-out on a step; {R} comes out holding a folded report; a doctor lights a cigarette. Harsh light, long shadows."),
 (25, s("ratan","deva"), f"A small village post office counter. {R} seals an envelope addressed to himself and posts it; a registered slip on the counter; {DV} beside him, not understanding. Dusty afternoon light."),
 (26, s("deva","manju"), f"A lamp-lit room at night. {DV} sits across from his teenage sister MANJU, asking her something gently; she has no answer, eyes down. Warm single light."),
 (27, s("amma","deva"), f"AMMA, an anxious ageing mother, tells {DV} a hard thing in a small night room, a worry under her brightness. One lamp."),
 (28, s("ratan"), f"Behind a country-liquor shop at dusk, {R} crouches by GANGA, a gaunt shaking doda addict folded against a wall, wrecked and hollow-eyed. Last grey light, deep shadow."),
 (29, s("ratan","deva"), f"Late night in a CBN office. {R} at his desk with a copied report, working a case out half to {DV} and half to himself. One desk lamp, black around."),
 (30, s("ratan"), f"Alone at a desk deep in the night, {R} stares at a page on which one name is written and the rest is empty; doubt on his lined face. A single failing lamp."),
 (31, s("deva"), f"A CBN office by day. A sly munshi slides a file with a fold of cash to {DV}, who signs but leaves the money; the daily machinery. Flat office light."),
 (32, s("ratan"), f"Stone steps by a river at evening. An old friend (GOVIND, an ageing man) sits beside {R} at the water's edge, a hand on his shoulder. Soft dusk over the river, warm shadow."),
 (33, s("ratan","deva"), f"A night lane. {RP} and {DV} walk together; at a fork they part, {R} not looking at the boy. Sparse lamplight, deep night."),
 (34, s("rana","bherulal"), f"{RANA} on a swing-seat feeds a caged songbird while {BH}, anxious for once, pleads before him. Warm verandah lamp, the cage and the black beyond."),
 (35, s("mishra","ratan"), f"{MI} gently sets a suspension order on a desk; {RP} unclips a police badge and lays it down beside a revolver. Tired, sorrowful, low light."),
 (36, s("ratan","kanta"), f"A bare dark kitchen at night. {RP} sits over a steel plate; his ageing wife KANTA in a plain sari sits down across from him for the first time in years and pushes the plate closer; pension papers on the table. One oil lamp, a thaw."),
 (37, s("ratan"), f"A senior officer's anteroom. {RP}, an old man in plain clothes with a folder on his knee, sits on a bench while a PA turns him away; a closed office door beyond. Cold institutional light."),
 (38, s("ratan","deva"), f"Across a dark field, a big lit haveli glows at the far end. {RP} and {DV}, out of uniform, stand in the black foreground watching it. Night, the only light the distant windows."),
 (39, s("ratan"), f"A lone old man (plain clothes, a folder under his arm) walks a dark empty road through the sleeping poppy belt toward a single lit house far ahead. Night, one distant light, vast black."),
]

todo = [(n, refs, p) for (n, refs, p) in FR if not os.path.exists(f"{OUT}/sc{n:02d}.png")]
print(f"{len(FR)} frames, {len(todo)} to render", flush=True)
for n, refs, p in todo:
    out = f"{OUT}/sc{n:02d}.png"
    try:
        frames.shot(p + SUF, out, refs=[r for r in refs if os.path.exists(r)], register="photoreal", pro=True, face_lock=False)
        print(f"  sc{n:02d} done", flush=True)
    except Exception as e:
        print(f"  sc{n:02d} FAIL {str(e)[:120]}", flush=True)
print("FRAMES DONE", flush=True)
