import os, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import frames

SH = "/Users/dusty/dev/brehon-law/stories/sky-king/sheets"
OUT = "/Users/dusty/dev/brehon-law/stories/sky-king/frames"
TEST = "/Users/dusty/dev/brehon-law/stories/sky-king/test_birdy_cockpit_v1.png"

# AMAL's house look (FRAMELOOK.md): naturalistic available light, Portra, candid, NO teal-orange.
REAL = (" Naturalistic available-light cinematography in the grounded realist style of prestige "
        "character dramas (Manchester by the Sea; the Indian crime dramas Kohrra and Delhi Crime), "
        "shot on KODAK PORTRA 400 colour film: fine organic grain, soft natural contrast, "
        "true-to-life skin tones with real skin texture. NEUTRAL, TRUE COLOUR with natural white "
        "balance: NO global yellow, amber, gold or sepia colour cast over the image (NO 'piss "
        "filter'), NO teal-and-orange grade, NO cyan shadows; whites read white, shadows read "
        "neutral. Warm tones appear ONLY from a motivated practical source (a bulb, a lamp, the "
        "sun) against neutral or cool ambient. NEVER glossy over-clean CG reflections, NEVER "
        "a clean video-game or movie-poster look. A CANDID, off-centre, in-the-moment documentary "
        "film still: people caught mid-action, NOT centred, NOT symmetrical, NOT posing for the "
        "camera. Backgrounds visible with real depth, never black. Grounded, photoreal, lived-in, "
        "imperfect. No text, no caption, no watermark.")

def t(*cs): return [f"{SH}/{c}_turnaround.png" for c in cs]

LOC = {}
for key, desc in [
    ("ramp", "An ordinary working airport ramp at dusk in steady rain: a regional jet at the gate, sodium floodlights, wet concrete, bag carts, ground crew. Gritty, real, lived-in."),
    ("kitchen", "The small kitchen and living room of a modest working-class rented house at night, a warm bulb over the table, a TV glowing in the next room, worn furniture, lived-in and cluttered."),
    ("sim", "A small unfinished spare room at night: a folding table with three computer monitors edge to edge running a flight simulator, a control yoke on plywood, a worn office chair, taped cardboard boxes, a space heater. Cramped, real, ordinary."),
    ("sky", "Aerial wide: a small white single-engine turboprop alone in a vast sky going gold at dusk, far below dark forest and an inlet, a snow mountain catching pink light. Immense, lonely, real."),
]:
    p = f"{OUT}/loc_{key}.png"
    frames.location_master(desc + REAL, p, register="photoreal", pro=True)
    LOC[key] = p
    print("loc", key, flush=True)

SHOTS = [
  ("s1a_sky", [LOC["sky"]], False, "Wide aerial of the small turboprop alone in the gold dusk sky, the world far below, the pink-topped snow mountain distant. Real, lonely, natural light."),
  ("s1c_mountain", [TEST], False, "Birdy's view out the cockpit windscreen at golden hour: the snow mountain gone pink at the top, the glowing instrument panel below the glass. Candid, natural gold light."),
  ("s1d_birdy_shadow", t("birdy")+[TEST], True, "Close, slightly off-centre, on Birdy's face in the cockpit at golden hour as the sun drops and the gold slowly leaves him, calm and far away, his hand resting on the dash. Candid, real skin, film grain."),
  ("s2a_ramp", [LOC["ramp"]], False, "The rainy working airport ramp at dusk, a regional jet parked at the gate, sodium floodlights on wet concrete, bag carts, crew at work. Candid, real, no symmetry."),
  ("s2b_birdy_bags", t("birdy")+[LOC["ramp"]], True, "Birdy, in a rain-soaked orange hi-vis vest, hauls bags onto the belt loader at the jet's forward hold, head down, working, unseen. Caught mid-action, off-centre, rain falling."),
  ("s2c_dez", t("dez")+[LOC["ramp"]], True, "Dez, big in his orange hi-vis vest, leans on a bag cart in the rain mid-sentence, frustrated and loyal, gesturing. Candid, off-centre, real."),
  ("s2d_marshal", t("birdy")+[LOC["ramp"]], True, "Birdy on the wet ramp marshalling a parked regional jet, both lighted wands raised over his head, seen from a low three-quarter angle off to one side, caught mid-motion, the jet looming behind and to the side, NOT dead centre. Rain through the floodlights."),
  ("s2e_jet_climb", t("birdy")+[LOC["ramp"]], False, "From behind and to the side: small Birdy on the dark wet ramp, wands half-lowered, watching a jet climb away off the runway into low cloud and the last gold of the day. Candid, real."),
  ("s3a_supper", t("birdy","maya")+[LOC["kitchen"]], True, "Birdy and Maya at a small kitchen table eating supper in near silence, not looking at each other, a warm bulb over the table, the cool blue glow of a TV from the next room, the worn kitchen around them. Candid, wide, the distance between them."),
  ("s3c_maya_asks", t("maya")+[LOC["kitchen"]], True, "Close, off-centre, on Maya at the kitchen table under the warm bulb, gentle and frightened, asking him the real question, her eyes searching. Candid, real skin."),
  ("s3d_birdy_chair", t("birdy")+[LOC["kitchen"]], True, "Birdy sunk in a worn old armchair in the dark living room, the cool blue TV light on his still hollow face, a young man sitting like a much older one. Candid, off-centre, lived-in room visible."),
  ("s4a_birdy_alive", t("birdy")+[LOC["sim"]], True, "Birdy at the home flight simulator in the cramped spare room, hands on the yoke, shoulders down, a small real private smile, the monitors' glow on his face, the space heater warm beside him. Candid, off-centre, real, alive for once."),
  ("s4b_maya_door", t("maya")+[LOC["sim"]], True, "Maya in a robe in the dark hallway, watching through the few inches of a cracked door, a thin bar of monitor-light across her face, her eyes shining. Candid, off-centre, real skin."),
  ("s4c_frozen", t("birdy")+[LOC["sim"]], True, "Birdy's face closed and hollow again at the dark simulator, the monitors showing a small plane frozen mid-air, only the space heater's orange coil lighting the cramped room. Candid, off-centre, real."),
]

for name, refs, fl, prompt in SHOTS:
    frames.shot(prompt + REAL, f"{OUT}/{name}.png", refs=refs, register="photoreal", pro=True,
                face_lock=fl, avoid=("Richard Russell",) if fl else ())
    print("done", name, flush=True)
print("REAL FRAMES DONE", flush=True)
