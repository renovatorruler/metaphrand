/* Enoch Brown V8 cold-open-only production proof.

   This driver can buy only the ten approved narrator turns. All sound effects
   and music are immutable, hash-pinned ElevenLabs masters from V7/V5. A dry
   run validates those bytes and writes the exact content-addressed spend plan.

   From studio/:
     DRY=1 node src/EnochBrown_ColdOpenV8.res.mjs
     PAID=1 GENERATE_TTS=1 APPROVED_PLAN_SHA256=<dry-plan-hash> \
       node src/EnochBrown_ColdOpenV8.res.mjs
*/

open Cinema_Backends
module Core = EnochBrown_ColdOpenV8Core

@val @scope(("process", "env")) external envDry: option<string> = "DRY"
@val @scope(("process", "env")) external envPaid: option<string> = "PAID"
@val @scope(("process", "env")) external envGenerateTts: option<string> = "GENERATE_TTS"
@val @scope(("process", "env")) external envApprovedPlan: option<string> = "APPROVED_PLAN_SHA256"
@val @scope(("process", "env")) external envRecoverNetworkTts: option<string> = "RECOVER_NETWORK_TTS"
@val @scope("process") external exit: int => unit = "exit"

exception ColdOpenAudio(string)

let pipelineVersion = "enoch-brown-cold-open-v8.0.0"
let assemblyVersion = "enoch-brown-cold-open-v8-assembly-v1.0.0"
let scriptPath = "../stories/enoch-brown/script/DOCUMENTARY_COLD_OPEN_v8.md"
let approvedScriptSha256 = "06a3e5b55183841381897c0b07d26077d286bce6e5bb72b691c76ecbc47b65a0"
let projectDir = "../stories/enoch-brown/production/audio_v8_cold_open"
let cacheDir = projectDir ++ "/cache"
let rawDialogueDir = cacheDir ++ "/provider_raw/dialogue"
let claimDir = cacheDir ++ "/paid_claims"
let outDir = projectDir ++ "/mix"
let planDir = projectDir ++ "/plans"
let reviewDir = projectDir ++ "/review"

let narratorVoiceId = "PKu46bbccMP1b22TyeI0"
let narratorVoiceName = "Jacob Michael / Bishop — author selected"
let initialLead = 2.00
let reviewTail = 6.0
let maxNewTtsRequests = 10
let maxNewTtsCharacters = 2800

type performanceProfile =
  | Conversational
  | Inquiry
  | Investigative
  | Pressure
  | FactualLanding
  | Reversal
  | Evidence
  | DateLanding
  | Title

type directive = {
  stage: Core.revealStage,
  profile: performanceProfile,
  intention: string,
  tag: string,
  settings: productionVoiceSettings,
  seed: int,
  gapAfter: float,
}

type turn = {
  id: string,
  text: string,
  stage: Core.revealStage,
  profile: performanceProfile,
  intention: string,
  tag: string,
  settings: productionVoiceSettings,
  seed: int,
  gapAfter: float,
}

type renderedTurn = {
  turn: turn,
  requestHash: string,
  rawPath: string,
  duration: float,
}

type loudnessStats = {
  integrated: float,
  truePeak: float,
  lra: float,
}

type assetKind = Sfx | Music

type reusedAsset = {
  id: string,
  kind: assetKind,
  path: string,
  receiptPath: string,
  model: string,
  requestSha256: string,
  assetSha256: string,
  duration: float,
}

let fail = (message: string): 'a => raise(ColdOpenAudio(message))
let trim = Js.String2.trim
let starts = (value: string, prefix: string): bool => Js.String2.startsWith(value, prefix)
let contains = (value: string, fragment: string): bool => Js.String2.includes(value, fragment)
let lower = Js.String2.toLowerCase
let secondsValue = (Seconds(value)): float => value
let pathString = (Path(value)): string => value
let shortHash = (hash: string): string => Js.String2.slice(hash, ~from=0, ~to_=20)
let floatMin = (a: float, b: float): float => a < b ? a : b

let profileName = profile => switch profile {
| Conversational => "conversational"
| Inquiry => "inquiry"
| Investigative => "investigative"
| Pressure => "pressure"
| FactualLanding => "factual-landing"
| Reversal => "reversal"
| Evidence => "evidence"
| DateLanding => "date-landing"
| Title => "title"
}

let assetKindName = kind => switch kind {
| Sfx => "sfx"
| Music => "music"
}

let directives: array<directive> = [
  {stage: Core.Ordinary, profile: Conversational, intention: "Let the listener recognize a school immediately.", tag: "", settings: {stability: 0.43, speed: 1.00}, seed: 17640831, gapAfter: 0.80},
  {stage: Core.Silence, profile: Inquiry, intention: "Replace recognition with an uneasy question.", tag: "[curious]", settings: {stability: 0.34, speed: 0.99}, seed: 17640837, gapAfter: 1.60},
  {stage: Core.Passerby, profile: Investigative, intention: "Turn uncertainty into a physical threshold.", tag: "", settings: {stability: 0.37, speed: 1.00}, seed: 17640843, gapAfter: 1.70},
  {stage: Core.Threshold, profile: Pressure, intention: "Put the decision directly to the listener, then act.", tag: "[tense]", settings: {stability: 0.34, speed: 1.01}, seed: 17640849, gapAfter: 1.50},
  {stage: Core.Discovery, profile: FactualLanding, intention: "State the discovery plainly; do not perform grief.", tag: "", settings: {stability: 0.49, speed: 0.98}, seed: 17640855, gapAfter: 1.25},
  {stage: Core.Survivor, profile: Reversal, intention: "Land the survivor as a reversal.", tag: "", settings: {stability: 0.39, speed: 0.99}, seed: 17640861, gapAfter: 1.50},
  {stage: Core.Eyewitness, profile: Evidence, intention: "Deliver the attributed clue and scale without melodrama.", tag: "", settings: {stability: 0.44, speed: 1.00}, seed: 17640867, gapAfter: 1.80},
  {stage: Core.Reframe, profile: Inquiry, intention: "Turn the listener's assumed time period against the story.", tag: "", settings: {stability: 0.36, speed: 0.99}, seed: 17640873, gapAfter: 2.50},
  {stage: Core.DateReveal, profile: DateLanding, intention: "Let the year alter everything already heard.", tag: "[serious]", settings: {stability: 0.50, speed: 0.98}, seed: 17640879, gapAfter: 2.50},
  {stage: Core.TitleReveal, profile: Title, intention: "State the title cleanly and leave the question hanging.", tag: "", settings: {stability: 0.46, speed: 0.99}, seed: 17640885, gapAfter: 0.0},
]

