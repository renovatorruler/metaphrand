# EP12 prompt-system audit — design

## Hypothesis verdict

HOLDS, as one of three co-equal mechanisms — not as the whole explanation. The mechanism is exactly what the author described and it is structural, not a habit: KukuEp12_Shots.res:325 `let people = Js.Array2.map(r.cast, w => subjectOf(w, r.doing))` binds ONE row-level string to every cast member, so a character's own SUBJECTS line describes the group or somebody else. Evidence: s33e renders `- KUKU — green paper dragon, small everyday form ... कैस्टर and फ्यूरिया in great form filling the courtyard` under KUKU, LEDA and VESPER alike; s33c renders `five great dragons lifting from the courtyard` five times; the s27 clip receipt says `the five sitting motionless` under all six cast lines; s52's KUKU line is an object (`the glowing golden curve standing before the niche`, :218). Across the 71 rows: 15 rows name no character at all (s10, s14, s26, s27, s31, s33a-f, s48, s52, s53, s55, s66), 20 use a collective (`the five`, `all four`, `the others`, `each child`), 47 use a bare pronoun. Lesson 6 already recorded the outcome of an unnamed group member (`two कैस्टरs and no लेडा`), and s33b rendered eight dragons with no lilac one. Indirect object reference is the same class: `the letter appears` / `column of golden glow` / `the golden letter` are three names for one thing and none is a picture (objects: [] at :341).

What it explains: defect 1 (which board is which role is left to colour matching), defect 5 (scale is asserted collectively and contradicted per line), defect 6 (nobody is told to leave; the group is told to keep position).

What it does NOT explain, and would recur even with perfect per-name prose: defect 3 (lit lamp) — the diya is a NAMED subject with a wick in every shot and its out state is an adjective plus a rule keyed only to `Dark`; defect 4 (style change) — the key swap a34b16f4 → ep12_style_key.png mid-episode, unsent set refs on every clip, and no freshness gate; defect 2 (glyph/beam) — shape nouns (`letter`, `द`, `line`, `column`, `beam`) reach the model although the letter is declared a VFX layer. The per-name rule is therefore necessary (Rule 1-3 below) but the regeneration is only re-spend-proof with the state typing (Rules 4-7), the receipt/freshness stamp (Rules 11-14), and the reference fixes (Rules 9-10) in place as well.

## Diagnosis

Ranked root causes, each tied to what the cut showed.

1. STORY STATE IS PROSE-SHADOWED, NOT TYPED — the same fact is derived in two or three places that disagree (defects 5, 3, 2, 1). Form: every dragon is constructed `P.Dragon({name: P.Kuku, form: P.Small, doing})` (KukuEp12_Shots.res:293-297) while `greatForm = ["s33b", ...]` (:87) bolts a rule on: the s33d receipt carries both `small everyday form: a small paper dragon child, the height of a human child` (five times) and `THE FIVE ARE IN THEIR GREAT FORM: each dragon now stands about seven metres tall`, with the small sheets attached (receipt params: kuku.png, furia.png, leda_small.png, castor.png, vesper_small.png) although `boardOf` already maps `Great` to `ep10prod/elements/future_<name>_board_bracelet.png` (Kuku_PromptSpec.res:300-304). Lamp: `diyaProp(lampLit(r.light))` is emitted for all 71 rows (:327), the hard rule keys on `r.light == Dark` (:346, :390) so the 13 Golden stills get a diya described only as `standing cold and dark` and no rule — s52 rendered a flame; and the out state is an adjective on a named object with a wick, which the model draws lit (s33e, s33d-first-try, s51-s53). Letter: `letterUp` is an id-prefix list (:318-322), `objects: []` (:341) never attaches `elements/letter_da.png`, and one prompt calls it `a standing column of soft golden glow` (SUBJECTS), `the letter द stands complete and burning` (SCENE, from :219 via `scene: r.action`), and `The golden letter is the one source of light` (LIGHTING, :42). Closeups re-derive light by hand thresholds (KukuEp12_Closeups.res:73-86: `if n <= 25 { S.LampNight } else if n <= 50 { S.Dark }`) against a table that says s26 is LampNight (:146).

2. ONE SHARED `doing` IS STAMPED ON EVERY CAST MEMBER, AND A STILL'S SCENE IS THE CLIP'S TIME-SPANNING `action` (defects 1, 5, 6). `let people = Js.Array2.map(r.cast, w => subjectOf(w, r.doing))` (:325, and :370 for clips); row type `cast: array<string>, doing: string` (:72-73); `scene: r.action == "" ? r.doing : r.action` (:334). So s33e's KUKU line reads `- KUKU — green paper dragon, small everyday form ... कैस्टर and फ्यूरिया in great form filling the courtyard`, s33c's five lines each say `five great dragons lifting` (twenty-five dragons named), the s27 clip says `the five sitting motionless` six times, and the s03 still is asked to show `walk forward ... and lower themselves` AND `sit in a half circle`. Fifteen rows name nobody; twenty use a collective. This is the author's hypothesis, and it is real — see verdict.

