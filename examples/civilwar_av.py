"""INDIVISIBLE Part One — pilot (Ch.1-3): single-voice audio + storyboard film.

The authored layer for the novel's audiobook-film. Emits the SAME artifacts the
heir toolchain consumes, so the proven renderers run untouched:

  perf      -> stories/civil-war/performance/pilot.performance.json
               (render with examples.heir_elevenlabs: George, eleven_v3, tags)
  shotlist  -> stories/civil-war/performance/pilot.shotlist.json
               (consumed by examples.heir_video: per-segment frames, weighted
                sub-cuts inside long segments)
  sheets    -> character reference portraits (faces stay consistent: every
               frame containing a recurring character is ref-conditioned on
               their sheet + the location master)
  frames    -> storyboard frames, gemini-3-pro-image only
  cards     -> chapter title cards (PIL, local — generated images carry no text)
  validate  -> re-derive every visual hold from the rendered manifest and
               assert the user's hard rule: NO VISUAL ON SCREEN > 10.0s

Segments are verbatim novel text chunked at sentence boundaries; segments in
one paragraph share a (scene, frame) group key so the dialogue request spans
the paragraph (natural prosody, one 550ms breath between paragraphs). The
shotlist supplies every real frame; chunks too long for one visual get
weighted sub-cuts apportioned by clause length.

    python -m examples.civilwar_av perf
    python -m examples.civilwar_av sheets
    python -m examples.civilwar_av cards
    python -m examples.civilwar_av frames [lo hi]
    python -m examples.civilwar_av validate
"""

from __future__ import annotations

import json
import os
import sys
import time

from examples.heir_storyboard import generate  # gemini-3-pro-image, refs supported

OUT = "stories/civil-war"
SB = f"{OUT}/storyboard"
PERF_DIR = f"{OUT}/performance"
GEORGE = "JBFqnCBsd6RMkjVDRZzb"
FLASH = "gemini-2.5-flash-image"  # faceless frames: separate quota bucket, 1/3 price
WPS = 2.42  # George, measured on the heir renders (~145 wpm)

# Frames whose clay is a FIGURE-staged render (posed humans/horses, not just the
# set). For these the clay leads the refs and the empty location master is
# dropped — otherwise the model anchors to the master and re-composes the people.
STAGED = frozenset({
    "c1-riders-come", "c1-leader", "c1-standoff", "c1-leader-talk", "c1-three-watch",
    "c1-dismount", "c1-block", "c1-glance-back", "c1-mount-up", "c1-turning",
    "c1-young-still", "c1-young-point", "c1-hands-show", "c1-pistol-up",
    "c1-yard-chaos", "c1-down", "c1-bay",
})
STAGED_INSTRUCTION = (
    " The FIRST attached image is a gray 3D staging render and it is THIS SHOT'S "
    "blocking law: reproduce the people and horses in it EXACTLY — same count, "
    "same positions, same scale, same poses, the same riders mounted — and match "
    "its camera, geometry and object placement precisely, rendered in the "
    "storyboard pencil style. Portrait sheets fix faces and clothing only; never "
    "let them change the blocking. Do not add or remove people or horses.")

STYLE = (
    "Film storyboard illustration: loose confident graphite pencil and charcoal on "
    "off-white paper, monochrome with rough hatching and smudged tone, strong cinematic "
    "lighting, widescreen framing drawn inside the image with a thin border. "
    "Hand-drawn production-storyboard look, expressive not photoreal. "
    "ABSOLUTELY NO TEXT of any kind anywhere on the page: no words, no letters, no "
    "speech bubbles, no character names, no labels, no panel numbers, no annotations, "
    "no watermark. The image is purely pictorial. "
    "COMPOSED LIKE A COMPETENT FEATURE FILM: one clear subject, rule-of-thirds "
    "placement, correct eyelines, consistent screen direction, camera at eye level "
    "unless the shot says otherwise, real depth (foreground, midground, background), "
    "faces visible unless the shot deliberately withholds them."
)

# ---------------------------------------------------------------- cast canon
# Recurring faces get a generated reference sheet; their frames are
# ref-conditioned on it. One-scene characters are text-only.
CAST = {
    "desmond": ("DESMOND: a Black American man in his early forties, tall and lean, "
                "close-cropped hair, short tidy beard, watchful deliberate eyes, the "
                "contained build of a careful methodical man"),
    "della":   ("DELLA: a Black American woman around forty, a schoolteacher's steady "
                "warm face, strong capable hands, hair pulled back"),
    "nia":     ("NIA: a Black American girl of twelve, braided hair, level serious "
                "eyes that weigh everything, quick and contained"),
    "ray":     ("RAY COLE: a white Texan man in his sixties, weathered sun-creased "
                "face, pale level eyes, short gray hair, plain work shirt — a man who "
                "prices everything he looks at"),
    "leader":  ("THE RIDER LEADER: a Black man in his fifties in a dusty dark "
                "broadcloth coat and slouch hat, heavy build, an easy contemptuous "
                "smile, mounted on a tall dark horse"),
    "dog":     ("THE DOG: a small wiry brown-and-white terrier mutt, about twelve "
                "pounds, ears always up, wearing a child's leather belt as a harness"),
    "min":     ("MIN: a Korean American boy of twelve, straight black hair falling "
                "into his eyes, an open earnest face, T-shirt and shorts"),
    "thanh":   ("THANH NGUYEN: a Vietnamese American man in his late fifties, "
                "silver-streaked side-parted hair, a kind precise face, white "
                "pharmacist's short-sleeve coat over a polo"),
    "hoa":     ("HOA NGUYEN: a Vietnamese American woman in her mid-fifties, neat "
                "bobbed hair, warm steady eyes that miss nothing, home cardigan"),
    "mehta":   ("DR. ARUN MEHTA: an Indian American man in his fifties, wire-rimmed "
                "glasses, silver-templed dark hair, a careful courteous face, golf "
                "shirt that has never been worn to golf"),
    "adeyemi": ("MRS. ADEYEMI: a dignified Nigerian American woman in her seventies, "
                "gray-streaked hair pulled back, Sunday-neat blouse and cardigan, a "
                "structured handbag carried in both hands, standing straight"),
}
SILAS = ("THE OLD RIDER: a spare gray-bearded Black man in his sixties, weathered "
         "oilcloth duster, low-crowned hat, the dead stillness of a hunt-camp foreman")
DAB = "THE BIG RIDER: a heavy-shouldered Black man in his forties, eating sunflower seeds from his palm"
ELI = "THE YOUNG RIDER: a lean Black youth of seventeen, eager, sharp-eyed, sitting his horse badly"
# one-scene characters, text only
BRAD = "BRAD: a white realtor in his forties, golf polo, lanyard, salesman's grin"
GRACE = ("GRACE KIM: a Korean American woman in her late thirties, neat and quick, "
         "a worried guarded face")
KGIRL = "a small Korean American girl of six"
DOCTOR = ("THE DOCTOR: a Vietnamese American man in his fifties, wire glasses, "
          "careful gentle face, wearing two coats over a sweater")
VWIFE = ("THE DOCTOR'S WIFE: a Vietnamese American woman in her fifties, layered "
         "cardigans, contained and watchful")
VGIRL = "a Vietnamese American girl of eight in a puffer coat over sweaters"
BETO = ("BETO: an unhurried Mexican man in his sixties, straw hat, neat gray "
        "mustache, reading glasses on a cord")
# wardrobe variants referenced by frame prompts (faces come from the sheets)
D_1860 = "wearing a rough homespun shirt, work trousers, broke-down shoes"
DELLA_1860 = "wearing a plain long homespun dress, sleeves rolled"
NIA_1860 = "wearing a plain gray period dress"

LOC = {
    "homestead": (
        "LOCATION CANON — a lone gray clapboard farmhouse at the end of a long dirt "
        "track, East Texas scrub country, dry summer light, high thin overcast. The "
        "house faces camera with a shaded porch and three wooden steps. In the bare "
        "dirt yard frame-right: a chopping block and woodpile. Frame-left: a stone "
        "well and an open lean-to shed with a bay horse tied in its shade, a saddle "
        "over the rail beside it. Behind the house a ragged tree line. The dirt track "
        "leaves the yard and runs far into the distance frame-left to meet a county "
        "road. Two upstairs windows over the porch. It looks like 1860; nothing in "
        "frame says otherwise."
    ),
    "bonusroom": (
        "LOCATION CANON — an empty new-build suburban bonus room, present day, Texas: "
        "fresh beige carpet, bright white walls, one window on the street side "
        "frame-right looking down onto a cul-de-sac that curls back on itself with a "
        "single entrance road, rooftops repeating beyond. Clean, bright, unfurnished."
    ),
    "fenceyard": (
        "LOCATION CANON — two adjoining suburban backyards, present day, late "
        "afternoon: a low chain-link fence runs across frame separating them, mowed "
        "grass both sides, a swing set far background-left, the neighbors' back porch "
        "with a screen door background-right."
    ),
    "hangar": (
        "LOCATION CANON — the inside of a small private hangar at night, one work "
        "light: a high-wing single-engine Cessna with its cabin door open, a freight "
        "scale bolted to the concrete floor centre, a long workbench frame-right with "
        "a coffee can and small tools, the big sliding hangar door open to darkness "
        "frame-left. Against the inside wall, a neat abandoned row: a toaster oven, a "
        "picture frame, a suitcase with a broken wheel."
    ),
    "strip": (
        "LOCATION CANON — a dirt airstrip in open dark Texas scrub at night, no "
        "lights, the Cessna pale under starlight. On the horizon frame-right, miles "
        "off, two small fires burn on an elevated interstate overpass. Flat darkness "
        "everywhere else."
    ),
    "betos": (
        "LOCATION CANON — a dirt strip south of the border at night: a flatbed truck "
        "with its parking lights on, steel fuel drums on the bed, a hand pump, dark "
        "brush line behind. Two young men by the drums; an unhurried older Mexican "
        "man in a straw hat at the tailgate. Warm dim light only from the truck."
    ),
    "pharmacy": (
        "LOCATION CANON — a strip-mall pharmacy interior, day: storefront glass "
        "across the front with a glass door frame-right (a hanging bell, a "
        "small blank hanging sign tile with no printing). The pharmacist's "
        "counter runs along the back-left with an old register and a beige "
        "computer terminal; behind it, wall shelving with white stock bottles, a "
        "small radio, and a pickup wall — rows of stapled white pharmacy "
        "bags standing patient in alphabet rows. Two low gondola shelving aisles "
        "run front-to-back mid-store (the second is the vitamin aisle). Outside "
        "the glass: a sidewalk, a girl's bicycle with a wire basket near the "
        "door, two parked cars in a sun-flattened lot, the road beyond. "
        "Fluorescent light, clean, twenty-one years tidy."
    ),
    "nkitchen": (
        "LOCATION CANON — the Nguyens' kitchen, evening: a small warm kitchen, a "
        "table for two centre with serving dishes and a smartphone propped "
        "against the rice cooker as a speakerphone; stove and counter along the "
        "back wall, a sink with a window over it frame-left, a hanging light "
        "over the table. Lived-in, exact, nothing wasted."
    ),
    "cockpit": (
        "LOCATION CANON — inside the Cessna cockpit at night: the instrument panel "
        "glowing dim red-orange, a worn control yoke, the windscreen full of black "
        "night and faint stars, fuel gauges low on the panel. Under the right side "
        "of the glareshield, low, a small old stencil of a name, paint gone bone-pale, "
        "too small and worn to read."
    ),
}

# ------------------------------------------------------------------- shots
# (frame_spec, text, tag)
#   frame_spec: "id" | [("id", weight), ...]   PARA = paragraph break (new group)
PARA = "¶"

CH1: list = [
    ([("c1-establish", 2), ("c1-yard-axe", 3)],
     "Desmond set the axe to the log again and missed the split again, and the wood rolled off the block into the dirt.", ""),
    PARA,
    ("c1-desmond-inside", "\"Nia,\" he said, not looking up. \"Water.\"", ""),
    PARA,
    ([("c1-nia-oats", 1), ("c1-bay", 1), ("c1-nia-oats", 1)],
     "\"I watered.\" Her voice came from the lean-to, where she had the bay's big head down in both hands and was feeding it oats out of her apron pocket a few at a time, making it work for them.", ""),
    PARA,
    ("c1-desmond-inside", "\"You watered the one you like. Troughs mean all three.\"", "[dry] "),
    PARA,
    ([("c1-nia-bucket", 1), ("c1-saddle-touch", 1), ("c1-saddle", 1), ("c1-saddle-touch", 1), ("c1-notebook", 1)],
     "She gave the bay the last of the oats and went for the well bucket with the put-upon walk she'd carried since she was small, and on her way past the rail she touched the saddle that sat there, the dark tooled leather with silver let into the cantle, the way you'd touch a thing in a store you'd been told twice not to handle. She had it drawn in her notebook already and had gotten the fork of it wrong, and had written under the drawing the question nobody downstairs would answer: WHOSE.", ""),
    PARA,
    ([("c1-washpot", 2), ("c1-linen-boil", 1)],
     "In the side yard Della had the wash pot going over a low fire, boiling her good linen on a Tuesday, stirring with the dolly stick, the lye smell flat on the heat.", ""),
    PARA,
    ("c1-quip-well", "\"You're chopping it like it owes you money,\" Nia said from the well.", "[dry] "),
    PARA,
    ("c1-desmond-inside", "\"Go on and pour.\" \"Mama does it better than you.\" \"Pour, Nia.\"", ""),
    PARA,
    ([("c1-rules-window", 1), ("c1-rules-road", 1)],
     "They kept their rules: nobody past the tree line alone, no lamp in the window after dark, somebody on the road from first light to last.", ""),
    PARA,
    ([("c1-nia-chin", 1), ("c1-dust", 1), ("c1-window-slide", 1), ("c1-look-stairs", 1), ("c1-window-slide", 1)],
     "Nia saw the dust first. She didn't shout, just said \"Daddy\" and lifted her chin to where the track met the county road, where something kicked up a haze with no wind to do it, and above Desmond a window slid in its frame before he'd turned all the way around. Della's rifle came to rest on the sill like it was being set in a rack built for it. He sent the girl up the stairs with a look and didn't watch her go, and heard the second window go up, the girl at it.", ""),
    PARA,
    ([("c1-axe-lean", 1), ("c1-hands-show", 1)],
     "He leaned the axe against the block like a man who meant to get back to it, and stood in the yard with his hands where they showed.", ""),
    PARA,
    ([("c1-riders-come", 1), ("c1-slickers-cu", 1), ("c1-leader", 1), ("c1-leader-smile", 1), ("c1-silas-gatepost", 1), ("c1-silas-reads", 1), ("c1-silas-gatepost", 1)],
     "The riders came up the track easy, in no hurry. They were four men as dark as he was, dusty and well-mounted, and they carried their rifles across their laps, oilcloth slickers rolled and tied behind the cantles, riding government leather on horses too good for field work. The one in front wore broadcloth gone green at the seams and a low crowned hat, and he walked his horse near to the porch before he stopped it and looked Desmond over, the homespun gone soft as paper, the brogans split at the welt, and smiled like the inventory pleased him. The oldest of them stopped well back by the gate post and didn't look at the house at all. He looked at the tree line, and at the wind in it, and then at the upstairs windows, in that order, and after that he sat still.", ""),
    PARA,
    ("c1-standoff", "\"Which plantation you run off from?\" the front one said.", "[low] "),
    PARA,
    ("c1-desmond-cu", "\"Don't know what you mean.\"", "[flat] "),
    PARA,
    ([("c1-leader-talk", 1), ("c1-moses-paper", 1), ("c1-paper-cu", 1), ("c1-leader-talk", 1)],
     "\"No?\" He hung his hands on the horn, comfortable. \"We're after a nigger come through here three, four days back. Tall, took a ball in the leg above the knee. Would've looked like he needed a place to lie up.\" He drew a paper from inside his coat and held it up unfolded, a printed thing, slick as a playing card and shining where the light got it. \"Recovery paper, all lawful. Man that gives him up holds forty dollars gold. Word of him alone is worth ten.\"", ""),
    PARA,
    ("c1-desmond-cu", "\"Nobody comes out this far.\"", ""),
    PARA,
    ([("c1-survey", 2), ("c1-leader-smile", 1)],
     "\"Somebody did.\" He looked the place over while he said it, the house, the well, the lean-to. \"Bring your wife on out. The girl too. We'll all of us talk about it.\"", ""),
    PARA,
    ("c1-desmond-talk", "\"They got nothing to tell you I can't.\"", ""),
    PARA,
    ("c1-leader-smile", "\"Wasn't a request.\"", "[flat] "),
    PARA,
    ([("c1-dismount", 1), ("c1-dab-seeds", 1), ("c1-block", 1), ("c1-glance-back", 1)],
     "One of the others got down off his horse and started for the porch, taking his time about it, a big man eating sunflower seeds out of his palm. Desmond stepped into his way, not fast, just enough to stand between him and the door, and the big man stopped and looked back — past the talker, all the way back to the old one at the gate post, who hadn't said a word yet. Desmond marked where the look went.", ""),
    PARA,
    ([("c1-desmond-talk", 3), ("c1-silas-gatepost", 2)],
     "\"There's no man here,\" Desmond said, to the gate post. \"Ride north, you'll cut his trail at the river. I wouldn't waste your daylight on us.\"", ""),
    PARA,
    ([("c1-silas-weigh", 2), ("c1-road-look", 1), ("c1-desmond-cu", 1)],
     "The old one sat his horse and chewed on it, looking at the house and the empty road north, and Desmond watched him weigh a houseful of women and a yard full of work against a lamed stranger and come up short.", ""),
    PARA,
    ("c1-silas-weigh", "\"Mount up,\" the old one said.", "[low] "),
    PARA,
    ("c1-mount-up", "The big man spat a hull at Desmond's feet and turned for his horse.", ""),
    PARA,
    ([("c1-turning", 1), ("c1-young-still", 1), ("c1-saddle", 1)],
     "They were bringing the horses around when the young one at the back went still. He was looking past the lean-to at the bay standing easy in the shade, and at the saddle on the rail beside her, the silver in the cantle throwing light, worth more than the house and everything in it.", ""),
    PARA,
    ("c1-young-point", "\"That's his saddle,\" the young one said, rising in his stirrups. \"That's the—\"", "[tense] "),
    PARA,
    ("c1-della-fires", "Della fired once from the upstairs window and took him off the horse with the sentence unfinished.", ""),
    PARA,
    ([("c1-dab-swing", 1), ("c1-desmond-draws", 1), ("c1-windows-fire", 1), ("c1-yard-chaos", 1), ("c1-leader", 1), ("c1-flee", 1), ("c1-track", 1)],
     "After that it went fast. The big man was already swinging his rifle up — he had started the swing before her shot, some cold corner of Desmond saw that and kept it — and Desmond pulled the pistol from the small of his back and put him down on the second shot. The second window opened up over him, the girl firing slow and level the way she'd been taught, and the yard filled with wheeling horses that couldn't turn in the close of it. The talker took one high in the shoulder, held on somehow, and got himself out low on his horse's neck. The old one was a length ahead of him going down the track, flat to the mane, and Desmond couldn't have said when the man started — only that nobody had been shooting at him yet when he did.", ""),
    PARA,
    ([("c1-pistol-up", 1), ("c1-down", 1), ("c1-pistol-up", 1)],
     "Desmond stood with the pistol up until there was nothing left to point it at. The young one lay where the yard's one piece of shade came up short, seventeen years old, maybe, and right, was all, half a second too loud about it.", ""),
    PARA,
    ([("c1-stairs", 1), ("c1-della-reload", 1)],
     "Desmond went inside and up the stairs. Della was thumbing rounds back into the rifle, the window still open, and she looked at his face once and went back to the work.", ""),
    PARA,
    ("c1-marriage", "\"I had them leaving,\" he said.", ""),
    PARA,
    ([("c1-della-reload", 2), ("c1-marriage", 1)],
     "\"You had them turning.\" She seated the last round. \"The big one started his swing before I fired. The old one was gone before anybody touched a trigger. Look again.\"", ""),
    PARA,
    ([("c1-replay-rein", 1), ("c1-silas-gatepost", 1)],
     "He played it back: the rein hand drifting while the talker talked, and the old man who'd looked at the wind and the windows and never once at him, pricing the place the whole time the front man kept him busy being brave.", ""),
    PARA,
    ([("c1-marriage", 2), ("c1-down", 1)],
     "\"Two got out,\" Della said. \"The old one's blood kin to that boy in the yard, or I've never watched a man not look at something. We have an hour. Maybe two.\"", ""),
    PARA,
    ("c1-pack", "\"Pack what you can carry,\" Desmond said. \"Ten minutes.\"", "[low] "),
    PARA,
    ([("c1-landing", 1), ("c1-bay-window", 1)],
     "Della was already past him with the rifle slung, calling the girl down off the landing. Desmond stood one moment more at the window, looking at the lean-to, where the bay stood easy in the shade wearing a dead boy's worth of silver.", ""),
    PARA,
    ("c1-track", "Ten minutes was not going to be enough.", ""),
]

