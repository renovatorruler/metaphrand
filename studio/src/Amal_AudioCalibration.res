/* AMAL audio-first Shyam/older-Deva calibration.

   The six V3 takes are final-pilot assets, not disposable auditions.  The
   renderer buys no music and no synthetic effects: every sound in this proof
   is a hash-pinned recording from the user's owned Pro Sound Effects library.

   From studio/:
     DRY=1 node src/Amal_AudioCalibration.res.mjs
     PAID=1 GENERATE_TTS=1 APPROVED_PLAN_SHA256=<dry-plan-hash> \
       node src/Amal_AudioCalibration.res.mjs
*/

open Cinema_Backends
module Core = EnochBrown_ColdOpenV8Core

@val @scope(("process", "env")) external envDry: option<string> = "DRY"
@val @scope(("process", "env")) external envPaid: option<string> = "PAID"
@val @scope(("process", "env")) external envGenerateTts: option<string> = "GENERATE_TTS"
@val @scope(("process", "env")) external envApprovedPlan: option<string> = "APPROVED_PLAN_SHA256"
@val @scope(("process", "env")) external envRecoverNetworkTts: option<string> = "RECOVER_NETWORK_TTS"
@val @scope("process") external exit: int => unit = "exit"

exception CalibrationError(string)

let pipelineVersion = "amal-audio-calibration-v1.0.1"
let assemblyVersion = "amal-audio-calibration-mix-v1.0.0"
let scriptPath = "../stories/amal/2026-08-30_AUDIO_FIRST_PILOT_v2.md"
let approvedScriptSha256 = "673771eb7fe708fb15b75840da42b19a1ab734000f692fa7df3fb57d609a4b52"
let projectDir = "../stories/amal/production/audio_first_pilot_v2_calibration"
let cacheDir = projectDir ++ "/cache"
let rawDialogueDir = cacheDir ++ "/provider_raw/dialogue"
let claimDir = cacheDir ++ "/paid_claims"
let outDir = projectDir ++ "/mix"
let planDir = projectDir ++ "/plans"
let reviewDir = projectDir ++ "/review"

let narratorVoiceId = "5ycO0zpSCEkvR4Ri6gk9"
let narratorVoiceName = "Shyam — older Deva / author selected"
let initialLead = 1.20
let reviewTail = 2.00
/* This is a performance-and-mix calibration, not an episode runtime target.
   Shyam's approved awake delivery lands at roughly 63 seconds; forcing the
   earlier 70-second estimate would add dead air and reward the sleepy pacing
   this calibration is meant to prevent. */
let minimumCalibrationSeconds = 60.0
let maximumCalibrationSeconds = 100.0
let maxNewTtsRequests = 6
let maxNewTtsCharacters = 1000

type turn = {
  id: string,
  text: string,
  tag: string,
  settings: productionVoiceSettings,
  seed: int,
  gapAfter: float,
  intention: string,
}

type renderedTurn = {
  turn: turn,
  requestHash: string,
  rawPath: string,
  duration: float,
}

type pseAsset = {
  id: string,
  path: string,
  sha256: string,
  duration: float,
  sourceUrl: string,
  calibrationOnly: bool,
}

type loudnessStats = {
  integrated: float,
  truePeak: float,
  lra: float,
}

let fail = (message: string): 'a => raise(CalibrationError(message))
let trim = Js.String2.trim
let contains = (value: string, fragment: string): bool => Js.String2.includes(value, fragment)
let lower = Js.String2.toLowerCase
let secondsValue = (Seconds(value)): float => value
let pathString = (Path(value)): string => value
let shortHash = (hash: string): string => Js.String2.slice(hash, ~from=0, ~to_=20)

let turns: array<turn> = [
  {
    id: "AMCAL01",
    text: "कभी गर्मी में जनरल डिब्बे में बैठे हैं? पंखा सिर के ऊपर घूमता रहता है, हवा फिर भी नहीं देता। सीटें कम, लोग ज़्यादा। थोड़ी देर में अजनबी भी एक-दूसरे के घर की बातें जान लेते हैं। उस दिन सामने बैठी एक औरत बस बोले जा रही थी। गोद में उसका मुन्ना था।",
    tag: "",
    settings: {stability: 0.43, speed: 1.00},
    seed: 26083001,
    gapAfter: 0.60,
    intention: "Older Deva talks to one listener: awake, warm, and lightly amused.",
  },
  {
    id: "AMCAL02",
    text: "बाक़ी लोग अपनी बातों में लगे रहे। रतन साहब की नज़र उस छोटे-से हाथ पर अटक गई। झटके में भी वह नहीं हिला था और कपड़े पर मक्खियाँ बैठने लगी थीं। गाड़ी रोकने वाली लाल जंजीर उनके सिर के ऊपर थी।",
    tag: "",
    settings: {stability: 0.36, speed: 1.01},
    seed: 26083002,
    gapAfter: 0.75,
    intention: "Attention narrows without becoming hushed, spooky, or slow.",
  },
  {
    id: "AMCAL03",
    text: "उस बच्चे की साँस बंद हो चुकी थी।",
    tag: "",
    settings: {stability: 0.50, speed: 0.99},
    seed: 26083003,
    gapAfter: 1.00,
    intention: "Land the fact plainly; do not perform grief.",
  },
  {
    id: "AMCAL04",
    text: "रतन सिंह पँवार ने यह देख लिया था, फिर भी जंजीर नहीं खींची।",
    tag: "[serious]",
    settings: {stability: 0.38, speed: 1.02},
    seed: 26083004,
    gapAfter: 1.25,
    intention: "Moral pressure without prosecution, anger, or trailer drama.",
  },
  {
    id: "AMCAL05",
    text: "मेरा नाम देवा है। बरसों बाद मेरी पोस्टिंग उन्हीं के साथ हुई। अमरगढ़ में लोग कहते थे, «पँवार साहब की फ़ाइल में झूठ नहीं मिलता।» सही कहते थे। मैं चौबीस साल का था। मुझे इतना ही काफ़ी लगा।",
    tag: "",
    settings: {stability: 0.44, speed: 1.00},
    seed: 26083005,
    gapAfter: 0.80,
    intention: "Older Deva implicates his younger self; sincere, never sarcastic.",
  },
  {
    id: "AMCAL06",
    text: "यह मेरे अमरगढ़ पहुँचने से कुछ पहले हुआ था। भेरूलाल की बेटी लीला मरी हुई मिली थी। घर वाले कह रहे थे, हादसा है। रतन साहब मौके से थाने लौटे थे और मुंशी पहली रिपोर्ट लिख रहा था।",
    tag: "",
    settings: {stability: 0.47, speed: 1.00},
    seed: 26083006,
    gapAfter: 0.00,
    intention: "Bridge factually into the next case while retaining forward momentum.",
  },
]

