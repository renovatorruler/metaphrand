# Ep2 spotting sheet — one mood brief per scene (SCORE_FRAMEWORK method).
# kind: "gen" (bespoke ElevenLabs cue to scene length) | "rudaali" (locked theme, featured)
#       | "have" (reuse an already-generated cue) | "silence" (room tone, no cue)
# lvl = mix level (much-softer template); lp = lowpass (darken/recede); win = (offset_s, dur_s) featured placement.

SUF = (" North Indian / Malwa instrumental palette, acoustic sarangi, harmonium, nagara, algoza flute, tanpura. "
       "Extremely sparse and spacious, very soft, ambient film underscore that sits far beneath dialogue, "
       "slow, free-floating and rhythmless, unresolved.")

SPOTS = {
 1:  {"kind":"rudaali", "lvl":0.09, "lp":6000, "win":(0,37)},
 2:  {"kind":"silence"},  # title sequence (own music)
 3:  {"kind":"gen", "lvl":0.08, "lp":5200, "brief":
      "A farmhouse verandah court at dusk. A genial political boss holds his little court; one old farmer "
      "stands and will not bow. A warm folk benediction on sweet sarangi and harmonium, almost a blessing, "
      "over a low sustained drone — but the drone keeps a faint cold edge, because someone is refusing the sweetness."},
 4:  {"kind":"rudaali", "lvl":0.07, "lp":6000, "win":(0,37)},
 5:  {"kind":"gen", "lvl":0.06, "lp":5000, "brief":
      "A small lamp-lit family room at night. A mother shows off a phone photo, bright and proud; a teenage "
      "girl keeps her eyes down; a tired young constable in the doorway. A gentle algoza folk-flute, warm and "
      "domestic, with a thin thread of unease underneath that the brightness is hiding."},
 6:  {"kind":"have", "cue":"cue_sc6_bespoke", "lvl":0.06, "lp":5000},
 7:  {"kind":"gen", "lvl":0.06, "lp":5000, "brief":
      "A bureaucrat's office. A reasonable voice and a tired refusal pushing against each other. A low "
      "sustained drone with a cold metallic tick entering and receding — pressure dressed as courtesy, the "
      "system leaning quietly on a man."},
 8:  {"kind":"gen", "lvl":0.07, "lp":5000, "brief":
      "A trader bands bricks of banknotes at a low table like a man counting grain; a silent woman watches "
      "from a dark doorway. A cold metallic tick like a weighing-scale over a flat tanpura drone — the machine "
      "that prices everything, indifferent and steady."},
 9:  {"kind":"gen", "lvl":0.07, "lp":5000, "brief":
      "Hard daylight outside a checkpost. A thick false warmth, an arm dropped around a shoulder, a flat-eyed "
      "enforcer a step behind. A warm phrase gone slightly sour over a low threatening drone — friendliness "
      "with a knife under it."},
 10: {"kind":"silence"},  # the immovable clerk — dialogue carries it
 11: {"kind":"rudaali", "lvl":0.10, "lp":6000, "win":(8,37)},
 12: {"kind":"gen", "lvl":0.06, "lp":5000, "brief":
      "A bare bulb over parked tempos, deep night. A quiet, careful transaction in the dark. A low drone with "
      "a faint cold tick, tense and hushed, holding its breath."},
 13: {"kind":"gen", "lvl":0.07, "lp":5200, "brief":
      "A green watered lawn glowing amid dry cracked land at twilight, armed men loitering. A low sustained "
      "drone with a sweet folk phrase trying to rise over it — the velvet ravine, beautiful and wrong, as the gate opens."},
 14: {"kind":"gen", "lvl":0.08, "lp":5400, "brief":
      "A wide verandah, a host rising with open arms. A warm folk benediction on sweet sarangi and harmonium, "
      "almost a blessing, over a low sustained drone. Pure public sweetness — the horror is that it is genuinely lovely."},
 15: {"kind":"gen", "lvl":0.07, "lp":5200, "brief":
      "An intimate offer of opium-water, the old courtesy that cannot be refused. The sweet benediction phrase, "
      "close and warm, over a low drone, with a faint narcotic heaviness slowing everything down."},
 16: {"kind":"gen", "lvl":0.08, "lp":5200, "brief":
      "A soft, intimate offer made across a warm lamp. The sweet benediction phrase, but the drone underneath "
      "begins to detune, one wrong interval surfacing — the warmth starting to curdle as the real proposition lands."},
 17: {"kind":"gen", "lvl":0.08, "lp":5000, "brief":
      "A man stands to leave, having refused. For one instant the host's warm mask is gone — the sweet phrase "
      "collapses into a cold detuned drone, something patient and measuring looking out of the dark."},
 18: {"kind":"gen", "lvl":0.05, "lp":4800, "brief":
      "A jeep on a dry field road, a green gate shrinking behind, parched fields under a hard low sun. A lone "
      "algoza flute, weary and thin, over cold ambience — the land beautiful and rotten, a man driving away "
      "from something he could not fix."},
 19: {"kind":"gen", "lvl":0.09, "lp":5200, "brief":
      "A tempo van running an empty pre-dawn highway with a body in the back; ahead the road is blocked, "
      "headlights closing behind. A low drone tightening, a distant heartbeat quickening, dread gathering — "
      "held tense and low, never breaking into noise."},
 20: {"kind":"gen", "lvl":0.06, "lp":5000, "brief":
      "A smooth man on a telephone feeling his control slip. A low drone with the cold tick faltering, the "
      "confident surface cracking — quiet alarm under a calm voice."},
 21: {"kind":"gen", "lvl":0.05, "lp":4800, "brief":
      "A cold hospital corridor, an exhausted man carrying one end of a wrapped body while no one helps. A "
      "deadened sarangi with no pulse over institutional cold — weariness past grief, a uniform worn by a dead man."},
 22: {"kind":"gen", "lvl":0.07, "lp":5000, "brief":
      "A cold morgue, a steel table and a floor drain, an autopsy beginning on a covered young body. A low "
      "dread drone with a high lonely sarangi threaded through it like a stifled cry — grief held at arm's "
      "length, the room refusing to feel what it is doing."},
 23: {"kind":"gen", "lvl":0.05, "lp":4800, "brief":
      "Almost silence in a steel room. A hard finding spoken flatly. One low cold sustained note enters and "
      "holds, the weight of it settling — nothing more."},
 24: {"kind":"silence"},  # too-bright day after the dark morgue — exhaustion, no music
 25: {"kind":"gen", "lvl":0.05, "lp":5000, "brief":
      "A dusty afternoon. A man quietly sealing an envelope to himself and posting it — insurance no one is "
      "meant to see. A spare low drone with a single wary note, a secret being set down."},
 26: {"kind":"gen", "lvl":0.06, "lp":5000, "brief":
      "A lamp-lit room at night, a brother asking his young sister something gently; she has no answer and "
      "keeps her eyes down. A soft domestic flute with the unease now closer to the surface, a worry that will "
      "not be spoken."},
 27: {"kind":"gen", "lvl":0.06, "lp":5000, "brief":
      "A small night room, a mother's brightness thinning as she tells her son a hard thing. A gentle flute "
      "folding down into a low ache — the worry finally named."},
 28: {"kind":"gen", "lvl":0.06, "lp":4800, "brief":
      "Behind a country-liquor shop at dusk, a gaunt wrecked addict folded against a wall. A hollow, bleak "
      "texture — a thin flute over an empty drone, the human cost of the belt, sparse and grey."},
 29: {"kind":"gen", "lvl":0.05, "lp":5000, "brief":
      "Late night in an office, one desk lamp. A man turning a case over, half aloud. A deadened sarangi "
      "beginning to find small purposeful phrases — the detective in the dead man waking, quiet and stubborn."},
 30: {"kind":"gen", "lvl":0.06, "lp":5000, "brief":
      "Alone at a desk deep in the night, one name on a page and the rest blank. A spare unresolved sarangi "
      "over near-silence, doubt and isolation, a single thread that will not yet connect."},
 31: {"kind":"gen", "lvl":0.06, "lp":5000, "brief":
      "Flat daytime office light, the daily machinery — a file and a fold of cash slid across, signed for, the "
      "money left untouched. The cold metallic tick over a tanpura drone, quieter now, a young man learning "
      "what his old man refused."},
 32: {"kind":"gen", "lvl":0.06, "lp":5400, "brief":
      "Stone steps at the water's edge at dusk, an old friend's hand on a shoulder. A warm, gentle, unhurried "
      "sarangi — the one kind moment, a small human warmth that asks nothing."},
 33: {"kind":"gen", "lvl":0.06, "lp":5000, "brief":
      "A sparse night lane, two men parting at a fork, the older not looking back at the boy. A weary low "
      "sarangi with a thread of tenderness held down — the cost of carrying this alone."},
 34: {"kind":"gen", "lvl":0.07, "lp":5400, "brief":
      "A boss at ease on his swing-seat feeding a caged songbird while a frightened man pleads. The sweet "
      "benediction phrase, calm and unhurried, over a low drone — menace perfectly relaxed, the cage singing in it."},
 35: {"kind":"gen", "lvl":0.07, "lp":4800, "brief":
      "A suspension order set down on a desk; a badge unclipped and laid beside a revolver. A deadened sarangi "
      "sinking under a slow heavy drone — the cost of saying no, grief without self-pity."},
 36: {"kind":"gen", "lvl":0.07, "lp":5400, "brief":
      "A bare dark kitchen, one oil lamp. A wife sits across from her husband for the first time in years and "
      "pushes his plate closer. A fragile warm sarangi, barely daring — a thaw, two people who had stopped, "
      "beginning again, tender and unsure."},
 37: {"kind":"silence"},  # the anteroom, the man shut out — institutional cold, dialogue carries
 38: {"kind":"gen", "lvl":0.07, "lp":5200, "brief":
      "Across a dark field a big lit haveli glows; two men out of uniform stand in the black watching it. A "
      "low nagara heartbeat strengthening under a held sarangi line — resolve gathering in the dark, patient "
      "and dangerous."},
 39: {"kind":"gen", "lvl":0.10, "lp":6000, "brief":
      "A lone man walks a dark empty road through the sleeping poppy belt toward a single far light. A gathering "
      "motif — a deepening nagara heartbeat under a defiant, slowly rising sarangi, the one who walks on; "
      "restrained and building, proud and unresolved, the only cue allowed to swell."},
}
