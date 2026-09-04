/* Enoch Brown V5 audio-first documentary production.

   This renderer is deliberately conservative with paid and historical audio:
   - Jacob Michael's selected performance is pinned to eleven_v3 / WAV 48 kHz.
   - Music is pinned to music_v2 / MP3 48 kHz 320 kbps.
   - All authored sound effects use ElevenLabs sound generation.
   - The attack is never reenacted in sound.
   - Every paid request is content-addressed and claimed atomically before use.

   Run from studio/:
     DRY=1 node src/EnochBrown_Audio.res.mjs
     PAID=1 GENERATE=1 node src/EnochBrown_Audio.res.mjs

   DRY=1 always wins and makes zero paid calls. */

open Cinema_Backends

@val @scope(("process", "env")) external envDry: option<string> = "DRY"
@val @scope(("process", "env")) external envPaid: option<string> = "PAID"
@val @scope(("process", "env")) external envGenerate: option<string> = "GENERATE"
@val @scope("process") external exit: int => unit = "exit"

exception EnochAudio(string)

let pipelineVersion = "enoch-brown-audio-v5.0.0"
let assemblyVersion = "enoch-brown-audio-v5-assembly-v1.0.0"
let dialogueTempo = 0.78
let scriptPath = "../stories/enoch-brown/script/DOCUMENTARY_SCRIPT_v5_INCIDENT_FIRST.md"
let approvedScriptSha256 = "a6d238049f1892207130801a2bf197bfaad26b8054c716b217b9be693c2ea816"
let projectDir = "../stories/enoch-brown/production/audio_v5"
let cacheDir = projectDir ++ "/cache"
let rawDialogueDir = cacheDir ++ "/provider_raw/dialogue"
let rawMusicDir = cacheDir ++ "/provider_raw/music"
let rawSfxDir = cacheDir ++ "/provider_raw/sfx"
let claimDir = cacheDir ++ "/paid_claims"
let stemDir = cacheDir ++ "/stems/dialogue"
let musicStemDir = cacheDir ++ "/stems/music"
let sfxAssetDir = cacheDir ++ "/stems/sfx"
let workDir = cacheDir ++ "/assembly"
let outDir = projectDir ++ "/mix"
let reviewDir = projectDir ++ "/review"
let planPath = projectDir ++ "/ENOCH_BROWN_AUDIO_PLAN.v5.json"
let manifestPath = projectDir ++ "/ENOCH_BROWN_AUDIO_MASTER_V5.manifest.json"
let voiceMasterPath = outDir ++ "/ENOCH_BROWN_VOICE_MASTER_V5_ATEMPO078.wav"
let sfxStemPath = outDir ++ "/ENOCH_BROWN_ELEVENLABS_SFX_STEM_V5.wav"
let scoreStemPath = outDir ++ "/ENOCH_BROWN_MUSIC_V2_STEM_V5.wav"
let finalWavPath = outDir ++ "/ENOCH_BROWN_AUDIO_MASTER_V5_QC.wav"
let finalM4aPath = reviewDir ++ "/THE_SCHOOLHOUSE_BEFORE_THE_NATION_V5.m4a"

let narratorVoiceId = "PKu46bbccMP1b22TyeI0"
let narratorVoiceName = "Jacob Michael / Bishop — author selected"
let archiveVoiceId = narratorVoiceId
let archiveVoiceName = "Jacob Michael / Bishop — dry archival reading"
let fixedSeed = 17640829

let titleMusicPrompt =
  "Sparse instrumental historical-documentary title motif, slow and spacious. One low sustained tone beneath two widely separated soft piano notes. Sober, intimate, humane, and reflective, with abundant air, gentle dynamics, and a long clean decay."

let warMusicPrompt =
  "Restrained instrumental historical-documentary underscore for a careful account of political conflict. Low sustained strings, very soft piano color, wide empty intervals, and slow organic movement. Neutral, humane, analytical, spacious, and suitable for a quiet repeating bed with a smooth loopable ending."

let weaponMusicPrompt =
  "Minimal instrumental documentary question motif. Two soft low piano notes separated by long intervals over a nearly still warm tone. Thoughtful, unresolved, spacious, emotionally restrained, and suitable for a quiet repeating bed with a smooth loopable ending."

type speaker = Narrator | Archive

type turn = {
  id: string,
  scene: string,
  speaker: speaker,
  text: string,
}

type cue = {
  id: string,
  scene: string,
  kind: string,
  evidence: string,
  text: string,
}

type sourceEvent =
  | Heading(string)
  | Sound(cue)
  | Speech(turn)
  | FadeOut

type musicSpec = {
  id: string,
  prompt: string,
  ms: int,
}

type sfxSpec = {
  id: string,
  cueFragment: string,
  prompt: string,
  seconds: float,
  influence: float,
}

type renderedTurn = {
  turn: turn,
  requestHash: string,
  rawPath: string,
  stemPath: string,
  duration: float,
}

type timelineCue = {
  cue: cue,
  eventIndex: int,
  start: float,
  end_: float,
}

type timelineTurn = {
  rendered: renderedTurn,
  eventIndex: int,
  start: float,
  end_: float,
}

type chapter = {title: string, at: float}

type sfxPlacement = {
  id: string,
  source: string,
  evidence: string,
  use_: string,
  at: float,
  trimStart: float,
  trimEnd: float,
  gain: float,
}

let fail = (message: string): 'a => raise(EnochAudio(message))
let trim = Js.String2.trim
let pathString = (Path(value)): string => value
let secondsValue = (Seconds(value)): float => value
let lower = Js.String2.toLowerCase
let contains = (value: string, fragment: string): bool => Js.String2.includes(value, fragment)
let starts = (value: string, prefix: string): bool => Js.String2.startsWith(value, prefix)
let intMax = (a: int, b: int): int => a > b ? a : b
let floatMax = (a: float, b: float): float => a > b ? a : b
let floatMin = (a: float, b: float): float => a < b ? a : b

let pad3 = (value: int): string => {
  let raw = Belt.Int.toString(value)
  switch Js.String2.length(raw) {
  | 1 => "00" ++ raw
  | 2 => "0" ++ raw
  | _ => raw
  }
}

let jsonString = (value: string): Js.Json.t => Js.Json.string(value)
let jsonNumber = (value: float): Js.Json.t => Js.Json.number(value)
let addString = (object_: Js.Dict.t<Js.Json.t>, key: string, value: string): unit =>
  Js.Dict.set(object_, key, jsonString(value))
let addNumber = (object_: Js.Dict.t<Js.Json.t>, key: string, value: float): unit =>
  Js.Dict.set(object_, key, jsonNumber(value))
let addBool = (object_: Js.Dict.t<Js.Json.t>, key: string, value: bool): unit =>
  Js.Dict.set(object_, key, Js.Json.boolean(value))

let speakerName = speaker => switch speaker {
| Narrator => "NARRATOR"
| Archive => "ARCHIVE READER"
}

let voiceIdFor = speaker => switch speaker {
| Narrator => narratorVoiceId
| Archive => archiveVoiceId
}

let voiceNameFor = speaker => switch speaker {
| Narrator => narratorVoiceName
| Archive => archiveVoiceName
}

let voiceSettingsFor = (speaker): productionVoiceSettings => switch speaker {
| Narrator => {stability: 0.50, speed: 0.80}
| Archive => {stability: 0.62, speed: 0.84}
}

let cleanFactTags = (value: string): string =>
  value->Js.String2.replaceByRe(%re("/\[FACTS:[^\]]+\]/g"), "")

let cleanParagraph = (value: string): string =>
  value
  ->Js.String2.replaceByRe(%re("/[\*`]/g"), "")
  ->Js.String2.replaceByRe(%re("/\s+/g"), " ")
  ->trim

let cleanSpeech = (value: string): string =>
  cleanFactTags(value)
  ->Js.String2.split("\n\n")
  ->Belt.Array.map(cleanParagraph)
  ->Belt.Array.keep(value => value != "")
  ->Js.Array2.joinWith("\n\n")
  ->trim

let cleanCue = (value: string): string =>
  cleanFactTags(value)->Js.String2.replaceByRe(%re("/\s+/g"), " ")->trim

let isHeading = (line: string): bool => starts(line, "## ")
let isSound = (line: string): bool => starts(line, "SOUND ")
let isMusic = (line: string): bool => starts(line, "MUSIC ")
let isCue = (line: string): bool => isSound(line) || isMusic(line)
let isNarrator = (line: string): bool => line == "NARRATOR:"
let isArchive = (line: string): bool => starts(line, "ARCHIVE READER")
let isFade = (line: string): bool => line == "FADE OUT."
let isMetadata = (line: string): bool =>
  starts(line, "FACTS:") || starts(line, "SOURCE:") || line == "---" || line == "END."
