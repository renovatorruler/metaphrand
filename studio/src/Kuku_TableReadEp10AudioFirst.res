/* कुकु और अक्षर — Episode 10 V4 audio-first full-cast table read.

   Only cast dialogue is sent to ElevenLabs. Ordinary action, headings and
   metadata are never spoken. Every screenplay `(ध्वनि: ...)` row is retained
   as an ordered, non-spoken cue with an exact local guide-SFX hook. The
   approved Kuku title song supplies a fifteen-second title interlude.

   Zero-cost validation:
     DRY=1 node src/Kuku_TableReadEp10AudioFirst.res.mjs

   Fresh production (may make paid calls):
     PAID=1 node src/Kuku_TableReadEp10AudioFirst.res.mjs

   Resume only an interrupted V4 run while preserving its existing lock:
     PAID=1 RESUME=1 node src/Kuku_TableReadEp10AudioFirst.res.mjs

   V4 has its own namespace and never searches V3 caches. Cache identities
   include the complete request signature. Provider calls are sequential and
   have no automatic retry. Raw responses are decoded before atomic publish. */

open Cinema_Backends

@val @scope(("process", "env")) external envDry: option<string> = "DRY"
@val @scope(("process", "env")) external envPaid: option<string> = "PAID"
@val @scope(("process", "env")) external envResume: option<string> = "RESUME"
@val @scope("process") external exit: int => unit = "exit"
@module("fs") external unlinkSync: string => unit = "unlinkSync"

@get external nodeErrorCause: Js.Exn.t => Js.Nullable.t<Js.Exn.t> = "cause"
@get external nodeErrorCode: Js.Exn.t => Js.Nullable.t<string> = "code"
@get external nodeErrorHostname: Js.Exn.t => Js.Nullable.t<string> = "hostname"
@get external nodeErrorSyscall: Js.Exn.t => Js.Nullable.t<string> = "syscall"

exception AudioFirst(string)

let dir = "../stories/kuku/ep10prod/audio_first_table_read_v4"
let screenplay = "../stories/kuku/2026-08-18_EP10_ga_gaay_SPEC_SCREENPLAY_v3_AUDIO_FIRST.md"
let tagmapPath = dir ++ "/expression_tags.v4.json"
let draftPlanPath = dir ++ "/EP10_AUDIO_FIRST_FULL_CAST_TABLE_READ_V4.DRAFT.plan.json"
let planPath = dir ++ "/EP10_AUDIO_FIRST_FULL_CAST_TABLE_READ_V4.plan.json"
let manifestPath = dir ++ "/EP10_AUDIO_FIRST_FULL_CAST_TABLE_READ_V4.manifest.json"
let outputPath = dir ++ "/EP10_AUDIO_FIRST_FULL_CAST_TABLE_READ_V4.mp3"
let paidLockPath = dir ++ "/EP10_AUDIO_FIRST_FULL_CAST_TABLE_READ_V4.PAID.lock"
let activeLeasePath = dir ++ "/EP10_AUDIO_FIRST_FULL_CAST_TABLE_READ_V4.ACTIVE.lease"
let cacheDir = dir ++ "/cache"
let guideSfxDir = dir ++ "/guide_sfx"

let titleSource = "../stories/kuku/titles/title_song.mp3"
let titleSourceSha256 = "33424e11dd558e743d7f1e55834009ec11d33fd25cb6f9f29f3a4cd5aefd4b45"
let titleExcerptMs = 15000

let pipelineVersion = "kuku-ep10-audio-first-table-read-v4"
let maxChunkChars = 1800
let expectedDialogueCues = 63
let expectedSfxCues = 22
let expectedExcludedActions = 18

type segment = {
  order: int,
  scene: int,
  dialogueIdx: int,
  sfxIdx: int,
  kind: string,
  speaker: string,
  direction: string,
  tag: string,
  text: string,
  providerText: string,
  providerTextProvenance: string,
  placeholderMs: int,
}

type chunk = {
  id: string,
  scene: int,
  kind: string,
  segments: array<segment>,
  chars: int,
}

type assemblyEntry =
  | VoiceChunk(int)
  | SfxCue(segment)
  | TitleCue(segment)

type guideAsset = {
  segment: segment,
  path: path,
  sha256: string,
  duration: float,
}

type config = {
  tags: Js.Dict.t<string>,
  lineTags: Js.Dict.t<string>,
  sfxTiming: Js.Dict.t<string>,
}

let fail = message => raise(AudioFirst(message))
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
  Belt.Array.length(parts) == 0 ? "unknown JavaScript error" : Js.Array2.joinWith(parts, "; ")
}

let describeNodeError = (error: Js.Exn.t): string =>
  switch nodeErrorCause(error)->Js.Nullable.toOption {
  | Some(cause) => describeNodeErrorPart(error) ++ "; cause: " ++ describeNodeErrorPart(cause)
  | None => describeNodeErrorPart(error)
  }

let stringDict = (j: Js.Json.t, field: string): Js.Dict.t<string> => {
  let out = Js.Dict.empty()
  switch fld(j, field)->Belt.Option.flatMap(Js.Json.decodeObject) {
  | Some(object) =>
    Js.Dict.entries(object)->Belt.Array.forEach(((key, value)) =>
      switch Js.Json.decodeString(value) {
      | Some(text) => Js.Dict.set(out, key, text)
      | None => ()
      }
    )
  | None => ()
  }
  out
}

let loadConfig = (): config => {
  let json = readText(Path(tagmapPath))->Js.Json.parseExn
  {
    tags: stringDict(json, "tags"),
    lineTags: stringDict(json, "line_tags"),
    sfxTiming: stringDict(json, "sfx_timing_ms"),
  }
}

let sceneNumber = (line: string): option<int> => {
  let bare = trim(line->Js.String2.replaceByRe(%re("/^#+[ \\t]*/"), ""))
  if !Js.String2.startsWith(bare, "दृश्य") {
    None
  } else {
    let rest = trim(Js.String2.sliceToEnd(bare, ~from=Js.String2.length("दृश्य")))
    let digits = [
      ("०", 0), ("१", 1), ("२", 2), ("३", 3), ("४", 4),
      ("५", 5), ("६", 6), ("७", 7), ("८", 8), ("९", 9),
    ]
    digits->Belt.Array.getBy(((digit, _)) => Js.String2.includes(rest, digit))->Belt.Option.map(((_, n)) => n)
  }
}

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
  | index => {
      let name = trim(Js.String2.slice(line, ~from=0, ~to_=index))
      let rest = trim(Js.String2.sliceToEnd(line, ~from=index + 1))
      Js.String2.length(name) > 0 && Js.String2.length(name) <= 18 ? Some((name, rest)) : None
    }
  }

let splitParenthetical = (rest: string): option<(string, string)> => {
  if !Js.String2.startsWith(rest, "(") {
    None
  } else {
    switch Js.String2.indexOf(rest, ")") {
    | -1 => None
    | index => Some((
        trim(Js.String2.slice(rest, ~from=1, ~to_=index)),
        clean(Js.String2.sliceToEnd(rest, ~from=index + 1)),
      ))
    }
  }
}

let isAction = (line: string): bool =>
  Js.String2.startsWith(line, "(") && Js.String2.endsWith(line, ")")

let isSfxAction = (line: string): bool => Js.String2.startsWith(line, "(ध्वनि:")

let sfxText = (line: string): string =>
  clean(
    Js.String2.slice(line, ~from=1, ~to_=Js.String2.length(line) - 1)
    ->Js.String2.replaceByRe(%re("/^ध्वनि:[ \\t]*/"), ""),
  )

let tagFor = (cfg: config, dialogueIdx: int, direction: string): option<string> =>
  switch Js.Dict.get(cfg.lineTags, Belt.Int.toString(dialogueIdx)) {
  | Some(tag) => Some(tag)
  | None => Js.Dict.get(cfg.tags, direction)
  }

let sfxTimingFor = (cfg: config, sfxIdx: int): int =>
  switch Js.Dict.get(cfg.sfxTiming, Belt.Int.toString(sfxIdx))->Belt.Option.flatMap(Belt.Int.fromString) {
  | Some(ms) if ms >= 250 && ms <= 10000 => ms
  | _ => fail("missing or invalid timing for SFX cue " ++ Belt.Int.toString(sfxIdx))
  }