3. NOTHING IN EP12 CHECKS FRESHNESS, AND THE RECEIPT CANNOT SEE WHAT CHANGED (defects 3, 4, 5, 1). `stills` skips on `existsSync(stillPath(r))` (:457); `clip` calls `receiptIntact(start)` (Kuku_Engine.res:293) which checks hashes only, never `PromptDrift`. Result on disk: s33e_too_big.png.gen.json (2026-09-02T15:19Z) has rules `THE CHILDREN ARE SMALL` and no `LAMP IS OUT`, refs[0] `a34b16f4-... PROVIDER_ASSET`; s33d_thrown_back.png.gen.json (21:43Z) has `THE LAMP IS OUT` + `THE FIVE ARE IN THEIR GREAT FORM`, refs[0] `ep12_style_key.png`. Adjacent frames, two rule states, two style keys, both reported Current. The style key is a mutable global provider id (`styleKeyRef = ref("a34b16f4-...")`, PromptSpec.res:114-117; `refHash = r => isProviderAsset(r) ? "PROVIDER_ASSET:" ++ r` Engine.res:53) so a key swap hashes to a constant; `version = "kuku-engine/1"` (:44) has not changed across four rule states, none committed (`?? studio/src/KukuEp12_Shots.res`). Clip receipts list refs the call never carried: EP12_s33c_they_rise.mp4.gen.json refs = 8 rows including ep12_style_key.png and courtyard_plate.png, params carry only `--start-image` + five `--image-references` (Engine.res:325 builds `refs` from `setRefs`; :328-340 never emits them). Every clip is start frame + boards only while every still is key + plate + boards — the receipt is a false proof.

4. THE ATTACHED REFERENCES ARGUE WITH THE TEXT (defects 1, 3, 4). The five child boards are single 3/4 cards generated 2026-08-28 under the retired paper-theatre key (`charsheets/kuku.png.gen.json`: `exactly one single character, full body, in a friendly relaxed 3/4 pose`, refs `0c47270d-...`), kuku.png carries a white card border, and they disagree in design language (horned/hornless, toddler/adult proportions) — re-breaking PRODUCTION_LESSONS §20. The prompt never maps a board to a name (`Every remaining attached image is a locked character design; match each EXACTLY`, PromptSpec.res:192) and per-character text is one colour word (:132-141). `requireBoards` only checks existence (Engine.res:72-73). पापा and कालू are `P.Prop` (:284-292) so no sheet is attached (s57 receipt: no papa.png) though charsheets/papa.png and kalu.png exist; DADI's line says `paper grandmother bird` (PromptSpec.res:147) against a grey dragon sheet. The single dusk plate is attached second to all 71 shots and, because `shot: P.Medium` is a constant (:335), the clause `identical palette and light` (PromptSpec.res:187) sits beside `LIGHTING: Deep blue darkness` in 50 Dark/Golden shots — the warm-lit niche is the compromise the model found.

5. VOCABULARY NAMES THE THING IT WANTS ABSENT OR STILL (defects 2, 3, 6, 4). Shape nouns reach the model in every letter shot (`column`, `curve`, `upright line`, `letter द`, `wide steady beam` at :226) although :308-311 declares the letter a VFX layer — s52 drew a glyph on a pole, s51/s53 a searchlight shaft, s54 वैस्पर holding a paper letter. The flight is contradicted four ways in its own clip prompt: `cameraTravels: false` (:368), `Everyone in frame keeps the position they hold in the start frame` (:375), `The camera holds completely still throughout` (:378), `--duration 5` because s33 is not in `storyCritical` (:401-408), and no `~endFrame` although the engine accepts one (Engine.res:289). PromptGate.res:20-23 bans only negation words; nothing bans shape nouns, collective nouns, state adjectives, or hold-vs-exit contradictions, and the empty rule branch emits a bare `- ` bullet.

6. REJECTION AND APPROVAL LIVE OUTSIDE THE RECEIPT SYSTEM (defects 7, 4). Rejected assets are hand-renamed (`LITLAMP_s33d_thrown_back.png`, `LANELEAK_...`, `GENLETTER_s54...`, 16 such files in stills/ with no .gen.json) and the assembler reads a hand-curated `stills_final/` (9 pngs, zero receipts). The engine cannot vouch for what the cut is built from, and there is no measured post-generation check for the one state (lamp cold) the show keeps getting wrong — Lesson 10 and Lesson 19 both already say this.

## Rules

### CAST_ENTRY: closed member variant with a per-member pose; no row-level doing  [type]
**where:** studio/src/KukuEp12_Shots.res (row type, :72-73, :293-297, :325, :370); studio/src/Kuku_PromptSpec.res (subject constructors)

**rationale:** The hypothesis mechanism lives at exactly one line (:325). Removing `doing` from the row makes it impossible to write a shot in which a character has no action of its own, and the closed variant kills the silent typo-to-VESPER path.

