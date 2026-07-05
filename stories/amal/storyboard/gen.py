"""अमल — train scene storyboard (photoreal stills), 1990s Indian Railways.

Face withheld throughout (woman from behind/side, never her face). The baby is only ever a wrapped
green bundle — nothing sensitive is generated, so each still is innocuous alone; the dread is only in
the sequence. Consistency rides a compartment location master + cascade conditioning on the anchor
frame (the green cloth + her silhouette), not a face turnaround.
"""
import os, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import frames

OUT = "/Users/dusty/dev/brehon-law/stories/amal/storyboard"
os.makedirs(OUT, exist_ok=True)
P = "photoreal"

NINETIES = (" Set in 1990s India: Indian Railways blue ICF coaches, blue-painted metal interior walls, "
            "barred windows, ceiling fans, simple wooden and blue-rexine bench seats; 1990s clothing "
            "and luggage (steel trunks, cloth bundles, holdalls); NO smartphones, no modern "
            "electronics; a diesel or electric train, NOT a steam train. Gritty documentary realism, "
            "natural light, 35mm look.")

# 0 — compartment location master (geographic/lighting anchor for every interior shot)
loc = frames.location_master(
    "The interior of a packed 1990s Indian Railways general (unreserved) compartment: blue-painted "
    "metal walls, barred windows, ceiling fans, wooden and blue-rexine bench seats, overhead racks of "
    "cloth bundles and steel trunks, warm dusty daylight through the bars." + NINETIES,
    f"{OUT}/loc_compartment.png", register=P, pro=True)

# 1 — platform (her from behind with the green bundle; 1990s blue coaches, diesel, NOT steam)
f1 = frames.shot(
    "A 1990s Indian railway platform in hard midday sun, blue Indian Railways coaches standing along "
    "it, a diesel locomotive down the line, yellow station signboards in Hindi and English, crowded "
    "with ordinary travellers, families on bedrolls, a tea stall, coolies in red. In the middle "
    "distance, seen FROM BEHIND, a woman in a plain faded sari holds a baby wrapped to the crown in a "
    "faded green cloth against her shoulder, one hand flat on the child's back. Her face is turned "
    "away and never visible." + NINETIES,
    f"{OUT}/f1_platform.png", refs=None, register=P, pro=True)

# 2 — settled by the window (THE ANCHOR for the woman + cloth; rides the location master)
f2 = frames.shot(
    "Inside the blue compartment, a woman in a plain faded sari sits by a barred window, seen FROM "
    "BEHIND and slightly to the side so her FACE IS NEVER VISIBLE, a baby wrapped to the crown in a "
    "faded green cloth held against her shoulder, one hand resting flat and still on the child's back. "
    "Other passengers around her on the bench seats. Warm dusty light from the barred window." + NINETIES,
    f"{OUT}/f2_settled.png", refs=[loc], register=P, pro=True)

# 3 — the green cloth + the first fly (close; baby fully hidden, the fly sharp and clear)
f3 = frames.shot(
    "Close on the bundle: a baby wrapped COMPLETELY to the crown in a faded green cloth so only the "
    "cloth shows and the baby's face is fully hidden, held against a woman's shoulder, her hand flat "
    "and still on it, seen from the side and behind with her FACE OUT OF FRAME. A single large "
    "housefly sits in sharp focus on the green cloth. Soft worn daylight, shallow depth of field, "
    "quietly ominous." + NINETIES,
    f"{OUT}/f3_cloth_fly.png", refs=[f2, loc], register=P, pro=True)

# 4 — the carriage noticing (push the dread harder)
f4 = frames.shot(
    "Inside the blue compartment, ordinary passengers on the bench seats — a middle-aged woman pulling "
    "her own small child closer to her, a tired man frowning hard — their faces tightening with "
    "unmistakable unease and fear as they look toward something across the aisle and then draw back "
    "from it. In the soft-focus foreground, from behind, the shoulder and green bundle of the seated "
    "woman." + NINETIES,
    f"{OUT}/f4_noticing.png", refs=[f2, loc], register=P, pro=True)

# 5 — police boarding at the nowhere station
f5 = frames.shot(
    "At a small 1990s Indian railway platform, two policemen in worn khaki uniforms climbing up into "
    "the doorway of a crowded blue Indian Railways carriage, urgent; passengers' faces at the barred "
    "windows. Hard daylight." + NINETIES,
    f"{OUT}/f5_police.png", refs=None, register=P, pro=True)

# 6 — the hand reaching the bundle (cascade on the cloth frame)
f6 = frames.shot(
    "A policeman's hand and uniformed khaki arm reaching toward a baby wrapped in a faded green cloth "
    "held in a seated woman's lap; the woman's own hand pressing flat on the bundle, seen FROM BEHIND "
    "so her face is not visible. Crowded compartment behind. Tense, restrained." + NINETIES,
    f"{OUT}/f6_hand.png", refs=[f3, loc], register=P, pro=True)

# 7 — the empty seat, the aftermath (clear vacancy, the cloth gone)
f7 = frames.shot(
    "A conspicuously EMPTY worn seat by a barred window in a 1990s blue Indian Railways compartment, "
    "the seat clearly vacant and the green cloth gone, the space where someone had been sitting now "
    "empty, a few nearby passengers looking away from it. Dusty afternoon light through the barred "
    "window, fields beyond. A clear sense of someone having just been taken away." + NINETIES,
    f"{OUT}/f7_empty.png", refs=[loc], register=P, pro=True)

print("DONE", flush=True)