let reusedAssets: array<reusedAsset> = [
  {
    id: "historical_schoolyard",
    kind: Sfx,
    path: "../stories/enoch-brown/production/audio_v7/cache/provider_raw/sfx/historical_schoolyard_faebc8d299e1faea.mp3",
    receiptPath: "../stories/enoch-brown/production/audio_v7/cache/provider_raw/sfx/historical_schoolyard_faebc8d299e1faea.mp3.receipt.json",
    model: "eleven_text_to_sound_v2",
    requestSha256: "faebc8d299e1faeaf8c2e2867f1dc480f9fb8620b93ed80d8d548ef3b38bc6cf",
    assetSha256: "b6f5f12b9c33395c7d335dcddd93784b40d0d6fa18f09ddea9eaa000744fa6dc",
    duration: 12.0,
  },
  {
    id: "summer_outdoors",
    kind: Sfx,
    path: "../stories/enoch-brown/production/audio_v7/cache/provider_raw/sfx/summer_outdoors_f9ba2ae6acee5070.mp3",
    receiptPath: "../stories/enoch-brown/production/audio_v7/cache/provider_raw/sfx/summer_outdoors_f9ba2ae6acee5070.mp3.receipt.json",
    model: "eleven_text_to_sound_v2",
    requestSha256: "f9ba2ae6acee50704b56ed45c7031a04f14fe8a5454d32169619e8033836057c",
    assetSha256: "06a64b775f19c090c18f939119082ccd6c703db20ba03778e52499a468ad1202",
    duration: 12.0,
  },
  {
    id: "packed_earth_footsteps",
    kind: Sfx,
    path: "../stories/enoch-brown/production/audio_v7/cache/provider_raw/sfx/packed_earth_footsteps_c902d902f492ce34.mp3",
    receiptPath: "../stories/enoch-brown/production/audio_v7/cache/provider_raw/sfx/packed_earth_footsteps_c902d902f492ce34.mp3.receipt.json",
    model: "eleven_text_to_sound_v2",
    requestSha256: "c902d902f492ce34a848728faa164c572d4f5fcfcf3620c4980366daca51b78f",
    assetSha256: "72154077eaaff9fc2f2dc5bc09f1063b1bd1472a5599636447ad4a22092721f1",
    duration: 8.0,
  },
  {
    id: "weapon_question",
    kind: Music,
    path: "../stories/enoch-brown/production/audio_v5/cache/provider_raw/music/weapon_question_5d903d10e4970255.mp3",
    receiptPath: "../stories/enoch-brown/production/audio_v5/cache/provider_raw/music/weapon_question_5d903d10e4970255.mp3.receipt.json",
    model: "music_v2",
    requestSha256: "5d903d10e497025531f472392fa4650e2f16f0de68aafd0293bb45ed4e99ca7d",
    assetSha256: "600f3872e0eb5782f57329e78da3456cf88466bd3387f7c2137bc0e8499e16db",
    duration: 120.024,
  },
  {
    id: "title_motif",
    kind: Music,
    path: "../stories/enoch-brown/production/audio_v5/cache/provider_raw/music/title_motif_09eee12c81d24680.mp3",
    receiptPath: "../stories/enoch-brown/production/audio_v5/cache/provider_raw/music/title_motif_09eee12c81d24680.mp3.receipt.json",
    model: "music_v2",
    requestSha256: "09eee12c81d246807ea1596537378ea9e0eebe93d69c50709c2be12279089d47",
    assetSha256: "b71b302195708c453a61287c2d2795af6f834eb0d4cc08cbebe407fb7d0dcc20",
    duration: 90.024,
  },
]

let holds: array<Core.holdSpec> = [{
  id: "H001_DISCOVERY_HOLD",
  afterTurnId: "CO005",
  seconds: 1.25,
  reason: "Let the discovery register before revealing the surviving pupil; unscored and without reenactment.",
}]

let sfxSpecs: array<Core.clipCue> = [
  {id: "S001_SCHOOLYARD", assetId: "historical_schoolyard", mode: Core.Transition, anchor: Core.Absolute(0.0), length: Core.Fixed(10.0), trimStart: 0.0, gainDb: -2.0, fadeIn: 0.08, fadeOut: 0.60},
  {id: "S002_COUNTRYSIDE_A", assetId: "summer_outdoors", mode: Core.Bed, anchor: Core.TurnStart("CO002", -0.15), length: Core.Fixed(12.0), trimStart: 0.0, gainDb: -7.0, fadeIn: 0.35, fadeOut: 0.60},
  {id: "S003_COUNTRYSIDE_B", assetId: "summer_outdoors", mode: Core.Bed, anchor: Core.TurnStart("CO002", 11.50), length: Core.Fixed(8.50), trimStart: 3.50, gainDb: -9.0, fadeIn: 0.35, fadeOut: 0.60},
  {id: "S004_COUNTRYSIDE_C", assetId: "summer_outdoors", mode: Core.Bed, anchor: Core.TurnStart("CO003", -0.10), length: Core.Fixed(12.0), trimStart: 0.0, gainDb: -9.0, fadeIn: 0.35, fadeOut: 0.60},
  {id: "S005_COUNTRYSIDE_D", assetId: "summer_outdoors", mode: Core.Bed, anchor: Core.TurnStart("CO003", 10.00), length: Core.Fixed(12.0), trimStart: 0.0, gainDb: -10.0, fadeIn: 0.35, fadeOut: 0.60},
  {id: "S006_COUNTRYSIDE_E", assetId: "summer_outdoors", mode: Core.Bed, anchor: Core.TurnEnd("CO005", -5.50), length: Core.Fixed(5.50), trimStart: 0.0, gainDb: -11.0, fadeIn: 0.35, fadeOut: 0.80},
  {id: "S007_FOOTSTEPS", assetId: "packed_earth_footsteps", mode: Core.Bed, anchor: Core.TurnStart("CO004", 0.0), length: Core.Fixed(8.0), trimStart: 0.0, gainDb: -4.0, fadeIn: 0.08, fadeOut: 0.45},
]

let musicSpecs: array<Core.clipCue> = [
  {id: "M001_UNRESOLVED_BED", assetId: "weapon_question", mode: Core.Bed, anchor: Core.TurnEnd("CO006", 0.05), length: Core.ToEnd(0.0), trimStart: 0.0, gainDb: -5.0, fadeIn: 1.2, fadeOut: 2.0},
  {id: "M002_TITLE_HIT", assetId: "title_motif", mode: Core.Hit, anchor: Core.TurnStart("CO010", -0.40), length: Core.Fixed(2.20), trimStart: 0.0, gainDb: -3.0, fadeIn: 0.25, fadeOut: 0.20},
  {id: "M003_TITLE_TAIL", assetId: "title_motif", mode: Core.Tail, anchor: Core.TurnEnd("CO010", 0.0), length: Core.ToEnd(0.0), trimStart: 2.20, gainDb: -4.0, fadeIn: 0.05, fadeOut: 2.5},
]

let jsonString = value => Js.Json.string(value)
let jsonNumber = value => Js.Json.number(value)
let addString = (root: Js.Dict.t<Js.Json.t>, key: string, value: string): unit =>
  Js.Dict.set(root, key, jsonString(value))
let addNumber = (root: Js.Dict.t<Js.Json.t>, key: string, value: float): unit =>
  Js.Dict.set(root, key, jsonNumber(value))
let addBool = (root: Js.Dict.t<Js.Json.t>, key: string, value: bool): unit =>
  Js.Dict.set(root, key, Js.Json.boolean(value))

let stringField = (json: Js.Json.t, key: string): string =>
  json
  ->Js.Json.decodeObject
  ->Belt.Option.flatMap(object_ => Js.Dict.get(object_, key))
  ->Belt.Option.flatMap(Js.Json.decodeString)
  ->Belt.Option.getWithDefault("")

let numberField = (json: Js.Json.t, key: string): float =>
  json
  ->Js.Json.decodeObject
  ->Belt.Option.flatMap(object_ => Js.Dict.get(object_, key))
  ->Belt.Option.flatMap(Js.Json.decodeNumber)
  ->Belt.Option.getWithDefault(-1.0)

let cleanSpeech = (value: string): string =>
  value
  ->Js.String2.replaceByRe(%re("/[\*`]/g"), "")
  ->Js.String2.replaceByRe(%re("/\s+/g"), " ")
  ->trim

let isControl = (line: string): bool =>
  starts(line, "SOUND ") || starts(line, "MUSIC ") || starts(line, "FACTS:") ||
  line == "NARRATOR:" || starts(line, "## ") || line == "---" || line == "END."

