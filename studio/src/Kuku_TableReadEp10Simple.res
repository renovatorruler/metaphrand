/* कुकु और अक्षर — Episode 10 simplified-script full-cast ElevenLabs v3 table read.

   Hiral Ben, the locked सूत्रधार, reads headings, action and written sound
   cues. The locked cast reads dialogue. Hindi performance parentheticals are
   translated to Eleven v3 expression tags and are never spoken.

   Safe validation (zero provider calls):
     DRY=1 node src/Kuku_TableReadEp10Simple.res.mjs

   Production (the only command that may make paid calls):
     PAID=1 node src/Kuku_TableReadEp10Simple.res.mjs

   Resume an interrupted production run without replacing its paid-run lock:
     PAID=1 RESUME=1 node src/Kuku_TableReadEp10Simple.res.mjs

   DRY=1 always wins over PAID=1. Without PAID=1, a missing audio cache fails
   closed. Cache keys include the exact voice, directed text and pipeline
   version. The final MP3 and manifest are published without overwrite. */

open Cinema_Backends

@val @scope(("process", "env")) external envDry: option<string> = "DRY"
@val @scope(("process", "env")) external envPaid: option<string> = "PAID"
@val @scope(("process", "env")) external envResume: option<string> = "RESUME"
@val @scope("process") external exit: int => unit = "exit"

@get external nodeErrorCause: Js.Exn.t => Js.Nullable.t<Js.Exn.t> = "cause"
@get external nodeErrorCode: Js.Exn.t => Js.Nullable.t<string> = "code"
@get external nodeErrorHostname: Js.Exn.t => Js.Nullable.t<string> = "hostname"
@get external nodeErrorSyscall: Js.Exn.t => Js.Nullable.t<string> = "syscall"

exception TableRead(string)

let dir = "../stories/kuku/ep10prod/simple_table_read_v3"
let screenplay = "../stories/kuku/2026-08-18_EP10_ga_gaay_SPEC_SCREENPLAY_v2_SIMPLE.md"
let globalTagmap = "../stories/kuku/ep5prod/tagmap.json"
let localTagmap = dir ++ "/expression_tags.v3.json"
let planPath = dir ++ "/EP10_SIMPLE_FULL_CAST_TABLE_READ_V3.plan.json"
let manifestPath = dir ++ "/EP10_SIMPLE_FULL_CAST_TABLE_READ_V3.manifest.json"
let outputPath = dir ++ "/EP10_SIMPLE_FULL_CAST_TABLE_READ_V3.mp3"
let paidLockPath = dir ++ "/EP10_SIMPLE_FULL_CAST_TABLE_READ_V3.PAID.lock"
let cacheDir = dir ++ "/cache"

let contextualGaSourcePath =
  "../stories/kuku/ep10prod/table_read/cache/dialogue_b497b68b2f901fae12e20dde321a1886b5d9b9815d1c92876694352bb49a647e.mp3"
let contextualGaSourceSha256 = "da4c4079417a28ef17cccaea11465622343dbc7bf8895349797c38eed63e2866"
let contextualGaSourceInputSha256 = "b497b68b2f901fae12e20dde321a1886b5d9b9815d1c92876694352bb49a647e"
let contextualGaAuditPath = "/private/tmp/ep10_old_chunk012_check.txt"
let contextualGaAuditSha256 = "655ed1c701959f526c3f2a76742684713923c18490f0b80661aa83b3400cda7b"

let pipelineVersion = "kuku-ep10-simple-table-read-v3"
let maxChunkChars = 1800
let expectedDialogueLines = 49

type segment = {
  order: int,
  scene: int,
  dialogueIdx: int,
  kind: string,
  speaker: string,
  direction: string,
  tag: string,
  text: string,
  providerText: string,
  providerTextProvenance: string,
}

type chunk = {
  id: string,
  scene: int,
  kind: string,
  segments: array<segment>,
  chars: int,
}

type tagmaps = {
  globalTags: Js.Dict.t<string>,
  globalVisual: array<string>,
  localTags: Js.Dict.t<string>,
  lineTags: Js.Dict.t<string>,
}

let fail = message => raise(TableRead(message))
let trim = Js.String2.trim
let clean = (value: string): string => value->Js.String2.replaceByRe(%re("/`/g"), "")->trim
let fld = (j, k) => j->Js.Json.decodeObject->Belt.Option.flatMap(o => Js.Dict.get(o, k))

let describeNodeErrorPart = (error: Js.Exn.t): string => {
  let parts: array<string> = []
  switch Js.Exn.message(error) {
  | Some(message) => ignore(Js.Array2.push(parts, message))
  | None => ()
  }
  switch nodeErrorCode(error)->Js.Nullable.toOption {
  | Some(code) => ignore(Js.Array2.push(parts, "code=" ++ code))
  | None => ()
  }
  switch nodeErrorSyscall(error)->Js.Nullable.toOption {
  | Some(syscall) => ignore(Js.Array2.push(parts, "syscall=" ++ syscall))
  | None => ()
  }
  switch nodeErrorHostname(error)->Js.Nullable.toOption {
  | Some(hostname) => ignore(Js.Array2.push(parts, "hostname=" ++ hostname))
  | None => ()
  }
  Belt.Array.length(parts) == 0
    ? "unknown JavaScript error"
    : Js.Array2.joinWith(parts, "; ")
}

let describeNodeError = (error: Js.Exn.t): string => {
  let outer = describeNodeErrorPart(error)
  switch nodeErrorCause(error)->Js.Nullable.toOption {
  | Some(cause) => outer ++ "; cause: " ++ describeNodeErrorPart(cause)
  | None => outer
  }
}

let stringDict = (j: Js.Json.t, field: string): Js.Dict.t<string> => {
  let out = Js.Dict.empty()
  switch fld(j, field)->Belt.Option.flatMap(Js.Json.decodeObject) {
  | Some(o) =>
    Js.Dict.entries(o)->Belt.Array.forEach(((k, v)) =>
      switch Js.Json.decodeString(v) {
      | Some(s) => Js.Dict.set(out, k, s)
      | None => ()
      }
    )
  | None => ()
  }
  out
}