let isPronunciationAudit = (segment: segment): bool =>
  switch (segment.dialogueIdx, segment.speaker, segment.providerText) {
  | (29, "KUKU", "गाड़ी, गाय और गुरुकुल, सबमें ग की आवाज़ है!") => true
  | (30, "LEDA", "गाड़ी आ रही है। अब पूरा ग बनाओ!") => true
  | (34, "CASTOR", "अरे! मेरे कड़े पर भी ग चमक रहा है!") => true
  | (41, "VESPER", "आगे के दोनों पहिए ग पर हैं!") => true
  | _ => false
  }

let isWordOnsetGuideSource = (segment: segment): bool =>
  switch (segment.dialogueIdx, segment.speaker, segment.providerText) {
  | (25, "FYURIA", "गाड़ी बहुत भारी है!") => true
  | (26, "CASTOR", "गाय फिर पीछे फिसल रही है!") => true
  | (27, "VESPER", "गाड़ी गुरुकुल की टूटी पटरी के पास पहुँच गई है!") => true
  | _ => false
  }

let parseScreenplay = (): array<segment> => {
  let cfg = loadConfig()
  let segments: array<segment> = []
  let currentScene = ref(-1)
  let order = ref(0)
  let dialogueIdx = ref(0)
  let sfxIdx = ref(0)
  let excludedActions = ref(0)
  let unresolved: array<string> = []
  let uncast: array<string> = []

  let push = (
    ~scene: int,
    ~dialogueIdx: int=0,
    ~sfxIdx: int=0,
    ~kind: string,
    ~speaker: string="",
    ~direction: string="",
    ~tag: string="",
    ~text: string,
    ~placeholderMs: int=0,
  ) => {
    order := order.contents + 1
    let providerText = kind == "dialogue" || kind == "chorus" ? clean(text) : ""
    let provenance = providerText == ""
      ? "not-provider-input"
      : "screenplay-exact-v4-audio-first-after-markdown-cleanup"
    let _ = Js.Array2.push(segments, {
      order: order.contents,
      scene,
      dialogueIdx,
      sfxIdx,
      kind,
      speaker,
      direction,
      tag,
      text: clean(text),
      providerText,
      providerTextProvenance: provenance,
      placeholderMs,
    })
  }

  readText(Path(screenplay))->Js.String2.split("\n")->Belt.Array.forEach(raw => {
    let line = trim(raw)
    if line != "" {
      if Js.String2.startsWith(line, "## शीर्षक-गीत") {
        if currentScene.contents != 0 {
          fail("title-song marker must follow scene 0")
        }
        push(
          ~scene=1000,
          ~dialogueIdx=dialogueIdx.contents,
          ~kind="title",
          ~text="शीर्षक-गीत",
          ~placeholderMs=titleExcerptMs,
        )
      } else {
        switch sceneNumber(line) {
        | Some(scene) => currentScene := scene
        | None if currentScene.contents >= 0 =>
          if line == "---" || Js.String2.startsWith(line, "#") {
            ()
          } else if isAction(line) {
            if isSfxAction(line) {
              sfxIdx := sfxIdx.contents + 1
              push(
                ~scene=currentScene.contents,
                ~dialogueIdx=dialogueIdx.contents,
                ~sfxIdx=sfxIdx.contents,
                ~kind="sfx",
                ~text=sfxText(line),
                ~placeholderMs=sfxTimingFor(cfg, sfxIdx.contents),
              )
            } else {
              excludedActions := excludedActions.contents + 1
            }
          } else {
            switch splitSpeaker(line) {
            | Some((name, rest)) =>
              switch splitParenthetical(rest) {
              | Some((direction, text)) =>
                switch speakerKey(name) {
                | Some(speaker) => {
                    dialogueIdx := dialogueIdx.contents + 1
                    switch tagFor(cfg, dialogueIdx.contents, direction) {
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
                    | None =>
                      ignore(Js.Array2.push(
                        unresolved,
                        Belt.Int.toString(dialogueIdx.contents) ++ " [" ++ direction ++ "] " ++ text,
                      ))
                    }
                  }
                | None => ignore(Js.Array2.push(uncast, name))
                }
              | None => ignore(Js.Array2.push(unresolved, "missing performance parenthetical: " ++ line))
              }
            | None => ()
            }
          }
        | None => ()
        }
      }
    }
  })

  if Belt.Array.length(uncast) > 0 {
    fail("uncast speakers: " ++ Js.Array2.joinWith(uncast, ", "))
  }
  if Belt.Array.length(unresolved) > 0 {
    unresolved->Belt.Array.forEach(item => Js.log("UNRESOLVED V4 TAG: " ++ item))
    fail(Belt.Int.toString(Belt.Array.length(unresolved)) ++ " unresolved V4 performance directions")
  }
  if dialogueIdx.contents != expectedDialogueCues || sfxIdx.contents != expectedSfxCues ||
     excludedActions.contents != expectedExcludedActions {
    fail(
      "audio-first snapshot drift: dialogue=" ++ Belt.Int.toString(dialogueIdx.contents) ++
      ", sfx=" ++ Belt.Int.toString(sfxIdx.contents) ++
      ", excluded_actions=" ++ Belt.Int.toString(excludedActions.contents),
    )
  }
  let dialogue = segments->Belt.Array.keep(segment => segment.kind == "dialogue")
  let chorus = segments->Belt.Array.keep(segment => segment.kind == "chorus")
  let sfx = segments->Belt.Array.keep(segment => segment.kind == "sfx")
  let titles = segments->Belt.Array.keep(segment => segment.kind == "title")
  let auditions = dialogue->Belt.Array.keep(isPronunciationAudit)
  let wordOnsetSources = dialogue->Belt.Array.keep(isWordOnsetGuideSource)
  if Belt.Array.length(segments) != 86 || Belt.Array.length(dialogue) != 61 ||
     Belt.Array.length(chorus) != 2 || Belt.Array.length(sfx) != 22 || Belt.Array.length(titles) != 1 {
    fail("audio-first snapshot must contain 61 solo dialogue, 2 chorus, 22 SFX and 1 title marker")
  }
  if Belt.Array.length(auditions) != 4 ||
     auditions->Belt.Array.map(segment => segment.speaker)->Js.Array2.joinWith(",") != "KUKU,LEDA,CASTOR,VESPER" {
    fail("the four production-used contextual ग pronunciation rows drifted")
  }
  if Belt.Array.length(wordOnsetSources) != 3 {
    fail("the three word-onset guide source rows drifted")
  }
  if Js.Dict.keys(cfg.sfxTiming)->Belt.Array.length != expectedSfxCues {
    fail("V4 SFX timing map must contain exactly 22 entries")
  }
  if segments->Belt.Array.some(segment => Js.String2.includes(segment.text, "`") || segment.speaker == "SUTRADHAR") {
    fail("V4 permits neither spoken markdown marks nor narrator segments")
  }
  segments
}

let pad3 = (value: int): string =>
  value < 10
    ? "00" ++ Belt.Int.toString(value)
    : value < 100
      ? "0" ++ Belt.Int.toString(value)
      : Belt.Int.toString(value)

let directed = (segment: segment): string =>
  segment.tag == "" ? segment.providerText : segment.tag ++ " " ++ segment.providerText

let chunkSegments = (segments: array<segment>): array<chunk> => {
  let chunks: array<chunk> = []
  let pending: ref<array<segment>> = ref([])
  let pendingScene = ref(-1)
  let pendingChars = ref(0)

  let addChunk = (~kind: string, ~scene: int, ~items: array<segment>, ~chars: int) => {
    ignore(Js.Array2.push(chunks, {
      id: "voice_" ++ pad3(Belt.Array.length(chunks)),
      scene,
      kind,
      segments: items,
      chars,
    }))
  }
  let flush = () => {
    if Belt.Array.length(pending.contents) > 0 {
      addChunk(
        ~kind="dialogue",
        ~scene=pendingScene.contents,
        ~items=pending.contents,
        ~chars=pendingChars.contents,
      )
      pending := []
      pendingScene := -1
      pendingChars := 0
    }
  }

  segments->Belt.Array.forEach(segment =>
    switch segment.kind {
    | "sfx" => flush()
    | "title" => flush()
    | "chorus" => {
        flush()
        addChunk(
          ~kind="chorus",
          ~scene=segment.scene,
          ~items=[segment],
          ~chars=Js.String2.length(directed(segment)),
        )
      }
    | "dialogue" if isPronunciationAudit(segment) => {
        flush()
        addChunk(
          ~kind="pronunciation",
          ~scene=segment.scene,
          ~items=[segment],
          ~chars=Js.String2.length(directed(segment)),
        )
      }
    | "dialogue" if isWordOnsetGuideSource(segment) => {
        flush()
        addChunk(
          ~kind="sfx_sync_source",
          ~scene=segment.scene,
          ~items=[segment],
          ~chars=Js.String2.length(directed(segment)),
        )
      }
    | "dialogue" => {
        let chars = Js.String2.length(directed(segment))
        if Belt.Array.length(pending.contents) > 0 &&
           (pendingScene.contents != segment.scene || pendingChars.contents + chars > maxChunkChars) {
          flush()
        }
        if Belt.Array.length(pending.contents) == 0 {
          pendingScene := segment.scene
        }
        pending := Belt.Array.concat(pending.contents, [segment])
        pendingChars := pendingChars.contents + chars
      }
    | other => fail("unexpected V4 segment kind while chunking: " ++ other)
    }
  )
  flush()
  chunks
}

