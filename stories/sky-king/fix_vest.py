import os, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import frames

SH = "/Users/dusty/dev/brehon-law/stories/sky-king/sheets"
OUT = "/Users/dusty/dev/brehon-law/stories/sky-king/frames"

NEUTRAL = (" Naturalistic available-light cinematography in the grounded realist style of prestige "
           "character dramas (Manchester by the Sea; Kohrra; Delhi Crime), shot on KODAK PORTRA 400 "
           "colour film: fine organic grain, soft natural contrast, true-to-life skin tones. NEUTRAL, "
           "TRUE COLOUR, natural white balance: NO global yellow/amber/gold/sepia cast (NO 'piss "
           "filter'), NO teal-and-orange grade, NO cyan shadows; whites read white. Warm tones ONLY "
           "from a motivated practical source (sodium floodlights). A CANDID, off-centre, in-the-moment "
           "documentary film still, never posed, never symmetrical, never looking at camera. "
           "Backgrounds visible with depth. NEVER a glossy CG-render or movie-poster look. Grounded, "
           "photoreal, lived-in. No text, no caption, no watermark.")

VEST = " He is wearing a bright ORANGE HI-VIS SAFETY VEST (with reflective silver stripes) over his hoodie — ground-crew uniform."

SHOTS = [
    ("s2d_marshal", "Birdy, a ground-crew worker, stands on the wet ramp marshalling a parked regional jet, both lighted orange wands raised over his head, seen from a low three-quarter angle off to one side, caught mid-motion, the jet looming behind and to the side, not dead centre. Rain through the sodium floodlights." + VEST),
    ("s2e_jet_climb", "From behind and to the side: Birdy, a ground-crew worker, small on the dark wet ramp, wands half-lowered, watching a jet climb away off the runway into low cloud and the last gold of the day." + VEST),
]

for name, prompt in SHOTS:
    frames.shot(prompt + NEUTRAL, f"{OUT}/{name}.png",
                refs=[f"{SH}/birdy_turnaround.png", f"{OUT}/loc_ramp.png"],
                register="photoreal", pro=True, face_lock=True, avoid=("Richard Russell",))
    print("done", name, flush=True)
print("VEST FIX DONE", flush=True)
