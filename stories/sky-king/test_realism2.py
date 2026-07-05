import os, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import frames

SH = "/Users/dusty/dev/brehon-law/stories/sky-king/sheets"
OUT = "/Users/dusty/dev/brehon-law/stories/sky-king/frames"

REAL = (" Naturalistic available-light cinematography in the grounded realist style of prestige "
        "character dramas (Manchester by the Sea; the Indian crime dramas Kohrra and Delhi Crime), "
        "shot on KODAK PORTRA 400 colour film: fine organic grain, soft natural contrast, "
        "true-to-life skin tones. Light is MOTIVATED and natural only — sodium ramp floodlights, "
        "the jet's beacons. NEVER a teal-and-orange grade, NEVER cyan shadows, NEVER glossy "
        "over-clean CG reflections, NEVER a clean video-game or movie-poster look. A CANDID, "
        "off-centre, in-the-moment documentary film still — the man is caught mid-action, NOT "
        "centred, NOT symmetrical, NOT posing for the camera. Backgrounds visible with real depth. "
        "Grounded, photoreal, lived-in, imperfect, slightly messy. No text, no caption, no watermark.")

prompt = ("On a rain-soaked airport ramp at dusk, BIRDY, a ground crew worker in a soaked orange "
          "hi-vis vest, stands marshalling a parked regional jet, both lighted wands raised over "
          "his head, seen from a LOW THREE-QUARTER angle off to one side, caught mid-motion. The "
          "jet looms behind and to the side, not dead centre. Rain falling through the floodlights, "
          "wet concrete, the ordinary working ramp around him.")

frames.shot(prompt + REAL, f"{OUT}/TEST_s2d_real.png",
            refs=[f"{SH}/birdy_turnaround.png", f"{OUT}/loc_ramp.png"],
            register="photoreal", pro=True, face_lock=True, avoid=("Richard Russell",))
print("done -> TEST_s2d_real.png", flush=True)