let stringArray = (j: Js.Json.t, field: string): array<string> =>
  fld(j, field)
  ->Belt.Option.flatMap(Js.Json.decodeArray)
  ->Belt.Option.getWithDefault([])
  ->Belt.Array.keepMap(Js.Json.decodeString)

let loadTagmaps = (): tagmaps => {
  let global = readText(Path(globalTagmap))->Js.Json.parseExn
  let local = readText(Path(localTagmap))->Js.Json.parseExn
  {
    globalTags: stringDict(global, "tags"),
    globalVisual: stringArray(global, "visual"),
    localTags: stringDict(local, "tags"),
    lineTags: stringDict(local, "lines"),
  }
}

let tagFor = (maps: tagmaps, idx: int, direction: string): option<string> => {
  let lineKey = Belt.Int.toString(idx)
  switch Js.Dict.get(maps.lineTags, lineKey) {
  | Some(tag) => Some(tag)
  | None =>
    switch Js.Dict.get(maps.localTags, direction) {
    | Some(tag) => Some(tag)
    | None =>
      switch Js.Dict.get(maps.globalTags, direction) {
      | Some(tag) => Some(tag)
      | None if Belt.Array.some(maps.globalVisual, visual => visual == direction) => Some("")
      | None => {
          let pieces =
            direction
            ->Js.String2.split(",")
            ->Belt.Array.map(trim)
            ->Belt.Array.keepMap(piece =>
              switch Js.Dict.get(maps.localTags, piece) {
              | Some(tag) => Some(tag)
              | None => Js.Dict.get(maps.globalTags, piece)
              }
            )
          Belt.Array.length(pieces) > 0 ? Some(Js.Array2.joinWith(pieces, " ")) : None
        }
      }
    }
  }
}

let sceneNumber = (line: string): option<int> => {
  let bare = trim(line->Js.String2.replaceByRe(%re("/^#+[ \\t]*/"), ""))
  if Js.String2.startsWith(bare, "दृश्य ०-अ") {
    Some(100)
  } else if Js.String2.startsWith(bare, "दृश्य") {
    let rest = trim(Js.String2.sliceToEnd(bare, ~from=Js.String2.length("दृश्य")))
    let asciiDigits =
      rest
      ->Js.String2.split("")
      ->Belt.Array.keep(c => c >= "0" && c <= "9")
      ->Js.Array2.joinWith("")
    if asciiDigits != "" {
      Belt.Int.fromString(asciiDigits)
    } else {
      let devanagari = [
        ("०", 0), ("१", 1), ("२", 2), ("३", 3), ("४", 4),
        ("५", 5), ("६", 6), ("७", 7), ("८", 8), ("९", 9),
      ]
      devanagari->Belt.Array.getBy(((digit, _)) => Js.String2.includes(rest, digit))->Belt.Option.map(((_, n)) => n)
    }
  } else {
    None
  }
}

let stripHeading = (line: string): string =>
  clean(line->Js.String2.replaceByRe(%re("/^#+[ \\t]*/"), ""))

let speakerKey = (name: string): option<string> =>
  switch name {
  | "कुकु" => Some("KUKU")
  | "फ्यूरिया" => Some("FYURIA")
  | "वैस्पर" => Some("VESPER")
  | "दादी" | "दादी माया" => Some("DADI")
  | "कैस्टर" => Some("CASTOR")
  | "लेडा" => Some("LEDA")
  | "चील" => Some("CHEEL")
  | "ऋषि" => Some("RISHI")
  | "चारों साथी" => Some("CHORUS_FOUR")
  | "पाँचों बच्चे" | "पांचों बच्चे" => Some("CHORUS_FIVE")
  | _ => None
  }

let chorusMembers = (speaker: string): array<string> =>
  switch speaker {
  | "CHORUS_FOUR" => ["FYURIA", "VESPER", "CASTOR", "LEDA"]
  | "CHORUS_FIVE" => ["KUKU", "FYURIA", "VESPER", "CASTOR", "LEDA"]
  | _ => fail("not a chorus speaker: " ++ speaker)
  }

let splitSpeaker = (line: string): option<(string, string)> =>
  switch Js.String2.indexOf(line, ":") {
  | -1 => None
  | i => {
      let name = trim(Js.String2.slice(line, ~from=0, ~to_=i))
      let rest = trim(Js.String2.sliceToEnd(line, ~from=i + 1))
      Js.String2.length(name) > 0 && Js.String2.length(name) <= 18 ? Some((name, rest)) : None
    }
  }

let splitParenthetical = (rest: string): option<(string, string)> =>
  if !Js.String2.startsWith(rest, "(") {
    None
  } else {
    switch Js.String2.indexOf(rest, ")") {
    | -1 => None
    | i => Some((
        trim(Js.String2.slice(rest, ~from=1, ~to_=i)),
        clean(Js.String2.sliceToEnd(rest, ~from=i + 1)),
      ))
    }
  }

let isAction = (line: string): bool =>
  Js.String2.startsWith(line, "(") && Js.String2.endsWith(line, ")")

let actionText = (line: string): string =>
  clean(Js.String2.slice(line, ~from=1, ~to_=Js.String2.length(line) - 1))

let narratorTagFor = (scene: int): string =>
  switch scene {
  | 0 => "[narrating with energy]"
  | 100 => "[mysterious] [tense]"
  | 1 | 2 | 3 => "[tense] [focused]"
  | 4 => "[warmly] [gently]"
  | 5 => "[mysterious] [sinister]"
  | _ => "[narrating]"
  }

let soundOnlyText = (name: string, direction: string): string => {
  let sound = clean(direction->Js.String2.replaceByRe(%re("/^ध्वनि:[ \\t]*/"), ""))
  name ++ " की " ++ sound ++ "।"
}

type providerTextChoice = {text: string, provenance: string}

/* The formerly bare ग line now carries its own spoken context. Freeze that
   exact row and record why it is safe; do not invent transliteration or hidden
   punctuation. Every provider row remains ordinary screenplay Devanagari. */