let chunkIndexForOrder = (chunks: array<chunk>, order: int): option<int> => {
  let found = ref(None)
  for index in 0 to Belt.Array.length(chunks) - 1 {
    let chunk = Belt.Array.getExn(chunks, index)
    if chunk.segments->Belt.Array.some(segment => segment.order == order) {
      found := Some(index)
    }
  }
  found.contents
}

let assemblyEntries = (segments: array<segment>, chunks: array<chunk>): array<assemblyEntry> => {
  let entries: array<assemblyEntry> = []
  let emitted = Js.Dict.empty()
  segments->Belt.Array.forEach(segment =>
    switch segment.kind {
    | "dialogue" | "chorus" =>
      switch chunkIndexForOrder(chunks, segment.order) {
      | Some(index) => {
          let key = Belt.Int.toString(index)
          if Js.Dict.get(emitted, key) != Some(true) {
            Js.Dict.set(emitted, key, true)
            ignore(Js.Array2.push(entries, VoiceChunk(index)))
          }
        }
      | None => fail("dialogue segment is absent from V4 voice chunks: " ++ Belt.Int.toString(segment.order))
      }
    | "sfx" => ignore(Js.Array2.push(entries, SfxCue(segment)))
    | "title" => ignore(Js.Array2.push(entries, TitleCue(segment)))
    | other => fail("unexpected V4 assembly segment kind: " ++ other)
    }
  )
  if Belt.Array.length(Js.Dict.keys(emitted)) != Belt.Array.length(chunks) ||
     Belt.Array.length(entries) != Belt.Array.length(chunks) + expectedSfxCues + 1 {
    fail("V4 interleaved assembly sequence is incomplete")
  }
  entries
}

let voiceFor = (speaker: string): string =>
  switch Kuku_Cast.voiceOf(speaker) {
  | Some(voice) => voice
  | None => fail("no locked Kuku voice for " ++ speaker)
  }

let dialogueSignature = (chunk: chunk): string =>
  "pipeline=" ++ pipelineVersion ++ "\n" ++
  "endpoint=/v1/text-to-dialogue\noutput_format=mp3_44100_128\nmodel_id=eleven_v3\n" ++
  chunk.segments
  ->Belt.Array.map(segment =>
    "voice_id=" ++ voiceFor(segment.speaker) ++ "\ntext=" ++ directed(segment)
  )
  ->Js.Array2.joinWith("\n--input--\n")

let singleSignature = (~speaker: string, ~text: string, ~purpose: string): string =>
  "pipeline=" ++ pipelineVersion ++ "\nendpoint=/v1/text-to-speech/{voice_id}\n" ++
  "output_format=mp3_44100_128\nmodel_id=eleven_v3\nvoice_settings=omitted\n" ++
  "purpose=" ++ purpose ++ "\nvoice_id=" ++ voiceFor(speaker) ++ "\ntext=" ++ text

let chorusSignature = (segment: segment): string =>
  "pipeline=" ++ pipelineVersion ++ "\nlocal_mix=chorus\n" ++
  chorusMembers(segment.speaker)
  ->Belt.Array.map(speaker => singleSignature(~speaker, ~text=directed(segment), ~purpose=segment.speaker))
  ->Js.Array2.joinWith("\n--member--\n")

let dialogueCache = (chunk: chunk): path =>
  Path(cacheDir ++ "/dialogue_" ++ sha256Text(dialogueSignature(chunk)) ++ ".mp3")

let dialogueRawCache = (chunk: chunk): path =>
  Path(cacheDir ++ "/raw_dialogue_" ++ sha256Text(dialogueSignature(chunk)) ++ ".mp3")

let singleCache = (~speaker: string, ~text: string, ~purpose: string): path =>
  Path(cacheDir ++ "/single_" ++ sha256Text(singleSignature(~speaker, ~text, ~purpose)) ++ ".mp3")

let singleRawCache = (~speaker: string, ~text: string, ~purpose: string): path =>
  Path(cacheDir ++ "/raw_single_" ++ sha256Text(singleSignature(~speaker, ~text, ~purpose)) ++ ".mp3")

let chorusCache = (chunk: chunk): path =>
  Path(cacheDir ++ "/chorus_" ++ sha256Text(chorusSignature(Belt.Array.getExn(chunk.segments, 0))) ++ ".mp3")

let cueSignature = (segment: segment): string =>
  "pipeline=" ++ pipelineVersion ++ "\nkind=local-guide-sfx\ncue_index=" ++
  Belt.Int.toString(segment.sfxIdx) ++ "\ntext=" ++ segment.text ++
  "\nplaceholder_ms=" ++ Belt.Int.toString(segment.placeholderMs)

let guideSfxPath = (segment: segment): path => {
  let hash = sha256Text(cueSignature(segment))
  Path(guideSfxDir ++ "/cue_" ++ pad3(segment.sfxIdx) ++ "_" ++ hash ++ ".mp3")
}

let titleSignature = (): string =>
  "pipeline=" ++ pipelineVersion ++ "\nkind=approved-title-excerpt\nsource_sha256=" ++
  titleSourceSha256 ++ "\nstart_ms=0\nduration_ms=" ++ Belt.Int.toString(titleExcerptMs) ++
  "\nfade_out_ms=700"

let titleCache = (): path => Path(cacheDir ++ "/title_" ++ sha256Text(titleSignature()) ++ ".mp3")

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

let cacheValid = (path: path): bool => {
  if !exists(path) {
    false
  } else {
    requireValidAudio(path, "V4 cached audio " ++ pathString(path))
    true
  }
}

let ensureTitleSource = (): unit => {
  if !exists(Path(titleSource)) {
    fail("approved title source is missing: " ++ titleSource)
  }
  if sha256File(Path(titleSource)) != titleSourceSha256 {
    fail("approved title source changed: " ++ titleSource)
  }
}

let inspectGuideSfx = (segments: array<segment>): (array<guideAsset>, array<string>) => {
  let assets: array<guideAsset> = []
  let missing: array<string> = []
  segments->Belt.Array.forEach(segment =>
    if segment.kind == "sfx" {
      let guide = guideSfxPath(segment)
      if exists(guide) {
        requireValidAudio(guide, "required local guide SFX cue " ++ Belt.Int.toString(segment.sfxIdx))
        let Seconds(duration) = probeDuration(guide)
        ignore(Js.Array2.push(assets, {
          segment,
          path: guide,
          sha256: sha256File(guide),
          duration,
        }))
      } else {
        ignore(Js.Array2.push(missing, pathString(guide)))
      }
    }
  )
  (assets, missing)
}

let validateGuideAssets = (assets: array<guideAsset>): unit => {
  assets->Belt.Array.forEach(asset => {
    if !exists(asset.path) {
      fail("frozen local guide SFX disappeared: " ++ pathString(asset.path))
    }
    requireValidAudio(asset.path, "frozen local guide SFX cue " ++ Belt.Int.toString(asset.segment.sfxIdx))
    let Seconds(duration) = probeDuration(asset.path)
    if sha256File(asset.path) != asset.sha256 || Js.Math.abs_float(duration -. asset.duration) > 0.0001 {
      fail("local guide SFX bytes or duration changed after V4 plan freeze: " ++ pathString(asset.path))
    }
  })
}

