/* कुकु और अक्षर — EP9 full-cast audio table read.

   This is a listening copy of the SPEC screenplay, not production dialogue:
   Hiral Ben (the canonical सूत्रधार) reads scene headings and every action
   paragraph, while the locked cast reads the dialogue. Hindi performance
   parentheticals become saved Eleven v3 audio tags; they are never spoken.

   Normal turns use ElevenLabs Text to Dialogue so exchanges share context. The
   request chunks stay under 1,800 characters (the service recommends <=2,000).
   The one chorus is a real five-child mix. Tansen's final ब is Kuku's voice with
   the established 15% parrot pitch lift, never a new character voice.

   DRY=1 parses, validates, and writes the plan without making a paid call.

   Run from studio/:
     DRY=1 node src/Kuku_TableReadEp9.res.mjs
     node src/Kuku_TableReadEp9.res.mjs */

open Cinema_Backends

@val @scope(("process", "env")) external envDry: option<string> = "DRY"
@val @scope("process") external exit: int => unit = "exit"

exception TableRead(string)

let dir = "../stories/kuku/ep9prod"
let screenplay = "../stories/kuku/2026-08-11_EP9_ba_bada_SPEC_SCREENPLAY.md"
let globalTagmap = "../stories/kuku/ep5prod/tagmap.json"
let localTagmap = dir ++ "/ep9_table_read_tags_v2_dream.json"
let planPath = dir ++ "/ep9_table_read_plan_v2_dream.json"
let renderPath = dir ++ "/EP9_FULL_CAST_TABLE_READ_V2_DREAM.manifest.json"
let outputPath = dir ++ "/EP9_FULL_CAST_TABLE_READ_V2_DREAM.mp3"
let cacheDir = dir ++ "/table_read/cache"

let maxChunkChars = 1800
let parrotPitch = 1.15
let audioPipelineVersion = "ep9-table-read-v2"

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

type chunk = {id: string, scene: int, kind: string, segments: array<segment>, chars: int}

type tagmaps = {
  globalTags: Js.Dict.t<string>,
  globalVisual: array<string>,
  localTags: Js.Dict.t<string>,
  lineTags: Js.Dict.t<string>,
}

let trim = Js.String2.trim
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
  let global = Js.Json.parseExn(readText(Path(globalTagmap)))
  let local = Js.Json.parseExn(readText(Path(localTagmap)))
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
  | Some(t) => Some(t)
  | None =>
    switch Js.Dict.get(maps.localTags, direction) {
    | Some(t) => Some(t)
    | None =>
      switch Js.Dict.get(maps.globalTags, direction) {
      | Some(t) => Some(t)
      | None if Belt.Array.some(maps.globalVisual, v => v == direction) => Some("")
      | None => {
          let pieces =
            Js.String2.split(direction, ",")
            ->Belt.Array.map(trim)
            ->Belt.Array.keepMap(p =>
              switch Js.Dict.get(maps.localTags, p) {
              | Some(t) => Some(t)
              | None => Js.Dict.get(maps.globalTags, p)
              }
            )
          Belt.Array.length(pieces) > 0 ? Some(Js.Array2.joinWith(pieces, " ")) : None
        }
      }
    }
  }
}

let sceneNumber = (line: string): option<int> => {
  let bare = trim(line->Js.String2.replaceByRe(%re("/^#+[ \t]*/"), ""))
  if Js.String2.startsWith(bare, "दृश्य 0-अ") {
    /* Keep the dream's quiet wake-up landing out of the battle-performance
       chunk while retaining an integer scene key for the audio plan. */
    Some(100)
  } else if Js.String2.startsWith(bare, "दृश्य") {
    let rest = trim(Js.String2.sliceToEnd(bare, ~from=Js.String2.length("दृश्य")))
    let digits = Js.Array2.joinWith(
      Js.String2.split(rest, "")->Belt.Array.keep(c => c >= "0" && c <= "9"),
      "",
    )
    Belt.Int.fromString(digits)
  } else {
    None
  }
}

