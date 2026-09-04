/* Frosya and Vasya — Episode 2 full-cast Russian table read, v3 screenplay.

   The bilingual spec's Russian layer is spoken. Action and sound-description
   lines are read by the narrator; SFX can be mixed later without rerendering
   the paid spoken master. Papa uses the 2026-08-16 Nester recast, never the
   superseded Anton voice. Mama remains Olga by the author's direction for this
   review read. The root creature and giant boy voices are explicitly
   provisional and do not establish series casting canon.

   Mama and Papa are never placed in the same ElevenLabs dialogue request. Vasya's
   transformed forms always retain Vasya's voice. The output records block-level
   timings so the episode can later be serialized into 3–5 minute installments.

   DRY=1 parses, validates, and writes the plan without making a paid call.

   Run from studio/:
     DRY=1 node src/Drakosha_Ep2RussianTableReadV3.res.mjs
     PAID=1 node src/Drakosha_Ep2RussianTableReadV3.res.mjs */

open Cinema_Backends

@val @scope(("process", "env")) external envDry: option<string> = "DRY"
@val @scope(("process", "env")) external envPaid: option<string> = "PAID"
@val @scope("process") external exit: int => unit = "exit"

exception TableRead(string)

let dir = "../stories/drakosha/audio/ep2_table_read_ru_v3"
let screenplay = "../stories/drakosha/2026-08-30_EP2_samyi-krutoi-nomer_SPEC_v2_numbered_bilingual.md"
let planPath = dir ++ "/ep2_table_read_ru_v3_plan.json"
let renderPath = dir ++ "/EP2_RUSSIAN_FULL_CAST_V3.manifest.json"
let outputPath = dir ++ "/EP2_RUSSIAN_FULL_CAST_V3.mp3"
let cacheDir = dir ++ "/cache"

let maxChunkChars = 1800
let maxChunkSegments = 20
let audioPipelineVersion = "drakosha-ep2-russian-table-read-v3"

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
  chars: int,
  parentVoice: string,
}

type castMember = {role: string, voice: string, voiceId: string, status: string}

let cast: array<castMember> = [
  {
    role: "NARRATOR",
    voice: "Anna Zub - Warm Multilingual Voice",
    voiceId: "deqzqEZ3ngCdcOl0jF1F",
    status: "author-directed previous Russian table-read narrator",
  },
  {
    role: "FROSYA",
    voice: "Ekaterina - Professional Female Russian",
    voiceId: "GN4wbsbejSnGSa1AzjH5",
    status: "approved Russian cast",
  },
  {
    role: "VASYA",
    voice: "Leonid - Warm and Calm Russian",
    voiceId: "bg9LrEYQkRYwqkxA8VOy",
    status: "approved Russian cast",
  },
  {
    role: "MAMA",
    voice: "Olga - Elegant Russian Voice",
    voiceId: "jF2jkOwefhvnRzZHn0sl",
    status: "author-directed existing Mama voice for this review read",
  },
  {
    role: "PAPA",
    voice: "Nester Surovy - Gravely yet Refined",
    voiceId: "pM78bgjPVk0JXtaEnFoj",
    status: "approved Russian recast 2026-08-16; supersedes Anton",
  },
  {
    role: "ROOT_CREATURE",
    voice: "Maxim - Deep Russian Narrator",
    voiceId: "gMIlPNegT3C1SdNBp6rW",
    status: "provisional Russian table-read voice; not series canon",
  },
  {
    role: "GIANT_BOY",
    voice: "Denis - Russian Narrator",
    voiceId: "76rT6drChOHgGsscaHMJ",
    status: "provisional Russian giant-boy table-read voice; not series canon",
  },
  {
    role: "MUSYA",
    voice: "Ekaterina - Professional Female Russian",
    voiceId: "GN4wbsbejSnGSa1AzjH5",
    status: "provisional one-syllable baby murmur using Frosya source voice",
  },
]

let trim = Js.String2.trim

let idFrom = (s: string): option<string> => {
  let i = Js.String2.indexOf(s, "E2V2-")
  i >= 0 && Js.String2.length(s) >= i + 8
    ? Some(Js.String2.slice(s, ~from=i, ~to_=i + 8))
    : None
}