let providerTextFor = (~dialogueIdx: int, ~speaker: string, ~text: string): providerTextChoice =>
  if dialogueIdx == 25 && speaker == "KUKU" && text == "ग की आवाज़!" {
    {
      text,
      provenance: "frozen-ep10-simple-v3-contextual-ga: screenplay dialogue 25 changed from bare ग to exact ग की आवाज़!",
    }
  } else {
    {text, provenance: "screenplay-exact-after-markdown-cleanup"}
  }

let parseScreenplay = (): array<segment> => {
  let maps = loadTagmaps()
  let segments: array<segment> = []
  let currentScene = ref(-1)
  let order = ref(0)
  let dialogueIdx = ref(0)
  let pseudoSpeakerSounds = ref(0)
  let unresolved: array<string> = []
  let uncast: array<string> = []

  let push = (~scene: int, ~dialogueIdx: int=0, ~kind: string, ~speaker: string, ~direction: string="", ~tag: string, ~text: string) => {
    order := order.contents + 1
    let provider = providerTextFor(~dialogueIdx, ~speaker, ~text)
    let _ = Js.Array2.push(segments, {
      order: order.contents,
      scene,
      dialogueIdx,
      kind,
      speaker,
      direction,
      tag,
      text,
      providerText: provider.text,
      providerTextProvenance: provider.provenance,
    })
  }

  readText(Path(screenplay))->Js.String2.split("\n")->Belt.Array.forEach(raw => {
    let line = trim(raw)
    if line != "" {
      switch sceneNumber(line) {
      | Some(scene) => {
          currentScene := scene
          push(~scene, ~kind="narration", ~speaker=Kuku_Cast.tableReadNarrator, ~tag="[announcing]", ~text=stripHeading(line))
        }
      | None if currentScene.contents >= 0 =>
        if Js.String2.startsWith(line, "## शीर्षक-गीत") {
          push(~scene=1000, ~kind="narration", ~speaker=Kuku_Cast.tableReadNarrator, ~tag="[announcing]", ~text="शीर्षक गीत।")
        } else if line == "---" || Js.String2.startsWith(line, "#") {
          ()
        } else if isAction(line) {
          /* Written sound cues are table-read narration, never generated SFX
             and never an inferred character imitation. */
          push(~scene=currentScene.contents, ~kind="narration", ~speaker=Kuku_Cast.tableReadNarrator, ~tag=narratorTagFor(currentScene.contents), ~text=actionText(line))
        } else {
          switch splitSpeaker(line) {
          | Some((name, rest)) =>
            switch splitParenthetical(rest) {
            | Some((direction, text)) if text == "" && Js.String2.startsWith(direction, "ध्वनि:") =>
              {
                pseudoSpeakerSounds := pseudoSpeakerSounds.contents + 1
                push(~scene=currentScene.contents, ~kind="narration", ~speaker=Kuku_Cast.tableReadNarrator, ~tag=narratorTagFor(currentScene.contents), ~text=soundOnlyText(name, direction))
              }
            | Some((direction, text)) =>
              switch speakerKey(name) {
              | Some(speaker) => {
                  dialogueIdx := dialogueIdx.contents + 1
                  switch tagFor(maps, dialogueIdx.contents, direction) {
                  | Some(tag) =>
                    push(
                      ~scene=currentScene.contents,
                      ~dialogueIdx=dialogueIdx.contents,
                      ~kind=Js.String2.startsWith(speaker, "CHORUS_") ? "chorus" : "dialogue",
                      ~speaker,
                      ~direction,
                      ~tag,
                      ~text,
                    )
                  | None => {
                      let _ = Js.Array2.push(unresolved, Belt.Int.toString(dialogueIdx.contents) ++ " [" ++ direction ++ "] " ++ text)
                    }
                  }
                }
              | None => {let _ = Js.Array2.push(uncast, name)}
              }
            | None => {let _ = Js.Array2.push(unresolved, "missing parenthetical: " ++ line)}
            }
          | None => ()
          }
        }
      | None => ()
      }
    }
  })

  if Belt.Array.length(uncast) > 0 {
    fail("uncast speakers: " ++ Js.Array2.joinWith(uncast, ", "))
  }
  if Belt.Array.length(unresolved) > 0 {
    unresolved->Belt.Array.forEach(item => Js.log("UNRESOLVED TAG: " ++ item))
    fail(Belt.Int.toString(Belt.Array.length(unresolved)) ++ " unresolved performance directions")
  }
  if dialogueIdx.contents != expectedDialogueLines {
    fail("expected " ++ Belt.Int.toString(expectedDialogueLines) ++ " dialogue lines, parsed " ++ Belt.Int.toString(dialogueIdx.contents))
  }
  let narration = segments->Belt.Array.keep(segment => segment.kind == "narration")
  let spoken = segments->Belt.Array.keep(segment => segment.kind == "dialogue" || segment.kind == "chorus")
  let choruses = segments->Belt.Array.keep(segment => segment.kind == "chorus")
  let mimics = segments->Belt.Array.keep(segment => segment.kind == "mimic")
  let expectedScenes = [0, 1, 2, 3, 4, 5, 1000]
  let actualScenes = Js.Dict.empty()
  segments->Belt.Array.forEach(segment => Js.Dict.set(actualScenes, Belt.Int.toString(segment.scene), true))
  if Belt.Array.length(segments) != 118 || Belt.Array.length(narration) != 69 || Belt.Array.length(spoken) != 49 {
    fail("simplified screenplay snapshot must remain 118 segments: 69 narration and 49 dialogue/group")
  }
  if Belt.Array.length(mimics) != 0 || pseudoSpeakerSounds.contents != 0 {
    fail("simplified screenplay permits no mimic or animal pseudo-speaker rows")
  }
  if Belt.Array.length(choruses) != 1 || Belt.Array.getExn(choruses, 0).speaker != "CHORUS_FIVE" {
    fail("simplified screenplay requires exactly one explicit five-child chorus")
  }
  if Belt.Array.length(Js.Dict.keys(actualScenes)) != Belt.Array.length(expectedScenes) ||
     !Belt.Array.every(expectedScenes, scene => Js.Dict.get(actualScenes, Belt.Int.toString(scene)) == Some(true)) {
    fail("simplified screenplay requires scenes 0 through 5 plus the title placeholder")
  }
  let overrides = segments->Belt.Array.keep(segment => segment.providerTextProvenance != "screenplay-exact-after-markdown-cleanup")
  if Belt.Array.length(overrides) != 1 {
    fail("expected exactly one frozen provider-text override")
  }
  let ga = Belt.Array.getExn(overrides, 0)
  if ga.dialogueIdx != 25 || ga.speaker != "KUKU" || ga.text != "ग की आवाज़!" || ga.providerText != ga.text {
    fail("contextual ग provider-text provenance drifted")
  }
  segments
}