# frame id -> (location key | None, prompt tail, [cast refs])
FRAMES_CH1 = {
    "c1-establish":   ("homestead", "EXTREME WIDE ESTABLISHING SHOT, day. The whole homestead small in the dry land, the dirt track running away to the horizon, heat-pale sky.", []),
    "c1-track":       ("homestead", "WIDE SHOT, day. The empty dirt track alone, running from foreground away to the distant county road, scrub on both sides, nothing moving.", []),
    "c1-yard-axe":    ("homestead", f"WIDE SHOT, day. {CAST['desmond']}, {D_1860}, mid-swing at the chopping block, the split missed, a chunk of wood rolling off into the dirt. The porch behind him.", ["desmond"]),
    "c1-nia-porch":   ("homestead", f"MEDIUM SHOT, day. {CAST['nia']}, {NIA_1860}, leaning on the post of the farmhouse own front porch with her arms crossed, the yard with the chopping block below her, watching something in the yard off frame-right with flat amusement. Camera on the porch with her; no other buildings exist anywhere.", ["nia"]),
    "c1-nia-quip":    ("homestead", f"TWO-SHOT, day. From beside the chopping block: {CAST['desmond']}, {D_1860}, axe in hand, looking over his shoulder at {CAST['nia']}, {NIA_1860}, on the porch steps mid-remark.", ["desmond", "nia"]),
    "c1-desmond-inside": ("homestead", f"CLOSE-UP, day. {CAST['desmond']}, {D_1860}, jaw set, the look of a father saying go inside and being ignored. Axe handle visible at the bottom of frame.", ["desmond"]),
    "c1-step-sit":    ("homestead", f"MEDIUM SHOT, day. {CAST['nia']}, {NIA_1860}, sitting on the porch step, knees drawn up under the dress, chin on her knees, gaze fixed far off down the track.", ["nia"]),
    "c1-road-look":   ("homestead", "POV SHOT, day. Looking down the long empty dirt track from the porch: scrub, distance, the county road a faint line. Nothing on it. Stillness with an edge.", []),
    "c1-kitchen-rifles": (None, f"INTERIOR MEDIUM SHOT, day. A spare period farmhouse kitchen, plank table. {CAST['della']}, {DELLA_1860}, a rifle broken open on the table in front of her, wiping the action with a rag, talking to herself, two more long guns laid in a row.", ["della"]),
    "c1-rules-window": (None, "INTERIOR DUSK SHOT. A farmhouse window at blue dusk, an unlit oil lamp on the sill, the last light dying outside. Nobody in frame. The discipline of a dark house.", []),
    "c1-rules-road":  ("homestead", f"WIDE SHOT, first light. {CAST['desmond']}, {D_1860}, a small figure standing at the head of the track in gray dawn, a long gun cradled, watching the road.", ["desmond"]),
    "c1-nia-chin":    ("homestead", f"CLOSE-UP, day. {CAST['nia']}, {NIA_1860}, on the porch step, chin lifted to point down the track, eyes level and serious, mouth barely open on one quiet word.", ["nia"]),
    "c1-dust":        ("homestead", "LONG LENS SHOT, day. Far down the track where it meets the county road: a low haze of dust rising with no wind to explain it. Heat shimmer. Nothing else.", []),
    "c1-riders-far":  ("homestead", "LONG LENS SHOT, day. Four horsemen small in the dust haze on the track, coming on at a walk, shapes more than men yet.", []),
    "c1-look-stairs": (None, f"INTERIOR MEDIUM SHOT, day. The foot of a narrow farmhouse staircase: {CAST['nia']}, {NIA_1860}, already three steps up and moving, looking back once; in the foreground edge {CAST['desmond']}'s shoulder, his face turned away toward the yard.", ["nia", "desmond"]),
    "c1-sill":        (None, "INTERIOR CLOSE-UP, day. An upstairs window slid open, the long barrel of a rifle coming gently to rest on the sill from inside, thin curtain stirring, a woman's steady hands.", []),
    "c1-axe-lean":    ("homestead", "CLOSE-UP, day. The axe being leaned carefully against the chopping block, a man's hand letting it go — the gesture of someone who means to come back to it.", []),
    "c1-hands-show":  ("homestead", f"WIDE SHOT, day. {CAST['desmond']}, {D_1860}, standing alone in the middle of the bare yard facing the track, arms loose at his sides, palms turned slightly out, hands plainly visible.", ["desmond"]),
    "c1-riders-come": ("homestead", f"WIDE SHOT, day. Four mounted Black men coming up the track into the yard at an easy walk, dusty, well-mounted, rifles laid across their laps. {CAST['leader']} slightly ahead.", ["leader"]),
    "c1-leader":      ("homestead", f"MEDIUM SHOT, day. {CAST['leader']} walking his horse right up near the porch and stopping it, looking down from the saddle, reins easy in one hand.", ["leader"]),
    "c1-leader-smile": ("homestead", f"CLOSE-UP, day. {CAST['leader']}, looking a man up and down from horseback — the homespun, the broken shoes — and smiling slow about it.", ["leader"]),
    "c1-standoff":    ("homestead", f"WIDE TWO-SHOT, day. {CAST['leader']} mounted, three riders behind him, facing {CAST['desmond']}, {D_1860}, on foot in the yard. Dust settling. Nobody moving.", ["leader", "desmond"]),
    "c1-desmond-cu":  ("homestead", f"CLOSE-UP, day. {CAST['desmond']}, {D_1860}, face level and closed, giving nothing, eyes steady on someone above him off frame.", ["desmond"]),
    "c1-leader-talk": ("homestead", f"MEDIUM CLOSE SHOT, day. {CAST['leader']} leaning forward in the saddle, hands hung on the horn, talking down — unhurried, certain, almost friendly.", ["leader"]),
    "c1-three-watch": ("homestead", "MEDIUM SHOT, day. The three other riders waiting behind, spread loose, rifles across their laps, horses shifting, one man's eyes moving over the upstairs windows.", []),
    "c1-survey":      ("homestead", f"POV PAN-STYLE WIDE SHOT, day. The homestead as {CAST['leader']} reads it from horseback: house, stone well, lean-to shed — an appraisal, not a look.", []),
    "c1-dismount":    ("homestead", "MEDIUM SHOT, day. One rider swinging down off his horse in no hurry, boots hitting dirt, starting toward the porch with all the time in the world.", []),
    "c1-block":       ("homestead", f"MEDIUM TWO-SHOT, day. {CAST['desmond']}, {D_1860}, has stepped into the walking man's path — not fast, just placed — standing between him and the porch door. The two men close, not touching.", ["desmond"]),
    "c1-desmond-talk": ("homestead", f"CLOSE-UP, day. {CAST['desmond']}, {D_1860}, talking calmly up at the mounted man, the words doing the work, pointing nothing, promising nothing.", ["desmond"]),
    "c1-glance-back": ("homestead", "MEDIUM SHOT, day. The dismounted rider stopped mid-stride, head turned back over his shoulder toward the mounted leader, waiting on the word.", []),
    "c1-leader-weigh": ("homestead", f"CLOSE-UP, day. {CAST['leader']} sitting his horse, jaw working slowly, eyes moving from the house to the empty road north — a man doing arithmetic he doesn't like.", ["leader"]),
    "c1-mount-up":    ("homestead", "MEDIUM SHOT, day. The dismounted rider spitting in the dirt and swinging back up onto his horse, one last flat look back at the man in the yard.", []),
    "c1-turning":     ("homestead", "WIDE SHOT, day. The four riders wheeling their horses in the tight yard to leave, dust kicking, the visit over.", []),
    "c1-young-still": ("homestead", "MEDIUM SHOT, day. The youngest rider at the back, his horse half-turned, gone suddenly still — staring hard at something off frame-left past the lean-to.", []),
    "c1-bay":         ("homestead", "MEDIUM SHOT, day. The lean-to in its shade: a tall bay horse tied there, groomed too well for this place, and a saddle over the rail beside it.", []),
    "c1-saddle":      ("homestead", "CLOSE-UP, day. The saddle on the rail: dark tooled leather with bright silver worked into the cantle, sunlight catching it — an expensive thing in a poor yard.", []),
    "c1-young-point": ("homestead", "MEDIUM CLOSE SHOT, day. The young rider, eyes wide, arm starting to rise toward the lean-to, mouth open mid-shout.", []),
    "c1-shot":        ("homestead", f"WIDE SHOT, day. A single pistol shot's white smoke at {CAST['desmond']}'s raised arm frame-right; across the yard the young rider tipping backward off his rearing horse, hat flying. Frozen instant, deadpan, no gore.", ["desmond"]),
    "c1-windows-fire": ("homestead", "LOW WIDE SHOT, day. The farmhouse front: both upstairs windows open, pale rifle smoke drifting from each, thin curtains moving. The house itself returning fire.", []),
    "c1-yard-chaos":  ("homestead", "WIDE SHOT, day. The yard in chaos: three horses wheeling and colliding in the tight space between porch, well and woodpile, riders hauling reins, dust everywhere.", []),
    "c1-down":        ("homestead", "MEDIUM WIDE SHOT, day. One rider down in the dirt and not moving, his horse standing off riderless with the reins hanging. Dust settling around him. No gore.", []),
    "c1-flee":        ("homestead", "WIDE SHOT, day. Two riders flat over their horses' necks at a dead run away down the track, one swaying badly in the saddle, dust boiling behind them.", []),
    "c1-pistol-up":   ("homestead", f"MEDIUM SHOT, day. {CAST['desmond']}, {D_1860}, alone in the smoke-hazed yard, pistol still raised at the empty track, perfectly still, nothing left to point it at.", ["desmond"]),
    "c1-stairs":      (None, f"INTERIOR MEDIUM SHOT, day. {CAST['desmond']}, {D_1860}, going up the narrow farmhouse stairs two at a time, one hand on the rail, the pistol still in the other.", ["desmond"]),
    "c1-pack":        (None, f"INTERIOR MEDIUM SHOT, day. An upstairs farmhouse room: {CAST['della']}, {DELLA_1860}, and {CAST['nia']}, {NIA_1860}, turning from the windows, rifles lowered, as {CAST['desmond']}'s silhouette fills the doorway. Ten minutes hangs in the air.", ["della", "nia", "desmond"]),
    "c1-nia-oats":    ("homestead", f"MEDIUM SHOT, day. In the lean-to shade, {CAST['nia']}, {NIA_1860}, has the bay horse's big head down in both hands, feeding it oats from her apron pocket a few at a time, making it work for them.", ["nia"]),
    "c1-nia-bucket":  ("homestead", f"WIDE SHOT, day. {CAST['nia']}, {NIA_1860}, crossing the yard toward the stone well carrying the bucket with a put-upon walk, the lean-to behind her.", ["nia"]),
    "c1-saddle-touch": ("homestead", f"CLOSE SHOT, day. A girl's hand resting two fingers on a dark tooled-leather saddle on a rail, silver worked into the cantle — touched the way you touch a thing you've been told twice not to handle.", []),
    "c1-notebook":    (None, "INSERT CLOSE-UP, day. A fat marbled composition notebook open on homespun cloth to a careful pencil drawing of a silver-cantled saddle, the fork of it drawn slightly wrong, a stub of pencil beside it. NO readable text anywhere.", []),
    "c1-washpot":     ("homestead", f"MEDIUM SHOT, day. In the side yard, {CAST['della']}, {DELLA_1860}, stirring a big iron wash pot over a low fire with a wooden dolly stick, steam off the water, white linen turning in it.", ["della"]),
    "c1-linen-boil":  (None, "CLOSE-UP, day. The surface of an iron wash pot: good white linen turning slowly in gray boiling water, steam, a wooden stick holding it under.", []),
    "c1-quip-well":   ("homestead", f"MEDIUM TWO-SHOT, day. From beside the chopping block: {CAST['desmond']}, {D_1860}, axe in hand, looking over his shoulder toward {CAST['nia']}, {NIA_1860}, at the stone well with the bucket, mid-remark.", ["desmond", "nia"]),
    "c1-window-slide": ("homestead", "LOW ANGLE SHOT, day. The farmhouse front from the yard: one upstairs window sliding open and a rifle barrel coming to rest on the sill from inside, unhurried, like a tool being set in a rack built for it.", []),
    "c1-slickers-cu": (None, "CLOSE SHOT, day. Detail at saddle height of mounted men on the move: a rifle laid across a lap, an oilcloth slicker rolled and tied behind the cantle, government-stamped leather, a horse too good for field work.", []),
    "c1-silas-gatepost": ("homestead", f"MEDIUM WIDE SHOT, day. {SILAS}, stopped well back by the gate post at the head of the track, apart from the others, sitting his horse with dead stillness.", []),
    "c1-silas-reads": ("homestead", f"MEDIUM CLOSE SHOT, day. {SILAS}, his eyes moving deliberately — to the tree line, to the wind in it, to the upstairs windows — reading the place like ground, never looking at the man in the yard.", []),
    "c1-moses-paper": ("homestead", f"MEDIUM SHOT, day. {CAST['leader']} holding up an unfolded printed paper from horseback, the sheet oddly slick and shining where the light catches it, presenting it like scripture.", ["leader"]),
    "c1-paper-cu":    (None, "EXTREME CLOSE-UP, day. An unfolded recovery notice held in a rider's fingers: dense printed lines and an official seal, the whole sheet unnaturally glossy, slick as a playing card, light sliding off it. The print is NOT readable — no legible words.", []),
    "c1-dab-seeds":   ("homestead", f"MEDIUM SHOT, day. {DAB} ambling toward the porch in no hurry, tossing sunflower seeds into his mouth from his open palm, hulls dropping.", []),
    "c1-silas-weigh": ("homestead", f"CLOSE-UP, day. {SILAS}, jaw working slowly, eyes moving from the house to the empty road north — a man pricing a houseful of trouble against a lamed stranger and coming up short.", []),
    "c1-della-fires": (None, "HARD LOW-ANGLE CLOSE SHOT from the yard, day, looking up at ONE upstairs farmhouse window filling the frame: a rifle muzzle at the sill with a sharp jet of white powder smoke bursting horizontally from it this instant, the thin curtain kicked aside, a woman's steady silhouette behind the glass. No chimney, no roofline, no wide view.", []),
    "c1-dab-swing":   ("homestead", f"MEDIUM SHOT, day. {DAB}, mid-motion, his rifle already swinging up toward the house — a movement that had started before any shot was fired.", []),
    "c1-desmond-draws": ("homestead", f"MEDIUM SHOT, day. {CAST['desmond']}, {D_1860}, pulling a pistol from the small of his back in one motion, body already turned toward the dismounted man, the bluff over.", ["desmond"]),
    "c1-della-reload": (None, f"INTERIOR MEDIUM SHOT, day. {CAST['della']}, {DELLA_1860}, at the open upstairs window thumbing rounds back into a rifle, calm as kitchen work, daylight on her hands, not looking up.", ["della"]),
    "c1-marriage":    (None, f"INTERIOR TWO-SHOT, day. The upstairs room: {CAST['desmond']}, {D_1860}, just inside the door, jaw set; {CAST['della']}, {DELLA_1860}, at the window with the rifle, looking at his face once. The argument standing in the air between them.", ["desmond", "della"]),
    "c1-replay-rein": (None, "EXTREME CLOSE-UP, day, memory-flat. A mounted man's gloved rein hand drifting sideways toward the rifle across his lap, slow, while somewhere off frame a voice keeps talking.", []),
    "c1-landing":     (None, f"INTERIOR MEDIUM SHOT, day. {CAST['della']}, {DELLA_1860}, rifle slung, moving fast past the camera onto the landing, calling up; {CAST['nia']}, {NIA_1860}, already coming down the stairs two at a time with the notebook under her arm.", ["della", "nia"]),
    "c1-bay-window":  (None, "POV SHOT, day, through the upstairs window glass: down across the yard to the lean-to, where the bay horse stands easy in the shade beside the silver-cantled saddle on its rail. Quiet, held, the freight nobody mentions.", []),
}

