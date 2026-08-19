/* कुकु और अक्षर — Episode 10 full-cast ElevenLabs v3 table read.

   Hiral Ben, the locked सूत्रधार, reads headings, action and written sound
   cues. The locked cast reads dialogue. Hindi performance parentheticals are
   translated to Eleven v3 expression tags and are never spoken.

   Safe validation (zero provider calls):
     DRY=1 node src/Kuku_TableReadEp10.res.mjs

   Production (the only command that may make paid calls):
     PAID=1 node src/Kuku_TableReadEp10.res.mjs

   DRY=1 always wins over PAID=1. Without PAID=1, a missing audio cache fails
   closed. Cache keys include the exact voice, directed text and pipeline
   version. The final MP3 and manifest are published without overwrite. */

open Cinema_Backends

@val @scope(("process", "env")) external envDry: option<string> = "DRY"
@val @scope(("process", "env")) external envPaid: option<string> = "PAID"
@val @scope("process") external exit: int => unit = "exit"

exception TableRead(string)

let dir = "../stories/kuku/ep10prod"
let screenplay = "../stories/kuku/2026-08-18_EP10_ga_gaay_SPEC_SCREENPLAY.md"
let globalTagmap = "../stories/kuku/ep5prod/tagmap.json"
let localTagmap = dir ++ "/ep10_table_read_tags_v1.json"
let planPath = dir ++ "/EP10_FULL_CAST_TABLE_READ.plan.json"
let manifestPath = dir ++ "/EP10_FULL_CAST_TABLE_READ.manifest.json"
let outputPath = dir ++ "/EP10_FULL_CAST_TABLE_READ.mp3"
let paidLockPath = dir ++ "/EP10_FULL_CAST_TABLE_READ.PAID.lock"
let cacheDir = dir ++ "/table_read/cache"

let pipelineVersion = "kuku-ep10-table-read-v1"
let maxChunkChars = 1800
let expectedDialogueLines = 101
let parrotPitch = 1.15