**check:** `type member = Kuku | Fyuria | Leda | Castor | Vesper | Dadi | Papa | Kalu`; `type castEntry = {who: member, form: P.form, pose: string}`; row field `cast: array<castEntry>` and the `doing: string` field is deleted so `subjectOf` has no shared string to stamp. Group actions are expanded at authoring time by a helper `all5: (member => string) => array<castEntry>` that returns five named entries. The wildcard arms `| _ => P.Dragon({name: P.Vesper ...})` (:297) and Closeups `| _ => "KUKU"` (:55) become compile errors because the switch is over a closed variant; the chorus «सब» gets an explicit `Chorus` case that the closeup driver handles by naming a member.

**prevents:** [1, 5, 6]

### PER_SUBJECT naming law (how cast are named in every sentence)  [gate]
**where:** studio/src/PromptGate.res (new `scanSubjects`, wired into `imagePrompt`/`videoPrompt` alongside `pass`)

**rationale:** Makes the per-name discipline a compile-of-the-prompt property rather than a habit. Board-to-role binding cannot work while five boards are tied to one indistinguishable sentence.

**check:** Rule of prose: every sentence sent to a model names its actor by that actor's own name (Latin header or Devanagari alias); a group action is written as N named clauses; collective nouns and bare pronouns are unrenderable. Mechanically, for every line matching `^- (KUKU|FYURIA|LEDA|CASTOR|VESPER|DADI|PAPA|KALU) — (.*)$`: (a) refuse if the tail matches /\b(the five|all five|the four|all four|the others|the children|each child|each of them|both of them|the group|five (great|small) dragons|everyone|they|them|their)\b/i; (b) refuse if the tail contains any OTHER cast member's Latin name or Devanagari alias from the table {KUKU:कुकु, FYURIA:फ्यूरिया, LEDA:लेडा, CASTOR:कैस्टर, VESPER:वैस्पर, KALU:कालू, DADI:दादी, PAPA:पापा}; (c) DUPLICATE_DOING — refuse when two subject lines share an identical tail; (d) the SCENE line (still) or every ACTION TIMING bullet (clip) of a shot with cast.length >= 2 must contain the alias of every cast member, else refuse `PROMPT: SCENE names <missing>`. Zero-cost fixtures in npm test: the s33e, s33c, s27 and s03 prompts copied verbatim from their receipts must be REFUSED (Lesson 10).

**prevents:** [1, 5, 6]

### REFERENCE_CLOSURE: every creature noun resolves to a cast member  [gate]
**where:** studio/src/PromptGate.res; studio/src/Kuku_PromptSpec.res (`imagePrompt` HARD RULES assembly :205-216 and the videoPrompt cast branch :265-267)

**rationale:** s53's invented figures and s55/s56's unreferenced पापा are the model filling a noun that nothing on the reference list resolves.

**check:** For SCENE, SUBJECTS, LIGHTING, ACTION TIMING and HARD RULES text: any match of /\b(child|children|dragon|dragons|faces?|wings?|paws?|claws?|he|she|his|her|they|them|their|everyone|figure)\b/i requires cast.length >= 1 for image specs / v.cast non-empty for video specs, and any Devanagari or Latin cast alias in that text must be a member of cast; otherwise refuse `PROMPT: '<noun>' has no cast member in <shot>`. The GREAT/SMALL scale rule is emitted only by `scaleRule(subjects)` which returns [] when no Dragon is present (today the else-branch at :349-351 emits THE CHILDREN ARE SMALL into empty-cast s53). Fixture: the EP12_s53_wind_cannot_touch clip prompt (`the children's wings are pressed flat` with `IN THIS SHOT: the place itself, empty and still`) must be refused.

**prevents:** [2, 1]

### FORM_SINGLE_SOURCE: form drives prose, hard rule and board from one value  [type]
**where:** studio/src/KukuEp12_Shots.res (delete `greatForm`/`isGreat` :87-88 and the two rule branches :349-350, :388-390); studio/src/Kuku_PromptSpec.res (`scaleRule`); studio/src/PromptGate.res (CONTRADICTION_FORM)

**rationale:** The कड़ा sequence alternated small/great because the majority of the prompt and all five reference images said child while one bullet said seven metres; the great turnarounds were on disk and unreachable.

**check:** `form` lives on `castEntry` (Rule 1) and is the only input to (a) `subjectText` (Great prose at PromptSpec :139), (b) `boardOf` (Great → `ep10prod/elements/future_<name>_board_bracelet.png`, the existing 2752x1536 turnarounds), and (c) a new `scaleRule: array<subject> => array<string>` that emits THE FIVE ARE IN THEIR GREAT FORM iff every Dragon is Great, THE CHILDREN ARE SMALL iff every Dragon is Small, and REFUSES (`PROMPT: mixed forms in <shot>`) otherwise. PromptGate CONTRADICTION_FORM as a backstop: refuse any prompt matching both /small everyday form/ and /GREAT FORM/i, and refuse /\b(great form|great dragons)\b/i inside a subject line whose head says `small paper dragon child`. Receipt field `state.forms: [[name, "Small"|"Great"], ...]`. Fixture: the s33d receipt prompt must be refused.