let pad3 = (i: int): string =>
  i < 10 ? "00" ++ Belt.Int.toString(i) : i < 100 ? "0" ++ Belt.Int.toString(i) : Belt.Int.toString(i)

let directed = (segment: segment): string =>
  segment.tag == "" ? segment.providerText : segment.tag ++ " " ++ segment.providerText

let chunkSegments = (segments: array<segment>): array<chunk> => {
  let chunks: array<chunk> = []
  let pending: ref<array<segment>> = ref([])
  let pendingScene = ref(-1)
  let pendingChars = ref(0)
  let flush = () => {
    if Belt.Array.length(pending.contents) > 0 {
      let _ = Js.Array2.push(chunks, {
        id: "chunk_" ++ pad3(Belt.Array.length(chunks)),
        scene: pendingScene.contents,
        kind: "dialogue",
        segments: pending.contents,
        chars: pendingChars.contents,
      })
      pending := []
      pendingScene := -1
      pendingChars := 0
    }
  }
  segments->Belt.Array.forEach(segment => {
    let special = segment.kind == "chorus"
    let chars = Js.String2.length(directed(segment))
    if special {
      flush()
      let _ = Js.Array2.push(chunks, {
        id: "chunk_" ++ pad3(Belt.Array.length(chunks)),
        scene: segment.scene,
        kind: segment.kind,
        segments: [segment],
        chars,
      })
    } else {
      if Belt.Array.length(pending.contents) > 0 && (pendingScene.contents != segment.scene || pendingChars.contents + chars > maxChunkChars) {
        flush()
      }
      if Belt.Array.length(pending.contents) == 0 {
        pendingScene := segment.scene
      }
      pending := Belt.Array.concat(pending.contents, [segment])
      pendingChars := pendingChars.contents + chars
    }
  })
  flush()
  chunks
}

let voiceFor = (speaker: string): string =>
  switch Kuku_Cast.voiceOf(speaker) {
  | Some(voice) => voice
  | None => fail("no locked voice for " ++ speaker)
  }

let dialogueSignature = (chunk: chunk): string =>
  chunk.segments
  ->Belt.Array.map(segment => voiceFor(segment.speaker) ++ "|" ++ directed(segment))
  ->Js.Array2.joinWith("\n") ++ "::eleven_v3::dialogue::" ++ pipelineVersion

let dialogueCache = (chunk: chunk): path =>
  Path(cacheDir ++ "/dialogue_" ++ sha256Text(dialogueSignature(chunk)) ++ ".mp3")

let dialogueRawCache = (chunk: chunk): path =>
  Path(cacheDir ++ "/raw_dialogue_" ++ sha256Text(dialogueSignature(chunk)) ++ ".mp3")

let singleSignature = (~speaker: string, ~text: string, ~purpose: string): string =>
  voiceFor(speaker) ++ "|" ++ text ++ "|" ++ purpose ++ "::eleven_v3::tts::" ++ pipelineVersion

let singleCache = (~speaker: string, ~text: string, ~purpose: string): path =>
  Path(cacheDir ++ "/single_" ++ sha256Text(singleSignature(~speaker, ~text, ~purpose)) ++ ".mp3")

let singleRawCache = (~speaker: string, ~text: string, ~purpose: string): path =>
  Path(cacheDir ++ "/raw_single_" ++ sha256Text(singleSignature(~speaker, ~text, ~purpose)) ++ ".mp3")

let chorusSignature = (segment: segment): string => {
  let members = chorusMembers(segment.speaker)
  members->Belt.Array.map(voiceFor)->Js.Array2.joinWith("|") ++ "|" ++ directed(segment) ++ "::chorus::" ++ pipelineVersion
}

let chorusCache = (chunk: chunk): path => {
  let segment = Belt.Array.getExn(chunk.segments, 0)
  Path(cacheDir ++ "/chorus_" ++ sha256Text(chorusSignature(segment)) ++ ".mp3")
}

let pathString = (Path(value)): string => value

let requireValidAudio = (path: path, label: string): unit => {
  if fileSizeMb(path) *. 1.0e6 <= 2000.0 {
    fail(label ++ " is too small to be valid audio")
  }
  let decoded = run(~cmd="ffmpeg", ~args=[
    "-nostdin", "-v", "error", "-i", pathString(path), "-f", "null", "-",
  ])
  if decoded.code != 0 {
    fail(label ++ " failed full audio decode")
  }
  let Seconds(duration) = probeDuration(path)
  if !Js.Float.isFinite(duration) || duration <= 0.05 {
    fail(label ++ " has invalid duration")
  }
}

/* An existing but corrupt cache is a hard stop. It is never treated as a cache
   miss, because doing so could silently buy a replacement take. */
let cacheValid = (path: path): bool => {
  if !exists(path) {
    false
  } else {
    requireValidAudio(path, "cached audio " ++ pathString(path))
    true
  }
}

let publishProviderRaw = (~blob, ~destination: path, ~label: string): path => {
  let scratch = tempDir("kuku-ep10-simple-provider-raw-")
  let candidate = Path(pathString(scratch) ++ "/response.mp3")
  let _ = writeBytes(candidate, blob)
  requireValidAudio(candidate, label ++ " provider response")
  if !publishFileExclusive(candidate, destination) {
    fail(label ++ " raw cache appeared concurrently; refusing to overwrite or retry")
  }
  requireValidAudio(destination, label ++ " immutable raw cache")
  destination
}
let paidAllowed = (dry: bool): bool => envPaid == Some("1") && !dry