let stripHeading = (line: string): string =>
  trim(line->Js.String2.replaceByRe(%re("/^#+[ \t]*/"), ""))

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
  | "नगर-रक्षक" => Some("NAGAR_RAKSHAK")
  | "सब" | "सब बच्चे" => Some("CHORUS_ALL")
  | _ => None
  }

let splitSpeaker = (line: string): option<(string, string)> =>
  switch Js.String2.indexOf(line, ":") {
  | -1 => None
  | i => {
      let name = trim(Js.String2.slice(line, ~from=0, ~to_=i))
      let rest = trim(Js.String2.sliceToEnd(line, ~from=i + 1))
      Js.String2.length(name) > 0 && Js.String2.length(name) <= 12 ? Some((name, rest)) : None
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
        trim(Js.String2.sliceToEnd(rest, ~from=i + 1)),
      ))
    }
  }

let isAction = (line: string): bool =>
  Js.String2.startsWith(line, "(") && Js.String2.endsWith(line, ")")

let actionText = (line: string): string =>
  trim(
    Js.String2.slice(line, ~from=1, ~to_=Js.String2.length(line) - 1)
    ->Js.String2.replaceByRe(%re("/`/g"), ""),
  )

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
      let setupRaw = trim(Js.String2.slice(cue, ~from=Js.String2.length("ध्वनि:"), ~to_=colon))
      let spoken = trim(Js.String2.slice(cue, ~from=a + 1, ~to_=b))
      let after = Js.String2.sliceToEnd(cue, ~from=Js.String2.indexOf(cue, "हूबहू") + 5)
      let name =
        Js.String2.split(trim(after), " ")
        ->Belt.Array.get(0)
        ->Belt.Option.getWithDefault("")
      switch Kuku_Cast.mimicVoiceKey(name) {
      | Some(voice) => Some({setup: setupRaw ++ "।", voice, text: spoken})
      | None => None
      }
    }
  }
}

let directed = (s: segment): string => s.tag == "" ? s.text : s.tag ++ " " ++ s.text

let hasAny = (text: string, needles: array<string>): bool =>
  Belt.Array.some(needles, needle => Js.String2.includes(text, needle))

