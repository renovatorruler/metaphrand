"""THE HEIR — storyboard frames via Gemini image generation.

Generates film-storyboard illustrations for the screenplay, to be cut against the
table-read audio. Style and recurring-character descriptions are repeated verbatim
in every prompt so frames stay consistent. Key is read from ~/.gemini_api_key.

    python -m examples.heir_storyboard            # the approval batch (first 8)
    python -m examples.heir_storyboard 3 5        # only frames 3..5
"""

from __future__ import annotations

import base64
import json
import os
import sys
import time
import urllib.request

MODEL = os.environ.get("GEMINI_IMAGE_MODEL", "gemini-3-pro-image")  # production tier
OUTDIR = "stories/the-heir/storyboard"

STYLE = (
    "Film storyboard illustration: loose confident graphite pencil and charcoal on "
    "off-white paper, monochrome with rough hatching and smudged tone, strong cinematic "
    "lighting, widescreen framing drawn inside the image with a thin border. "
    "Hand-drawn production-storyboard look, expressive not photoreal. "
    "ABSOLUTELY NO TEXT of any kind anywhere on the page: no words, no letters, no "
    "speech bubbles, no dialogue balloons, no character names, no labels, no "
    "aspect-ratio markings, no panel numbers, no annotations, no watermark. "
    "The image is purely pictorial. "
    "COMPOSED LIKE A COMPETENT FEATURE FILM: one clear subject, rule-of-thirds "
    "placement, correct eyelines between characters, consistent screen direction, "
    "camera at eye level unless the shot says otherwise, real depth (foreground, "
    "midground, background), faces visible unless the shot deliberately withholds them."
)

# Location sheets — fixed geography, camera side, and props canon per set.
# Every prompt for a location includes its sheet verbatim; coverage shots are
# generated FROM the location's master frame (reference-conditioned) so the room
# and its equipment stay identical between angles.
SHEETS = {
    "aslan_room": (
        "LOCATION CANON — Aslan's sickroom in the presidential palace, night: a "
        "dark-panelled state bedroom converted to a sickroom. The bed sits centre-left, "
        "headboard against the left wall. On the FAR side of the bed near the headboard "
        "stands a 1990s institutional cardiac monitor — a beige CRT unit on a wheeled "
        "steel cart — with an IV stand beside it. An oxygen line runs to the patient. "
        "On the NEAR side of the bed, a side table with a large floral arrangement, and "
        "the son's chair between bed and the curtained window on the right wall. Door "
        "in the background right. Camera always lives on the window side: the father is "
        "always frame-left, the son always frame-right. Machines are 1990s beige, "
        "never modern flatscreens."
    ),
    "presidents_office": (
        "LOCATION CANON — the President's office, palace, night: a vast dark office, "
        "the great desk centre with tall windows BEHIND it showing the city's lights. "
        "On the desk: a heavy black LANDLINE telephone (no mobile phones exist in "
        "Karash scenes), a green-shaded lamp, squared folders. Door far right; sitting "
        "area in the left gloom. Camera from in front of the desk."
    ),
    "justice_house": (
        "LOCATION CANON — the Chief Justice's street and door, night: a quiet "
        "prosperous street, solid older houses behind low walls on the LEFT side of "
        "frame, bare trees, every window dark on purpose. The Justice's front door is "
        "mid-left: heavy varnished wood with a brass security chain. At the curb "
        "frame-right, one black government sedan, lights off. One weak hall light "
        "inside the door; one distant streetlamp. Nadir at the door is frame-left; "
        "the car and Bayar frame-right."
    ),
    "checkpoint": (
        "LOCATION CANON — boulevard checkpoint, night: the boulevard runs away from "
        "camera into darkness. Floodlight masts on the LEFT throw hard white light; "
        "concrete barriers stagger the centre; the queue of stopped civilian cars "
        "occupies the right lane, receding. Soldiers in modern field dress walk the "
        "line with torches. The spread-eagled man against his car roof is middle "
        "distance LEFT; the dark sedan carrying Nadir and Bayar is foreground RIGHT."
    ),
    "bayar_office": (
        "LOCATION CANON — Bayar's office at the Office, night: spare and exact. Desk "
        "centre-right with a single desk lamp, venetian blinds half-down on the rear "
        "wall striping the light, two hard chairs facing the desk, door frame-left, a "
        "drinks tray on a low cabinet. Bayar belongs behind the desk (frame-right); "
        "Nadir in a chair frame-left; Turan stands near the door, left. On the desk a "
        "heavy black LANDLINE telephone. Camera from the door side."
    ),
}