let parseScript = (): array<turn> => {
  if !exists(Path(scriptPath)) {
    fail("cold-open script is missing: " ++ scriptPath)
  }
  let actualHash = sha256File(Path(scriptPath))
  if actualHash != approvedScriptSha256 {
    fail("approved cold-open script changed; expected " ++ approvedScriptSha256 ++ ", got " ++ actualHash)
  }
  let lines = readText(Path(scriptPath))->Js.String2.split("\n")
  let texts: array<string> = []
  let active = ref(false)
  let index = ref(0)
  while index.contents < Belt.Array.length(lines) {
    let line = trim(Belt.Array.getExn(lines, index.contents))
    if starts(line, "## COLD OPEN") {
      active := true
      index := index.contents + 1
    } else if active.contents && line == "NARRATOR:" {
      let collected: array<string> = []
      let next = ref(index.contents + 1)
      while next.contents < Belt.Array.length(lines) && !isControl(trim(Belt.Array.getExn(lines, next.contents))) {
        Js.Array2.push(collected, Belt.Array.getExn(lines, next.contents))->ignore
        next := next.contents + 1
      }
      let text = cleanSpeech(Js.Array2.joinWith(collected, "\n"))
      if text == "" {
        fail("empty narrator block in cold-open script")
      }
      Js.Array2.push(texts, text)->ignore
      index := next.contents
    } else {
      index := index.contents + 1
    }
  }
  if Belt.Array.length(texts) != 10 || Belt.Array.length(directives) != 10 {
    fail("V8 proof requires exactly ten short narrator turns")
  }
  texts->Belt.Array.mapWithIndex((index, text) => {
    let directive = Belt.Array.getExn(directives, index)
    {
      id: "CO" ++ (index + 1 < 10 ? "00" : "0") ++ Belt.Int.toString(index + 1),
      text,
      stage: directive.stage,
      profile: directive.profile,
      intention: directive.intention,
      tag: directive.tag,
      settings: directive.settings,
      seed: directive.seed,
      gapAfter: directive.gapAfter,
    }
  })
}

let providerText = (turn: turn): string => turn.tag == "" ? turn.text : turn.tag ++ " " ++ turn.text

let wordsIn = (value: string): int =>
  value->trim == "" ? 0 : value->trim->Js.String2.splitByRe(%re("/\s+/"))->Belt.Array.length

let requestSignature = (turn: turn): string => Js.Array2.joinWith([
  "model=eleven_v3",
  "output_format=wav_48000",
  "language_code=en",
  "apply_text_normalization=on",
  "voice=" ++ narratorVoiceId,
  "seed=" ++ Belt.Int.toString(turn.seed),
  "stability=" ++ Js.Float.toString(turn.settings.stability),
  "speed=" ++ Js.Float.toString(turn.settings.speed),
  "text=" ++ providerText(turn),
], "|")

let requestHash = (turn: turn): string => sha256Text(requestSignature(turn))
let rawPathFor = (turn: turn): string =>
  rawDialogueDir ++ "/" ++ turn.id ++ "_" ++ shortHash(requestHash(turn)) ++ ".wav"

let assetById = (id: string): reusedAsset => switch Belt.Array.getBy(reusedAssets, asset => asset.id == id) {
| Some(asset) => asset
| None => fail("unknown reused asset " ++ id)
}

let validateAudio = (path: string, label: string): float => {
  if !exists(Path(path)) {
    fail(label ++ " is missing: " ++ path)
  }
  let decode = run(~cmd="ffmpeg", ~args=["-nostdin", "-v", "error", "-i", path, "-f", "null", "-"])
  if decode.code != 0 {
    fail(label ++ " does not decode: " ++ Js.String2.slice(decode.stderr, ~from=0, ~to_=320))
  }
  let duration = probeDuration(Path(path))->secondsValue
  if duration <= 0.2 {
    fail(label ++ " has invalid duration")
  }
  duration
}

let validateReusedAssets = (): unit => reusedAssets->Belt.Array.forEach(asset => {
  if !exists(Path(asset.path)) || !exists(Path(asset.receiptPath)) {
    fail("required immutable " ++ assetKindName(asset.kind) ++ " asset or receipt is missing: " ++ asset.id)
  }
  if sha256File(Path(asset.path)) != asset.assetSha256 {
    fail("reused asset bytes changed: " ++ asset.id)
  }
  let receipt = Js.Json.parseExn(readText(Path(asset.receiptPath)))
  if stringField(receipt, "model") != asset.model ||
     stringField(receipt, "request_sha256") != asset.requestSha256 ||
     stringField(receipt, "asset_sha256") != asset.assetSha256 {
    fail("reused asset receipt does not match its pin: " ++ asset.id)
  }
  let duration = validateAudio(asset.path, "reused " ++ asset.id)
  if Js.Math.abs_float(duration -. asset.duration) > 0.08 ||
     Js.Math.abs_float(numberField(receipt, "duration_seconds") -. asset.duration) > 0.08 {
    fail("reused asset duration changed: " ++ asset.id)
  }
})

let validateTurns = (turns: array<turn>): unit => {
  let staged: array<Core.stagedText> = turns->Belt.Array.map(turn => {
    let row: Core.stagedText = {id: turn.id, stage: turn.stage, text: turn.text}
    row
  })
  Core.validateRevealOrder(staged)
  let profileNames = turns->Belt.Array.map(turn => profileName(turn.profile))
  let uniqueProfiles = profileNames->Belt.Array.reduce([], (rows: array<string>, name) => {
    if Belt.Array.some(rows, existing => existing == name) {
      rows
    } else {
      Js.Array2.concat(rows, [name])
    }
  })
  if Belt.Array.length(uniqueProfiles) < 4 {
    fail("V8 requires at least four distinct performance profiles")
  }
  let tagged = turns->Belt.Array.keep(turn => turn.tag != "")
  if Belt.Array.length(tagged) != 3 {
    fail("V8 performance map requires exactly three sparse expression tags")
  }
  turns->Belt.Array.forEach(turn => {
    if wordsIn(turn.text) > 90 || Js.String2.length(providerText(turn)) > 700 {
      fail("thought-based turn is too long: " ++ turn.id)
    }
    if trim(turn.intention) == "" {
      fail("performance intention is missing: " ++ turn.id)
    }
    if contains(lower(providerText(turn)), "[whisper") || contains(lower(providerText(turn)), "[slowly]") {
      fail("sleepy performance direction is forbidden: " ++ turn.id)
    }
  })
}

let estimateDuration = (turn: turn): float =>
  /* Calibrated from the ten approved Jacob Michael V3 turns in this proof. */
  Belt.Int.toFloat(wordsIn(turn.text)) /. (2.75 *. turn.settings.speed)

let timelineInputs = (~turns: array<turn>, ~durations: array<float>): array<Core.turnInput> => {
  if Belt.Array.length(turns) != Belt.Array.length(durations) {
    fail("turn/duration cardinality mismatch")
  }
  turns->Belt.Array.mapWithIndex((index, turn) => {
    let row: Core.turnInput = {
      id: turn.id,
      duration: Belt.Array.getExn(durations, index),
      gapAfter: turn.gapAfter,
    }
    row
  })
}

let masterDurationFor = (timeline: array<Core.turnWindow>): float =>
  Belt.Array.getExn(timeline, Belt.Array.length(timeline) - 1).end_ +. reviewTail

let resolveAll = (~timeline: array<Core.turnWindow>, ~masterDuration: float) => {
  let sfx = sfxSpecs->Belt.Array.map(spec => Core.resolveClip(~turns=timeline, ~masterDuration, spec))
  let music = musicSpecs->Belt.Array.map(spec => Core.resolveClip(~turns=timeline, ~masterDuration, spec))
  (sfx, music)
}

