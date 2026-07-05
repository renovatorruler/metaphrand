import os, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import characters

SH = "/Users/dusty/dev/brehon-law/stories/sky-king/sheets"
os.makedirs(SH, exist_ok=True)
TEST = "/Users/dusty/dev/brehon-law/stories/sky-king/test_birdy_cockpit_v1.png"

BIRDY = ("the man in the reference image: a gentle ordinary everyman of about 30, "
         "soft-featured, short mussed brown hair, warm tired hazel eyes, faint stubble, "
         "a shy quiet melancholy face, a plain gray hoodie. An ordinary, unremarkable, "
         "working-class man you would not look at twice.")
MAYA = ("MAYA, a woman in her late 20s, warm and tired, pretty in an unshowy working-class "
        "way: shoulder-length wavy brown hair, kind worried hazel eyes, fair skin, little or "
        "no makeup, a soft real face, a plain dark grocery-store polo. An ORIGINAL individual "
        "who does NOT resemble any real, famous, or recognizable actor.")
DEZ = ("DEZ, a man in his mid-30s, big and broad-shouldered, warm and loud, a working man: "
       "close-cropped dark hair and a short beard, an open friendly expressive face, brown "
       "eyes, an orange hi-vis ground-crew vest over a hoodie. An ORIGINAL individual who "
       "does NOT resemble any real, famous, or recognizable actor.")

# Birdy: lock the face to the approved test frame
characters.turnaround(TEST, BIRDY, f"{SH}/birdy_turnaround.png", pro=True)
print("birdy done", flush=True)

# Maya + Dez: fresh portrait, then turnaround
for name, desc in [("maya", MAYA), ("dez", DEZ)]:
    p = characters.portrait(desc, f"{SH}/{name}.png", pro=True)
    characters.turnaround(p, desc, f"{SH}/{name}_turnaround.png", pro=True)
    print(name, "done", flush=True)

characters.contact_sheet(
    [f"{SH}/birdy_turnaround.png", f"{SH}/maya_turnaround.png", f"{SH}/dez_turnaround.png"],
    ["BIRDY", "MAYA", "DEZ"],
    f"{SH}/cast_contact.png", cols=1,
)
print("CAST DONE", flush=True)
