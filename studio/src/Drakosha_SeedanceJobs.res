/* The ten EP1 scenes 2–4 job records. Cast/props/start-images per the
   script-derived manifest reviewed with the director 2026-08-08:
   - jobs 13 and 14 run WITHOUT start images (close-ups; her ruling),
   - Frosya is the pre-gift version batch-wide (registry handles it),
   - creative choreography lives in production/seedance_batch/creative/,
     loaded by the stage; the emitter rejects any tag smuggled inside it. */

open Drakosha_SeedanceBatch

let creativeDir = "../stories/drakosha/production/seedance_batch/creative"

/* WHICH MODEL A JOB RUNS ON IS PART OF THE JOB, not a constant in the emitter.
   The three Seedance models differ in the two things that decide a shot: how
   long a single generation may run, and what it costs per second.

     mini  2.5 cr/s   max 15s    9 image refs
     v20   4.5 cr/s   max 15s    9 image refs
     v25   6.5 cr/s   max 30s   30 image refs

   Almost everything on this show fits mini, which is why mini is the default
   answer and 2.5 has to be argued for. The one place it cannot reach is a
   speech longer than about thirteen seconds, because the gate also reserves a
   two-second head for the beat before anyone speaks. `Drakosha_SeedanceDryRun`
   enforces the ceilings and prices the whole batch, so a job that quietly asks
   for 17s on mini is a red run and never a truncated clip. */
/* KLING JOINED THE REGISTRY 2026-08-20. It is not a Seedance model and it does
   not behave like one: it takes no image references, it charges for its own
   sound whether or not the shot has any, and Kling 3.0 is the only model on the
   account that accepts an END frame as well as a start frame — which is what a
   seamless loop needs, because the loop is nothing more than a clip whose last
   frame is its first.

     kling2_6  1.0 cr/s with sound OFF (2.0 with it on), 5s or 10s only
     kling3_0  1.5 cr/s std, sound off, arbitrary duration, START + END frames

   Both are cheaper than the mini we have been shooting on at 2.5 cr/s. */
type seedanceModel = Mini | V20 | V25 | Kling26 | Kling30 | Veo31Lite

let modelName = m =>
  switch m {
  | Mini => "seedance_2_0_mini"
  | V20 => "seedance_2_0"
  | V25 => "seedance_2_5"
  | Kling26 => "kling2_6"
  | Kling30 => "kling3_0"
  | Veo31Lite => "veo3_1_lite"
  }

let modelMaxSec = m =>
  switch m {
  | Mini | V20 => 15
  | V25 => 30
  | Kling26 | Kling30 => 10
  | Veo31Lite => 8
  }

/* Kling takes a start frame and nothing else. A job that hands it reference
   images is a job that thinks it is talking to Seedance. */
let modelMaxRefs = m =>
  switch m {
  | Mini | V20 => 9
  | V25 => 30
  | Kling26 | Kling30 | Veo31Lite => 0
  }

let modelCreditsPerSec = m =>
  switch m {
  | Mini => 2.5
  | V20 => 4.5
  | V25 => 6.5
  | Kling26 => 1.0
  | Kling30 => 1.5
  | Veo31Lite => 1.0
  }

/* endImage is Kling-3.0 only and exists for one reason: a loop. Pass the same
   frame as start and end and the clip returns to where it began, so it can be
   cut back to itself without a seam. */
type jobSpec = {
  record: shotRecord,
  creativeFile: string,
  model: seedanceModel,
  endImage: option<string>,
}

let job = (jobId, shots, cast, props, startImage, durationSec, model): jobSpec => {
  record: {jobId, shots, cast, props, startImage, durationSec, creative: ""},
  creativeFile: creativeDir ++ "/" ++ jobId ++ ".creative.txt",
  model,
  endImage: None,
}