CH2: list = [
    ([("c2-house-ext", 2), ("c2-bonus-brad", 3)],
     "The realtor's name was Brad, and he had a way of announcing every room like it was the best one in the house.", ""),
    PARA,
    ("c2-brad-talk",
     "\"Now this,\" Brad said, \"is your bonus room. Media room, home gym, man cave — whatever speaks to you.\"", ""),
    PARA,
    ([("c2-desmond-window", 3), ("c2-culdesac", 2)],
     "What spoke to Desmond was the window. One window, street side, and past it the cul-de-sac curled back on itself with a single way in and out.", ""),
    ([("c2-desmond-window-cu", 3), ("c2-culdesac", 2)],
     "He stood there working it the way he worked everything — where's the door, where's the second door, what happens when the first one fails.", ""),
    PARA,
    ([("c2-della-smile", 2), ("c2-desmond-window-cu", 1)],
     "\"You're doing the thing,\" Della said, beside him, smiling out at the yard so Brad wouldn't catch her not smiling at her husband.", ""),
    PARA,
    ("c2-couple-window",
     "\"I'm looking at the house.\" \"You're looking at the exits.\"", "[dry] "),
    PARA,
    ([("c2-desmond-low", 1), ("c2-culdesac", 1), ("c2-desmond-low", 1)],
     "\"One road in, Dell. One road in is one road out.\" He kept it low. \"I keep telling you. We should be looking at land. Couple acres east of here, some space around us, something we can actually—\"", "[low] "),
    PARA,
    ("c2-della-laugh",
     "\"A compound.\" She almost laughed. \"You want to raise our daughter in a compound.\"", ""),
    PARA,
    ("c2-couple-window", "\"I want to raise our daughter.\"", "[quietly] "),
    PARA,
    ([("c2-della-cu", 2), ("c2-couple-soft", 2), ("c2-culdesac", 1)],
     "\"Desmond.\" She looked at him then, still smiling. \"It's going to be okay. People have been calling the end of the country since before there was a country. We're going to buy a house, gripe about the HOA, complain about the heat after thirty years of St. Louis winters, and be fine.\"", "[warm] "),
    PARA,
    ("c2-brad-hall",
     "\"Schools out here are phenomenal, by the way,\" Brad said from the hall.", ""),
    PARA,
    ("c2-della-smile", "\"See?\" Della said. \"Phenomenal schools.\"", "[dry] "),
    PARA,
    ("c2-desmond-window-cu", "Desmond looked back out the one window.", ""),
    PARA,
    ("c2-street-kids",
     "Outside, Nia found the only other kids on the street.", ""),
    PARA,
    ([("c2-yard-kids", 2), ("c2-min", 1)],
     "They were in the next yard over, a boy and a smaller girl, running something back and forth that took a lot of shrieking. The boy looked about her age.", ""),
    ([("c2-culdesac", 1), ("c2-yard-kids", 1)],
     "Theirs was the only yard on the cul-de-sac with a fence, chain-link and a head taller than it needed to be, matching nothing else on the street.", ""),
    ([("c2-nia-fence", 2), ("c2-kids-stop", 1)],
     "Nia went to the chain-link, hooked her fingers in it, and watched, waiting to be noticed. The smaller girl noticed first and stopped, and then the boy stopped.", ""),
    PARA,
    ([("c2-mother", 2), ("c2-nia-watch", 1)],
     "Then the screen door banged and the mother came out fast, talking. The talk wasn't for Nia. It went over her head in a language she didn't have one word of.", ""),
    ([("c2-wrist", 1), ("c2-between", 1), ("c2-nia-watch", 1)],
     "She didn't need the words. She had the face, and the way the woman caught the little girl by the wrist and turned her with it, and the way she put herself between her kids and the fence without once looking at what was on the other side of it.", ""),
    PARA,
    ("c2-fingers-out", "Nia took her fingers out of the chain-link.", ""),
    PARA,
    ("c2-nia-walk",
     "She knew it without the words. She'd known it without the words before.", "[quietly] "),
    PARA,
    ("c2-gate",
     "She was almost back to her own yard when she heard the gate.", ""),
    PARA,
    ([("c2-min-gate", 1), ("c2-min-approach", 1)],
     "The boy had come through it. He stood a second like he wasn't sure why, then crossed the grass with his hands in his pockets and stopped a careful few feet off.", ""),
    PARA,
    ("c2-min-cu", "\"She's not always like that,\" he said.", ""),
    PARA,
    ([("c2-nia-flat", 1), ("c2-min-house", 1), ("c2-min-earnest", 1)],
     "\"It's okay.\" \"It's not, though.\" He looked back at his house, then at her. \"You want to see something? There's a frog living in the storm drain by the hydrant. He's the size of a softball.\"", ""),
    PARA,
    ("c2-nia-look", "Nia looked at him.", ""),
    PARA,
    ("c2-min-earnest", "\"I'm serious,\" the boy said. \"He's enormous.\"", ""),
    PARA,
    ("c2-two-walk", "\"Okay,\" Nia said, and went with him.", ""),
]

FRAMES_CH2 = {
    "c2-bonus-brad":     ("bonusroom", f"WIDE SHOT, day. The empty bonus room, bright and beige. {BRAD} stands centre presenting the room with both arms like a prize; near the window frame-right, {CAST['desmond']} and {CAST['della']}, modern casual clothes, politely not looking at him.", ["desmond", "della"]),
    "c2-house-ext":      (None, "WIDE ESTABLISHING SHOT, day. A brand-new two-story Texas suburban house, fresh sod, a realtor's open-house sign at the curb, a couple's pickup truck in the drive, hard bright sun.", []),
    "c2-brad-talk":      ("bonusroom", f"MEDIUM SHOT, day. {BRAD} mid-announcement, hands shaping an invisible media room, lanyard swinging, the grin fully deployed.", []),
    "c2-desmond-window": ("bonusroom", f"MEDIUM SHOT, day. {CAST['desmond']}, modern casual button-down, at the window with his hands in his pockets, reading the street below like a schematic.", ["desmond"]),
    "c2-culdesac":       (None, "HIGH ANGLE SHOT, day. A new Texas cul-de-sac from a second-floor window: the street curls back on itself, identical rooftops, one single road in and out at the far end. Clean, sunny, sealed.", []),
    "c2-desmond-window-cu": ("bonusroom", f"CLOSE-UP, day. {CAST['desmond']} in profile at the window glass, eyes moving in small exact steps — door, second door, failure mode. Modern casual clothes.", ["desmond"]),
    "c2-della-smile":    ("bonusroom", f"MEDIUM CLOSE SHOT, day. {CAST['della']}, modern blouse, standing beside her husband, smiling brightly out at the yard — the smile aimed away from what her eyes are saying sideways.", ["della"]),
    "c2-couple-window":  ("bonusroom", f"TWO-SHOT, day. {CAST['desmond']} and {CAST['della']} side by side at the bonus-room window, modern casual clothes, both facing the glass, talking without looking at each other.", ["desmond", "della"]),
    "c2-desmond-low":    ("bonusroom", f"MEDIUM TWO-SHOT, day. {CAST['desmond']} turned to his wife, head bent close, talking low and urgent; {CAST['della']} listening with her arms crossed, patient.", ["desmond", "della"]),
    "c2-della-laugh":    ("bonusroom", f"CLOSE-UP, day. {CAST['della']}, a laugh she almost let out caught at the corner of her mouth, one eyebrow up — affection and disbelief in the same look.", ["della"]),
    "c2-della-cu":       ("bonusroom", f"CLOSE-UP, day. {CAST['della']} looking directly at her husband now, still smiling but level, the voice of the marriage: it is going to be okay.", ["della"]),
    "c2-couple-soft":    ("bonusroom", f"TWO-SHOT, day. {CAST['della']}'s hand resting on {CAST['desmond']}'s forearm at the window, his shoulders down half an inch, the argument set down without being settled.", ["desmond", "della"]),
    "c2-brad-hall":      ("bonusroom", f"MEDIUM SHOT, day. {BRAD} leaning his head in from the hallway door with the grin, mid-pitch, one hand on the door frame.", []),
    "c2-street-kids":    (None, f"WIDE SHOT, day. A new suburban street, fresh sod yards. {CAST['nia']}, modern T-shirt and shorts, standing alone on the sidewalk, looking toward the sound of kids in the next yard.", ["nia"]),
    "c2-yard-kids":      ("fenceyard", f"WIDE SHOT, day. In the far yard {CAST['min']} and {KGIRL} run something back and forth at full shriek; in the near yard, small at frame-left, {CAST['nia']} watching.", ["min", "nia"]),
    "c2-min":            ("fenceyard", f"MEDIUM SHOT, day. {CAST['min']} mid-run, laughing, the little girl chasing him.", ["min"]),
    "c2-nia-fence":      ("fenceyard", f"MEDIUM SHOT, day. {CAST['nia']}, modern clothes, fingers hooked in the chain-link at eye height, perfectly still, watching, waiting to be noticed.", ["nia"]),
    "c2-kids-stop":      ("fenceyard", f"MEDIUM SHOT, day. {KGIRL} stopped mid-game staring at the fence; behind her {CAST['min']} slowing to a stop too, the ball dead in his hands.", ["min"]),
    "c2-mother":         ("fenceyard", f"MEDIUM SHOT, day. {GRACE} coming out of the screen door fast, mid-sentence, one arm already reaching; the porch door still swinging behind her.", []),
    "c2-nia-watch":      ("fenceyard", f"CLOSE-UP, day. {CAST['nia']} at the chain-link, face level and unreadable, eyes tracking something happening on the other side. Words washing over her head.", ["nia"]),
    "c2-wrist":          ("fenceyard", f"CLOSE SHOT, day. {GRACE}'s hand closed around {KGIRL}'s wrist, turning the child by it, the child's feet already pivoting.", []),
    "c2-between":        ("fenceyard", f"WIDE SHOT, day. {GRACE} planted between her children and the chain-link fence, herding them toward the house, her back to the fence, never once looking at it.", []),
    "c2-fingers-out":    ("fenceyard", "EXTREME CLOSE-UP, day. A girl's fingers uncurling from the chain-link diamond and withdrawing, the wire swaying just barely.", []),
    "c2-nia-walk":       (None, f"MEDIUM SHOT, day. {CAST['nia']} walking back along the sidewalk alone, modern clothes, face composed, a girl filing something away in a drawer that already has things in it.", ["nia"]),
    "c2-gate":           ("fenceyard", "MEDIUM SHOT, day. A chain-link gate between the yards swinging open, nobody through it yet — caught at the exact second of the latch sound.", []),
    "c2-min-gate":       ("fenceyard", f"MEDIUM SHOT, day. {CAST['min']} standing just inside the open gate, hands in his pockets, like he isn't sure why he came through it.", ["min"]),
    "c2-min-approach":   (None, f"WIDE SHOT, day. {CAST['min']} crossing the grass toward {CAST['nia']}, hands in pockets, stopping a careful few feet off — the negotiated distance of twelve-year-olds.", ["min", "nia"]),
    "c2-min-cu":         (None, f"CLOSE-UP, day. {CAST['min']}, earnest, apologetic without the vocabulary for it, saying the thing about his mother.", ["min"]),
    "c2-nia-flat":       (None, f"CLOSE-UP, day. {CAST['nia']}, the level look, saying it's okay in the voice that files it under not-okay.", ["nia"]),
    "c2-min-house":      (None, f"MEDIUM SHOT, day. {CAST['min']} glancing back over his shoulder at his own house — the screen door, the kitchen window — then turning back.", ["min"]),
    "c2-min-earnest":    (None, f"CLOSE-UP, day. {CAST['min']} lit up, mid-pitch, hands starting to shape the size of it — the only diplomacy that works at twelve. NO frog anywhere in frame; the frog is elsewhere, only promised.", ["min"]),
    "c2-nia-look":       (None, f"CLOSE-UP, day. {CAST['nia']} looking at the boy a long beat, weighing the frog, the gate, the mother, all of it on the same scale.", ["nia"]),
    "c2-two-walk":       (None, f"WIDE SHOT, day. {CAST['nia']} and {CAST['min']} walking off down the sidewalk together toward a fire hydrant up the street, not talking yet, the afternoon suddenly ordinary.", ["nia", "min"]),
}