let pseAssets: array<pseAsset> = [
  {
    id: "train_interior",
    path: "/Users/dusty/SFX/PSE/TRNDiesl_Train Onboard Interior Ride Train Bell_PSE_SMV1_OJSDj.wav",
    sha256: "c429113c43f12c9c23d991a42d9cfc1c4d6b2e893fc6fd278500f2271af91e54",
    duration: 174.464,
    sourceUrl: "https://www.prosoundeffects.com/sound-effects/PSE_SMV1/OJSDj/train-onboard-interior-ride-train-bell",
    calibrationOnly: false,
  },
  {
    id: "passenger_laughter",
    path: "/Users/dusty/SFX/PSE/CRWDLaff_Small Crowd Laughter Reserved Laughing and Chuckling_PSE_CHCH_EjMvn.wav",
    sha256: "04f06d396f6ec4d8b3822f2cedbb4d0463304b14437fe41854a64a6b4644fe1f",
    duration: 10.922667,
    sourceUrl: "owned PSE CORE local library asset",
    calibrationOnly: false,
  },
  {
    id: "metal_cans",
    path: "/Users/dusty/SFX/PSE/METLCrsh_Metal Cans Movement_PSE_SMV1_Z7NDA.wav",
    sha256: "f042160dde6816bdb25d8726cbc117d649045bc7a3a54504c6808610624f045f",
    duration: 56.096,
    sourceUrl: "https://www.prosoundeffects.com/sound-effects/PSE_SMV1/Z7NDA/metal-cans-movement",
    calibrationOnly: false,
  },
  {
    id: "cloth_rustle",
    path: "/Users/dusty/SFX/PSE/CLOTHMvmt_Cloth Rustle Close Up Heavy Fabric Movement 01_PSE_GEN2_QN1BA.wav",
    sha256: "a20e79d16ba04eff3ab8d3dd7845a3861baea8b76cc2c217abf67d721dde8a7b",
    duration: 2.304,
    sourceUrl: "owned PSE CORE local library asset",
    calibrationOnly: false,
  },
  {
    id: "chain_ring",
    path: "/Users/dusty/SFX/PSE/CHAINMvmt_Heavy Metal Chain Over Metal Ring Movement_PSE_GEN_D1MEP.wav",
    sha256: "da35c43ba5f2d122d02582e428a69f5ab26257809e3a79d31e93f2585cfce740",
    duration: 10.125333,
    sourceUrl: "https://www.prosoundeffects.com/sound-effects/PSE_GEN/D1MEP/heavy-metal-chain-over-metal-ring-movement",
    calibrationOnly: false,
  },
  {
    id: "office_fan_proxy",
    path: "/Users/dusty/SFX/PSE/AMBRoom_Vent Rattle Hallway Air Conditioning Shaking CU_PSE_GEN_gYLeA.wav",
    sha256: "11231f36ea56cf4ff3a5686ff4c6ba311ddfbbe7176de9f6015dd8057d9c4465",
    duration: 55.013333,
    sourceUrl: "owned PSE CORE local library asset",
    calibrationOnly: true,
  },
  {
    id: "pencil_writing",
    path: "/Users/dusty/SFX/PSE/OBJWrite_Pencil Writing on Paper CU_PSE_GEN3_KuUeX.wav",
    sha256: "466e7d05fa54c8ef4b150a7558711951748acf6e387a87b531f2675a0032d6cc",
    duration: 2.133333,
    sourceUrl: "owned PSE CORE local library asset",
    calibrationOnly: false,
  },
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

let providerText = (turn: turn): string => turn.tag == "" ? turn.text : turn.tag ++ " " ++ turn.text

let wordsIn = (value: string): int =>
  value->trim == "" ? 0 : value->trim->Js.String2.splitByRe(%re("/\s+/"))->Belt.Array.length

let requestSignature = (turn: turn): string => Js.Array2.joinWith([
  "model=eleven_v3",
  "output_format=wav_48000",
  "language_code=hi",
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

let assetById = (id: string): pseAsset => switch Belt.Array.getBy(pseAssets, asset => asset.id == id) {
| Some(asset) => asset
| None => fail("unknown PSE asset " ++ id)
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

let validateScriptAndTurns = (): unit => {
  if !exists(Path(scriptPath)) {
    fail("canonical AMAL pilot is missing")
  }
  let actualHash = sha256File(Path(scriptPath))
  if actualHash != approvedScriptSha256 {
    fail("approved pilot changed; expected " ++ approvedScriptSha256 ++ ", got " ++ actualHash)
  }
  let script = readText(Path(scriptPath))
  let tagged = ref(0)
  turns->Belt.Array.forEach(turn => {
    if !contains(script, turn.text) {
      fail(turn.id ++ " is not exact reusable text from the approved pilot")
    }
    if turn.tag != "" {
      tagged := tagged.contents + 1
    }
    if wordsIn(turn.text) > 90 || Js.String2.length(providerText(turn)) > 700 {
      fail(turn.id ++ " is too long for a thought-based V3 take")
    }
    let provider = lower(providerText(turn))
    ["[whisper", "[quiet", "[soft", "[slowly]", "[calm]", "[gently]"]->Belt.Array.forEach(forbidden =>
      if contains(provider, forbidden) {
        fail(turn.id ++ " contains a sleepy or hushed direction")
      }
    )
    if trim(turn.intention) == "" {
      fail(turn.id ++ " has no performance intention")
    }
  })
  if tagged.contents != 1 || Belt.Array.getExn(turns, 3).tag != "[serious]" {
    fail("calibration requires exactly one restrained [serious] tag on AMCAL04")
  }
}

let validatePseAssets = (): unit => pseAssets->Belt.Array.forEach(asset => {
  if !exists(Path(asset.path)) {
    fail("owned PSE asset is missing: " ++ asset.id)
  }
  if sha256File(Path(asset.path)) != asset.sha256 {
    fail("owned PSE asset bytes changed: " ++ asset.id)
  }
  let duration = validateAudio(asset.path, "PSE " ++ asset.id)
  if Js.Math.abs_float(duration -. asset.duration) > 0.08 {
    fail("owned PSE asset duration changed: " ++ asset.id)
  }
})

let estimateDuration = (turn: turn): float =>
  Belt.Int.toFloat(wordsIn(turn.text)) /. (2.45 *. turn.settings.speed)

let timelineInputs = (~durations: array<float>): array<Core.turnInput> => {
  if Belt.Array.length(durations) != Belt.Array.length(turns) {
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

let cueSpecs = (~timeline: array<Core.turnWindow>, ~masterDuration: float): array<Core.clipCue> => {
  let trainEnd = Core.findTurn(timeline, "AMCAL04").end_ +. 0.55
  let officeStart = Core.findTurn(timeline, "AMCAL05").start -. 0.25
  [
    {id: "S001_TRAIN_INTERIOR", assetId: "train_interior", mode: Core.Bed, anchor: Core.Absolute(0.0), length: Core.Fixed(trainEnd), trimStart: 60.0, gainDb: -7.5, fadeIn: 0.30, fadeOut: 1.10},
    {id: "S002_PASSENGER_LAUGH", assetId: "passenger_laughter", mode: Core.Hit, anchor: Core.TurnStart("AMCAL01", 8.5), length: Core.Fixed(2.0), trimStart: 0.2, gainDb: -15.0, fadeIn: 0.15, fadeOut: 0.35},
    {id: "S003_METAL_JOLT", assetId: "metal_cans", mode: Core.Hit, anchor: Core.TurnStart("AMCAL02", -0.20), length: Core.Fixed(1.55), trimStart: 4.0, gainDb: -13.0, fadeIn: 0.04, fadeOut: 0.35},
    {id: "S004_CLOTH", assetId: "cloth_rustle", mode: Core.Hit, anchor: Core.TurnStart("AMCAL02", 0.35), length: Core.Fixed(1.20), trimStart: 0.20, gainDb: -15.0, fadeIn: 0.05, fadeOut: 0.20},
    {id: "S005_CHAIN", assetId: "chain_ring", mode: Core.Hit, anchor: Core.TurnEnd("AMCAL04", -1.60), length: Core.Fixed(1.35), trimStart: 1.0, gainDb: -14.0, fadeIn: 0.05, fadeOut: 0.22},
    {id: "S006_OFFICE_FAN", assetId: "office_fan_proxy", mode: Core.Bed, anchor: Core.Absolute(officeStart), length: Core.Fixed(masterDuration -. officeStart), trimStart: 5.0, gainDb: -11.0, fadeIn: 0.80, fadeOut: 0.60},
    {id: "S007_PENCIL", assetId: "pencil_writing", mode: Core.Hit, anchor: Core.TurnStart("AMCAL06", -0.35), length: Core.Fixed(2.05), trimStart: 0.0, gainDb: -16.0, fadeIn: 0.08, fadeOut: 0.25},
  ]
}

let resolveCues = (~timeline: array<Core.turnWindow>, ~masterDuration: float): (array<Core.resolvedClip>, float) => {
  let clips = cueSpecs(~timeline, ~masterDuration)->Belt.Array.map(spec =>
    Core.resolveClip(~turns=timeline, ~masterDuration, spec)
  )
  clips->Belt.Array.forEach(clip => {
    let asset = assetById(clip.spec.assetId)
    let used = clip.spec.trimStart +. clip.end_ -. clip.start
    if used > asset.duration +. 0.01 {
      fail("cue " ++ clip.spec.id ++ " exceeds source " ++ asset.id)
    }
  })
  let overlap = Core.validateSfxOverlap(~turns=timeline, ~clips)
  (clips, overlap)
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

let clipSignature = (clip: Core.resolvedClip): string => Js.Array2.joinWith([
  clip.spec.id,
  clip.spec.assetId,
  Core.modeName(clip.spec.mode),
  anchorSignature(clip.spec.anchor),
  lengthSignature(clip.spec.length),
  Js.Float.toString(clip.spec.trimStart),
  Js.Float.toString(clip.spec.gainDb),
  Js.Float.toString(clip.spec.fadeIn),
  Js.Float.toString(clip.spec.fadeOut),
  Js.Float.toString(clip.start),
  Js.Float.toString(clip.end_),
], "|")

let planSignature = (~timeline: array<Core.turnWindow>, ~masterDuration: float): string => {
  let (clips, _) = resolveCues(~timeline, ~masterDuration)
  Js.Array2.joinWith([
    pipelineVersion,
    assemblyVersion,
    approvedScriptSha256,
    turns->Belt.Array.map(turn => Js.Array2.joinWith([
      turn.id,
      turn.intention,
      turn.tag,
      Js.Float.toString(turn.settings.stability),
      Js.Float.toString(turn.settings.speed),
      Belt.Int.toString(turn.seed),
      Js.Float.toString(turn.gapAfter),
      requestHash(turn),
    ], "~"))->Js.Array2.joinWith("||"),
    pseAssets->Belt.Array.map(asset => asset.id ++ "=" ++ asset.sha256)->Js.Array2.joinWith("||"),
    clips->Belt.Array.map(clipSignature)->Js.Array2.joinWith("||"),
    Core.masterMixConfig,
  ], "###")
}

let turnJson = (turn: turn): Js.Json.t => {
  let root = Js.Dict.empty()
  addString(root, "id", turn.id)
  addString(root, "intention", turn.intention)
  addString(root, "source_text", turn.text)
  addString(root, "provider_text", providerText(turn))
  addString(root, "expression_tag", turn.tag)
  addNumber(root, "stability", turn.settings.stability)
  addNumber(root, "speed", turn.settings.speed)
  addNumber(root, "seed", Belt.Int.toFloat(turn.seed))
  addNumber(root, "gap_after_seconds", turn.gapAfter)
  addNumber(root, "characters", Belt.Int.toFloat(Js.String2.length(providerText(turn))))
  addNumber(root, "words", Belt.Int.toFloat(wordsIn(turn.text)))
  addString(root, "request_sha256", requestHash(turn))
  addString(root, "raw_cache", rawPathFor(turn))
  Js.Json.object_(root)
}

let assetJson = (asset: pseAsset): Js.Json.t => {
  let root = Js.Dict.empty()
  addString(root, "id", asset.id)
  addString(root, "provider", "Pro Sound Effects — owned CORE library")
  addString(root, "path", asset.path)
  addString(root, "sha256", asset.sha256)
  addNumber(root, "duration_seconds", asset.duration)
  addString(root, "source_url", asset.sourceUrl)
  addBool(root, "calibration_only_proxy", asset.calibrationOnly)
  Js.Json.object_(root)
}

let clipJson = (clip: Core.resolvedClip): Js.Json.t => {
  let root = Js.Dict.empty()
  addString(root, "id", clip.spec.id)
  addString(root, "asset_id", clip.spec.assetId)
  addString(root, "mode", Core.modeName(clip.spec.mode))
  addNumber(root, "start_seconds", clip.start)
  addNumber(root, "end_seconds", clip.end_)
  addNumber(root, "trim_start_seconds", clip.spec.trimStart)
  addNumber(root, "gain_db", clip.spec.gainDb)
  Js.Json.object_(root)
}

let writePlan = (~timeline: array<Core.turnWindow>, ~masterDuration: float, ~overlap: float): string => {
  let planHash = sha256Text(planSignature(~timeline, ~masterDuration))
  let missing = turns->Belt.Array.keep(turn => !exists(Path(rawPathFor(turn))))
  let missingChars = missing->Belt.Array.reduce(0, (sum, turn) => sum + Js.String2.length(providerText(turn)))
  let plannedChars = turns->Belt.Array.reduce(0, (sum, turn) => sum + Js.String2.length(providerText(turn)))
  let (clips, _) = resolveCues(~timeline, ~masterDuration)
  ensureDirPath(Path(planDir))
  let path = planDir ++ "/AMAL_SHYAM_CALIBRATION_PLAN_" ++ shortHash(planHash) ++ ".json"
  let root = Js.Dict.empty()
  addString(root, "schema", "amal.audio-calibration-plan/v1")
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "assembly_version", assemblyVersion)
  addString(root, "canonical_script", scriptPath)
  addString(root, "canonical_script_sha256", approvedScriptSha256)
  addString(root, "plan_sha256", planHash)
  addString(root, "narrator", narratorVoiceName)
  addString(root, "voice_id", narratorVoiceId)
  addString(root, "speech_model", "eleven_v3")
  addString(root, "language_code", "hi")
  addString(root, "speech_output", "wav_48000")
  addString(root, "performance_policy", "Six thought-based final-pilot takes; one sparse [serious] tag; no sleepy, whisper, or per-take loudness normalization.")
  addString(root, "mix_policy", "Independent voice and PSE lanes; all effects overlap and sidechain beneath speech; cues never advance the voice timeline.")
  addNumber(root, "estimated_duration_seconds", masterDuration)
  addNumber(root, "estimated_bed_overlap_fraction", overlap)
  /* Cache state is execution state, not plan identity.  Keeping it out of the
     immutable plan lets the same approved plan remain valid after its assets
     have been rendered. */
  addNumber(root, "planned_tts_requests", Belt.Int.toFloat(Belt.Array.length(turns)))
  addNumber(root, "planned_tts_characters", Belt.Int.toFloat(plannedChars))
  addNumber(root, "maximum_new_tts_requests", Belt.Int.toFloat(maxNewTtsRequests))
  addNumber(root, "maximum_new_tts_characters", Belt.Int.toFloat(maxNewTtsCharacters))
  addNumber(root, "new_sfx_requests", 0.0)
  addNumber(root, "new_music_requests", 0.0)
  addString(root, "music_policy", "No music in this pre-title calibration; zero Music v2 calls.")
  addString(root, "known_limitation", "The owned PSE catalogue had no licensed infant-cry recording; the calibration omits that optional hit rather than substituting or purchasing one.")
  addString(root, "paid_gate", "PAID=1 + GENERATE_TTS=1 + APPROVED_PLAN_SHA256 equal to this plan hash; DRY=1 always wins.")
  Js.Dict.set(root, "turns", Js.Json.array(turns->Belt.Array.map(turnJson)))
  Js.Dict.set(root, "pse_assets", Js.Json.array(pseAssets->Belt.Array.map(assetJson)))
  Js.Dict.set(root, "sfx_cues", Js.Json.array(clips->Belt.Array.map(clipJson)))
  let text = Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n"
  if exists(Path(path)) {
    if readText(Path(path)) != text {
      fail("content-addressed plan contains different bytes")
    }
  } else if !writeTextExclusive(Path(path), text) {
    fail("could not publish content-addressed plan")
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
  addString(root, "policy", "A claim without a cached output is an uncertain paid attempt; automatic retry is forbidden.")
  if !writeTextExclusive(Path(path), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n") {
    if envRecoverNetworkTts == Some(turn.id) {
      let recoveryPath = claimDir ++ "/recovery_network_" ++ turn.id ++ "_" ++ hash ++ ".json"
      let recovery = Js.Dict.empty()
      addString(recovery, "pipeline_version", pipelineVersion)
      addString(recovery, "kind", "tts")
      addString(recovery, "turn_id", turn.id)
      addString(recovery, "request_sha256", hash)
      addString(recovery, "reason", "One controlled retry after a confirmed local network failure before provider delivery.")
      if !writeTextExclusive(Path(recoveryPath), Js.Json.stringifyWithSpace(Js.Json.object_(recovery), 1) ++ "\n") {
        fail("controlled recovery already consumed for " ++ turn.id)
      }
    } else {
      fail("paid attempt already claimed but cache is missing: " ++ turn.id)
    }
  }
}

let publishFetched = (~audio: blob, ~destination: string, ~label: string): float => {
  let scratch = tempDir("amal-calibration-tts-")->pathString
  let temporary = scratch ++ "/take.wav"
  writeBytes(Path(temporary), audio)->ignore
  let duration = validateAudio(temporary, label)
  if !publishFileExclusive(Path(temporary), Path(destination)) {
    fail("refusing to overwrite immutable provider take: " ++ destination)
  }
  duration
}

let writeProviderReceipt = (~turn: turn, ~path: string, ~duration: float): unit => {
  let root = Js.Dict.empty()
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "kind", "tts")
  addString(root, "turn_id", turn.id)
  addString(root, "model", "eleven_v3")
  addString(root, "language_code", "hi")
  addString(root, "voice_id", narratorVoiceId)
  addString(root, "request_sha256", requestHash(turn))
  addString(root, "asset", path)
  addString(root, "asset_sha256", sha256File(Path(path)))
  addNumber(root, "duration_seconds", duration)
  if !writeTextExclusive(Path(path ++ ".receipt.json"), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n") {
    fail("provider receipt already exists unexpectedly")
  }
}

let requirePaidPlan = (~planHash: string, ~missing: array<turn>): unit => {
  let chars = missing->Belt.Array.reduce(0, (sum, turn) => sum + Js.String2.length(providerText(turn)))
  if Belt.Array.length(missing) > maxNewTtsRequests || chars > maxNewTtsCharacters {
    fail("missing TTS exceeds the approved calibration ceiling")
  }
  if envDry == Some("1") || envPaid != Some("1") || envGenerateTts != Some("1") {
    fail("paid narration is locked")
  }
  if envApprovedPlan != Some(planHash) {
    fail("APPROVED_PLAN_SHA256 does not match the dry plan")
  }
}

let renderDialogue = async (~planHash: string): array<renderedTurn> => {
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
      Js.log("PAID ELEVEN V3 " ++ turn.id ++ " / " ++ Belt.Int.toString(Js.String2.length(providerText(turn))) ++ " characters")
      let audio = await productionTtsForLanguage(
        ~text=Text(providerText(turn)),
        ~voice=VoiceId(narratorVoiceId),
        ~languageCode="hi",
        ~seed=turn.seed,
        ~settings=turn.settings,
      )
      let duration = publishFetched(~audio, ~destination=path, ~label="AMAL " ++ turn.id)
      writeProviderReceipt(~turn, ~path, ~duration)
    }
    let duration = validateAudio(path, "cached " ++ turn.id)
    if duration > 35.0 {
      fail(turn.id ++ " exceeds the 35-second intention limit")
    }
    Js.Array2.push(rendered, {turn, requestHash: requestHash(turn), rawPath: path, duration})->ignore
    index := index.contents + 1
  }
  rendered
}

let derivativeManifest = path => path ++ ".manifest.json"

let verifyDerivative = (~path: string, ~fingerprint: string): bool => {
  let manifest = derivativeManifest(path)
  if !exists(Path(path)) && !exists(Path(manifest)) {
    false
  } else if !exists(Path(path)) || !exists(Path(manifest)) {
    fail("incomplete content-addressed derivative: " ++ path)
  } else {
    let json = Js.Json.parseExn(readText(Path(manifest)))
    if stringField(json, "fingerprint_sha256") != fingerprint ||
       stringField(json, "audio_sha256") != sha256File(Path(path)) {
      fail("derivative manifest mismatch: " ++ path)
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
  if !writeTextExclusive(Path(derivativeManifest(path)), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n") {
    fail("refusing to overwrite derivative manifest")
  }
}

let buildVoiceLane = (~rendered: array<renderedTurn>, ~timeline: array<Core.turnWindow>, ~duration: float): string => {
  ensureDirPath(Path(outDir))
  let config = "voice|48k-stereo|highpass55|assembled-loudnorm=-18/-3/11|no-per-take-normalization"
  let fingerprint = sha256Text(Js.Array2.joinWith([
    assemblyVersion,
    config,
    Js.Float.toString(duration),
    rendered->Belt.Array.mapWithIndex((index, row) => {
      let window = Belt.Array.getExn(timeline, index)
      row.turn.id ++ "=" ++ sha256File(Path(row.rawPath)) ++ "=" ++ Js.Float.toString(window.start)
    })->Js.Array2.joinWith("|"),
  ], "###"))
  let path = outDir ++ "/voice_" ++ shortHash(fingerprint) ++ ".wav"
  if !verifyDerivative(~path, ~fingerprint) {
    let temporary = tempDir("amal-calibration-voice-")->pathString ++ "/voice.wav"
    let inputs = rendered->Belt.Array.map(row => ["-i", row.rawPath])->Belt.Array.concatMany
    let chains = rendered->Belt.Array.mapWithIndex((index, _) => {
      let window = Belt.Array.getExn(timeline, index)
      "[" ++ Belt.Int.toString(index) ++ ":a]aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo," ++
      "highpass=f=55,adelay=" ++ Belt.Int.toString(Belt.Float.toInt(window.start *. 1000.0)) ++ ":all=1[d" ++ Belt.Int.toString(index) ++ "]"
    })
    let labels = rendered->Belt.Array.mapWithIndex((index, _) => "[d" ++ Belt.Int.toString(index) ++ "]")->Js.Array2.joinWith("")
    let graph = Js.Array2.joinWith(chains, ";") ++ ";" ++
      "anullsrc=r=48000:cl=stereo:d=" ++ Js.Float.toString(duration) ++ "[clock];" ++
      "[clock]" ++ labels ++ "amix=inputs=" ++ Belt.Int.toString(Belt.Array.length(rendered) + 1) ++
      ":duration=first:normalize=0:dropout_transition=0,loudnorm=I=-18:TP=-3:LRA=11,atrim=0:" ++ Js.Float.toString(duration) ++ "[out]"
    ffmpeg(Belt.Array.concatMany([
      ["-nostdin", "-v", "error", "-n"], inputs,
      ["-filter_complex", graph, "-map", "[out]", "-ar", "48000", "-ac", "2", "-c:a", "pcm_s24le", temporary],
    ]))
    publishDerivative(~temporary, ~path, ~fingerprint, ~kind="assembled Shyam voice lane")
  }
  path
}

let buildSfxLane = (~clips: array<Core.resolvedClip>, ~duration: float): string => {
  ensureDirPath(Path(outDir))
  let fingerprint = sha256Text(Js.Array2.joinWith([
    assemblyVersion,
    "pse-lane|48k-stereo|one-lane-normalization=-24/-4/11",
    Js.Float.toString(duration),
    clips->Belt.Array.map(clip => clipSignature(clip) ++ "=" ++ assetById(clip.spec.assetId).sha256)->Js.Array2.joinWith("||"),
  ], "###"))
  let path = outDir ++ "/pse_" ++ shortHash(fingerprint) ++ ".wav"
  if !verifyDerivative(~path, ~fingerprint) {
    let temporary = tempDir("amal-calibration-pse-")->pathString ++ "/pse.wav"
    let inputs = clips->Belt.Array.map(clip => ["-i", assetById(clip.spec.assetId).path])->Belt.Array.concatMany
    let chains = clips->Belt.Array.mapWithIndex((index, clip) => {
      let clipDuration = clip.end_ -. clip.start
      let fadeOutStart = clipDuration -. clip.spec.fadeOut
      let fadeIn = clip.spec.fadeIn > 0.0 ? "afade=t=in:st=0:d=" ++ Js.Float.toString(clip.spec.fadeIn) ++ "," : ""
      let fadeOut = clip.spec.fadeOut > 0.0 ? "afade=t=out:st=" ++ Js.Float.toString(fadeOutStart) ++ ":d=" ++ Js.Float.toString(clip.spec.fadeOut) ++ "," : ""
      "[" ++ Belt.Int.toString(index) ++ ":a]atrim=start=" ++ Js.Float.toString(clip.spec.trimStart) ++
      ":end=" ++ Js.Float.toString(clip.spec.trimStart +. clipDuration) ++ ",asetpts=PTS-STARTPTS," ++
      "aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo," ++ fadeIn ++ fadeOut ++
      "volume=" ++ Js.Float.toString(clip.spec.gainDb) ++ "dB,adelay=" ++
      Belt.Int.toString(Belt.Float.toInt(clip.start *. 1000.0)) ++ ":all=1[c" ++ Belt.Int.toString(index) ++ "]"
    })
    let labels = clips->Belt.Array.mapWithIndex((index, _) => "[c" ++ Belt.Int.toString(index) ++ "]")->Js.Array2.joinWith("")
    let graph = Js.Array2.joinWith(chains, ";") ++ ";" ++
      "anullsrc=r=48000:cl=stereo:d=" ++ Js.Float.toString(duration) ++ "[clock];" ++
      "[clock]" ++ labels ++ "amix=inputs=" ++ Belt.Int.toString(Belt.Array.length(clips) + 1) ++
      ":duration=first:normalize=0:dropout_transition=0,highpass=f=35,loudnorm=I=-24:TP=-4:LRA=11," ++
      "atrim=0:" ++ Js.Float.toString(duration) ++ "[out]"
    ffmpeg(Belt.Array.concatMany([
      ["-nostdin", "-v", "error", "-n"], inputs,
      ["-filter_complex", graph, "-map", "[out]", "-ar", "48000", "-ac", "2", "-c:a", "pcm_s24le", temporary],
    ]))
    publishDerivative(~temporary, ~path, ~fingerprint, ~kind="licensed PSE lane")
  }
  path
}

let buildSilentMusicLane = (~duration: float): string => {
  ensureDirPath(Path(outDir))
  let fingerprint = sha256Text(assemblyVersion ++ "|silent-music|" ++ Js.Float.toString(duration))
  let path = outDir ++ "/music_silent_" ++ shortHash(fingerprint) ++ ".wav"
  if !verifyDerivative(~path, ~fingerprint) {
    let temporary = tempDir("amal-calibration-silent-")->pathString ++ "/music.wav"
    ffmpeg([
      "-nostdin", "-v", "error", "-n", "-f", "lavfi", "-i",
      "anullsrc=r=48000:cl=stereo:d=" ++ Js.Float.toString(duration),
      "-t", Js.Float.toString(duration), "-c:a", "pcm_s24le", temporary,
    ])
    publishDerivative(~temporary, ~path, ~fingerprint, ~kind="intentional silent music lane")
  }
  path
}

let buildMaster = (~voice: string, ~sfx: string, ~music: string, ~duration: float): (string, string, string) => {
  ensureDirPath(Path(reviewDir))
  let fingerprint = sha256Text(Js.Array2.joinWith([
    assemblyVersion,
    Core.masterMixConfig,
    Js.Float.toString(duration),
    sha256File(Path(voice)),
    sha256File(Path(sfx)),
    sha256File(Path(music)),
  ], "###"))
  let stamp = shortHash(fingerprint)
  let wavPath = outDir ++ "/master_" ++ stamp ++ ".wav"
  if !verifyDerivative(~path=wavPath, ~fingerprint) {
    let temporary = tempDir("amal-calibration-master-")->pathString ++ "/master.wav"
    ffmpeg([
      "-nostdin", "-v", "error", "-n", "-i", voice, "-i", sfx, "-i", music,
      "-filter_complex", Core.masterMixGraph(~duration), "-map", "[out]",
      "-ar", "48000", "-ac", "2", "-c:a", "pcm_s24le", temporary,
    ])
    publishDerivative(~temporary, ~path=wavPath, ~fingerprint, ~kind="final calibration WAV")
  }
  let m4aFingerprint = sha256Text(fingerprint ++ "|" ++ sha256File(Path(wavPath)) ++ "|aac-256k-48k-stereo")
  let m4aPath = reviewDir ++ "/AMAL_SHYAM_CALIBRATION_" ++ shortHash(m4aFingerprint) ++ ".m4a"
  if !verifyDerivative(~path=m4aPath, ~fingerprint=m4aFingerprint) {
    let temporary = tempDir("amal-calibration-m4a-")->pathString ++ "/review.m4a"
    ffmpeg([
      "-nostdin", "-v", "error", "-n", "-i", wavPath, "-map", "0:a:0", "-map_metadata", "-1",
      "-c:a", "aac", "-b:a", "256k", "-ar", "48000", "-ac", "2", "-movflags", "+faststart",
      "-metadata", "title=AMAL — Shyam calibration", temporary,
    ])
    publishDerivative(~temporary, ~path=m4aPath, ~fingerprint=m4aFingerprint, ~kind="review M4A")
  }
  (wavPath, m4aPath, fingerprint)
}

let analyzeLoudness = (path: string, label: string): loudnessStats => {
  let result = run(
    ~cmd="ffmpeg",
    ~args=["-nostdin", "-hide_banner", "-i", path, "-af", "loudnorm=I=-16:TP=-2:LRA=9:print_format=json", "-f", "null", "-"],
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

let finalQc = (~wavPath: string, ~m4aPath: string, ~duration: float): (loudnessStats, loudnessStats) => {
  let wavDuration = validateAudio(wavPath, "final WAV")
  let m4aDuration = validateAudio(m4aPath, "review M4A")
  if duration < minimumCalibrationSeconds || duration > maximumCalibrationSeconds {
    fail("calibration runtime is outside 60–100 seconds")
  }
  if Js.Math.abs_float(wavDuration -. duration) > 0.10 || Js.Math.abs_float(m4aDuration -. duration) > 0.10 ||
     Js.Math.abs_float(wavDuration -. m4aDuration) > 0.10 {
    fail("final duration QC failed")
  }
  let silence = run(
    ~cmd="ffmpeg",
    ~args=["-nostdin", "-hide_banner", "-i", wavPath, "-af", "silencedetect=noise=-55dB:d=3.5", "-f", "null", "-"],
  )
  if silence.stderr->Js.String2.split("\n")->Belt.Array.some(line => contains(line, "silence_duration:")) {
    fail("master contains unintended silence longer than 3.5 seconds")
  }
  let wavStats = analyzeLoudness(wavPath, "WAV")
  let m4aStats = analyzeLoudness(m4aPath, "M4A")
  if wavStats.integrated < -16.7 || wavStats.integrated > -15.3 || m4aStats.integrated < -16.7 || m4aStats.integrated > -15.3 {
    fail("final integrated loudness is outside -16 ±0.7 LUFS")
  }
  if wavStats.truePeak > -1.5 || m4aStats.truePeak > -1.0 {
    fail("final true peak ceiling failed")
  }
  if wavStats.lra < 2.0 || wavStats.lra > 10.0 || m4aStats.lra < 2.0 || m4aStats.lra > 10.0 {
    fail("final loudness range is implausible")
  }
  Js.log("QC PASS -> " ++ Js.Float.toString(duration) ++ " sec / " ++ Js.Float.toString(m4aStats.integrated) ++ " LUFS / " ++ Js.Float.toString(m4aStats.truePeak) ++ " dBTP")
  (wavStats, m4aStats)
}

let writeMasterManifest = (
  ~planHash: string,
  ~rendered: array<renderedTurn>,
  ~timeline: array<Core.turnWindow>,
  ~clips: array<Core.resolvedClip>,
  ~overlap: float,
  ~duration: float,
  ~voicePath: string,
  ~sfxPath: string,
  ~wavPath: string,
  ~m4aPath: string,
  ~fingerprint: string,
  ~wavStats: loudnessStats,
  ~m4aStats: loudnessStats,
): string => {
  let path = projectDir ++ "/AMAL_SHYAM_CALIBRATION_MASTER_" ++ shortHash(fingerprint) ++ ".manifest.json"
  let root = Js.Dict.empty()
  addString(root, "schema", "amal.audio-calibration-master/v1")
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "canonical_script_sha256", approvedScriptSha256)
  addString(root, "plan_sha256", planHash)
  addString(root, "master_fingerprint_sha256", fingerprint)
  addNumber(root, "duration_seconds", duration)
  addNumber(root, "ordinary_sfx_overlap_fraction", overlap)
  addString(root, "voice_lane", voicePath)
  addString(root, "voice_lane_sha256", sha256File(Path(voicePath)))
  addString(root, "pse_lane", sfxPath)
  addString(root, "pse_lane_sha256", sha256File(Path(sfxPath)))
  addString(root, "master_wav", wavPath)
  addString(root, "master_wav_sha256", sha256File(Path(wavPath)))
  addString(root, "review_m4a", m4aPath)
  addString(root, "review_m4a_sha256", sha256File(Path(m4aPath)))
  addNumber(root, "wav_integrated_lufs", wavStats.integrated)
  addNumber(root, "wav_true_peak_dbtp", wavStats.truePeak)
  addNumber(root, "m4a_integrated_lufs", m4aStats.integrated)
  addNumber(root, "m4a_true_peak_dbtp", m4aStats.truePeak)
  addNumber(root, "new_tts_requests", 6.0)
  addNumber(root, "new_sfx_requests", 0.0)
  addNumber(root, "new_music_requests", 0.0)
  Js.Dict.set(root, "pse_assets", Js.Json.array(pseAssets->Belt.Array.map(assetJson)))
  Js.Dict.set(root, "sfx_cues", Js.Json.array(clips->Belt.Array.map(clipJson)))
  Js.Dict.set(root, "dialogue", Js.Json.array(rendered->Belt.Array.mapWithIndex((index, audio) => {
    let row = turnJson(audio.turn)->Js.Json.decodeObject->Belt.Option.getExn
    let window = Belt.Array.getExn(timeline, index)
    addString(row, "provider_asset", audio.rawPath)
    addString(row, "provider_asset_sha256", sha256File(Path(audio.rawPath)))
    addNumber(row, "start_seconds", window.start)
    addNumber(row, "end_seconds", window.end_)
    Js.Json.object_(row)
  })))
  let text = Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n"
  if exists(Path(path)) {
    if readText(Path(path)) != text {
      fail("content-addressed master manifest mismatch")
    }
  } else if !writeTextExclusive(Path(path), text) {
    fail("could not publish master manifest")
  }
  path
}

let main = async (): unit => {
  validateScriptAndTurns()
  validatePseAssets()
  let estimatedDurations = turns->Belt.Array.map(estimateDuration)
  let estimatedTimeline = Core.buildTurnTimeline(~turns=timelineInputs(~durations=estimatedDurations), ~initialLead)
  let estimatedMaster = masterDurationFor(estimatedTimeline)
  let (_, estimatedOverlap) = resolveCues(~timeline=estimatedTimeline, ~masterDuration=estimatedMaster)
  let planHash = writePlan(~timeline=estimatedTimeline, ~masterDuration=estimatedMaster, ~overlap=estimatedOverlap)
  if envDry == Some("1") {
    Js.log("DRY PASS — approved script, six performance intentions, PSE hashes, overlap, runtime estimate, and paid ceilings validated; zero provider calls.")
  } else {
    let rendered = await renderDialogue(~planHash)
    let timeline = Core.buildTurnTimeline(~turns=timelineInputs(~durations=rendered->Belt.Array.map(row => row.duration)), ~initialLead)
    let duration = masterDurationFor(timeline)
    let (clips, overlap) = resolveCues(~timeline, ~masterDuration=duration)
    let voicePath = buildVoiceLane(~rendered, ~timeline, ~duration)
    let sfxPath = buildSfxLane(~clips, ~duration)
    let musicPath = buildSilentMusicLane(~duration)
    let (wavPath, m4aPath, fingerprint) = buildMaster(~voice=voicePath, ~sfx=sfxPath, ~music=musicPath, ~duration)
    let (wavStats, m4aStats) = finalQc(~wavPath, ~m4aPath, ~duration)
    let manifest = writeMasterManifest(
      ~planHash,
      ~rendered,
      ~timeline,
      ~clips,
      ~overlap,
      ~duration,
      ~voicePath,
      ~sfxPath,
      ~wavPath,
      ~m4aPath,
      ~fingerprint,
      ~wavStats,
      ~m4aStats,
    )
    Js.log("MASTER WAV -> " ++ wavPath)
    Js.log("REVIEW M4A -> " ++ m4aPath)
    Js.log("MANIFEST -> " ++ manifest)
  }
}

main()
->Js.Promise2.catch(error => {
  Js.log2("AMAL CALIBRATION FAILED:", error)
  exit(1)
  Js.Promise.resolve()
})
->ignore
