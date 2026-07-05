import os, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import frames

SH = "/Users/dusty/dev/brehon-law/stories/sky-king/sheets"
OUT = "/Users/dusty/dev/brehon-law/stories/sky-king/frames"
os.makedirs(OUT, exist_ok=True)
TEST = "/Users/dusty/dev/brehon-law/stories/sky-king/test_birdy_cockpit_v1.png"

DRIVE = (" Shot on 35mm ANAMORPHIC motion-picture film (Kodak Vision3), the visual style of "
  "the film DRIVE: warm golden-amber highlights against cool teal shadows, soft HALATION "
  "around bright lights, fine organic film grain, shallow depth of field, gentle anamorphic "
  "lens character. Backgrounds present with depth, never crushed to black. CANDID, "
  "in-the-moment, never posed, no one looking at camera. NO text, NO captions, NO watermarks.")

def t(*cs): return [f"{SH}/{c}_turnaround.png" for c in cs]

LOC = {}
def loc(key, desc):
    p = f"{OUT}/loc_{key}.png"
    if not os.path.exists(p):
        frames.location_master(desc + DRIVE, p, register="photoreal", pro=True)
        print("loc", key, flush=True)
    LOC[key] = p

loc("ramp", "An airport ramp at dusk in steady rain: a regional jet at the gate with its beacon turning, floodlights, wet concrete throwing light back up, bag carts in a row, orange ground crew. Gritty, working, gray-blue.")
loc("kitchen", "The small kitchen and living room of a modest rented house at night, lit warm and low, a TV glowing blue in the next room, worn furniture, lived-in.")
loc("sim", "A small unfinished spare room at night: a folding table with three computer monitors edge to edge showing a flight-simulator cockpit, a control yoke bolted to plywood, a worn office chair, taped cardboard boxes, a space heater glowing orange.")
loc("sky", "Aerial wide: a small white single-engine turboprop alone and tiny in a vast sky going gold at dusk, far below dark forest and an inlet gone copper, a snow mountain catching pink light. Dreamy, immense, lonely.")

# (out_name, refs, face_lock, prompt)
SHOTS = [
  ("s1a_sky", [LOC["sky"]], False, "Wide aerial: the small turboprop alone in the enormous gold dusk sky, the world soft and far below, the pink-topped snow mountain in the distance."),
  ("s1c_mountain", [TEST], False, "Birdy's point of view out the cockpit windscreen: the snow mountain gone pink at the very top in the last of the sun, the instrument panel glowing in the foreground."),
  ("s1d_birdy_shadow", t("birdy")+[TEST], True, "Close on Birdy's face in the cockpit as the sun drops to the horizon and the gold leaves him, his face sliding slowly into shadow, calm and far away, his hand flat on the dash."),
  ("s2a_ramp", [LOC["ramp"]], False, "Wide: the rainy floodlit airport ramp at dusk, a regional jet parked at the gate, wet concrete, bag carts, the working world."),
  ("s2b_birdy_bags", t("birdy")+[LOC["ramp"]], True, "Birdy in a rain-darkened orange hi-vis vest works the belt loader at the forward hold of the jet, hoisting bags, quietly good at it, unseen, rain coming down."),
  ("s2c_dez", t("dez")+[LOC["ramp"]], True, "Dez, big in his orange hi-vis vest, leans on a bag cart in the rain and talks, frustrated and loyal, one hand gesturing at the jet."),
  ("s2d_marshal", t("birdy")+[LOC["ramp"]], True, "Birdy stands on the wet ramp facing the jet, both lighted orange marshalling wands raised over his head, engines blowing rain sideways, the huge jet close in front of him."),
  ("s2e_jet_climb", t("birdy")+[LOC["ramp"]], False, "From behind: small Birdy on the dark wet ramp, wands still half-raised, watching the jet climb away off the runway into the low cloud and the last gold of the day."),
  ("s3a_supper", t("birdy","maya")+[LOC["kitchen"]], True, "Birdy and Maya sit at a small kitchen table eating supper in near silence, blue TV light from the next room, the space between them."),
  ("s3c_maya_asks", t("maya")+[LOC["kitchen"]], True, "Close on Maya at the kitchen table, gentle and frightened, asking him the real question, her eyes searching his face."),
  ("s3d_birdy_chair", t("birdy")+[LOC["kitchen"]], True, "Birdy sunk in a worn old armchair in the dark living room, blue TV light on his still face, a young man sitting like a much older one, hollow."),
  ("s4a_birdy_alive", t("birdy")+[LOC["sim"]], True, "Birdy at the flight simulator, hands easy on the yoke, shoulders down, his face open with a real private smile, the monitors throwing gold sky-light on him, alive for the first time."),
  ("s4b_maya_door", t("maya")+[LOC["sim"]], True, "Maya in a robe in the dark hallway, watching through the few inches of a cracked door, a bar of monitor-light across her face, her eyes shining, not daring to move."),
  ("s4c_frozen", t("birdy")+[LOC["sim"]], True, "Birdy's face closed and hollow again at the dark simulator, the monitors showing a small plane frozen mid-air going nowhere, the room lit only by a space heater's orange coil."),
]

for name, refs, fl, prompt in SHOTS:
    out = f"{OUT}/{name}.png"
    if os.path.exists(out):
        print("skip", name, flush=True); continue
    frames.shot(prompt + DRIVE, out, refs=refs, register="photoreal", pro=True,
                face_lock=fl, avoid=("Richard Russell",) if fl else ())
    print("done", name, flush=True)
print("FRAMES DONE", flush=True)