let idNumber = (id: string): int =>
  Js.String2.sliceToEnd(id, ~from=5)->Belt.Int.fromString->Belt.Option.getWithDefault(-1)

let includedBlock = (id: string): bool => {
  let n = idNumber(id)
  n == 1 || (n >= 4 && n <= 232)
}

let sceneForHeading = (id: string): option<string> =>
  switch id {
  | "E2V2-001" => Some("title")
  | "E2V2-004" => Some("scene_01")
  | "E2V2-049" => Some("scene_02")
  | "E2V2-057" => Some("scene_03")
  | "E2V2-067" => Some("scene_04")
  | "E2V2-100" => Some("scene_05")
  | "E2V2-116" => Some("scene_06")
  | "E2V2-136" => Some("scene_07")
  | "E2V2-145" => Some("scene_08")
  | "E2V2-163" => Some("scene_09")
  | "E2V2-180" => Some("scene_10")
  | "E2V2-206" => Some("scene_11")
  | "E2V2-226" => Some("scene_12")
  | _ => None
  }

let stripHtml = (s: string): string =>
  s
  ->Js.String2.replaceByRe(%re("/<[^>]+>/g"), "")
  ->Js.String2.replaceByRe(%re("/&amp;/g"), "&")
  ->Js.String2.replaceByRe(%re("/&nbsp;/g"), " ")
  ->trim

let stripMarkdown = (s: string): string =>
  s
  ->stripHtml
  ->Js.String2.replaceByRe(%re("/[*_]/g"), "")
  ->Js.String2.replaceByRe(%re("/^#+ */g"), "")
  ->Js.String2.replaceByRe(%re("/^E2V2-[0-9]{3} *[·—] */g"), "")
  ->trim

let performanceTag = (direction: string): string => {
  let d = Js.String2.toLowerCase(direction)
  if Js.String2.includes(d, "шёп") || Js.String2.includes(d, "тихо") {
    "[whispering]"
  } else if Js.String2.includes(d, "запых") ||
            Js.String2.includes(d, "переводя дух") ||
            Js.String2.includes(d, "задых") {
    "[out of breath]"
  } else if Js.String2.includes(d, "оглуш") {
    "[dazed]"
  } else if Js.String2.includes(d, "усили") ||
            Js.String2.includes(d, "напряг") ||
            Js.String2.includes(d, "сквозь") ||
            Js.String2.includes(d, "рыча") {
    "[strained]"
  } else if Js.String2.includes(d, "твёрд") ||
            Js.String2.includes(d, "решитель") ||
            Js.String2.includes(d, "строго") ||
            Js.String2.includes(d, "точно") {
    "[firmly]"
  } else if Js.String2.includes(d, "удовлетвор") {
    "[low] [satisfied]"
  } else if Js.String2.includes(d, "удив") || Js.String2.includes(d, "не веря") {
    "[surprised]"
  } else if Js.String2.includes(d, "не понима") || Js.String2.includes(d, "озадач") {
    "[puzzled]"
  } else if Js.String2.includes(d, "сухо") || Js.String2.includes(d, "под нос") {
    "[dryly]"
  } else if Js.String2.includes(d, "обид") ||
            Js.String2.includes(d, "оскорб") ||
            Js.String2.includes(d, "возмущ") ||
            Js.String2.includes(d, "ворч") {
    "[upset]"
  } else if Js.String2.includes(d, "резко") ||
            Js.String2.includes(d, "гроз") ||
            Js.String2.includes(d, "в ужасе") ||
            Js.String2.includes(d, "испуган") {
    "[angrily]"
  } else if Js.String2.includes(d, "торгу") {
    "[bargaining]"
  } else if Js.String2.includes(d, "разочар") {
    "[disappointed]"
  } else if Js.String2.includes(d, "надежд") {
    "[hopefully]"
  } else if Js.String2.includes(d, "горд") {
    "[proudly]"
  } else if Js.String2.includes(d, "радост") ||
            Js.String2.includes(d, "восхищ") ||
            Js.String2.includes(d, "лику") ||
            Js.String2.includes(d, "счастлив") ||
            Js.String2.includes(d, "вспыхивая") {
    "[excitedly]"
  } else if Js.String2.includes(d, "задорно") ||
            Js.String2.includes(d, "игрив") ||
            Js.String2.includes(d, "невозмут") {
    "[playfully]"
  } else if Js.String2.includes(d, "торжеств") ||
            Js.String2.includes(d, "ведущ") ||
            Js.String2.includes(d, "громко") {
    "[grandly]"
  } else if Js.String2.includes(d, "во весь голос") ||
            Js.String2.includes(d, "во всю") {
    "[loudly]"
  } else if Js.String2.includes(d, "медленно") ||
            Js.String2.includes(d, "по одной букве") {
    "[slowly]"
  } else if Js.String2.includes(d, "серьёз") ||
            Js.String2.includes(d, "собран") ||
            Js.String2.includes(d, "вниматель") {
    "[seriously]"
  } else if Js.String2.includes(d, "спокой") ||
            Js.String2.includes(d, "ровно") ||
            Js.String2.includes(d, "чётко") ||
            Js.String2.includes(d, "просто") {
    "[calmly]"
  } else if Js.String2.includes(d, "быстро") ||
            Js.String2.includes(d, "тороп") ||
            Js.String2.includes(d, "нетерпел") {
    "[quickly]"
  } else if Js.String2.includes(d, "сообраз") || Js.String2.includes(d, "вспоминая") {
    "[realizing]"
  } else if Js.String2.includes(d, "делов") ||
            Js.String2.includes(d, "считая") ||
            Js.String2.includes(d, "проверяя") {
    "[matter-of-fact]"
  } else {
    ""
  }
}