let isControl = (line: string): bool =>
  isHeading(line) || isCue(line) || isNarrator(line) || isArchive(line) || isFade(line) || isMetadata(line)

let evidenceFrom = (line: string): string => {
  let colonIndex = Js.String2.indexOf(line, ":")
  if colonIndex < 0 {
    fail("sound cue has no evidence class: " ++ line)
  }
  let header = Js.String2.slice(line, ~from=0, ~to_=colonIndex)->trim
  let pieces = Js.String2.split(header, " ")
  if Belt.Array.length(pieces) != 2 {
    fail("sound cue has invalid header: " ++ line)
  }
  Belt.Array.getExn(pieces, 1)
}

let parseScript = (): (array<sourceEvent>, array<turn>, array<cue>) => {
  if !exists(Path(scriptPath)) {
    fail("canonical script is missing: " ++ scriptPath)
  }
  let actualScriptHash = sha256File(Path(scriptPath))
  if actualScriptHash != approvedScriptSha256 {
    fail("approved V5 script changed; refusing generation. Expected " ++ approvedScriptSha256 ++ ", got " ++ actualScriptHash)
  }
  let lines = readText(Path(scriptPath))->Js.String2.split("\n")
  let events: array<sourceEvent> = []
  let turns: array<turn> = []
  let cues: array<cue> = []
  let active = ref(false)
  let scene = ref("")
  let turnCount = ref(0)
  let cueCount = ref(0)
  let index = ref(0)
  while index.contents < Belt.Array.length(lines) {
    let raw = Belt.Array.getExn(lines, index.contents)
    let line = trim(raw)
    if isHeading(line) {
      let title = Js.String2.sliceToEnd(line, ~from=3)->trim
      if starts(title, "COLD OPEN") {
        active := true
      }
      if active.contents {
        scene := title
        Js.Array2.push(events, Heading(title))->ignore
      }
      index := index.contents + 1
    } else if !active.contents {
      index := index.contents + 1
    } else if isCue(line) {
      let collected: array<string> = [line]
      let next = ref(index.contents + 1)
      while next.contents < Belt.Array.length(lines) && trim(Belt.Array.getExn(lines, next.contents)) != "" {
        Js.Array2.push(collected, trim(Belt.Array.getExn(lines, next.contents)))->ignore
        next := next.contents + 1
      }
      cueCount := cueCount.contents + 1
      let row = {
        id: "C" ++ pad3(cueCount.contents),
        scene: scene.contents,
        kind: isMusic(line) ? "MUSIC" : "SOUND",
        evidence: evidenceFrom(line),
        text: cleanCue(Js.Array2.joinWith(collected, " ")),
      }
      Js.Array2.push(cues, row)->ignore
      Js.Array2.push(events, Sound(row))->ignore
      index := next.contents
    } else if isNarrator(line) || isArchive(line) {
      let speaker = isNarrator(line) ? Narrator : Archive
      let collected: array<string> = []
      let next = ref(index.contents + 1)
      while next.contents < Belt.Array.length(lines) && !isControl(trim(Belt.Array.getExn(lines, next.contents))) {
        Js.Array2.push(collected, Belt.Array.getExn(lines, next.contents))->ignore
        next := next.contents + 1
      }
      let text = cleanSpeech(Js.Array2.joinWith(collected, "\n"))
      if text == "" {
        fail("empty spoken block after " ++ line ++ " in " ++ scene.contents)
      }
      turnCount := turnCount.contents + 1
      let row = {
        id: "T" ++ pad3(turnCount.contents),
        scene: scene.contents,
        speaker,
        text,
      }
      Js.Array2.push(turns, row)->ignore
      Js.Array2.push(events, Speech(row))->ignore
      index := next.contents
    } else if isFade(line) {
      Js.Array2.push(events, FadeOut)->ignore
      index := index.contents + 1
    } else {
      index := index.contents + 1
    }
  }
  if Belt.Array.length(turns) != 29 {
    fail("parser expected 29 V5 speaker turns; got " ++ Belt.Int.toString(Belt.Array.length(turns)))
  }
  if Belt.Array.length(cues) != 16 {
    fail("parser expected 16 V5 audio cues; got " ++ Belt.Int.toString(Belt.Array.length(cues)))
  }
  let narratorCount = turns->Belt.Array.reduce(0, (count, turn) => switch turn.speaker {
  | Narrator => count + 1
  | Archive => count
  })
  let archiveCount = Belt.Array.length(turns) - narratorCount
  let soundCount = cues->Belt.Array.reduce(0, (count, cue) => cue.kind == "SOUND" ? count + 1 : count)
  let musicCount = Belt.Array.length(cues) - soundCount
  if narratorCount != 28 || archiveCount != 1 {
    fail("parser expected 28 narrator blocks and one archive block")
  }
  if soundCount != 8 || musicCount != 8 {
    fail("parser expected eight SOUND and eight MUSIC cues")
  }
  cues->Belt.Array.forEach(cue => {
    if cue.evidence != "I" && cue.evidence != "E" {
      fail("cue " ++ cue.id ++ " has invalid evidence class " ++ cue.evidence)
    }
  })
  turns->Belt.Array.forEach(turn => {
    let providerText = turn.text
    ["FACTS:", "SOURCE:", "SOUND I:", "SOUND E:", "MUSIC E:", "---"]->Belt.Array.forEach(marker => {
      if contains(providerText, marker) {
        fail("provider text for " ++ turn.id ++ " contains production metadata: " ++ marker)
      }
    })
  })
  (events, turns, cues)
}

let expressionTag = (turn: turn): string => switch turn.id {
| "T001" => "[curious] "
| "T003" => "[slowly] "
| "T011" => "[serious] "
| "T016" => "[curious] "
| "T021" => "[quietly] "
| _ => ""
}

let renderText = (turn: turn): string => expressionTag(turn) ++ turn.text

let requestSignature = (turn: turn): string => {
  let settings = voiceSettingsFor(turn.speaker)
  Js.Array2.joinWith([
    pipelineVersion,
    "eleven_v3",
    "wav_48000",
    "language_code=en",
    "apply_text_normalization=on",
    "seed=" ++ Belt.Int.toString(fixedSeed),
    "voice=" ++ voiceIdFor(turn.speaker),
    "stability=" ++ Js.Float.toString(settings.stability),
    "speed=" ++ Js.Float.toString(settings.speed),
    renderText(turn),
  ], "|")
}

let requestHash = (turn: turn): string => sha256Text(requestSignature(turn))
let shortHash = (hash: string): string => Js.String2.slice(hash, ~from=0, ~to_=16)
let cachedDialoguePath = (~dir: string, ~turn: turn): string => {
  let suffix = "_" ++ shortHash(requestHash(turn)) ++ ".wav"
  switch readDir(Path(dir))->Belt.Array.getBy(name => Js.String2.endsWith(name, suffix)) {
  | Some(name) => dir ++ "/" ++ name
  | None => dir ++ "/" ++ turn.id ++ suffix
  }
}
let rawPathFor = (turn: turn): string => cachedDialoguePath(~dir=rawDialogueDir, ~turn)
let stemPathFor = (turn: turn): string =>
  stemDir ++ "/" ++ turn.id ++ "_" ++ shortHash(requestHash(turn)) ++ "_atempo078.wav"

let musicSpecs: array<musicSpec> = [
  {id: "title_motif", prompt: titleMusicPrompt, ms: 90000},
  {id: "war_context", prompt: warMusicPrompt, ms: 120000},
  {id: "weapon_question", prompt: weaponMusicPrompt, ms: 120000},
]

let sfxSpecs: array<sfxSpec> = [
  {
    id: "ordinary_schoolroom",
    cueFragment: "restrained colonial school texture",
    prompt: "Intimate dry interior of a small eighteenth-century schoolroom during an ordinary calm lesson: a few children recite indistinctly as a soft group murmur, a slate pencil scratches, one paper page turns, and one wooden bench shifts. Natural restrained documentary ambience with each detail clear and gentle.",
    seconds: 8.0,
    influence: 0.72,
  },
  {
    id: "schoolroom_closing_page",
    cueFragment: "school texture resolves into one last page movement",
    prompt: "A quiet schoolroom texture settles naturally into one final dry paper page movement and then clean stillness, intimate close documentary recording.",
    seconds: 3.0,
    influence: 0.78,
  },
  {
    id: "archive_sheet_unfold",
    cueFragment: "one dry sheet of paper is unfolded",
    prompt: "One dry old paper sheet is unfolded once by careful hands and settles flat on a wooden table, close intimate documentary recording.",
    seconds: 3.0,
    influence: 0.80,
  },
  {
    id: "measured_shovel_cuts",
    cueFragment: "two measured shovel cuts enter loose soil",
    prompt: "Two separate measured shovel blade cuts enter loose cultivated soil, followed by soft earth being moved aside; restrained close outdoor documentary recording with a clean ending.",
    seconds: 4.5,
    influence: 0.82,
  },
  {
    id: "school_objects_coda",
    cueFragment: "slate pencil makes one short line",
    prompt: "Three isolated close sounds in a quiet dry room: a slate pencil draws one short line, one paper page turns, then one wooden school bench settles. Each sound is distinct with silence between them and a clean ending.",
    seconds: 5.0,
    influence: 0.84,
  },
]