**prevents:** [5, 1, 6]

### LAMP_AS_TYPED_PROP_STATE: an absent object is not named  [type]
**where:** studio/src/KukuEp12_Shots.res (`lampLit` :317, `diyaProp` :300-306, rule branches :346 and :390, VIEWPOINT prose :55-60); studio/src/Kuku_PromptSpec.res (`extraRules: array<option<string>>`, flattened); studio/src/PromptGate.res (STATE_PAIR)

**rationale:** A diya described with its wick is drawn lit no matter what adjective follows; the plate's niche is empty, so absence is the cheapest state to render — the type makes the prompt ask for what is actually there.

**check:** `type lampState = Lit | Cold`, `lampOf: light => lampState` total (Dusk | LampNight | NextDusk => Lit; Dark | Golden => Cold), used by diya prop, lighting prose, rule list and station prose — the three re-derivations are deleted. `type propState = Present(P.subject) | Absent`; `Cold => Absent`: the diya reaches neither SUBJECTS nor VIEWPOINT (station prose says `the empty stone shelf of the niche`) and the rule is positive: `THE NICHE SHELF IS BARE STONE, in shadow; all light comes from <lightProse source>`. The cold bowl, if wanted on screen, is a composited layer like the letter (Lesson 19). `extraRules` becomes `array<option<string>>` flattened by the renderer so a bare `- ` bullet is unrepresentable. PromptGate STATE_PAIR: refuse any generation prompt matching /\b(cold and dark|unlit|wick dark|empty and cold|dead lamp)\b/i (the named-and-forbidden class), and refuse /\b(flame|lit lamp|burning wick|single small flame)\b/i when LIGHTING matches /darkness|night sky|one source of light/. Receipt field `state.lamp: "Lit"|"Cold"`. Fixtures: s33e and s52 receipt prompts must be refused.

**prevents:** [3]

### LETTER_AS_VFX: letterMode and letterState are types; shape nouns are unrenderable  [type]
**where:** studio/src/KukuEp12_Shots.res (delete `letterUp` :318-322, `letterProp` :313, letter prose in rows :219, :226, :229 and `lightProse(Golden)` :42); studio/src/PromptGate.res (SHAPE_WORDS); new studio/src/Kuku_LetterComposite.res (ReScript port of ep12_letter_composite.mjs)

**rationale:** Lesson 14 (generated glyphs are gibberish) and the :308 comment already decided this; the decision was applied to one subject line while SCENE and LIGHTING still said 'letter' and 'column', which the model drew as a glyph and a searchlight.

**check:** Episode constant `let letterMode: letterMode = GlowOnly` with `type letterMode = GlowOnly | LockedGlyph(string)`; row field `letter: letterState` with `type letterState = NoLetter | Trace | CurveReversed | CurveRight | Complete`. In GlowOnly the renderer produces the glow prop, `lightProse(Golden)` and any frame/action text about the letter from ONE template that contains only light vocabulary: `A SOFT POOL OF WARM GOLDEN LIGHT hanging in the air before the niche, its edges fading gently into the dark, about as tall as a seated child` / `a warm golden glow standing in the air before the niche is the one source of light` / for s55 `the golden glow spreads over the wall and down the valley`. `LockedGlyph(path)` forces `objects = [path]` so the receipt shows the glyph reference. PromptGate SHAPE_WORDS, applied to every image AND video prompt of a GlowOnly episode: refuse /\b(letter|letters|glyph|curve|curves|line|lines|stroke|column|pillar|post|pole|beam|shaft|ray|searchlight|symbol|character|shape)\b/i and any Devanagari codepoint run that is not a cast alias in the table (catches द, दा). Receipt fields `letterMode` and `state.letter`; `Kuku_LetterComposite` refuses to draw the font onto a frame whose receipt lacks `letterMode: GlowOnly` or whose `gates` list lacks `SHAPE_WORDS: PASS`. Fixtures: s52 still prompt, s52 clip prompt, s53 clip prompt and s55 must be refused.

**prevents:** [2]

### MOTION_KIND: Departs requires an end still and drops the hold clauses  [type]
**where:** studio/src/KukuEp12_Shots.res (row type; `clipSpecOf` :367-395; `clipSecs`/`storyCritical` :401-408; `doClip` :411-419); studio/src/PromptGate.res (EXIT_VS_HOLD)

**rationale:** The s33c clip prompt asked for departure in one sentence and for stillness in four; an end frame is the one anchor Cinema Studio actually honours for where bodies end up.