CH6_FLIGHT: list = [
    ([("c3-hangar-wide", 3), ("c3-family", 2)],
     "The Nguyens were four hundred and ten pounds of people and sixty-one pounds of luggage, and Ray Cole had told them forty on the phone.", ""),
    PARA,
    ([("c3-ray-cu", 1), ("c3-scale-cu", 1), ("c3-drums-flash", 1)],
     "He priced in gallons. He'd quit explaining that years ago, but it was the whole arithmetic: a pound in the cabin was fuel out of the tanks, gold was fuel waiting at the far end, and the price of a seat wasn't greed, it was drums — Beto's drums, on a dirt strip south of Sabinas, that Beto sold for gold and pumped to the coin.", ""),
    ("c3-family-coats",
     "Four hundred and ten pounds of people was fuel. Sixty-one pounds of luggage was fuel.", ""),
    PARA,
    ([("c3-scale-duffel", 2), ("c3-duffel-cu", 2), ("c3-ray-cu", 1)],
     "He stood at the scale he kept bolted to the hangar floor and watched the doctor take things out of a duffel and look at them and put them back: a framed thing, a folder of papers with a rubber band around it, a pair of shoes.", ""),
    PARA,
    ("c3-ray-doctor",
     "\"Forty,\" Ray said. \"The frame is my parents.\" \"The frame is six pounds.\"", "[flat] "),
    PARA,
    ([("c3-wife-low", 1), ("c3-photo-roll", 1)],
     "The doctor's wife said something low in Vietnamese, and the doctor took the photograph out of the frame, rolled it, and put it in his coat.", ""),
    ([("c3-frame-set", 1), ("c3-curb-row", 1), ("c3-toaster", 1)],
     "He set the frame on the concrete next to the scale, square to the wall, like he might come back for it. People did that. Lined their things up neat at the edge of the hangar the way they'd leave them at a curb. There was a toaster oven over there had been sitting square to the wall since March.", ""),
    PARA,
    ([("c3-phone", 3), ("c3-family-wait", 2)],
     "The phone in the hangar rang while the doctor repacked. A man's voice, young, doing the thing where it stands up too straight.", ""),
    PARA,
    ("c3-ray-phone-cu",
     "\"I heard you fly people.\" \"Where to?\" \"Mexico.\" \"Where in Mexico.\"", ""),
    PARA,
    ("c3-ray-listen",
     "There was a silence with swallowing in it. \"Mexico,\" the man said.", ""),
    PARA,
    ([("c3-hangup", 2), ("c3-family-wait", 1)],
     "\"Call me when it's a place,\" Ray said, and hung up, because a man with a destination is cargo and a man without one is weather, and he didn't fly weather.", ""),
    PARA,
    ([("c3-wing-count", 1), ("c3-coins-cu", 1), ("c3-wing-count", 1)],
     "The gold came up short. He knew it before the doctor did, watching him count it out on the wing in the worklight — coins laid in a row like a man setting a table, and the row stopped two coins shy of where it had to stop.", ""),
    ("c3-recount",
     "The doctor counted it again. The second count is for the counter, not the coins. Ray let him have it.", ""),
    PARA,
    ("c3-watch-offer",
     "\"I have a watch,\" the doctor said. \"Omega. My father's.\" \"Beto doesn't take watches.\"", ""),
    PARA,
    ("c3-doctor-lost",
     "The doctor looked at him, lost. Ray nodded at the row of coins.", ""),
    PARA,
    ([("c3-ray-explain", 1), ("c3-coin-turn", 1)],
     "\"The two coins you're short are Beto's, on the other end. Fuel for getting home. The man who sells it counts the way I count.\" He picked a coin up, turned it over, set it back down in the row.", ""),
    ([("c3-ray-terms", 1), ("c3-kids-shirts", 1), ("c3-curb-row", 1), ("c3-ray-terms", 1)],
     "\"So here's where we are. I take the watch for the two coins because we're standing here at eleven-forty at night and your kids are wearing three shirts each. And the difference comes out of my tanks coming back, and that's mine to fly, not yours. Or you put two seats of weight back on that curb and the math closes the regular way. I'll do it either way. You pick.\"", ""),
    PARA,
    ([("c3-family-coats", 1), ("c3-doctor-look", 1)],
     "The doctor looked over at his family standing next to the airplane in their coats. It was sixty degrees out. People wore everything they couldn't pack; you could tell how far somebody was going by how much they had on.", ""),
    PARA,
    ("c3-watch-off", "\"The watch,\" the doctor said, and took it off.", "[quietly] "),
    PARA,
    ([("c3-coffee-can", 1), ("c3-girl-dog", 1)],
     "Ray put it in the coffee can on the workbench where the odd ends went. Then the mother stepped forward with the little girl, and the little girl had the dog.", ""),
    PARA,
    ([("c3-dog-cu", 3), ("c3-harness-cu", 2)],
     "The dog was some kind of terrier arithmetic, eleven or twelve pounds, in a harness made out of a child's belt, ears up like the whole thing had been its idea.", ""),
    PARA,
    ("c3-mother-ask",
     "\"The dog is not on the list,\" the mother said. It came out half a question.", ""),
    PARA,
    ([("c3-ray-dog-look", 3), ("c3-sight-tube", 2)],
     "Twelve pounds was two gallons, near enough. Two gallons, on a night he was already flying home light, was the difference between margin and faith.", ""),
    ([("c3-dog-look-back", 1), ("c3-girl-grip", 1)],
     "He looked at the dog. The dog looked at him. The girl had both hands in the harness already, braced for how the grown-up conversation usually ended.", ""),
    PARA,
    ("c3-ray-verdict",
     "\"Dogs don't weigh what they cost,\" Ray said. \"He flies. He rides on the girl.\"", "[flat] "),
    PARA,
    ("c3-loading",
     "He didn't say it kind and nobody thanked him, which was how he preferred a thing like that to go.", ""),
    ([("c3-walkaround", 1), ("c3-chains", 1)],
     "He walked the airplane — hand on the cowl, fuel sumps, control surfaces, a tug on tiedown chains he'd already taken off, which made no sense and he did it anyway.", ""),
    ([("c3-stencil", 1), ("c3-thumb", 1)],
     "Under the right side of the glareshield, low where a passenger wouldn't see it unless they knew, there was a name stenciled in paint gone the color of old bone, and his thumb crossed it on the way by, not looking and not slowing.", ""),
    PARA,
    ("c3-get-in", "\"Get in,\" he said. \"Belts on everything.\"", ""),
    PARA,
    ([("c3-strip-dark", 1), ("c3-fires", 1), ("c3-fires-cu", 1)],
     "The strip had no lights and didn't need any. The only lights worth anything were the two fires burning up on the interstate overpass, five, six miles, where the checkpoint was. They'd been burning every night that week. Nobody knew what they burned up there and everybody knew better than to drive up and ask.", ""),
    PARA,
    ("c3-cockpit-doctor",
     "The doctor leaned forward between the seats while Ray ran the engine up.", ""),
    PARA,
    ([("c3-doctor-cu-cockpit", 2), ("c3-ray-profile", 1)],
     "\"They said on the radio they will register everyone. In the spring. Everyone counted, and then the moving begins. For safety, they said.\" \"They been saying it.\" \"Do you believe it?\"", ""),
    PARA,
    ("c3-ray-profile",
     "\"I believe weather reports,\" Ray said, \"after the weather.\"", "[dry] "),
    PARA,
    ([("c3-night-flight", 1), ("c3-border-lights", 1), ("c3-landing-betos", 1)],
     "It was two hours and ten minutes of nothing southbound, the border coming up the way it did now — lights bright on the south side, the north side unplugged at the wall. He put her down long and easy past Beto's brush line and taxied to the truck with its parking lights on.", ""),
    PARA,
    ([("c3-beto-count", 1), ("c3-beto-look", 1)],
     "Beto counted the gold on the tailgate by flashlight, unhurried, the way he did everything, and when he finished he looked at the row and then at Ray, and didn't recount it, because Beto's first count was for the coins.", ""),
    PARA,
    ("c3-beto-ray", "\"Short.\" \"I know what it is.\"", ""),
    PARA,
    ([("c3-beto-cu", 2), ("c3-pumping", 1)],
     "\"The road got expensive, compadre. The men on it got expensive.\" Beto was arithmetic with a hat on. He nodded at his sons to start pumping.", ""),
    ([("c3-beto-cu", 1), ("c3-watch-flash", 1), ("c3-watch-back", 1)],
     "\"I give you what the gold gives you. You want the rest on a promise, I can't. I have sons, the sons have prices.\" He held up the watch when Ray offered it, turned it in the flashlight, handed it back. \"I have a watch.\"", ""),
    PARA,
    ("c3-ray-night-cu", "\"Everybody's got a watch,\" Ray said.", "[dry] "),
    PARA,
    ([("c3-wingtip", 1), ("c3-truck-load", 1), ("c3-halftanks", 1), ("c3-night-sky", 1)],
     "The drums gave him what the gold gave him. He did the number standing at the wingtip while the Nguyens loaded into the truck — tanks at a hair over half, the home leg long, and the forecast he'd read at sundown calling the wind out of the north at altitude, on the nose the whole way back, the kind of wind you shrugged at with full tanks and read twice without them.", ""),
    ([("c3-girl-dog-dirt", 1), ("c3-dog-leg", 1)],
     "The little girl walked the dog in the dirt by the truck lights, and the dog lifted its leg on Mexico like it was any other country, which it was, which was the whole thing nobody on that airplane would have said out loud.", ""),
    PARA,
    ([("c3-doctor-wing", 1), ("c3-sight-tube", 1)],
     "The doctor came to the wing. He was going to say something with thank you in it, and Ray kept his eyes on the fuel going amber in the sight tube until the moment starved out.", ""),
    PARA,
    ("c3-wing-two",
     "\"You carry many people out?\" the doctor asked instead. \"I carry weight,\" Ray said. \"Some of it talks.\"", ""),
    PARA,
    ("c3-takeoff-night",
     "He was airborne before one, and the wind was there waiting, right where the forecast had put it.", ""),
    PARA,
    ([("c3-cockpit-night", 1), ("c3-mixture-hand", 1), ("c3-groundspeed", 1), ("c3-three-fires", 1)],
     "He flew the first hour like a man spending out of an envelope. High as the airplane would profitably go, because height was a kind of money; mixture leaned back to where the engine ran lean and grumpy and sipped; the groundspeed reading like a bad joke, the fires on the overpass ahead of him for forty minutes, not seeming to come any closer, two of them, then while he watched, a third, small and new, further east.", ""),
    ("c3-ray-cockpit-cu",
     "He noted it the way he noted weather building — where it was, and which way the wind would move it.", ""),
    PARA,
    ("c3-needles",
     "The gauge needles did what needles do at the bottom of their arc, which is stop being instruments and start being opinions.", ""),
    PARA,
    ([("c3-ray-decide", 2), ("c3-power-back", 1)],
     "Twenty miles out he ran the arithmetic the last time and didn't like the remainder, and did the thing he hated, which was spend the height.", ""),
    ([("c3-glide", 1), ("c3-panel-ghost", 1), ("c3-glide", 1)],
     "Power back to nothing, prop coarse, and the airplane became a glider with a rattle in it, coming downhill through the dark at the best-glide number his boy had once written on a card and taped to the panel, the card long gone, the number not.", ""),
    ([("c3-shutdown-hand", 1), ("c3-prop-stop", 1), ("c3-silent-glide", 1), ("c3-dark-ahead", 1)],
     "Eight miles out the engine coughed on the fumes in the line and he shut it down himself rather than let it die rough — fuel off, mags off, and then it was just wind over the skin, the quietest the world ever got, the strip somewhere ahead in the dark where it had always been, and no lights to flare by, and no engine to wave off with, and one approach in it.", "[low] "),
    ([("c3-treeline-dark", 1), ("c3-flare", 1), ("c3-rollout", 1), ("c3-prop-frozen", 1)],
     "The trees told him where the edge was by being darker than the dark. He came over them high enough to clear and low enough to make the far end matter, held her off, held her off, and the wheels found the dirt about where he'd told them to, and the airplane rolled out long and slow and stopped in the silence she'd been gliding in for eight miles, prop frozen, ticking somewhere as the metal cooled.", ""),
    PARA,
    ("c3-hands-wheel",
     "Ray sat in the dark a minute with his hands still on the wheel.", ""),
    PARA,
    ([("c3-ray-dark-cu", 1), ("c3-windscreen-dark", 1), ("c3-panel-dark", 1)],
     "The dog weighed twelve pounds, which was two gallons, near enough. He ran the numbers the whole quiet length of the rollout and for once they didn't come out even, and he knew exactly which line item had done it, and he'd fly it again the same way tomorrow, which was the part he sat with.", ""),
    PARA,
    ("c3-thumb", "His thumb found the stencil in the dark.", ""),
    PARA,
    ("c3-chaining",
     "He was halfway through chaining her down by feel when something shifted in the baggage bay.", ""),
    PARA,
    ([("c3-chain-still", 1), ("c3-cargo-door", 1), ("c3-dog-drop", 1)],
     "Ray stood still with the chain in his hand. The cargo door, which he had latched in Mexico, bumped from the inside, and bumped again, and swung, and the dog dropped out onto the dirt and shook itself the full length of its body, ears to tail, the way dogs reset.", ""),
    PARA,
    ("c3-harness-cu", "The girl's belt was still on it for a harness.", ""),
    PARA,
    ([("c3-ray-dog-stare", 1), ("c3-flashback-ramp", 1), ("c3-ray-dog-stare", 1)],
     "Ray looked at the dog a long time, putting together the bags going up in the truck lights and the family counting itself into the cab while twelve pounds of terrier arithmetic walked itself quietly back up the ramp into the dark, everyone watching everything except the one thing moving.", ""),
    ([("c3-dog-sit-dark", 3), ("c3-moon-strip", 2)],
     "It had ridden the whole way home through the lean burn and the dead-stick glide, a passenger he'd already flown one direction for free.", ""),
    PARA,
    ("c3-ray-tells-dog", "\"You're going the wrong way,\" Ray told it.", "[dry] "),
    PARA,
    ([("c3-boot-dog", 1), ("c3-two-night", 1)],
     "The dog sat down in the dirt next to his boot and looked out at the night with him, ears up, like the whole thing had been its idea.", ""),
    ([("c3-coffee-can", 1), ("c3-boot-dog", 1)],
     "Somewhere north a family eleven days from Toronto didn't know yet, and there was no number to call and no address to send to, and the gold was counted and the watch was in the can and none of it had a line for this.", ""),
    PARA,
    ([("c3-hangar-door-moon", 2), ("c3-curb-row-moon", 2), ("c3-dog-up-look", 1)],
     "He stood a minute in the open hangar door, where the toaster oven and the picture frame and a suitcase with a broken wheel sat square against the wall in the moonlight, all of it lined up neat, like the start of a town — and now the town had a dog.", ""),
]

