/* Frosya and Vasya — Episode 2 English table read, v2.

   This is a surgical narrator replacement, not a new full-cast performance:
   - Bella performs every English narration/action block.
   - Existing v1 character performances are recovered with ElevenLabs forced
     alignment and cut locally with ffmpeg.
   - The four character-only v1 takes are reused whole, preserving their pauses.
   - No sound-effects mix is performed here.

   The v1 parser/chunker output is the immutable input contract. Nothing in this
   program writes a v1 path. Every generated artifact contains V2 in its name or
   lives below cache_v2/.

   Run from studio/:
     DRY=1 node src/Drakosha_Ep2TableReadV2.res.mjs
     PAID=1 node src/Drakosha_Ep2TableReadV2.res.mjs

   DRY=1 always wins over PAID=1 and makes zero paid calls. A missing paid cache
   fails closed unless PAID=1 is present. */

open Cinema_Backends

@val @scope(("process", "env")) external envDry: option<string> = "DRY"
@val @scope(("process", "env")) external envPaid: option<string> = "PAID"
@val @scope(("process", "env")) external envRerenderMixed: option<string> = "RERENDER_MIXED"
@val @scope(("process", "env")) external envProbeChunk: option<string> = "PROBE_CHUNK"
@val @scope("process") external exit: int => unit = "exit"

exception TableReadV2(string)

let dir = "../stories/drakosha/audio/ep2_table_read"
let v1PlanPath = dir ++ "/ep2_table_read_plan.json"
let v1ManifestPath = dir ++ "/EP2_FULL_CAST_TABLE_READ.manifest.json"
let v1AudioPath = dir ++ "/EP2_FULL_CAST_TABLE_READ.mp3"
let v2PlanPath = dir ++ "/ep2_table_read_V2_plan.json"
let v2ManifestPath = dir ++ "/EP2_FULL_CAST_TABLE_READ_V2.manifest.json"
let v2OutputPath = dir ++ "/EP2_FULL_CAST_TABLE_READ_V2.mp3"
let cacheDir = dir ++ "/cache_v2"
let stemDir = cacheDir ++ "/stems"
let pipelineVersion = "drakosha-ep2-table-read-v2"
let rerenderPipelineVersion = "drakosha-ep2-table-read-v2-rerender-mixed"

let bellaVoiceId = "hpp4J3VqNfWAUOO0d1Us"
let bellaVoice = "Bella - Professional, Bright, Warm (US)"

type segment = {
  order: int,
  blockId: string,
  scene: string,
  kind: string,
  speaker: string,
  direction: string,
  tag: string,
  text: string,
}

type chunk = {
  id: string,
  scene: string,
  kind: string,
  segments: array<segment>,
  sourceSegments: array<segment>,
}

type v1Take = {id: string, scene: string, path: string, duration: float}
type charTiming = {text: string, start: float, end_: float}
type alignment = {characters: array<charTiming>, loss: float}
type relativeBlock = {blockId: string, start: float, end_: float}

type piece = {
  id: string,
  chunkId: string,
  scene: string,
  path: string,
  sourceGroup: string,
  sourcePath: string,
  sourceStart: float,
  sourceEnd: float,
  sourceKind: string,
  blocks: array<relativeBlock>,
}

let fail = message => raise(TableReadV2(message))
let trim = Js.String2.trim
let pathString = (Path(value)): string => value
let jsonObject = (j: Js.Json.t, label: string): Js.Dict.t<Js.Json.t> =>
  switch Js.Json.decodeObject(j) {
  | Some(value) => value
  | None => fail(label ++ " must be a JSON object")
  }
let field = (o: Js.Dict.t<Js.Json.t>, key: string): option<Js.Json.t> => Js.Dict.get(o, key)
let stringField = (o, key, label): string =>
  switch field(o, key)->Belt.Option.flatMap(Js.Json.decodeString) {
  | Some(value) => value
  | None => fail(label ++ "." ++ key ++ " must be a string")
  }
let numberField = (o, key, label): float =>
  switch field(o, key)->Belt.Option.flatMap(Js.Json.decodeNumber) {
  | Some(value) => value
  | None => fail(label ++ "." ++ key ++ " must be a number")
  }
let arrayField = (o, key, label): array<Js.Json.t> =>
  switch field(o, key)->Belt.Option.flatMap(Js.Json.decodeArray) {
  | Some(value) => value
  | None => fail(label ++ "." ++ key ++ " must be an array")
  }

let parseSegment = (j: Js.Json.t): segment => {
  let o = jsonObject(j, "segment")
  {
    order: numberField(o, "order", "segment")->Belt.Float.toInt,
    blockId: stringField(o, "block_id", "segment"),
    scene: stringField(o, "scene", "segment"),
    kind: stringField(o, "kind", "segment"),
    speaker: stringField(o, "speaker", "segment"),
    direction: stringField(o, "direction", "segment"),
    tag: stringField(o, "tag", "segment"),
    text: stringField(o, "text", "segment"),
  }
}

/* These are the eleven approved action-line repairs in the v1 renderer. Keeping
   them explicit makes an older/stale plan incapable of silently restoring the
   rough wording. */