let roleForSpeaker = (speaker: string): option<string> =>
  switch speaker {
  | "ФРОСЯ" => Some("FROSYA")
  | "ВАСЯ"
  | "ВАСЯ-ВОЛ"
  | "ВАСЯ-СОВА"
  | "ВАСЯ-ВОЛК" => Some("VASYA")
  | "МАМА" => Some("MAMA")
  | "ПАПА" => Some("PAPA")
  | "КОРНЕВОЙ ЗВЕРЬ" => Some("ROOT_CREATURE")
  | "МАЛЬЧИК-ВЕЛИКАН" => Some("GIANT_BOY")
  | "МУСЯ" => Some("MUSYA")
  | "ФРОСЯ И ВАСЯ" => Some("CHORUS_SIBLINGS")
  | _ => None
  }

let dialogueFrom = (html: string): (string, string, string, string) => {
  let plain = stripMarkdown(html)
  let colon = Js.String2.indexOf(plain, ":")
  if colon < 0 {
    raise(TableRead("dialogue has no speaker colon: " ++ plain))
  }
  let sourceSpeaker = Js.String2.slice(plain, ~from=0, ~to_=colon)->trim
  let speaker = switch roleForSpeaker(sourceSpeaker) {
  | Some(role) => role
  | None => raise(TableRead("no cast mapping for speaker " ++ sourceSpeaker))
  }
  let rest = Js.String2.sliceToEnd(plain, ~from=colon + 1)->trim
  let (direction, spoken) =
    if Js.String2.startsWith(rest, "(") {
      let close = Js.String2.indexOf(rest, ")")
      close > 0
        ? (
            Js.String2.slice(rest, ~from=1, ~to_=close),
            Js.String2.sliceToEnd(rest, ~from=close + 1)->trim,
          )
        : ("", rest)
    } else {
      ("", rest)
    }
  let clean =
    spoken
    ->Js.String2.replace("(твёрдо)", "[firmly]")
    ->trim
  (speaker, direction, performanceTag(direction), clean)
}

let narrationFrom = (id: string, scene: string, markdown: string): (string, string) => {
  let plain =
    stripMarkdown(markdown)
    ->Js.String2.replaceByRe(%re("/[(]Звук: ([^)]+)[)]/g"), "$1")
    ->trim
  let fixed = switch id {
  | "E2V2-001" => "«Фрося и Вася». Серия вторая: «Самый крутой номер»."
  | _ => plain
  }
  let tag = if id == "E2V2-001" {
    "[warmly]"
  } else if switch sceneForHeading(id) {
  | Some(_) => true
  | None => false
  } {
    scene == "scene_07" || scene == "scene_08" || scene == "scene_09" || scene == "scene_10"
      ? "[tense storytelling]"
      : scene == "scene_11" || scene == "scene_12"
        ? "[mysterious storytelling]"
        : "[storytelling]"
  } else {
    ""
  }
  (tag, fixed)
}