let missingProviderRequests = (chunks: array<chunk>): int =>
  chunks->Belt.Array.reduce(0, (count, chunk) =>
    switch chunk.kind {
    | "chorus" if cacheValid(chorusCache(chunk)) => count
    | "chorus" => {
        let segment = Belt.Array.getExn(chunk.segments, 0)
        let missing = chorusMembers(segment.speaker)->Belt.Array.reduce(0, (n, speaker) =>
          cacheValid(singleCache(~speaker, ~text=directed(segment), ~purpose="chorus")) ||
          cacheValid(singleRawCache(~speaker, ~text=directed(segment), ~purpose="chorus"))
            ? n
            : n + 1
        )
        count + missing
      }
    | _ => cacheValid(dialogueCache(chunk)) || cacheValid(dialogueRawCache(chunk)) ? count : count + 1
    }
  )

let coldProviderRequests = (chunks: array<chunk>): int =>
  chunks->Belt.Array.reduce(0, (count, chunk) =>
    switch chunk.kind {
    | "chorus" => count + chorusMembers(Belt.Array.getExn(chunk.segments, 0).speaker)->Belt.Array.length
    | _ => count + 1
    }
  )

let providerBillableChars = (chunks: array<chunk>): int =>
  chunks->Belt.Array.reduce(0, (count, chunk) =>
    switch chunk.kind {
    | "chorus" =>
      count + chunk.chars * chorusMembers(Belt.Array.getExn(chunk.segments, 0).speaker)->Belt.Array.length
    | _ => count + chunk.chars
    }
  )

let contextualGaProvenanceJson = (): Js.Json.t => {
  if !exists(Path(contextualGaSourcePath)) || sha256File(Path(contextualGaSourcePath)) != contextualGaSourceSha256 {
    fail("frozen contextual ग source chunk is missing or changed")
  }
  if exists(Path(contextualGaAuditPath)) && sha256File(Path(contextualGaAuditPath)) != contextualGaAuditSha256 {
    fail("local contextual ग audit changed")
  }
  let row = Js.Dict.empty()
  Js.Dict.set(row, "method", Js.Json.string("zero-credit local Whisper transcription of completed old Episode 10 chunk"))
  Js.Dict.set(row, "source_audio", Js.Json.string(contextualGaSourcePath))
  Js.Dict.set(row, "source_audio_sha256", Js.Json.string(contextualGaSourceSha256))
  Js.Dict.set(row, "source_input_sha256", Js.Json.string(contextualGaSourceInputSha256))
  Js.Dict.set(row, "audit_path", Js.Json.string(contextualGaAuditPath))
  Js.Dict.set(row, "audit_sha256", Js.Json.string(contextualGaAuditSha256))
  Js.Dict.set(row, "transcript_at_01_11_48", Js.Json.string("गह अपनी जगा पर है"))
  Js.Dict.set(row, "finding", Js.Json.string("contextual Devanagari ग was spoken as Hindi ग/गह, not English जी; no transliteration or invented punctuation needed"))
  Js.Json.object_(row)
}

let normalize = (~src: path, ~out: path, ~lufs: int): path => {
  if cacheValid(out) {
    out
  } else {
    let scratch = tempDir("kuku-ep10-simple-normalize-")
    let candidate = Path(pathString(scratch) ++ "/normalized.mp3")
    ffmpeg([
      "-nostdin", "-loglevel", "error", "-y", "-i", pathString(src),
      "-af", "loudnorm=I=" ++ Belt.Int.toString(lufs) ++ ":TP=-1.5:LRA=11",
      "-c:a", "libmp3lame", "-q:a", "3", pathString(candidate),
    ])
    requireValidAudio(candidate, "normalized candidate")
    if !publishFileExclusive(candidate, out) {
      fail("normalized cache appeared concurrently; refusing overwrite")
    }
    requireValidAudio(out, "immutable normalized cache")
    out
  }
}

let renderDialogue = async (chunk: chunk, dry: bool): option<path> => {
  let out = dialogueCache(chunk)
  let rawCache = dialogueRawCache(chunk)
  if cacheValid(out) {
    Js.log("  reuse " ++ chunk.id ++ " dialogue")
    Some(out)
  } else if cacheValid(rawCache) && dry {
    Js.log("  would normalize cached raw " ++ chunk.id ++ " dialogue")
    None
  } else if cacheValid(rawCache) {
    let _ = normalize(~src=rawCache, ~out, ~lufs=-18)
    Js.log("  normalized cached raw " ++ chunk.id ++ " dialogue")
    Some(out)
  } else if dry {
    Js.log("  would render " ++ chunk.id ++ " dialogue, " ++ Belt.Int.toString(chunk.chars) ++ " chars")
    None
  } else {
    if !paidAllowed(dry) {
      fail("paid dialogue required for " ++ chunk.id ++ "; rerun with PAID=1")
    }
    let inputs = chunk.segments->Belt.Array.map(segment => (Text(directed(segment)), VoiceId(voiceFor(segment.speaker))))
    let voices = Js.Dict.empty()
    inputs->Belt.Array.forEach(((_, VoiceId(voice))) => Js.Dict.set(voices, voice, true))
    if Belt.Array.length(Js.Dict.keys(voices)) > 10 {
      fail(chunk.id ++ " exceeds ElevenLabs' ten-voice request limit")
    }
    let blob = await dialogue(inputs)
    let _ = publishProviderRaw(~blob, ~destination=rawCache, ~label=chunk.id ++ " dialogue")
    let _ = normalize(~src=rawCache, ~out, ~lufs=-18)
    Js.log("  rendered " ++ chunk.id ++ " dialogue")
    Some(out)
  }
}

