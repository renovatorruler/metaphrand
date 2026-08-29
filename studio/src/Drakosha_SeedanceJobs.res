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
  record: {jobId, shots, cast, props, startImage, durationSec, creative: "", carriesLines: []},
  creativeFile: creativeDir ++ "/" ++ jobId ++ ".creative.txt",
  model,
  endImage: None,
}

/* A shot pinned at BOTH ends: the author supplies the frame it opens on and the
   frame it must finish on, and the model interpolates between them. Different
   from loopJob, where the two frames are the same one.

   This is what an outcome the model keeps getting wrong is for. The gather shot
   came back with every block on the floor swept into one long line because the
   prompt could describe "four" but could not enforce it; an end frame showing
   four in a row and the strays untouched states the answer in the only language
   that is not open to interpretation. Seedance mini takes an end frame AND
   references, which is the combination this needs — the frames pin the
   composition, the sheets carry who he is. */
let endJob = (jobId, shots, cast, props, startFrame, endFrame, durationSec, model): jobSpec => {
  record: {jobId, shots, cast, props, startImage: Some(startFrame), durationSec, creative: "", carriesLines: []},
  creativeFile: creativeDir ++ "/" ++ jobId ++ ".creative.txt",
  model,
  endImage: Some(endFrame),
}

/* endJob for a shot that carries only SOME of what the script gives its SH
   codes — name the recordings it actually holds and the duration gate sizes it
   against those. */
let endJobCarrying = (jobId, shots, cast, props, startFrame, endFrame, durationSec, model, carries): jobSpec => {
  record: {jobId, shots, cast, props, startImage: Some(startFrame), durationSec, creative: "", carriesLines: carries},
  creativeFile: creativeDir ++ "/" ++ jobId ++ ".creative.txt",
  model,
  endImage: Some(endFrame),
}

/* job() for a shot carrying only part of what the script gives its SH codes. */
let jobCarrying = (jobId, shots, cast, props, startFrame, durationSec, model, carries): jobSpec => {
  record: {jobId, shots, cast, props, startImage: Some(startFrame), durationSec, creative: "", carriesLines: carries},
  creativeFile: creativeDir ++ "/" ++ jobId ++ ".creative.txt",
  model,
  endImage: None,
}

/* A close-up built from references alone: no start frame, but recorded lines.
   2026-08-26, for v10brovi — the punch-in on Вася-мама's boil. */
let jobCarryingNoStart = (jobId, shots, cast, props, durationSec, model, carries): jobSpec => {
  record: {jobId, shots, cast, props, startImage: None, durationSec, creative: "", carriesLines: carries},
  creativeFile: creativeDir ++ "/" ++ jobId ++ ".creative.txt",
  model,
  endImage: None,
}