let parseScreenplay = (): array<segment> => {
  let segments: array<segment> = []
  let currentId = ref("")
  let currentScene = ref("title")
  let order = ref(0)
  readText(Path(screenplay))
  ->Js.String2.split("\n")
  ->Belt.Array.forEach(raw => {
    switch idFrom(raw) {
    | Some(id) => currentId := id
    | None => ()
    }
    let isHeading = Js.String2.startsWith(raw, "# ") || Js.String2.startsWith(raw, "## ")
    let isNumbered = Js.String2.startsWith(raw, "**E2V2-")
    if (isHeading || isNumbered) && includedBlock(currentId.contents) {
      let id = currentId.contents
      switch sceneForHeading(id) {
      | Some(scene) => currentScene := scene
      | None => ()
      }
      order := order.contents + 1
      if Js.String2.includes(raw, ":**") {
        let (speaker, direction, tag, parsedText) = dialogueFrom(raw)
        let text = parsedText
        let kind = speaker == "CHORUS_SIBLINGS" ? "chorus" : "dialogue"
        let _ = Js.Array2.push(segments, {
          order: order.contents,
          blockId: id,
          scene: currentScene.contents,
          kind,
          speaker,
          direction,
          tag,
          text,
        })
      } else {
        let (tag, text) = narrationFrom(id, currentScene.contents, raw)
        let _ = Js.Array2.push(segments, {
          order: order.contents,
          blockId: id,
          scene: currentScene.contents,
          kind: "narration",
          speaker: "NARRATOR",
          direction: "",
          tag,
          text,
        })
      }
    }
  })
  segments
}

let directed = (s: segment): string => s.tag == "" ? s.text : s.tag ++ " " ++ s.text

let voiceFor = (role: string): string =>
  switch Belt.Array.getBy(cast, member => member.role == role) {
  | Some(member) => member.voiceId
  | None => raise(TableRead("no voice for role " ++ role))
  }

let parentVoiceFor = (speaker: string): string =>
  speaker == "MAMA" || speaker == "PAPA" ? speaker : ""

let chunkSegments = (segments: array<segment>): array<chunk> => {
  let chunks: array<chunk> = []
  let current: array<segment> = []
  let currentScene = ref("")
  let currentChars = ref(0)
  let currentParent = ref("")
  let chunkIndex = ref(0)

  let flush = () => {
    if Belt.Array.length(current) > 0 {
      chunkIndex := chunkIndex.contents + 1
      let scene = currentScene.contents
      let id = scene ++ "_take_" ++ Belt.Int.toString(chunkIndex.contents)
      let _ = Js.Array2.push(chunks, {
        id,
        scene,
        kind: "dialogue",
        segments: Belt.Array.map(current, x => x),
        chars: currentChars.contents,
        parentVoice: currentParent.contents,
      })
      Js.Array2.spliceInPlace(current, ~pos=0, ~remove=Belt.Array.length(current), ~add=[])->ignore
      currentChars := 0
      currentParent := ""
    }
  }

  segments->Belt.Array.forEach(s => {
    if s.kind == "chorus" {
      flush()
      chunkIndex := chunkIndex.contents + 1
      let _ = Js.Array2.push(chunks, {
        id: s.scene ++ "_chorus_" ++ Belt.Int.toString(chunkIndex.contents),
        scene: s.scene,
        kind: "chorus",
        segments: [s],
        chars: Js.String2.length(directed(s)),
        parentVoice: "",
      })
    } else {
      let chars = Js.String2.length(directed(s))
      let nextParent = parentVoiceFor(s.speaker)
      let parentConflict =
        nextParent != "" && currentParent.contents != "" && nextParent != currentParent.contents
      let mustFlush = Belt.Array.length(current) > 0 && (
        currentScene.contents != s.scene ||
        Belt.Array.length(current) >= maxChunkSegments ||
        currentChars.contents + chars > maxChunkChars ||
        parentConflict
      )
      if mustFlush {
        flush()
      }
      if Belt.Array.length(current) == 0 {
        currentScene := s.scene
      }
      let _ = Js.Array2.push(current, s)
      currentChars := currentChars.contents + chars
      if currentParent.contents == "" && nextParent != "" {
        currentParent := nextParent
      }
    }
  })
  flush()
  chunks
}