let narrationFix = (id: string): option<string> =>
  switch id {
  | "E2SP061" =>
    Some("The word flashes. A soft chime and an airy poof. A large fluffy wad of white cotton appears beside it. Rusya immediately plunges both hands into it. Musya acquires a fluffy white mustache.")
  | "E2SP077" =>
    Some("Frosya pushes off. Whizz-whizz—wheels thump over the plank. The scooter flies off the end of the ramp. Frosya reaches out and strikes the bell.")
  | "E2SP113" =>
    Some("Vasya-Wolf leaps onto the ramp, throws back his head, and howls. A small but genuine wolf howl travels beneath the porch and into the earth. When he finishes, he jumps back onto the fixed masonry landing beside Frosya.")
  | "E2SP124" =>
    Some("The bell tears free of its thread, lands on the tilted boards, and rolls toward the bright edge of the porch. Ding… ding… faster and faster. It slips beneath the outer railing, drops into the drainage groove, and vanishes beyond the line of daylight.")
  | "E2SP128" =>
    Some("The creature whips the vine around and throws Vasya-Wolf. A whistle and a soft poof. The wolf lands in Frosya’s cotton.")
  | "E2SP141" =>
    Some("Vasya returns to himself. Enraged at losing the pencil, the creature growls, loops a new vine around the outer crossbeam, and yanks it downward. The boards crack more sharply. Papa sinks lower beneath the weight.")
  | "E2SP146" =>
    Some("The word flashes. A metallic chime. A short, sturdy crowbar appears on the stone.")
  | "E2SP163" =>
    Some("With one hand, Papa guides the brace’s lower end toward the notch. A wooden thunk. The brace seats back into place.")
  | "E2SP165" =>
    Some("The rising beam jerks the vine wrapped around it. Roots tear. The root creature is ripped out of the earth and tumbles into the drainage groove, scattering clods of black soil.")
  | "E2SP166" =>
    Some("The creature scrambles up, looks back at the pencil in Frosya’s hand, and dives into a dark gap among earth and ordinary roots. The dry rustle rapidly recedes.")
  | "E2SP190" =>
    Some("The girl slips the bell into her pocket and walks away. With each step, the bell rings more faintly inside her pocket.")
  | _ => None
  }

let applyApprovedFixes = (s: segment): segment => {
  let fixedText = switch narrationFix(s.blockId) {
  | Some(text) => text
  | None => s.text
  }
  /* The first delivery is slow and exact; the final ВЖУХ is separately firm.
     The inner [firmly] tag is already embedded at the correct phrase boundary. */
  if s.blockId == "E2SP158" {
    {...s, tag: "[slowly]", text: "В-О-Л. ВОЛ. [firmly] ВЖУХ!"}
  } else {
    {...s, text: fixedText}
  }
}

let segmentByOrder = (segments: array<segment>, order: int): segment =>
  switch Belt.Array.getBy(segments, s => s.order == order) {
  | Some(s) => s
  | None => fail("chunk refers to missing segment order " ++ Belt.Int.toString(order))
  }

let loadV1Plan = (): (array<segment>, array<chunk>) => {
  if !exists(Path(v1PlanPath)) {
    fail("missing v1 parser/chunker plan: " ++ v1PlanPath)
  }
  let root = readText(Path(v1PlanPath))->Js.Json.parseExn->jsonObject("v1 plan")
  let sourceSegments = arrayField(root, "segments", "v1 plan")->Belt.Array.map(parseSegment)
  let segments = sourceSegments->Belt.Array.map(applyApprovedFixes)
  let chunks = arrayField(root, "chunks", "v1 plan")->Belt.Array.map(j => {
    let o = jsonObject(j, "chunk")
    let orders = arrayField(o, "segment_orders", "chunk")->Belt.Array.map(order =>
      switch Js.Json.decodeNumber(order) {
      | Some(n) => Belt.Float.toInt(n)
      | None => fail("chunk.segment_orders must contain numbers")
      }
    )
    {
      id: stringField(o, "id", "chunk"),
      scene: stringField(o, "scene", "chunk"),
      kind: stringField(o, "kind", "chunk"),
      segments: Belt.Array.map(orders, order => segmentByOrder(segments, order)),
      sourceSegments: Belt.Array.map(orders, order => segmentByOrder(sourceSegments, order)),
    }
  })
  (segments, chunks)
}

let loadV1Takes = (): array<v1Take> => {
  if !exists(Path(v1ManifestPath)) {
    fail("missing v1 render manifest: " ++ v1ManifestPath)
  }
  let root = readText(Path(v1ManifestPath))->Js.Json.parseExn->jsonObject("v1 manifest")
  arrayField(root, "chunks", "v1 manifest")->Belt.Array.map(j => {
    let o = jsonObject(j, "v1 take")
    {
      id: stringField(o, "id", "v1 take"),
      scene: stringField(o, "scene", "v1 take"),
      path: stringField(o, "path", "v1 take"),
      duration: numberField(o, "duration_seconds", "v1 take"),
    }
  })
}

let v1TakeFor = (takes: array<v1Take>, id: string): v1Take =>
  switch Belt.Array.getBy(takes, take => take.id == id) {
  | Some(take) => take
  | None => fail("v1 manifest has no take " ++ id)
  }

let removeTags = (text: string): string =>
  text->Js.String2.replaceByRe(%re("/\\[[^\\]]+\\]\\s*/g"), "")->trim

let spokenText = (s: segment): string => removeTags(s.text)
let directed = (s: segment): string => s.tag == "" ? s.text : s.tag ++ " " ++ s.text

type textSpan = {blockId: string, from: int, to_: int}
type transcriptMap = {text: string, spans: array<textSpan>}

let transcriptMap = (segments: array<segment>): transcriptMap => {
  let buffer = ref("")
  let spans: array<textSpan> = []
  segments->Belt.Array.forEach(s => {
    if buffer.contents != "" {
      buffer := buffer.contents ++ " "
    }
    let from = Js.String2.length(buffer.contents)
    let text = spokenText(s)
    buffer := buffer.contents ++ text
    let _ = Js.Array2.push(spans, {blockId: s.blockId, from, to_: Js.String2.length(buffer.contents)})
  })
  {text: buffer.contents, spans}
}