**check:** Row field `motion: motion` with `type motion = Holds | Moves(string) | Departs({beat: string, endStill: string})`; `kind: Still` rows carry `Holds` only. A `Departs` row: `doClip` passes `~endFrame=endStill` (Engine already accepts it, :289), the blocking line `Everyone in frame keeps the position they hold in the start frame` and `The courtyard stays exactly as it is` are replaced by `ends with <beat>`, `cameraTravels` is set from the station pair, and seconds are the row's written `secs` (the hand list `storyCritical` is deleted; `Departs` and dialogue rows keep their length by construction). PromptGate EXIT_VS_HOLD: refuse any video prompt matching /\b(rise|rises|lift|lifting|fly|flies|leave|leaves|out over|off the ground|into the sky|over the wall)\b/i together with /keeps the position|holds completely still|stays exactly as it is/. Fixture: the EP12_s33c clip receipt prompt must be refused.

**prevents:** [6]

### STATION_VARIANT: camera station carries framing; vantage prose names no posture or prop  [type]
**where:** studio/src/KukuEp12_Shots.res (`camProse` :52-65 with its `| _ =>` fallback; `shot: P.Medium` :335; `cam: string`)

**rationale:** Station prose smuggled a seated group into standing shots and a lamp into every letter shot, and the constant MEDIUM chose the plate clause that pinned wide/valley shots to the door-side vantage.

**check:** `type station = Wide | Niche | Flame | LampMed | Faces | ChildEye | OverFuria | Door | Valley | Group34 | High`; `framingOf: station => P.shot` (Wide/High/Door/Valley → Wide or HighWide; Faces/Group34/LampMed → Medium; Niche → CloseMedium; Flame → Insert); `vantageOf: station => string` whose text names a place to stand and a direction only — no `seated group`, no `across the lamp`, no `the lamp filling the middle of the frame` (posture and prop belong to cast entries and the typed lamp state). `shot` in `specOf` becomes `framingOf(r.station)`; the string switch and its wildcard are gone. PromptGate backstop: VIEWPOINT text must not match /\b(seated|sitting|standing|lamp|flame|letter)\b/i.

**prevents:** [6, 5, 4]

### PLATE_PER_LIGHT: plate typed with its light state; plate clause never asserts light  [type]
**where:** studio/src/Kuku_PromptSpec.res (`plate: option<string>` :35 and the SET PLATE clause :185-187); studio/src/Kuku_Engine.res (`still` plate check :263-266); new plates under stories/kuku/ep12/sets/

**rationale:** Fifty Dark/Golden shots were told to match a golden-dusk plate's palette and light; the warm-lit niche the model produced is that instruction obeyed.

**check:** `type plate = {path: string, light: light, station: station}`; `imageSpec.plate: option<plate>`; `plateOf: (light, station) => plate` in the driver, generated as receipted edits of the master dusk plate (five light states: dusk, lamp-night, dark, golden, next-dusk). The SET PLATE clause drops `identical palette and light` and reads `identical geometry, materials and landmarks; the light of this shot is described under LIGHTING`. `Kuku_Engine.still` refuses `PREMISE MISSING: plate for light <state>` when `spec.plate.light != lightOf(spec)`. PromptGate LIGHT_CONTRADICTION: refuse /identical palette and light/ together with /darkness|night sky|one source of light/. Receipt: the plate row carries `role: Plate` and `light`.

**prevents:** [3, 4]

### BOARD_CONTRACT: boards are receipted three-view turnarounds under the locked key, mapped to names by ordinal  [gate]
**where:** studio/src/Kuku_Engine.res (`requireBoards` :67-90, `requireFile` :60); studio/src/Kuku_PromptSpec.res (`subjectText` :130-151, `boardOf` :296-320, the clause at :192); new studio/src/Kuku_Sheets.res

**rationale:** Identity was left to colour-matching five single-pose cards of five design languages, one of them a bordered print, generated under the key the codebase blames for leaking objects. Lesson 20 already required turnarounds; the gate makes the lesson refuse instead of remind.

**check:** Opaque `type board` constructed only by `Kuku_Sheets.turnaround(~member, ~views=[Side, Front, HeadClose])`, whose receipt records `views: 3`, `framed: false` and refs[0] = the locked style key. `requireBoards` reads each board's receipt and refuses `PREMISE STALE: sheet <name>` unless (a) `receiptIntact`, (b) prompt matches /three views|turnaround|side profile.*front.*head close/i, (c) refs[0] sha256 == STYLE_LOCK key sha, (d) magic bytes match the extension (a WebP named .png is refused). Sheet prompts are gated against /\b(card|print|photo|border|frame)\b/i so the frame-within-frame cannot recur. Renderer: `imageRefs` and `subjectText` derive from one ordered reference list so each line reads `- KUKU — the THIRD attached image — green paper dragon, two short tan horns, round toddler build, ...` with the ordinal computed and a `featuresOf(name)` (horns/crest/build) beside `colorOf`. Papa and Kalu become `member` variants with boards (charsheets/papa.png, kalu.png regenerated as turnarounds); Dadi's line is derived from her sheet receipt's SUBJECT text (no 'bird'). Closeups use the HeadClose view.

**prevents:** [1]