FRAMES_CH6_FLIGHT = {
    "c3-hangar-wide":    ("hangar", f"WIDE SHOT, night. The full hangar under the one work light: the Cessna, and beside the scale a Vietnamese American family of four in winter coats — {DOCTOR}, {VWIFE}, {VGIRL} holding a small dog, a teenage boy — with one duffel between them. {CAST['ray']} stands by the scale.", ["ray", "dog"]),
    "c3-family":         ("hangar", f"MEDIUM SHOT, night. The family grouped close in the work light: {DOCTOR} in front, {VWIFE} behind him, {VGIRL} with the dog at her chest, everyone wearing too many clothes.", ["dog"]),
    "c3-ray-cu":         ("hangar", f"CLOSE-UP, night. {CAST['ray']} in the work light, the long-haul squint, a man running numbers behind his eyes while his face does nothing.", ["ray"]),
    "c3-scale-cu":       ("hangar", "CLOSE-UP, night. A heavy freight scale bolted to hangar concrete, its big analog dial, a worn duffel sitting on it. Work-light shadows.", []),
    "c3-drums-flash":    ("betos", "MEDIUM SHOT, night. Steel fuel drums standing on a flatbed in warm truck light, a hand pump between them, dark brush behind — somewhere else entirely, the far end of the arithmetic.", []),
    "c3-family-coats":   ("hangar", f"MEDIUM WIDE SHOT, night. The family standing next to the airplane in their coats, sixty degrees out, layered like winter — you can tell how far somebody is going by how much they have on.", []),
    "c3-scale-duffel":   ("hangar", f"MEDIUM SHOT, night. {DOCTOR} crouched at the open duffel beside the scale, mid-decision, an object in each hand; {CAST['ray']}'s legs at frame edge, waiting.", ["ray"]),
    "c3-duffel-cu":      ("hangar", "CLOSE-UP, night. Inside the duffel: a picture frame face-down, a rubber-banded folder of papers, a pair of good shoes — a life sorted into carry weight.", []),
    "c3-ray-doctor":     ("hangar", f"TWO-SHOT, night. {CAST['ray']} and {DOCTOR} facing each other over the scale, the duffel between them, the doctor holding the framed photograph with both hands.", ["ray"]),
    "c3-wife-low":       ("hangar", f"MEDIUM CLOSE SHOT, night. {VWIFE} leaning to her husband's ear, saying something low, her eyes on the frame in his hands.", []),
    "c3-photo-roll":     ("hangar", f"CLOSE SHOT, night. {DOCTOR}'s careful hands taking the photograph out of its frame and rolling it like a document, the empty frame under his arm.", []),
    "c3-frame-set":      ("hangar", "CLOSE SHOT, night. The empty picture frame being set down on the concrete against the wall, squared to it, gently — the gesture of a man who tells himself he is coming back.", []),
    "c3-curb-row":       ("hangar", "MEDIUM SHOT, night. The hangar's inside wall: a neat abandoned row — toaster oven, picture frame, suitcase with a broken wheel — each thing squared to the wall like luggage at a curb.", []),
    "c3-toaster":        ("hangar", "CLOSE-UP, night. The toaster oven alone against the wall, dusty, cord coiled on top, squared off — five months of waiting in one appliance.", []),
    "c3-phone":          ("hangar", f"MEDIUM SHOT, night. {CAST['ray']} with an old wall phone to his ear at the workbench, body half-turned from the family, listening with no expression.", ["ray"]),
    "c3-ray-phone-cu":   ("hangar", f"CLOSE-UP, night. {CAST['ray']} on the wall phone, eyes on the middle distance, the receiver loose against his ear — a man billing the call by the word.", ["ray"]),
    "c3-ray-listen":     ("hangar", f"CLOSE-UP, night. {CAST['ray']} listening to a silence on the line, jaw still, eyes narrowing one notch.", ["ray"]),
    "c3-hangup":         ("hangar", f"MEDIUM SHOT, night. {CAST['ray']} hanging the receiver back on its wall cradle with finality, already turning back toward the scale.", ["ray"]),
    "c3-family-wait":    ("hangar", f"MEDIUM SHOT, night. The family waiting by the airplane, not talking, {VGIRL} adjusting the dog's belt-harness, the duffel repacked at their feet.", ["dog"]),
    "c3-wing-count":     ("hangar", f"MEDIUM SHOT, night. {DOCTOR} counting gold coins into a row on the Cessna's wing under a clamped worklight, deliberate as setting a table; {CAST['ray']} watching from a step back, arms folded.", ["ray"]),
    "c3-coins-cu":       ("hangar", "EXTREME CLOSE-UP, night. A row of gold coins on aluminum wing skin in hard worklight — and the row stopping, two coin-widths of bare metal where the row needed to keep going.", []),
    "c3-recount":        ("hangar", f"CLOSE SHOT, night. {DOCTOR}'s hands recounting the same coins, touching each one; above the hands, his face already knowing the answer.", []),
    "c3-watch-offer":    ("hangar", f"CLOSE SHOT, night. {DOCTOR} unstrapping a steel wristwatch, holding it out into the worklight with both hands, an heirloom presented like evidence.", []),
    "c3-doctor-lost":    ("hangar", f"CLOSE-UP, night. {DOCTOR}, lost, the watch still in his hand, looking at a man who has just declined it for reasons that haven't been explained yet.", []),
    "c3-ray-explain":    ("hangar", f"MEDIUM CLOSE SHOT, night. {CAST['ray']} by the wing, talking plainly, pointing nothing — a man explaining the far end of a supply line he respects more than sentiment.", ["ray"]),
    "c3-coin-turn":      ("hangar", f"CLOSE SHOT, night. {CAST['ray']}'s weathered fingers picking one gold coin off the wing, turning it over, setting it back in the row exactly where it was.", ["ray"]),
    "c3-ray-terms":      ("hangar", f"MEDIUM SHOT, night. {CAST['ray']} laying out terms across the wing to {DOCTOR}, palms open, unhurried — a fair deal delivered with no warmth at eleven-forty at night.", ["ray"]),
    "c3-kids-shirts":    ("hangar", f"MEDIUM SHOT, night. The two children by the airplane: {VGIRL} with the dog, the teenage boy beside her, both visibly wearing three shirts each, collars stacked at their necks.", ["dog"]),
    "c3-doctor-look":    ("hangar", f"OVER-THE-SHOULDER SHOT, night. Past {DOCTOR}'s shoulder: his family small by the airplane in their coats, waiting on what he decides.", []),
    "c3-watch-off":      ("hangar", f"CLOSE SHOT, night. The watch coming off {DOCTOR}'s wrist for the last time, the pale band of skin under it.", []),
    "c3-coffee-can":     ("hangar", "CLOSE-UP, night. An old coffee can on the workbench among small tools, a man's hand dropping a wristwatch in with the odd ends — washers, a key, a pocketknife.", []),
    "c3-girl-dog":       ("hangar", f"MEDIUM SHOT, night. {VWIFE} stepping forward with {VGIRL}, and the girl holding the small dog against her chest, its ears up over her arm.", ["dog"]),
    "c3-dog-cu":         ("hangar", f"CLOSE-UP, night. {CAST['dog']}, in the girl's arms, ears up, entirely pleased with events so far.", ["dog"]),
    "c3-harness-cu":     ("hangar", "EXTREME CLOSE-UP, night. The dog's harness: a child's leather belt, buckled small, the extra length wrapped twice and tucked — somebody's careful work.", ["dog"]),
    "c3-mother-ask":     ("hangar", f"MEDIUM CLOSE SHOT, night. {VWIFE} stating the dog is not on the list in the posture of a woman asking, her hand on her daughter's shoulder.", []),
    "c3-ray-dog-look":   ("hangar", f"MEDIUM SHOT, night. {CAST['ray']} looking down at the dog in the girl's arms, doing fuel math against twelve pounds of optimism.", ["ray", "dog"]),
    "c3-sight-tube":     ("cockpit", "EXTREME CLOSE-UP, night. A fuel sight tube on the cabin wall, the amber line of fuel in the glass, low. Numbers made visible.", []),
    "c3-dog-look-back":  ("hangar", f"CLOSE-UP, night. {CAST['dog']} looking back up at the man, head tilted one degree, holding the stare like a negotiating position.", ["dog"]),
    "c3-girl-grip":      ("hangar", f"CLOSE SHOT, night. {VGIRL}'s hands wrapped tight in the belt-harness, knuckles pale, the grip of a child braced for the usual grown-up answer.", ["dog"]),
    "c3-ray-verdict":    ("hangar", f"CLOSE-UP, night. {CAST['ray']}, the verdict delivered with no kindness in the voice and the whole kindness in the words.", ["ray"]),
    "c3-loading":        ("hangar", f"WIDE SHOT, night. The family climbing the wing step into the Cessna's cabin, bags passed up, {CAST['ray']} steadying nothing, supervising everything.", ["ray"]),
    "c3-walkaround":     ("hangar", f"MEDIUM SHOT, night. {CAST['ray']}'s hand flat on the engine cowl mid-walkaround, his eyes already on the next item, the ritual older than the airplane.", ["ray"]),
    "c3-chains":         ("hangar", f"CLOSE SHOT, night. {CAST['ray']}'s hand giving one firm tug on a tiedown chain that is already off and coiled on the ground — the check that makes no sense and gets made anyway.", ["ray"]),
    "c3-stencil":        ("cockpit", "CLOSE-UP, night. Low under the right glareshield: a small stenciled name in paint gone the color of old bone, too worn to read, lit by spill from the panel.", []),
    "c3-thumb":          ("cockpit", "EXTREME CLOSE-UP, night. A weathered thumb crossing the worn stencil once, in passing, not slowing — a touch with twenty years of habit in it.", []),
    "c3-get-in":         ("hangar", f"MEDIUM SHOT, night. {CAST['ray']} at the cabin door, jerking his chin up into the airplane, the family's faces looking down from the seats.", ["ray"]),
    "c3-strip-dark":     ("strip", "EXTREME WIDE SHOT, night. The dirt strip in starlight, the pale Cessna taxiing out, no lights anywhere on the ground but the far fires.", []),
    "c3-fires":          ("strip", "LONG LENS SHOT, night. The interstate overpass miles off: two fires burning up on the elevated deck, small and steady, the checkpoint's silhouette under them.", []),
    "c3-fires-cu":       ("strip", "CLOSER LONG LENS SHOT, night. The two fires on the overpass: figures tiny against the flame light, unreadable at this distance, which is the point of the distance.", []),
    "c3-cockpit-doctor": ("cockpit", f"MEDIUM SHOT, night. Inside the cabin: {DOCTOR} leaning forward between the front seats toward {CAST['ray']} at the controls, the panel glow on both faces, the engine run-up shaking the frame.", ["ray"]),
    "c3-doctor-cu-cockpit": ("cockpit", f"CLOSE-UP, night. {DOCTOR} in the red-orange panel light, asking the question a man asks when he wants a different answer than the radio gave him.", []),
    "c3-ray-profile":    ("cockpit", f"PROFILE CLOSE-UP, night. {CAST['ray']} flying, panel glow on the weathered face, eyes forward, giving the weather report answer.", ["ray"]),
    "c3-night-flight":   (None, "EXTREME WIDE SHOT, night. A small high-wing airplane tiny against a black sky over dark featureless land, no ground lights at all, stars above.", []),
    "c3-border-lights":  (None, "AERIAL WIDE SHOT, night. The border from altitude: the south side a warm lit grid of towns, the north side black to the horizon — one country plugged in, the other switched off, a dark wall between.", []),
    "c3-landing-betos":  ("betos", "WIDE SHOT, night. The Cessna rolling out past a dark brush line toward a flatbed truck with parking lights on, dust drifting through the beams.", []),
    "c3-beto-count":     ("betos", f"MEDIUM SHOT, night. {BETO} counting gold coins into a row on the tailgate by flashlight, unhurried, glasses down his nose; {CAST['ray']} standing across the tailgate.", ["ray"]),
    "c3-beto-look":      ("betos", f"CLOSE-UP, night. {BETO} looking up from the finished row over his glasses at the man across the tailgate — the look that replaces a recount.", []),
    "c3-beto-ray":       ("betos", f"TWO-SHOT, night. {BETO} and {CAST['ray']} facing each other over the tailgate row of coins, flashlight between them, two honest accountants of a dishonest year.", ["ray"]),
    "c3-beto-cu":        ("betos", f"MEDIUM CLOSE SHOT, night. {BETO} talking across the tailgate, reasonable and final, a man quoting prices he didn't set.", []),
    "c3-pumping":        ("betos", "MEDIUM SHOT, night. Two young men working a hand pump on the flatbed, fuel hose running down to the Cessna's wing, truck light catching the line.", []),
    "c3-watch-flash":    ("betos", f"CLOSE SHOT, night. {BETO} holding the wristwatch up into the flashlight beam, turning it once, appraising it without wanting it.", []),
    "c3-watch-back":     ("betos", f"CLOSE SHOT, night. The watch being handed back across the tailgate into {CAST['ray']}'s open palm.", ["ray"]),
    "c3-ray-night-cu":   ("betos", f"CLOSE-UP, night. {CAST['ray']} in the truck light, pocketing the watch, the joke delivered without a smile.", ["ray"]),
    "c3-wingtip":        ("betos", f"MEDIUM SHOT, night. {CAST['ray']} standing alone at the Cessna's wingtip in the dark, hand resting on it, head down, running the number.", ["ray"]),
    "c3-truck-load":     ("betos", f"WIDE SHOT, night. The family loading into the flatbed's cab in the parking lights, bags passed up, {VGIRL} lifted in last.", []),
    "c3-halftanks":      ("cockpit", "CLOSE-UP, night. A fuel gauge needle sitting one hair over the half mark, panel glow, the arc below it long and empty.", []),
    "c3-night-sky":      (None, "WIDE SHOT, night. The northern sky from the strip: high cloud moving south in moonlight, the direction legible in the sky itself — wind on the nose for the ride home.", []),
    "c3-girl-dog-dirt":  ("betos", f"MEDIUM SHOT, night. {VGIRL} walking the small dog on its belt-leash through the headlight dust by the truck, a tiny ordinary errand in the middle of an extraordinary night.", ["dog"]),
    "c3-dog-leg":        ("betos", f"MEDIUM SHOT, night. {CAST['dog']} lifting its leg on a clump of Mexican scrub in the truck light, supremely indifferent to international relations.", ["dog"]),
    "c3-doctor-wing":    ("betos", f"TWO-SHOT, night. {DOCTOR} standing at the Cessna's wing where {CAST['ray']} is fueling, the thank-you forming and dying in the silence between them.", ["ray"]),
    "c3-wing-two":       ("betos", f"MEDIUM SHOT, night. {CAST['ray']} and {DOCTOR} at the wing in the dark, both looking at the airplane instead of each other, the conversation conducted at forty-five degrees.", ["ray"]),
    "c3-takeoff-night":  ("betos", "WIDE SHOT, night. The Cessna lifting off the dark strip into a darker sky, truck lights small below, dust hanging in the beams.", []),
    "c3-cockpit-night":  ("cockpit", f"MEDIUM SHOT, night. {CAST['ray']} alone in the cockpit, panel glow, the empty seats behind him, flying high and lean — a man spending out of an envelope.", ["ray"]),
    "c3-mixture-hand":   ("cockpit", "CLOSE-UP, night. A weathered hand easing a red mixture knob back a fraction at a time, listening through the fingertips.", []),
    "c3-groundspeed":    ("cockpit", "CLOSE-UP, night. The groundspeed reading on the panel, insultingly low, the needle steady — a bad joke told in instrument form.", []),
    "c3-three-fires":    (None, "AERIAL SHOT, night. Through the windscreen far ahead: the overpass fires — two, and east of them a third, small and new. The land otherwise black.", []),
    "c3-ray-cockpit-cu": ("cockpit", f"CLOSE-UP, night. {CAST['ray']} reading the fires the way he reads weather: where it is, which way the wind will move it. No alarm. Filing.", ["ray"]),
    "c3-needles":        ("cockpit", "EXTREME CLOSE-UP, night. Two fuel gauge needles low in their arcs, trembling at the bottom — instruments resigning into opinions.", []),
    "c3-ray-decide":     ("cockpit", f"CLOSE-UP, night. {CAST['ray']}, the last arithmetic done, not liking the remainder — the held half-second before a decision he hates.", ["ray"]),
    "c3-power-back":     ("cockpit", "CLOSE SHOT, night. The throttle coming all the way back under a steady hand, the prop lever set coarse — spending the height.", []),
    "c3-glide":          (None, "WIDE SHOT, night. The little airplane descending through darkness, prop barely turning, nose held at one exact attitude — a glider with a rattle in it.", []),
    "c3-panel-ghost":    ("cockpit", "CLOSE-UP, night. A bare spot on the panel edge where tape once held a card, the adhesive ghost still visible; the airspeed needle pinned on one number beside it.", []),
    "c3-shutdown-hand":  ("cockpit", "CLOSE SHOT, night. The fuel selector turned to OFF, then the mag switch, the same hand, no hurry — a man putting his own engine to sleep.", []),
    "c3-prop-stop":      (None, "MEDIUM SHOT, night. From beside the cowl: the propeller blade slowing, slowing, stopping at an angle against the stars.", []),
    "c3-silent-glide":   (None, "EXTREME WIDE SHOT, night. The airplane a silent shape sinking across the starfield, no engine, no lights, wind the only thing in the world.", []),
    "c3-dark-ahead":     ("cockpit", "POV SHOT, night. Through the windscreen: total darkness, a horizon told only by the stars stopping, somewhere in it a strip that has to be where it has always been.", []),
    "c3-treeline-dark":  (None, "POV SHOT, night. The treeline materializing below — darker than the dark, a serrated edge rising at the bottom of the windscreen.", []),
    "c3-flare":          ("strip", "WIDE SHOT, night. The Cessna inches over the dirt in the dark, nose high, held off, held off, main wheels feeling for the ground.", []),
    "c3-rollout":        ("strip", "WIDE SHOT, night. The airplane rolling out long and slow on the dirt strip in starlight, no engine, dust barely rising, coming to rest.", []),
    "c3-prop-frozen":    ("strip", "CLOSE SHOT, night. The propeller stopped dead against the night sky, heat shimmer off the cowl, the tick of cooling metal almost visible.", []),
    "c3-hands-wheel":    ("cockpit", f"MEDIUM SHOT, night. {CAST['ray']} sitting still in the dark cockpit, hands resting on the yoke, the panel dead, starlight through the windscreen.", ["ray"]),
    "c3-ray-dark-cu":    ("cockpit", f"CLOSE-UP, night. {CAST['ray']}'s face in starlight only, eyes open, doing the one sum that didn't come out even and signing it anyway.", ["ray"]),
    "c3-windscreen-dark": ("cockpit", "POV SHOT, night. Through the windscreen from the parked airplane: the dark strip, the darker trees, stillness with the engine's absence in it.", []),
    "c3-panel-dark":     ("cockpit", "CLOSE-UP, night. The instrument panel switched off and dark, every needle at rest, faint starlight on the glass faces.", []),
    "c3-chaining":       ("strip", f"MEDIUM SHOT, night. {CAST['ray']} crouched at the wing tiedown in the dark, chaining the airplane down by feel, head turning suddenly toward the tail.", ["ray"]),
    "c3-chain-still":    ("strip", f"CLOSE SHOT, night. {CAST['ray']} frozen with the chain in his hand, listening, eyes on the baggage door.", ["ray"]),
    "c3-cargo-door":     ("strip", "CLOSE SHOT, night. The cargo door bumping from the inside — once, again — then swinging open onto darkness.", []),
    "c3-dog-drop":       ("strip", f"MEDIUM SHOT, night. {CAST['dog']} dropping out of the baggage bay onto the dirt and shaking itself the full length of its body, ears to tail, the child's belt still on it.", ["dog"]),
    "c3-ray-dog-stare":  ("strip", f"MEDIUM TWO-SHOT, night. {CAST['ray']} standing with the chain, looking down a long time at {CAST['dog']} sitting in the dirt looking up, neither moving.", ["ray", "dog"]),
    "c3-flashback-ramp": ("betos", f"MEDIUM SHOT, night. Back at the truck: everyone's eyes on the bags going up into the cab — and behind them all, small and unnoticed, {CAST['dog']} trotting quietly up the airplane's ramp into the dark bay.", ["dog"]),
    "c3-dog-sit-dark":   ("strip", f"CLOSE-UP, night. {CAST['dog']} sitting in the dirt in starlight, ears up, the belt-harness on, looking up with the whole night's stowaway behind it.", ["dog"]),
    "c3-moon-strip":     ("strip", "WIDE SHOT, night. The chained Cessna pale on the empty strip under stars, one man and one small dog beside it, the only two upright things for miles.", []),
    "c3-ray-tells-dog":  ("strip", f"CLOSE-UP, night. {CAST['ray']} looking down, telling the dog the one true thing — it is going the wrong way — and the dog declining to hear it.", ["ray"]),
    "c3-boot-dog":       ("strip", f"CLOSE SHOT, night. {CAST['dog']} sitting down in the dirt against {CAST['ray']}'s boot, both of them facing out at the same darkness.", ["ray", "dog"]),
    "c3-two-night":      ("strip", f"WIDE SHOT, night. Man and dog side by side at the edge of the strip, backs to camera, looking north into the dark where the family went.", ["ray", "dog"]),
    "c3-hangar-door-moon": ("hangar", f"WIDE SHOT, night. {CAST['ray']} standing in the open hangar doorway in moonlight, the dog a small shape at his heel, the hangar dark behind them.", ["ray", "dog"]),
    "c3-curb-row-moon":  ("hangar", "MEDIUM SHOT, night. The row against the wall in moonlight: toaster oven, empty picture frame, suitcase with a broken wheel — lined up neat, the start of a town.", []),
    "c3-dog-up-look":    ("hangar", f"CLOSE-UP, night. {CAST['dog']} at the man's feet in the moonlit doorway, looking up, ears at full mast, awaiting assignment.", ["dog"]),
}