let alignmentJson = (value: alignment): Js.Json.t => {
  let root = Js.Dict.empty()
  Js.Dict.set(root, "loss", Js.Json.number(value.loss))
  Js.Dict.set(root, "characters", Js.Json.array(value.characters->Belt.Array.map(c => {
    let row = Js.Dict.empty()
    Js.Dict.set(row, "text", Js.Json.string(c.text))
    Js.Dict.set(row, "start", Js.Json.number(c.start))
    Js.Dict.set(row, "end", Js.Json.number(c.end_))
    Js.Json.object_(row)
  })))
  Js.Json.object_(root)
}

let parseAlignment = (raw: string): alignment => {
  let root = raw->Js.Json.parseExn->jsonObject("forced alignment cache")
  {
    loss: numberField(root, "loss", "forced alignment cache"),
    characters: arrayField(root, "characters", "forced alignment cache")->Belt.Array.map(j => {
      let o = jsonObject(j, "alignment character")
      {
        text: stringField(o, "text", "alignment character"),
        start: numberField(o, "start", "alignment character"),
        end_: numberField(o, "end", "alignment character"),
      }
    }),
  }
}

let paidAllowed = (): bool => envPaid == Some("1") && envDry != Some("1")

let paidLeasePath = cacheDir ++ "/PAID_V2.lock"

let acquirePaidLease = (dry: bool): unit => {
  if !dry && paidAllowed() && !writeTextExclusive(
    Path(paidLeasePath),
    "Episode 2 table read v2 paid-run lease. Remove only after verifying no v2 process is active.\n",
  ) {
    fail(
      "another paid v2 run already owns " ++ paidLeasePath ++
      "; refusing duplicate ElevenLabs charges",
    )
  }
}

let alignmentForTake = async (
  take: v1Take,
  segments: array<segment>,
  dry: bool,
): option<alignment> => {
  let mapped = transcriptMap(segments)
  let signature =
    sha256File(Path(take.path)) ++ "|" ++ mapped.text ++ "::forced-alignment::" ++ pipelineVersion
  let cachePath = cacheDir ++ "/alignment_" ++ sha256Text(signature) ++ ".json"
  if exists(Path(cachePath)) {
    Some(parseAlignment(readText(Path(cachePath))))
  } else if dry {
    Js.log("  would align v1 take " ++ take.id)
    None
  } else {
    if !paidAllowed() {
      fail("paid forced alignment required for " ++ take.id ++ "; rerun with PAID=1")
    }
    let result = await forcedAlignment(~audio=Path(take.path), ~text=Text(mapped.text))
    let converted = {
      loss: result.loss,
      characters: result.characters->Belt.Array.map(c => ({
        text: c.text,
        start: c.start,
        end_: c.end_,
      })),
    }
    writeText(Path(cachePath), alignmentJson(converted)->Js.Json.stringifyWithSpace(1))
    Some(converted)
  }
}

let blockTimings = (
  mapped: transcriptMap,
  aligned: alignment,
  label: string,
): array<relativeBlock> => {
  let rebuilt = aligned.characters->Belt.Array.map(c => c.text)->Js.Array2.joinWith("")
  if rebuilt != mapped.text {
    fail(
      label ++ " forced-alignment transcript mismatch (expected " ++
      Belt.Int.toString(Js.String2.length(mapped.text)) ++ " chars, got " ++
      Belt.Int.toString(Js.String2.length(rebuilt)) ++ ")",
    )
  }
  mapped.spans->Belt.Array.map(span => {
    let first = ref(span.from)
    while first.contents < span.to_ &&
          trim(Belt.Array.getExn(aligned.characters, first.contents).text) == "" {
      first := first.contents + 1
    }
    let last = ref(span.to_ - 1)
    while last.contents >= first.contents &&
          trim(Belt.Array.getExn(aligned.characters, last.contents).text) == "" {
      last := last.contents - 1
    }
    if first.contents >= span.to_ || last.contents < first.contents {
      fail(label ++ " has an empty aligned block " ++ span.blockId)
    }
    let start = Belt.Array.getExn(aligned.characters, first.contents).start
    let end_ = Belt.Array.getExn(aligned.characters, last.contents).end_
    if start < 0.0 || end_ <= start {
      fail(label ++ " has invalid timing for " ++ span.blockId)
    }
    {blockId: span.blockId, start, end_}
  })
}

type narratorGroup = {audio: path, timings: array<relativeBlock>}
type mixedGroup = {audio: path, timings: array<relativeBlock>}

let timingCacheJson = (rows: array<relativeBlock>): Js.Json.t =>
  Js.Json.array(rows->Belt.Array.map(row => {
    let o = Js.Dict.empty()
    Js.Dict.set(o, "block_id", Js.Json.string(row.blockId))
    Js.Dict.set(o, "start", Js.Json.number(row.start))
    Js.Dict.set(o, "end", Js.Json.number(row.end_))
    Js.Json.object_(o)
  }))

let parseTimingCache = (raw: string): array<relativeBlock> =>
  switch raw->Js.Json.parseExn->Js.Json.decodeArray {
  | Some(rows) => rows->Belt.Array.map(j => {
      let o = jsonObject(j, "narrator timing")
      {
        blockId: stringField(o, "block_id", "narrator timing"),
        start: numberField(o, "start", "narrator timing"),
        end_: numberField(o, "end", "narrator timing"),
      }
    })
  | None => fail("narrator timing cache must be an array")
  }

