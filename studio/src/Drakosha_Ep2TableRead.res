/* Frosya and Vasya — Episode 2 full-cast English table read.

   The bilingual spec's English layer is spoken. Russian letters, spelling, and
   magic words remain in Cyrillic. Anna Zub, the established multilingual
   table-read narrator, reads scene headings and action. The later approved
   native-US English cast reads character dialogue.

   Mama and Papa are never placed in the same ElevenLabs dialogue request. That
   is an explicit regression guard against the parent voice bleed found in the
   first Episode 1 English table read. Vasya's transformed forms always retain
   Vasya's voice. The root creature has one line and uses a clearly labelled
   provisional table-read voice because no series voice has been approved yet.

   DRY=1 parses, validates, and writes the plan without making a paid call.

   Run from studio/:
     DRY=1 node src/Drakosha_Ep2TableRead.res.mjs
     node src/Drakosha_Ep2TableRead.res.mjs */

open Cinema_Backends

@val @scope(("process", "env")) external envDry: option<string> = "DRY"
@val @scope("process") external exit: int => unit = "exit"

exception TableRead(string)

let dir = "../stories/drakosha/audio/ep2_table_read"
let screenplay = "../stories/drakosha/2026-08-11_EP2_samyi-krutoi-nomer_SPEC_numbered_bilingual.md"
let planPath = dir ++ "/ep2_table_read_plan.json"
let renderPath = dir ++ "/EP2_FULL_CAST_TABLE_READ.manifest.json"
let outputPath = dir ++ "/EP2_FULL_CAST_TABLE_READ.mp3"
let cacheDir = dir ++ "/cache"

let maxChunkChars = 1800
let maxChunkSegments = 20
let audioPipelineVersion = "drakosha-ep2-table-read-v1"

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
    status: "established multilingual table-read narrator",
  },
  {
    role: "FROSYA",
    voice: "Cherry Twinkle - Bubbly Cartoon Girl (US)",
    voiceId: "XJ2fW4ybq7HouelYYGcL",
    status: "approved native-US English table-read cast",
  },
  {
    role: "VASYA",
    voice: "Teddy Twinkle - Cute Cartoon Boy (US)",
    voiceId: "XjGYkUkzth8BPs29fmcV",
    status: "approved native-US English table-read cast",
  },
  {
    role: "MAMA",
    voice: "Sarah - Mature, Reassuring, Confident (US)",
    voiceId: "EXAVITQu4vr4xnSDxMaL",
    status: "approved native-US English table-read cast",
  },
  {
    role: "PAPA",
    voice: "Brian - Deep, Resonant and Comforting (US)",
    voiceId: "nPczCjzI2devNBz1zQrb",
    status: "approved native-US English table-read cast",
  },
  {
    role: "ROOT_CREATURE",
    voice: "Bill - Provisional Root Creature (US)",
    voiceId: "pqHfZKP75CvOlQylNhV4",
    status: "provisional table-read voice; series voice not yet approved",
  },
  {
    role: "GIANT_GIRL",
    voice: "Jessica - Playful, Bright, Warm (US)",
    voiceId: "cgSgspJ2msm6clMCkdW9",
    status: "approved native-US giant-child table-read voice",
  },
]

let trim = Js.String2.trim

let idFrom = (s: string): option<string> => {
  let i = Js.String2.indexOf(s, "E2SP")
  i >= 0 && Js.String2.length(s) >= i + 7
    ? Some(Js.String2.slice(s, ~from=i, ~to_=i + 7))
    : None
}

let idNumber = (id: string): int =>
  Js.String2.sliceToEnd(id, ~from=4)->Belt.Int.fromString->Belt.Option.getWithDefault(-1)

let includedBlock = (id: string): bool => {
  let n = idNumber(id)
  n == 1 || (n >= 4 && n <= 193)
}

let sceneForHeading = (id: string): option<string> =>
  switch id {
  | "E2SP001" => Some("title")
  | "E2SP004" => Some("scene_01")
  | "E2SP042" => Some("scene_02")
  | "E2SP049" => Some("scene_03")
  | "E2SP073" => Some("scene_04")
  | "E2SP085" => Some("scene_05")
  | "E2SP114" => Some("scene_06")
  | "E2SP133" => Some("scene_07")
  | "E2SP143" => Some("scene_08")
  | "E2SP170" => Some("scene_09")
  | "E2SP186" => Some("scene_10")
  | "E2SP192" => Some("final_card")
  | _ => None
  }

let stripHtml = (s: string): string =>
  s
  ->Js.String2.replaceByRe(%re("/<[^>]+>/g"), "")
  ->Js.String2.replaceByRe(%re("/&amp;/g"), "&")
  ->Js.String2.replaceByRe(%re("/&nbsp;/g"), " ")
  ->trim

let removeMagicGlosses = (s: string): string =>
  s
  ->Js.String2.replaceByRe(
    %re("/ [(](cotton wool|helmet|bell|kick scooter|ball of thread|ox|owl|wolf|crowbar|car|lava|bench|juice|salad|large metal container)[)]/g"),
    "",
  )