type segment = {
  order: int,
  scene: int,
  dialogueIdx: int,
  kind: string,
  speaker: string,
  direction: string,
  tag: string,
  text: string,
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
  | "पाँचों बच्चे" => Some("CHORUS_FIVE")
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

let isSoundCue = (line: string): bool => Js.String2.startsWith(line, "(ध्वनि:")

type mimic = {setup: string, voice: string, text: string}

let parseMimic = (line: string): option<mimic> => {
  let cue = actionText(line)
  if !Js.String2.includes(cue, "हूबहू") {
    None
  } else {
    let colon = Js.String2.lastIndexOf(cue, ":")
    let a = Js.String2.indexOf(cue, "«")
    let b = Js.String2.lastIndexOf(cue, "»")
    if colon < 0 || a < 0 || b <= a {
      None
    } else {
      let setup = trim(Js.String2.slice(cue, ~from=Js.String2.length("ध्वनि:"), ~to_=colon)) ++ "।"
      let text = clean(Js.String2.slice(cue, ~from=a + 1, ~to_=b))
      let after = Js.String2.sliceToEnd(cue, ~from=Js.String2.indexOf(cue, "हूबहू") + 5)
      let name = trim(after)->Js.String2.split(" ")->Belt.Array.get(0)->Belt.Option.getWithDefault("")
      switch Kuku_Cast.mimicVoiceKey(name) {
      | Some(voice) => Some({setup, voice, text})
      | None => None
      }
    }
  }
}

let narratorTagFor = (scene: int): string =>
  switch scene {
  | 0 => "[narrating with wonder]"
  | 100 => "[mysterious] [tense]"
  | 1 | 2 | 3 | 4 | 5 => "[tense] [focused]"
  | 6 => "[warmly]"
  | 7 => "[storyteller, warm and unhurried]"
  | 8 => "[mysterious]"
  | _ => "[narrating]"
  }

let soundOnlyText = (name: string, direction: string): string => {
  let sound = clean(direction->Js.String2.replaceByRe(%re("/^ध्वनि:[ \\t]*/"), ""))
  name ++ " की " ++ sound ++ "।"
}

let parseScreenplay = (): array<segment> => {
  let maps = loadTagmaps()
  let segments: array<segment> = []
  let currentScene = ref(-1)
  let order = ref(0)
  let dialogueIdx = ref(0)
  let unresolved: array<string> = []
  let uncast: array<string> = []

  let push = (~scene: int, ~dialogueIdx: int=0, ~kind: string, ~speaker: string, ~direction: string="", ~tag: string, ~text: string) => {
    order := order.contents + 1
    let _ = Js.Array2.push(segments, {
      order: order.contents,
      scene,
      dialogueIdx,
      kind,
      speaker,
      direction,
      tag,
      text,
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
          if isSoundCue(line) {
            switch parseMimic(line) {
            | Some(m) => {
                push(~scene=currentScene.contents, ~kind="narration", ~speaker=Kuku_Cast.tableReadNarrator, ~tag=narratorTagFor(currentScene.contents), ~text=m.setup)
                push(~scene=currentScene.contents, ~kind="mimic", ~speaker=m.voice, ~tag="", ~text=m.text)
              }
            | None =>
              push(~scene=currentScene.contents, ~kind="narration", ~speaker=Kuku_Cast.tableReadNarrator, ~tag=narratorTagFor(currentScene.contents), ~text=actionText(line))
            }
          } else {
            push(~scene=currentScene.contents, ~kind="narration", ~speaker=Kuku_Cast.tableReadNarrator, ~tag=narratorTagFor(currentScene.contents), ~text=actionText(line))
          }
        } else {
          switch splitSpeaker(line) {
          | Some((name, rest)) =>
            switch splitParenthetical(rest) {
            | Some((direction, text)) if text == "" && Js.String2.startsWith(direction, "ध्वनि:") =>
              push(~scene=currentScene.contents, ~kind="narration", ~speaker=Kuku_Cast.tableReadNarrator, ~tag=narratorTagFor(currentScene.contents), ~text=soundOnlyText(name, direction))
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
  segments
}

let pad3 = (i: int): string =>
  i < 10 ? "00" ++ Belt.Int.toString(i) : i < 100 ? "0" ++ Belt.Int.toString(i) : Belt.Int.toString(i)

let directed = (segment: segment): string =>
  segment.tag == "" ? segment.text : segment.tag ++ " " ++ segment.text

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
    let special = segment.kind == "chorus" || segment.kind == "mimic"
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

let mimicSignature = (segment: segment): string =>
  voiceFor(segment.speaker) ++ "|" ++ segment.text ++ "|" ++ Js.Float.toString(parrotPitch) ++ "::parrot::" ++ pipelineVersion

let mimicCache = (chunk: chunk): path => {
  let segment = Belt.Array.getExn(chunk.segments, 0)
  Path(cacheDir ++ "/mimic_" ++ sha256Text(mimicSignature(segment)) ++ ".mp3")
}

let mimicRawCache = (chunk: chunk): path => {
  let segment = Belt.Array.getExn(chunk.segments, 0)
  Path(cacheDir ++ "/raw_mimic_" ++ sha256Text(mimicSignature(segment)) ++ ".mp3")
}

let cacheValid = (path: path): bool => exists(path) && fileSizeMb(path) *. 1.0e6 > 2000.0
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
    | "mimic" => cacheValid(mimicCache(chunk)) || cacheValid(mimicRawCache(chunk)) ? count : count + 1
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

let normalize = (~src: path, ~out: path, ~lufs: int): path => {
  let Path(source) = src
  let Path(output) = out
  ffmpeg([
    "-nostdin", "-loglevel", "error", "-y", "-i", source,
    "-af", "loudnorm=I=" ++ Belt.Int.toString(lufs) ++ ":TP=-1.5:LRA=11",
    "-c:a", "libmp3lame", "-q:a", "3", output,
  ])
  out
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
    let _ = writeBytes(rawCache, blob)
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
    let _ = writeBytes(rawCache, blob)
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
    let Path(output) = out
    let count = Belt.Int.toString(Belt.Array.length(parts))
    ffmpeg(Belt.Array.concatMany([
      ["-nostdin", "-loglevel", "error", "-y"],
      inputs,
      ["-filter_complex", "amix=inputs=" ++ count ++ ":duration=longest:normalize=1,loudnorm=I=-17:TP=-1.5:LRA=11", "-c:a", "libmp3lame", "-q:a", "3", output],
    ]))
    Js.log("  rendered " ++ chunk.id ++ " chorus")
    Some(out)
  }
}

let renderMimic = async (chunk: chunk, dry: bool): option<path> => {
  let out = mimicCache(chunk)
  let rawCache = mimicRawCache(chunk)
  let segment = Belt.Array.getExn(chunk.segments, 0)
  if cacheValid(out) {
    Js.log("  reuse " ++ chunk.id ++ " Tansen mimic")
    Some(out)
  } else if cacheValid(rawCache) && dry {
    Js.log("  would pitch cached raw " ++ chunk.id ++ " Tansen mimic")
    None
  } else if dry {
    Js.log("  would render " ++ chunk.id ++ " Tansen mimic")
    None
  } else {
    if !cacheValid(rawCache) && !paidAllowed(dry) {
      fail("paid Tansen mimic required for " ++ chunk.id ++ "; rerun with PAID=1")
    }
    if !cacheValid(rawCache) {
      let blob = await tts(~text=Text(segment.text), ~voice=VoiceId(voiceFor(segment.speaker)))
      let _ = writeBytes(rawCache, blob)
    }
    let Path(rawPath) = rawCache
    let probe = run(~cmd="ffprobe", ~args=["-v", "error", "-select_streams", "a:0", "-show_entries", "stream=sample_rate", "-of", "csv=p=0", rawPath])
    let sourceRate = Belt.Float.fromString(trim(probe.stdout))->Belt.Option.getWithDefault(44100.0)
    let shiftedRate = Belt.Float.toInt(sourceRate *. parrotPitch)
    let Path(source) = rawCache
    let Path(output) = out
    ffmpeg([
      "-nostdin", "-loglevel", "error", "-y", "-i", source,
      "-af", "asetrate=" ++ Belt.Int.toString(shiftedRate) ++ ",aresample=" ++ Belt.Float.toString(sourceRate) ++ ",atempo=" ++ Js.Float.toFixedWithPrecision(1.0 /. parrotPitch, ~digits=4) ++ ",loudnorm=I=-17:TP=-1.5:LRA=11",
      "-c:a", "libmp3lame", "-q:a", "3", output,
    ])
    Js.log("  rendered " ++ chunk.id ++ " Tansen mimic")
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
  Js.Json.object_(row)
}

let chunkInputHash = (chunk: chunk): string =>
  switch chunk.kind {
  | "chorus" => sha256Text(chorusSignature(Belt.Array.getExn(chunk.segments, 0)))
  | "mimic" => sha256Text(mimicSignature(Belt.Array.getExn(chunk.segments, 0)))
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
  Js.Dict.set(root, "schema", Js.Json.string("kuku.table_read.plan.v1"))
  Js.Dict.set(root, "pipeline_version", Js.Json.string(pipelineVersion))
  Js.Dict.set(root, "screenplay", Js.Json.string(screenplay))
  Js.Dict.set(root, "screenplay_sha256", Js.Json.string(sha256File(Path(screenplay))))
  Js.Dict.set(root, "global_tagmap_sha256", Js.Json.string(sha256File(Path(globalTagmap))))
  Js.Dict.set(root, "local_tagmap_sha256", Js.Json.string(sha256File(Path(localTagmap))))
  Js.Dict.set(root, "model_id", Js.Json.string("eleven_v3"))
  Js.Dict.set(root, "max_chunk_characters", Js.Json.number(Belt.Int.toFloat(maxChunkChars)))
  Js.Dict.set(root, "cast", Js.Json.object_(cast))
  Js.Dict.set(root, "segments", Js.Json.array(segments->Belt.Array.map(segmentJson)))
  Js.Dict.set(root, "chunks", Js.Json.array(chunkRows))
  Js.Dict.set(root, "cold_cache_provider_requests", Js.Json.number(Belt.Int.toFloat(coldProviderRequests(chunks))))
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

let acquirePaidLock = (planHash: string, missing: int): unit => {
  let body =
    "Episode 10 table-read paid-run lock.\n" ++
    "plan_sha256=" ++ planHash ++ "\n" ++
    "missing_provider_requests_at_start=" ++ Belt.Int.toString(missing) ++ "\n" ++
    "This persistent lock prevents an accidental duplicate paid run.\n"
  if !writeTextExclusive(Path(paidLockPath), body) {
    fail(
      "paid-run lock already exists at " ++ paidLockPath ++
      "; refusing possible duplicate ElevenLabs charges",
    )
  }
}

let renderAll = async (chunks: array<chunk>, dry: bool, planHash: string): unit => {
  ensureDirPath(Path(cacheDir))
  let tmp = tempDir("kuku-ep10-table-read-")
  let files: array<option<path>> = []
  for i in 0 to Belt.Array.length(chunks) - 1 {
    let chunk = Belt.Array.getExn(chunks, i)
    let rendered = switch chunk.kind {
    | "chorus" => await renderChorus(chunk, dry)
    | "mimic" => await renderMimic(chunk, dry)
    | _ => await renderDialogue(chunk, dry)
    }
    let _ = Js.Array2.push(files, rendered)
  }
  if dry {
    Js.log("DRY run — zero ElevenLabs calls; no audio was rendered or assembled.")
  } else {
    if exists(Path(outputPath)) || exists(Path(manifestPath)) {
      fail("published Episode 10 table read already exists; refusing overwrite")
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
    let tempOutput = Path(temp ++ "/EP10_FULL_CAST_TABLE_READ.mp3")
    let assembled = concatAudio(parts, tempOutput)
    let Seconds(total) = probeDuration(assembled)
    let audioHash = sha256File(assembled)
    if exists(Path(outputPath)) || exists(Path(manifestPath)) {
      fail("Episode 10 output appeared during assembly; refusing overwrite")
    }
    if !publishFileExclusive(assembled, Path(outputPath)) {
      fail("Episode 10 audio appeared during publication; refusing overwrite")
    }
    let root = Js.Dict.empty()
    Js.Dict.set(root, "schema", Js.Json.string("kuku.table_read.manifest.v1"))
    Js.Dict.set(root, "pipeline_version", Js.Json.string(pipelineVersion))
    Js.Dict.set(root, "plan", Js.Json.string(planPath))
    Js.Dict.set(root, "plan_sha256", Js.Json.string(planHash))
    Js.Dict.set(root, "audio", Js.Json.string(outputPath))
    Js.Dict.set(root, "audio_sha256", Js.Json.string(audioHash))
    Js.Dict.set(root, "duration_seconds", Js.Json.number(total))
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
  Js.log("PLAN -> " ++ planPath ++ " sha256=" ++ planHash)
  if !dry && (exists(Path(outputPath)) || exists(Path(manifestPath))) {
    fail("published Episode 10 table read already exists; refusing any paid work or overwrite")
  }
  if !dry && missing > 0 && !paidAllowed(dry) {
    fail("missing " ++ Belt.Int.toString(missing) ++ " paid takes; production requires PAID=1")
  }
  if !dry && missing > 0 {
    acquirePaidLock(planHash, missing)
  }
  await renderAll(chunks, dry, planHash)
}

let runMain = async () => {
  try await main() catch {
  | TableRead(message) => {
      Js.log("EP10 TABLE READ FAILED: " ++ message)
      exit(1)
    }
  | BackendError(message) => {
      Js.log("EP10 TABLE READ BACKEND FAILED: " ++ message)
      exit(1)
    }
  }
}

runMain()->ignore