let validate = (segments: array<segment>, chunks: array<chunk>): unit => {
  if Belt.Array.length(segments) != 230 {
    raise(TableRead(
      "expected 230 spoken spec blocks, got " ++ Belt.Int.toString(Belt.Array.length(segments)),
    ))
  }
  let dialogue = segments->Belt.Array.keep(s => s.kind == "dialogue" || s.kind == "chorus")
  let narration = segments->Belt.Array.keep(s => s.kind == "narration")
  if Belt.Array.length(dialogue) != 125 || Belt.Array.length(narration) != 105 {
    raise(TableRead(
      "expected 125 dialogue and 105 narration blocks, got " ++
      Belt.Int.toString(Belt.Array.length(dialogue)) ++ " and " ++
      Belt.Int.toString(Belt.Array.length(narration)),
    ))
  }
  let choruses = segments->Belt.Array.keep(s => s.kind == "chorus")
  if Belt.Array.length(choruses) != 1 {
    raise(TableRead("expected exactly one sibling chorus"))
  }
  let missingText = segments->Belt.Array.keep(s => trim(s.text) == "")
  if Belt.Array.length(missingText) > 0 {
    raise(TableRead("one or more spoken blocks are empty"))
  }
  let leakedDirection = dialogue->Belt.Array.keep(s =>
    Js.String2.startsWith(s.text, "(") || Js.String2.includes(s.text, "</em>"),
  )
  if Belt.Array.length(leakedDirection) > 0 {
    raise(TableRead("an acting direction leaked into spoken dialogue"))
  }
  let notes = segments->Belt.Array.keep(s => idNumber(s.blockId) >= 233)
  if Belt.Array.length(notes) > 0 {
    raise(TableRead("production notes must not be spoken"))
  }
  let missingMagic = ["ВОСК", "ВАТА", "КАСКА", "КОЛОКОЛ", "ВОЛ", "СОВА", "ВОЛК"]
  ->Belt.Array.keep(word => !Belt.Array.some(segments, s => Js.String2.includes(s.text, word)))
  if Belt.Array.length(missingMagic) > 0 {
    raise(TableRead("a required Russian magic word is missing from the performance"))
  }
  chunks->Belt.Array.forEach(c => {
    if c.kind == "dialogue" && c.chars > maxChunkChars {
      raise(TableRead(c.id ++ " exceeds the dialogue character limit"))
    }
    let hasMama = Belt.Array.some(c.segments, s => s.speaker == "MAMA")
    let hasPapa = Belt.Array.some(c.segments, s => s.speaker == "PAPA")
    if hasMama && hasPapa {
      raise(TableRead(c.id ++ " contains both Mama and Papa"))
    }
    if c.kind == "dialogue" {
      let uniqueVoices = Js.Dict.empty()
      c.segments->Belt.Array.forEach(s => Js.Dict.set(uniqueVoices, voiceFor(s.speaker), true))
      if Belt.Array.length(Js.Dict.keys(uniqueVoices)) > 10 {
        raise(TableRead(c.id ++ " exceeds ElevenLabs' ten-voice request limit"))
      }
    }
  })
}

let segmentJson = (s: segment): Js.Json.t => {
  let o = Js.Dict.empty()
  Js.Dict.set(o, "order", Js.Json.number(Belt.Int.toFloat(s.order)))
  Js.Dict.set(o, "block_id", Js.Json.string(s.blockId))
  Js.Dict.set(o, "scene", Js.Json.string(s.scene))
  Js.Dict.set(o, "kind", Js.Json.string(s.kind))
  Js.Dict.set(o, "speaker", Js.Json.string(s.speaker))
  Js.Dict.set(o, "direction", Js.Json.string(s.direction))
  Js.Dict.set(o, "tag", Js.Json.string(s.tag))
  Js.Dict.set(o, "text", Js.Json.string(s.text))
  Js.Json.object_(o)
}

let castJson = (member: castMember): Js.Json.t => {
  let o = Js.Dict.empty()
  Js.Dict.set(o, "voice", Js.Json.string(member.voice))
  Js.Dict.set(o, "voice_id", Js.Json.string(member.voiceId))
  Js.Dict.set(o, "status", Js.Json.string(member.status))
  Js.Json.object_(o)
}