let musicSignature = (spec: musicSpec): string => Js.Array2.joinWith([
  pipelineVersion,
  "music_v2",
  "mp3_48000_320",
  "force_instrumental=true",
  "store_for_inpainting=false",
  "sign_with_c2pa=true",
  "ms=" ++ Belt.Int.toString(spec.ms),
  spec.prompt,
], "|")

let musicHash = (spec: musicSpec): string => sha256Text(musicSignature(spec))
let musicRawPath = (spec: musicSpec): string => rawMusicDir ++ "/" ++ spec.id ++ "_" ++ shortHash(musicHash(spec)) ++ ".mp3"
let musicStemPath = (spec: musicSpec): string => musicStemDir ++ "/" ++ spec.id ++ "_" ++ shortHash(musicHash(spec)) ++ ".wav"

let sfxSignature = (spec: sfxSpec): string => Js.Array2.joinWith([
  pipelineVersion,
  "elevenlabs_sound_generation",
  "mp3_44100_128",
  "seconds=" ++ Js.Float.toString(spec.seconds),
  "influence=" ++ Js.Float.toString(spec.influence),
  spec.prompt,
], "|")

let sfxHash = (spec: sfxSpec): string => sha256Text(sfxSignature(spec))
let sfxRawPath = (spec: sfxSpec): string => rawSfxDir ++ "/" ++ spec.id ++ "_" ++ shortHash(sfxHash(spec)) ++ ".mp3"
let sfxAssetPath = (spec: sfxSpec): string => sfxAssetDir ++ "/" ++ spec.id ++ "_" ++ shortHash(sfxHash(spec)) ++ ".wav"

let wordsIn = (value: string): int =>
  value->trim == ""
    ? 0
    : value
      ->trim
      ->Js.String2.replaceByRe(%re("/\s+/g"), " ")
      ->Js.String2.split(" ")
      ->Belt.Array.length

let charCount = (value: string): int => Js.String2.length(value)

let turnJson = (turn: turn): Js.Json.t => {
  let settings = voiceSettingsFor(turn.speaker)
  let root = Js.Dict.empty()
  addString(root, "id", turn.id)
  addString(root, "scene", turn.scene)
  addString(root, "speaker", speakerName(turn.speaker))
  addString(root, "voice_id", voiceIdFor(turn.speaker))
  addString(root, "voice_name", voiceNameFor(turn.speaker))
  addNumber(root, "characters", Belt.Int.toFloat(charCount(renderText(turn))))
  addNumber(root, "words", Belt.Int.toFloat(wordsIn(renderText(turn))))
  addNumber(root, "stability", settings.stability)
  addNumber(root, "speed", settings.speed)
  addNumber(root, "seed", Belt.Int.toFloat(fixedSeed))
  addString(root, "request_sha256", requestHash(turn))
  addString(root, "raw_cache", rawPathFor(turn))
  addString(root, "text", renderText(turn))
  Js.Json.object_(root)
}

let cueJson = (cue: cue): Js.Json.t => {
  let root = Js.Dict.empty()
  addString(root, "id", cue.id)
  addString(root, "scene", cue.scene)
  addString(root, "kind", cue.kind)
  addString(root, "evidence_class", cue.evidence)
  addString(root, "text", cue.text)
  Js.Json.object_(root)
}

let musicJson = (spec: musicSpec): Js.Json.t => {
  let root = Js.Dict.empty()
  addString(root, "id", spec.id)
  addString(root, "model", "music_v2")
  addString(root, "output_format", "mp3_48000_320")
  addNumber(root, "duration_ms", Belt.Int.toFloat(spec.ms))
  addBool(root, "instrumental", true)
  addBool(root, "store_for_inpainting", false)
  addBool(root, "sign_with_c2pa", true)
  addString(root, "request_sha256", musicHash(spec))
  addString(root, "raw_cache", musicRawPath(spec))
  addString(root, "prompt", spec.prompt)
  Js.Json.object_(root)
}

let sfxJson = (spec: sfxSpec): Js.Json.t => {
  let root = Js.Dict.empty()
  addString(root, "id", spec.id)
  addString(root, "model", "eleven_text_to_sound_v2")
  addString(root, "output_format", "mp3_44100_128")
  addString(root, "cue_fragment", spec.cueFragment)
  addNumber(root, "duration_seconds", spec.seconds)
  addNumber(root, "prompt_influence", spec.influence)
  addString(root, "request_sha256", sfxHash(spec))
  addString(root, "raw_cache", sfxRawPath(spec))
  addString(root, "prompt", spec.prompt)
  Js.Json.object_(root)
}

let validateExpressionTags = (turns: array<turn>): unit => {
  let allowed = ["[serious] ", "[slowly] ", "[quietly] ", "[curious] "]
  let tagged = ref(0)
  let previousTagged = ref(false)
  turns->Belt.Array.forEach(turn => {
    let tag = expressionTag(turn)
    let isTagged = tag != ""
    if isTagged && !Belt.Array.some(allowed, allowedTag => allowedTag == tag) {
      fail("unapproved Eleven v3 expression tag on " ++ turn.id ++ ": " ++ tag)
    }
    if isTagged && previousTagged.contents {
      fail("adjacent tagged V3 turns are forbidden at " ++ turn.id)
    }
    if isTagged {
      tagged := tagged.contents + 1
    }
    previousTagged := isTagged
  })
  if tagged.contents * 5 >= Belt.Array.length(turns) {
    fail("at least 80% of narration must remain untagged")
  }
  if expressionTag(Belt.Array.getExn(turns, 6)) != "" ||
     expressionTag(Belt.Array.getExn(turns, 7)) != "" ||
     expressionTag(Belt.Array.getExn(turns, 28)) != "" {
    fail("archive quote, 'He was alive,' and final turn must remain untagged")
  }
}

let writePlan = (~turns: array<turn>, ~cues: array<cue>): unit => {
  validateExpressionTags(turns)
  ensureDirPath(Path(projectDir))
  let totalChars = turns->Belt.Array.reduce(0, (total, turn) => total + charCount(renderText(turn)))
  let totalWords = turns->Belt.Array.reduce(0, (total, turn) => total + wordsIn(renderText(turn)))
  let maxChars = turns->Belt.Array.reduce(0, (largest, turn) => intMax(largest, charCount(renderText(turn))))
  if maxChars > 5000 {
    fail("a V3 request exceeds the documented 5,000-character limit: " ++ Belt.Int.toString(maxChars))
  }
  let ttsEstimate = Belt.Int.toFloat(totalChars) /. 1000.0 *. 0.10
  let musicMs = musicSpecs->Belt.Array.reduce(0, (total, spec) => total + spec.ms)
  let musicEstimate = Belt.Int.toFloat(musicMs) /. 60000.0 *. 0.15
  let sfxSeconds = sfxSpecs->Belt.Array.reduce(0.0, (total, spec) => total +. spec.seconds)
  let sfxCreditEstimate = sfxSeconds *. 40.0
  let scriptHash = sha256File(Path(scriptPath))
  let root = Js.Dict.empty()
  addString(root, "schema", "enoch.audio-plan/v1")
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "assembly_version", assemblyVersion)
  addString(root, "canonical_script", scriptPath)
  addString(root, "canonical_script_sha256", scriptHash)
  addString(root, "speech_model", "eleven_v3")
  addString(root, "speech_output_format", "wav_48000")
  addNumber(root, "local_dialogue_tempo", dialogueTempo)
  addString(root, "runtime_policy", "Deliberate provider pacing plus a mild pitch-preserving local slowdown targets 27–30 minutes; the final runtime is a hard QC gate.")
  addNumber(root, "speaker_turns", Belt.Int.toFloat(Belt.Array.length(turns)))
  addNumber(root, "sound_cues", Belt.Int.toFloat(Belt.Array.length(cues)))
  addNumber(root, "spoken_words", Belt.Int.toFloat(totalWords))
  addNumber(root, "spoken_characters", Belt.Int.toFloat(totalChars))
  addNumber(root, "largest_request_characters", Belt.Int.toFloat(maxChars))
  addNumber(root, "estimated_tts_usd_at_public_rate", ttsEstimate)
  addNumber(root, "estimated_music_usd_at_public_rate", musicEstimate)
  addNumber(root, "estimated_total_usd_at_public_rate", ttsEstimate +. musicEstimate)
  addNumber(root, "estimated_sfx_credits", sfxCreditEstimate)
  addString(root, "cost_disclaimer", "Estimate only; account billing and credits are controlled by ElevenLabs.")
  addString(root, "paid_gate", "PAID=1 and GENERATE=1; DRY=1 always forbids paid calls")
  addString(root, "sfx_provider", "ElevenLabs eleven_text_to_sound_v2")
  addString(root, "attack_sound_policy", "Zero weapons, impacts, cries, pleas, body sounds, approach blocking, doors, or attacker voices.")
  addString(root, "expression_map_sha256", sha256Text(turns->Belt.Array.map(turn => turn.id ++ "=" ++ expressionTag(turn))->Js.Array2.joinWith("|")))
  Js.Dict.set(root, "turns", Js.Json.array(turns->Belt.Array.map(turnJson)))
  Js.Dict.set(root, "sound_design", Js.Json.array(cues->Belt.Array.map(cueJson)))
  Js.Dict.set(root, "music", Js.Json.array(musicSpecs->Belt.Array.map(musicJson)))
  Js.Dict.set(root, "generated_sfx", Js.Json.array(sfxSpecs->Belt.Array.map(sfxJson)))
  writeText(Path(planPath), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n")
  Js.log(
    "PLAN -> " ++ planPath ++ "\n" ++
    Belt.Int.toString(Belt.Array.length(turns)) ++ " V3 turns; " ++
    Belt.Int.toString(totalChars) ++ " characters; " ++
    Belt.Int.toString(totalWords) ++ " words; three Music v2 cues; five ElevenLabs SFX cues.\n" ++
    "Estimated public-rate spend: $" ++ Js.Float.toFixedWithPrecision(ttsEstimate +. musicEstimate, ~digits=2),
  )
}