# ---- Chapter 3 (v11): THE NGUYENS — the pharmacy, the relay, the spoon ----
CH3: list = [
    ([("n3-pharm-wide Every sign, label and tile in the store is BLANK colored plastic with no printing of any kind.", 1), ("n3-screen-stare", 1)],
     "The system wanted a number Mrs. Adeyemi did not have, and Thanh Nguyen had been staring at the field for most of a minute.", ""),
    PARA,
    ("n3-thanh-cu", "\"It's the update,\" he said. \"They put a new field in. It won't take blank.\"", ""),
    PARA,
    ("n3-adeyemi", "\"What number is it asking for?\"", ""),
    PARA,
    ([("n3-screen-turn", 1), ("n3-field-cu", 1), ("n3-count-fives", 1), ("n3-vial-push", 1)],
     "\"It doesn't say.\" He turned the screen so she could see it not saying. The field had a name made of initials, and a red asterisk, and twenty-one years of filling her blood-pressure pills stood on one side of it and the refill stood on the other. Thanh keyed back out, took a stock bottle off the shelf behind him, counted fourteen days of tablets into a vial by fives, the tray clicking, and pushed the vial across with the label blank.", ""),
    PARA,
    ([("n3-thanh-kind", 2), ("n3-vial-push", 1)],
     "\"That's a sample,\" he said. \"Samples don't go in the computer. By the time you're through them, the field will have a help line.\"", ""),
    PARA,
    ([("n3-register", 1), ("n3-door-watch", 1), ("n3-willcall Every sign, label and tile in the store is BLANK colored plastic with no printing of any kind.", 1)],
     "He rang up her cough drops so she'd have a receipt for the walk back, and watched her out the door, and then he stood a while looking at the pickup wall of stapled white bags, where the stapled bags waited patient in their rows and every one carried a family's name in his own block letters.", ""),
    PARA,
    ([("n3-radio", 1), ("n3-pharm-wide", 1)],
     "The radio on the back counter, low, was running the noon update. Registration would open statewide the first of the month, the warm voice said. Everyone counted, so everyone's cared for.", ""),
    PARA,
    ([("n3-phone-two", 2), ("n3-lot-heat", 1)],
     "Hoa called at two, which was her time, with the question she asked once a week the way other people went to church.", ""),
    PARA,
    ([("n3-hoa-kitchen", 1), ("n3-tap", 1), ("n3-hoa-kitchen", 1)],
     "\"Binh says the hospital will sponsor. He says his attending did it for a family from Laos, four people, eight weeks start to finish.\" The pause had a kitchen in it — somewhere behind her a tap ran and shut off. \"Eight weeks, Thanh. If we filed now.\"", ""),
    PARA,
    ("n3-thanh-cu", "\"Who fills Mrs. Adeyemi on the fifteenth?\"", "[quietly] "),
    PARA,
    ("n3-hoa-kitchen", "\"Walgreens fills her.\"", ""),
    PARA,
    ([("n3-thanh-gentle", 1), ("n3-lot-heat", 1), ("n3-thanh-gentle", 1)],
     "\"Walgreens' computer is the same computer.\" He said it gently, and not for the first time, and through the window he watched the parking lot do nothing in the heat. \"We'll talk at dinner.\"", ""),
    PARA,
    ([("n3-hoa-hangup", 2), ("n3-hoa-kitchen", 1)],
     "\"We'll talk at dinner,\" she said, in the voice of a woman filing the case for next week, and was kind enough to hang up first.", ""),
    PARA,
    ([("n3-mehta-enters", 1), ("n3-mehta-counter", 1), ("n3-bike-dog Every sign, label and tile in the store is BLANK colored plastic with no printing of any kind.", 1), ("n3-mehta-counter", 1), ("n3-bike-dog", 1)],
     "Dr. Mehta came in at ten to six, on a Tuesday that should have had him at the hospital, and he came in person, a man whose prescriptions had arrived by fax for nine years under a signature like a cardiogram. He stood at the counter in a golf shirt that had never been worn to golf, and out front, past the glass, a small dog sat up in the basket of a girl's bicycle with its ears up like a captain.", ""),
    PARA,
    ("n3-mehta-cu", "\"Thanh,\" he said. \"I find myself with a free afternoon.\"", ""),
    PARA,
    ("n3-thanh-cu", "\"On a Tuesday.\"", "[flat] "),
    PARA,
    ([("n3-mehta-mat", 1), ("n3-mehta-cu", 1)],
     "\"On all the Tuesdays.\" Dr. Mehta straightened the counter mat with one finger. \"There was an audit this morning. A category audit. My privileges are suspended pending — \" he turned his hand over \" — pending.\"", ""),
    PARA,
    ("n3-counter-word",
     "The word sat on the counter between them like a thing that had crawled up there.", ""),
    PARA,
    ([("n3-mehta-tells", 1), ("n3-thanh-listens", 1), ("n3-mehta-tells", 1), ("n3-thanh-listens", 1)],
     "\"Priya's brother drove to the airport Friday,\" Dr. Mehta said. \"He had visas, tickets, everything stamped. They boarded him back off at the gate, and the paper gives no reason. It says see addendum, and there is no addendum.\" He was working to keep it in the contractual voice, the voice that had read labs to frightened men for thirty years, and it mostly held.", ""),
    PARA,
    ("n3-mehta-asks", "\"You said once — last winter, you said a thing to me. About a man with an airplane.\"", "[low] "),
    PARA,
    ([("n3-door-look", 1), ("n3-lot-survey", 1), ("n3-sign-flip", 1)],
     "Thanh came around the counter, went to the door, and stood looking at the lot a moment — at the girl and the bicycle and the dog, at the two parked cars, at the road. Then he flipped the sign to CLOSED and came back.", ""),
    PARA,
    ("n3-thanh-level", "\"You were never in today,\" he said.", ""),
    PARA,
    ("n3-mehta-cu", "\"I was never in.\"", ""),
    PARA,
    ([("n3-number-said", 2), ("n3-thanh-level", 1)],
     "\"There's a strip past Bowie.\" Then he said a phone number once, at the speed a man says his own. \"Say it back.\"", ""),
    PARA,
    ([("n3-two-memorize", 1), ("n3-vitamins", 1), ("n3-two-memorize", 1)],
     "Dr. Mehta said it back. Thanh nodded and did not say it again, and wrote nothing down, and watched the doctor not write it down either, the two of them standing in the smell of vitamins committing a phone number the old way, like men their age memorizing a girl's address in 1985.", ""),
    PARA,
    ([("n3-thanh-warns", 1), ("n3-aisle-walk", 1), ("n3-tablets-hand", 1), ("n3-thanh-warns", 1)],
     "\"He prices in gold,\" Thanh said. \"If you bargain, he subtracts. And he'll want a place, not a country — have the place before you call.\" He went down the second aisle and came back with a small box and put it in the doctor's hand. \"For the girl. Half a tablet, twenty minutes before. It's a small airplane.\"", ""),
    PARA,
    ("n3-tablets-thumb",
     "Dr. Mehta looked at the box of motion-sickness tablets a long moment, his thumb moving once across it.", ""),
    PARA,
    ("n3-mehta-pay", "\"I would want to pay something,\" he said. \"For the introduction.\"", ""),
    PARA,
    ([("n3-thanh-kindly", 1), ("n3-mehta-cu", 1), ("n3-thanh-kindly", 1)],
     "\"You'd pay him. There's nothing to pay me for. I wasn't in today, and I didn't do anything, and you'll remember that I didn't.\" Thanh said it kindly, the way he said take with food. \"Toronto?\"", ""),
    PARA,
    ([("n3-mehta-cu", 1), ("n3-door-unlock", 1), ("n3-dog-warning", 1)],
     "\"My sister.\" \"Eat at her place a year before you open anything.\" He unlocked the door. \"Doctor. The girl takes the dog, or the girl learns the word for what happens to it. There's no third thing in between, whatever Priya is hoping.\"", ""),
    PARA,
    ([("n3-bell-leave", 1), ("n3-bike-wobble", 1), ("n3-lights-buzz", 1)],
     "The bell went, and the doctor was a customer leaving, and the bicycle wobbled off the curb with its captain riding high, and Thanh turned the sign back and stood at his counter with the lights buzzing.", ""),
    PARA,
    ([("n3-dinner-wide", 1), ("n3-phone-speaker", 1), ("n3-dinner-wide", 1)],
     "At dinner Hoa put Binh on speaker while she served, and the boy's voice came out bright and far and resident-tired, from a city where the word pending was something you did to a file. Eight weeks, he said, maybe ten now; the forms kept changing but the attending knew the new forms.", ""),
    PARA,
    ([("n3-thanh-eats", 1), ("n3-hoa-watches", 1), ("n3-willcall", 1), ("n3-thanh-eats", 1)],
     "Thanh ate, and said the food was good, and it was. Across the table his wife watched him the way she'd watched him for thirty years, adding up what he wasn't saying, and the pickup wall of stapled white bags stood in his mind, the stapled bags waiting patient with every name in his own square hand, and forty years ago somebody had said a number out loud once in a room in Songkhla and his whole family had happened because of it.", ""),
    PARA,
    ("n3-thanh-phone-dinner",
     "\"Ten weeks is fast,\" he said to the phone. \"That's good news, Binh. Tell me again after the fifteenth.\"", ""),
    PARA,
    ("n3-spoon",
     "Hoa set the serving spoon down with no sound at all.", "[quietly] "),
]