let writePlan = (segments: array<segment>, chunks: array<chunk>): unit => {
  let castObject = Js.Dict.empty()
  cast->Belt.Array.forEach(member => Js.Dict.set(castObject, member.role, castJson(member)))
  let chunkJson = chunks->Belt.Array.map(c => {
    let o = Js.Dict.empty()
    Js.Dict.set(o, "id", Js.Json.string(c.id))
    Js.Dict.set(o, "scene", Js.Json.string(c.scene))
    Js.Dict.set(o, "kind", Js.Json.string(c.kind))
    Js.Dict.set(o, "characters", Js.Json.number(Belt.Int.toFloat(c.chars)))
    Js.Dict.set(o, "parent_voice_guard", Js.Json.string(c.parentVoice))
    Js.Dict.set(
      o,
      "segment_orders",
      Js.Json.array(c.segments->Belt.Array.map(s => Js.Json.number(Belt.Int.toFloat(s.order)))),
    )
    Js.Json.object_(o)
  })
  let root = Js.Dict.empty()
  Js.Dict.set(root, "title", Js.Json.string("Фрося и Вася — Серия 2: Самый крутой номер"))
  Js.Dict.set(root, "screenplay", Js.Json.string(screenplay))
  Js.Dict.set(root, "language_policy", Js.Json.string("Russian authoritative screenplay layer"))
  Js.Dict.set(root, "model_id", Js.Json.string("eleven_v3"))
  Js.Dict.set(root, "audio_pipeline_version", Js.Json.string(audioPipelineVersion))
  Js.Dict.set(root, "cast", Js.Json.object_(castObject))
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
  let signature =
    inputs
    ->Belt.Array.map(((Text(t), VoiceId(v))) => v ++ "|" ++ t)
    ->Js.Array2.joinWith("\n") ++ "::eleven_v3::dialogue::" ++ audioPipelineVersion
  let out = Path(cacheDir ++ "/dialogue_" ++ sha256Text(signature) ++ ".mp3")
  if exists(out) && fileSizeMb(out) *. 1.0e6 > 2000.0 {
    Js.log("  reuse " ++ c.id)
    Some(out)
  } else if dry {
    Js.log("  would render " ++ c.id ++ " (" ++ Belt.Int.toString(c.chars) ++ " chars)")
    None
  } else {
    let Path(t) = tmp
    let raw = Path(t ++ "/" ++ c.id ++ "_raw.mp3")
    let blob = await dialogue(inputs)
    let _ = writeBytes(raw, blob)
    let _ = normalize(~src=raw, ~out, ~lufs=-18)
    Js.log("  rendered " ++ c.id)
    Some(out)
  }
}

let renderSingle = async (
  ~voice: string,
  ~text: string,
  ~label: string,
  ~dry: bool,
  ~tmp: path,
): option<path> => {
  let signature = voice ++ "|" ++ text ++ "::eleven_v3::tts::" ++ audioPipelineVersion
  let out = Path(cacheDir ++ "/single_" ++ sha256Text(signature) ++ ".mp3")
  if exists(out) && fileSizeMb(out) *. 1.0e6 > 2000.0 {
    Some(out)
  } else if dry {
    Js.log("    would render " ++ label)
    None
  } else {
    let Path(t) = tmp
    let raw = Path(t ++ "/single_" ++ sha256Text(signature) ++ "_raw.mp3")
    let blob = await tts(~text=Text(text), ~voice=VoiceId(voice))
    let _ = writeBytes(raw, blob)
    let _ = normalize(~src=raw, ~out, ~lufs=-18)
    Some(out)
  }
}