let validateSourceLengths = (clips: array<Core.resolvedClip>): unit => clips->Belt.Array.forEach(clip => {
  let asset = assetById(clip.spec.assetId)
  let used = clip.spec.trimStart +. clip.end_ -. clip.start
  if used > asset.duration +. 0.01 {
    fail("cue " ++ clip.spec.id ++ " exceeds source " ++ asset.id)
  }
})

let validateTimeline = (
  ~turns: array<turn>,
  ~inputs: array<Core.turnInput>,
  ~timeline: array<Core.turnWindow>,
  ~masterDuration: float,
): (array<Core.resolvedClip>, array<Core.resolvedClip>, array<Core.holdWindow>, float) => {
  let titleStart = Core.findTurn(timeline, "CO010").start
  if titleStart < 110.0 || titleStart > 130.0 {
    fail("title must land between 1:50 and 2:10; got " ++ Js.Float.toFixedWithPrecision(titleStart, ~digits=3))
  }
  if masterDuration > 135.0 {
    fail("cold-open proof must end by 2:15; got " ++ Js.Float.toFixedWithPrecision(masterDuration, ~digits=3))
  }
  Core.validateAnomalyTiming(~turns=timeline, ~silenceTurnId="CO002")
  timeline->Belt.Array.forEachWithIndex((index, window) => {
    if window.end_ -. window.start > 35.0 {
      fail("rendered thought exceeds 35 seconds: " ++ Belt.Array.getExn(turns, index).id)
    }
  })
  let (sfx, music) = resolveAll(~timeline, ~masterDuration)
  validateSourceLengths(sfx)
  validateSourceLengths(music)
  let overlap = Core.validateSfxOverlap(~turns=timeline, ~clips=sfx)
  let holdWindows = Core.resolveHolds(~turns=timeline, ~turnInputs=inputs, ~holds)
  Core.validateHoldsAreEmpty(~holds=holdWindows, ~clips=Js.Array2.concat(sfx, music))
  (sfx, music, holdWindows, overlap)
}

let anchorSignature = anchor => switch anchor {
| Core.Absolute(seconds) => "absolute:" ++ Js.Float.toString(seconds)
| Core.TurnStart(id, offset) => "turn-start:" ++ id ++ ":" ++ Js.Float.toString(offset)
| Core.TurnEnd(id, offset) => "turn-end:" ++ id ++ ":" ++ Js.Float.toString(offset)
}

let lengthSignature = length => switch length {
| Core.Fixed(seconds) => "fixed:" ++ Js.Float.toString(seconds)
| Core.ToEnd(before) => "to-end:" ++ Js.Float.toString(before)
}

let clipSpecSignature = (spec: Core.clipCue): string => Js.Array2.joinWith([
  spec.id,
  spec.assetId,
  Core.modeName(spec.mode),
  anchorSignature(spec.anchor),
  lengthSignature(spec.length),
  Js.Float.toString(spec.trimStart),
  Js.Float.toString(spec.gainDb),
  Js.Float.toString(spec.fadeIn),
  Js.Float.toString(spec.fadeOut),
], "|")

let planSignature = (turns: array<turn>): string => Js.Array2.joinWith([
  pipelineVersion,
  assemblyVersion,
  approvedScriptSha256,
  turns->Belt.Array.map(turn => Js.Array2.joinWith([
    turn.id,
    Core.stageName(turn.stage),
    profileName(turn.profile),
    turn.intention,
    turn.tag,
    Js.Float.toString(turn.settings.stability),
    Js.Float.toString(turn.settings.speed),
    Belt.Int.toString(turn.seed),
    Js.Float.toString(turn.gapAfter),
    requestHash(turn),
  ], "~"))->Js.Array2.joinWith("||"),
  sfxSpecs->Belt.Array.map(clipSpecSignature)->Js.Array2.joinWith("||"),
  musicSpecs->Belt.Array.map(clipSpecSignature)->Js.Array2.joinWith("||"),
  reusedAssets->Belt.Array.map(asset => asset.id ++ "=" ++ asset.requestSha256 ++ "=" ++ asset.assetSha256)->Js.Array2.joinWith("||"),
  holds->Belt.Array.map(hold => hold.id ++ "=" ++ hold.afterTurnId ++ "=" ++ Js.Float.toString(hold.seconds) ++ "=" ++ hold.reason)->Js.Array2.joinWith("||"),
  Core.masterMixConfig,
], "###")

let turnPlanJson = (turn: turn): Js.Json.t => {
  let root = Js.Dict.empty()
  addString(root, "id", turn.id)
  addString(root, "stage", Core.stageName(turn.stage))
  addString(root, "profile", profileName(turn.profile))
  addString(root, "intention", turn.intention)
  addString(root, "expression_tag", turn.tag)
  addNumber(root, "stability", turn.settings.stability)
  addNumber(root, "speed", turn.settings.speed)
  addNumber(root, "seed", Belt.Int.toFloat(turn.seed))
  addNumber(root, "gap_after_seconds", turn.gapAfter)
  addNumber(root, "words", Belt.Int.toFloat(wordsIn(turn.text)))
  addNumber(root, "characters", Belt.Int.toFloat(Js.String2.length(providerText(turn))))
  addNumber(root, "estimated_seconds", estimateDuration(turn))
  addString(root, "request_sha256", requestHash(turn))
  addString(root, "raw_cache", rawPathFor(turn))
  addString(root, "source_text", turn.text)
  addString(root, "provider_text", providerText(turn))
  Js.Json.object_(root)
}

let assetJson = (asset: reusedAsset): Js.Json.t => {
  let root = Js.Dict.empty()
  addString(root, "id", asset.id)
  addString(root, "kind", assetKindName(asset.kind))
  addString(root, "model", asset.model)
  addString(root, "source", asset.path)
  addString(root, "receipt", asset.receiptPath)
  addString(root, "request_sha256", asset.requestSha256)
  addString(root, "asset_sha256", asset.assetSha256)
  addNumber(root, "duration_seconds", asset.duration)
  addBool(root, "new_paid_call", false)
  Js.Json.object_(root)
}

let clipSpecJson = (spec: Core.clipCue): Js.Json.t => {
  let root = Js.Dict.empty()
  addString(root, "id", spec.id)
  addString(root, "asset_id", spec.assetId)
  addString(root, "mode", Core.modeName(spec.mode))
  addString(root, "anchor", anchorSignature(spec.anchor))
  addString(root, "length", lengthSignature(spec.length))
  addNumber(root, "trim_start_seconds", spec.trimStart)
  addNumber(root, "gain_db", spec.gainDb)
  addNumber(root, "fade_in_seconds", spec.fadeIn)
  addNumber(root, "fade_out_seconds", spec.fadeOut)
  Js.Json.object_(root)
}