### STYLE_KEY_LOCAL_AND_REQUIRED: no global ref, no provider id, one key per episode  [type]
**where:** studio/src/Kuku_PromptSpec.res (delete `styleKeyDefault`/`styleKeyRef`/`useStyleKey`/`styleKey` :114-117; `imageSpec`/`videoSpec` gain `styleKey: styleKey`); studio/src/Kuku_Engine.res (`isProviderAsset` exemption :49-53 removed from refs[0] and from `requireFile`); new stories/kuku/ep12/style/STYLE_LOCK.json

**rationale:** 145 of 146 stills/closeups were made under a34b16f4 and one under ep12_style_key.png, invisibly, because the key was a mutable global that hashed to a constant.

**check:** `type styleKey = private StyleKey(string)` constructed only by `Kuku_Style.lock(path)` which requires a local, receipt-intact file (a provider uuid is refused: `PREMISE MISSING: style key must be a receipted local file`). Every spec carries it as a required field, so a driver cannot forget it and a module-level side effect cannot swap it. Receipt field `styleKeySha256`; STYLE_LOCK.json pins key sha + every board sha for the episode. Preflight check `stills-share-one-style-key` (in `gate`): the set of refs[0] sha256 across an episode's still and closeup receipts must have exactly one member, else the drifted ids are listed and the gate fails.

**prevents:** [4, 1]

### REFS_FROM_ARGS: the receipt's reference list is computed from the provider call  [receipt]
**where:** studio/src/Kuku_Engine.res (`clip` :304-341, `still` :267-275, `writeReceipt` :95-118); studio/scripts (zero-cost test in npm test)

**rationale:** Every EP12 clip receipt claims two set anchors the call never carried; the receipt is the show's only proof and it was false about its own premises.

**check:** `type reference = Style(string) | Plate(string) | Object(string) | Board(string) | Start(string) | End(string) | Video(string)`; one function `argsOf: array<reference> => array<string>` renders CLI flags (Style/Plate/Object/Board → `--image-references` for clips, `--image` for stills; Start → `--start-image`; End → `--end-image`; Video → `--video-references`) and `receiptRowsOf` renders the receipt from the SAME list with a `role` field per row. `writeReceipt` refuses (`RECEIPT: ref <path> not in params`) if any local ref path in refs is absent from params. If Cinema Studio has no slot for a plate/key, `clip` refuses `PREMISE UNSUPPORTED: set anchors on clip` instead of recording them. Zero-cost test: build the s33c clip args with `setRefs=[key, plate]` and assert both appear in argv — this test fails against today's code.

**prevents:** [4, 1]

### RULES_STAMP: receipts carry the rule version, the typed story state and the git state; freshness refuses stale rules  [receipt]
**where:** studio/src/Kuku_Engine.res (`writeReceipt` :95-118, `freshness` :124-165, `receiptIntact` :172-204); studio/src/Kuku_Spend.res (`guard`)

**rationale:** Four rule states produced assets that all say kuku-engine/1; 'stale' had no definition except eyeballing. The stamp gives the regeneration campaign a mechanical list of what it owes and makes a later rule change stale everything made before it.