let paidAllowed = (): bool => envDry != Some("1") && envPaid == Some("1") && envGenerate == Some("1")

let requirePaid = (label: string): unit => {
  if envDry == Some("1") {
    fail("DRY=1 forbids paid generation for " ++ label)
  }
  if !paidAllowed() {
    fail("paid generation is locked for " ++ label ++ "; set PAID=1 and GENERATE=1")
  }
}

let validateAudio = (path: string, label: string): float => {
  if !exists(Path(path)) {
    fail(label ++ " was not written: " ++ path)
  }
  let decode = run(~cmd="ffmpeg", ~args=["-nostdin", "-v", "error", "-i", path, "-f", "null", "-"])
  if decode.code != 0 {
    fail(label ++ " does not decode: " ++ Js.String2.slice(decode.stderr, ~from=0, ~to_=400))
  }
  let duration = probeDuration(Path(path))->secondsValue
  if duration <= 0.2 {
    fail(label ++ " has invalid duration " ++ Js.Float.toString(duration))
  }
  duration
}

let claimPaid = (~kind: string, ~id: string, ~hash: string, ~detail: string): unit => {
  ensureDirPath(Path(claimDir))
  let path = claimDir ++ "/" ++ kind ++ "_" ++ hash ++ ".claim.json"
  let root = Js.Dict.empty()
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "kind", kind)
  addString(root, "id", id)
  addString(root, "request_sha256", hash)
  addString(root, "detail", detail)
  addString(root, "policy", "An existing claim with no cached output is an uncertain paid attempt; do not retry automatically.")
  if !writeTextExclusive(Path(path), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n") {
    fail("paid attempt already claimed for " ++ kind ++ " " ++ id ++ "; cache is missing, so automatic retry is blocked: " ++ path)
  }
}

let publishFetched = (~blob: blob, ~extension: string, ~destination: string, ~label: string): float => {
  let scratch = tempDir("enoch-provider-")->pathString
  let temporary = scratch ++ "/asset." ++ extension
  writeBytes(Path(temporary), blob)->ignore
  let duration = validateAudio(temporary, label)
  if !publishFileExclusive(Path(temporary), Path(destination)) {
    fail("refusing to overwrite an immutable provider asset: " ++ destination)
  }
  duration
}