let writePlan = (
  ~turns: array<turn>,
  ~estimatedTimeline: array<Core.turnWindow>,
  ~estimatedMaster: float,
  ~estimatedOverlap: float,
): string => {
  let signature = planSignature(turns)
  let planHash = sha256Text(signature)
  ensureDirPath(Path(planDir))
  let path = planDir ++ "/ENOCH_BROWN_COLD_OPEN_V8_PLAN_" ++ shortHash(planHash) ++ ".json"
  let missing = turns->Belt.Array.keep(turn => !exists(Path(rawPathFor(turn))))
  let missingChars = missing->Belt.Array.reduce(0, (total, turn) => total + Js.String2.length(providerText(turn)))
  let root = Js.Dict.empty()
  addString(root, "schema", "enoch.cold-open-audio-plan/v8")
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "assembly_version", assemblyVersion)
  addString(root, "canonical_script", scriptPath)
  addString(root, "canonical_script_sha256", approvedScriptSha256)
  addString(root, "plan_sha256", planHash)
  addString(root, "narrator", narratorVoiceName)
  addString(root, "voice_id", narratorVoiceId)
  addString(root, "speech_model", "eleven_v3")
  addString(root, "speech_output", "wav_48000")
  addString(root, "mix_policy", "Independent narration, SFX, and music lanes; SFX and music sidechain under narration; no sound cue advances dialogue.")
  addString(root, "normalization_policy", "No per-clip dialogue loudness normalization; one assembled voice-lane normalization.")
  addNumber(root, "initial_sound_lead_seconds", initialLead)
  addNumber(root, "estimated_title_start_seconds", Core.findTurn(estimatedTimeline, "CO010").start)
  addNumber(root, "estimated_proof_end_seconds", estimatedMaster)
  addNumber(root, "estimated_ordinary_sfx_overlap_fraction", estimatedOverlap)
  addString(root, "timing_gate", "Title 110–130 seconds; proof end at or before 135 seconds; speech is never stretched to satisfy the gate.")
  addNumber(root, "missing_tts_requests", Belt.Int.toFloat(Belt.Array.length(missing)))
  addNumber(root, "missing_tts_characters", Belt.Int.toFloat(missingChars))
  addNumber(root, "maximum_new_tts_requests", Belt.Int.toFloat(maxNewTtsRequests))
  addNumber(root, "maximum_new_tts_characters", Belt.Int.toFloat(maxNewTtsCharacters))
  addNumber(root, "new_sfx_requests", 0.0)
  addNumber(root, "new_music_requests", 0.0)
  addString(root, "paid_gate", "PAID=1 + GENERATE_TTS=1 + APPROVED_PLAN_SHA256 equal to this plan hash; DRY=1 always wins")
  Js.Dict.set(root, "turns", Js.Json.array(turns->Belt.Array.map(turnPlanJson)))
  Js.Dict.set(root, "reused_assets", Js.Json.array(reusedAssets->Belt.Array.map(assetJson)))
  Js.Dict.set(root, "sfx_cues", Js.Json.array(sfxSpecs->Belt.Array.map(clipSpecJson)))
  Js.Dict.set(root, "music_cues", Js.Json.array(musicSpecs->Belt.Array.map(clipSpecJson)))
  let text = Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n"
  if exists(Path(path)) {
    if readText(Path(path)) != text {
      fail("content-addressed plan path contains different bytes: " ++ path)
    }
  } else if !writeTextExclusive(Path(path), text) {
    fail("could not publish content-addressed plan: " ++ path)
  }
  Js.log("PLAN -> " ++ path)
  Js.log("PLAN SHA-256 -> " ++ planHash)
  Js.log("MISSING TTS -> " ++ Belt.Int.toString(Belt.Array.length(missing)) ++ " requests / " ++ Belt.Int.toString(missingChars) ++ " characters")
  Js.log("NEW SFX/MUSIC CALLS -> 0 / 0")
  planHash
}

let claimPaid = (~turn: turn, ~hash: string): unit => {
  ensureDirPath(Path(claimDir))
  let path = claimDir ++ "/tts_" ++ hash ++ ".claim.json"
  let root = Js.Dict.empty()
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "kind", "tts")
  addString(root, "turn_id", turn.id)
  addString(root, "request_sha256", hash)
  addString(root, "policy", "An existing claim with no cached output is an uncertain paid attempt; automatic retry is forbidden.")
  if !writeTextExclusive(Path(path), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n") {
    if envRecoverNetworkTts == Some(turn.id) {
      let recoveryPath = claimDir ++ "/recovery_network_" ++ turn.id ++ "_" ++ hash ++ ".json"
      let recovery = Js.Dict.empty()
      addString(recovery, "pipeline_version", pipelineVersion)
      addString(recovery, "kind", "tts")
      addString(recovery, "turn_id", turn.id)
      addString(recovery, "request_sha256", hash)
      addString(recovery, "reason", "One controlled retry after the local sandbox failed DNS resolution with ENOTFOUND before reaching the provider.")
      addString(recovery, "policy", "This recovery receipt is exclusive. A second retry is blocked.")
      if !writeTextExclusive(Path(recoveryPath), Js.Json.stringifyWithSpace(Js.Json.object_(recovery), 1) ++ "\n") {
        fail("controlled network recovery already consumed for " ++ turn.id ++ "; refusing another retry")
      }
      Js.log("CONTROLLED NETWORK RECOVERY 1/1 " ++ turn.id)
    } else {
      fail("paid TTS attempt already claimed but cache is missing: " ++ turn.id)
    }
  }
}

let publishFetched = (~audio: blob, ~destination: string, ~label: string): float => {
  let scratch = tempDir("enoch-v8-tts-")->pathString
  let temporary = scratch ++ "/take.wav"
  writeBytes(Path(temporary), audio)->ignore
  let duration = validateAudio(temporary, label)
  if !publishFileExclusive(Path(temporary), Path(destination)) {
    fail("refusing to overwrite immutable provider take: " ++ destination)
  }
  duration
}

let writeProviderReceipt = (~turn: turn, ~path: string, ~duration: float): unit => {
  let receiptPath = path ++ ".receipt.json"
  let root = Js.Dict.empty()
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "kind", "tts")
  addString(root, "turn_id", turn.id)
  addString(root, "model", "eleven_v3")
  addString(root, "request_sha256", requestHash(turn))
  addString(root, "asset", path)
  addString(root, "asset_sha256", sha256File(Path(path)))
  addNumber(root, "duration_seconds", duration)
  if !writeTextExclusive(Path(receiptPath), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n") {
    fail("provider receipt already exists unexpectedly: " ++ receiptPath)
  }
}

let requirePaidPlan = (~planHash: string, ~missing: array<turn>): unit => {
  let missingChars = missing->Belt.Array.reduce(0, (total, turn) => total + Js.String2.length(providerText(turn)))
  if Belt.Array.length(missing) > maxNewTtsRequests || missingChars > maxNewTtsCharacters {
    fail("missing TTS work exceeds the cold-open paid ceiling")
  }
  if envDry == Some("1") || envPaid != Some("1") || envGenerateTts != Some("1") {
    fail("paid narration is locked; require PAID=1 and GENERATE_TTS=1 with DRY unset")
  }
  if envApprovedPlan != Some(planHash) {
    fail("APPROVED_PLAN_SHA256 does not match the dry plan")
  }
}

let renderDialogue = async (~turns: array<turn>, ~planHash: string): array<renderedTurn> => {
  ensureDirPath(Path(rawDialogueDir))
  let missing = turns->Belt.Array.keep(turn => !exists(Path(rawPathFor(turn))))
  if Belt.Array.length(missing) > 0 {
    requirePaidPlan(~planHash, ~missing)
  }
  let rendered: array<renderedTurn> = []
  let index = ref(0)
  while index.contents < Belt.Array.length(turns) {
    let turn = Belt.Array.getExn(turns, index.contents)
    let path = rawPathFor(turn)
    if !exists(Path(path)) {
      let hash = requestHash(turn)
      claimPaid(~turn, ~hash)
      Js.log("PAID V3 " ++ turn.id ++ " / " ++ Belt.Int.toString(Js.String2.length(providerText(turn))) ++ " characters")
      let audio = await productionTts(
        ~text=Text(providerText(turn)),
        ~voice=VoiceId(narratorVoiceId),
        ~seed=turn.seed,
        ~settings=turn.settings,
      )
      let duration = publishFetched(~audio, ~destination=path, ~label="V8 " ++ turn.id)
      writeProviderReceipt(~turn, ~path, ~duration)
    }
    let duration = validateAudio(path, "cached V8 " ++ turn.id)
    if duration > 35.0 {
      fail("rendered thought exceeds 35 seconds: " ++ turn.id)
    }
    Js.Array2.push(rendered, {turn, requestHash: requestHash(turn), rawPath: path, duration})->ignore
    index := index.contents + 1
  }
  rendered
}