let narratorGroup = async (
  c: chunk,
  narration: array<segment>,
  dry: bool,
): option<narratorGroup> => {
  let inputs = narration->Belt.Array.map(s => directed(s))
  let signature =
    bellaVoiceId ++ "|" ++ Js.Array2.joinWith(inputs, "\n") ++
    "::eleven-v3-dialogue-timed::" ++ pipelineVersion
  let hash = sha256Text(signature)
  let audioPath = cacheDir ++ "/bella_group_" ++ hash ++ ".mp3"
  let timingPath = cacheDir ++ "/bella_group_" ++ hash ++ ".timings.json"
  if exists(Path(audioPath)) && exists(Path(timingPath)) {
    Some({audio: Path(audioPath), timings: parseTimingCache(readText(Path(timingPath)))})
  } else if dry {
    Js.log(
      "  would render Bella narration group " ++ c.id ++ " (" ++
      Belt.Int.toString(Belt.Array.length(narration)) ++ " blocks)",
    )
    None
  } else {
    if !paidAllowed() {
      fail("paid Bella narration required for " ++ c.id ++ "; rerun with PAID=1")
    }
    let request = narration->Belt.Array.map(s => (Text(directed(s)), VoiceId(bellaVoiceId)))
    let (audio, times) = await dialogueTimed(request)
    let _ = writeBytes(Path(audioPath), audio)
    if Belt.Array.length(times) != Belt.Array.length(narration) {
      fail("Bella timing count mismatch in " ++ c.id)
    }
    let timings = narration->Belt.Array.mapWithIndex((i, s) => {
      let (start, end_) = Belt.Array.getExn(times, i)
      if end_ <= start {
        fail("Bella returned missing timing for " ++ s.blockId)
      }
      {blockId: s.blockId, start, end_}
    })
    writeText(Path(timingPath), timingCacheJson(timings)->Js.Json.stringifyWithSpace(1))
    Some({audio: Path(audioPath), timings})
  }
}

let voiceFor = (speaker: string): string =>
  switch speaker {
  | "NARRATOR" => bellaVoiceId
  | "FROSYA" => "XJ2fW4ybq7HouelYYGcL"
  | "VASYA" => "XjGYkUkzth8BPs29fmcV"
  | "MAMA" => "EXAVITQu4vr4xnSDxMaL"
  | "PAPA" => "nPczCjzI2devNBz1zQrb"
  | "ROOT_CREATURE" => "pqHfZKP75CvOlQylNhV4"
  | "GIANT_GIRL" => "cgSgspJ2msm6clMCkdW9"
  | "CHORUS_SIBLINGS" => fail("sibling chorus must remain a whole v1 take")
  | role => fail("no English voice for " ++ role)
  }

/* Robust fallback when the account cannot use forced alignment. Every mixed v1
   take is re-performed once, in its original segment order, with Bella replacing
   only the narrator voice. dialogueTimed supplies exact block boundaries. */
let mixedGroup = async (c: chunk, dry: bool): option<mixedGroup> => {
  if Belt.Array.every(c.segments, s => s.kind == "narration") {
    let narrator = await narratorGroup(c, c.segments, dry)
    switch narrator {
    | Some(group) => Some({audio: group.audio, timings: group.timings})
    | None => None
    }
  } else {
  let signature =
    c.segments
    ->Belt.Array.map(s => voiceFor(s.speaker) ++ "|" ++ directed(s))
    ->Js.Array2.joinWith("\n") ++ "::eleven-v3-dialogue-timed::" ++ rerenderPipelineVersion
  let hash = sha256Text(signature)
  let audioPath = cacheDir ++ "/mixed_group_" ++ hash ++ ".mp3"
  let timingPath = cacheDir ++ "/mixed_group_" ++ hash ++ ".timings.json"
  if exists(Path(audioPath)) && exists(Path(timingPath)) {
    Some({audio: Path(audioPath), timings: parseTimingCache(readText(Path(timingPath)))})
  } else if dry {
    Js.log(
      "  would rerender mixed take " ++ c.id ++ " with Bella + existing cast (" ++
      Belt.Int.toString(Belt.Array.length(c.segments)) ++ " blocks)",
    )
    None
  } else {
    if !paidAllowed() {
      fail("paid mixed-take rerender required for " ++ c.id ++ "; rerun with PAID=1")
    }
    let request = c.segments->Belt.Array.map(s => (
      Text(directed(s)),
      VoiceId(voiceFor(s.speaker)),
    ))
    let (audio, times) = await dialogueTimed(request)
    let _ = writeBytes(Path(audioPath), audio)
    if Belt.Array.length(times) != Belt.Array.length(c.segments) {
      fail("mixed-take timing count mismatch in " ++ c.id)
    }
    let timings = c.segments->Belt.Array.mapWithIndex((i, s) => {
      let (start, end_) = Belt.Array.getExn(times, i)
      if !Js.Float.isFinite(start) || !Js.Float.isFinite(end_) || start < 0.0 || end_ <= start {
        fail("mixed-take returned invalid timing for " ++ s.blockId)
      }
      {blockId: s.blockId, start, end_}
    })
    writeText(Path(timingPath), timingCacheJson(timings)->Js.Json.stringifyWithSpace(1))
    Some({audio: Path(audioPath), timings})
  }
  }
}

let timingFor = (rows: array<relativeBlock>, blockId: string, label: string): relativeBlock =>
  switch Belt.Array.getBy(rows, row => row.blockId == blockId) {
  | Some(row) => row
  | None => fail(label ++ " has no timing for " ++ blockId)
  }

/* Preserve breaths, reactions, and acting-tag business around a v1 character
   line without stealing an adjacent spoken line. Boundaries fall halfway across
   the silence between aligned blocks; overlapping speech is never clipped. */