let narratorTagFor = (~scene: int, ~text: string): string =>
  if scene == 0 {
    if hasAny(text, [
      "एक विशाल सिंदूरी ड्रैगन", "उसके गले में लाल-सुनहरी चमक",
      "पहली बार आग फूँकती है", "अपनी ही आग को देखकर",
      "एक विशाल गहरा-नीला ड्रैगन", "दो और विशाल ड्रैगन साथ आते हैं",
      "कैस्टर उड़ते-उड़ते छोटा", "एक विशाल, ठोस, सुनहरा क",
      "विशाल कुकु उड़ता हुआ", "पाँचों एक साथ आगे उड़ते हैं",
    ]) {
      "[narrating with wonder]"
    } else if hasAny(text, [
      "लेडा दूर से टूटे बुर्ज", "लेडा बाहर से उसकी सही जगह",
      "कैस्टर कुंडी तक पहुँचता", "वह दो को छोड़कर नदी से उठती",
      "वैस्पर छिपी धारा के किनारे", "वह वैस्पर के चुने रास्ते",
    ]) {
      "[focused]"
    } else if hasAny(text, ["कड़ाक!", "खट!"]) {
      "[sharply]"
    } else if hasAny(text, [
      "फ्यूरिया की मुस्कान गायब", "बुर्ज का आख़िरी साबुत हिस्सा",
      "आख़िरी क्षण में हमलावर", "दूर बादलों में दर्जनों काले पंख",
      "उनके पीछे एक ऐसी परछाईं",
    ]) {
      "[serious] [tense]"
    } else {
      "[tense]"
    }
  } else if scene == 100 && Js.String2.includes(text, "फ्यूरिया उसी साँस के साथ जाग") {
    "[alarmed]"
  } else {
    switch scene {
    | 100 => "[softly]"
    | 1 => "[mysterious]"
    | 2 | 3 | 4 => "[storyteller, warm and unhurried]"
    | 5 | 6 | 10 => "[narrating with wonder]"
    | 7 | 8 => "[tense]"
    | 9 => "[calm]"
    | _ => "[narrating]"
    }
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

  readText(Path(screenplay))
  ->Js.String2.split("\n")
  ->Belt.Array.forEach(raw => {
    let line = trim(raw)
    if line != "" {
      switch sceneNumber(line) {
      | Some(scene) => {
          currentScene := scene
          push(
            ~scene,
            ~kind="narration",
            ~speaker=Kuku_Cast.tableReadNarrator,
            ~tag="[announcing]",
            ~text=stripHeading(line),
          )
        }
      | None if currentScene.contents >= 0 =>
        if Js.String2.startsWith(line, "## शीर्षक-गीत") {
          /* A table-read placeholder, not an invented song. The artificial scene
             id gives it a clean pause on both sides. */
          push(
            ~scene=1000,
            ~kind="narration",
            ~speaker=Kuku_Cast.tableReadNarrator,
            ~tag="[announcing]",
            ~text="शीर्षक गीत।",
          )
        } else if line == "---" || Js.String2.startsWith(line, "#") {
          ()
        } else if isAction(line) {
          if isSoundCue(line) {
            switch parseMimic(line) {
            | Some(m) => {
                push(
                  ~scene=currentScene.contents,
                  ~kind="narration",
                  ~speaker=Kuku_Cast.tableReadNarrator,
                  ~tag=narratorTagFor(~scene=currentScene.contents, ~text=m.setup),
                  ~text=m.setup,
                )
                push(
                  ~scene=currentScene.contents,
                  ~dialogueIdx=dialogueIdx.contents,
                  ~kind="mimic",
                  ~speaker=m.voice,
                  ~tag="",
                  ~text=m.text,
                )
              }
            | None =>
              push(
                ~scene=currentScene.contents,
                ~kind="narration",
                ~speaker=Kuku_Cast.tableReadNarrator,
                ~tag=narratorTagFor(~scene=currentScene.contents, ~text=actionText(line)),
                ~text=actionText(line),
              )
            }
          } else {
            push(
              ~scene=currentScene.contents,
              ~kind="narration",
              ~speaker=Kuku_Cast.tableReadNarrator,
              ~tag=narratorTagFor(~scene=currentScene.contents, ~text=actionText(line)),
              ~text=actionText(line),
            )
          }
        } else {
          switch splitSpeaker(line) {
          | Some((name, rest)) =>
            switch (speakerKey(name), splitParenthetical(rest)) {
            | (Some(speaker), Some((direction, text))) => {
                dialogueIdx := dialogueIdx.contents + 1
                switch tagFor(maps, dialogueIdx.contents, direction) {
                | Some(tag) =>
                  push(
                    ~scene=currentScene.contents,
                    ~dialogueIdx=dialogueIdx.contents,
                    ~kind=speaker == "CHORUS_ALL" ? "chorus" : "dialogue",
                    ~speaker,
                    ~direction,
                    ~tag,
                    ~text,
                  )
                | None => {
                    let _ = Js.Array2.push(
                      unresolved,
                      Belt.Int.toString(dialogueIdx.contents) ++ " [" ++ direction ++ "] " ++ text,
                    )
                  }
                }
              }
            | (None, _) => {
                let _ = Js.Array2.push(uncast, name)
              }
            | (_, None) => {
                let _ = Js.Array2.push(unresolved, "missing parenthetical: " ++ line)
              }
            }
          | None => ()
          }
        }
      | None => ()
      }
    }
  })

  if Belt.Array.length(uncast) > 0 {
    raise(TableRead("uncast speakers: " ++ Js.Array2.joinWith(uncast, ", ")))
  }
  if Belt.Array.length(unresolved) > 0 {
    unresolved->Belt.Array.forEach(x => Js.log("UNRESOLVED TAG: " ++ x))
    raise(TableRead(Belt.Int.toString(Belt.Array.length(unresolved)) ++ " unresolved performance directions"))
  }
  if dialogueIdx.contents != 154 {
    raise(TableRead("expected 154 dialogue lines, parsed " ++ Belt.Int.toString(dialogueIdx.contents)))
  }
  segments
}

let pad3 = (i: int): string =>
  i < 10 ? "00" ++ Belt.Int.toString(i) : i < 100 ? "0" ++ Belt.Int.toString(i) : Belt.Int.toString(i)

