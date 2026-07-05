import os, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import frames

SH = "/Users/dusty/dev/brehon-law/stories/sky-king/sheets"
OUT = "/Users/dusty/dev/brehon-law/stories/sky-king/frames"

# The realism look, built on AMAL's FRAMELOOK (the proven one) — warm dusk MOOD via
# motivated natural light, NOT a teal-orange grade.
REAL = (" Naturalistic available-light cinematography in the grounded realist style of prestige "
        "character dramas (the register of Manchester by the Sea, and the Indian crime dramas "
        "Kohrra and Delhi Crime), shot on KODAK PORTRA 400 colour film: fine organic grain, soft "
        "natural contrast, gentle natural warmth, true-to-life skin tones with real skin texture. "
        "Light is MOTIVATED and natural only (a bare warm kitchen bulb, the cool blue glow of a TV "
        "in the next room). NEVER a teal-and-orange grade, NEVER a heavy amber filter, NEVER glossy "
        "halation, NEVER a clean video-game or CG-render look. Backgrounds visible with real depth, "
        "never swallowed by black. A CANDID, in-the-moment documentary film still: the people are "
        "absorbed in the moment, never posed, never looking at the camera. Grounded, photoreal, "
        "lived-in and imperfect. No text, no caption, no watermark.")

prompt = ("Birdy and Maya sit at a small kitchen table eating supper in near silence, not looking "
          "at each other, the worn lived-in kitchen around them, the cool blue light of a TV "
          "spilling in from the next room, the quiet distance between them. Plain working-class home.")

frames.shot(prompt + REAL, f"{OUT}/TEST_s3a_real.png",
            refs=[f"{SH}/birdy_turnaround.png", f"{SH}/maya_turnaround.png", f"{OUT}/loc_kitchen.png"],
            register="photoreal", pro=True, face_lock=True, avoid=("Richard Russell",))
print("done -> TEST_s3a_real.png", flush=True)
