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
type seedanceModel = Mini | V20 | V25

let modelName = m =>
  switch m {
  | Mini => "seedance_2_0_mini"
  | V20 => "seedance_2_0"
  | V25 => "seedance_2_5"
  }

let modelMaxSec = m =>
  switch m {
  | Mini | V20 => 15
  | V25 => 30
  }

let modelMaxRefs = m =>
  switch m {
  | Mini | V20 => 9
  | V25 => 30
  }

let modelCreditsPerSec = m =>
  switch m {
  | Mini => 2.5
  | V20 => 4.5
  | V25 => 6.5
  }

type jobSpec = {record: shotRecord, creativeFile: string, model: seedanceModel}

let job = (jobId, shots, cast, props, startImage, durationSec, model): jobSpec => {
  record: {jobId, shots, cast, props, startImage, durationSec, creative: ""},
  creativeFile: creativeDir ++ "/" ++ jobId ++ ".creative.txt",
  model,
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
  job("s7jobA", "SH082-083", [Mama, Frosya, Vasya], [RoomBack, RoomFront, Chest, Pencil], None, 12, Mini),
  job("s7jobB", "SH084-086", [Mama, Frosya, Vasya], [RoomBack, Chest, Pencil], None, 13, Mini),
  job("s7jobC", "SH087-090", [Mama], [RoomBack, Chest, Tiles], None, 13, Mini),
  job("s7jobD", "SH091", [Vasya], [RoomFront, Tiles], None, 10, Mini),
  job("s7jobE", "SH092-093", [Mama, Frosya, Vasya], [RoomBack, RoomFront, Chest, Tiles], None, 14, Mini),
  job("s7jobF", "SH094-095", [Frosya, Mama], [RoomBack, RoomFront, Tiles], None, 10, Mini),
  job("s7jobG", "SH098-101", [Vasya, Frosya, YagaDomovoy, Mama], [RoomFront, RoomBack, Pouch, Broom], None, 15, Mini),

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