let characterCutRange = (
  rows: array<relativeBlock>,
  blockId: string,
  sourceDuration: float,
  label: string,
): (float, float, relativeBlock) => {
  let index = switch Belt.Array.getIndexBy(rows, row => row.blockId == blockId) {
  | Some(index) => index
  | None => fail(label ++ " has no timing for " ++ blockId)
  }
  let current = Belt.Array.getExn(rows, index)
  let start = if index == 0 {
    0.0
  } else {
    let previous = Belt.Array.getExn(rows, index - 1)
    previous.end_ <= current.start
      ? (previous.end_ +. current.start) /. 2.0
      : current.start
  }
  let end_ = if index == Belt.Array.length(rows) - 1 {
    sourceDuration
  } else {
    let next = Belt.Array.getExn(rows, index + 1)
    next.start >= current.end_
      ? (current.end_ +. next.start) /. 2.0
      : current.end_
  }
  if start < 0.0 || end_ > sourceDuration +. 0.05 || end_ <= start {
    fail(label ++ " produced an invalid character cut range for " ++ blockId)
  }
  (start, min(sourceDuration, end_), current)
}

let cutStem = (
  ~src: path,
  ~start: float,
  ~end_: float,
  ~blockId: string,
  ~kind: string,
): path => {
  let Path(source) = src
  let signature =
    sha256File(src) ++ "|" ++ Js.Float.toString(start) ++ "|" ++ Js.Float.toString(end_) ++
    "|" ++ kind ++ "::" ++ pipelineVersion
  let out = Path(stemDir ++ "/" ++ blockId ++ "_" ++ sha256Text(signature) ++ ".mp3")
  if !exists(out) {
    let Path(output) = out
    let duration = end_ -. start
    if duration <= 0.0 {
      fail("refusing non-positive stem for " ++ blockId)
    }
    let filters = kind == "narration"
      ? ["-af", "loudnorm=I=-18:TP=-1.5:LRA=11"]
      : []
    ffmpeg([
      "-nostdin", "-loglevel", "error", "-y", "-i", source,
      "-ss", Js.Float.toString(start), "-t", Js.Float.toString(duration),
      ...filters,
      "-c:a", "libmp3lame", "-q:a", "3", "-ac", "1", output,
    ])
  }
  out
}

let pureCharacterTakeIds = [
  "scene_01_chorus_5",
  "scene_01_take_7",
  "scene_01_take_8",
  "scene_03_take_12",
]

let isPureCharacterChunk = (c: chunk): bool =>
  Belt.Array.every(c.segments, s => s.kind != "narration")

type silenceGap = {start: float, end_: float}

let floatAfter = (line: string, marker: string): option<float> => {
  let index = Js.String2.indexOf(line, marker)
  index < 0
    ? None
    : Js.String2.sliceToEnd(line, ~from=index + Js.String2.length(marker))
      ->trim
      ->Js.String2.split(" ")
      ->Belt.Array.get(0)
      ->Belt.Option.flatMap(Belt.Float.fromString)
}

/* The four character-only legacy takes contain one or three lines. In fallback
   mode no cloud alignment is needed: split the three-line takes at the first two
   real silent gaps, leaving all breaths and pauses inside each reusable slot. */
let localPureTimings = (c: chunk, take: v1Take): array<relativeBlock> => {
  let count = Belt.Array.length(c.segments)
  if count == 1 {
    [{blockId: Belt.Array.getExn(c.segments, 0).blockId, start: 0.0, end_: take.duration}]
  } else {
    let result = run(
      ~cmd="ffmpeg",
      ~args=[
        "-nostdin", "-hide_banner", "-i", take.path,
        "-af", "silencedetect=noise=-38dB:d=0.18", "-f", "null", "-",
      ],
    )
    if result.code != 0 {
      fail("local silence analysis failed for " ++ c.id ++ ": " ++ result.stderr)
    }
    let gaps: array<silenceGap> = []
    let pending: ref<option<float>> = ref(None)
    result.stderr->Js.String2.split("\n")->Belt.Array.forEach(line => {
      switch floatAfter(line, "silence_start:") {
      | Some(start) => pending := Some(start)
      | None => ()
      }
      switch (pending.contents, floatAfter(line, "silence_end:")) {
      | (Some(start), Some(end_)) => {
          if start > 0.1 && end_ < take.duration -. 0.1 {
            let _ = Js.Array2.push(gaps, {start, end_})
          }
          pending := None
        }
      | _ => ()
      }
    })
    if Belt.Array.length(gaps) < count - 1 {
      fail(
        c.id ++ " needs " ++ Belt.Int.toString(count - 1) ++
        " local silence boundaries, found " ++ Belt.Int.toString(Belt.Array.length(gaps)),
      )
    }
    let boundaries = Belt.Array.make(count - 1, 0.0)
    for i in 0 to count - 2 {
      let gap = Belt.Array.getExn(gaps, i)
      Belt.Array.setExn(boundaries, i, (gap.start +. gap.end_) /. 2.0)
    }
    c.segments->Belt.Array.mapWithIndex((i, s) => ({
      blockId: s.blockId,
      start: i == 0 ? 0.0 : Belt.Array.getExn(boundaries, i - 1),
      end_: i == count - 1 ? take.duration : Belt.Array.getExn(boundaries, i),
    }))
  }
}