FRAMES_CH3 = {
    "n3-pharm-wide":   ("pharmacy", f"WIDE SHOT, day. The pharmacy interior from the front aisles: {CAST['thanh']} small behind the counter at the terminal, the wall of stapled white paper bags behind him, fluorescent calm.", ["thanh"]),
    "n3-screen-stare": ("pharmacy", f"MEDIUM SHOT, day. {CAST['thanh']} behind the counter, staring at a beige computer screen, one hand resting on the keys, not typing.", ["thanh"]),
    "n3-thanh-cu":     ("pharmacy", f"CLOSE-UP, day. {CAST['thanh']}, the kind precise face, explaining a small absurdity without raising his voice.", ["thanh"]),
    "n3-adeyemi":      ("pharmacy", f"MEDIUM CLOSE-UP, day, camera at the counter: {CAST['adeyemi']} STANDING upright at the counter, no stool, no chair, waiting on an answer with great patience. Tight framing, head and shoulders, the counter edge at the bottom of frame.", ["adeyemi"]),
    "n3-screen-turn":  ("pharmacy", f"MEDIUM TWO-SHOT, day, BOTH PEOPLE AT THE PHARMACY COUNTER facing each other across it: {CAST['thanh']} stands BEHIND the counter with both hands turning the beige computer monitor on its base toward the customer; {CAST['adeyemi']} stands on the customer side, upright, leaning in slightly to read the screen. The monitor between them, mid-rotation. Two people in frame, no one seated.", ["thanh", "adeyemi"]),
    "n3-field-cu":     (None, "EXTREME CLOSE-UP. A beige CRT pharmacy screen showing a form rendered ONLY as soft gray scribble-lines and empty boxes — absolutely no letters, no words, no numbers, no legible characters anywhere — with one empty field outlined and a small red asterisk beside it.", []),
    "n3-count-fives":  (None, "CLOSE-UP, day. A pharmacist's counting tray: tablets being raked into groups of five with a steel spatula, quick and exact, a stock bottle open beside it.", []),
    "n3-vial-push":    ("pharmacy", f"CLOSE SHOT, day, from the customer's side of the counter: {CAST['thanh']} stands behind the counter and his hand and forearm extend naturally across the countertop, pushing an amber pill vial with a blank white label forward. The arm is plainly connected to his shoulder; correct human anatomy; the computer terminal is off to one side, not blocking him. No text anywhere.", ["thanh"]),
    "n3-thanh-kind":   ("pharmacy", f"MEDIUM CLOSE-UP, day. {CAST['thanh']} behind his counter, conspiratorial kindness delivered deadpan — tight on him, the customer's shoulder soft in the near foreground edge.", ["thanh"]),
    "n3-register":     ("pharmacy", f"CLOSE SHOT, day, on the old register: {CAST['thanh']}'s hands ringing up a small item, the drawer opening; across the counter, {CAST['adeyemi']} STANDS upright holding her handbag — visible from waist up, no stool, no chair.", ["thanh", "adeyemi"]),
    "n3-door-watch":   ("pharmacy", f"MEDIUM SHOT, day, from behind the counter looking toward the storefront: {CAST['adeyemi']} WALKING out through the glass door, mid-step, the bell still moving above it, sunlight flat on the lot beyond.", ["adeyemi"]),
    "n3-willcall":     ("pharmacy", "MEDIUM SHOT, day. The pickup wall: rows of stapled white paper pharmacy bags standing in tidy rows on brick-built shelving, patient as a choir, every bag a blank white LEGO piece.", []),
    "n3-radio":        ("pharmacy", "CLOSE-UP, day. A small old radio on the back counter between stock bottles, its grille catching fluorescent light, volume knob at low.", []),
    "n3-phone-two":    ("pharmacy", f"MEDIUM SHOT, day. {CAST['thanh']} leaning at the counter with a cordless phone to his ear, afternoon light through the storefront, listening to a case he has heard before.", ["thanh"]),
    "n3-lot-heat":     ("pharmacy", "POV SHOT, day, through the storefront glass: the parking lot doing nothing in the heat — two parked cars, white sun, the road beyond. Stillness.", []),
    "n3-hoa-kitchen":  ("nkitchen", f"MEDIUM SHOT, day. {CAST['hoa']} at the kitchen counter with the phone to her ear, mid-case, a dish towel over her shoulder, the argument gentle and rehearsed.", ["hoa"]),
    "n3-tap":          ("nkitchen", "CLOSE-UP, day. A kitchen tap running into a steel sink, then a hand shutting it off — the pause in a phone call made visible.", []),
    "n3-thanh-gentle": ("pharmacy", f"CLOSE-UP, day. {CAST['thanh']}, phone to his ear, saying the gentle thing he has said before, eyes out the window at nothing.", ["thanh"]),
    "n3-hoa-hangup":   ("nkitchen", f"MEDIUM CLOSE SHOT, day. {CAST['hoa']} setting the phone down on the counter, unhurried, the face of a woman filing a case for next week, not defeated.", ["hoa"]),
    "n3-mehta-enters": ("pharmacy", f"WIDE SHOT, evening. The glass door opening under the bell: {CAST['mehta']} stepping in, out of place in his own clothes, the low sun behind him.", ["mehta"]),
    "n3-mehta-counter": ("pharmacy", f"MEDIUM TWO-SHOT, evening. {CAST['mehta']} — SILVER-GRAY TEMPLED dark hair and WIRE-RIMMED SPECTACLES, fifties, golf shirt — standing at the counter opposite {CAST['thanh']}, the counter between them, both men careful.", ["mehta", "thanh"]),
    "n3-bike-dog":     ("pharmacy", f"MEDIUM SHOT, evening, from inside the pharmacy looking out through the storefront glass: OUTSIDE on the sidewalk at the curb stands a girl's bicycle with {CAST['dog']} as a molded LEGO dog sitting up in its wire basket, ears at full mast. The bicycle and dog are entirely OUTSIDE the building, beyond the glass. In the near foreground inside, the counter edge with {CAST['thanh']} partially visible.", ["dog", "thanh"]),
    "n3-mehta-cu":     ("pharmacy", f"CLOSE-UP, evening. {CAST['mehta']}, the courteous face working to stay contractual, fluorescent light on the wire rims.", ["mehta"]),
    "n3-mehta-mat":    (None, "EXTREME CLOSE-UP, evening. A man's finger straightening a rubber counter mat by one degree — the small correction of a man keeping his hands busy while he says a hard thing.", []),
    "n3-counter-word": ("pharmacy", f"TWO-SHOT, evening. {CAST['thanh']} and {CAST['mehta']} on either side of the empty counter, both looking down at it, as if something had crawled up between them and sat there.", ["thanh", "mehta"]),
    "n3-mehta-tells":  ("pharmacy", f"MEDIUM CLOSE SHOT, evening. {CAST['mehta']} recounting the airport flatly, one hand flat on the counter, the cardiologist's voice holding.", ["mehta"]),
    "n3-thanh-listens": ("pharmacy", f"CLOSE-UP, evening. {CAST['thanh']} listening without moving, the stillness of a man taking inventory of a risk.", ["thanh"]),
    "n3-mehta-asks":   ("pharmacy", f"CLOSE-UP, evening. {CAST['mehta']} leaning in a careful inch, voice dropped, asking about a man with an airplane.", ["mehta"]),
    "n3-door-look":    ("pharmacy", f"MEDIUM SHOT, evening. {CAST['thanh']} at the glass door, one hand on the frame, scanning the lot with the unhurried thoroughness of a man who was never in today.", ["thanh"]),
    "n3-lot-survey":   ("pharmacy", "POV SHOT, evening, through the door glass: the girl on her bicycle with the dog in the basket, two parked cars, the empty road — each item checked once.", []),
    "n3-sign-flip":    ("pharmacy", "CLOSE-UP, evening. A hand flipping the hanging door sign over, the lettering turned away from camera, the bell above it dead still. NO readable text.", []),
    "n3-thanh-level":  ("pharmacy", f"CLOSE-UP, evening. {CAST['thanh']}, all the kindness still in the face but the eyes level now, setting the terms of a thing that never happened.", ["thanh"]),
    "n3-number-said":  ("pharmacy", f"TIGHT TWO-SHOT, evening. {CAST['thanh']} and {CAST['mehta']} close over the counter, one man saying something once, the other receiving it like a diagnosis.", ["thanh", "mehta"]),
    "n3-two-memorize": ("pharmacy", f"WIDE SHOT, evening. The two men standing still in the aisle light among the shelves, facing each other, nothing in their hands, nothing being written.", ["thanh", "mehta"]),
    "n3-vitamins":     ("pharmacy", "MEDIUM SHOT, evening. The vitamin aisle: orderly shelves of bottles in fluorescent light, labels soft and unreadable, the dead-quiet geometry of a closed store.", []),
    "n3-thanh-warns":  ("pharmacy", f"MEDIUM CLOSE SHOT, evening. {CAST['thanh']} giving instructions with a pharmacist's precision — dosage cadence, no drama, eyes making sure each line lands.", ["thanh"]),
    "n3-aisle-walk":   ("pharmacy", f"WIDE SHOT, evening. {CAST['thanh']} walking down the second aisle away from camera, certain of the shelf he wants, the store his body knows in the dark.", ["thanh"]),
    "n3-tablets-hand": (None, "CLOSE SHOT, evening. A small pharmacy box being placed into a man's open palm, the giver's hand steady, the receiver's hand not yet closing.", []),
    "n3-tablets-thumb": (None, "EXTREME CLOSE-UP, evening. A man's thumb moving once across the face of a small box of tablets — the whole goodbye conducted in one gesture. NO readable text on the box.", []),
    "n3-mehta-pay":    ("pharmacy", f"CLOSE-UP, evening. {CAST['mehta']}, formal again for one sentence, offering to make gratitude contractual.", ["mehta"]),
    "n3-thanh-kindly": ("pharmacy", f"CLOSE-UP, evening. {CAST['thanh']} declining payment the way he says take with food — kindness with a deniability clause inside it.", ["thanh"]),
    "n3-door-unlock":  ("pharmacy", f"MEDIUM SHOT, evening. {CAST['thanh']} turning the deadbolt and opening the glass door for his customer, the lot gone gold outside.", ["thanh"]),
    "n3-dog-warning":  ("pharmacy", f"CLOSE-UP, evening. {CAST['thanh']} in the open doorway, delivering the one hard sentence — the girl takes the dog — with no kindness in the voice and all of it in the words.", ["thanh"]),
    "n3-bell-leave":   ("pharmacy", f"MEDIUM SHOT, evening. {CAST['mehta']} going out under the bell, a customer leaving a pharmacy, nothing more, the gold light taking him.", ["mehta"]),
    "n3-bike-wobble":  ("pharmacy", f"WIDE SHOT, evening, through the glass: the bicycle wobbling off the curb and away, {CAST['dog']} riding high in the basket, ears up, the lot long with shadows.", ["dog"]),
    "n3-lights-buzz":  ("pharmacy", f"WIDE SHOT, evening. {CAST['thanh']} alone behind his counter in the empty store, fluorescent hum almost visible, the pickup wall of stapled white bags keeping its names behind him.", ["thanh"]),
    "n3-dinner-wide":  ("nkitchen", f"MEDIUM WIDE SHOT, night. The kitchen table: {CAST['thanh']} and {CAST['hoa']} — her hair piece is a molded SILVER-GRAY bob, the same silver-gray as her portrait — at dinner, serving dishes between them, a phone propped against the rice cooker glowing mid-call.", ["hoa", "thanh"]),
    "n3-phone-speaker": ("nkitchen", "CLOSE-UP, night. A smartphone propped against a rice cooker on a kitchen table, screen glowing with an active call, steam from the dishes drifting past it. NO readable text on screen.", []),
    "n3-thanh-eats":   ("nkitchen", f"MEDIUM CLOSE SHOT, night. {CAST['thanh']} eating slowly, complimenting the food with his eyes somewhere else entirely.", ["thanh"]),
    "n3-hoa-watches":  ("nkitchen", f"CLOSE-UP, night. {CAST['hoa']} across the table, watching her husband over the serving dishes, thirty years of addition behind her eyes.", ["hoa"]),
    "n3-thanh-phone-dinner": ("nkitchen", f"MEDIUM SHOT, night. {CAST['thanh']} speaking toward the propped phone, pleasant and final, a man closing a clinic visit.", ["thanh"]),
    "n3-spoon":        ("nkitchen", f"EXTREME CLOSE-UP, night, tabletop level: a single metallic LEGO spoon utensil piece lying perfectly flat on the brick-built dinner table beside a small dish piece, warm lamp light, shallow focus; in the soft background beyond it, {CAST['hoa']} — molded SILVER-GRAY bob hair piece — seated with her arms lowered, the moment after.", ["hoa"]),
}

CARDS = {"card-ch1": ("I", ""), "card-ch2": ("II", "EIGHTEEN MONTHS EARLIER"),
         "card-ch3": ("III", "")}


def _save_png(path: str, data: bytes) -> None:
    """Gemini sometimes returns JPEG bytes; normalize to real PNG on disk."""
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    if data[:2] == b"\xff\xd8":
        from PIL import Image
        import io as _io
        Image.open(_io.BytesIO(data)).save(path, "PNG")
    else:
        open(path, "wb").write(data)


LEGO_STYLE = (
    "A frame of stylized 3D LEGO animation in which EVERY SINGLE THING WITHOUT "
    "EXCEPTION is built from glossy plastic LEGO bricks and pieces: the ground "
    "is LEGO baseplates, roads are gray LEGO plates, the sky is the animated "
    "world's simple gradient backdrop, trees and plants are molded LEGO "
    "foliage pieces, vehicles are brick-built LEGO cars, animals are molded "
    "LEGO animal figures, food and bottles and shelf goods are tiny LEGO "
    "brick and tile pieces, furniture and walls and windows are brick-built. "
    "Characters are LEGO MINIFIGURES with molded hair pieces and printed "
    "faces and torsos. All signs and labels and screens are BLANK plastic "
    "tiles with no printing. Bright clean toy-plastic colors, crisp studs "
    "everywhere, cinematic staging and lighting rendered entirely inside this "
    "all-plastic animated world. ABSOLUTELY NO TEXT anywhere, no letters, no "
    "logos. Composed like a competent feature film: one clear subject, "
    "rule-of-thirds placement, correct eyelines, real depth."
)


def _seedream_generate(prompt: str, refs: list[str] | None) -> bytes:
    """Seedream 4 on Replicate (submit + poll; its renders outrun Prefer:wait)."""
    import base64
    import json as _json
    import time as _time
    import urllib.request
    token = open(os.path.expanduser("~/.replicate_api_key")).read().strip()
    image_input = ["data:image/png;base64," + base64.b64encode(open(r, "rb").read()).decode()
                   for r in (refs or [])]
    body = {"input": {"prompt": prompt, "aspect_ratio": "16:9", "size": "2K"}}
    if image_input:
        body["input"]["image_input"] = image_input
    pred = None
    for attempt in range(6):
        req = urllib.request.Request(
            "https://api.replicate.com/v1/models/bytedance/seedream-4/predictions",
            headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
            data=_json.dumps(body).encode())
        try:
            with urllib.request.urlopen(req, timeout=120) as r:
                pred = _json.load(r)
            break
        except urllib.error.HTTPError as e:
            if e.code == 429 and attempt < 5:
                _time.sleep(10 * (attempt + 1))
                continue
            raise
    pid = pred["id"]
    for _ in range(60):
        _time.sleep(4)
        q = urllib.request.Request(f"https://api.replicate.com/v1/predictions/{pid}",
                                   headers={"Authorization": f"Bearer {token}"})
        with urllib.request.urlopen(q, timeout=60) as r:
            pred = _json.load(r)
        if pred["status"] in ("succeeded", "failed", "canceled"):
            break
    if pred["status"] != "succeeded":
        raise RuntimeError(f"seedream {pred['status']}: {str(pred.get('error'))[:200]}")
    out = pred["output"]
    url = out if isinstance(out, str) else out[0]
    with urllib.request.urlopen(url, timeout=120) as r:
        return r.read()


def _replicate_generate(prompt: str, refs: list[str] | None, model: str | None) -> bytes:
    """Same Google models, Replicate billing — no project quota. Maps FLASH ->
    google/nano-banana, pro -> google/nano-banana-pro."""
    import base64
    import json as _json
    import urllib.request
    token = open(os.path.expanduser("~/.replicate_api_key")).read().strip()
    slug = "google/nano-banana" if model == FLASH else "google/nano-banana-pro"
    image_input = ["data:image/png;base64," + base64.b64encode(open(r, "rb").read()).decode()
                   for r in (refs or [])]
    body = {"input": {"prompt": prompt, "aspect_ratio": "16:9", "output_format": "png"}}
    if image_input:
        body["input"]["image_input"] = image_input
    import time as _time
    pred = None
    for attempt in range(7):
        req = urllib.request.Request(
            f"https://api.replicate.com/v1/models/{slug}/predictions",
            headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json",
                     "Prefer": "wait"},
            data=_json.dumps(body).encode())
        try:
            with urllib.request.urlopen(req, timeout=300) as r:
                pred = _json.load(r)
            break
        except urllib.error.HTTPError as e:
            detail = e.read()[:200].decode(errors="replace")
            if e.code == 429 and attempt < 6:
                _time.sleep(12 * (attempt + 1))
                continue
            raise RuntimeError(f"replicate HTTP {e.code}: {detail}") from e
    _time.sleep(1.5)  # pace the batch under the account rate limit
    if pred.get("status") != "succeeded":
        raise RuntimeError(f"replicate {pred.get('status')}: {str(pred.get('error'))[:200]}")
    out = pred["output"]
    url = out if isinstance(out, str) else out[0]
    for attempt in range(5):
        try:
            with urllib.request.urlopen(url, timeout=120) as r:
                return r.read()
        except urllib.error.HTTPError as e:
            if e.code in (429, 500, 502, 503) and attempt < 4:
                _time.sleep(8 * (attempt + 1))
                continue
            raise RuntimeError(f"replicate delivery HTTP {e.code}") from e


def _generate(prompt: str, key: str, refs: list[str] | None = None,
              model: str | None = None) -> bytes:
    if os.environ.get("IMAGE_BACKEND") == "replicate":
        return _replicate_generate(prompt, refs, model)
    return generate(prompt, key, refs=refs, model=model)


def chapters() -> list[tuple[str, str, list, dict]]:
    return [("ch1", "Chapter One.", CH1, FRAMES_CH1),
            ("ch2", "Chapter Two. Eighteen months earlier.", CH2, FRAMES_CH2),
            ("ch3", "Chapter Three.", CH3, FRAMES_CH3)]


def style_mode() -> str:
    return os.environ.get("STYLE_MODE", "graphite")


def style_block() -> str:
    return LEGO_STYLE if style_mode() == "lego" else STYLE


def frame_path(fid: str) -> str:
    if style_mode() == "lego" and not fid.startswith("card-"):
        d = os.environ.get("LEGO_DIR", f"{SB}/lego")
        return f"{d}/{fid}.png"
    return f"{os.environ.get('SB_DIR', SB)}/{fid}.png"


def build_perf() -> tuple[dict, dict]:
    """Emit performance JSON + shotlist in the heir renderers' formats."""
    segments, shots = [], {}
    for ch, card_text, shotlist, _frames in chapters():
        if not shotlist:
            continue
        segments.append({"scene": f"{ch}card", "frame": f"{ch}card",
                         "speaker": "NARRATOR", "text": card_text})
        shots[str(len(segments) - 1)] = frame_path(f"card-{ch}")
        para = 0
        for item in shotlist:
            if item == PARA:
                para += 1
                continue
            spec, text, tag = item
            segments.append({"scene": f"{ch}p{para:03d}", "frame": f"{ch}p{para:03d}",
                             "speaker": "NARRATOR", "text": tag + text})
            idx = str(len(segments) - 1)
            if isinstance(spec, str):
                shots[idx] = frame_path(spec)
            else:
                shots[idx] = [[frame_path(f), w] for f, w in spec]
    perf = {
        "title": "INDIVISIBLE — Part One, pilot (ch.1-3)",
        "model_id": "eleven_v3",
        "output_format": "mp3_44100_128",
        "gaps_ms": {"group": 550},
        "cast": {"NARRATOR": {
            "voice": "George", "voice_id": GEORGE,
            "direction": "audiobook narration: measured, dry, unhurried; reports "
                         "emotion, never performs it; dialogue inside narration gets "
                         "only the lightest shift of register"}},
        "segments": segments,
    }
    return perf, {"shots": shots}


def all_frames() -> dict:
    out: dict = {}
    for _ch, _card, _shots, frames in chapters():
        out.update(frames)
    return out


def estimate() -> None:
    perf, shotlist = build_perf()
    total_w = sum(len(s["text"].split()) for s in perf["segments"])
    cuts = sum(len(v) if isinstance(v, list) else 1 for v in shotlist["shots"].values())
    worst = 0.0
    for i, s in enumerate(perf["segments"]):
        spec = shotlist["shots"][str(i)]
        dur = len(s["text"].split()) / WPS
        if isinstance(spec, list):
            wsum = sum(w for _, w in spec)
            worst = max(worst, max(dur * w / wsum for _, w in spec))
        else:
            worst = max(worst, dur)
    print(f"{len(perf['segments'])} segments, {total_w} words "
          f"(~{total_w/WPS/60:.1f} min), {cuts} cuts, {len(all_frames())} unique frames, "
          f"worst estimated hold {worst:.1f}s")


def write_perf() -> None:
    os.makedirs(PERF_DIR, exist_ok=True)
    perf, shotlist = build_perf()
    json.dump(perf, open(f"{PERF_DIR}/pilot.performance.json", "w"), indent=1)
    json.dump(shotlist, open(f"{PERF_DIR}/pilot.shotlist.json", "w"), indent=1)
    estimate()
    print(f"-> {PERF_DIR}/pilot.performance.json + pilot.shotlist.json")


def gen_sheets(only: str | None = None) -> None:
    key = open(os.path.expanduser("~/.gemini_api_key")).read().strip()
    os.makedirs(f"{SB}/sheets", exist_ok=True)
    for name, desc in CAST.items():
        if only and name != only:
            continue
        path = f"{SB}/sheets/{name}.png"
        if os.path.exists(path):
            print(f"skip {path}")
            continue
        prompt = (f"{STYLE} CHARACTER REFERENCE PORTRAIT: a single medium-close bust "
                  f"portrait against a plain neutral background, subject facing camera, "
                  f"even soft light, no scenery. {desc}.")
        t = time.time()
        _save_png(path, _generate(prompt, key, model=FLASH if os.environ.get("FORCE_FLASH") else None))
        print(f"sheet {name}  ({time.time()-t:.0f}s)")