let renderSingle = async (~speaker: string, ~text: string, ~purpose: string, ~label: string, ~dry: bool): option<path> => {
  let out = singleCache(~speaker, ~text, ~purpose)
  let rawCache = singleRawCache(~speaker, ~text, ~purpose)
  if cacheValid(out) {
    Some(out)
  } else if cacheValid(rawCache) && dry {
    Js.log("    would normalize cached raw " ++ label)
    None
  } else if cacheValid(rawCache) {
    let _ = normalize(~src=rawCache, ~out, ~lufs=-17)
    Some(out)
  } else if dry {
    Js.log("    would render " ++ label)
    None
  } else {
    if !paidAllowed(dry) {
      fail("paid single-voice take required for " ++ label ++ "; rerun with PAID=1")
    }
    let blob = await tts(~text=Text(text), ~voice=VoiceId(voiceFor(speaker)))
    let _ = publishProviderRaw(~blob, ~destination=rawCache, ~label)
    let _ = normalize(~src=rawCache, ~out, ~lufs=-17)
    Some(out)
  }
}

let renderChorus = async (chunk: chunk, dry: bool): option<path> => {
  let out = chorusCache(chunk)
  let segment = Belt.Array.getExn(chunk.segments, 0)
  let members = chorusMembers(segment.speaker)
  let text = directed(segment)
  if cacheValid(out) {
    Js.log("  reuse " ++ chunk.id ++ " chorus")
    Some(out)
  } else if dry {
    Js.log("  would render " ++ chunk.id ++ " " ++ Belt.Int.toString(Belt.Array.length(members)) ++ "-child chorus")
    members->Belt.Array.forEach(speaker =>
      ignore(renderSingle(~speaker, ~text, ~purpose="chorus", ~label=chunk.id ++ "/" ++ speaker, ~dry))
    )
    None
  } else {
    let parts: array<path> = []
    for i in 0 to Belt.Array.length(members) - 1 {
      let speaker = Belt.Array.getExn(members, i)
      switch await renderSingle(~speaker, ~text, ~purpose="chorus", ~label=chunk.id ++ "/" ++ speaker, ~dry) {
      | Some(path) => {let _ = Js.Array2.push(parts, path)}
      | None => ()
      }
    }
    if Belt.Array.length(parts) != Belt.Array.length(members) {
      fail(chunk.id ++ " chorus is missing a child voice")
    }
    let inputs = parts->Belt.Array.map(path => {let Path(value) = path; ["-i", value]})->Belt.Array.concatMany
    let scratch = tempDir("kuku-ep10-simple-chorus-")
    let candidate = Path(pathString(scratch) ++ "/chorus.mp3")
    let count = Belt.Int.toString(Belt.Array.length(parts))
    ffmpeg(Belt.Array.concatMany([
      ["-nostdin", "-loglevel", "error", "-y"],
      inputs,
      ["-filter_complex", "amix=inputs=" ++ count ++ ":duration=longest:normalize=1,loudnorm=I=-17:TP=-1.5:LRA=11", "-c:a", "libmp3lame", "-q:a", "3", pathString(candidate)],
    ]))
    requireValidAudio(candidate, chunk.id ++ " chorus mix")
    if !publishFileExclusive(candidate, out) {
      fail(chunk.id ++ " chorus cache appeared concurrently; refusing overwrite")
    }
    requireValidAudio(out, chunk.id ++ " immutable chorus cache")
    Js.log("  rendered " ++ chunk.id ++ " chorus")
    Some(out)
  }
}

let segmentJson = (segment: segment): Js.Json.t => {
  let row = Js.Dict.empty()
  Js.Dict.set(row, "order", Js.Json.number(Belt.Int.toFloat(segment.order)))
  Js.Dict.set(row, "scene", Js.Json.number(Belt.Int.toFloat(segment.scene)))
  Js.Dict.set(row, "dialogue_idx", Js.Json.number(Belt.Int.toFloat(segment.dialogueIdx)))
  Js.Dict.set(row, "kind", Js.Json.string(segment.kind))
  Js.Dict.set(row, "speaker", Js.Json.string(segment.speaker))
  Js.Dict.set(row, "direction", Js.Json.string(segment.direction))
  Js.Dict.set(row, "tag", Js.Json.string(segment.tag))
  Js.Dict.set(row, "text", Js.Json.string(segment.text))
  Js.Dict.set(row, "provider_text", Js.Json.string(segment.providerText))
  Js.Dict.set(row, "provider_text_provenance", Js.Json.string(segment.providerTextProvenance))
  Js.Json.object_(row)
}

let chunkInputHash = (chunk: chunk): string =>
  switch chunk.kind {
  | "chorus" => sha256Text(chorusSignature(Belt.Array.getExn(chunk.segments, 0)))
  | _ => sha256Text(dialogueSignature(chunk))
  }

let planJson = (segments: array<segment>, chunks: array<chunk>): Js.Json.t => {
  let cast = Js.Dict.empty()
  ["SUTRADHAR", "CHEEL", "RISHI", "DADI", "KUKU", "FYURIA", "VESPER", "CASTOR", "LEDA"]
  ->Belt.Array.forEach(speaker => Js.Dict.set(cast, speaker, Js.Json.string(voiceFor(speaker))))
  let chunkRows = chunks->Belt.Array.map(chunk => {
    let row = Js.Dict.empty()
    Js.Dict.set(row, "id", Js.Json.string(chunk.id))
    Js.Dict.set(row, "scene", Js.Json.number(Belt.Int.toFloat(chunk.scene)))
    Js.Dict.set(row, "kind", Js.Json.string(chunk.kind))
    Js.Dict.set(row, "characters", Js.Json.number(Belt.Int.toFloat(chunk.chars)))
    Js.Dict.set(row, "input_sha256", Js.Json.string(chunkInputHash(chunk)))
    Js.Dict.set(row, "segment_orders", Js.Json.array(chunk.segments->Belt.Array.map(segment => Js.Json.number(Belt.Int.toFloat(segment.order)))))
    Js.Json.object_(row)
  })
  let root = Js.Dict.empty()
  Js.Dict.set(root, "schema", Js.Json.string("kuku.table_read.plan.v3"))
  Js.Dict.set(root, "pipeline_version", Js.Json.string(pipelineVersion))
  Js.Dict.set(root, "screenplay", Js.Json.string(screenplay))
  Js.Dict.set(root, "screenplay_sha256", Js.Json.string(sha256File(Path(screenplay))))
  Js.Dict.set(root, "global_tagmap_sha256", Js.Json.string(sha256File(Path(globalTagmap))))
  Js.Dict.set(root, "local_tagmap_sha256", Js.Json.string(sha256File(Path(localTagmap))))
  Js.Dict.set(root, "model_id", Js.Json.string("eleven_v3"))
  Js.Dict.set(root, "provider_text_policy", Js.Json.string("exact cleaned Devanagari; contextual ग row frozen with provenance; no transliteration"))
  Js.Dict.set(root, "provider_execution", Js.Json.string("sequential; no automatic retries"))
  Js.Dict.set(root, "contextual_ga_pronunciation_provenance", contextualGaProvenanceJson())
  Js.Dict.set(root, "max_chunk_characters", Js.Json.number(Belt.Int.toFloat(maxChunkChars)))
  Js.Dict.set(root, "cast", Js.Json.object_(cast))
  Js.Dict.set(root, "segments", Js.Json.array(segments->Belt.Array.map(segmentJson)))
  Js.Dict.set(root, "chunks", Js.Json.array(chunkRows))
  Js.Dict.set(root, "cold_cache_provider_requests", Js.Json.number(Belt.Int.toFloat(coldProviderRequests(chunks))))
  Js.Dict.set(root, "directed_characters", Js.Json.number(Belt.Int.toFloat(chunks->Belt.Array.reduce(0, (sum, chunk) => sum + chunk.chars))))
  Js.Dict.set(root, "provider_billable_characters", Js.Json.number(Belt.Int.toFloat(providerBillableChars(chunks))))
  Js.Json.object_(root)
}