let validate = (
  segments: array<segment>,
  chunks: array<chunk>,
  takes: array<v1Take>,
): unit => {
  if Belt.Array.length(segments) != 191 {
    fail("expected 191 parser blocks, got " ++ Belt.Int.toString(Belt.Array.length(segments)))
  }
  let uniqueIds = Js.Dict.empty()
  segments->Belt.Array.forEach(s => {
    if Js.Dict.get(uniqueIds, s.blockId) != None {
      fail("duplicate block ID " ++ s.blockId)
    }
    Js.Dict.set(uniqueIds, s.blockId, true)
  })
  let fixedCount = segments->Belt.Array.keep(s => narrationFix(s.blockId) != None)->Belt.Array.length
  if fixedCount != 11 {
    fail("all eleven approved narration repairs must be present")
  }
  let e2sp158 = segmentByOrder(segments, 156)
  if e2sp158.blockId != "E2SP158" || e2sp158.tag != "[slowly]" ||
     e2sp158.text != "В-О-Л. ВОЛ. [firmly] ВЖУХ!" {
    fail("E2SP158 phrase-level tag fix is missing")
  }
  let actualPure = chunks->Belt.Array.keep(isPureCharacterChunk)->Belt.Array.map(c => c.id)
  if Belt.Array.length(actualPure) != 4 ||
     Belt.Array.some(pureCharacterTakeIds, id => !Belt.Array.some(actualPure, actual => actual == id)) {
    fail("the four character-only take invariant changed")
  }
  chunks->Belt.Array.forEach(c => {
    let take = v1TakeFor(takes, c.id)
    if !exists(Path(take.path)) {
      fail("missing paid v1 take: " ++ take.path)
    }
    if fileSizeMb(Path(take.path)) *. 1.0e6 < 2000.0 {
      fail("v1 take is implausibly small: " ++ take.path)
    }
  })
  if !exists(Path(v1AudioPath)) {
    fail("v1 full mix is missing; refusing a v2 that cannot prove its source")
  }
  if exists(Path(v2OutputPath)) || exists(Path(v2ManifestPath)) {
    fail("V2 output already exists; this generator never overwrites a completed v2")
  }
}

let planJson = (segments: array<segment>, chunks: array<chunk>): Js.Json.t => {
  let root = Js.Dict.empty()
  Js.Dict.set(root, "pipeline_version", Js.Json.string(pipelineVersion))
  Js.Dict.set(root, "language", Js.Json.string("English"))
  Js.Dict.set(root, "narrator", Js.Json.string(bellaVoice))
  Js.Dict.set(root, "narrator_voice_id", Js.Json.string(bellaVoiceId))
  Js.Dict.set(root, "v1_plan", Js.Json.string(v1PlanPath))
  Js.Dict.set(root, "v1_manifest", Js.Json.string(v1ManifestPath))
  Js.Dict.set(root, "v1_audio", Js.Json.string(v1AudioPath))
  Js.Dict.set(root, "v2_audio", Js.Json.string(v2OutputPath))
  Js.Dict.set(root, "sound_effects", Js.Json.string("not mixed in this pass"))
  Js.Dict.set(root, "block_count", Js.Json.number(Belt.Int.toFloat(Belt.Array.length(segments))))
  Js.Dict.set(root, "chunk_count", Js.Json.number(Belt.Int.toFloat(Belt.Array.length(chunks))))
  Js.Dict.set(root, "approved_narration_fix_count", Js.Json.number(11.0))
  Js.Dict.set(
    root,
    "mixed_take_strategy",
    Js.Json.string(envRerenderMixed == Some("1")
      ? "rerender mixed chunks with Bella + existing cast via dialogueTimed"
      : "preserve mixed performances using forced alignment"),
  )
  Js.Dict.set(root, "whole_v1_takes", Js.Json.array(pureCharacterTakeIds->Belt.Array.map(Js.Json.string)))
  Js.Json.object_(root)
}