let loopJob = (jobId, shots, cast, props, frame, durationSec, model): jobSpec => {
  record: {jobId, shots, cast, props, startImage: Some(frame), durationSec, creative: ""},
  creativeFile: creativeDir ++ "/" ++ jobId ++ ".creative.txt",
  model,
  endImage: Some(frame),
}

/* JOBS 10-19 ARE ALL SHOT. Their footage is in seedance_batch/output and in the
   clip library, and every one of them predates the REACTIONS rule, so they fail
   assertReactionsWritten and would hold the dry run red forever. A red run that
   is always red is a run nobody reads — the same reasoning that retired s5job1
   and s5job2. They live in `retired` below, which keeps them available for
   start-frame chain lookups without putting them back in the submission queue.

   If any of them is ever RESHOT, it comes back into `all` and must gain a
   REACTIONS block first: the frozen-expression defect the author found in
   s5job2 is present in all of this footage, because none of these prompts ever
   directed a listener's face. */
let all: array<jobSpec> = [
  /* THE WRITING LOOP — one letter's worth of strokes and a spark at the tip,
     ending exactly where it began so it can be cut back to itself for every
     letter of every word. Author's own start frame; kling3_0 because it is the
     only model on the account that takes an end frame, and a loop is nothing
     but a clip whose last frame is its first. The paper stays blank: the
     letters are her artwork and go on afterwards. */
  /* Same loop, same start frame, but the shot is now about her FACE: concentrate
     → surprise at the spark → a beat of thinking about the next letter → back
     down into the starting concentration. Veo 3.1 Lite because it also takes an
     end frame and it is the model on this account with the best claim to
     facial performance — and at 6s it costs 6 credits against Kling's 7.5. */
  /* The same silent-mouth, tongue-out, eyes-roll-aside loop on Kling 3.0, so the
     two models are judged on the one thing that failed: the mouth. Kling held
     identity, the blank paper and the loop perfectly the first time; all it did
     wrong was fill an unoccupied mouth with speech. */
  /* THE AGREED LOOP, 2026-08-20. One letter at a child's pace — three seconds,
     because at five it is too slow to read as writing and at one it is faster
     than the model will shoot. The TRAIL is the model's job and must die out in
     mid-air; the LETTERS are the author's and are added afterwards. The thinking
     is one flick of the eyes, because this clip is watched three times in a row
     and anything larger becomes a twitch. */
  /* THE EXPRESSION EXPERIMENT, 2026-08-20. Every expressive shot we have ever
     cut ran on mini with the character sheets bound and NO start frame; this
     loop ran on Kling, which takes no sheets, and came back with a blank face.
     Mini is the only model that takes a start frame, an end frame AND
     references at once. Four seconds because mini refuses anything shorter. */
  /* THE FINAL MARK — generated ONCE and reused in every transformation for the
     rest of the series. This is the half of the scene that never changes; the
     word before it changes every time and is lip-synced onto existing footage
     instead. Generate what repeats, lip-sync what varies. No end frame: it is
     an action, not a loop, and it has to finish somewhere new so the cut to the
     transformation has somewhere to go. */
  /* SCENE 8, SHOT 2 — the children and the spilled tiles, overhead. The
     author's start frame carries CORRECT tiles (А×3 М×2 К С Л Т О Б — the
     eight kinds plus the duplicates МАМА will need), so the job of the
     generation is only the children: nobody touches a tile. Фрося is back to
     camera, so her line needs no lip-sync. */
  job(
    "s8shot2",
    "SH103",
    [Frosya, Vasya],
    [RoomBack],
    Some("2026-08-22_S8_SHOT2_tiles_start.png"),
    12,
    Mini,
  ),
  /* «И ТОЧКА» — the seal, generated once and reused for every word. Seeded
     from shot 2+3's final frame with the pencil top repainted blunt (the render
     had grown a second point — the author caught it). Pencil prop bound so the
     model has the real object, not its habit. */
  job(
    "s8tochka2",
    "TOCHKA-SEAL",
    [Frosya],
    [RoomBack, Pencil],
    Some("2026-08-23_S8_TOCHKA_seed.png"),
    4,
    Mini,
  ),
  /* ВАСЯ AND THE LIGHT — the seal seen from his side. Author's start frame
     with a deep-blurred empty background, so there is no face back there to
     get wrong and the seed's own depth of field holds the blur. His sheet is
     the only reference. */
  job(
    "s8vasya",
    "SH106",
    [Vasya],
    [],
    Some("2026-08-23_S8_VASYA_light_start.png"),
    4,
    Mini,
  ),
  /* THE OFFER — «Сока хочешь?» from Вася's side. Author's start frame; her
     pre-pencil sheet, the juice glass and the pencil bound. */
  job(
    "s8offer",
    "SH107",
    [Frosya],
    [Juice, Pencil],
    Some("2026-08-23_S8_OFFER_start.png"),
    5,
    Mini,
  ),
  /* THE GLASS — Вася looks through the juice and asks. Author's start frame;
     his sheet and the juice glass bound. */
  job(
    "s8glass",
    "SH108",
    [Vasya],
    [Juice],
    Some("2026-08-23_S8_VASYA_glass_start.png"),
    5,
    Mini,
  ),
  /* САЛАТ — the second writing. Author's start frame; her sheet, the pencil
     and the back plate bound. Eight seconds because the re-recorded spelling
     runs 5.76s and the gate wants its two-second head. */
  job(
    "s8salat",
    "SH109",
    [Frosya],
    [RoomBack, Pencil],
    Some("2026-08-23_S8_SALAT_write_start.png"),
    11,
    Mini,
  ),
  /* THE SALAD ARRIVES — out of the spark, a hand's width up, drop, rock,
     settle. Author's start frame and her bowl reference. */
  job(
    "s8bowl",
    "SH110",
    [Frosya],
    [Salad, Pencil],
    Some("2026-08-23_S8_SPARK_bowl_start.png"),
    5,
    Mini,
  ),
  /* «ФУ-У-У! ОВОЩИ!» — the same proven start frame as the light shot; no
     light this time, the face itself turns from wonder to disgust. His hands
     (and the glass) stay below frame, so nothing has to be drawn holding. */
  job(
    "s8fu",
    "SH111",
    [Vasya],
    [],
    Some("2026-08-23_S8_VASYA_light_start.png"),
    5,
    Mini,
  ),
  /* РУСЯ И САЛАТ — one continuous wide; the close insert cuts into its middle
     in the edit, and the second half of the take is the zoom-out. The children
     hear him before we see him, and their eyes carry every beat. */
  job(
    "s8rusya",
    "SH112-114",
    [Frosya, Vasya, Rusya],
    [Salad, Juice, Pencil],
    Some("2026-08-23_S8_RUSYA_wide_start.png"),
    10,
    Mini,
  ),
  /* МАК — write, seal, and the poppy rising out of the settled light, one
     take, no wipe: the full statement of her magic's grammar. */
  job(
    "s8mak",
    "SH115",
    [Frosya],
    [RoomBack, Pencil, Poppy],
    Some("2026-08-23_S8_SALAT_write_start.png"),
    13,
    Mini,
  ),
  /* «МАМ, ЭТО ТЕБЕ» — the offer starts un-extended so the gesture happens on
     camera. МАМА's line dubs as Olga placeholder until the recast decides. */
  job(
    "s8poppy",
    "SH117-118",
    [Frosya, Mama],
    [Poppy],
    Some("2026-08-23_S8_POPPY_offer_start.png"),
    8,
    Mini,
  ),
  /* «А Я, Я ТОЖЕ ХОЧУ» — the ask. Whiny, then alight: he wants magic too and
     cannot see where a person starts. The middle beat is his eyes dropping to
     the scattered tiles, hand hovering, not landing — which is what makes her
     answer in the next shot a reply rather than a brush-off.

     NO @TILES AND NO @POUCH REFERENCE, deliberately. The author's start plate
     already has both exactly right: dark end-grain tiles on the floorboards and
     the burlap pouch lying open beside him. The chest sheet backing @TILES shows
     PALE GOLDEN tiles inside a chest — a sheet that disagrees with the plate is
     a liability, and it would drag the tiles lighter and invite a chest into a
     shot that has none. @POUCH is backed by page-04, which the @VASYA token
     already attaches, and its old tagline put the pouch at his hip. Both prop
     positions live in the shot text instead, per the ANCHOR RULE.

     EIGHT SECONDS, NOT SIX. line60 is 5.28s and the gate reserves a two-second
     head, so six would be refused. The extra two seconds are where the shot
     actually lives: the whine lands before the words, and he is left leaning in
     and waiting at the end, which is what motivates the cut to Фрося. */
  job(
    "v01ask",
    "SH120",
    [Frosya, Vasya],
    [Salad, Juice, Pencil],
    Some("2026-08-24_V01_vasya-asks_start_v2.png"),
    8,
    Mini,
  ),
  /* «НУ СОБЕРИ САМ» — her answer, and the reverse of V01. THE CAMERA IS ON
     ВАСЯ'S AXIS, so she looks down the lens a touch to screen-left rather than
     to screen-right: in a two-shot she looks toward his side of the frame, but
     once the camera stands where he stands, his side IS the lens. Reading the
     two-shot rule into a reverse single is how an eyeline gets called broken
     when it is correct (2026-08-24).

     Her line is a reply, not a brush-off. He looked at the scattered tiles in
     V01 and could not see a way in; here she nods at them — once, with the head
     alone, never touching one — and that nod is the whole performance.

     THE WALL BEHIND HER IS THE HATCH WALL (author, 2026-08-24), not the kitchen
     end. Which wall a character has behind them is a fact about where the
     CAMERA stands, not about the character, so it is answered per shot and
     never carried over from the last one.

     ФРОСЯ IS page-05, «ДО карандаша», AND THAT IS CORRECT HERE. The two Фрося
     sheets differ in exactly one thing: page-06 «ПОСЛЕ карандаша» has the pencil
     stub tucked in her hair. Which sheet a shot wants is decided by whether the
     pencil is ON HER in that frame, not by where we are in the story — and in
     this plate it lies on the floorboards. Binding page-06 would put a pencil in
     her hair that the frame does not have. (The flower sits on her screen-right;
     the pencil goes on her screen-left. Opposite sides.)

     page-06 becomes the right sheet the moment she tucks it behind her ear —
     SH119B, and everything after it if the author moves that tuck to the end of
     this block.

     THAT FACT LIVES HERE AND NOT IN THE PROMPT. The plate shows a bare run of
     stone with no hatch in it and no hatch reference is bound, so writing
     "hatch wall" into the choreography would be an instruction to draw one —
     into a frame that has none. The name is production knowledge that tells the
     NEXT shot where it stands; the prompt gets what the frame shows.

     FIVE SECONDS, NOT FOUR. line61 is 2.48s and the gate reserves a two-second
     head, so four would be refused. */
  job(
    "v02answer",
    "SH121",
    [Frosya],
    [Salad, Pencil],
    Some("2026-08-24_V02_frosya-answers_start_v2.png"),
    5,
    Mini,
  ),
  /* HE CHOOSES THE LETTERS — the experiment that unlocks the tile beat. The
     camera lies low enough that the tiles are edge-on and their faces never
     turn to the lens, so THE GLYPH PROBLEM DOES NOT EXIST IN THIS SHOT. Scene 7
     lost every letter shot to Cyrillic the model cannot draw; this one cannot
     lose that way, because there is nothing to draw. The word gets read in the
     next shot, off the author's legible plate.

     HE SLIDES, HE NEVER LIFTS. A tile pushed flat along the boards is one
     contact point and one direction of travel; a tile picked up, carried and
     set down is a grip, an occlusion, a rotation and a landing — four ways to
     break, per tile, four times over. This single choice is the largest thing
     standing between the shot and a mess.

     NEAR TO FAR, so a failure comes late. The first gather is the tile already
     under his hand and is nearly free; the longest reach is last. If the model
     breaks on the third or fourth, the take is trimmed at the break and what
     survives is two clean gathers — which says everything the shot has to say.
     Eight seconds: four gathers at about a second and a half, plus a beat.

     No @TILES: the chest sheet is a whole chest, and this plate carries the
     tiles perfectly already. No @POUCH: it is backed by page-04, which @VASYA
     attaches anyway. */
  job(
    "v03gather",
    "SH122",
    [Vasya],
    [],
    Some("2026-08-24_V03_gather_start.png"),
    8,
    Mini,
  ),
  /* SCENE 7 — the niche, the chest, the letters. All on mini.

     GEOGRAPHY, set once by the author and not re-derived per shot: Мама works at
     the BACK WALL with the niche behind her; the children sit on the play mat
     with their backs to the room, so the front of the hall — bulbs and the ramp
     railing — is what lies behind THEM; Бабушка-Яга sits across the corner in one
     of the knitted armchairs with the kitchen end behind her. Every job below
     states which wall is behind whom and `assertBackgroundsAssigned` checks it.

     DURATIONS ARE DELIBERATELY LONG ON МАМА'S JOBS. Her voice is still being cast
     and the two finalists read this line 20-50% slower than the Olga recordings
     the line index holds. Sizing these from the existing files would repeat the
     s6jobC failure — a dub that does not fit its own picture — so Мама's lines
     are budgeted at the slowest plausible pace instead. The extra seconds cost
     2.5 credits each and are cheaper than one reshoot. */

]