# recurring cast — repeated verbatim for consistency
NADIR = ("NADIR: a lean man in his early forties, dark neatly-parted hair, tired "
         "intelligent eyes, clean-shaven, well-cut dark suit")
NADIR_LDN = ("NADIR: a lean man in his early forties, dark neatly-parted hair, warm "
             "easy posture, barrister's dark suit worn loose")
ASLAN = "ASLAN: a gaunt eighty-year-old man, once-massive frame, oxygen tube, in a sickbed"
LENA = "LENA: an English woman in her late thirties, shoulder-length hair, sharp kind face"
BAYAR = ("BAYAR: a spare grey-haired man in his late sixties, immaculate plain dark "
         "suit, folded hands, unreadable courteous face")
RUSTAM = ("GENERAL RUSTAM: a powerfully built man in his late fifties — broad and "
          "heavy but with realistic human proportions — shaved head, heavy brow, "
          "modern field combat uniform")
OSMAN = ("OSMAN: a stooped man in his seventies, donated overcoat, schoolteacher's "
         "gentle face, two fingers missing from his right hand")

FRAMES = [
    # (filename, prompt)
    ("01_cold-open_desk",
     f"{STYLE} EXTREME WIDE SHOT, night. A vast presidential office in near-darkness, "
     f"tall windows full of distant city lights. {NADIR} sits utterly still behind an "
     f"enormous dark desk, one hand resting on an internal telephone, his face half in "
     f"shadow. The room dwarfs him but he fits it. Cold, composed menace."),
    ("02_cold-open_watch",
     f"{STYLE} MEDIUM CLOSE-UP from behind, night. {NADIR} stands silhouetted at a tall "
     f"window. Far across the dark city, floodlights climb a distant building lighting a "
     f"four-storey portrait banner of a stern young military strongman. The man does not "
     f"look at it; his head is bowed slightly, speaking one word to no one."),
    ("03_london_osman",
     f"{STYLE} MEDIUM TWO-SHOT, day. A warm London barrister's chambers, rain on tall "
     f"Georgian windows, books. {OSMAN} clasps the right hand of {NADIR_LDN} in both of "
     f"his weathered hands, overcome with gratitude, eyes wet — all the emotion is the "
     f"old man's. Nadir stands composed and upright, letting him hold the hand, a faint "
     f"kind embarrassed smile, his free hand relaxed at his side. Soft grey daylight."),
    ("04_london_flat",
     f"{STYLE} WIDE SHOT, night. A small warm London flat, bookshelves, a radiator, rain "
     f"on the window. {NADIR_LDN} stands at the dark window holding a phone loosely at "
     f"his side, the call over, his ease gone. {LENA} watches him from across the room, "
     f"a closed book in her lap. Distance between them filled with the news."),
    ("05_deathbed",
     f"{STYLE} MEDIUM SHOT, night. A dim presidential sickroom: machines, a slack oxygen "
     f"tube, floral arrangement failing to soften it. {ASLAN} lies still. Beside the bed "
     f"{NADIR} sits in his travelling coat, shoulders just dropping in guilty relief, a "
     f"hand pressed over his own mouth, watching the flatlined monitor, not the man."),
    ("06_mr-president",
     f"{STYLE} OVER-THE-SHOULDER SHOT, night. From inside the dim sickroom past {NADIR} "
     f"in his chair: the door has opened and {BAYAR} stands in the lit doorway, a "
     f"respectful dark silhouette inclining his head, like a butler announcing dinner at "
     f"a deathbed. Nadir does not turn around."),
    ("07_office_screens",
     f"{STYLE} WIDE SHOT, night. A windowless security-headquarters operations room: a "
     f"wall of glowing monitors showing a TV test card, an empty airport road, and a "
     f"military column of trucks on the move. {BAYAR} stands calmly before the wall of "
     f"screens. {NADIR}, still in his travelling coat, stares at the screens, lost."),
    ("08_rustam_corridor",
     f"{STYLE} LOW-ANGLE MEDIUM SHOT, night. A grand MODERN palace corridor — marble, "
     f"electric wall sconces, a red runner — lined with soldiers in modern field dress "
     f"holding rifles. {RUSTAM} dominates the frame, contemptuous and amused, looking "
     f"down at {NADIR}, who stands his ground in his funeral suit, slighter but unbowed, "
     f"jaw set. Power against legitimacy in one image."),

    # --- coverage / establishing shots (flash tier; cheap, used as cutaways) ---
    ("11_ext_palace_night",
     f"{STYLE} EXTREME WIDE ESTABLISHING SHOT, night. A monumental presidential palace "
     f"on a low hill above a dark Caspian capital — Soviet-classical marble bulk, a long "
     f"floodlit facade, black ornamental gardens. High in the building, ONE window lit. "
     f"The city's lights spread below. Still, watchful mood."),
    ("12_phone_hand_cu",
     f"{STYLE} EXTREME CLOSE-UP, night. A man's hand resting with complete calm on the "
     f"receiver of a heavy black desk telephone, dark polished desk, the soft bokeh of "
     f"city lights beyond. The hand of a man who is not hesitating, merely waiting."),
    ("13_ext_grays_inn",
     f"{STYLE} WIDE ESTABLISHING SHOT, day. Gray's Inn, legal London in the rain — "
     f"Georgian brick facades, tall sash windows, wet flagstones, two barristers under "
     f"a black umbrella, a worn doorway with brass plates. Grey soft light, unhurried."),
    ("14_chambers_wide",
     f"{STYLE} WIDE SHOT, day. A barrister's room: bookshelf walls, rain on tall "
     f"Georgian windows. {NADIR_LDN} stands by the window with {OSMAN}; near the door a "
     f"younger COLLEAGUE in shirtsleeves holds a folder, watching with a half-smile. "
     f"Warm, cluttered, safe."),
    ("15_ext_london_flat",
     f"{STYLE} WIDE ESTABLISHING SHOT, night. A quiet London residential terrace in "
     f"light rain — brick fronts, iron railings, parked cars, a streetlamp. One warm "
     f"bay window lit on the first floor, two figures faintly visible inside."),
    ("16_lena_cu",
     f"{STYLE} CLOSE-UP, night, lamplight. {LENA} in an armchair, a closed book in her "
     f"lap, looking up and across the room with level, unafraid concern — the look of a "
     f"woman listening to one half of a phone call and understanding all of it."),
    ("17_nadir_window_cu",
     f"{STYLE} CLOSE-UP, night. {NADIR_LDN} at a dark rain-streaked window, phone to "
     f"his ear, listening, the ease gone out of his face, faint reflections of rain "
     f"moving on his skin."),
    ("18_aslan_cu",
     f"{STYLE} CLOSE-UP, night. {ASLAN} — the gaunt face in profile on the pillow, "
     f"oxygen tube, eyes closed, lit only by the green-grey glow of machines. A once "
     f"enormous force of a man, down to breath."),
    ("19_ext_office_hq",
     f"{STYLE} WIDE ESTABLISHING SHOT, night. A windowless brutalist concrete building "
     f"behind a high fence — no sign, no flag, sodium lights, a row of identical black "
     f"cars, one steel gate standing open. The building everyone in the city knows and "
     f"no one names."),
    ("20_screens_cu",
     f"{STYLE} CLOSE-UP, night. A bank of control-room monitors in a dark room: one "
     f"shows a TV test card, one an empty floodlit airport road, one a column of "
     f"military trucks moving with headlights on. The glow falls on the edge of two "
     f"watching faces, out of focus."),
    ("21_rustam_cu",
     f"{STYLE} LOW-ANGLE CLOSE-UP, night. {RUSTAM} — the shaved head and heavy brow lit "
     f"from one side by a wall sconce, the faint amused contempt of a man explaining "
     f"something to a child he intends to bury. Marble corridor soft behind him."),

    # --- act 1 part 2 (minutes 10-15): each used exactly once, linear ---
    ("22_ext_justice_house",
     f"{STYLE} WIDE ESTABLISHING SHOT, night. A quiet prosperous residential street in "
     f"a Caspian capital — solid older houses behind low walls, bare trees, one parked "
     f"black government car at the curb with its lights off. Every window on the street "
     f"dark on purpose. A single figure in an overcoat stands at one front door."),
    ("23_door_chain",
     f"{STYLE} TIGHT TWO-SHOT AT A DOORWAY, night. {NADIR} in an overcoat over a black "
     f"funeral suit stands on the front step holding a thick tabbed legal folder, "
     f"leaning earnestly toward a front door that is open only the width of its brass "
     f"security chain. In the gap: a sliver of an old man's face, one frightened eye, "
     f"white hair. Porch shadow, one weak hall light inside."),
    ("24_checkpoint",
     f"{STYLE} WIDE SHOT, night. A military checkpoint on a city boulevard — harsh "
     f"floodlights, concrete barriers, a queue of stopped civilian cars. Soldiers in "
     f"modern field dress walk the line with torches. In the middle distance a man is "
     f"spread-eagled against the roof of his car, his suitcase open on the asphalt, "
     f"shirts blowing. In the foreground corner, the dark rear window of a sedan with "
     f"two seated silhouettes watching."),
    ("25_bayar_office",
     f"{STYLE} MEDIUM WIDE SHOT, night. A spare security-chief's office: desk, two "
     f"chairs, blinds half down, one lamp. {BAYAR} pours from a bottle into two "
     f"glasses. {NADIR}, coat over his funeral suit, sits exhausted, not touching the "
     f"glass in front of him. Standing to the side: GENERAL TURAN, seventy, scarred "
     f"weathered face, an old soldier in service uniform, arms folded, watching the "
     f"young man with grim sympathy."),
    ("26_bayar_cu",
     f"{STYLE} CLOSE-UP, night. {BAYAR} — the spare grey face lit from below by a desk "
     f"lamp, mid-sentence, patient and absolutely certain, the courteous expression of "
     f"an old man explaining to a younger one the only door left in the building. "
     f"Blinds-shadow striping the wall behind him."),
]


