# Codex ImageGen prompt package

Generation mode: Codex built-in ImageGen, one 16:9 production still per call, with local reference images. No external generation service is required.

For regeneration, concatenate the relevant world lock, the frame delta, and that world's negative lock. The resulting three blocks are the final prompt for that frame.

## Performance-world references

Primary continuity image: `canon/mangu_phad_dafli_master_v1.png`.

Original Kark continuity sources used to establish the master:

- `../kark-mv/elements/mangu_c3.png` — canonical Mangu identity and costume.
- `../kark-mv/atape/gpt_daf_mid.png` — dafli construction and grip.
- `../kark-mv/thumbs/bhopa_phad_night.png` — open-field Phad setup.

### Performance world lock

> Create a 16:9 photorealistic cinematic production still of the exact recurring Mangu Bhopa: a weathered Rajasthani man around 55 with a huge upturned black moustache, open salt-and-pepper beard, strong lined face, and saffron-orange Rajasthani safa with the same vertical fan-like turra and wrapped pech. He wears the same deep red silk kurta, white dhoti trousers, layered silver neckpiece, and broad engraved silver cuffs. He is barefoot in a dark open rural field at blue hour before one real hand-painted Phad textile stretched between exactly two rough wooden poles, with one small kerosene lamp on the earth. His only instrument is one round pale-hide dafli with a wooden rim and small red, green, and yellow pom-poms. Preserve the same face, body, clothing, jewelry, dafli, Phad, poles, lamp, warm-on-cool lighting, restrained documentary realism, and natural low-light grain.

### Performance frame deltas

| Frame | Append this shot instruction |
|---|---|
| P01 | Extreme locked-off wide; show his full body, entire Phad, both poles, lamp, dark sky, and empty ground. Mangu sings quietly with the dafli at chest height. |
| P02 | Medium full performance master; composed untrained singing, dafli vertical at chest, one hand resting naturally on the skin, Phad fully legible behind him. |
| P03 | Tight tactile insert from collarbone to waist; face mostly out of frame; both anatomically correct hands, silver cuffs, hide texture, lacing, rim, and pom-poms in sharp focus. |
| P04 | Intimate head-and-shoulders singing close-up; eyes slightly beyond camera; open but unforced mouth; only a small dafli rim at the lower edge; Phad softly defocused. |
| P05 | Medium spoken-coda shot; mouth naturally open for unpitched speech; dafli held lower in the left hand; right arm down and visibly away from the drum; no musical gesture. |
| P06 | Extreme-wide final silence matching P01; lips fully closed; dafli lowered vertically beside the left thigh; right arm empty at his side; inward expression and no performance gesture. |

### Performance negative lock

> No ravanhatta, bow, string instrument, extra drum, audience, second person, duplicated limbs, extra fingers, Sikh-turban silhouette, tucked beard, young face, clean shave, palace, temple, magical portal, battle effect, text, caption, logo, watermark, glossy studio lighting, or modern object.

## Story-world references

Primary continuity image: `canon/old_leader_army_river_master_v1.png`. Use the immediately preceding S-frame as a second reference when advancing the action.

### Story world lock

> Create a 16:9 photorealistic cinematic production still in the exact recurring historical river world. Preserve the same approximately 70-year-old commander with a weathered angular face, short grey beard, large wrapped indigo-black turban, raw off-white cotton kurta and dhoti, faded madder-red quilted vest, and long charcoal-black shawl. He rides the same unarmoured ash-grey horse with worn practical tack and remains the final person in the procession. Ahead is the same small column of weary ordinary foot soldiers in dusty undyed cotton with muted ochre, madder, and indigo turbans, simple spears, a few round dark shields, exactly two laden pack animals, and exactly one plain emblem-free faded madder-red standard. They move consistently from screen-left toward screen-right beside and then across a broad calm river at dusty apricot dusk. The far bank has sparse semi-arid scrub. Use observed historical realism, natural anatomy, subdued color, fine fabric and dust detail, and an emotional tone of departure and acceptance rather than victory.

### Story frame deltas

| Frame | Append this shot instruction |
|---|---|
| S00 | Rear three-quarter story master at the near bank; commander large at left on the grey horse, column and standard ahead descending toward the river, his eyes fixed on the far bank. |
| S01 | Same composition and instant; commander raises one open right palm in a small quiet signal while the line responds; full natural hand anatomy and no other gesture. |
| S02 | Very wide elevated view; the entire line has turned into a diagonal toward the water, standard at the front and commander still last at lower-left. |
| S03 | Clean lateral profile; column walks left-to-right along the riverbank, flag held straight by the wind, two pack animals centered, mounted commander last at far left. |
| S04 | Tight right-facing profile of the commander's face and turban; horse ears at lower-right; river, tiny army, and single standard defocused behind him. |
| S05 | Elevated very wide rear three-quarter view; front ranks and standard calf-deep in a shallow ford, middle and two pack animals entering, commander and grey horse last at the waterline. |
| S06 | Several minutes later; most of the line nears the far bank, standard small at upper-right, commander and horse calf-deep and alone at lower-left, river dominant as empty space. |

### Story negative lock

> No battle, enemy, charge, gallop, weapon raised, heroic pose, splash spectacle, swimming, drowning, deep water, supernatural aura, deity, ghost, palace, fort, bridge, boat, modern object, second standard, emblem, duplicate commander, extra mounted rider, text, caption, logo, or watermark.