let writeImmutablePlan = (body: string): unit => {
  if exists(Path(planPath)) {
    if readText(Path(planPath)) != body {
      fail("immutable plan differs from current screenplay: " ++ planPath)
    }
  } else if !writeTextExclusive(Path(planPath), body) && readText(Path(planPath)) != body {
    fail("could not publish immutable plan: " ++ planPath)
  }
}

let paidLockBody = (planHash: string, initialMissing: int): string =>
  "Episode 10 simplified table-read paid-run lock.\n" ++
  "plan_sha256=" ++ planHash ++ "\n" ++
  "missing_provider_requests_at_start=" ++ Belt.Int.toString(initialMissing) ++ "\n" ++
  "This persistent lock prevents an accidental duplicate paid run.\n"

let acquirePaidLock = (planHash: string, initialMissing: int): unit => {
  if !writeTextExclusive(Path(paidLockPath), paidLockBody(planHash, initialMissing)) {
    fail(
      "paid-run lock already exists at " ++ paidLockPath ++
      "; refusing possible duplicate ElevenLabs charges",
    )
  }
}

let validateResume = (~planHash: string, ~currentMissing: int): unit => {
  if envPaid != Some("1") {
    fail("RESUME=1 requires PAID=1")
  }
  if !exists(Path(paidLockPath)) {
    fail("RESUME=1 requires the existing paid-run lock: " ++ paidLockPath)
  }
  let actual = readText(Path(paidLockPath))
  let missingPrefix = "missing_provider_requests_at_start="
  let initialMissing =
    switch actual->Js.String2.split("\n")->Belt.Array.get(2) {
    | Some(line) if Js.String2.startsWith(line, missingPrefix) =>
      Js.String2.sliceToEnd(line, ~from=Js.String2.length(missingPrefix))
      ->Belt.Int.fromString
      ->Belt.Option.getWithDefault(-1)
    | _ => -1
    }
  let expected = paidLockBody(planHash, initialMissing)
  if initialMissing <= 0 {
    fail("paid-run lock has no valid initial missing count")
  }
  if actual != expected {
    fail("paid-run lock does not exactly match the current plan hash and initial missing count")
  }
  if exists(Path(outputPath)) || exists(Path(manifestPath)) {
    fail("RESUME=1 requires output and manifest to remain absent")
  }
  if currentMissing < 0 {
    fail("RESUME=1 current missing count cannot be negative")
  }
  if currentMissing > initialMissing {
    fail("RESUME=1 current missing count exceeds the lock's initial missing count")
  }
  Js.log(
    "RESUME preflight validated existing lock: plan=" ++ planHash ++
    ", initial_missing=" ++ Belt.Int.toString(initialMissing) ++
    ", current_missing=" ++ Belt.Int.toString(currentMissing) ++
    "; lock preserved unchanged",
  )
  if currentMissing == 0 {
    Js.log("RESUME is assembly-only: every paid response is already cached; making zero provider calls")
  }
}