let loopJob = (jobId, shots, cast, props, frame, durationSec, model): jobSpec => {
  record: {jobId, shots, cast, props, startImage: Some(frame), durationSec, creative: "", carriesLines: []},
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

     THE PROMPT NEVER SAYS THE WORD "LETTER". Naming them letter tiles is an
     instruction to draw letters, in the one shot built so that none exists —
     and it is why @TILES stays unbound here too, since its tagline reads "each
     carved with one Cyrillic letter". They are wooden blocks. Verified on the
     emitted prompt, not just the creative: zero occurrences.

     THE SHOT NOW HAS A THOUGHT IN IT (author, 2026-08-24): he looks the scatter
     over and scratches his head with no idea; he pushes a couple of tiles about,
     turning it over; the idea lands and he grins a crooked, up-to-something
     grin — he has decided to spell his own mother — and only then does he
     gather. Without that middle beat he is a boy sorting tiles; with it he is a
     boy who has just thought of something he should probably not do.

     EASY BEATS FIRST, HARD BEATS LAST, so a failure comes late. The head
     scratch and the single fingertip touch are large, cheap gestures the model
     does well; the
     four slides are the fragile part and they run last. The first gather is the
     tile already under his hand and is nearly free; the longest reach is last of
     all. If it breaks on the third or fourth we trim at the break, and what
     survives is the thinking, the idea and two clean gathers — which is the shot.

     TEN SECONDS, NOT EIGHT. The added beats need the room, and since a failure
     is trimmed from the end anyway, the extra two seconds buy more usable take
     for five credits rather than more risk.

     No @TILES: the chest sheet is a whole chest, and this plate carries the
     tiles perfectly already. No @POUCH: it is backed by page-04, which @VASYA
     attaches anyway.

     THIS IS A PICKUP, NOT A RESHOOT (author, 2026-08-24). The first take is good
     up to the moment he grins, and only what follows is being reshot. The join
     is exact rather than approximate: the author built the start plate from
     FRAME 107 of that take — measured diff 0.00 against it, where two of her own
     renders of the same scene differ by 10-25 — so the pickup opens on precisely
     the frame the cut is already showing at 4.458s. Nothing has to match by eye.

     The old take is used to frame 106; this one supplies 107 onward.

     FIVE SECONDS. The looking, the scratch and the idea are already shot, so this
     buys only the four gathers and the settle onto his heels. The creative says
     so in the first line of WHAT HAPPENS — a pickup that opens with a
     settling-in beat would stutter against the frame it is joining. */
  endJob(
    "v03gather",
    "SH122",
    [Vasya],
    [],
    "2026-08-24_V03_gather_start_v3.png",
    "2026-08-24_V03_gather_END_v3.png",
    5,
    Mini,
  ),
  /* МАМА LIGHTS UP — generated, not composited. Two of the author's own renders
     of this overhead sit within 1.2px of each other: same camera, same hands,
     same tiles, differing only in the glow and where the finger is. They become
     the start and end frames and the model generates the travel between them.

     KLING3_0, NOT SEEDANCE. Measured on our own write-loop footage of 2026-08-20,
     where the same plate was pinned at both ends: kling3_0 held it at 2.88 in
     the first frame and 3.10 in the last, and — the number that matters —
     drifted only to 3.60 through the MIDDLE. veo3_1_lite pinned the ends at
     2.07 but swung to 7.48 in between, which is the character turning into
     somebody else; mini with references peaked at 6.51. Seedance mini on the
     gather shot came back at 9.98 and 16.61. Kling is the only one on the
     account that stays with the plate the whole way through.

     Kling's flatness is a liability where a shot needs a big change and a virtue
     here, because almost nothing changes: four blocks that must not move, one
     hand that must not move, and a fingertip sliding sideways. The whole event
     is a glow arriving four times.

     Kling takes no image references at all, which costs nothing — no face is in
     frame, and the author's plates carry the tiles and the letters. */
  endJobCarrying(
    "v04read",
    "SH123",
    [],
    [],
    "2026-08-25_V04_MAMA_start_unlit.png",
    "2026-08-25_V04_MAMA_END_all-lit.png",
    6,
    Kling30,
    ["line62a_VASYA_read_cut.mp3"],
  ),
  /* HE TRIES THE WORD, AND THE LIGHT ANSWERS. The author's plate has him sitting
     with the word already lit in front of him, which is the state the overhead
     insert leaves him in — so this shot opens on a boy who has just read
     something and is pleased with himself, throws the word away lightly, and
     only then tries the other one.

     THE UNCERTAIN ВЖУХ, AND THE BEAT OF NOTHING. Settled 2026-08-23 and it still
     holds: the arms-raised transformation card is a boy who has done this
     before, and he has not. He tries the sound the way you try a light switch in
     an unfamiliar room, nothing happens, and then it happens TO him.

     THE LIGHT COMES OUT OF THE BLOCKS. The author, 2026-08-25 — the glow grows
     and fills the screen. That is better than the wipe we had planned, because
     it says the WORD did this rather than that he did: he read four blocks and
     the four blocks answer. It also means the transformation needs no pose.

     MINI, NOT KLING. This is a performance — a face crossing from delight to a
     question to nothing-happened to alarm — and Kling takes no references and
     stays flat against its plate. Kling is right where a shot is a state change;
     this one is acting. */
  /* THE WHOLE TRANSFORMATION IN ONE TAKE. He reads, tries the word, nothing
     happens, the light answers, and when it drains SHE is crouched on all fours
     where he sat — startled — and comes up onto her feet.

     THE CROUCH IS THE AUTHOR'S, AND IT SOLVES THE FRAME. Her standing height
     does not fit this framing: measured, he occupies 451px sitting and Мама
     standing would put her head 400-490px above the top of frame. Arriving
     crouched fits; coming up out of it makes the height a MOVE rather than a
     problem, and the prompt says nothing at all about the frame — only what she
     does — because a framing instruction the model cannot satisfy is what pushes
     it to shrink her instead, and a child-sized Вася-мама kills the babies
     mistaking her for their mother.

     THE CAMERA MOVES, AND MINI CAN DO THAT. I claimed it could not and the
     author asked what I was basing that on: nothing. SHOT1, already in the cut
     and approved, is a mini push from the family wide onto the babies — edge
     energy falling steadily 2.98 to 2.16 across six seconds. What we have no
     evidence for is a move, a hold, and a move BACK, which is what this shot
     needs. That is the thing being tested.

     NOT the bare room plate: @FLOOR_AFTER shows the blocks and the pouch still
     there, so nothing invites them to vanish with him. */
  jobCarrying(
    "v05single",
    "SH123-124",
    [Vasya, VasyaMama],
    [FloorAfter],
    "2026-08-25_V05_vzhukh_start_v2.png",
    15,
    Mini,
    ["line63a_VASYA_mama-vzhukh.mp3"],
  ),
  /* THE EYEBROWS — SP120-121. Мама's dry line, his sulk, and the ВЖУХ.

     TWO SPEAKERS, ONE SHOT. The line and the reaction have to share a frame or
     the joke is split across a cut and dies. Мама speaks 1.0-3.1, he shouts
     6.2-7.4, and the four seconds between are the sulk building.

     THE SHOT STOPS BEFORE THE MAGIC. A transformation is a light event and V05
     proved it needs its own space, so this one ends on him rigid and glaring —
     and the creative says outright that nothing glows, flashes or changes shape
     here, because a model handed a shouted ВЖУХ will otherwise invent one.

     ANGER, AND IT IS A CHILD'S ANGER. Fists driven down at the sides, shoulders
     hunched to the ears, chin tucked, everything held in — a small boy who has
     been made fun of, wearing a grown woman. Мама stays SATISFACTION throughout
     and is never rattled; the whole gag is that only one of them is upset. */
  /* THE RESCUE — SP118-119. Мама walks in and takes the babies off him.

     ONE SHOT, NOT TWO. Her arrival and both lifts are a single continuous
     action; cutting into it throws away the entrance, which is the whole point
     — a second identical woman walking calmly into frame.

     THE MODEL HAS NO CONTEXT AND THAT IS USABLE. It does not need to be told
     this is his mother or that he is a boy inside her body. It needs the
     picture: two women dressed identically, same height, same build,
     distinguishable ONLY by the eyebrows — huge and shaggy on one, ordinary on
     the other. Story explanation would cost characters and buy nothing.

     ЕЁ ЛИЦО — SATISFACTION, NOT ALARM. Мама has done this a thousand times and
     is quietly amused. That is the joke: the panic is entirely on his side.

     PLATE IS V08'S LAST FRAME — both babies already clamped on, so the shot
     opens mid-crisis with nothing to establish. */
  /* SCENE 9, SHOT 3 — the deal. SP129, and the line the whole series runs on:
     he learns the three letters, she writes the car.

     PLATE IS 1C'S LAST FRAME. Author, 2026-08-28: "we could use one of her
     close-ups or a last frame of the last video we took of her." The last frame
     wins because she is already upset, already close, and her hand is still up
     from counting — so the deal grows out of the beat before it instead of
     resetting. Her existing close-ups all have her in the wrong state: grinning,
     or staring in disbelief from scene 8.

     ONE FINGER, NOT THREE. The counting hand folds down to a single finger as
     she turns. Author, 2026-08-28: "make sure she's not jabbing three fingers
     against him. She's pointing with one finger towards him." The script agrees
     — «с жаром тыча в него пальцем», singular — and it is the gesture converting
     from counting to accusing that makes the turn read.

     THE PENCIL STAYS BEHIND HER EAR. She put it there in 1C and does not take it
     down; this is also where EP2 needs the audience to know she keeps it. */
  job(
    "s9deal",
    "SH140",
    [Frosya],
    [Pencil],
    Some("2026-08-28_S9_deal_start_from1C.png"),
    9,
    Mini,
  ),
  /* SCENE 9, SHOT 2 — Вася's «И что теперь?». SP128.

     THE PLATE IS THE CLOSE-UP WITH NO HANDS IN IT. Author, 2026-08-28: "we're
     gonna use the close-up where you cannot see his hands." That matters twice —
     he is subdued in it, which is where scene 8 left him, and with his hands out
     of frame nothing has to match what he was holding a moment earlier.

     HE IS NOT NEUTRAL AT THE START. He has been flat since the babies were
     peeled off him and Мама called him out. This is the first time in the scene
     that anyone has needed anything from him, and his question is what pulls
     Фрося out of her own head — she says the missing letters to herself, and he
     is the one who answers it.

     COPIED FROM s8fu, the other close single on him that landed first take: same
     block order, same length, same locked-off camera. What differs is the line,
     and that he begins deflated rather than surprised. */
  job(
    "s9vasyaask",
    "SH139",
    [Vasya],
    [],
    Some("2026-08-28_S9_VASYA_cu_subdued.png"),
    5,
    Mini,
  ),
  /* SCENE 9, SHOT 1B — МАШИНА and the failure. SP125-130.

     THE FAILURE IS A SPARK THAT DIES, NOT LETTERS THAT DIE. Author, 2026-08-28:
     "the spark from her pencil is gonna go to the floor as usual and starts
     glowing and then it's just gonna die down." Same path as every success —
     СОК, САЛАТ, МАК all send the spark down and grow the thing out of it — and
     it stops halfway. The audience has been taught this path four times, so the
     failure needs no explaining.

     THE SPARK LANDS CLEAR OF THE TILES. Author asked whether it mattered that it
     might land among them: it does. A glow under the tiles reads as the TILES
     doing the magic, the embers and dust would settle on faces that are already
     a repaint, and those same tiles have to stay pristine because she builds
     САМОКАТ out of them two shots later. So the landing spot is bare board,
     short of every tile.

     A FINAL POOF. Author: "when the spark is dying down, there should be a final
     poof." It is the anti-chime — every success ends chime-and-a-thing, so the
     failure needs a full stop of its own or it merely trails off. It also gives
     her face one moment to drop on instead of a slow sag, and the drifting dust
     keeps something moving at the end of the shot, which is where v09 froze.

     ONE TAKE FROM THE WRITING TO THE DROP. Author: "why would we cut it on the
     failure? That's the worst part to cut." The dud only lands because it
     arrives inside the same breath as the expectation.

     PLATE IS THE AUTHOR'S OWN, and the cut from 1A is an ordinary angle change —
     1A ends on the back of her head, which cannot carry this shot. */
  job(
    "s9mashina",
    "SH138",
    [Frosya],
    [Pencil],
    Some("2026-08-28_S9_1B_start_v3_master-conformed.png"),
    15,
    Mini,
  ),
  /* SCENE 9, SHOT 1A — the recovery. SP124, and the handover from scene 8.

     NO TILES PROP. The start plate already fixes the tile layout exactly — Т О О
     К Л К past her head, Б С А М К in front of her — and @TILES binds
     D-MAM-CHEST-01_approved.png, which is Мама's CHEST full of tiles. Attaching
     it would give the model a second authority for something the plate has
     already settled, and could put a treasure chest on the floorboards. Author,
     2026-08-28: "you should not be giving the model what the tiles look like as
     a separate prop." Two competing anchors for one thing is the v09 failure that
     cost 235 credits.

     THE CUT IS HERE AND NOT LATER. 1B carries the writing, the точка, the chime
     and the failure in ONE take. Author: "why would we cut it on the failure?
     That's the worst part to cut" — the dud only lands because it arrives inside
     the same breath as the expectation. Cutting at "ready to write" also means
     the cheap half proves the slate angle and her position before the expensive
     half spends on a composite.

     THE START FRAME IS THE PEAK OF A LAUGH, which invites the model to keep
     laughing. The laugh is written as ENDING from frame one and no new wave
     arrives; her eyes open early or she reads as asleep rather than spent.

     THE SLATE FACE IS NEVER SEEN. It is a blank prop — the word appears as
     composited letters in the air in 1B. Show the model a writing surface and it
     writes its own word on it. */
  job(
    "s9recover",
    "SH137",
    [Frosya],
    [Pencil],
    Some("2026-08-28_S9_shot1_start_author.png"),
    6,
    Mini,
  ),
  /* SH119 — SP109, Бабушка-Яга's approving reaction. The one shot scene 8 was
     missing: without it the cut goes straight from Мама's thank-you to Вася's
     ask and changes subject with no breath.

     THE PENCIL TUCK IS CUT FROM THIS SHOT. SP109 also has Фрося tucking the
     pencil behind her ear, but that gesture already lives in scene 9 at SP136
     where she needs both hands for the scooter handlebars — and that is where
     the audience must learn she carries it on her person, because EP2 has the
     beast steal it off her. Author decision, 2026-08-26.

     NOBODY ELSE IS NAMED IN THE CREATIVE. She is reacting to the poppy going
     from Фрося to Мама, but both are off-frame and the model has no story. Given
     their names it would draw them. It gets the direction her eyes travel and
     nothing about who is there.

     THE GAZE IS STATED AS A RANGE, NOT A PROHIBITION. Author, 2026-08-26: "if
     I'm gonna find out that you're just gonna write in the prompt that at no
     point she's turning towards the left of frame, I'm gonna shut you down."
     Naming the side she must avoid puts that side in front of the model. So the
     creative says where the turn starts, how far it goes and where it stops, and
     assertNoNegatedDirection refuses the job if a negated screen direction ever
     reaches the emitted text.

     PLATE IS THE AUTHOR'S OWN RE-RENDER at 1672x941, above the 1280x720 ceiling
     mini outputs. Мама is out of frame in it, which matters: at SP109 she is
     holding the poppy, and any frame showing her empty-handed would contradict
     the shot before. The raised steaming cup is the gift — it gives Яга a real
     action to play and the steam guarantees motion, so a four-second cutaway of
     a woman already smiling cannot come back frozen the way V09 did. */
  job(
    "sh119yaga",
    "SH119",
    [YagaDomovoy],
    [],
    Some("2026-08-26_SH119_yaga-hum_start.png"),
    4,
    Mini,
  ),
  jobCarrying(
    "v11laugh",
    "SH136",
    [Frosya],
    [Pencil],
    "2026-08-26_V11_frosya-laugh_start.png",
    9,
    Mini,
    ["line68_FROSYA_laugh.mp3"],
  ),
  jobCarrying(
    "v10brovi",
    "SH133-135",
    [Mama, VasyaMama, Vasya, Rusya, Musya],
    [TwoMamas],
    "2026-08-26_V10_brovi_start.png",
    14,
    Mini,
    ["line66_MAMA_brovi.mp3", "line67_VASYAMAMA_vzhukh.mp3"],
  ),
  endJobCarrying(
    "v09rescue",
    "SH131-132",
    [VasyaMama, Mama, Rusya, Musya],
    [TwoMamas],
    "2026-08-26_V09_mama-rescue_start.png",
    "2026-08-26_V09_rescue_END_author.png",
    12,
    Mini,
    ["line65_VASYAMAMA_ya-ne-mama.mp3"],
  ),
  /* THEY REACH HER — SP116. The babies arrive at Вася-мама and take hold.

     WHAT SHE IS DOING — SHE IS CELEBRATING, AND IT IS THE AUTHOR'S IDEA. V06 and
     V07 put nineteen seconds between the transformation and this shot, so a held
     pose reads as a freeze. The author, 2026-08-26: "maybe he's jumping around
     screaming, Ya mama, ya mama. Сработало" — and, on the silence generally:
     "it's a show that's supposed to help kids learn Russian, and there is
     awfully lots of silent scenes for this purpose." She is right on both. The
     raised hands in the plate are a victory pose, which needs no explaining, and
     the scene gets Russian in it.

     I FIRST CLAIMED THE PLATE SHOWED HER HOLDING THE MATCH AND HER BRAID. It
     does not — her hands are open and empty, the braid hangs untouched beside
     them, and the match is sitting in the apron pocket where the character sheet
     puts it. Nothing in V05 ever told her to pick anything up. That was invented,
     and it is the same failure as the geography errors: describing what I expect
     instead of what the frame shows.

     THE SHOT RUNS ON PAST THE GRAB. The author: "we should not just cut it on
     babies taking a bite, we should continue with the scene where he's
     complaining about them eating him." So SP117 plays in the same setup rather
     than as a separate shot.

     TIMED ON THE REAL RECORDINGS, NOT ON GUESSES. line63b is 3.28s and line64 is
     4.56s, both in ВАСЯ's voice — 314Hz and 324Hz against his cast reference of
     305Hz, a climb from baseline to excited to panicking. The beats are written
     to those numbers: first line 0.5-3.8, babies enter at 2.9 while she is still
     shouting, grab at 5.2, her head down at 6.0, second line 6.8-11.4, and the
     last stretch is Муся chewing the apron.

     GEOGRAPHY OFF ROOM_MAP v7. Camera stands at Фрося's side of the work area,
     so Вася-мама shows the braid TO THE LENS. The rug is north-west of her, so
     the babies enter SCREEN-LEFT and take her RIGHT flank while she is turned
     toward the camera and away from them.

     NO CEILING, STATED AS A LOCK. The author's repaint removed V05's low plank
     ceiling and re-hung the string lights on a wire across the stone wall. That
     is a change the model will happily undo, so the BACKGROUNDS block says
     outright that the wall runs up out of frame and no beams, planks or roof
     appear.

     FIRST JOB UNDER THE EMOTION GATE. Each face is named and differentiated by
     WHICH PART does the work, which is the v07table lesson: Вася-мама SHOCK
     (mouth and brows), Руся GLEE (mouth and eyes), Муся DETERMINATION (jaw and
     brow, and she never opens her mouth). Not three volumes of the same
     instruction. */
  jobCarrying(
    "v08babies",
    "SH128-130",
    [VasyaMama, Rusya, Musya],
    [],
    "2026-08-26_V08_babies-arrive_start.png",
    15,
    Mini,
    ["line63b_VASYAMAMA_ya-mama.mp3", "line64_VASYAMAMA_oni-menya-edyat.mp3"],
  ),
  /* ФРОСЯ SEES IT — the reaction the shot list never had. The author, on the
     table wide: "Фрося is not in the shot because she was next to him when the
     transformation happened. It's almost weird to leave her out. It feels like
     her reaction shot should have been first." So this cuts between V05 and
     V07table.

     THE EYELINE CLIMB IS THE SHOT. This is the only place in the sequence where
     somebody at floor level registers the new height: her eyes start level with
     the lens, where a sitting boy's face was, and end far above it. The camera
     stays LOCKED and low — if it tilts up with her we lose the face doing the
     work, and the height stops being something a person noticed and becomes
     something the camera did.

     SHE IS NOT ASTONISHED THAT MAGIC WORKS. She owns the pencil and made a
     poppy out of nothing four shots ago. What floors her is the SCALE: she wrote
     МАК and got a flower, he wrote МАМА and got a whole person, and she is the
     only one in the house who can measure the difference. So the shot ends on
     her studying it — gaping first, then mouth closed and brows down and eyes
     working — which is a change the gate accepts and is also the opposite of a
     punchline.

     NO LAUGH ANYWHERE IN THIS SHOT. The author, 2026-08-26: "I disagree that
     there should be any hint of future laughter. In the end, she's laughing
     because of the whole baby incident." A first draft had the laugh arriving
     here and caught behind her hand. That both SPENDS the collapse and
     MIS-ATTRIBUTES it — she is not laughing at the transformation, she is
     laughing at the babies eating him. The prompt now carries positive locks
     saying her mouth never turns up after the first grin goes.

     THE AUTHOR'S PLATE, 2026-08-26, AND IT IS THE MAP'S «КАДР 3»: camera at the
     table end looking back at Фрося with the BACK PLATE behind her, which
     ROOM_MAP_v4 says we already have. ВАСЯ-МАМА IS IN THE FRAME — the tall
     out-of-focus dusty-rose skirt with the square red-stitched patch at the
     extreme left edge, which matches C-VASMAMA-01 exactly. That occlusion is
     what makes the shot: her skirt fills the height of the picture and Фрося's
     head reaches a third of the way up, so the height is told by COMPOSITION
     and not by an eyeline climb I have to ask the model to animate.

     WHICH FLIPS THE BEAT, AND FOR THE BETTER. The plate already has her
     grinning up at the standing woman, so the shot no longer climbs — it opens
     on the grin and puts it out. She told him to spell it himself and it
     worked, and she is pleased with herself for exactly one moment before what
     he actually made lands on her. Two beats, four seconds.

     SHE IS NOT BOUND AND NOT NAMED, even though she is in frame. Only a skirt
     is visible, the prompt describes it as a soft out-of-focus shape and nails
     it in place, and binding her sheet would invite the model to bring the
     rest of her into the picture.

     ФРОСЯ IS page-05, «ДО карандаша», for the same reason V02 is: the pencil
     lies on the floorboards in this plate, not in her hair. ВАСЯ-МАМА is not
     bound and never named — she is past the lens, off frame, and the prompt
     says only that whoever she is looking at never enters the picture. */
  job(
    "v06frosya",
    "SH124B",
    [Frosya],
    [Pencil],
    Some("2026-08-26_V06_frosya-reaction_start_v2.png"),
    4,
    Mini,
  ),
  /* THE TABLE TURNS — SP115. Everyone at the table looks screen-right at the
     thing that just happened, off frame.

     FOUR DIFFERENT FACES, NOT ONE SHARED ONE. The author: "I feel like it would
     be weird if they all stared in disbelief, since I'm sure Grandma would not
     be in disbelief." She is right and it is a story point. Яга gave him the
     gift; she is the one person in the room who knows exactly what she is
     looking at, so she is the one whose face does not fall — and the wide is
     funnier for it, because everybody freezes and one person keeps drinking.
     Папа carries the plain shock. Мама is not shocked at all: she is looking at
     her own face, which is why the eyebrow check reads as CHECKING rather than
     as one more beat of astonishment.

     NO NEW PLATE. The shot is a CHANGE from a known state, which is what a start
     frame is for; the scene's own opening plate already holds all five of them
     mid-conversation, and rendering them pre-frozen would throw away the turn.
     Same five references SHOT1 used, same start frame.

     WHERE SHE IS STANDING COMES FROM THE MAP, NOT FROM MEMORY. ROOM_MAP_v4:
     the РАБОЧАЯ ЗОНА sits SOUTH of the table, toward the camera and a little
     east, and the map's own arrow runs the babies from their rug diagonally
     down-right into it. So Вася-мама is near the LENS, just past its right-hand
     side — not out at the far right edge on the table's plane.

     THE EYELINE IS LEVEL FOR THE ADULTS AND UP ONLY FOR THE BABIES, AND THAT
     COMES OUT OF THE SCALE REGISTRY RATHER THAN OUT OF MY HEAD. I got this
     wrong twice: first "low", because I read her floor POSITION off the map and
     never converted it into a HEIGHT; then "craning up", after the author asked
     why seated people would look down at a standing woman — an overcorrection I
     made without doing the arithmetic either.

     The arithmetic, from OBJECT_SCALE_REGISTRY_v1: Мама stands 9.91cm, so her
     eyes sit near 9. The adults are on spools with their eyes near 6 — a rise of
     about 3cm across roughly 20cm of floor between table and work area, which is
     about 8 degrees. That is level with a hint of lift, not a craned neck. The
     babies are the exception at roughly 3cm of eye height: about 17 degrees,
     which does read, so they are the only two whose heads tip back.

     THE LESSON IS THE GENERAL ONE. An angle is a ratio, and I twice supplied one
     side of it and guessed the other. The registry holds the heights and the map
     holds the distances; neither answer is available from either document
     alone.

     THAT INVERTS THE TURNS, WHICH IS WHAT THE FIRST DRAFT GOT WRONG. Папа sits
     at the screen-right end already facing screen-left; a turn to the right
     EDGE swings him away from the camera and takes the biggest laugh in the
     shot with it. Turning to the near point brings every face round to the
     FRONT of the shot instead: Папа travels furthest and ends almost square to
     the lens, Мама and Яга were already facing that way and only come forward.
     The babies then crawl toward camera and out of the bottom-right corner,
     which is the map's arrow exactly.

     ВАСЯ-МАМА IS NOT BOUND AND IS NEVER NAMED. The prompt says only that the
     thing they look at never enters frame. Naming her is an instruction to
     draw her. This worked: she never appeared.

     SHOT AND IN THE CUT, BUT NOT APPROVED. v1 came back 2026-08-26 with the
     staging right and the performances wrong: all three adults landed on the
     same worried face, and Мама's close-up reads as a scowl. The author is
     keeping it and will reshoot only if allowance remains at the end of the
     show. The full defect list and the reshoot brief live in
     production/seedance_batch/2026-08-26_V07_DEFECTS_reshoot-brief.md — read it
     BEFORE touching this creative again.

     THE ONE-LINE LESSON, because it generalises past this shot: three different
     INTENTIONS written as three overlapping sets of ANATOMY collapse into one
     face. Папа's "brows shoot up", Мама's "brows draw in", Яга's "one eyebrow
     climbs" are the same instruction at three volumes, and the model averaged
     them. Differentiate by which PART of the face does the work — Папа the
     mouth, Яга the eyes and the cup, Мама the closed mouth and the hand — not
     by degrees of the same part. */
  job(
    "v07table",
    "SH125-127",
    [Papa, YagaDomovoy, Mama, Rusya, Musya],
    [],
    Some("2026-08-22_S8_SHOT1_table_start.png"),
    15,
    Mini,
  ),
  jobCarrying(
    "v05vzhukh",
    "SH123",
    [Vasya],
    [],
    "2026-08-25_V05_vzhukh_start.png",
    6,
    Mini,
    ["line63a_VASYA_mama-vzhukh.mp3"],
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
  {jobId: "s6jobF", shots: "SH081", cast: [Mama], props: [RoomFront], startImage: None, durationSec: 11, creative: "", carriesLines: []},
  /* SCENE 6, SHOT AND ACCEPTED 2026-08-18. Retired the moment the footage
     existed, which is also what frees the choreography to keep improving: these
     five creatives predate assertHandsWritten and the facial-anatomy rule, and
     left in `all` they would hold the dry run red forever over prompts whose
     clips are already cut. Their records stay here for start-frame lookups.

     s6jobE is a PARTIAL accept: 4.45s of it is used and Мама's third shot was
     reshot as s6jobF. The record keeps the generation that actually happened. */
  {jobId: "s6jobA", shots: "SH066-068", cast: [YagaDomovoy, Frosya], props: [RoomFront, Pencil], startImage: None, durationSec: 12, creative: "", carriesLines: []},
  {jobId: "s6jobB", shots: "SH069-073", cast: [Frosya, YagaDomovoy, Vasya], props: [RoomFront, Pencil], startImage: None, durationSec: 13, creative: "", carriesLines: []},
  {jobId: "s6jobC", shots: "SH074-077", cast: [Vasya, YagaDomovoy, Frosya], props: [RoomFront, Pencil], startImage: None, durationSec: 17, creative: "", carriesLines: []},
  {jobId: "s6jobD", shots: "SH078", cast: [YagaDomovoy, Frosya, Vasya], props: [RoomFront, Pencil], startImage: None, durationSec: 8, creative: "", carriesLines: []},
  {jobId: "s6jobE", shots: "SH079-081", cast: [Frosya, YagaDomovoy, Mama], props: [RoomFront, Pencil], startImage: None, durationSec: 13, creative: "", carriesLines: []},
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
    carriesLines: [],
  },
  {
    jobId: "s5job1",
    shots: "SH057-059",
    cast: [YagaDomovoy, Frosya, Vasya, Mama, Papa, Rusya, Musya],
    props: [],
    startImage: None,
    durationSec: 8,
    creative: "",
    carriesLines: [],
  },
  {
    jobId: "s5job2",
    shots: "SH057-062",
    cast: [YagaDomovoy, Frosya, Vasya, Mama, Papa, Rusya, Musya],
    props: [RoomFront],
    startImage: Some("FRAME:scene5/2026-08-17_SCENE5_MASTER_dinner-table_author.png"),
    durationSec: 20,
    creative: "",
    carriesLines: [],
  },
]