let buildPieces = async (
  chunks: array<chunk>,
  takes: array<v1Take>,
  dry: bool,
): array<piece> => {
  let pieces: array<piece> = []
  let rerenderMixed = envRerenderMixed == Some("1")
  for i in 0 to Belt.Array.length(chunks) - 1 {
    let c = Belt.Array.getExn(chunks, i)
    let selected = switch envProbeChunk {
    | Some(id) => id == c.id
    | None => true
    }
    if selected {
    let take = v1TakeFor(takes, c.id)
    let characters = c.segments->Belt.Array.keep(s => s.kind != "narration")
    let narration = c.segments->Belt.Array.keep(s => s.kind == "narration")
    let oldAlignment = if Belt.Array.length(characters) > 0 && !rerenderMixed {
      /* Alignment transcript must describe what is already in the v1 audio,
         not the cleaned Bella wording used by v2. */
      await alignmentForTake(take, c.sourceSegments, dry)
    } else {
      None
    }
    let oldTimings = if rerenderMixed && isPureCharacterChunk(c) {
      localPureTimings(c, take)
    } else {
      switch oldAlignment {
      | Some(aligned) => blockTimings(transcriptMap(c.sourceSegments), aligned, c.id)
      | None => []
      }
    }
    let newNarrator = Belt.Array.length(narration) > 0 && !rerenderMixed
      ? await narratorGroup(c, narration, dry)
      : None
    let newMixed = Belt.Array.length(narration) > 0 && rerenderMixed
      ? await mixedGroup(c, dry)
      : None

    if !dry {
      if isPureCharacterChunk(c) {
        /* Intentionally reuse the whole source take: no slicing and no rebuilt
           pauses. Alignment is used only to expose block timings. */
        let _ = Js.Array2.push(pieces, {
          id: c.id,
          chunkId: c.id,
          scene: c.scene,
          path: take.path,
          sourceGroup: "v1:" ++ c.id,
          sourcePath: take.path,
          sourceStart: 0.0,
          sourceEnd: take.duration,
          sourceKind: "v1_character_take_whole",
          blocks: c.segments->Belt.Array.map(s => timingFor(oldTimings, s.blockId, c.id)),
        })
      } else if rerenderMixed {
        switch newMixed {
        | Some(group) => {
            let Seconds(duration) = probeDuration(group.audio)
            let _ = Js.Array2.push(pieces, {
              id: c.id,
              chunkId: c.id,
              scene: c.scene,
              path: pathString(group.audio),
              sourceGroup: "rerendered:" ++ c.id,
              sourcePath: pathString(group.audio),
              sourceStart: 0.0,
              sourceEnd: duration,
              sourceKind: "rerendered_mixed_take",
              blocks: c.segments->Belt.Array.map(s => timingFor(group.timings, s.blockId, c.id)),
            })
          }
        | None => fail("missing rerendered mixed take " ++ c.id)
        }
      } else {
        c.segments->Belt.Array.forEach(s => {
          if s.kind == "narration" {
            switch newNarrator {
            | Some(group) => {
                let timing = timingFor(group.timings, s.blockId, "Bella " ++ c.id)
                let stem = cutStem(
                  ~src=group.audio,
                  ~start=timing.start,
                  ~end_=timing.end_,
                  ~blockId=s.blockId,
                  ~kind="narration",
                )
                let Seconds(duration) = probeDuration(stem)
                let _ = Js.Array2.push(pieces, {
                  id: s.blockId,
                  chunkId: c.id,
                  scene: c.scene,
                  path: pathString(stem),
                  sourceGroup: "bella:" ++ c.id,
                  sourcePath: pathString(group.audio),
                  sourceStart: timing.start,
                  sourceEnd: timing.end_,
                  sourceKind: "bella_narration",
                  blocks: [{blockId: s.blockId, start: 0.0, end_: duration}],
                })
              }
            | None => fail("missing Bella narration group " ++ c.id)
            }
          } else {
            let (cutStart, cutEnd, speech) = characterCutRange(
              oldTimings,
              s.blockId,
              take.duration,
              c.id,
            )
            let stem = cutStem(
              ~src=Path(take.path),
              ~start=cutStart,
              ~end_=cutEnd,
              ~blockId=s.blockId,
              ~kind="character",
            )
            let _ = Js.Array2.push(pieces, {
              id: s.blockId,
              chunkId: c.id,
              scene: c.scene,
              path: pathString(stem),
              sourceGroup: "v1:" ++ c.id,
              sourcePath: take.path,
              sourceStart: cutStart,
              sourceEnd: cutEnd,
              sourceKind: "v1_character_slice",
              blocks: [{
                blockId: s.blockId,
                start: speech.start -. cutStart,
                end_: speech.end_ -. cutStart,
              }],
            })
          }
        })
      }
    }
    }
  }
  pieces
}

let gapBefore = (previous: option<piece>, current: piece): int =>
  switch previous {
  | None => 0
  | Some(prev) if prev.chunkId != current.chunkId => prev.scene == current.scene ? 350 : 1100
  | Some(prev) if prev.sourceGroup == current.sourceGroup => {
      let gap = max(0.0, current.sourceStart -. prev.sourceEnd)
      Belt.Float.toInt(gap *. 1000.0)
    }
  | Some(_) => 180
  }

let manifestBlockJson = (
  piece: piece,
  relative: relativeBlock,
  pieceStart: float,
): Js.Json.t => {
  let o = Js.Dict.empty()
  Js.Dict.set(o, "block_id", Js.Json.string(relative.blockId))
  Js.Dict.set(o, "start_seconds", Js.Json.number(pieceStart +. relative.start))
  Js.Dict.set(o, "end_seconds", Js.Json.number(pieceStart +. relative.end_))
  Js.Dict.set(o, "stem", Js.Json.string(piece.path))
  Js.Dict.set(o, "stem_start_seconds", Js.Json.number(relative.start))
  Js.Dict.set(o, "stem_end_seconds", Js.Json.number(relative.end_))
  Js.Dict.set(o, "source_kind", Js.Json.string(piece.sourceKind))
  Js.Dict.set(o, "source", Js.Json.string(piece.sourcePath))
  let sourceStart = piece.sourceKind == "v1_character_take_whole"
    ? relative.start
    : piece.sourceStart
  let sourceEnd = piece.sourceKind == "v1_character_take_whole"
    ? relative.end_
    : piece.sourceEnd
  Js.Dict.set(o, "source_start_seconds", Js.Json.number(sourceStart))
  Js.Dict.set(o, "source_end_seconds", Js.Json.number(sourceEnd))
  Js.Json.object_(o)
}