let performanceTag = (direction: string): string => {
  let d = Js.String2.toLowerCase(direction)
  if Js.String2.includes(d, "whisper") {
    "[whispering]"
  } else if Js.String2.includes(d, "out of breath") ||
            Js.String2.includes(d, "catching her breath") ||
            Js.String2.includes(d, "catching his breath") ||
            Js.String2.includes(d, "pant") {
    "[out of breath]"
  } else if Js.String2.includes(d, "dazed") {
    "[dazed]"
  } else if Js.String2.includes(d, "strained") ||
            Js.String2.includes(d, "straining") ||
            Js.String2.includes(d, "through clenched teeth") {
    "[strained]"
  } else if Js.String2.includes(d, "firm") ||
            Js.String2.includes(d, "absolute") ||
            Js.String2.includes(d, "leaving no room") {
    "[firmly]"
  } else if Js.String2.includes(d, "low and satisfied") {
    "[low] [satisfied]"
  } else if Js.String2.includes(d, "surpris") {
    "[surprised]"
  } else if Js.String2.includes(d, "puzzled") {
    "[puzzled]"
  } else if Js.String2.includes(d, "without much enthusiasm") ||
            Js.String2.includes(d, "dryly") {
    "[dryly]"
  } else if Js.String2.includes(d, "stung") ||
            Js.String2.includes(d, "offended") ||
            Js.String2.includes(d, "aggrieved") ||
            Js.String2.includes(d, "grumbling") ||
            Js.String2.includes(d, "indignant") {
    "[upset]"
  } else if Js.String2.includes(d, "angry") ||
            Js.String2.includes(d, "sharply") {
    "[angrily]"
  } else if Js.String2.includes(d, "bargaining") {
    "[bargaining]"
  } else if Js.String2.includes(d, "disappointed") {
    "[disappointed]"
  } else if Js.String2.includes(d, "hopeful") {
    "[hopefully]"
  } else if Js.String2.includes(d, "proud") {
    "[proudly]"
  } else if Js.String2.includes(d, "thrilled") ||
            Js.String2.includes(d, "delight") ||
            Js.String2.includes(d, "lighting up") ||
            Js.String2.includes(d, "triumphant") {
    "[excitedly]"
  } else if Js.String2.includes(d, "playfully") ||
            Js.String2.includes(d, "cheerful") ||
            Js.String2.includes(d, "innocently") {
    "[playfully]"
  } else if Js.String2.includes(d, "ceremon") ||
            Js.String2.includes(d, "grandly") ||
            Js.String2.includes(d, "master of ceremonies") {
    "[grandly]"
  } else if (Js.String2.includes(d, "loudly") ||
            Js.String2.includes(d, "calling") ||
            Js.String2.includes(d, "raising her voice")) &&
            !Js.String2.includes(d, "without raising") {
    "[loudly]"
  } else if Js.String2.includes(d, "slow") ||
            Js.String2.includes(d, "carefully") {
    "[slowly]"
  } else if Js.String2.includes(d, "precisely") {
    "[firmly]"
  } else if Js.String2.includes(d, "focused") ||
            Js.String2.includes(d, "intently") ||
            Js.String2.includes(d, "serious") {
    "[seriously]"
  } else if Js.String2.includes(d, "calm") ||
            Js.String2.includes(d, "evenly") ||
            Js.String2.includes(d, "unruffled") ||
            Js.String2.includes(d, "without raising") {
    "[calmly]"
  } else if Js.String2.includes(d, "hurried") ||
            Js.String2.includes(d, "quick") ||
            Js.String2.includes(d, "eager") ||
            Js.String2.includes(d, "impatient") {
    "[quickly]"
  } else if Js.String2.includes(d, "realizing") {
    "[realizing]"
  } else if Js.String2.includes(d, "explaining") ||
            Js.String2.includes(d, "businesslike") ||
            Js.String2.includes(d, "counting") {
    "[matter-of-fact]"
  } else {
    ""
  }
}

let roleForSpeaker = (speaker: string): option<string> =>
  switch speaker {
  | "FROSYA" => Some("FROSYA")
  | "VASYA"
  | "VASYA-OX"
  | "VASYA-OWL"
  | "VASYA-WOLF" => Some("VASYA")
  | "MAMA" => Some("MAMA")
  | "PAPA" => Some("PAPA")
  | "ROOT CREATURE" => Some("ROOT_CREATURE")
  | "GIANT GIRL" => Some("GIANT_GIRL")
  | "FROSYA AND VASYA" => Some("CHORUS_SIBLINGS")
  | _ => None
  }

let dialogueFrom = (html: string): (string, string, string, string) => {
  let plain = stripHtml(html)
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
    ->Js.String2.replace("(boldly)", "[boldly]")
    ->Js.String2.replace("(firmly)", "[firmly]")
    ->removeMagicGlosses
    ->trim
  (speaker, direction, performanceTag(direction), clean)
}