let writeProviderReceipt = (
  ~path: string,
  ~kind: string,
  ~id: string,
  ~model: string,
  ~requestHash: string,
  ~assetPath: string,
  ~duration: float,
): unit => {
  let receiptPath = path ++ ".receipt.json"
  if !exists(Path(receiptPath)) {
    let root = Js.Dict.empty()
    addString(root, "pipeline_version", pipelineVersion)
    addString(root, "kind", kind)
    addString(root, "id", id)
    addString(root, "model", model)
    addString(root, "request_sha256", requestHash)
    addString(root, "asset", assetPath)
    addString(root, "asset_sha256", sha256File(Path(assetPath)))
    addNumber(root, "duration_seconds", duration)
    writeText(Path(receiptPath), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n")
  }
}

let renderDialogue = async (turns: array<turn>): array<renderedTurn> => {
  ensureDirPath(Path(rawDialogueDir))
  ensureDirPath(Path(stemDir))
  let rendered: array<renderedTurn> = []
  let index = ref(0)
  while index.contents < Belt.Array.length(turns) {
    let turn = Belt.Array.getExn(turns, index.contents)
    let hash = requestHash(turn)
    let rawPath = rawPathFor(turn)
    if !exists(Path(rawPath)) {
      requirePaid("V3 turn " ++ turn.id)
      claimPaid(
        ~kind="tts",
        ~id=turn.id,
        ~hash,
        ~detail=speakerName(turn.speaker) ++ " / " ++ Belt.Int.toString(charCount(renderText(turn))) ++ " characters",
      )
      Js.log(
        "V3 " ++ Belt.Int.toString(index.contents + 1) ++ "/" ++ Belt.Int.toString(Belt.Array.length(turns)) ++
        " " ++ turn.id ++ " " ++ speakerName(turn.speaker) ++ " (" ++ Belt.Int.toString(charCount(renderText(turn))) ++ " chars)",
      )
      let audio = await productionTts(
        ~text=Text(renderText(turn)),
        ~voice=VoiceId(voiceIdFor(turn.speaker)),
        ~seed=fixedSeed,
        ~settings=voiceSettingsFor(turn.speaker),
      )
      let duration = publishFetched(~blob=audio, ~extension="wav", ~destination=rawPath, ~label="V3 " ++ turn.id)
      writeProviderReceipt(
        ~path=rawPath,
        ~kind="tts",
        ~id=turn.id,
        ~model="eleven_v3",
        ~requestHash=hash,
        ~assetPath=rawPath,
        ~duration,
      )
    }
    let rawDuration = validateAudio(rawPath, "cached V3 " ++ turn.id)
    let stemPath = stemPathFor(turn)
    if !exists(Path(stemPath)) {
      let scratch = tempDir("enoch-dialogue-stem-")->pathString
      let temporary = scratch ++ "/" ++ turn.id ++ ".wav"
      ffmpeg([
        "-nostdin", "-v", "error", "-n", "-i", rawPath,
        "-af", "highpass=f=55,atempo=" ++ Js.Float.toString(dialogueTempo) ++ ",loudnorm=I=-18:TP=-2:LRA=7",
        "-ar", "48000", "-ac", "1", "-c:a", "pcm_s24le", temporary,
      ])
      validateAudio(temporary, "normalized dialogue " ++ turn.id)->ignore
      if !publishFileExclusive(Path(temporary), Path(stemPath)) {
        fail("refusing to overwrite normalized dialogue stem: " ++ stemPath)
      }
    }
    let duration = validateAudio(stemPath, "dialogue stem " ++ turn.id)
    let expectedDuration = rawDuration /. dialogueTempo
    if Js.Math.abs_float(duration -. expectedDuration) > 0.75 {
      fail("tempo-normalized duration mismatch for " ++ turn.id)
    }
    Js.Array2.push(rendered, {turn, requestHash: hash, rawPath, stemPath, duration})->ignore
    index := index.contents + 1
  }
  rendered
}

let renderMusic = async (): array<(musicSpec, string, string, float)> => {
  ensureDirPath(Path(rawMusicDir))
  ensureDirPath(Path(musicStemDir))
  let rendered: array<(musicSpec, string, string, float)> = []
  let index = ref(0)
  while index.contents < Belt.Array.length(musicSpecs) {
    let spec = Belt.Array.getExn(musicSpecs, index.contents)
    let hash = musicHash(spec)
    let rawPath = musicRawPath(spec)
    if !exists(Path(rawPath)) {
      requirePaid("Music v2 " ++ spec.id)
      claimPaid(
        ~kind="music",
        ~id=spec.id,
        ~hash,
        ~detail=Belt.Int.toString(spec.ms) ++ " ms instrumental",
      )
      Js.log("MUSIC V2 " ++ Belt.Int.toString(index.contents + 1) ++ "/" ++ Belt.Int.toString(Belt.Array.length(musicSpecs)) ++ " " ++ spec.id)
      let audio = await productionMusic(
        ~prompt=Prompt(spec.prompt),
        ~ms=Millis(spec.ms),
        ~instrumental=true,
        ~storeForInpainting=false,
        ~signWithC2pa=true,
      )
      let duration = publishFetched(~blob=audio, ~extension="mp3", ~destination=rawPath, ~label="Music v2 " ++ spec.id)
      writeProviderReceipt(
        ~path=rawPath,
        ~kind="music",
        ~id=spec.id,
        ~model="music_v2",
        ~requestHash=hash,
        ~assetPath=rawPath,
        ~duration,
      )
    }
    validateAudio(rawPath, "cached Music v2 " ++ spec.id)->ignore
    let stemPath = musicStemPath(spec)
    if !exists(Path(stemPath)) {
      let scratch = tempDir("enoch-music-stem-")->pathString
      let temporary = scratch ++ "/" ++ spec.id ++ ".wav"
      ffmpeg([
        "-nostdin", "-v", "error", "-n", "-i", rawPath,
        "-af", "loudnorm=I=-26:TP=-3:LRA=11",
        "-ar", "48000", "-ac", "2", "-c:a", "pcm_s24le", temporary,
      ])
      validateAudio(temporary, "normalized music " ++ spec.id)->ignore
      if !publishFileExclusive(Path(temporary), Path(stemPath)) {
        fail("refusing to overwrite normalized music stem: " ++ stemPath)
      }
    }
    let duration = validateAudio(stemPath, "music stem " ++ spec.id)
    Js.Array2.push(rendered, (spec, rawPath, stemPath, duration))->ignore
    index := index.contents + 1
  }
  rendered
}

let renderSfx = async (): array<(sfxSpec, string, string, float)> => {
  ensureDirPath(Path(rawSfxDir))
  ensureDirPath(Path(sfxAssetDir))
  let rendered: array<(sfxSpec, string, string, float)> = []
  let index = ref(0)
  while index.contents < Belt.Array.length(sfxSpecs) {
    let spec = Belt.Array.getExn(sfxSpecs, index.contents)
    let hash = sfxHash(spec)
    let rawPath = sfxRawPath(spec)
    if !exists(Path(rawPath)) {
      requirePaid("Sound Effects v2 " ++ spec.id)
      claimPaid(
        ~kind="sfx",
        ~id=spec.id,
        ~hash,
        ~detail=Js.Float.toString(spec.seconds) ++ " seconds / eleven_text_to_sound_v2",
      )
      Js.log(
        "SOUND EFFECT V2 " ++ Belt.Int.toString(index.contents + 1) ++ "/" ++
        Belt.Int.toString(Belt.Array.length(sfxSpecs)) ++ " " ++ spec.id,
      )
      let audio = await soundEffect(
        ~prompt=Prompt(spec.prompt),
        ~seconds=spec.seconds,
        ~influence=spec.influence,
      )
      let duration = publishFetched(
        ~blob=audio,
        ~extension="mp3",
        ~destination=rawPath,
        ~label="Sound Effects v2 " ++ spec.id,
      )
      writeProviderReceipt(
        ~path=rawPath,
        ~kind="sfx",
        ~id=spec.id,
        ~model="eleven_text_to_sound_v2",
        ~requestHash=hash,
        ~assetPath=rawPath,
        ~duration,
      )
    }
    validateAudio(rawPath, "cached Sound Effects v2 " ++ spec.id)->ignore
    let stemPath = sfxAssetPath(spec)
    if !exists(Path(stemPath)) {
      let scratch = tempDir("enoch-sfx-asset-")->pathString
      let temporary = scratch ++ "/" ++ spec.id ++ ".wav"
      ffmpeg([
        "-nostdin", "-v", "error", "-n", "-i", rawPath,
        "-af", "highpass=f=35,loudnorm=I=-24:TP=-4:LRA=10",
        "-ar", "48000", "-ac", "2", "-c:a", "pcm_s24le", temporary,
      ])
      validateAudio(temporary, "normalized Sound Effects v2 " ++ spec.id)->ignore
      if !publishFileExclusive(Path(temporary), Path(stemPath)) {
        fail("refusing to overwrite normalized SFX asset: " ++ stemPath)
      }
    }
    let duration = validateAudio(stemPath, "SFX asset " ++ spec.id)
    Js.Array2.push(rendered, (spec, rawPath, stemPath, duration))->ignore
    index := index.contents + 1
  }
  rendered
}

let cueWindow = (cue: cue): float => {
  switch cue.id {
  | "C001" => 8.0
  | "C002" => 3.0
  | "C003" => 0.0
  | "C004" => 0.0
  | "C005" => 2.0
  | "C006" => 3.0
  | "C007" => 4.0
  | "C008" => 0.0
  | "C009" => 1.2
  | "C010" => 0.0
  | "C011" => 1.2
  | "C012" => 4.5
  | "C013" => 1.0
  | "C014" => 5.0
  | "C015" => 0.0
  | "C016" => 4.0
  | _ => fail("no V5 cue window for " ++ cue.id)
  }
}

let silencePath = (seconds: float): string => {
  let ms = Belt.Float.toInt(seconds *. 1000.0)
  let path = workDir ++ "/silence_" ++ Belt.Int.toString(ms) ++ ".wav"
  if !exists(Path(path)) {
    ensureDirPath(Path(workDir))
    ffmpeg([
      "-nostdin", "-v", "error", "-n", "-f", "lavfi", "-i", "anullsrc=r=48000:cl=mono",
      "-t", Js.Float.toString(seconds), "-c:a", "pcm_s24le", path,
    ])
  }
  path
}

let renderedById = (rows: array<renderedTurn>, id: string): renderedTurn => switch Belt.Array.getBy(rows, row => row.turn.id == id) {
| Some(row) => row
| None => fail("no rendered dialogue for " ++ id)
}

let buildVoiceTimeline = (
  ~events: array<sourceEvent>,
  ~rendered: array<renderedTurn>,
): (array<timelineCue>, array<timelineTurn>, array<chapter>, float) => {
  ensureDirPath(Path(outDir))
  ensureDirPath(Path(workDir))
  let parts: array<string> = []
  let timelineCues: array<timelineCue> = []
  let timelineTurns: array<timelineTurn> = []
  let chapters: array<chapter> = []
  let cursor = ref(0.0)
  events->Belt.Array.forEachWithIndex((eventIndex, event) => switch event {
  | Heading(title) => {
      if cursor.contents > 0.0 {
        let gap = 0.75
        Js.Array2.push(parts, silencePath(gap))->ignore
        cursor := cursor.contents +. gap
      }
      Js.Array2.push(chapters, {title, at: cursor.contents})->ignore
    }
  | Sound(cue) => {
      let duration = cueWindow(cue)
      let start = cursor.contents
      if duration > 0.0 {
        Js.Array2.push(parts, silencePath(duration))->ignore
        cursor := cursor.contents +. duration
      }
      Js.Array2.push(timelineCues, {cue, eventIndex, start, end_: cursor.contents})->ignore
    }
  | Speech(turn) => {
      let row = renderedById(rendered, turn.id)
      let start = cursor.contents
      Js.Array2.push(parts, row.stemPath)->ignore
      cursor := cursor.contents +. row.duration
      let end_ = cursor.contents
      Js.Array2.push(timelineTurns, {rendered: row, eventIndex, start, end_})->ignore
      let gap = 0.38
      Js.Array2.push(parts, silencePath(gap))->ignore
      cursor := cursor.contents +. gap
    }
  | FadeOut => {
      let gap = 1.8
      Js.Array2.push(parts, silencePath(gap))->ignore
      cursor := cursor.contents +. gap
    }
  })
  let total = cursor.contents
  let listPath = workDir ++ "/voice_concat.txt"
  let pwdResult = run(~cmd="pwd", ~args=[])
  if pwdResult.code != 0 {
    fail("cannot resolve assembly paths: " ++ pwdResult.stderr)
  }
  let base = trim(pwdResult.stdout)
  let list = parts
  ->Belt.Array.map(path => "file '" ++ (starts(path, "/") ? path : base ++ "/" ++ path) ++ "'")
  ->Js.Array2.joinWith("\n") ++ "\n"
  writeText(Path(listPath), list)
  if !exists(Path(voiceMasterPath)) {
    let scratch = tempDir("enoch-voice-master-")->pathString
    let temporary = scratch ++ "/voice.wav"
    ffmpeg([
      "-nostdin", "-v", "error", "-n", "-f", "concat", "-safe", "0", "-i", listPath,
      "-ar", "48000", "-ac", "1", "-c:a", "pcm_s24le", temporary,
    ])
    validateAudio(temporary, "voice master")->ignore
    if !publishFileExclusive(Path(temporary), Path(voiceMasterPath)) {
      fail("refusing to overwrite voice master: " ++ voiceMasterPath)
    }
  }
  let actual = validateAudio(voiceMasterPath, "voice master")
  if Js.Math.abs_float(actual -. total) > 1.0 {
    fail("voice timeline duration mismatch: planned " ++ Js.Float.toString(total) ++ ", got " ++ Js.Float.toString(actual))
  }
  (timelineCues, timelineTurns, chapters, actual)
}

let cueHas = (row: timelineCue, fragment: string): bool => contains(lower(row.cue.text), fragment)

let addPlacement = (rows: array<sfxPlacement>, row: sfxPlacement): unit => {
  if !exists(Path(row.source)) {
    fail("required ElevenLabs SFX asset is missing: " ++ row.source)
  }
  let sourceDuration = probeDuration(Path(row.source))->secondsValue
  if row.trimStart < 0.0 || row.trimEnd <= row.trimStart || row.trimEnd > sourceDuration +. 0.01 {
    fail("invalid SFX trim for " ++ row.id ++ " against " ++ Js.Float.toString(sourceDuration) ++ "s source")
  }
  Js.Array2.push(rows, row)->ignore
}

let renderedSfxById = (rows: array<(sfxSpec, string, string, float)>, id: string): (sfxSpec, string, string, float) =>
  switch Belt.Array.getBy(rows, ((spec, _, _, _)) => spec.id == id) {
  | Some(row) => row
  | None => fail("missing rendered Sound Effects v2 asset " ++ id)
  }

let sfxPlacements = (
  ~cues: array<timelineCue>,
  ~sfx: array<(sfxSpec, string, string, float)>,
): array<sfxPlacement> => {
  let rows: array<sfxPlacement> = []
  sfxSpecs->Belt.Array.forEach(spec => {
    let cue = switch Belt.Array.getBy(cues, row => cueHas(row, lower(spec.cueFragment))) {
    | Some(row) => row
    | None => fail("no authored SOUND cue matches SFX " ++ spec.id)
    }
    if cue.cue.kind != "SOUND" {
      fail("SFX " ++ spec.id ++ " matched a non-SOUND cue")
    }
    let (_, _, source, sourceDuration) = renderedSfxById(sfx, spec.id)
    let gain = switch spec.id {
    | "ordinary_schoolroom" => 0.58
    | "schoolroom_closing_page" => 0.55
    | "archive_sheet_unfold" => 0.62
    | "measured_shovel_cuts" => 0.68
    | _ => 0.58
    }
    addPlacement(rows, {
      id: cue.cue.id ++ "_" ++ spec.id,
      source,
      evidence: cue.cue.evidence,
      use_: spec.prompt,
      at: cue.start,
      trimStart: 0.0,
      trimEnd: floatMin(sourceDuration, spec.seconds),
      gain,
    })
  })
  let authoredSounds = cues->Belt.Array.keep(row => row.cue.kind == "SOUND")
  if Belt.Array.length(authoredSounds) != 8 || Belt.Array.length(rows) != 5 {
    fail("V5 sound map must contain five generated SFX and three explicit silence cues")
  }
  ["C003", "C007", "C013"]->Belt.Array.forEach(id => {
    if !Belt.Array.some(authoredSounds, row => row.cue.id == id) {
      fail("missing explicit room-tone cue " ++ id)
    }
  })
  rows
}

let buildSfxStem = (~placements: array<sfxPlacement>, ~duration: float): unit => {
  if exists(Path(sfxStemPath)) {
    validateAudio(sfxStemPath, "ElevenLabs SFX stem")->ignore
  } else {
    let scratch = tempDir("enoch-sfx-stem-")->pathString
    let temporary = scratch ++ "/sfx.wav"
    let inputs = placements->Belt.Array.map(row => ["-i", row.source])->Belt.Array.concatMany
    let chains = placements->Belt.Array.mapWithIndex((index, row) =>
      "[" ++ Belt.Int.toString(index) ++ ":a]" ++
      "atrim=" ++ Js.Float.toString(row.trimStart) ++ ":" ++ Js.Float.toString(row.trimEnd) ++ "," ++
      "asetpts=PTS-STARTPTS,aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo," ++
      "highpass=f=45,volume=" ++ Js.Float.toString(row.gain) ++ "," ++
      "adelay=" ++ Belt.Int.toString(Belt.Float.toInt(row.at *. 1000.0)) ++ ":all=1[s" ++ Belt.Int.toString(index) ++ "]"
    )
    let labels = placements->Belt.Array.mapWithIndex((index, _) => "[s" ++ Belt.Int.toString(index) ++ "]")->Js.Array2.joinWith("")
    let graph =
      Js.Array2.joinWith(chains, ";") ++ ";" ++
      "anullsrc=r=48000:cl=stereo:d=" ++ Js.Float.toString(duration) ++ "[clock];" ++
      "[clock]" ++ labels ++ "amix=inputs=" ++ Belt.Int.toString(Belt.Array.length(placements) + 1) ++
      ":duration=first:normalize=0:dropout_transition=0,alimiter=limit=0.80[out]"
    ffmpeg(Belt.Array.concatMany([
      ["-nostdin", "-v", "error", "-n"],
      inputs,
      ["-filter_complex", graph, "-map", "[out]", "-ar", "48000", "-ac", "2", "-c:a", "pcm_s24le", temporary],
    ]))
    validateAudio(temporary, "ElevenLabs SFX stem")->ignore
    if !publishFileExclusive(Path(temporary), Path(sfxStemPath)) {
      fail("refusing to overwrite ElevenLabs SFX stem: " ++ sfxStemPath)
    }
  }
}

let cueTime = (cues: array<timelineCue>, fragment: string): float => switch Belt.Array.getBy(cues, row => cueHas(row, fragment)) {
| Some(row) => row.start
| None => fail("timeline has no cue containing: " ++ fragment)
}

let musicStemFor = (rows: array<(musicSpec, string, string, float)>, id: string): (string, float) => switch Belt.Array.getBy(rows, ((spec, _, _, _)) => spec.id == id) {
| Some((_, _, stem, duration)) => (stem, duration)
| None => fail("missing rendered Music v2 stem " ++ id)
}

let buildScoreStem = (
  ~music: array<(musicSpec, string, string, float)>,
  ~cues: array<timelineCue>,
  ~duration: float,
): unit => {
  if exists(Path(scoreStemPath)) {
    validateAudio(scoreStemPath, "Music v2 stem")->ignore
  } else {
    let (titlePath, titleSourceDuration) = musicStemFor(music, "title_motif")
    let (warPath, warSourceDuration) = musicStemFor(music, "war_context")
    let titleStart = cueTime(cues, "one dry slate stroke")
    let titleStop = cueTime(cues, "title motif fades") +. 0.5
    let titleDuration = floatMin(titleSourceDuration, floatMax(3.0, titleStop -. titleStart))
    let warStart = cueTime(cues, "score opens into a wider")
    let warStop = cueTime(cues, "score stops")
    let warDuration = floatMax(3.0, warStop -. warStart)
    let reductionAt = cueTime(cues, "score reduces to one sustained tone") -. warStart
    let scratch = tempDir("enoch-score-stem-")->pathString
    let temporary = scratch ++ "/score.wav"
    let graph =
      "[0:a]atrim=0:" ++ Js.Float.toString(titleDuration) ++ ",asetpts=PTS-STARTPTS," ++
      "afade=t=in:st=0:d=1,afade=t=out:st=" ++ Js.Float.toString(floatMax(0.0, titleDuration -. 2.0)) ++ ":d=2," ++
      "volume=0.78,adelay=" ++ Belt.Int.toString(Belt.Float.toInt(titleStart *. 1000.0)) ++ ":all=1[title];" ++
      "[1:a]atrim=0:" ++ Js.Float.toString(floatMin(warSourceDuration, warDuration)) ++ ",asetpts=PTS-STARTPTS," ++
      "afade=t=in:st=0:d=2,afade=t=out:st=" ++ Js.Float.toString(floatMax(0.0, floatMin(warSourceDuration, warDuration) -. 3.0)) ++ ":d=3," ++
      "volume='if(lt(t\\," ++ Js.Float.toString(floatMax(0.0, reductionAt)) ++ ")\\,0.62\\,0.30)'," ++
      "adelay=" ++ Belt.Int.toString(Belt.Float.toInt(warStart *. 1000.0)) ++ ":all=1[war];" ++
      "anullsrc=r=48000:cl=stereo:d=" ++ Js.Float.toString(duration) ++ "[clock];" ++
      "[clock][title][war]amix=inputs=3:duration=first:normalize=0:dropout_transition=0[out]"
    ffmpeg([
      "-nostdin", "-v", "error", "-n", "-i", titlePath, "-i", warPath,
      "-filter_complex", graph, "-map", "[out]", "-ar", "48000", "-ac", "2", "-c:a", "pcm_s24le", temporary,
    ])
    validateAudio(temporary, "Music v2 stem")->ignore
    if !publishFileExclusive(Path(temporary), Path(scoreStemPath)) {
      fail("refusing to overwrite Music v2 stem: " ++ scoreStemPath)
    }
  }
}

let cueById = (cues: array<timelineCue>, id: string): timelineCue => switch Belt.Array.getBy(cues, row => row.cue.id == id) {
| Some(row) => row
| None => fail("timeline has no cue " ++ id)
}

let buildScoreStemV5 = (
  ~music: array<(musicSpec, string, string, float)>,
  ~cues: array<timelineCue>,
  ~duration: float,
): unit => {
  if exists(Path(scoreStemPath)) {
    validateAudio(scoreStemPath, "Music v2 stem")->ignore
  } else {
    let (titlePath, titleSourceDuration) = musicStemFor(music, "title_motif")
    let (warPath, warSourceDuration) = musicStemFor(music, "war_context")
    let (weaponPath, weaponSourceDuration) = musicStemFor(music, "weapon_question")
    let titleStart = cueById(cues, "C004").start
    let titleStop = cueById(cues, "C005").end_
    let titleDuration = floatMin(titleSourceDuration, floatMax(3.0, titleStop -. titleStart))
    let warStart = cueById(cues, "C008").start
    let warStop = cueById(cues, "C009").end_
    let warDuration = floatMax(3.0, warStop -. warStart)
    let weaponStart = cueById(cues, "C010").start
    let weaponStop = cueById(cues, "C011").end_
    let weaponDuration = floatMax(3.0, weaponStop -. weaponStart)
    let codaStart = cueById(cues, "C015").start
    let codaStop = cueById(cues, "C016").end_
    let codaDuration = floatMin(titleSourceDuration, floatMax(3.0, codaStop -. codaStart))
    let warLoopSamples = intMax(1, Belt.Float.toInt(warSourceDuration *. 48000.0))
    let weaponLoopSamples = intMax(1, Belt.Float.toInt(weaponSourceDuration *. 48000.0))
    let scratch = tempDir("enoch-score-v5-")->pathString
    let temporary = scratch ++ "/score.wav"
    let graph =
      "[0:a]asplit=2[title_source][coda_source];" ++
      "[title_source]atrim=0:" ++ Js.Float.toString(titleDuration) ++ ",asetpts=PTS-STARTPTS," ++
      "afade=t=in:st=0:d=1,afade=t=out:st=" ++ Js.Float.toString(floatMax(0.0, titleDuration -. 2.0)) ++ ":d=2," ++
      "volume=0.52,adelay=" ++ Belt.Int.toString(Belt.Float.toInt(titleStart *. 1000.0)) ++ ":all=1[title];" ++
      "[1:a]aloop=loop=-1:size=" ++ Belt.Int.toString(warLoopSamples) ++ "," ++
      "atrim=0:" ++ Js.Float.toString(warDuration) ++ ",asetpts=PTS-STARTPTS," ++
      "afade=t=in:st=0:d=2,afade=t=out:st=" ++ Js.Float.toString(floatMax(0.0, warDuration -. 3.0)) ++ ":d=3," ++
      "volume=0.30,adelay=" ++ Belt.Int.toString(Belt.Float.toInt(warStart *. 1000.0)) ++ ":all=1[war];" ++
      "[2:a]aloop=loop=-1:size=" ++ Belt.Int.toString(weaponLoopSamples) ++ "," ++
      "atrim=0:" ++ Js.Float.toString(weaponDuration) ++ ",asetpts=PTS-STARTPTS," ++
      "afade=t=in:st=0:d=2,afade=t=out:st=" ++ Js.Float.toString(floatMax(0.0, weaponDuration -. 2.5)) ++ ":d=2.5," ++
      "volume=0.32,adelay=" ++ Belt.Int.toString(Belt.Float.toInt(weaponStart *. 1000.0)) ++ ":all=1[weapon];" ++
      "[coda_source]atrim=0:" ++ Js.Float.toString(codaDuration) ++ ",asetpts=PTS-STARTPTS," ++
      "afade=t=in:st=0:d=1.5,afade=t=out:st=" ++ Js.Float.toString(floatMax(0.0, codaDuration -. 3.0)) ++ ":d=3," ++
      "volume=0.46,adelay=" ++ Belt.Int.toString(Belt.Float.toInt(codaStart *. 1000.0)) ++ ":all=1[coda];" ++
      "anullsrc=r=48000:cl=stereo:d=" ++ Js.Float.toString(duration) ++ "[clock];" ++
      "[clock][title][war][weapon][coda]amix=inputs=5:duration=first:normalize=0:dropout_transition=0[out]"
    ffmpeg([
      "-nostdin", "-v", "error", "-n", "-i", titlePath, "-i", warPath, "-i", weaponPath,
      "-filter_complex", graph, "-map", "[out]", "-ar", "48000", "-ac", "2", "-c:a", "pcm_s24le", temporary,
    ])
    validateAudio(temporary, "Music v2 V5 stem")->ignore
    if !publishFileExclusive(Path(temporary), Path(scoreStemPath)) {
      fail("refusing to overwrite Music v2 V5 stem: " ++ scoreStemPath)
    }
  }
}

let finalMix = (~duration: float): unit => {
  ensureDirPath(Path(reviewDir))
  if !exists(Path(finalWavPath)) {
    let scratch = tempDir("enoch-final-mix-")->pathString
    let temporary = scratch ++ "/master.wav"
    let graph =
      "[0:a]aformat=sample_fmts=fltp:channel_layouts=stereo[voice];" ++
      "[2:a][voice]sidechaincompress=threshold=0.025:ratio=8:attack=20:release=350:makeup=1[ducked_music];" ++
      "[voice][1:a][ducked_music]amix=inputs=3:duration=first:normalize=0:dropout_transition=0," ++
      "atrim=0:" ++ Js.Float.toString(duration) ++ "," ++
      "loudnorm=I=-16:TP=-2:LRA=7,alimiter=limit=0.84,volume=-0.7dB[out]"
    ffmpeg([
      "-nostdin", "-v", "error", "-n", "-i", voiceMasterPath, "-i", sfxStemPath, "-i", scoreStemPath,
      "-filter_complex", graph, "-map", "[out]", "-ar", "48000", "-ac", "2", "-c:a", "pcm_s24le", temporary,
    ])
    validateAudio(temporary, "final WAV master")->ignore
    if !publishFileExclusive(Path(temporary), Path(finalWavPath)) {
      fail("refusing to overwrite final master: " ++ finalWavPath)
    }
  }
  if !exists(Path(finalM4aPath)) {
    let scratch = tempDir("enoch-final-m4a-")->pathString
    let temporary = scratch ++ "/master.m4a"
    ffmpeg([
      "-nostdin", "-v", "error", "-n", "-i", finalWavPath,
      "-map", "0:a:0", "-map_metadata", "-1", "-c:a", "aac", "-b:a", "256k", "-ar", "48000", "-ac", "2",
      "-movflags", "+faststart", "-metadata", "title=The Schoolhouse Before the Nation", temporary,
    ])
    validateAudio(temporary, "final M4A master")->ignore
    if !publishFileExclusive(Path(temporary), Path(finalM4aPath)) {
      fail("refusing to overwrite final M4A: " ++ finalM4aPath)
    }
  }
}

let placementJson = (row: sfxPlacement): Js.Json.t => {
  let root = Js.Dict.empty()
  addString(root, "id", row.id)
  addString(root, "provider", "ElevenLabs")
  addString(root, "model", "eleven_text_to_sound_v2")
  addString(root, "source", row.source)
  addString(root, "source_sha256", sha256File(Path(row.source)))
  addString(root, "evidence_class", row.evidence)
  addString(root, "use", row.use_)
  addNumber(root, "timeline_seconds", row.at)
  addNumber(root, "trim_start_seconds", row.trimStart)
  addNumber(root, "trim_end_seconds", row.trimEnd)
  addNumber(root, "linear_gain", row.gain)
  Js.Json.object_(root)
}

let timelineTurnJson = (row: timelineTurn): Js.Json.t => {
  let root = Js.Dict.empty()
  addString(root, "id", row.rendered.turn.id)
  addString(root, "scene", row.rendered.turn.scene)
  addString(root, "speaker", speakerName(row.rendered.turn.speaker))
  addString(root, "voice_id", voiceIdFor(row.rendered.turn.speaker))
  addString(root, "source_text", row.rendered.turn.text)
  addString(root, "provider_text", renderText(row.rendered.turn))
  addString(root, "request_sha256", row.rendered.requestHash)
  addString(root, "raw_provider_asset", row.rendered.rawPath)
  addString(root, "raw_provider_sha256", sha256File(Path(row.rendered.rawPath)))
  addString(root, "normalized_stem", row.rendered.stemPath)
  addString(root, "normalized_stem_sha256", sha256File(Path(row.rendered.stemPath)))
  addNumber(root, "start_seconds", row.start)
  addNumber(root, "end_seconds", row.end_)
  Js.Json.object_(root)
}

let timelineCueJson = (row: timelineCue): Js.Json.t => {
  let root = Js.Dict.empty()
  addString(root, "id", row.cue.id)
  addString(root, "scene", row.cue.scene)
  addString(root, "kind", row.cue.kind)
  addString(root, "evidence_class", row.cue.evidence)
  addString(root, "text", row.cue.text)
  addNumber(root, "start_seconds", row.start)
  addNumber(root, "end_seconds", row.end_)
  Js.Json.object_(root)
}

let chapterJson = (row: chapter): Js.Json.t => {
  let root = Js.Dict.empty()
  addString(root, "title", row.title)
  addNumber(root, "start_seconds", row.at)
  Js.Json.object_(root)
}

let writeManifest = (
  ~turns: array<timelineTurn>,
  ~cues: array<timelineCue>,
  ~chapters: array<chapter>,
  ~placements: array<sfxPlacement>,
  ~music: array<(musicSpec, string, string, float)>,
  ~sfx: array<(sfxSpec, string, string, float)>,
  ~duration: float,
): unit => {
  let root = Js.Dict.empty()
  addString(root, "schema", "enoch.audio-master/v5")
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "assembly_version", assemblyVersion)
  addString(root, "canonical_script", scriptPath)
  addString(root, "canonical_script_sha256", sha256File(Path(scriptPath)))
  addString(root, "status", "FULL V5 AUDIO PRODUCTION: Jacob Michael, Eleven v3, Music v2, ElevenLabs Sound Effects v2")
  addString(root, "master_wav", finalWavPath)
  addString(root, "master_wav_sha256", sha256File(Path(finalWavPath)))
  addString(root, "master_m4a", finalM4aPath)
  addString(root, "master_m4a_sha256", sha256File(Path(finalM4aPath)))
  addNumber(root, "duration_seconds", duration)
  addString(root, "speech_model", "eleven_v3")
  addString(root, "narrator_voice_id", narratorVoiceId)
  addString(root, "narrator_voice_name", narratorVoiceName)
  addString(root, "expression_map_sha256", sha256Text(turns->Belt.Array.map(row => row.rendered.turn.id ++ "=" ++ expressionTag(row.rendered.turn))->Js.Array2.joinWith("|")))
  addNumber(root, "local_dialogue_tempo", dialogueTempo)
  addString(root, "music_model", "music_v2")
  addString(root, "sfx_source", "ElevenLabs eleven_text_to_sound_v2")
  addString(root, "prohibited_content_audit", "The attack is not reenacted. Authored effects contain only ordinary school texture, paper, soil digging, slate, and furniture.")
  Js.Dict.set(root, "chapters", Js.Json.array(chapters->Belt.Array.map(chapterJson)))
  Js.Dict.set(root, "dialogue", Js.Json.array(turns->Belt.Array.map(timelineTurnJson)))
  Js.Dict.set(root, "sound_cues", Js.Json.array(cues->Belt.Array.map(timelineCueJson)))
  Js.Dict.set(root, "sfx_placements", Js.Json.array(placements->Belt.Array.map(placementJson)))
  Js.Dict.set(root, "music", Js.Json.array(music->Belt.Array.map(((spec, raw, stem, seconds)) => {
    let row = Js.Dict.empty()
    addString(row, "id", spec.id)
    addString(row, "model", "music_v2")
    addString(row, "request_sha256", musicHash(spec))
    addString(row, "raw_provider_asset", raw)
    addString(row, "raw_provider_sha256", sha256File(Path(raw)))
    addString(row, "normalized_stem", stem)
    addString(row, "normalized_stem_sha256", sha256File(Path(stem)))
    addNumber(row, "provider_duration_seconds", seconds)
    addString(row, "prompt", spec.prompt)
    Js.Json.object_(row)
  })))
  Js.Dict.set(root, "generated_sfx", Js.Json.array(sfx->Belt.Array.map(((spec, raw, stem, seconds)) => {
    let row = Js.Dict.empty()
    addString(row, "id", spec.id)
    addString(row, "model", "eleven_text_to_sound_v2")
    addString(row, "request_sha256", sfxHash(spec))
    addString(row, "raw_provider_asset", raw)
    addString(row, "raw_provider_sha256", sha256File(Path(raw)))
    addString(row, "normalized_stem", stem)
    addString(row, "normalized_stem_sha256", sha256File(Path(stem)))
    addNumber(row, "provider_duration_seconds", seconds)
    addNumber(row, "prompt_influence", spec.influence)
    addString(row, "prompt", spec.prompt)
    Js.Json.object_(row)
  })))
  writeText(Path(manifestPath), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n")
}

let qc = (): unit => {
  let wavDuration = validateAudio(finalWavPath, "final WAV master")
  let m4aDuration = validateAudio(finalM4aPath, "final M4A review file")
  if wavDuration < 1620.0 || wavDuration > 1800.0 {
    fail("final runtime is outside the approved 27–30 minute window: " ++ Js.Float.toString(wavDuration))
  }
  if Js.Math.abs_float(wavDuration -. m4aDuration) > 0.10 {
    fail("WAV/M4A duration mismatch exceeds 0.10 seconds")
  }
  let decode = run(~cmd="ffmpeg", ~args=["-nostdin", "-v", "error", "-i", finalWavPath, "-f", "null", "-"])
  if decode.code != 0 {
    fail("final decode QC failed: " ++ decode.stderr)
  }
  let silence = run(
    ~cmd="ffmpeg",
    ~args=["-nostdin", "-hide_banner", "-i", finalWavPath, "-af", "silencedetect=noise=-55dB:d=6", "-f", "null", "-"],
  )
  if contains(silence.stderr, "silence_duration:") {
    fail("final QC found an unintended silence of six seconds or longer")
  }
  let peak = run(
    ~cmd="ffmpeg",
    ~args=["-nostdin", "-hide_banner", "-i", finalWavPath, "-af", "volumedetect", "-f", "null", "-"],
  )
  Js.log("QC decode PASS; runtime PASS; no >=6s silence. " ++
    peak.stderr->Js.String2.split("\n")->Belt.Array.keep(line => contains(line, "max_volume"))->Js.Array2.joinWith(" "))
}

let main = async (): unit => {
  let (events, turns, cues) = parseScript()
  writePlan(~turns, ~cues)
  if envDry == Some("1") {
    Js.log("DRY run — zero paid calls, zero generated audio.")
  } else {
    let renderedTurns = await renderDialogue(turns)
    let (timelineCues, timelineTurns, chapters, voiceDuration) = buildVoiceTimeline(~events, ~rendered=renderedTurns)
    if voiceDuration < 1620.0 || voiceDuration > 1800.0 {
      fail(
        "V5 voice timeline is outside 27–30 minutes; paid SFX and music were not started. Duration: " ++
        Js.Float.toString(voiceDuration),
      )
    }
    let renderedSfx = await renderSfx()
    let renderedMusic = await renderMusic()
    let placements = sfxPlacements(~cues=timelineCues, ~sfx=renderedSfx)
    buildSfxStem(~placements, ~duration=voiceDuration)
    buildScoreStemV5(~music=renderedMusic, ~cues=timelineCues, ~duration=voiceDuration)
    finalMix(~duration=voiceDuration)
    let finalDuration = validateAudio(finalWavPath, "final master")
    qc()
    writeManifest(
      ~turns=timelineTurns,
      ~cues=timelineCues,
      ~chapters,
      ~placements,
      ~music=renderedMusic,
      ~sfx=renderedSfx,
      ~duration=finalDuration,
    )
    Js.log("MASTER WAV -> " ++ finalWavPath)
    Js.log("MASTER M4A -> " ++ finalM4aPath)
    Js.log("MANIFEST -> " ++ manifestPath)
  }
}

main()
->Js.Promise2.catch(error => {
  Js.log2("ENOCH AUDIO FAILED:", error)
  exit(1)
  Js.Promise.resolve()
})
->ignore