let requireCompleteGuideSet = (assets: array<guideAsset>, missing: array<string>): unit => {
  if Belt.Array.length(missing) > 0 || Belt.Array.length(assets) != expectedSfxCues {
    fail(
      "all 22 local guide SFX files are required before lock/provider work; missing " ++
      Belt.Int.toString(Belt.Array.length(missing)) ++
      (Belt.Array.length(missing) > 0 ? ", first: " ++ Belt.Array.getExn(missing, 0) : ""),
    )
  }
  validateGuideAssets(assets)
}

let publishProviderRaw = (~blob, ~destination: path, ~label: string): path => {
  let scratch = tempDir("kuku-ep10-v4-provider-raw-")
  let candidate = Path(pathString(scratch) ++ "/response.mp3")
  ignore(writeBytes(candidate, blob))
  requireValidAudio(candidate, label ++ " provider response")
  if !publishFileExclusive(candidate, destination) {
    fail(label ++ " raw cache appeared concurrently; refusing overwrite and retry")
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
        count + chorusMembers(segment.speaker)->Belt.Array.reduce(0, (missing, speaker) =>
          cacheValid(singleCache(~speaker, ~text=directed(segment), ~purpose=segment.speaker)) ||
          cacheValid(singleRawCache(~speaker, ~text=directed(segment), ~purpose=segment.speaker))
            ? missing
            : missing + 1
        )
      }
    | _ =>
      cacheValid(dialogueCache(chunk)) || cacheValid(dialogueRawCache(chunk)) ? count : count + 1
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

let normalize = (~src: path, ~out: path, ~lufs: int): path => {
  if cacheValid(out) {
    out
  } else {
    let scratch = tempDir("kuku-ep10-v4-normalize-")
    let candidate = Path(pathString(scratch) ++ "/normalized.mp3")
    ffmpeg([
      "-nostdin", "-loglevel", "error", "-y", "-i", pathString(src),
      "-af", "loudnorm=I=" ++ Belt.Int.toString(lufs) ++ ":TP=-1.5:LRA=11",
      "-c:a", "libmp3lame", "-q:a", "3", pathString(candidate),
    ])
    requireValidAudio(candidate, "V4 normalized candidate")
    if !publishFileExclusive(candidate, out) {
      fail("V4 normalized cache appeared concurrently; refusing overwrite")
    }
    requireValidAudio(out, "V4 immutable normalized cache")
    out
  }
}

let renderDialogue = async (chunk: chunk, dry: bool): option<path> => {
  let out = dialogueCache(chunk)
  let raw = dialogueRawCache(chunk)
  if cacheValid(out) {
    Js.log("  reuse " ++ chunk.id ++ " " ++ chunk.kind)
    Some(out)
  } else if cacheValid(raw) && dry {
    Js.log("  would normalize cached raw " ++ chunk.id ++ " " ++ chunk.kind)
    None
  } else if cacheValid(raw) {
    ignore(normalize(~src=raw, ~out, ~lufs=-18))
    Js.log("  normalized cached raw " ++ chunk.id ++ " " ++ chunk.kind)
    Some(out)
  } else if dry {
    let suffix = switch chunk.kind {
    | "pronunciation" => " [production pronunciation audition]"
    | "sfx_sync_source" => " [isolated word-onset guide source]"
    | _ => ""
    }
    Js.log(
      "  would render " ++ chunk.id ++ " " ++ chunk.kind ++ ", " ++
      Belt.Int.toString(chunk.chars) ++ " chars" ++ suffix,
    )
    None
  } else {
    if !paidAllowed(dry) {
      fail("paid V4 dialogue required for " ++ chunk.id ++ "; rerun with PAID=1")
    }
    let inputs = chunk.segments->Belt.Array.map(segment =>
      (Text(directed(segment)), VoiceId(voiceFor(segment.speaker)))
    )
    let voices = Js.Dict.empty()
    inputs->Belt.Array.forEach(((_, VoiceId(voice))) => Js.Dict.set(voices, voice, true))
    if Belt.Array.length(Js.Dict.keys(voices)) > 10 {
      fail(chunk.id ++ " exceeds ElevenLabs' ten-voice dialogue limit")
    }
    let blob = await dialogue(inputs)
    ignore(publishProviderRaw(~blob, ~destination=raw, ~label=chunk.id ++ " " ++ chunk.kind))
    ignore(normalize(~src=raw, ~out, ~lufs=-18))
    Js.log("  rendered " ++ chunk.id ++ " " ++ chunk.kind)
    Some(out)
  }
}

let renderSingle = async (
  ~speaker: string,
  ~text: string,
  ~purpose: string,
  ~label: string,
  ~dry: bool,
): option<path> => {
  let out = singleCache(~speaker, ~text, ~purpose)
  let raw = singleRawCache(~speaker, ~text, ~purpose)
  if cacheValid(out) {
    Some(out)
  } else if cacheValid(raw) && dry {
    Js.log("    would normalize cached raw " ++ label)
    None
  } else if cacheValid(raw) {
    ignore(normalize(~src=raw, ~out, ~lufs=-17))
    Some(out)
  } else if dry {
    Js.log("    would render " ++ label)
    None
  } else {
    if !paidAllowed(dry) {
      fail("paid V4 chorus take required for " ++ label ++ "; rerun with PAID=1")
    }
    let blob = await tts(~text=Text(text), ~voice=VoiceId(voiceFor(speaker)))
    ignore(publishProviderRaw(~blob, ~destination=raw, ~label))
    ignore(normalize(~src=raw, ~out, ~lufs=-17))
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
  } else {
    let parts: array<path> = []
    if dry {
      Js.log(
        "  would render " ++ chunk.id ++ " " ++ Belt.Int.toString(Belt.Array.length(members)) ++
        "-child chorus",
      )
    }
    for index in 0 to Belt.Array.length(members) - 1 {
      let speaker = Belt.Array.getExn(members, index)
      switch await renderSingle(
        ~speaker,
        ~text,
        ~purpose=segment.speaker,
        ~label=chunk.id ++ "/" ++ speaker,
        ~dry,
      ) {
      | Some(path) => ignore(Js.Array2.push(parts, path))
      | None => ()
      }
    }
    if dry {
      None
    } else {
      if Belt.Array.length(parts) != Belt.Array.length(members) {
        fail(chunk.id ++ " chorus is missing a child voice")
      }
      let inputs = parts->Belt.Array.map(path => ["-i", pathString(path)])->Belt.Array.concatMany
      let scratch = tempDir("kuku-ep10-v4-chorus-")
      let candidate = Path(pathString(scratch) ++ "/chorus.mp3")
      ffmpeg(Belt.Array.concatMany([
        ["-nostdin", "-loglevel", "error", "-y"],
        inputs,
        [
          "-filter_complex",
          "amix=inputs=" ++ Belt.Int.toString(Belt.Array.length(parts)) ++
          ":duration=longest:normalize=1,loudnorm=I=-17:TP=-1.5:LRA=11",
          "-c:a", "libmp3lame", "-q:a", "3", pathString(candidate),
        ],
      ]))
      requireValidAudio(candidate, chunk.id ++ " V4 chorus mix")
      if !publishFileExclusive(candidate, out) {
        fail(chunk.id ++ " V4 chorus cache appeared concurrently; refusing overwrite")
      }
      requireValidAudio(out, chunk.id ++ " V4 immutable chorus cache")
      Js.log("  rendered " ++ chunk.id ++ " chorus")
      Some(out)
    }
  }
}

let chunkInputHash = (chunk: chunk): string =>
  switch chunk.kind {
  | "chorus" => sha256Text(chorusSignature(Belt.Array.getExn(chunk.segments, 0)))
  | _ => sha256Text(dialogueSignature(chunk))
  }

let segmentJson = (segment: segment): Js.Json.t => {
  let row = Js.Dict.empty()
  Js.Dict.set(row, "order", Js.Json.number(Belt.Int.toFloat(segment.order)))
  Js.Dict.set(row, "scene", Js.Json.number(Belt.Int.toFloat(segment.scene)))
  Js.Dict.set(row, "kind", Js.Json.string(segment.kind))
  Js.Dict.set(row, "text", Js.Json.string(segment.text))
  switch segment.kind {
  | "dialogue" | "chorus" => {
      Js.Dict.set(row, "dialogue_idx", Js.Json.number(Belt.Int.toFloat(segment.dialogueIdx)))
      Js.Dict.set(row, "speaker", Js.Json.string(segment.speaker))
      Js.Dict.set(row, "direction", Js.Json.string(segment.direction))
      Js.Dict.set(row, "expression_tag", Js.Json.string(segment.tag))
      Js.Dict.set(row, "provider_text", Js.Json.string(segment.providerText))
      Js.Dict.set(row, "provider_text_provenance", Js.Json.string(segment.providerTextProvenance))
      Js.Dict.set(row, "production_pronunciation_audition", Js.Json.boolean(isPronunciationAudit(segment)))
      Js.Dict.set(row, "word_onset_guide_source", Js.Json.boolean(isWordOnsetGuideSource(segment)))
    }
  | "sfx" => {
      Js.Dict.set(row, "sfx_idx", Js.Json.number(Belt.Int.toFloat(segment.sfxIdx)))
      Js.Dict.set(row, "after_dialogue_idx", Js.Json.number(Belt.Int.toFloat(segment.dialogueIdx)))
      Js.Dict.set(row, "before_dialogue_idx", Js.Json.number(Belt.Int.toFloat(segment.dialogueIdx + 1)))
      Js.Dict.set(row, "placeholder_ms", Js.Json.number(Belt.Int.toFloat(segment.placeholderMs)))
      Js.Dict.set(row, "cue_signature_sha256", Js.Json.string(sha256Text(cueSignature(segment))))
      Js.Dict.set(row, "local_guide_path", Js.Json.string(pathString(guideSfxPath(segment))))
      Js.Dict.set(row, "spoken", Js.Json.boolean(false))
      if segment.sfxIdx >= 8 && segment.sfxIdx <= 10 {
        Js.Dict.set(
          row,
          "timing_limitation",
          Js.Json.string(
            "table-read guide is inserted immediately after the isolated source line; final word-onset placement requires line-level alignment",
          ),
        )
      }
    }
  | "title" => {
      Js.Dict.set(row, "after_dialogue_idx", Js.Json.number(Belt.Int.toFloat(segment.dialogueIdx)))
      Js.Dict.set(row, "before_dialogue_idx", Js.Json.number(Belt.Int.toFloat(segment.dialogueIdx + 1)))
      Js.Dict.set(row, "source", Js.Json.string(titleSource))
      Js.Dict.set(row, "source_sha256", Js.Json.string(titleSourceSha256))
      Js.Dict.set(row, "excerpt_ms", Js.Json.number(Belt.Int.toFloat(titleExcerptMs)))
    }
  | _ => ()
  }
  Js.Json.object_(row)
}

let chunkJson = (chunk: chunk): Js.Json.t => {
  let row = Js.Dict.empty()
  Js.Dict.set(row, "id", Js.Json.string(chunk.id))
  Js.Dict.set(row, "scene", Js.Json.number(Belt.Int.toFloat(chunk.scene)))
  Js.Dict.set(row, "kind", Js.Json.string(chunk.kind))
  Js.Dict.set(row, "characters", Js.Json.number(Belt.Int.toFloat(chunk.chars)))
  Js.Dict.set(row, "input_sha256", Js.Json.string(chunkInputHash(chunk)))
  Js.Dict.set(
    row,
    "dialogue_indices",
    Js.Json.array(chunk.segments->Belt.Array.map(segment => Js.Json.number(Belt.Int.toFloat(segment.dialogueIdx)))),
  )
  Js.Dict.set(
    row,
    "segment_orders",
    Js.Json.array(chunk.segments->Belt.Array.map(segment => Js.Json.number(Belt.Int.toFloat(segment.order)))),
  )
  Js.Dict.set(
    row,
    "provider_requests",
    Js.Json.number(Belt.Int.toFloat(
      chunk.kind == "chorus"
        ? chorusMembers(Belt.Array.getExn(chunk.segments, 0).speaker)->Belt.Array.length
        : 1,
    )),
  )
  Js.Json.object_(row)
}

let assemblyEntryJson = (chunks: array<chunk>, entry: assemblyEntry): Js.Json.t => {
  let row = Js.Dict.empty()
  switch entry {
  | VoiceChunk(index) => {
      let chunk = Belt.Array.getExn(chunks, index)
      Js.Dict.set(row, "kind", Js.Json.string("voice_chunk"))
      Js.Dict.set(row, "chunk_id", Js.Json.string(chunk.id))
      Js.Dict.set(row, "scene", Js.Json.number(Belt.Int.toFloat(chunk.scene)))
      Js.Dict.set(
        row,
        "dialogue_indices",
        Js.Json.array(chunk.segments->Belt.Array.map(segment => Js.Json.number(Belt.Int.toFloat(segment.dialogueIdx)))),
      )
    }
  | SfxCue(segment) => {
      Js.Dict.set(row, "kind", Js.Json.string("guide_sfx"))
      Js.Dict.set(row, "sfx_idx", Js.Json.number(Belt.Int.toFloat(segment.sfxIdx)))
      Js.Dict.set(row, "scene", Js.Json.number(Belt.Int.toFloat(segment.scene)))
      Js.Dict.set(row, "path", Js.Json.string(pathString(guideSfxPath(segment))))
      Js.Dict.set(row, "after_dialogue_idx", Js.Json.number(Belt.Int.toFloat(segment.dialogueIdx)))
    }
  | TitleCue(_) => {
      Js.Dict.set(row, "kind", Js.Json.string("title_interlude"))
      Js.Dict.set(row, "source", Js.Json.string(titleSource))
      Js.Dict.set(row, "excerpt_ms", Js.Json.number(Belt.Int.toFloat(titleExcerptMs)))
    }
  }
  Js.Json.object_(row)
}

let pronunciationAuditJson = (segment: segment): Js.Json.t => {
  let row = Js.Dict.empty()
  Js.Dict.set(row, "dialogue_idx", Js.Json.number(Belt.Int.toFloat(segment.dialogueIdx)))
  Js.Dict.set(row, "speaker", Js.Json.string(segment.speaker))
  Js.Dict.set(row, "voice_id", Js.Json.string(voiceFor(segment.speaker)))
  Js.Dict.set(row, "exact_directed_text", Js.Json.string(directed(segment)))
  Js.Dict.set(row, "policy", Js.Json.string("isolated production request; accepted take is used in the master; not an extra probe"))
  Js.Json.object_(row)
}

let guideAssetJson = (asset: guideAsset): Js.Json.t => {
  let row = Js.Dict.empty()
  Js.Dict.set(row, "sfx_idx", Js.Json.number(Belt.Int.toFloat(asset.segment.sfxIdx)))
  Js.Dict.set(row, "cue_signature_sha256", Js.Json.string(sha256Text(cueSignature(asset.segment))))
  Js.Dict.set(row, "path", Js.Json.string(pathString(asset.path)))
  Js.Dict.set(row, "audio_sha256", Js.Json.string(asset.sha256))
  Js.Dict.set(row, "decoded_duration_seconds", Js.Json.number(asset.duration))
  Js.Dict.set(
    row,
    "provenance",
    Js.Json.string(
      "local guide asset supplied by the separate Episode 10 SFX build; this V4 renderer did not generate, synthesize or modify it",
    ),
  )
  Js.Dict.set(row, "verification", Js.Json.string("full ffmpeg decode, ffprobe duration and SHA-256 byte digest"))
  Js.Json.object_(row)
}

let planJson = (
  segments: array<segment>,
  chunks: array<chunk>,
  guideAssets: array<guideAsset>,
  missingGuides: array<string>,
): Js.Json.t => {
  ensureTitleSource()
  let cast = Js.Dict.empty()
  ["CHEEL", "RISHI", "DADI", "KUKU", "FYURIA", "VESPER", "CASTOR", "LEDA"]
  ->Belt.Array.forEach(speaker => Js.Dict.set(cast, speaker, Js.Json.string(voiceFor(speaker))))
  let dialogue = segments->Belt.Array.keep(segment => segment.kind == "dialogue" || segment.kind == "chorus")
  let solo = segments->Belt.Array.keep(segment => segment.kind == "dialogue")
  let chorus = segments->Belt.Array.keep(segment => segment.kind == "chorus")
  let sfx = segments->Belt.Array.keep(segment => segment.kind == "sfx")
  let titles = segments->Belt.Array.keep(segment => segment.kind == "title")
  let auditions = segments->Belt.Array.keep(isPronunciationAudit)
  let wordOnsetSources = segments->Belt.Array.keep(isWordOnsetGuideSource)
  let assembly = assemblyEntries(segments, chunks)
  let directedChars = chunks->Belt.Array.reduce(0, (total, chunk) => total + chunk.chars)
  let root = Js.Dict.empty()
  Js.Dict.set(root, "schema", Js.Json.string("kuku.audio_first.table_read.plan.v4"))
  Js.Dict.set(root, "pipeline_version", Js.Json.string(pipelineVersion))
  Js.Dict.set(root, "screenplay", Js.Json.string(screenplay))
  Js.Dict.set(root, "screenplay_sha256", Js.Json.string(sha256File(Path(screenplay))))
  Js.Dict.set(root, "expression_tagmap", Js.Json.string(tagmapPath))
  Js.Dict.set(root, "expression_tagmap_sha256", Js.Json.string(sha256File(Path(tagmapPath))))
  Js.Dict.set(root, "model_id", Js.Json.string("eleven_v3"))
  Js.Dict.set(root, "provider_execution", Js.Json.string("strictly sequential; no automatic retries"))
  Js.Dict.set(root, "cache_policy", Js.Json.string("V4-only content-addressed complete request signatures; no V3 lookup, fallback or implicit import"))
  Js.Dict.set(root, "speech_policy", Js.Json.string("cast dialogue only; no narrator, ordinary action, heading, metadata or spoken SFX cue"))
  Js.Dict.set(root, "sfx_policy", Js.Json.string("all 22 non-spoken cues are hard voice-chunk boundaries and are inserted from exact validated local guide paths; no effect generated or fabricated by this renderer"))
  Js.Dict.set(root, "word_onset_chime_limitation", Js.Json.string("cues 8-10 are inserted immediately after their isolated source line in the table-read guide; final mix must align them to the named word onset"))
  Js.Dict.set(root, "guide_assets_complete", Js.Json.boolean(Belt.Array.length(missingGuides) == 0 && Belt.Array.length(guideAssets) == expectedSfxCues))
  Js.Dict.set(root, "guide_asset_inventory", Js.Json.array(guideAssets->Belt.Array.map(guideAssetJson)))
  Js.Dict.set(root, "missing_guide_paths", Js.Json.array(missingGuides->Belt.Array.map(Js.Json.string)))
  Js.Dict.set(root, "excluded_ordinary_action_lines", Js.Json.number(Belt.Int.toFloat(expectedExcludedActions)))
  Js.Dict.set(root, "screenplay_audio_cues", Js.Json.number(Belt.Int.toFloat(Belt.Array.length(dialogue) + Belt.Array.length(sfx))))
  Js.Dict.set(root, "dialogue_cues", Js.Json.number(Belt.Int.toFloat(Belt.Array.length(dialogue))))
  Js.Dict.set(root, "solo_dialogue_cues", Js.Json.number(Belt.Int.toFloat(Belt.Array.length(solo))))
  Js.Dict.set(root, "chorus_cues", Js.Json.number(Belt.Int.toFloat(Belt.Array.length(chorus))))
  Js.Dict.set(root, "sfx_cues", Js.Json.number(Belt.Int.toFloat(Belt.Array.length(sfx))))
  Js.Dict.set(root, "title_interludes", Js.Json.number(Belt.Int.toFloat(Belt.Array.length(titles))))
  Js.Dict.set(root, "voice_chunks", Js.Json.number(Belt.Int.toFloat(Belt.Array.length(chunks))))
  Js.Dict.set(root, "cold_cache_provider_requests", Js.Json.number(Belt.Int.toFloat(coldProviderRequests(chunks))))
  Js.Dict.set(root, "directed_characters", Js.Json.number(Belt.Int.toFloat(directedChars)))
  Js.Dict.set(root, "provider_billable_characters", Js.Json.number(Belt.Int.toFloat(providerBillableChars(chunks))))
  Js.Dict.set(root, "max_chunk_characters", Js.Json.number(Belt.Int.toFloat(maxChunkChars)))
  Js.Dict.set(root, "cast", Js.Json.object_(cast))
  let title = Js.Dict.empty()
  Js.Dict.set(title, "source", Js.Json.string(titleSource))
  Js.Dict.set(title, "source_sha256", Js.Json.string(titleSourceSha256))
  Js.Dict.set(title, "excerpt_start_ms", Js.Json.number(0.0))
  Js.Dict.set(title, "excerpt_duration_ms", Js.Json.number(Belt.Int.toFloat(titleExcerptMs)))
  Js.Dict.set(title, "fade_out_ms", Js.Json.number(700.0))
  Js.Dict.set(root, "approved_title_interlude", Js.Json.object_(title))
  Js.Dict.set(root, "production_pronunciation_auditions", Js.Json.array(auditions->Belt.Array.map(pronunciationAuditJson)))
  Js.Dict.set(root, "word_onset_guide_source_rows", Js.Json.array(wordOnsetSources->Belt.Array.map(segmentJson)))
  Js.Dict.set(root, "ordered_timeline", Js.Json.array(segments->Belt.Array.map(segmentJson)))
  Js.Dict.set(root, "voice_chunks_plan", Js.Json.array(chunks->Belt.Array.map(chunkJson)))
  Js.Dict.set(root, "deterministic_assembly_sequence", Js.Json.array(assembly->Belt.Array.map(entry => assemblyEntryJson(chunks, entry))))
  Js.Json.object_(root)
}

let writeImmutablePlan = (body: string): unit => {
  if exists(Path(planPath)) {
    if readText(Path(planPath)) != body {
      fail("immutable V4 plan differs from current screenplay/config: " ++ planPath)
    }
  } else if !writeTextExclusive(Path(planPath), body) && readText(Path(planPath)) != body {
    fail("could not publish immutable V4 plan: " ++ planPath)
  }
}

let writeDraftPlan = (body: string): unit => writeText(Path(draftPlanPath), body)

let paidLockBody = (planHash: string, initialMissing: int): string =>
  "Episode 10 V4 audio-first paid-run lock.\n" ++
  "plan_sha256=" ++ planHash ++ "\n" ++
  "missing_provider_requests_at_start=" ++ Belt.Int.toString(initialMissing) ++ "\n" ++
  "This persistent lock prevents accidental duplicate ElevenLabs charges.\n"

let acquirePaidLock = (planHash: string, initialMissing: int): unit => {
  if !writeTextExclusive(Path(paidLockPath), paidLockBody(planHash, initialMissing)) {
    fail("V4 paid-run lock already exists; refusing possible duplicate charges: " ++ paidLockPath)
  }
}

let validateResume = (~planHash: string, ~currentMissing: int): unit => {
  if envPaid != Some("1") {
    fail("V4 RESUME=1 requires PAID=1")
  }
  if !exists(Path(paidLockPath)) {
    fail("V4 RESUME=1 requires the existing V4 paid-run lock: " ++ paidLockPath)
  }
  let actual = readText(Path(paidLockPath))
  let prefix = "missing_provider_requests_at_start="
  let initialMissing =
    switch actual->Js.String2.split("\n")->Belt.Array.get(2) {
    | Some(line) if Js.String2.startsWith(line, prefix) =>
      Js.String2.sliceToEnd(line, ~from=Js.String2.length(prefix))
      ->Belt.Int.fromString
      ->Belt.Option.getWithDefault(-1)
    | _ => -1
    }
  if initialMissing <= 0 || actual != paidLockBody(planHash, initialMissing) {
    fail("V4 paid-run lock does not exactly match the current plan and initial request count")
  }
  if exists(Path(outputPath)) || exists(Path(manifestPath)) {
    fail("V4 RESUME=1 requires output and manifest to remain absent")
  }
  if currentMissing < 0 || currentMissing > initialMissing {
    fail("V4 resume request count is outside the lock's initial range")
  }
  Js.log(
    "V4 RESUME preflight validated existing lock: plan=" ++ planHash ++
    ", initial_missing=" ++ Belt.Int.toString(initialMissing) ++
    ", current_missing=" ++ Belt.Int.toString(currentMissing) ++
    "; lock preserved unchanged",
  )
  if currentMissing == 0 {
    Js.log("V4 RESUME is assembly-only; all provider responses are already cached")
  }
}

let activeLeaseBody = (planHash: string, mode: string): string =>
  "Episode 10 V4 active provider lease.\n" ++
  "plan_sha256=" ++ planHash ++ "\n" ++
  "mode=" ++ mode ++ "\n" ++
  "Only one process may hold this lease while issuing or assembling V4 takes.\n"

let acquireActiveLease = (planHash: string, mode: string): string => {
  let body = activeLeaseBody(planHash, mode)
  if !writeTextExclusive(Path(activeLeasePath), body) {
    fail(
      "V4 active lease already exists; refusing concurrent duplicate provider work: " ++
      activeLeasePath,
    )
  }
  body
}

let releaseActiveLease = (expectedBody: string): unit => {
  if !exists(Path(activeLeasePath)) {
    fail("V4 active lease disappeared before guarded work completed")
  }
  if readText(Path(activeLeasePath)) != expectedBody {
    fail("V4 active lease changed ownership; refusing to remove it")
  }
  try {
    unlinkSync(activeLeasePath)
  } catch {
  | Js.Exn.Error(error) =>
    fail("could not release V4 active lease: " ++ describeNodeError(error))
  }
}

let makeTitleExcerpt = (): path => {
  ensureTitleSource()
  let out = titleCache()
  if cacheValid(out) {
    out
  } else {
    requireValidAudio(Path(titleSource), "approved Kuku title source")
    let scratch = tempDir("kuku-ep10-v4-title-")
    let candidate = Path(pathString(scratch) ++ "/title_excerpt.mp3")
    ffmpeg([
      "-nostdin", "-loglevel", "error", "-y", "-i", titleSource,
      "-t", "15.000", "-af", "afade=t=out:st=14.300:d=0.700",
      "-c:a", "libmp3lame", "-q:a", "3", pathString(candidate),
    ])
    requireValidAudio(candidate, "V4 title excerpt candidate")
    if !publishFileExclusive(candidate, out) {
      fail("V4 title excerpt cache appeared concurrently; refusing overwrite")
    }
    requireValidAudio(out, "V4 immutable title excerpt")
    out
  }
}

let timelineAudioRow = (
  ~kind: string,
  ~id: string,
  ~scene: int,
  ~path: path,
  ~start: float,
): (Js.Json.t, float) => {
  let Seconds(duration) = probeDuration(path)
  let row = Js.Dict.empty()
  Js.Dict.set(row, "kind", Js.Json.string(kind))
  Js.Dict.set(row, "id", Js.Json.string(id))
  Js.Dict.set(row, "scene", Js.Json.number(Belt.Int.toFloat(scene)))
  Js.Dict.set(row, "start_seconds", Js.Json.number(start))
  Js.Dict.set(row, "duration_seconds", Js.Json.number(duration))
  Js.Dict.set(row, "path", Js.Json.string(pathString(path)))
  Js.Dict.set(row, "sha256", Js.Json.string(sha256File(path)))
  (Js.Json.object_(row), duration)
}

let rollbackPublishedFile = (~path: path, ~expectedSha256: string, ~label: string): unit => {
  if exists(path) {
    if sha256File(path) != expectedSha256 {
      fail("refusing to roll back changed " ++ label ++ ": " ++ pathString(path))
    }
    try {
      unlinkSync(pathString(path))
    } catch {
    | Js.Exn.Error(error) =>
      fail("could not roll back " ++ label ++ ": " ++ describeNodeError(error))
    }
  }
}

let renderAll = async (
  segments: array<segment>,
  chunks: array<chunk>,
  guideAssets: array<guideAsset>,
  dry: bool,
  planHash: string,
): unit => {
  validateGuideAssets(guideAssets)
  let rendered: array<option<path>> = []
  for index in 0 to Belt.Array.length(chunks) - 1 {
    let chunk = Belt.Array.getExn(chunks, index)
    let audio = chunk.kind == "chorus"
      ? await renderChorus(chunk, dry)
      : await renderDialogue(chunk, dry)
    ignore(Js.Array2.push(rendered, audio))
  }

  let sfx = segments->Belt.Array.keep(segment => segment.kind == "sfx")
  let availableGuides = ref(0)
  sfx->Belt.Array.forEach(segment => {
    let guide = guideSfxPath(segment)
    if exists(guide) {
      requireValidAudio(guide, "local guide SFX cue " ++ Belt.Int.toString(segment.sfxIdx))
      availableGuides := availableGuides.contents + 1
      if dry {
        Js.log("  local guide ready cue_" ++ pad3(segment.sfxIdx) ++ " -> " ++ pathString(guide))
      }
    } else if dry {
      Js.log("  local guide hook cue_" ++ pad3(segment.sfxIdx) ++ " -> " ++ pathString(guide))
    }
  })
  Js.log(
    "guide SFX: " ++ Belt.Int.toString(availableGuides.contents) ++ "/" ++
    Belt.Int.toString(Belt.Array.length(sfx)) ++
    " local files available; no SFX was generated by this renderer",
  )

  if dry {
    Js.log("V4 DRY run — zero provider calls; no lock, cache audio, output or manifest was created.")
  } else {
    validateGuideAssets(guideAssets)
    ensureDirPath(Path(cacheDir))
    if exists(Path(outputPath)) || exists(Path(manifestPath)) {
      fail("published V4 output or manifest already exists; refusing overwrite")
    }
    let parts: array<path> = []
    let timelineRows: array<Js.Json.t> = []
    let elapsed = ref(0.0)
    let previousVoiceScene = ref(-999)
    let previousWasVoice = ref(false)
    let titleCount = ref(0)
    let insertedSfx = ref(0)

    let add = (~kind: string, ~id: string, ~scene: int, ~path: path) => {
      ignore(Js.Array2.push(parts, path))
      let (row, duration) = timelineAudioRow(~kind, ~id, ~scene, ~path, ~start=elapsed.contents)
      ignore(Js.Array2.push(timelineRows, row))
      elapsed := elapsed.contents +. duration
    }
    let addGap = (ms: int, id: string, scene: int) => {
      let gap = silence(Millis(ms), Path(cacheDir))
      add(~kind="spacing", ~id, ~scene, ~path=gap)
    }

    let entries = assemblyEntries(segments, chunks)
    entries->Belt.Array.forEach(entry =>
      switch entry {
      | VoiceChunk(index) => {
          let chunk = Belt.Array.getExn(chunks, index)
          if previousWasVoice.contents {
            addGap(
              chunk.scene == previousVoiceScene.contents ? 250 : 900,
              "voice_gap_" ++ pad3(index),
              chunk.scene,
            )
          }
          switch Belt.Array.getExn(rendered, index) {
          | Some(path) => add(~kind=chunk.kind, ~id=chunk.id, ~scene=chunk.scene, ~path)
          | None => fail("missing rendered V4 voice chunk " ++ chunk.id)
          }
          previousVoiceScene := chunk.scene
          previousWasVoice := true
        }
      | SfxCue(segment) => {
          let guide = guideSfxPath(segment)
          requireValidAudio(guide, "assembly guide SFX cue " ++ Belt.Int.toString(segment.sfxIdx))
          add(
            ~kind="guide_sfx",
            ~id="cue_" ++ pad3(segment.sfxIdx),
            ~scene=segment.scene,
            ~path=guide,
          )
          insertedSfx := insertedSfx.contents + 1
          previousWasVoice := false
        }
      | TitleCue(_) => {
          if previousWasVoice.contents {
            addGap(500, "pre_title_gap", 1000)
          }
          add(
            ~kind="title_interlude",
            ~id="approved_title_first_15s",
            ~scene=1000,
            ~path=makeTitleExcerpt(),
          )
          addGap(500, "post_title_gap", 1000)
          titleCount := titleCount.contents + 1
          previousWasVoice := false
        }
      }
    )
    if titleCount.contents != 1 || insertedSfx.contents != expectedSfxCues {
      fail("V4 assembly did not insert exactly one title and all 22 guide SFX cues")
    }

    let scratch = tempDir("kuku-ep10-v4-master-")
    let candidate = Path(pathString(scratch) ++ "/EP10_AUDIO_FIRST_FULL_CAST_TABLE_READ_V4.mp3")
    let assembled = concatAudio(parts, candidate)
    requireValidAudio(assembled, "V4 assembled dialogue-and-guide-SFX master")
    let Seconds(total) = probeDuration(assembled)
    let audioHash = sha256File(assembled)
    let manifest = Js.Dict.empty()
    Js.Dict.set(manifest, "schema", Js.Json.string("kuku.audio_first.table_read.manifest.v4"))
    Js.Dict.set(manifest, "pipeline_version", Js.Json.string(pipelineVersion))
    Js.Dict.set(manifest, "plan", Js.Json.string(planPath))
    Js.Dict.set(manifest, "plan_sha256", Js.Json.string(planHash))
    Js.Dict.set(manifest, "audio", Js.Json.string(outputPath))
    Js.Dict.set(manifest, "audio_sha256", Js.Json.string(audioHash))
    Js.Dict.set(manifest, "duration_seconds", Js.Json.number(total))
    Js.Dict.set(manifest, "provider_billable_characters", Js.Json.number(Belt.Int.toFloat(providerBillableChars(chunks))))
    Js.Dict.set(manifest, "complete_audio_timeline", Js.Json.array(timelineRows))
    Js.Dict.set(manifest, "sfx_assembly_status", Js.Json.string("all 22 validated local guide SFX inserted in screenplay order; none generated by renderer"))
    Js.Dict.set(manifest, "available_local_guide_sfx", Js.Json.number(Belt.Int.toFloat(availableGuides.contents)))
    Js.Dict.set(manifest, "ordered_sfx_cues", Js.Json.array(sfx->Belt.Array.map(segmentJson)))
    let body = Js.Json.object_(manifest)->Js.Json.stringifyWithSpace(1)
    let manifestCandidate = Path(pathString(scratch) ++ "/EP10_AUDIO_FIRST_FULL_CAST_TABLE_READ_V4.manifest.json")
    writeText(manifestCandidate, body)
    if readText(manifestCandidate) != body {
      fail("V4 staged manifest did not round-trip exactly")
    }
    if exists(Path(outputPath)) || exists(Path(manifestPath)) {
      fail("V4 output appeared during assembly; refusing overwrite")
    }
    if !publishFileExclusive(assembled, Path(outputPath)) {
      fail("V4 output appeared during publication; refusing overwrite")
    }
    try {
      if !publishFileExclusive(manifestCandidate, Path(manifestPath)) {
        rollbackPublishedFile(~path=Path(outputPath), ~expectedSha256=audioHash, ~label="V4 output")
        fail("immutable V4 manifest appeared during pair publication; rolled back new audio")
      }
    } catch {
    | BackendError(message) => {
        rollbackPublishedFile(~path=Path(outputPath), ~expectedSha256=audioHash, ~label="V4 output")
        raise(BackendError(message))
      }
    | Js.Exn.Error(error) => {
        rollbackPublishedFile(~path=Path(outputPath), ~expectedSha256=audioHash, ~label="V4 output")
        raise(AudioFirst("V4 manifest publication failed: " ++ describeNodeError(error)))
      }
    }
    Js.log(
      "V4 AUDIO-FIRST DIALOGUE+GUIDE-SFX MASTER -> " ++ outputPath ++ " (" ++
      Js.Float.toFixedWithPrecision(total /. 60.0, ~digits=1) ++ " min)",
    )
    Js.log("V4 IMMUTABLE MANIFEST -> " ++ manifestPath)
  }
}

let renderWithActiveLease = async (
  segments: array<segment>,
  chunks: array<chunk>,
  guideAssets: array<guideAsset>,
  planHash: string,
  mode: string,
): unit => {
  let leaseBody = acquireActiveLease(planHash, mode)
  try {
    await renderAll(segments, chunks, guideAssets, false, planHash)
    releaseActiveLease(leaseBody)
  } catch {
  | AudioFirst(message) => {
      releaseActiveLease(leaseBody)
      raise(AudioFirst(message))
    }
  | BackendError(message) => {
      releaseActiveLease(leaseBody)
      raise(BackendError(message))
    }
  | Js.Exn.Error(error) => {
      releaseActiveLease(leaseBody)
      raise(AudioFirst("unexpected async failure while holding V4 lease: " ++ describeNodeError(error)))
    }
  }
}

let main = async () => {
  let dry = envDry == Some("1")
  let resume = envResume == Some("1")
  let segments = parseScreenplay()
  let chunks = chunkSegments(segments)
  let oversized = chunks->Belt.Array.keep(chunk => chunk.kind != "chorus" && chunk.chars > maxChunkChars)
  if Belt.Array.length(oversized) > 0 {
    fail("a V4 voice chunk exceeds " ++ Belt.Int.toString(maxChunkChars) ++ " characters")
  }
  let (guideAssets, missingGuides) = inspectGuideSfx(segments)
  let guidesComplete = Belt.Array.length(missingGuides) == 0 && Belt.Array.length(guideAssets) == expectedSfxCues
  let planBody = planJson(segments, chunks, guideAssets, missingGuides)->Js.Json.stringifyWithSpace(1)
  let planHash = sha256Text(planBody)
  if guidesComplete {
    writeImmutablePlan(planBody)
  } else {
    if exists(Path(planPath)) {
      fail("frozen V4 production plan exists but its guide asset set is no longer complete")
    }
    writeDraftPlan(planBody)
  }
  let dialogue = segments->Belt.Array.keep(segment => segment.kind == "dialogue" || segment.kind == "chorus")
  let sfx = segments->Belt.Array.keep(segment => segment.kind == "sfx")
  let auditions = segments->Belt.Array.keep(isPronunciationAudit)
  let directedChars = chunks->Belt.Array.reduce(0, (total, chunk) => total + chunk.chars)
  let missing = missingProviderRequests(chunks)
  Js.log(
    "V4 plan: " ++ Belt.Int.toString(Belt.Array.length(dialogue)) ++ " cast dialogue cues, " ++
    Belt.Int.toString(Belt.Array.length(sfx)) ++ " non-spoken SFX markers, " ++
    Belt.Int.toString(Belt.Array.length(chunks)) ++ " voice chunks, " ++
    Belt.Int.toString(Belt.Array.length(auditions)) ++ " production-used contextual ग auditions",
  )
  Js.log(
    "V4 provider requests: " ++ Belt.Int.toString(coldProviderRequests(chunks)) ++
    " on an empty V4 cache; " ++ Belt.Int.toString(missing) ++ " currently missing; sequential/no retry",
  )
  Js.log(
    "V4 characters: " ++ Belt.Int.toString(directedChars) ++ " directed once; " ++
    Belt.Int.toString(providerBillableChars(chunks)) ++ " provider-billable after chorus expansion",
  )
  Js.log(
    (guidesComplete ? "V4 IMMUTABLE PLAN -> " ++ planPath : "V4 DRAFT PLAN -> " ++ draftPlanPath) ++
    " sha256=" ++ planHash,
  )

  if !dry && (exists(Path(outputPath)) || exists(Path(manifestPath))) {
    fail("published V4 output or manifest already exists; refusing paid work and overwrite")
  }
  if !dry {
    /* Local effects are an input prerequisite, not something this paid path
       creates. Validate every one before acquiring or accepting a paid lock. */
    requireCompleteGuideSet(guideAssets, missingGuides)
    if !exists(Path(planPath)) || readText(Path(planPath)) != planBody {
      fail("V4 paid preflight requires the immutable plan bound to current guide bytes and durations")
    }
    if exists(Path(activeLeasePath)) {
      fail("V4 active lease already exists; refusing concurrent or stale provider work: " ++ activeLeasePath)
    }
  }
  if resume {
    validateResume(~planHash, ~currentMissing=missing)
  } else {
    if !dry && missing > 0 && !paidAllowed(dry) {
      fail("missing " ++ Belt.Int.toString(missing) ++ " paid V4 takes; production requires PAID=1")
    }
    if !dry && exists(Path(paidLockPath)) {
      fail("V4 paid-run lock already exists; use guarded PAID=1 RESUME=1 only for that interrupted run")
    }
    if !dry && missing > 0 {
      acquirePaidLock(planHash, missing)
    }
  }
  if dry {
    await renderAll(segments, chunks, guideAssets, true, planHash)
  } else {
    await renderWithActiveLease(
      segments,
      chunks,
      guideAssets,
      planHash,
      resume ? "resume" : "fresh",
    )
  }
}

let runMain = async () => {
  try await main() catch {
  | AudioFirst(message) => {
      Js.log("EP10 V4 AUDIO-FIRST FAILED: " ++ message)
      exit(1)
    }
  | BackendError(message) => {
      Js.log("EP10 V4 AUDIO-FIRST BACKEND FAILED: " ++ message)
      exit(1)
    }
  | Js.Exn.Error(error) => {
      Js.log("EP10 V4 AUDIO-FIRST ASYNC JS FAILED: " ++ describeNodeError(error))
      exit(1)
    }
  }
}

runMain()->ignore