def generate(prompt: str, key: str, refs: list[str] | None = None,
             model: str | None = None) -> bytes:
    """Text -> image; optionally conditioned on reference frames (continuity):
    pass the location's master shot in `refs` and ask for a new angle of the
    SAME room — equipment and geography then carry over instead of re-rolling."""
    parts: list[dict] = []
    for ref in refs or []:
        parts.append({"inlineData": {
            "mimeType": "image/png",
            "data": base64.b64encode(open(ref, "rb").read()).decode(),
        }})
    parts.append({"text": prompt})
    req = urllib.request.Request(
        f"https://generativelanguage.googleapis.com/v1beta/models/{model or MODEL}:generateContent",
        headers={"Content-Type": "application/json", "x-goog-api-key": key},
        data=json.dumps({
            "contents": [{"parts": parts}],
            "generationConfig": {
                "responseModalities": ["IMAGE"],
                "imageConfig": {"aspectRatio": "16:9"},
            },
        }).encode(),
    )
    with urllib.request.urlopen(req, timeout=180) as r:
        body = json.load(r)
    for cand in body.get("candidates", []):
        for part in cand.get("content", {}).get("parts", []):
            if "inlineData" in part:
                return base64.b64decode(part["inlineData"]["data"])
    raise RuntimeError(f"no image in response: {json.dumps(body)[:400]}")


def main(argv: list[str]) -> None:
    key = open(os.path.expanduser("~/.gemini_api_key")).read().strip()
    os.makedirs(OUTDIR, exist_ok=True)
    lo = int(argv[0]) if argv else 1
    hi = int(argv[1]) if len(argv) > 1 else (int(argv[0]) if argv else len(FRAMES))
    for i, (name, prompt) in enumerate(FRAMES, 1):
        if not (lo <= i <= hi):
            continue
        path = f"{OUTDIR}/{name}.png"
        t = time.time()
        png = generate(prompt, key)
        open(path, "wb").write(png)
        print(f"[{i}/{len(FRAMES)}] {path}  ({len(png)//1024} KB, {time.time()-t:.0f}s)")


if __name__ == "__main__":
    main(sys.argv[1:])