let renderChorus = async (c: chunk, dry: bool, tmp: path): option<path> => {
  let s = Belt.Array.getExn(c.segments, 0)
  let text = "[together] " ++ (s.tag == "" ? s.text : s.tag ++ " " ++ s.text)
  let frosyaVoice = voiceFor("FROSYA")
  let vasyaVoice = voiceFor("VASYA")
  let signature =
    frosyaVoice ++ "|" ++ vasyaVoice ++ "|" ++ text ++ "::sibling-chorus::" ++
    audioPipelineVersion
  let out = Path(cacheDir ++ "/chorus_" ++ sha256Text(signature) ++ ".mp3")
  if exists(out) && fileSizeMb(out) *. 1.0e6 > 2000.0 {
    Js.log("  reuse " ++ c.id ++ " sibling chorus")
    Some(out)
  } else if dry {
    Js.log("  would render " ++ c.id ++ " sibling chorus")
    ignore(await renderSingle(~voice=frosyaVoice, ~text, ~label="chorus/Frosya", ~dry, ~tmp))
    ignore(await renderSingle(~voice=vasyaVoice, ~text, ~label="chorus/Vasya", ~dry, ~tmp))
    None
  } else {
    let frosya = await renderSingle(~voice=frosyaVoice, ~text, ~label="chorus/Frosya", ~dry, ~tmp)
    let vasya = await renderSingle(~voice=vasyaVoice, ~text, ~label="chorus/Vasya", ~dry, ~tmp)
    switch (frosya, vasya) {
    | (Some(Path(f)), Some(Path(v))) => {
        let Path(o) = out
        ffmpeg([
          "-nostdin", "-loglevel", "error", "-y", "-i", f, "-i", v,
          "-filter_complex",
          "[0:a][1:a]amix=inputs=2:duration=longest:normalize=1,loudnorm=I=-18:TP=-1.5:LRA=11",
          "-c:a", "libmp3lame", "-q:a", "3", o,
        ])
        Js.log("  rendered " ++ c.id ++ " sibling chorus")
        Some(out)
      }
    | _ => raise(TableRead("sibling chorus did not render both voices"))
    }
  }
}

let renderAll = async (chunks: array<chunk>, dry: bool): unit => {
  ensureDirPath(Path(cacheDir))
  let tmp = tempDir("drakosha-ep2-table-read-")
  let files: array<option<path>> = []
  for i in 0 to Belt.Array.length(chunks) - 1 {
    let c = Belt.Array.getExn(chunks, i)
    let rendered = c.kind == "chorus"
      ? await renderChorus(c, dry, tmp)
      : await renderDialogue(c, dry, tmp)
    let _ = Js.Array2.push(files, rendered)
  }
  if dry {
    Js.log("DRY run — no ElevenLabs call was made.")
  } else {
    let parts: array<path> = []
    let renderedRows: array<Js.Json.t> = []
    let previousScene = ref("")
    for i in 0 to Belt.Array.length(chunks) - 1 {
      let c = Belt.Array.getExn(chunks, i)
      switch Belt.Array.getExn(files, i) {
      | Some(p) => {
          if Belt.Array.length(parts) > 0 {
            let gap = c.scene == previousScene.contents ? 350 : 1100
            let _ = Js.Array2.push(parts, silence(Millis(gap), Path(cacheDir)))
          }
          let _ = Js.Array2.push(parts, p)
          previousScene := c.scene
          let Seconds(duration) = probeDuration(p)
          let Path(file) = p
          let row = Js.Dict.empty()
          Js.Dict.set(row, "id", Js.Json.string(c.id))
          Js.Dict.set(row, "scene", Js.Json.string(c.scene))
          Js.Dict.set(row, "kind", Js.Json.string(c.kind))
          Js.Dict.set(row, "path", Js.Json.string(file))
          Js.Dict.set(row, "duration_seconds", Js.Json.number(duration))
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
  if !dry && envPaid != Some("1") {
    raise(TableRead("paid render requires PAID=1; use DRY=1 for zero-cost preflight"))
  }
  ensureDirPath(Path(dir))
  let segments = parseScreenplay()
  let chunks = chunkSegments(segments)
  validate(segments, chunks)
  writePlan(segments, chunks)
  let dialogue = segments->Belt.Array.keep(s => s.kind == "dialogue" || s.kind == "chorus")
  let narration = segments->Belt.Array.keep(s => s.kind == "narration")
  Js.log(
    "validated plan: " ++ Belt.Int.toString(Belt.Array.length(dialogue)) ++
    " dialogue blocks, " ++ Belt.Int.toString(Belt.Array.length(narration)) ++
    " narrated headings/actions, " ++ Belt.Int.toString(Belt.Array.length(chunks)) ++ " takes",
  )
  Js.log("PLAN -> " ++ planPath)
  await renderAll(chunks, dry)
}

main()
->Js.Promise2.catch(error => {
  Js.log2("EP2 TABLE READ FAILED:", error)
  exit(1)
  Js.Promise.resolve()
})
->ignore