def gen_setsheets(only: str | None = None) -> None:
    """Route A: a production-design SET SHEET per location — one page, six panels
    (plan, two elevations, three eye-level corners) of the SAME geometry. Passed
    as a ref with every frame shot in that location."""
    key = open(os.path.expanduser("~/.gemini_api_key")).read().strip()
    os.makedirs(f"{SB}/sheets", exist_ok=True)
    for loc, canon in LOC.items():
        if only and loc != only:
            continue
        path = f"{SB}/sheets/set-{loc}.png"
        if os.path.exists(path):
            print(f"skip {path}")
            continue
        prompt = (f"{STYLE} PRODUCTION-DESIGN SET SHEET: one page divided into six "
                  f"panels in a 3x2 grid, all six showing THE SAME single location "
                  f"with perfectly consistent geometry: top row — an overhead floor "
                  f"plan, a front elevation, a side elevation; bottom row — three "
                  f"eye-level views from three different corners of the space. "
                  f"{canon}")
        png = _generate(prompt, key, model=FLASH if os.environ.get("FORCE_FLASH") else None)
        _save_png(path, png)
        print(f"set sheet {loc}")


def gen_cards() -> None:
    from PIL import Image, ImageDraw, ImageFont
    W, H = 2752, 1536   # native; downscales cleanly for the compat cuts
    didot = "/System/Library/Fonts/Supplemental/Didot.ttc"
    for fid, spec in CARDS.items():
        numeral, subtitle = spec if isinstance(spec, tuple) else (spec, "")
        img = Image.new("RGB", (W, H), (8, 8, 8))
        d = ImageDraw.Draw(img)
        nfont = ImageFont.truetype(didot, 360)
        nb = d.textbbox((0, 0), numeral, font=nfont)
        d.text(((W - nb[2] + nb[0]) / 2, H / 2 - (300 if subtitle else 210)),
               numeral, fill=(214, 210, 196), font=nfont)
        if subtitle:
            sfont = ImageFont.truetype(didot, 92)
            track = int(92 * 0.34)
            widths = [(d.textbbox((0, 0), c, font=sfont)[2] if c != " " else int(92 * 0.4))
                      for c in subtitle]
            total = sum(widths) + track * (len(subtitle) - 1)
            cx = (W - total) // 2
            sy = H / 2 + 200
            rule_w = int(total * 1.06)
            d.line([((W - rule_w) // 2, sy - 60), ((W + rule_w) // 2, sy - 60)],
                   fill=(150, 144, 128), width=2)
            for c, w in zip(subtitle, widths):
                d.text((cx, sy), c, font=sfont, fill=(198, 190, 170))
                cx += w + track
        img.save(frame_path(fid))
        print(f"card {fid}")


def gen_frames(lo: int = 1, hi: int = 10 ** 6) -> None:
    key = open(os.path.expanduser("~/.gemini_api_key")).read().strip()
    os.makedirs(SB, exist_ok=True)
    frames = all_frames()
    masters = {"homestead": frame_path("c1-establish"),
               "bonusroom": frame_path("c2-bonus-brad"),
               "fenceyard": frame_path("c2-yard-kids"),
               "hangar": frame_path("c3-hangar-wide"),
               "strip": frame_path("c3-strip-dark"),
               "betos": frame_path("c3-landing-betos"),
               "cockpit": frame_path("c3-cockpit-doctor"),
               "pharmacy": frame_path("n3-pharm-wide"),
               "nkitchen": frame_path("n3-dinner-wide")}
    order = list(frames.items())
    for i, (fid, spec) in enumerate(order, 1):
        loc, tail, refs = spec[0], spec[1], spec[2]
        anchor = spec[3] if len(spec) > 3 else None
        if not (lo <= i <= hi):
            continue
        path = frame_path(fid)
        if os.path.exists(path):
            continue
        prompt = style_block() + " " + (LOC[loc] + " " if loc else "") + tail
        clay = f"{SB}/clay/{fid}.png"
        staged = fid in STAGED and os.path.exists(clay)
        ref_paths = [clay] if staged else []   # figure-clay leads on staged shots
        ref_paths += [f"{SB}/sheets/{r}.png" for r in refs
                      if os.path.exists(f"{SB}/sheets/{r}.png")]
        master = masters.get(loc or "")
        if master and os.path.exists(master) and master != path and not staged:
            ref_paths.append(master)
        setsheet = f"{SB}/sheets/set-{loc}.png" if loc else ""
        if setsheet and os.path.exists(setsheet):
            ref_paths.append(setsheet)
        if os.path.exists(clay) and not staged:
            ref_paths.append(clay)
        if anchor and os.path.exists(frame_path(anchor)):
            ref_paths.append(frame_path(anchor))
            prompt += (" One attached reference is THE SAME SCENE moments away: "
                       "the same people in the same clothes in the same positions "
                       "— keep their identities, wardrobe and blocking EXACTLY, "
                       "changing only what this shot's description changes.")
        if ref_paths:
            if style_mode() == "lego":
                prompt += (" The attached PORTRAIT references are character canon: "
                           "render each as a LEGO MINIFIGURE whose hair piece, "
                           "printed face and torso match that portrait's person, "
                           "kept EXACTLY consistent across shots. Any attached "
                           "location frame fixes the geography. If a gray 3D clay "
                           "render is attached it is THIS SHOT'S exact camera and "
                           "layout: match it precisely, rebuilt in LEGO.")
            else:
                prompt += (" Use the attached reference images as canon: the portrait "
                           "sheets fix each character's face and build; keep them "
                           "EXACTLY consistent. Any attached location frame or "
                           "multi-panel set sheet fixes the geography of the place. "
                           "If a gray 3D clay render is attached, it is THIS SHOT'S "
                           "exact camera and geometry: match its layout, perspective "
                           "and object positions precisely while rendering in the "
                           "storyboard style.")
        t = time.time()
        model = (FLASH if os.environ.get("FORCE_FLASH")
                 else None if os.environ.get("FORCE_PRO")
                 else (None if refs else FLASH))
        for attempt in range(3):
            try:
                if style_mode() == "lego":
                    if os.environ.get("LEGO_BACKEND") == "pro":
                        png = _replicate_generate(prompt, ref_paths or None, None)
                    else:
                        png = _seedream_generate(prompt, ref_paths or None)
                else:
                    png = _generate(prompt, key, refs=ref_paths or None, model=model)
                _save_png(path, png)
                break
            except Exception as e:  # noqa: BLE001 — safety blocks etc; retry softened
                if attempt == 2:
                    print(f"FAIL {fid}: {e}")
                else:
                    time.sleep(4)
        else:
            continue
        print(f"[{i}/{len(order)}] {fid}  ({time.time()-t:.0f}s)")


def validate() -> None:
    """Re-derive every visual hold exactly as heir_video will, assert <= 10s."""
    from examples.heir_video import groups_of
    perf = json.load(open(f"{PERF_DIR}/pilot.performance.json"))
    manifest = json.load(open(f"{PERF_DIR}/pilot.manifest.json"))
    shots = json.load(open(f"{PERF_DIR}/pilot.shotlist.json"))["shots"]
    groups = groups_of(perf)
    assert len(groups) == len(manifest), "group mismatch — re-render audio"
    cuts: list[tuple[str, float]] = []
    for g, m in zip(groups, manifest):
        total = sum(len(s["text"]) for _, s in g) or 1
        for j, (i, seg) in enumerate(g):
            hold = m["duration"] * len(seg["text"]) / total
            if j == len(g) - 1:
                hold += m.get("gap_after_ms", 0) / 1000.0
            spec = shots.get(str(i), seg.get("frame"))
            if isinstance(spec, list):
                wsum = sum(w for _, w in spec) or 1
                cuts.extend((f, hold * w / wsum) for f, w in spec)
            else:
                cuts.append((spec, hold))
    merged: list[list] = []
    for f, h in cuts:
        if merged and merged[-1][0] == f:
            merged[-1][1] += h
        else:
            merged.append([f, h])
    over = [(f, h) for f, h in merged if h > 10.0]
    missing = sorted({f for f, _ in merged if not os.path.exists(f)})
    print(f"{len(merged)} cuts; longest {max(h for _, h in merged):.1f}s; "
          f"shortest {min(h for _, h in merged):.1f}s")
    for f, h in sorted(over, key=lambda x: -x[1]):
        print(f"  OVER 10s: {h:5.1f}s  {os.path.basename(f)}")
    for f in missing:
        print(f"  MISSING FRAME: {f}")
    if not over and not missing:
        print("OK: every visual <= 10.0s and every frame exists")


def _assemble_xfade(items: list, res: str, crf: str, aud: str, out: str, T: float) -> None:
    """Assemble with a short cross-dissolve at every cut, audio-synced. Each clip
    is extended by T and the transition is centered on the original cut boundary,
    so the holds (and the narration timing) are preserved."""
    import subprocess
    W, H = res.split(":")
    holds = [h for _, h in items]
    cmd = ["ffmpeg", "-nostdin", "-loglevel", "error", "-y"]
    for frame, hold in items:
        cmd += ["-loop", "1", "-t", f"{hold + T:.3f}", "-i", os.path.abspath(frame)]
    cmd += ["-i", aud]
    parts = [f"[{i}:v]fps=30,scale={W}:{H}:flags=lanczos,setsar=1,format=yuv420p[v{i}]"
             for i in range(len(items))]
    prev, B = "v0", 0.0
    for j in range(len(items) - 1):
        B += holds[j]
        tj = max(0.05, min(T, holds[j] * 0.7, holds[j + 1] * 0.7))  # fit short cuts
        lbl = "vout" if j == len(items) - 2 else f"x{j+1}"
        parts.append(f"[{prev}][v{j+1}]xfade=transition=fade:duration={tj:.3f}:"
                     f"offset={B - tj/2:.3f}[{lbl}]")
        prev = lbl
    cmd += ["-filter_complex", ";".join(parts), "-map", "[vout]", "-map", f"{len(items)}:a",
            "-c:v", "libx264", "-pix_fmt", "yuv420p", "-preset", "fast", "-crf", crf,
            "-c:a", "aac", "-b:a", "160k", "-ar", "48000", "-shortest",
            "-movflags", "+faststart", out]
    subprocess.run(cmd, check=True)


def chapter_video(ch: str, out: str) -> None:
    """Assemble ONE chapter's video: chapter cuts + the matching audio span."""
    import subprocess
    from examples.heir_video import groups_of
    perf = json.load(open(f"{PERF_DIR}/pilot.performance.json"))
    manifest = json.load(open(f"{PERF_DIR}/pilot.manifest.json"))
    shots = json.load(open(f"{PERF_DIR}/pilot.shotlist.json"))["shots"]
    groups = groups_of(perf)
    assert len(groups) == len(manifest), "group mismatch — re-render audio"

    offset, span, cuts = 0.0, 0.0, []
    for g, m in zip(groups, manifest):
        glen = m["duration"] + m.get("gap_after_ms", 0) / 1000.0
        scene = g[0][1]["scene"]
        if not scene.startswith(ch):
            if not cuts:
                offset += glen
            continue
        span += glen
        total = sum(len(s["text"]) for _, s in g) or 1
        for j, (i, seg) in enumerate(g):
            hold = m["duration"] * len(seg["text"]) / total
            if j == len(g) - 1:
                hold += m.get("gap_after_ms", 0) / 1000.0
            spec = shots.get(str(i), seg.get("frame"))
            if isinstance(spec, list):
                wsum = sum(w for _, w in spec) or 1
                cuts.extend((f, hold * w / wsum) for f, w in spec)
            else:
                cuts.append((spec, hold))
    merged: list[list] = []
    for f, h in cuts:
        if merged and merged[-1][0] == f:
            merged[-1][1] += h
        else:
            merged.append([f, h])
    over = [(f, h) for f, h in merged if h > 10.0]
    missing = [f for f, _ in merged if not os.path.exists(f)]
    assert not over, f"holds over 10s: {over}"
    assert not missing, f"missing frames: {missing}"

    framedir = os.environ.get("FRAME_DIR")
    if framedir:
        remapped = []
        for f, h in merged:
            cand = os.path.join(framedir, os.path.basename(f))
            remapped.append([cand if os.path.exists(cand) else f, h])
        merged = remapped
    black = f"{SB}/black.png"
    if not os.path.exists(black):
        from PIL import Image
        Image.new("RGB", (1376, 768), (0, 0, 0)).save(black)
    aud = f"{PERF_DIR}/{ch}.mp3"
    subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y",
                    "-ss", f"{offset:.3f}", "-t", f"{span:.3f}",
                    "-i", f"{PERF_DIR}/pilot.mp3",
                    "-codec:a", "libmp3lame", "-b:a", "96k", aud], check=True)
    res = os.environ.get("VIDEO_RES", "1376:768")   # native frames are 2752:1536
    crf = os.environ.get("VIDEO_CRF", "26")
    xfade = float(os.environ.get("XFADE", "0"))     # seconds of cross-dissolve per cut
    if xfade > 0:
        _assemble_xfade(merged + [[black, 1.0]], res, crf, aud, out, xfade)
    else:
        lst = out + ".frames.txt"
        with open(lst, "w") as f:
            for frame, hold in merged:
                f.write(f"file '{os.path.abspath(frame)}'\nduration {hold:.3f}\n")
            f.write(f"file '{os.path.abspath(black)}'\nduration 1.0\n"
                    f"file '{os.path.abspath(black)}'\n")
        subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y",
                        "-f", "concat", "-safe", "0", "-i", lst, "-i", aud,
                        "-vf", f"scale={res}:flags=lanczos,format=yuv420p", "-fps_mode", "vfr",
                        "-c:v", "libx264", "-tune", "stillimage", "-preset", "slow", "-crf", crf,
                        "-c:a", "aac", "-b:a", "160k", "-movflags", "+faststart", out], check=True)
        os.remove(lst)
    print(f"{out}: {len(merged)} cuts, {span/60:.1f} min, "
          f"longest hold {max(h for _, h in merged):.1f}s, "
          f"{os.path.getsize(out)/1e6:.1f} MB")


def gen_one(fid: str) -> None:
    """Regenerate a single frame by id, exactly as gen_frames builds it."""
    key = open(os.path.expanduser("~/.gemini_api_key")).read().strip()
    spec = all_frames()[fid]
    loc, tail, refs = spec[0], spec[1], spec[2]
    anchor = spec[3] if len(spec) > 3 else None
    masters = {"homestead": frame_path("c1-establish"),
               "bonusroom": frame_path("c2-bonus-brad"),
               "fenceyard": frame_path("c2-yard-kids"),
               "hangar": frame_path("c3-hangar-wide"),
               "strip": frame_path("c3-strip-dark"),
               "betos": frame_path("c3-landing-betos"),
               "cockpit": frame_path("c3-cockpit-doctor"),
               "pharmacy": frame_path("n3-pharm-wide"),
               "nkitchen": frame_path("n3-dinner-wide")}
    prompt = style_block() + " " + (LOC[loc] + " " if loc else "") + tail
    ref_paths = [f"{SB}/sheets/{r}.png" for r in refs
                 if os.path.exists(f"{SB}/sheets/{r}.png")]
    master = masters.get(loc or "")
    if master and os.path.exists(master) and master != frame_path(fid):
        ref_paths.append(master)
    setsheet = f"{SB}/sheets/set-{loc}.png" if loc else ""
    if setsheet and os.path.exists(setsheet):
        ref_paths.append(setsheet)
    clay = f"{SB}/clay/{fid}.png"
    if os.path.exists(clay):
        ref_paths.append(clay)
    if anchor and os.path.exists(frame_path(anchor)):
        ref_paths.append(frame_path(anchor))
        prompt += (" One attached reference is THE SAME SCENE moments away: keep "
                   "identities, wardrobe and blocking EXACTLY, changing only what "
                   "this shot's description changes.")
    if ref_paths:
        prompt += (" Use the attached reference images as canon: the portrait "
                   "sheets fix each character's face and build; keep them "
                   "EXACTLY consistent. Any attached location frame or "
                   "multi-panel set sheet fixes the geography of the place. "
                   "If a gray 3D clay render is attached, it is THIS SHOT'S "
                   "exact camera and geometry: match its layout, perspective "
                   "and object positions precisely while rendering in the "
                   "storyboard style.")
    if style_mode() == "lego":
        if os.environ.get("LEGO_BACKEND") == "pro":
            png = _replicate_generate(prompt, ref_paths or None, None)
        else:
            png = _seedream_generate(prompt, ref_paths or None)
    else:
        png = _generate(prompt, key, refs=ref_paths or None,
                        model=(FLASH if os.environ.get("FORCE_FLASH")
                               else None if os.environ.get("FORCE_PRO")
                               else (None if refs else FLASH)))
    _save_png(frame_path(fid), png)
    print(f"regenerated {fid}")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "estimate"
    if cmd == "perf":
        write_perf()
    elif cmd == "sheets":
        gen_sheets(sys.argv[2] if len(sys.argv) > 2 else None)
    elif cmd == "cards":
        gen_cards()
    elif cmd == "frames":
        gen_frames(int(sys.argv[2]) if len(sys.argv) > 2 else 1,
                   int(sys.argv[3]) if len(sys.argv) > 3 else 10 ** 6)
    elif cmd == "validate":
        validate()
    elif cmd == "chapter":
        chapter_video(sys.argv[2], sys.argv[3])
    elif cmd == "one":
        gen_one(sys.argv[2])
    elif cmd == "setsheets":
        gen_setsheets(sys.argv[2] if len(sys.argv) > 2 else None)
    else:
        estimate()
