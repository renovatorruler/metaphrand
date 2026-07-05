import os, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import frames

SH = "/Users/dusty/dev/brehon-law/stories/sky-king/sheets"
OUT = "/Users/dusty/dev/brehon-law/stories/sky-king/frames"

# Neutral Portra realism: NO piss filter (no global yellow), NO teal-orange.
NEUTRAL = (" Naturalistic available-light cinematography in the grounded realist style of prestige "
           "character dramas (Manchester by the Sea; the Indian crime dramas Kohrra and Delhi Crime), "
           "shot on KODAK PORTRA 400 colour film: fine organic grain, soft natural contrast, "
           "true-to-life skin tones with real skin texture. NEUTRAL, TRUE COLOUR with natural white "
           "balance: NO global yellow, amber, gold or sepia colour cast over the image (NO 'piss "
           "filter'), and NO teal-and-orange grade. Whites read white, shadows read neutral. Warm "
           "tones appear ONLY from a motivated practical source (a bulb, a lamp) against neutral or "
           "cool ambient. A CANDID, off-centre, in-the-moment documentary film still — never posed, "
           "never symmetrical, never looking at the camera. Backgrounds visible with real depth. "
           "NEVER a glossy CG-render or movie-poster look. Grounded, photoreal, lived-in, imperfect. "
           "No text, no caption, no watermark.")

prompt = ("Birdy and Maya at a small kitchen table eating supper in near silence, not looking at "
          "each other, a bare warm bulb over the table, the cool blue glow of a TV from the next "
          "room, the worn working-class kitchen around them. Candid, wide, the distance between them.")

frames.shot(prompt + NEUTRAL, f"{OUT}/TEST_s3a_neutral.png",
            refs=[f"{SH}/birdy_turnaround.png", f"{SH}/maya_turnaround.png", f"{OUT}/loc_kitchen.png"],
            register="photoreal", pro=True, face_lock=True, avoid=("Richard Russell",))
print("done -> TEST_s3a_neutral.png", flush=True)