let derivativeReceiptPath = path => path ++ ".manifest.json"

let verifyDerivative = (~path: string, ~fingerprint: string): bool => {
  let receiptPath = derivativeReceiptPath(path)
  if !exists(Path(path)) && !exists(Path(receiptPath)) {
    false
  } else if !exists(Path(path)) || !exists(Path(receiptPath)) {
    fail("content-addressed derivative is incomplete: " ++ path)
  } else {
    let receipt = Js.Json.parseExn(readText(Path(receiptPath)))
    if stringField(receipt, "fingerprint_sha256") != fingerprint ||
       stringField(receipt, "audio_sha256") != sha256File(Path(path)) {
      fail("content-addressed derivative does not match its manifest: " ++ path)
    }
    validateAudio(path, "cached derivative")->ignore
    true
  }
}

let publishDerivative = (~temporary: string, ~path: string, ~fingerprint: string, ~kind: string): unit => {
  validateAudio(temporary, kind)->ignore
  if !publishFileExclusive(Path(temporary), Path(path)) {
    fail("refusing to overwrite derivative: " ++ path)
  }
  let root = Js.Dict.empty()
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "kind", kind)
  addString(root, "fingerprint_sha256", fingerprint)
  addString(root, "audio", path)
  addString(root, "audio_sha256", sha256File(Path(path)))
  addNumber(root, "duration_seconds", probeDuration(Path(path))->secondsValue)
  if !writeTextExclusive(Path(derivativeReceiptPath(path)), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n") {
    fail("refusing to overwrite derivative manifest: " ++ derivativeReceiptPath(path))
  }
}

let buildVoiceLane = (
  ~rendered: array<renderedTurn>,
  ~timeline: array<Core.turnWindow>,
  ~masterDuration: float,
): string => {
  ensureDirPath(Path(outDir))
  let config = "voice-lane-v8|no-per-take-loudnorm|highpass55|assembled-loudnorm=-18/-3/11|48k-stereo"
  let fingerprint = sha256Text(Js.Array2.joinWith([
    assemblyVersion,
    config,
    Js.Float.toString(masterDuration),
    rendered->Belt.Array.mapWithIndex((index, row) => {
      let window = Belt.Array.getExn(timeline, index)
      row.turn.id ++ "=" ++ sha256File(Path(row.rawPath)) ++ "=" ++
      Js.Float.toString(window.start) ++ "=" ++ Js.Float.toString(window.end_)
    })->Js.Array2.joinWith("|"),
  ], "###"))
  let path = outDir ++ "/voice_" ++ shortHash(fingerprint) ++ ".wav"
  if !verifyDerivative(~path, ~fingerprint) {
    let scratch = tempDir("enoch-v8-voice-")->pathString
    let temporary = scratch ++ "/voice.wav"
    let inputs = rendered->Belt.Array.map(row => ["-i", row.rawPath])->Belt.Array.concatMany
    let chains = rendered->Belt.Array.mapWithIndex((index, _) => {
      let window = Belt.Array.getExn(timeline, index)
      "[" ++ Belt.Int.toString(index) ++ ":a]aresample=48000," ++
      "aformat=sample_fmts=fltp:channel_layouts=stereo,highpass=f=55," ++
      "adelay=" ++ Belt.Int.toString(Belt.Float.toInt(window.start *. 1000.0)) ++ ":all=1[d" ++ Belt.Int.toString(index) ++ "]"
    })
    let labels = rendered->Belt.Array.mapWithIndex((index, _) => "[d" ++ Belt.Int.toString(index) ++ "]")->Js.Array2.joinWith("")
    let graph = Js.Array2.joinWith(chains, ";") ++ ";" ++
      "anullsrc=r=48000:cl=stereo:d=" ++ Js.Float.toString(masterDuration) ++ "[clock];" ++
      "[clock]" ++ labels ++ "amix=inputs=" ++ Belt.Int.toString(Belt.Array.length(rendered) + 1) ++
      ":duration=first:normalize=0:dropout_transition=0," ++
      "loudnorm=I=-18:TP=-3:LRA=11,atrim=0:" ++ Js.Float.toString(masterDuration) ++ "[out]"
    ffmpeg(Belt.Array.concatMany([
      ["-nostdin", "-v", "error", "-n"],
      inputs,
      ["-filter_complex", graph, "-map", "[out]", "-ar", "48000", "-ac", "2", "-c:a", "pcm_s24le", temporary],
    ]))
    publishDerivative(~temporary, ~path, ~fingerprint, ~kind="assembled voice lane")
  }
  path
}

let clipSignature = (clip: Core.resolvedClip): string => {
  let asset = assetById(clip.spec.assetId)
  Js.Array2.joinWith([
    clipSpecSignature(clip.spec),
    asset.assetSha256,
    Js.Float.toString(clip.start),
    Js.Float.toString(clip.end_),
  ], "|")
}

let buildClipLane = (
  ~label: string,
  ~clips: array<Core.resolvedClip>,
  ~masterDuration: float,
  ~music: bool,
): string => {
  ensureDirPath(Path(outDir))
  let normalizer = music ? "loudnorm=I=-26:TP=-4:LRA=12" : "highpass=f=40,loudnorm=I=-24:TP=-4:LRA=11"
  let config = label ++ "|" ++ normalizer ++ "|48k-stereo|content-addressed"
  let fingerprint = sha256Text(Js.Array2.joinWith([
    assemblyVersion,
    config,
    Js.Float.toString(masterDuration),
    clips->Belt.Array.map(clipSignature)->Js.Array2.joinWith("||"),
  ], "###"))
  let path = outDir ++ "/" ++ label ++ "_" ++ shortHash(fingerprint) ++ ".wav"
  if !verifyDerivative(~path, ~fingerprint) {
    let scratch = tempDir("enoch-v8-" ++ label ++ "-")->pathString
    let temporary = scratch ++ "/" ++ label ++ ".wav"
    let inputs = clips->Belt.Array.map(clip => ["-i", assetById(clip.spec.assetId).path])->Belt.Array.concatMany
    let chains = clips->Belt.Array.mapWithIndex((index, clip) => {
      let duration = clip.end_ -. clip.start
      let fadeOutStart = duration -. clip.spec.fadeOut
      let fadeIn = clip.spec.fadeIn > 0.0 ? "afade=t=in:st=0:d=" ++ Js.Float.toString(clip.spec.fadeIn) ++ "," : ""
      let fadeOut = clip.spec.fadeOut > 0.0 ? "afade=t=out:st=" ++ Js.Float.toString(fadeOutStart) ++ ":d=" ++ Js.Float.toString(clip.spec.fadeOut) ++ "," : ""
      "[" ++ Belt.Int.toString(index) ++ ":a]" ++
      "atrim=start=" ++ Js.Float.toString(clip.spec.trimStart) ++ ":end=" ++ Js.Float.toString(clip.spec.trimStart +. duration) ++ "," ++
      "asetpts=PTS-STARTPTS,aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo," ++
      normalizer ++ "," ++ fadeIn ++ fadeOut ++
      "volume=" ++ Js.Float.toString(clip.spec.gainDb) ++ "dB," ++
      "adelay=" ++ Belt.Int.toString(Belt.Float.toInt(clip.start *. 1000.0)) ++ ":all=1[c" ++ Belt.Int.toString(index) ++ "]"
    })
    let labels = clips->Belt.Array.mapWithIndex((index, _) => "[c" ++ Belt.Int.toString(index) ++ "]")->Js.Array2.joinWith("")
    let graph = Js.Array2.joinWith(chains, ";") ++ ";" ++
      "anullsrc=r=48000:cl=stereo:d=" ++ Js.Float.toString(masterDuration) ++ "[clock];" ++
      "[clock]" ++ labels ++ "amix=inputs=" ++ Belt.Int.toString(Belt.Array.length(clips) + 1) ++
      ":duration=first:normalize=0:dropout_transition=0,alimiter=limit=0.88," ++
      "atrim=0:" ++ Js.Float.toString(masterDuration) ++ "[out]"
    ffmpeg(Belt.Array.concatMany([
      ["-nostdin", "-v", "error", "-n"],
      inputs,
      ["-filter_complex", graph, "-map", "[out]", "-ar", "48000", "-ac", "2", "-c:a", "pcm_s24le", temporary],
    ]))
    publishDerivative(~temporary, ~path, ~fingerprint, ~kind=label ++ " lane")
  }
  path
}

