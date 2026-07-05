import os, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import backends

# SKY KING look = "the Drive look": 35mm anamorphic, Kodak Vision3, gold vs teal,
# halation, organic grain, shallow focus. Test frame: Birdy in the cockpit, gold hour.
PROMPT = (
    "A photorealistic cinematic film still, shot on 35mm ANAMORPHIC motion-picture film "
    "(Kodak Vision3 250D), in the visual style of the film DRIVE (cinematographer Newton "
    "Thomas Sigel): warm golden-amber highlights against cool teal shadows, soft HALATION "
    "blooming around the bright sunlight, fine organic 35mm film grain, shallow depth of "
    "field, gentle anamorphic lens character and oval bokeh. Golden hour, the last low sun.\n\n"
    "SUBJECT: Inside the cramped cockpit of a small single-engine turboprop, airborne at "
    "dusk. BIRDY, a gentle ordinary man of about 30, soft-featured and a little heavyset, "
    "short mussed brown hair, warm tired hazel eyes, a shy quiet face, faint stubble, in a "
    "plain hoodie, sits at the controls, one hand light on the yoke, looking out the "
    "windscreen at the gold light. The low sun comes straight through the glass and lays "
    "warm gold across the side of his face. He is calm, melancholy, alone. CANDID, "
    "in-the-moment, never posed, NOT looking at camera. Medium shot: his face, the cockpit, "
    "and the gold sky beyond the windscreen all visible, backgrounds present with depth, "
    "never crushed to black.\n\n"
    "CRITICAL, COMMERCIAL LIKENESS: this must be an ORIGINAL individual. He must NOT "
    "resemble Richard Russell, nor any real, famous, or recognizable actor or public "
    "figure. An original, clearable, ordinary everyman face is required. NO text, NO "
    "captions, NO subtitles, NO watermarks anywhere in the image."
)

out = "/Users/dusty/dev/brehon-law/stories/sky-king/test_birdy_cockpit_v1.png"
os.makedirs(os.path.dirname(out), exist_ok=True)
data = backends.image(PROMPT, refs=None, pro=True, aspect="16:9")
open(out, "wb").write(data)
print("saved", out, len(data), "bytes")