/* the shot batch, kept for provenance and for start-frame lookups */
let retiredBatch: array<shotRecord> = [
  {jobId: "job10", shots: "SH018-020", cast: [Frosya, Vasya, Mama, Papa, Rusya, Musya], props: [RoomFront, Carry, Top], startImage: None, durationSec: 12, creative: "", carriesLines: []},
  {jobId: "job11", shots: "SH021-023", cast: [Frosya, Vasya, Papa], props: [RoomFront, Top], startImage: None, durationSec: 12, creative: "", carriesLines: []},
  {jobId: "job12", shots: "SH024-027", cast: [Frosya, Vasya, Papa, Mama, Babies], props: [RoomFront, Top], startImage: None, durationSec: 12, creative: "", carriesLines: []},
  {jobId: "job13", shots: "SH028-029", cast: [Mama, Frosya, Babies], props: [RoomFront, Tin, Top], startImage: None, durationSec: 8, creative: "", carriesLines: []},
  {jobId: "job14", shots: "SH030-032", cast: [Frosya, Mama, Babies], props: [RoomFront, Tin], startImage: None, durationSec: 12, creative: "", carriesLines: []},
  {jobId: "job15", shots: "SH033-035", cast: [YagaFlight], props: [Roof, Stupa], startImage: None, durationSec: 8, creative: "", carriesLines: []},
  {jobId: "job16", shots: "SH036-038", cast: [YagaFlight], props: [Roof, Stupa], startImage: None, durationSec: 8, creative: "", carriesLines: []},
  {jobId: "job17", shots: "SH039-041", cast: [Frosya, Vasya, Mama, Papa, Babies], props: [RoomFront, RoomFrontLow, RoomFrontHatch, Door], startImage: None, durationSec: 8, creative: "", carriesLines: []},
  {jobId: "job18", shots: "SH042-043", cast: [YagaDomovoy], props: [Stupa, Pomelo, Broom], startImage: Some("2026-08-14_KF_job18_start_from-job17-lastframe_hatch-puff.png"), durationSec: 12, creative: "", carriesLines: []},
  {jobId: "job19", shots: "SH044-046", cast: [YagaDomovoy, Frosya, Vasya, Mama, Papa, Babies], props: [RoomFront, RoomFrontLow, RoomFrontHatch, Door, Stupa], startImage: None, durationSec: 8, creative: "", carriesLines: []},
]