let chunkSegments = (segments: array<segment>): array<chunk> => {
  let chunks: array<chunk> = []
  let pending: ref<array<segment>> = ref([])
  let pendingScene = ref(-1)
  let pendingChars = ref(0)

  let flush = () => {
    if Belt.Array.length(pending.contents) > 0 {
      let i = Belt.Array.length(chunks)
      let _ = Js.Array2.push(chunks, {
        id: "chunk_" ++ pad3(i),
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

  segments->Belt.Array.forEach(s => {
    let special = s.kind == "chorus" || s.kind == "mimic"
    let n = Js.String2.length(directed(s))
    if special {
      flush()
      let i = Belt.Array.length(chunks)
      let _ = Js.Array2.push(chunks, {
        id: "chunk_" ++ pad3(i),
        scene: s.scene,
        kind: s.kind,
        segments: [s],
        chars: n,
      })
    } else {
      if (
        Belt.Array.length(pending.contents) > 0 &&
        (pendingScene.contents != s.scene || pendingChars.contents + n > maxChunkChars)
      ) {
        flush()
      }
      if Belt.Array.length(pending.contents) == 0 {
        pendingScene := s.scene
      }
      pending := Belt.Array.concat(pending.contents, [s])
      pendingChars := pendingChars.contents + n
    }
  })
  flush()
  chunks
}

let voiceFor = (speaker: string): string =>
  switch Kuku_Cast.voiceOf(speaker) {
  | Some(v) => v
  | None => raise(TableRead("no locked voice for " ++ speaker))
  }

let segmentJson = (s: segment): Js.Json.t => {
  let o = Js.Dict.empty()
  Js.Dict.set(o, "order", Js.Json.number(Belt.Int.toFloat(s.order)))
  Js.Dict.set(o, "scene", Js.Json.number(Belt.Int.toFloat(s.scene)))
  Js.Dict.set(o, "dialogue_idx", Js.Json.number(Belt.Int.toFloat(s.dialogueIdx)))
  Js.Dict.set(o, "kind", Js.Json.string(s.kind))
  Js.Dict.set(o, "speaker", Js.Json.string(s.speaker))
  Js.Dict.set(o, "direction", Js.Json.string(s.direction))
  Js.Dict.set(o, "tag", Js.Json.string(s.tag))
  Js.Dict.set(o, "text", Js.Json.string(s.text))
  Js.Json.object_(o)
}

let writePlan = (segments: array<segment>, chunks: array<chunk>): unit => {
  let cast = Js.Dict.empty()
  [
    "SUTRADHAR", "CHEEL", "RISHI", "DADI", "KUKU", "FYURIA", "VESPER", "CASTOR", "LEDA",
    "NAGAR_RAKSHAK",
  ]->Belt.Array.forEach(who => Js.Dict.set(cast, who, Js.Json.string(voiceFor(who))))
  let chunkJson = chunks->Belt.Array.map(c => {
    let o = Js.Dict.empty()
    Js.Dict.set(o, "id", Js.Json.string(c.id))
    Js.Dict.set(o, "scene", Js.Json.number(Belt.Int.toFloat(c.scene)))
    Js.Dict.set(o, "kind", Js.Json.string(c.kind))
    Js.Dict.set(o, "characters", Js.Json.number(Belt.Int.toFloat(c.chars)))
    Js.Dict.set(o, "segment_orders", Js.Json.array(c.segments->Belt.Array.map(s => Js.Json.number(Belt.Int.toFloat(s.order)))))
    Js.Json.object_(o)
  })
  let root = Js.Dict.empty()
  Js.Dict.set(root, "screenplay", Js.Json.string(screenplay))
  Js.Dict.set(root, "model_id", Js.Json.string("eleven_v3"))
  Js.Dict.set(root, "max_chunk_characters", Js.Json.number(Belt.Int.toFloat(maxChunkChars)))
  Js.Dict.set(root, "cast", Js.Json.object_(cast))
  Js.Dict.set(root, "segments", Js.Json.array(segments->Belt.Array.map(segmentJson)))
  Js.Dict.set(root, "chunks", Js.Json.array(chunkJson))
  writeText(Path(planPath), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1))
}

let normalize = (~src: path, ~out: path, ~lufs: int): path => {
  let Path(s) = src
  let Path(o) = out
  ffmpeg([
    "-nostdin", "-loglevel", "error", "-y", "-i", s,
    "-af", "loudnorm=I=" ++ Belt.Int.toString(lufs) ++ ":TP=-1.5:LRA=11",
    "-c:a", "libmp3lame", "-q:a", "3", o,
  ])
  out
}

let renderDialogue = async (c: chunk, dry: bool, tmp: path): option<path> => {
  let inputs = c.segments->Belt.Array.map(s => (
    Text(directed(s)),
    VoiceId(voiceFor(s.speaker)),
  ))
  let uniqueVoices = Js.Dict.empty()
  inputs->Belt.Array.forEach(((_, VoiceId(v))) => Js.Dict.set(uniqueVoices, v, true))
  if Belt.Array.length(Js.Dict.keys(uniqueVoices)) > 10 {
    raise(TableRead(c.id ++ " exceeds ElevenLabs' ten-voice request limit"))
  }
  let signature =
    inputs
    ->Belt.Array.map(((Text(t), VoiceId(v))) => v ++ "|" ++ t)
    ->Js.Array2.joinWith("\n") ++ "::eleven_v3::dialogue::" ++ audioPipelineVersion
  let out = Path(cacheDir ++ "/dialogue_" ++ sha256Text(signature) ++ ".mp3")
  if exists(out) && fileSizeMb(out) *. 1.0e6 > 2000.0 {
    Js.log("  reuse " ++ c.id ++ " dialogue")
    Some(out)
  } else if dry {
    Js.log("  would render " ++ c.id ++ " dialogue " ++ Belt.Int.toString(c.chars) ++ " chars")
    None
  } else {
    let raw = {
      let Path(t) = tmp
      Path(t ++ "/" ++ c.id ++ "_dialogue_raw.mp3")
    }
    let blob = await dialogue(inputs)
    let _ = writeBytes(raw, blob)
    let _ = normalize(~src=raw, ~out, ~lufs=-18)
    Js.log("  rendered " ++ c.id ++ " dialogue")
    Some(out)
  }
}

let renderSingle = async (~speaker: string, ~text: string, ~label: string, ~dry: bool, ~tmp: path): option<path> => {
  let voice = voiceFor(speaker)
  let sig_ = voice ++ "|" ++ text ++ "::eleven_v3::tts::" ++ audioPipelineVersion
  let out = Path(cacheDir ++ "/single_" ++ sha256Text(sig_) ++ ".mp3")
  if exists(out) && fileSizeMb(out) *. 1.0e6 > 2000.0 {
    Some(out)
  } else if dry {
    Js.log("    would render " ++ label)
    None
  } else {
    let Path(t) = tmp
    let raw = Path(t ++ "/single_" ++ sha256Text(sig_) ++ "_raw.mp3")
    let blob = await tts(~text=Text(text), ~voice=VoiceId(voice))
    let _ = writeBytes(raw, blob)
    let _ = normalize(~src=raw, ~out, ~lufs=-17)
    Some(out)
  }
}

let renderChorus = async (c: chunk, dry: bool, tmp: path): option<path> => {
  let s = Belt.Array.getExn(c.segments, 0)
  let members = Kuku_Cast.chorusMembersFor(dir)
  let text = directed(s)
  let signature =
    members->Belt.Array.map(w => voiceFor(w))->Js.Array2.joinWith("|") ++ "|" ++ text ++
    "::chorus::" ++ audioPipelineVersion
  let out = Path(cacheDir ++ "/chorus_" ++ sha256Text(signature) ++ ".mp3")
  if exists(out) && fileSizeMb(out) *. 1.0e6 > 2000.0 {
    Js.log("  reuse " ++ c.id ++ " five-child chorus")
    Some(out)
  } else if dry {
    Js.log("  would render " ++ c.id ++ " five-child chorus")
    for i in 0 to Belt.Array.length(members) - 1 {
      switch Belt.Array.get(members, i) {
      | Some(w) => ignore(await renderSingle(~speaker=w, ~text, ~label="chorus/" ++ w, ~dry, ~tmp))
      | None => ()
      }
    }
    None
  } else {
    let parts: array<path> = []
    for i in 0 to Belt.Array.length(members) - 1 {
      switch Belt.Array.get(members, i) {
      | Some(w) =>
        switch await renderSingle(~speaker=w, ~text, ~label="chorus/" ++ w, ~dry, ~tmp) {
        | Some(p) => {let _ = Js.Array2.push(parts, p)}
        | None => ()
        }
      | None => ()
      }
    }
    if Belt.Array.length(parts) != 5 {
      raise(TableRead("chorus needs five rendered voices"))
    }
    let inputs = parts->Belt.Array.map(p => {let Path(x) = p; ["-i", x]})->Belt.Array.concatMany
    let Path(o) = out
    ffmpeg(Belt.Array.concatMany([
      ["-nostdin", "-loglevel", "error", "-y"],
      inputs,
      [
        "-filter_complex",
        "amix=inputs=5:duration=longest:normalize=1,loudnorm=I=-17:TP=-1.5:LRA=11",
        "-c:a", "libmp3lame", "-q:a", "3", o,
      ],
    ]))
    Js.log("  rendered " ++ c.id ++ " five-child chorus")
    Some(out)
  }
}

let renderMimic = async (c: chunk, dry: bool, tmp: path): option<path> => {
  let s = Belt.Array.getExn(c.segments, 0)
  let voice = voiceFor(s.speaker)
  let signature =
    voice ++ "|" ++ s.text ++ "|" ++ Js.Float.toString(parrotPitch) ++ "::parrot::" ++
    audioPipelineVersion
  let out = Path(cacheDir ++ "/mimic_" ++ sha256Text(signature) ++ ".mp3")
  if exists(out) && fileSizeMb(out) *. 1.0e6 > 2000.0 {
    Js.log("  reuse " ++ c.id ++ " Tansen as " ++ s.speaker)
    Some(out)
  } else if dry {
    Js.log("  would render " ++ c.id ++ " Tansen as " ++ s.speaker)
    None
  } else {
    let Path(t) = tmp
    let raw = Path(t ++ "/" ++ c.id ++ "_mimic_raw.mp3")
    let blob = await tts(~text=Text(s.text), ~voice=VoiceId(voice))
    let _ = writeBytes(raw, blob)
    let probe = run(
      ~cmd="ffprobe",
      ~args=[
        "-v", "error", "-select_streams", "a:0", "-show_entries", "stream=sample_rate",
        "-of", "csv=p=0", t ++ "/" ++ c.id ++ "_mimic_raw.mp3",
      ],
    )
    let srcRate =
      Belt.Float.fromString(trim(probe.stdout))->Belt.Option.getWithDefault(44100.0)
    let rate = Belt.Float.toInt(srcRate *. parrotPitch)
    let Path(r) = raw
    let Path(o) = out
    ffmpeg([
      "-nostdin", "-loglevel", "error", "-y", "-i", r,
      "-af",
      "asetrate=" ++ Belt.Int.toString(rate) ++
      ",aresample=" ++ Belt.Float.toString(srcRate) ++
      ",atempo=" ++ Js.Float.toFixedWithPrecision(1.0 /. parrotPitch, ~digits=4) ++
      ",loudnorm=I=-17:TP=-1.5:LRA=11",
      "-c:a", "libmp3lame", "-q:a", "3", o,
    ])
    let Seconds(before) = probeDuration(raw)
    let Seconds(after) = probeDuration(out)
    let slack = Js.Math.max_float(0.05, before *. 0.02)
    if Js.Math.abs_float(after -. before) > slack {
      raise(TableRead(
        "Tansen pitch changed duration: " ++
        Js.Float.toFixedWithPrecision(before, ~digits=3) ++ " -> " ++
        Js.Float.toFixedWithPrecision(after, ~digits=3),
      ))
    }
    Js.log("  rendered " ++ c.id ++ " Tansen as " ++ s.speaker)
    Some(out)
  }
}

let renderAll = async (chunks: array<chunk>, dry: bool): unit => {
  ensureDirPath(Path(cacheDir))
  let tmp = tempDir("kuku-ep9-table-read-")
  let files: array<option<path>> = []
  for i in 0 to Belt.Array.length(chunks) - 1 {
    let c = Belt.Array.getExn(chunks, i)
    let rendered = switch c.kind {
    | "chorus" => await renderChorus(c, dry, tmp)
    | "mimic" => await renderMimic(c, dry, tmp)
    | _ => await renderDialogue(c, dry, tmp)
    }
    let _ = Js.Array2.push(files, rendered)
  }
  if dry {
    Js.log("DRY run — no ElevenLabs call was made.")
  } else {
    let parts: array<path> = []
    let renderedRows: array<Js.Json.t> = []
    let previousScene = ref(-999)
    for i in 0 to Belt.Array.length(chunks) - 1 {
      let c = Belt.Array.getExn(chunks, i)
      switch Belt.Array.getExn(files, i) {
      | Some(p) => {
          if Belt.Array.length(parts) > 0 {
            let gap = c.scene == previousScene.contents ? 300 : 1200
            let _ = Js.Array2.push(parts, silence(Millis(gap), Path(cacheDir)))
          }
          let _ = Js.Array2.push(parts, p)
          previousScene := c.scene
          let Seconds(d) = probeDuration(p)
          let Path(file) = p
          let row = Js.Dict.empty()
          Js.Dict.set(row, "id", Js.Json.string(c.id))
          Js.Dict.set(row, "scene", Js.Json.number(Belt.Int.toFloat(c.scene)))
          Js.Dict.set(row, "kind", Js.Json.string(c.kind))
          Js.Dict.set(row, "path", Js.Json.string(file))
          Js.Dict.set(row, "duration_seconds", Js.Json.number(d))
          let _ = Js.Array2.push(renderedRows, Js.Json.object_(row))
        }
      | None => raise(TableRead("missing rendered chunk " ++ c.id))
      }
    }
    let out = concatAudio(parts, Path(outputPath))
    let Seconds(total) = probeDuration(out)
    let manifest = Js.Dict.empty()
    Js.Dict.set(manifest, "audio", Js.Json.string(outputPath))
    Js.Dict.set(manifest, "duration_seconds", Js.Json.number(total))
    Js.Dict.set(manifest, "chunks", Js.Json.array(renderedRows))
    writeText(Path(renderPath), Js.Json.stringifyWithSpace(Js.Json.object_(manifest), 1))
    Js.log(
      "FULL CAST TABLE READ -> " ++ outputPath ++ " (" ++
      Js.Float.toFixedWithPrecision(total /. 60.0, ~digits=1) ++ " min)",
    )
  }
}

let main = async () => {
  let dry = envDry == Some("1")
  let segments = parseScreenplay()
  let chunks = chunkSegments(segments)
  writePlan(segments, chunks)
  let dialogueLines = segments->Belt.Array.keep(s => s.kind == "dialogue" || s.kind == "chorus")
  let actionLines = segments->Belt.Array.keep(s => s.kind == "narration")
  let totalChars = chunks->Belt.Array.reduce(0, (n, c) => n + c.chars)
  Js.log(
    "plan: " ++ Belt.Int.toString(Belt.Array.length(dialogueLines)) ++ " dialogue lines, " ++
    Belt.Int.toString(Belt.Array.length(actionLines)) ++ " narrated headings/actions, " ++
    Belt.Int.toString(Belt.Array.length(chunks)) ++ " chunks, " ++
    Belt.Int.toString(totalChars) ++ " directed characters",
  )
  let tooLarge = chunks->Belt.Array.keep(c => c.kind == "dialogue" && c.chars > maxChunkChars)
  if Belt.Array.length(tooLarge) > 0 {
    raise(TableRead("a dialogue chunk exceeds " ++ Belt.Int.toString(maxChunkChars) ++ " characters"))
  }
  await renderAll(chunks, dry)
}

main()
->Js.Promise2.catch(err => {
  Js.log2("EP9 TABLE READ FAILED:", err)
  exit(1)
  Js.Promise.resolve()
})
->ignore