/* NO START KEYFRAMES (author, 2026-08-13). Every kf*.png was generated in the
   earlier round and predates the corrections made since: the green unlit door,
   the chairs on the юла, the round tin, Руся and Муся as separate characters.
   Anchoring a shot to one would reimpose the old canon over correct references.
   seedance_2_5 needs no start image — omni_reference only requires at least one
   reference media item, and every job carries several. */

/* RETIRED jobs: already shot, out of the submission queue, but still real links
   in the start-frame chain. A later job can lift its opening frame from one of
   these, so the gate has to be able to look up where they were set — otherwise
   assertStartFrameSameLocation finds no source record and silently passes,
   which is exactly what it did the first time it was tested. */
let retired: array<shotRecord> = [
  /* s6jobF — SHOT AND ACCEPTED 2026-08-18. Мама's line, reshot alone after the
     first take smiled through it. Retired with the rest of scene 6. */
  {jobId: "s6jobF", shots: "SH081", cast: [Mama], props: [RoomFront], startImage: None, durationSec: 11, creative: ""},
  /* SCENE 6, SHOT AND ACCEPTED 2026-08-18. Retired the moment the footage
     existed, which is also what frees the choreography to keep improving: these
     five creatives predate assertHandsWritten and the facial-anatomy rule, and
     left in `all` they would hold the dry run red forever over prompts whose
     clips are already cut. Their records stay here for start-frame lookups.

     s6jobE is a PARTIAL accept: 4.45s of it is used and Мама's third shot was
     reshot as s6jobF. The record keeps the generation that actually happened. */
  {jobId: "s6jobA", shots: "SH066-068", cast: [YagaDomovoy, Frosya], props: [RoomFront, Pencil], startImage: None, durationSec: 12, creative: ""},
  {jobId: "s6jobB", shots: "SH069-073", cast: [Frosya, YagaDomovoy, Vasya], props: [RoomFront, Pencil], startImage: None, durationSec: 13, creative: ""},
  {jobId: "s6jobC", shots: "SH074-077", cast: [Vasya, YagaDomovoy, Frosya], props: [RoomFront, Pencil], startImage: None, durationSec: 17, creative: ""},
  {jobId: "s6jobD", shots: "SH078", cast: [YagaDomovoy, Frosya, Vasya], props: [RoomFront, Pencil], startImage: None, durationSec: 8, creative: ""},
  {jobId: "s6jobE", shots: "SH079-081", cast: [Frosya, YagaDomovoy, Mama], props: [RoomFront, Pencil], startImage: None, durationSec: 13, creative: ""},
  /* s5job3 — SHOT 2026-08-18 as 2026-08-18_EP1_s5job3_v1_seedance25_16s.mp4.
     Retired the moment its footage existed, for the reason written above: a job
     that stays in `all` after it is shot is a job the batch would pay for twice,
     and it also freezes every reference line it touches — the broom-in-hand
     correction below could not be made while a shot job still depended on the
     old wording. The record stays here so start-frame chains can find it. */
  {
    jobId: "s5job3",
    shots: "SH063-065",
    cast: [YagaDomovoy, Frosya, Vasya, Mama, Papa, Rusya, Musya],
    props: [RoomFront, SeatingScene5],
    startImage: Some("FRAME:scene5/2026-08-18_SCENE5_job3_START_from-s5job2-mama.png"),
    durationSec: 16,
    creative: "",
  },
  {
    jobId: "s5job1",
    shots: "SH057-059",
    cast: [YagaDomovoy, Frosya, Vasya, Mama, Papa, Rusya, Musya],
    props: [],
    startImage: None,
    durationSec: 8,
    creative: "",
  },
  {
    jobId: "s5job2",
    shots: "SH057-062",
    cast: [YagaDomovoy, Frosya, Vasya, Mama, Papa, Rusya, Musya],
    props: [RoomFront],
    startImage: Some("FRAME:scene5/2026-08-17_SCENE5_MASTER_dinner-table_author.png"),
    durationSec: 20,
    creative: "",
  },
]