let buildMaster = (~voice: string, ~sfx: string, ~music: string, ~masterDuration: float): (string, string, string) => {
  ensureDirPath(Path(reviewDir))
  let fingerprint = sha256Text(Js.Array2.joinWith([
    assemblyVersion,
    Core.masterMixConfig,
    Js.Float.toString(masterDuration),
    sha256File(Path(voice)),
    sha256File(Path(sfx)),
    sha256File(Path(music)),
  ], "###"))
  let stamp = shortHash(fingerprint)
  let wavPath = outDir ++ "/master_" ++ stamp ++ ".wav"
  if !verifyDerivative(~path=wavPath, ~fingerprint) {
    let scratch = tempDir("enoch-v8-master-")->pathString
    let temporary = scratch ++ "/master.wav"
    ffmpeg([
      "-nostdin", "-v", "error", "-n", "-i", voice, "-i", sfx, "-i", music,
      "-filter_complex", Core.masterMixGraph(~duration=masterDuration), "-map", "[out]",
      "-ar", "48000", "-ac", "2", "-c:a", "pcm_s24le", temporary,
    ])
    publishDerivative(~temporary, ~path=wavPath, ~fingerprint, ~kind="final WAV master")
  }
  let m4aConfig = "aac-256k|48k-stereo|metadata-stripped|faststart"
  let m4aFingerprint = sha256Text(fingerprint ++ "|" ++ sha256File(Path(wavPath)) ++ "|" ++ m4aConfig)
  let m4aPath = reviewDir ++ "/THE_SCHOOL_WENT_QUIET_COLD_OPEN_V8_" ++ shortHash(m4aFingerprint) ++ ".m4a"
  if !verifyDerivative(~path=m4aPath, ~fingerprint=m4aFingerprint) {
    let scratch = tempDir("enoch-v8-m4a-")->pathString
    let temporary = scratch ++ "/master.m4a"
    ffmpeg([
      "-nostdin", "-v", "error", "-n", "-i", wavPath,
      "-map", "0:a:0", "-map_metadata", "-1", "-c:a", "aac", "-b:a", "256k",
      "-ar", "48000", "-ac", "2", "-movflags", "+faststart",
      "-metadata", "title=The School Went Quiet — V8 Cold Open", temporary,
    ])
    publishDerivative(~temporary, ~path=m4aPath, ~fingerprint=m4aFingerprint, ~kind="review M4A")
  }
  (wavPath, m4aPath, fingerprint)
}

let resolvedClipJson = (clip: Core.resolvedClip): Js.Json.t => {
  let root = clipSpecJson(clip.spec)->Js.Json.decodeObject->Belt.Option.getExn
  let overlap = clip.end_ -. clip.start
  addNumber(root, "start_seconds", clip.start)
  addNumber(root, "end_seconds", clip.end_)
  addNumber(root, "rendered_seconds", overlap)
  addString(root, "source_sha256", assetById(clip.spec.assetId).assetSha256)
  Js.Json.object_(root)
}

let writeMasterManifest = (
  ~turns: array<turn>,
  ~rendered: array<renderedTurn>,
  ~timeline: array<Core.turnWindow>,
  ~sfx: array<Core.resolvedClip>,
  ~music: array<Core.resolvedClip>,
  ~holdWindows: array<Core.holdWindow>,
  ~overlap: float,
  ~planHash: string,
  ~masterDuration: float,
  ~voicePath: string,
  ~sfxPath: string,
  ~musicPath: string,
  ~wavPath: string,
  ~m4aPath: string,
  ~masterFingerprint: string,
  ~wavStats: loudnessStats,
  ~m4aStats: loudnessStats,
): string => {
  let path = projectDir ++ "/ENOCH_BROWN_COLD_OPEN_V8_MASTER_" ++ shortHash(masterFingerprint) ++ ".manifest.json"
  let root = Js.Dict.empty()
  addString(root, "schema", "enoch.cold-open-audio-master/v8")
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "assembly_version", assemblyVersion)
  addString(root, "canonical_script", scriptPath)
  addString(root, "canonical_script_sha256", approvedScriptSha256)
  addString(root, "plan_sha256", planHash)
  addString(root, "master_fingerprint_sha256", masterFingerprint)
  addNumber(root, "duration_seconds", masterDuration)
  addNumber(root, "ordinary_sfx_overlap_fraction", overlap)
  addString(root, "voice_lane", voicePath)
  addString(root, "voice_lane_sha256", sha256File(Path(voicePath)))
  addString(root, "sfx_lane", sfxPath)
  addString(root, "sfx_lane_sha256", sha256File(Path(sfxPath)))
  addString(root, "music_lane", musicPath)
  addString(root, "music_lane_sha256", sha256File(Path(musicPath)))
  addString(root, "master_wav", wavPath)
  addString(root, "master_wav_sha256", sha256File(Path(wavPath)))
  addString(root, "review_m4a", m4aPath)
  addString(root, "review_m4a_sha256", sha256File(Path(m4aPath)))
  addNumber(root, "wav_integrated_lufs", wavStats.integrated)
  addNumber(root, "wav_true_peak_dbtp", wavStats.truePeak)
  addNumber(root, "wav_lra_lu", wavStats.lra)
  addNumber(root, "m4a_integrated_lufs", m4aStats.integrated)
  addNumber(root, "m4a_true_peak_dbtp", m4aStats.truePeak)
  addNumber(root, "m4a_lra_lu", m4aStats.lra)
  addNumber(root, "new_sfx_requests", 0.0)
  addNumber(root, "new_music_requests", 0.0)
  addString(root, "public_disclosure", "Some sounds are dramatized. The exact attack sequence and weapon are unknown.")
  Js.Dict.set(root, "reused_assets", Js.Json.array(reusedAssets->Belt.Array.map(assetJson)))
  Js.Dict.set(root, "sfx_cues", Js.Json.array(sfx->Belt.Array.map(resolvedClipJson)))
  Js.Dict.set(root, "music_cues", Js.Json.array(music->Belt.Array.map(resolvedClipJson)))
  Js.Dict.set(root, "dialogue", Js.Json.array(turns->Belt.Array.mapWithIndex((index, turn) => {
    let row = Js.Dict.empty()
    let audio = Belt.Array.getExn(rendered, index)
    let window = Belt.Array.getExn(timeline, index)
    addString(row, "id", turn.id)
    addString(row, "stage", Core.stageName(turn.stage))
    addString(row, "profile", profileName(turn.profile))
    addString(row, "intention", turn.intention)
    addString(row, "expression_tag", turn.tag)
    addNumber(row, "stability", turn.settings.stability)
    addNumber(row, "speed", turn.settings.speed)
    addNumber(row, "seed", Belt.Int.toFloat(turn.seed))
    addString(row, "request_sha256", audio.requestHash)
    addString(row, "provider_asset", audio.rawPath)
    addString(row, "provider_asset_sha256", sha256File(Path(audio.rawPath)))
    addNumber(row, "start_seconds", window.start)
    addNumber(row, "end_seconds", window.end_)
    addString(row, "source_text", turn.text)
    addString(row, "provider_text", providerText(turn))
    Js.Json.object_(row)
  })))
  Js.Dict.set(root, "holds", Js.Json.array(holdWindows->Belt.Array.map(hold => {
    let row = Js.Dict.empty()
    addString(row, "id", hold.spec.id)
    addString(row, "after_turn_id", hold.spec.afterTurnId)
    addString(row, "reason", hold.spec.reason)
    addNumber(row, "start_seconds", hold.start)
    addNumber(row, "end_seconds", hold.end_)
    Js.Json.object_(row)
  })))
  let text = Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n"
  if exists(Path(path)) {
    if readText(Path(path)) != text {
      fail("content-addressed master manifest contains different bytes")
    }
  } else if !writeTextExclusive(Path(path), text) {
    fail("could not publish master manifest")
  }
  path
}