let narrationFrom = (id: string, scene: string, html: string): (string, string) => {
  let plain0 =
    stripHtml(html)
    ->Js.String2.replaceByRe(%re("/[(]Sound: ([^)]+)[)]/g"), "$1")
    ->trim
  let plain = if Js.String2.length(plain0) > 0 {
    Js.String2.toUpperCase(Js.String2.slice(plain0, ~from=0, ~to_=1)) ++
    Js.String2.sliceToEnd(plain0, ~from=1)
  } else {
    plain0
  }
  let fixed = switch id {
  | "E2SP001" => "“Frosya and Vasya.” Episode Two: “The Coolest Act.”"
  | "E2SP061" =>
    "The word flashes. A soft chime rings out, followed by an airy poof. A large fluffy wad of white cotton appears beside it. Rusya immediately plunges both hands into it. Musya acquires a fluffy white mustache."
  | "E2SP077" =>
    "Frosya pushes off. The scooter goes whizz-whizz, and its wheels thump over the plank. It flies off the end of the ramp. Frosya reaches out and strikes the bell."
  | "E2SP113" =>
    "Vasya-Wolf leaps onto the ramp, throws back his head, and howls. The small but genuine wolf howl travels beneath the porch and into the earth. When he finishes, he jumps back onto the fixed masonry landing beside Frosya."
  | "E2SP124" =>
    "The bell tears free of its thread, lands on the tilted boards, and rolls toward the bright edge of the porch. It goes ding… ding… faster and faster. It slips beneath the outer railing, drops into the drainage groove, and vanishes beyond the line of daylight."
  | "E2SP128" =>
    "The creature whips the vine around and throws Vasya-Wolf. There is a whistle and a soft poof. The wolf lands in Frosya’s cotton."
  | "E2SP141" =>
    "Vasya returns to himself. Enraged at losing the pencil, the creature growls, loops a new vine around the outer crossbeam, and yanks it downward. The boards crack more sharply. Papa sinks lower beneath the weight."
  | "E2SP146" =>
    "The word flashes. A metallic chime rings out. A short, sturdy crowbar appears on the stone."
  | "E2SP163" =>
    "With one hand, Papa guides the brace’s lower end toward the notch. There is a wooden thunk. The brace seats back into place."
  | "E2SP165" =>
    "The rising beam jerks the vine wrapped around it. Roots tear with a loud crack. The root creature is ripped out of the earth and tumbles into the drainage groove, scattering clods of black soil."
  | "E2SP166" =>
    "The creature scrambles up, looks back at the pencil in Frosya’s hand, and dives into a dark gap among earth and ordinary roots. Its dry rustle rapidly recedes."
  | "E2SP190" =>
    "The girl slips the bell into her pocket and walks away. With each step, the bell rings more faintly inside her pocket."
  | "E2SP192" => "Final card."
  | _ => plain
  }
  let tag = if id == "E2SP001" {
    "[warmly]"
  } else if switch sceneForHeading(id) {
  | Some(_) => true
  | None => false
  } {
    scene == "scene_06" || scene == "scene_07" || scene == "scene_08"
      ? "[tense storytelling]"
      : scene == "scene_10"
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
    if Js.String2.startsWith(raw, "<small>") && includedBlock(currentId.contents) {
      let id = currentId.contents
      switch sceneForHeading(id) {
      | Some(scene) => currentScene := scene
      | None => ()
      }
      order := order.contents + 1
      if Js.String2.includes(raw, ":</strong>") {
        let (speaker, direction, tag, parsedText) = dialogueFrom(raw)
        let text = id == "E2SP017"
          ? Js.String2.replace(parsedText, "V-v-v", "В-в-в")
          : parsedText
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
  if Belt.Array.length(segments) != 191 {
    raise(TableRead(
      "expected 191 spoken spec blocks, got " ++ Belt.Int.toString(Belt.Array.length(segments)),
    ))
  }
  let dialogue = segments->Belt.Array.keep(s => s.kind == "dialogue" || s.kind == "chorus")
  let narration = segments->Belt.Array.keep(s => s.kind == "narration")
  if Belt.Array.length(dialogue) != 104 || Belt.Array.length(narration) != 87 {
    raise(TableRead(
      "expected 104 dialogue and 87 narration blocks, got " ++
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
  let notes = segments->Belt.Array.keep(s => idNumber(s.blockId) >= 194)
  if Belt.Array.length(notes) > 0 {
    raise(TableRead("production notes must not be spoken"))
  }
  let missingMagic = ["ВАТА", "КАСКА", "КОЛОКОЛ", "ВОЛ", "СОВА", "ВОЛК", "ЛОМ"]
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
  Js.Dict.set(root, "title", Js.Json.string("Frosya and Vasya — Episode 2: The Coolest Act"))
  Js.Dict.set(root, "screenplay", Js.Json.string(screenplay))
  Js.Dict.set(root, "language_policy", Js.Json.string(
    "English translation layer; Russian letters, spelled words, and magic words retained in Cyrillic",
  ))
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