let renderAll = async (chunks: array<chunk>, dry: bool, planHash: string): unit => {
  ensureDirPath(Path(cacheDir))
  let tmp = tempDir("kuku-ep10-simple-table-read-")
  let files: array<option<path>> = []
  for i in 0 to Belt.Array.length(chunks) - 1 {
    let chunk = Belt.Array.getExn(chunks, i)
    let rendered = switch chunk.kind {
    | "chorus" => await renderChorus(chunk, dry)
    | _ => await renderDialogue(chunk, dry)
    }
    let _ = Js.Array2.push(files, rendered)
  }
  if dry {
    Js.log("DRY run — zero ElevenLabs calls; no audio was rendered or assembled.")
  } else {
    if exists(Path(outputPath)) || exists(Path(manifestPath)) {
      fail("published Episode 10 simplified table read already exists; refusing overwrite")
    }
    let parts: array<path> = []
    let renderedRows: array<Js.Json.t> = []
    let previousScene = ref(-999)
    for i in 0 to Belt.Array.length(chunks) - 1 {
      let chunk = Belt.Array.getExn(chunks, i)
      switch Belt.Array.getExn(files, i) {
      | Some(path) => {
          if Belt.Array.length(parts) > 0 {
            let gap = chunk.scene == previousScene.contents ? 300 : 1200
            let _ = Js.Array2.push(parts, silence(Millis(gap), Path(cacheDir)))
          }
          let _ = Js.Array2.push(parts, path)
          previousScene := chunk.scene
          let Seconds(duration) = probeDuration(path)
          let Path(file) = path
          let row = Js.Dict.empty()
          Js.Dict.set(row, "id", Js.Json.string(chunk.id))
          Js.Dict.set(row, "scene", Js.Json.number(Belt.Int.toFloat(chunk.scene)))
          Js.Dict.set(row, "kind", Js.Json.string(chunk.kind))
          Js.Dict.set(row, "input_sha256", Js.Json.string(chunkInputHash(chunk)))
          Js.Dict.set(row, "audio_sha256", Js.Json.string(sha256File(path)))
          Js.Dict.set(row, "cache_path", Js.Json.string(file))
          Js.Dict.set(row, "duration_seconds", Js.Json.number(duration))
          let _ = Js.Array2.push(renderedRows, Js.Json.object_(row))
        }
      | None => fail("missing rendered chunk " ++ chunk.id)
      }
    }
    let Path(temp) = tmp
    let tempOutput = Path(temp ++ "/EP10_SIMPLE_FULL_CAST_TABLE_READ_V3.mp3")
    let assembled = concatAudio(parts, tempOutput)
    let Seconds(total) = probeDuration(assembled)
    let audioHash = sha256File(assembled)
    if exists(Path(outputPath)) || exists(Path(manifestPath)) {
      fail("Episode 10 simplified output appeared during assembly; refusing overwrite")
    }
    if !publishFileExclusive(assembled, Path(outputPath)) {
      fail("Episode 10 simplified audio appeared during publication; refusing overwrite")
    }
    let root = Js.Dict.empty()
    Js.Dict.set(root, "schema", Js.Json.string("kuku.table_read.manifest.v3"))
    Js.Dict.set(root, "pipeline_version", Js.Json.string(pipelineVersion))
    Js.Dict.set(root, "plan", Js.Json.string(planPath))
    Js.Dict.set(root, "plan_sha256", Js.Json.string(planHash))
    Js.Dict.set(root, "audio", Js.Json.string(outputPath))
    Js.Dict.set(root, "audio_sha256", Js.Json.string(audioHash))
    Js.Dict.set(root, "duration_seconds", Js.Json.number(total))
    Js.Dict.set(root, "provider_billable_characters", Js.Json.number(Belt.Int.toFloat(providerBillableChars(chunks))))
    Js.Dict.set(root, "chunks", Js.Json.array(renderedRows))
    let manifestBody = Js.Json.object_(root)->Js.Json.stringifyWithSpace(1)
    if !writeTextExclusive(Path(manifestPath), manifestBody) {
      fail("immutable manifest already exists; audio was not overwritten")
    }
    Js.log("FULL CAST TABLE READ -> " ++ outputPath ++ " (" ++ Js.Float.toFixedWithPrecision(total /. 60.0, ~digits=1) ++ " min)")
    Js.log("IMMUTABLE MANIFEST -> " ++ manifestPath)
  }
}

let main = async () => {
  let dry = envDry == Some("1")
  let resume = envResume == Some("1")
  let segments = parseScreenplay()
  let chunks = chunkSegments(segments)
  let tooLarge = chunks->Belt.Array.keep(chunk => chunk.kind == "dialogue" && chunk.chars > maxChunkChars)
  if Belt.Array.length(tooLarge) > 0 {
    fail("a dialogue chunk exceeds " ++ Belt.Int.toString(maxChunkChars) ++ " characters")
  }
  let planBody = planJson(segments, chunks)->Js.Json.stringifyWithSpace(1)
  let planHash = sha256Text(planBody)
  writeImmutablePlan(planBody)
  let dialogueLines = segments->Belt.Array.keep(segment => segment.kind == "dialogue" || segment.kind == "chorus")
  let narrationLines = segments->Belt.Array.keep(segment => segment.kind == "narration")
  let totalChars = chunks->Belt.Array.reduce(0, (sum, chunk) => sum + chunk.chars)
  let missing = missingProviderRequests(chunks)
  Js.log(
    "plan: " ++ Belt.Int.toString(Belt.Array.length(dialogueLines)) ++ " dialogue lines, " ++
    Belt.Int.toString(Belt.Array.length(narrationLines)) ++ " narrated headings/actions/sounds, " ++
    Belt.Int.toString(Belt.Array.length(chunks)) ++ " chunks, " ++
    Belt.Int.toString(totalChars) ++ " directed characters",
  )
  Js.log(
    "provider requests: " ++ Belt.Int.toString(coldProviderRequests(chunks)) ++
    " on an empty cache; " ++ Belt.Int.toString(missing) ++ " currently missing",
  )
  Js.log(
    "characters: " ++ Belt.Int.toString(totalChars) ++ " directed once; " ++
    Belt.Int.toString(providerBillableChars(chunks)) ++ " provider-billable with chorus multiplied by five",
  )
  Js.log("PLAN -> " ++ planPath ++ " sha256=" ++ planHash)
  if !dry && (exists(Path(outputPath)) || exists(Path(manifestPath))) {
    fail("published Episode 10 simplified table read already exists; refusing any paid work or overwrite")
  }
  if resume {
    validateResume(~planHash, ~currentMissing=missing)
  } else {
    if !dry && missing > 0 && !paidAllowed(dry) {
      fail("missing " ++ Belt.Int.toString(missing) ++ " paid takes; production requires PAID=1")
    }
    if !dry && exists(Path(paidLockPath)) {
      fail(
        "paid-run lock already exists at " ++ paidLockPath ++
        "; use the separately guarded PAID=1 RESUME=1 path only for the interrupted run",
      )
    }
    if !dry && missing > 0 {
      acquirePaidLock(planHash, missing)
    }
  }
  await renderAll(chunks, dry, planHash)
}

let runMain = async () => {
  try await main() catch {
  | TableRead(message) => {
      Js.log("EP10 SIMPLE TABLE READ FAILED: " ++ message)
      exit(1)
    }
  | BackendError(message) => {
      Js.log("EP10 SIMPLE TABLE READ BACKEND FAILED: " ++ message)
      exit(1)
    }
  | Js.Exn.Error(error) => {
      Js.log("EP10 SIMPLE TABLE READ ASYNC JS FAILED: " ++ describeNodeError(error))
      exit(1)
    }
  }
}

runMain()->ignore