let analyzeLoudness = (path: string, label: string): loudnessStats => {
  let result = run(
    ~cmd="ffmpeg",
    ~args=[
      "-nostdin", "-hide_banner", "-i", path,
      "-af", "loudnorm=I=-16:TP=-2:LRA=9:print_format=json", "-f", "null", "-",
    ],
  )
  let left = Js.String2.lastIndexOf(result.stderr, "{")
  let right = Js.String2.lastIndexOf(result.stderr, "}")
  if result.code != 0 || left < 0 || right <= left {
    fail(label ++ " loudness analysis failed")
  }
  let json = Js.Json.parseExn(Js.String2.slice(result.stderr, ~from=left, ~to_=right + 1))
  let number = key => switch Belt.Float.fromString(stringField(json, key)) {
  | Some(value) => value
  | None => fail(label ++ " loudness analysis omitted " ++ key)
  }
  {integrated: number("input_i"), truePeak: number("input_tp"), lra: number("input_lra")}
}

let validateLoudness = (~stats: loudnessStats, ~label: string, ~peakCeiling: float): unit => {
  if stats.integrated < -16.7 || stats.integrated > -15.3 {
    fail(label ++ " integrated loudness is outside -16.0 ±0.7 LUFS")
  }
  if stats.truePeak > peakCeiling {
    fail(label ++ " true peak exceeds " ++ Js.Float.toString(peakCeiling) ++ " dBTP")
  }
  if stats.lra < 3.0 || stats.lra > 9.0 {
    fail(label ++ " loudness range is outside 3–9 LU")
  }
}

let finalQc = (~wavPath: string, ~m4aPath: string, ~duration: float): (loudnessStats, loudnessStats) => {
  let wavDuration = validateAudio(wavPath, "final WAV")
  let m4aDuration = validateAudio(m4aPath, "review M4A")
  if Js.Math.abs_float(wavDuration -. duration) > 0.10 || Js.Math.abs_float(m4aDuration -. duration) > 0.10 ||
     Js.Math.abs_float(wavDuration -. m4aDuration) > 0.10 {
    fail("final duration QC failed")
  }
  let silence = run(
    ~cmd="ffmpeg",
    ~args=["-nostdin", "-hide_banner", "-i", wavPath, "-af", "silencedetect=noise=-55dB:d=3.5", "-f", "null", "-"],
  )
  let unexpected = silence.stderr->Js.String2.split("\n")->Belt.Array.keep(line => contains(line, "silence_duration:"))
  if Belt.Array.length(unexpected) > 0 {
    fail("master contains unintended silence longer than 3.5 seconds")
  }
  let wavStats = analyzeLoudness(wavPath, "WAV")
  let m4aStats = analyzeLoudness(m4aPath, "M4A")
  validateLoudness(~stats=wavStats, ~label="WAV", ~peakCeiling=-1.5)
  validateLoudness(~stats=m4aStats, ~label="M4A", ~peakCeiling=-1.0)
  Js.log(
    "QC PASS — decode, duration, overlap, authored hold, silence, loudness, LRA, and true peak. " ++
    "WAV " ++ Js.Float.toString(wavStats.integrated) ++ " LUFS / " ++ Js.Float.toString(wavStats.truePeak) ++ " dBTP; " ++
    "M4A " ++ Js.Float.toString(m4aStats.integrated) ++ " LUFS / " ++ Js.Float.toString(m4aStats.truePeak) ++ " dBTP",
  )
  (wavStats, m4aStats)
}

let main = async (): unit => {
  let turns = parseScript()
  validateTurns(turns)
  validateReusedAssets()
  let estimatedDurations = turns->Belt.Array.map(estimateDuration)
  let estimatedInputs = timelineInputs(~turns, ~durations=estimatedDurations)
  let estimatedTimeline = Core.buildTurnTimeline(~turns=estimatedInputs, ~initialLead)
  let estimatedMaster = masterDurationFor(estimatedTimeline)
  let (_, _, _, estimatedOverlap) = validateTimeline(
    ~turns,
    ~inputs=estimatedInputs,
    ~timeline=estimatedTimeline,
    ~masterDuration=estimatedMaster,
  )
  let planHash = writePlan(~turns, ~estimatedTimeline, ~estimatedMaster, ~estimatedOverlap)
  if envDry == Some("1") {
    Js.log("DRY PASS — script, reveal order, performance map, pinned reused assets, estimated runtime, overlap, and paid ceilings validated; zero external generation calls.")
  } else {
    let rendered = await renderDialogue(~turns, ~planHash)
    let durations = rendered->Belt.Array.map(row => row.duration)
    let inputs = timelineInputs(~turns, ~durations)
    let timeline = Core.buildTurnTimeline(~turns=inputs, ~initialLead)
    let masterDuration = masterDurationFor(timeline)
    let (sfx, music, holdWindows, overlap) = validateTimeline(~turns, ~inputs, ~timeline, ~masterDuration)
    let voicePath = buildVoiceLane(~rendered, ~timeline, ~masterDuration)
    let sfxPath = buildClipLane(~label="sfx", ~clips=sfx, ~masterDuration, ~music=false)
    let musicPath = buildClipLane(~label="music", ~clips=music, ~masterDuration, ~music=true)
    let (wavPath, m4aPath, masterFingerprint) = buildMaster(~voice=voicePath, ~sfx=sfxPath, ~music=musicPath, ~masterDuration)
    let (wavStats, m4aStats) = finalQc(~wavPath, ~m4aPath, ~duration=masterDuration)
    let manifestPath = writeMasterManifest(
      ~turns,
      ~rendered,
      ~timeline,
      ~sfx,
      ~music,
      ~holdWindows,
      ~overlap,
      ~planHash,
      ~masterDuration,
      ~voicePath,
      ~sfxPath,
      ~musicPath,
      ~wavPath,
      ~m4aPath,
      ~masterFingerprint,
      ~wavStats,
      ~m4aStats,
    )
    Js.log("MASTER WAV -> " ++ wavPath)
    Js.log("REVIEW M4A -> " ++ m4aPath)
    Js.log("MANIFEST -> " ++ manifestPath)
  }
}

main()
->Js.Promise2.catch(error => {
  Js.log2("ENOCH V8 COLD OPEN FAILED:", error)
  exit(1)
  Js.Promise.resolve()
})
->ignore