/* the shot batch, kept for provenance and for start-frame lookups */
let retiredBatch: array<shotRecord> = [
  {jobId: "job10", shots: "SH018-020", cast: [Frosya, Vasya, Mama, Papa, Rusya, Musya], props: [RoomFront, Carry, Top], startImage: None, durationSec: 12, creative: ""},
  {jobId: "job11", shots: "SH021-023", cast: [Frosya, Vasya, Papa], props: [RoomFront, Top], startImage: None, durationSec: 12, creative: ""},
  {jobId: "job12", shots: "SH024-027", cast: [Frosya, Vasya, Papa, Mama, Babies], props: [RoomFront, Top], startImage: None, durationSec: 12, creative: ""},
  {jobId: "job13", shots: "SH028-029", cast: [Mama, Frosya, Babies], props: [RoomFront, Tin, Top], startImage: None, durationSec: 8, creative: ""},
  {jobId: "job14", shots: "SH030-032", cast: [Frosya, Mama, Babies], props: [RoomFront, Tin], startImage: None, durationSec: 12, creative: ""},
  {jobId: "job15", shots: "SH033-035", cast: [YagaFlight], props: [Roof, Stupa], startImage: None, durationSec: 8, creative: ""},
  {jobId: "job16", shots: "SH036-038", cast: [YagaFlight], props: [Roof, Stupa], startImage: None, durationSec: 8, creative: ""},
  {jobId: "job17", shots: "SH039-041", cast: [Frosya, Vasya, Mama, Papa, Babies], props: [RoomFront, RoomFrontLow, RoomFrontHatch, Door], startImage: None, durationSec: 8, creative: ""},
  {jobId: "job18", shots: "SH042-043", cast: [YagaDomovoy], props: [Stupa, Pomelo, Broom], startImage: Some("2026-08-14_KF_job18_start_from-job17-lastframe_hatch-puff.png"), durationSec: 12, creative: ""},
  {jobId: "job19", shots: "SH044-046", cast: [YagaDomovoy, Frosya, Vasya, Mama, Papa, Babies], props: [RoomFront, RoomFrontLow, RoomFrontHatch, Door, Stupa], startImage: None, durationSec: 8, creative: ""},
]