let assemble = (pieces: array<piece>, expectedSegments: array<segment>): unit => {
  let parts: array<path> = []
  let blockRows: array<Js.Json.t> = []
  let absoluteRows: array<relativeBlock> = []
  let timeline = ref(0.0)
  let previous: ref<option<piece>> = ref(None)
  pieces->Belt.Array.forEach(piece => {
    let gapMs = gapBefore(previous.contents, piece)
    if gapMs > 0 {
      let gap = silence(Millis(gapMs), Path(cacheDir))
      let _ = Js.Array2.push(parts, gap)
      let Seconds(actualGap) = probeDuration(gap)
      timeline := timeline.contents +. actualGap
    }
    let pieceStart = timeline.contents
    let _ = Js.Array2.push(parts, Path(piece.path))
    piece.blocks->Belt.Array.forEach(relative => {
      let _ = Js.Array2.push(blockRows, manifestBlockJson(piece, relative, pieceStart))
      let _ = Js.Array2.push(absoluteRows, {
        blockId: relative.blockId,
        start: pieceStart +. relative.start,
        end_: pieceStart +. relative.end_,
      })
    })
    let Seconds(duration) = probeDuration(Path(piece.path))
    timeline := timeline.contents +. duration
    previous := Some(piece)
  })
  if Belt.Array.length(blockRows) != Belt.Array.length(expectedSegments) {
    fail(
      "expected " ++ Belt.Int.toString(Belt.Array.length(expectedSegments)) ++ " timing rows, got " ++
      Belt.Int.toString(Belt.Array.length(blockRows)),
    )
  }
  expectedSegments->Belt.Array.forEachWithIndex((i, expected) => {
    let actual = Belt.Array.getExn(absoluteRows, i)
    if actual.blockId != expected.blockId {
      fail(
        "timing manifest order mismatch at " ++ Belt.Int.toString(i) ++ ": expected " ++
        expected.blockId ++ ", got " ++ actual.blockId,
      )
    }
    if !Js.Float.isFinite(actual.start) || !Js.Float.isFinite(actual.end_) ||
       actual.start < 0.0 || actual.end_ <= actual.start {
      fail("invalid absolute timing for " ++ actual.blockId)
    }
    if i > 0 {
      let previous = Belt.Array.getExn(absoluteRows, i - 1)
      if actual.start +. 0.005 < previous.end_ {
        fail("overlapping absolute timings: " ++ previous.blockId ++ " / " ++ actual.blockId)
      }
    }
  })
  let scratch = tempDir("drakosha-ep2-v2-assemble-")
  let tempOutput = Path(pathString(scratch) ++ "/EP2_FULL_CAST_TABLE_READ_V2.mp3")
  let out = concatAudio(parts, tempOutput)
  let Seconds(total) = probeDuration(out)
  if abs_float(total -. timeline.contents) > 0.25 {
    fail(
      "assembled duration drifted by " ++
      Js.Float.toFixedWithPrecision(abs_float(total -. timeline.contents), ~digits=3) ++ " seconds",
    )
  }
  absoluteRows->Belt.Array.forEach(row => {
    if row.end_ > total +. 0.01 {
      fail(row.blockId ++ " ends beyond final audio duration")
    }
  })
  if exists(Path(v2OutputPath)) || exists(Path(v2ManifestPath)) {
    fail("V2 output appeared during assembly; refusing to overwrite it")
  }
  if !publishFileExclusive(out, Path(v2OutputPath)) {
    fail("V2 audio appeared during publication; refusing to overwrite it")
  }
  let root = Js.Dict.empty()
  Js.Dict.set(root, "audio", Js.Json.string(v2OutputPath))
  Js.Dict.set(root, "duration_seconds", Js.Json.number(total))
  Js.Dict.set(root, "pipeline_version", Js.Json.string(pipelineVersion))
  Js.Dict.set(root, "narrator", Js.Json.string(bellaVoice))
  Js.Dict.set(root, "narrator_voice_id", Js.Json.string(bellaVoiceId))
  Js.Dict.set(root, "character_source_audio", Js.Json.string(v1AudioPath))
  Js.Dict.set(root, "sound_effects", Js.Json.string("not mixed"))
  Js.Dict.set(root, "blocks", Js.Json.array(blockRows))
  writeText(Path(v2ManifestPath), Js.Json.object_(root)->Js.Json.stringifyWithSpace(1))
  Js.log(
    "V2 TABLE READ -> " ++ v2OutputPath ++ " (" ++
    Js.Float.toFixedWithPrecision(total /. 60.0, ~digits=1) ++ " min)",
  )
  Js.log("TIMING MANIFEST -> " ++ v2ManifestPath)
}

let main = async () => {
  let dry = envDry == Some("1")
  let probing = envProbeChunk != None
  ensureDirPath(Path(cacheDir))
  ensureDirPath(Path(stemDir))
  let (segments, chunks) = loadV1Plan()
  let takes = loadV1Takes()
  validate(segments, chunks, takes)
  if probing && envRerenderMixed != Some("1") {
    fail("PROBE_CHUNK is supported only with RERENDER_MIXED=1")
  }
  switch envProbeChunk {
  | Some(id) =>
    switch Belt.Array.getBy(chunks, c => c.id == id) {
    | Some(c) if !isPureCharacterChunk(c) => ()
    | Some(_) => fail("PROBE_CHUNK must name a mixed take, not a whole reused take")
    | None => fail("unknown PROBE_CHUNK " ++ id)
    }
  | None => ()
  }
  acquirePaidLease(dry)
  writeText(Path(v2PlanPath), planJson(segments, chunks)->Js.Json.stringifyWithSpace(1))
  Js.log(
    "validated v2 plan: " ++ Belt.Int.toString(Belt.Array.length(segments)) ++
    " blocks; Bella narration; " ++ (envRerenderMixed == Some("1")
      ? "mixed takes rerendered, four character-only v1 takes preserved"
      : "exact v1 character performances recovered by alignment"),
  )
  Js.log("PLAN -> " ++ v2PlanPath)
  let pieces = await buildPieces(chunks, takes, dry)
  if dry {
    Js.log("DRY run — zero paid calls; no audio was rendered or assembled.")
  } else if probing {
    Js.log(
      "PROBE complete — cached only " ++ envProbeChunk->Belt.Option.getWithDefault("") ++
      "; no full V2 audio was assembled.",
    )
  } else {
    assemble(pieces, segments)
  }
}

let runMain = async () => {
  try await main() catch {
  | TableReadV2(message) => {
      Js.log("EP2 TABLE READ V2 FAILED: " ++ message)
      exit(1)
    }
  | BackendError(message) => {
      Js.log("EP2 TABLE READ V2 BACKEND FAILED: " ++ message)
      exit(1)
    }
  }
}

runMain()->ignore