**check:** New receipt fields: `rulesSha256` = sha256 over the compiled `Kuku_PromptSpec.res.mjs`, `PromptGate.res.mjs`, `Kuku_Engine.res.mjs` and the driver `.res.mjs` that produced the prompt; `tableSha256` = sha256 of the `list` manifest (every row's typed fields); `gitHead`, `dirty: bool`; `state: {light, lamp, letter, forms: [[name, form]], cast: [members], station, motion}` written from the typed row, never from prose; `styleKeySha256`; `gates: ["NEGATION: PASS", "PER_SUBJECT: PASS", "SHAPE_WORDS: PASS", ...]`. `freshness` gains `RulesDrift | StyleKeyDrift | RefListDrift(expected, recorded) | StateDrift` and returns `Current` only when promptSha256, rulesSha256, styleKeySha256, the ORDERED ref path list recomputed from the current spec, and `state` all match the receipt. `Kuku_Spend.guard` refuses to spend when the driver source is untracked or the tree is dirty unless `STUDIO_ALLOW_DIRTY=1`, and stamps that flag into the receipt so an audit can find every asset made from uncommitted law.

**prevents:** [3, 4, 5]

### FRESHNESS_GATE_IN_DRIVERS: approvedFrame is an opaque type; skip only on Current  [process]
**where:** studio/src/KukuEp12_Shots.res (`stills` :456-462, `doClip` :411-419, `gate` branch :464-472); studio/src/KukuEp12_Closeups.res; studio/src/Kuku_Engine.res (`clip` signature :289)

**rationale:** s33b's clip (GREAT + LAMP OUT) was animated from an s33b still (SMALL, no lamp rule) because file existence stood in for approval and hash-intact stood in for current.

**check:** `stills`/closeups skip a shot only when `Kuku_Engine.freshness(~asset, ~prompt=P.imagePrompt(specOf(r)), ~spec) == Current`; any other verdict regenerates and prints the verdict. `Kuku_Engine.clip` takes `~start: approvedFrame` where `type approvedFrame = private Approved(string)` is constructed only by `Kuku_Engine.approve(~asset, ~stillPrompt)` which returns Some iff freshness is Current AND the receipt carries `approvedAt`; a clip receipt records `startPromptSha256` and `startRulesSha256`, and a clip's freshness re-derives the still prompt and compares. The `gate` command prints every shot's verdict (copy KukuEp10_Shots.res:1016-1050) and exits non-zero on any non-Current asset present on disk.

**prevents:** [3, 5, 4]

### REJECT_AND_APPROVE_IN_RECEIPTS: assembler reads only Current+approved assets  [process]
**where:** studio/src/Kuku_Engine.res (new `reject`, `approve`); the ReScript assembler (`Kuku_Assemble`) replacing assemble_episode.mjs:112's `stills_final/` read; studio/scripts/trash.sh

**rationale:** The cut was built from a hand-curated directory with no receipts and rejected frames lost their provenance on rename; the engine could not vouch for anything in the timeline.

**check:** `Kuku_Engine.reject(~asset, ~reason: rejectReason)` with `type rejectReason = LitLamp | LaneLeak | Jitter | GenLetter | BeamOrGlyph | WrongForm | ScaleFlip | StyleDrift | Duplicate | Other(string)` moves the asset and its receipt to `.trash/` via `removeFile` and writes `<asset>.reject.json` {reason, at, receiptSha}; hand renaming with prefixes is retired (a `gate` check lists any file in stills/ clips/ closeups/ without a `.gen.json` as `UNRECEIPTED`). `approve(~asset)` writes `approvedAt`/`approvedBy` into the receipt after the author has seen the file (the file is sent to the author; Creative-changes-need-approval memory). `stills_final/` is trashed; the assembler refuses any still/clip whose freshness != Current or lacks `approvedAt`, and matches dialogue takes by id (the defect-7 fix), never by sorted position.

**prevents:** [7, 4, 3]

### CONTINUITY_GATE + MEASURED_LAMP: story state is checked across the table and measured on the pixels  [process]
**where:** studio/src/KukuEp12_Shots.res (`gate` command); studio/src/Kuku_Verify.res (new `nicheLuminance`)

**rationale:** Lesson 11 and Lesson 19: state changes move to the validation layer; the only lamp-state detection today is a human looking at a contact sheet, twice.

**check:** From the typed rows, `gate` asserts before any spend: light sequence is monotone Dusk→LampNight→Dark→Golden→NextDusk; `lampOf` flips Lit→Cold exactly once (s26) and Cold→Lit exactly once (s64); `letter` is NoLetter until s46, Complete from s52 onward; Great forms occur only in the contiguous s33b–s33f block; every Golden row has letter != NoLetter. After generation, `Kuku_Verify.nicheLuminance(~asset, ~station)` crops the station-fixed niche region (coordinates from the plate receipt) and requires mean luminance below a threshold for every `state.lamp == Cold` frame; the threshold is calibrated so the check FAILS on `.trash/…/LITLAMP_s33d_thrown_back.png` and passes on the approved cold s33d before it is trusted (Lesson 10). A failing frame is auto-`reject(LitLamp)`ed and the shot is re-queued, so the lit-lamp class costs one regen, not an eyeball pass.

**prevents:** [3]

### ONE_LIGHT_SOURCE_FOR_CLOSEUPS: light is looked up from the table, not re-derived  [process]
**where:** studio/src/KukuEp12_Closeups.res (`lightOf` :73-86, `roleOf` :46-56)

**rationale:** s26 is LampNight in the table and Dark in the closeup thresholds; any renumbering silently changes the light of seventy-three frames.

**check:** Delete the threshold function; `S.lightOfShot: string => option<light>` looks the row up by the cue's shot id, and a cue whose label resolves to no row refuses `CUE: शॉट <n> has no row`. `roleOf` returns `option<member>` over the closed variant; the chorus is an explicit `Chorus` case rendered as the named member the table read assigns. Zero-cost test: every cue in LINE_INDEX resolves to a row and a member.

**prevents:** [3, 4]

### FRAME_VS_ACTION: a still describes an instant, a clip describes a change  [type]
**where:** studio/src/KukuEp12_Shots.res (row type: `frame: string` and `action: option<string>` replacing the `doing`/`action` pair; `specOf` :334 `scene:`; `clipSpecOf` :367, :377); studio/src/PromptGate.res (TWO_STATES)

**rationale:** A single frame asked to show 'walk forward and lower themselves' AND 'sit in a half circle', or a lamp carried in both hands AND standing lit on the shelf (s64), is resolved by the model drawing whichever it likes.

**check:** Stills render SCENE from `frame` (the instant the picture shows); clips render ACTION TIMING from `action` and their FIRST FRAME is the still. A row with `kind: Motion` must supply both; `Still` rows cannot carry an action (the constructor `s` has no slot). PromptGate TWO_STATES on still SCENE lines: refuse sequencing connectives /\b(then|and then|until|begins? to|becomes?|where .* stood|now fill)\b/i and any two conflicting posture verbs from {sit, sits, sitting} × {walk, walks, walking, rise, rises, stand up}. Fixture: the s03 and s33b still prompts must be refused.

**prevents:** [1, 3, 6]


## Definition of done

1. G0 LAW COMMITTED: KukuEp12_Shots.res, KukuEp12_Closeups.res, Kuku_PromptSpec.res, Kuku_Engine.res, PromptGate.res and the new Kuku_Sheets/Kuku_Style/Kuku_Verify/Kuku_LetterComposite modules are tracked, the working tree is clean, `npm test` is green (escape-hatch scan, build with warning 8 fatal, and the new zero-cost tests), and `Kuku_Spend.guard` refuses spend on a dirty tree — proven by running it once dirty and watching it refuse.

2. G1 GATES FAIL ON KNOWN-BAD INPUT (Lesson 10): the verbatim prompts copied from the s33e, s33d, s33c(still), s03, s52(still), s52(clip), s53(clip), s55 and s27(clip) receipts are fixtures that PromptGate must REFUSE (PER_SUBJECT, REFERENCE_CLOSURE, CONTRADICTION_FORM, STATE_PAIR, SHAPE_WORDS, EXIT_VS_HOLD, LIGHT_CONTRADICTION, TWO_STATES each named at least once); the refs-from-args test fails against the pre-fix clip builder and passes after; `nicheLuminance` fails on the trashed LITLAMP_s33d frame.

3. G2 TYPES COMPILE WITH THE OLD SHAPES GONE: no `doing` on the row, no `greatForm`/`isGreat`, no `letterUp`, no `storyCritical`, no `useStyleKey`/`styleKeyRef`, no `| _ =>` arm in any cast/speaker/station switch, `shot` derived from `station`, `extraRules` cannot emit an empty bullet — verified by grep in a preflight script that fails if any of those identifiers reappear.

4. G3 STYLE LOCK: `ep12/style/ep12_style_key.png` is receipt-intact and locked via `Kuku_Style.lock`; `STYLE_LOCK.json` written with key sha; `stills-share-one-style-key` passes on the (now empty, everything old trashed with its receipts) stills/, clips/ and closeups/ directories; `stills_final/` is trashed.

5. G4 BOARDS: five child three-view turnarounds (plus HeadClose view) regenerated by `Kuku_Sheets.turnaround` under the locked key with the Aug-28 cards as design references, plus Papa, Kalu, and Dadi's sheet receipted with a SUBJECT line the renderer reads; `requireBoards` passes for every cast of all 71 rows and 73 cues; every sheet sent to the author and approved (`approvedAt` set) — the only spend before G5, about 8 stills.

6. G5 PLATES PER LIGHT: five receipted plates (dusk, lamp-night, dark, golden, next-dusk) produced as edits of the master plate, each with `light` in its receipt; `plateOf(light, station)` resolves for every row; author approves the five plates.

7. G6 GATE CLEAN, ZERO COST: `node src/KukuEp12_Shots.res.mjs gate` renders all 71 still prompts, every clip prompt (with end-still prompts for `Departs` rows) and all 73 closeup prompts, passes every PromptGate rule, passes the continuity gate (lamp flips at s26/s64 only, letter from s46/s52, Great only in s33b–s33f, closeup light resolved from the table), prints each shot's typed `state`, and reports every asset on disk as Current or absent — nothing stale.

8. G7 AUTHOR READS THE PROMPTS: the rendered prompt text for the कड़ा block (s33a–s33f including the s33c end still) and the letter block (s46–s56) is sent to the author as text; the per-name phrasing, the glow-only letter wording and the flight's end-frame beat are approved before any frame is made (creative changes need approval first).

9. G8 BUDGET PINNED: `list` prints the spend plan (stills + end stills + clips at their typed seconds + closeups) with a total; the Kuku_Spend cap is set to exactly that total; `STUDIO_ALLOW_DIRTY` is unset; no re-fire before a response returns.

10. G9 GENERATE IN DEPENDENCY ORDER WITH FRESHNESS STOPS: stills → each still sent to the author and `approve`d (rejections go through `reject(reason)`, never rename) → `nicheLuminance` on every Cold frame → end stills for Departs rows → clips only from `approvedFrame` values (receipt carries startPromptSha256/startRulesSha256) → closeups; after every batch `gate` must report zero non-Current assets before the next batch starts.

11. G10 COMPOSITE AND ASSEMBLE FROM RECEIPTS ONLY: `Kuku_LetterComposite` draws the font only onto frames whose receipt says `letterMode: GlowOnly` and `SHAPE_WORDS: PASS`, stamping via `stamp`; the assembler refuses any asset not Current+approved, matches dialogue takes by id, and the EDL gate (Lesson checks: no-dialogue-still-across-scenes, shot-refs-include-speaker, sfx placement, levelling) passes; per-scene cut files are delivered to the author as 1–3 MB attachments.
