/* AMAL — "The Train" opening audio-drama proof.

   This renderer is deliberately narrow. It produces only the first compartment
   movement of the author-directed scene, ending on Rajesh's dismissal. Action
   lines are never narrated: the train, passengers, cloth, luggage, and flies
   carry the physical story underneath one contextual Text-to-Dialogue take.

   The dry plan is the authority for every potentially paid request:

     DRY=1 node src/Amal_TrainAudioProof.res.mjs

     PAID=1 GENERATE_DIALOGUE=1 GENERATE_SFX=1 \
       APPROVED_PLAN_SHA256=<exact-dry-plan-hash> \
       node src/Amal_TrainAudioProof.res.mjs

   DRY=1 always wins. A claimed request whose immutable cache is absent is an
   uncertain paid attempt and is never retried automatically. */

open Cinema_Backends
module Core = EnochBrown_ColdOpenV8Core

@val @scope(("process", "env")) external envDry: option<string> = "DRY"
@val @scope(("process", "env")) external envPaid: option<string> = "PAID"
@val @scope(("process", "env")) external envGenerateDialogue: option<string> = "GENERATE_DIALOGUE"
@val @scope(("process", "env")) external envGenerateSfx: option<string> = "GENERATE_SFX"
@val @scope(("process", "env")) external envApprovedPlan: option<string> = "APPROVED_PLAN_SHA256"
@val @scope("process") external exit: int => unit = "exit"

exception TrainAudioProofError(string)

let pipelineVersion = "amal-train-audio-proof-v1.0.0"
let assemblyVersion = "amal-train-audio-proof-mix-v1.0.0"
let scriptPath = "../stories/amal/train-scene.md"
let approvedScriptSha256 = "6b084ea7d3a1c0a3ed22006df2d5034c2630c3cef9a4793e0b90f5e91910001e"
let projectDir = "../stories/amal/production/train_audio_proof_v1"
let cacheDir = projectDir ++ "/cache"
let rawDialogueDir = cacheDir ++ "/provider_raw/dialogue"
let rawSfxDir = cacheDir ++ "/provider_raw/sfx"
let claimDir = cacheDir ++ "/paid_claims"
let outDir = projectDir ++ "/mix"
let planDir = projectDir ++ "/plans"
let reviewDir = projectDir ++ "/review"

let initialLead = 1.50
let reviewTail = 2.00
let maxNewDialogueRequests = 1
let maxNewDialogueCharacters = 900
let maxNewSfxRequests = 2
let maxNewSfxSeconds = 18.0

type speaker = Kamla | Suresh | Woman | Rajesh

type castMember = {
  speaker: speaker,
  accountName: string,
  voiceId: string,
  publicOwnerId: option<string>,
}

type dialogueLine = {
  id: string,
  speaker: speaker,
  text: string,
  tag: string,
  gapAfter: float,
}

type timedLine = {
  id: string,
  start: float,
  end_: float,
}

type dialogueCache = {
  rawPath: string,
  duration: float,
  timings: array<timedLine>,
}

type generatedSfxSpec = {
  id: string,
  prompt: string,
  seconds: float,
  influence: float,
}

type pseAsset = {
  id: string,
  path: string,
  sha256: string,
  duration: float,
  source: string,
}

type audioAsset = {
  id: string,
  path: string,
  sha256: string,
  duration: float,
  source: string,
}

type loudnessStats = {
  integrated: float,
  truePeak: float,
  lra: float,
}

let fail = (message: string): 'a => raise(TrainAudioProofError(message))
let trim = Js.String2.trim
let lower = Js.String2.toLowerCase
let contains = (value: string, fragment: string): bool => Js.String2.includes(value, fragment)
let starts = (value: string, prefix: string): bool => Js.String2.startsWith(value, prefix)
let secondsValue = (Seconds(value)): float => value
let pathString = (Path(value)): string => value
let shortHash = (hash: string): string => Js.String2.slice(hash, ~from=0, ~to_=20)
let floatMin = (a: float, b: float): float => a < b ? a : b
let floatMax = (a: float, b: float): float => a > b ? a : b

let speakerName = speaker => switch speaker {
| Kamla => "KAMLA"
| Suresh => "SURESH"
| Woman => "WOMAN"
| Rajesh => "RAJESH"
}

let cast: array<castMember> = [
  {
    speaker: Suresh,
    accountName: "Gajendra — AMAL Suresh",
    voiceId: "6xalENe4gtaDq8XTGd7G",
    publicOwnerId: Some("c0c7d01bfa452287ca8221ec9bd14fa49d2b95ac3fa4809ccb1293f84d1136c3"),
  },
  {
    speaker: Rajesh,
    accountName: "Krish — AMAL Rajesh",
    voiceId: "eUfplp5rzZJd9uBGf0sv",
    publicOwnerId: Some("7398804d9eaf2f463899a907587c33a390591775784f87857b6d0e1e4e3e66f6"),
  },
  {
    speaker: Kamla,
    accountName: "Madhusmita — AMAL Kamla",
    voiceId: "0VYKG6D7F62aQxdckt3c",
    publicOwnerId: Some("7398804d9eaf2f463899a907587c33a390591775784f87857b6d0e1e4e3e66f6"),
  },
  {
    speaker: Woman,
    accountName: "Mahira — AMAL Woman",
    voiceId: "subIZc6skATBQ1Rbqpi7",
    publicOwnerId: None,
  },
]

let lines: array<dialogueLine> = [
  {
    id: "AP01",
    speaker: Kamla,
    text: "मैंने कहा था ना सुबह वाली पकड़ लेते। अब बैठो इस लू में। और वो अचार वाला डब्बा तुमने ऊपर रखा कि नीचे? मुझे तो याद ही नहीं आ रहा।",
    tag: "[animated]",
    gapAfter: 0.0,
  },
  {id: "AP02", speaker: Suresh, text: "रखा है कहीं।", tag: "", gapAfter: 0.0},
  {
    id: "AP03",
    speaker: Kamla,
    text: "और जीजाजी को फ़ोन कर देना उतरते ही, वरना वो फिर मुँह फुलाए बैठे रहेंगे शादी भर।",
    tag: "",
    gapAfter: 0.0,
  },
  {
    id: "AP04",
    speaker: Kamla,
    text: "उई, ये मक्खियाँ कहाँ से आ गईं इतनी। बहन, तुम्हारे ही ऊपर भिनभिना रही हैं। कुछ मीठा रखा है क्या साथ में?",
    tag: "[friendly]",
    gapAfter: 0.0,
  },
  {id: "AP05", speaker: Kamla, text: "कितने महीने का है? लड़का है ना?", tag: "", gapAfter: 0.0},
  {
    id: "AP06",
    speaker: Kamla,
    text: "इतनी गरमी में इत्ता लपेट के रखा है बेचारे को, घुटन नहीं होगी उसको? ज़रा खोलो ऊपर से।",
    tag: "[concerned]",
    gapAfter: 0.0,
  },
  {id: "AP07", speaker: Woman, text: "सो रहा है। ठीक है वो।", tag: "[matter-of-fact]", gapAfter: 0.0},
  {
    id: "AP08",
    speaker: Kamla,
    text: "हाँ तो मैं कह रही थी, जीजी का घर स्टेशन से दस मिनट है, पर रिक्शे वाले दिन में लूटते हैं...",
    tag: "",
    gapAfter: 3.80,
  },
  {id: "AP09", speaker: Suresh, text: "राजेश। इधर आ ज़रा।", tag: "[concerned]", gapAfter: 0.0},
  {
    id: "AP10",
    speaker: Suresh,
    text: "उस औरत को देख। बच्चे को। इतनी गरमी है और उसने मुँह तक ढक रखा है। और एक बात बता — गाड़ी चली तब से, वो बच्चा एक बार हिला तेरे को?",
    tag: "",
    gapAfter: 0.0,
  },
  {
    id: "AP11",
    speaker: Rajesh,
    text: "सो रहा होगा भैया। छोटे बच्चे दिन भर सोते हैं। और ठंड भी जल्दी लग जाती है इनको, इसीलिए ढका होगा। तुम भी ना।",
    tag: "[matter-of-fact]",
    gapAfter: 0.0,
  },
]

let generatedSfx: array<generatedSfxSpec> = [
  {
    id: "adult_passenger_walla",
    prompt: "Rear of a crowded 1990s Indian railway general coach, several adult passengers conversing at once in warm indistinct speech blurred beyond intelligibility, bodies shifting gently on hard benches, natural documentary ambience focused on human murmur and bench movement.",
    seconds: 12.0,
    influence: 0.58,
  },
  {
    id: "close_houseflies",
    prompt: "Two or three close houseflies circle and hover near heavy cloth inside a hot railway carriage, brief passes near the listener and small shifts in distance, realistic documentary recording.",
    seconds: 6.0,
    influence: 0.65,
  },
]

let pseAssets: array<pseAsset> = [
  {
    id: "train_interior",
    path: "/Users/dusty/SFX/PSE/TRNDiesl_Train Onboard Interior Ride Train Bell_PSE_SMV1_OJSDj.wav",
    sha256: "c429113c43f12c9c23d991a42d9cfc1c4d6b2e893fc6fd278500f2271af91e54",
    duration: 174.464,
    source: "owned PSE CORE local library asset",
  },
  {
    id: "metal_luggage_jolt",
    path: "/Users/dusty/SFX/PSE/METLCrsh_Metal Cans Movement_PSE_SMV1_Z7NDA.wav",
    sha256: "f042160dde6816bdb25d8726cbc117d649045bc7a3a54504c6808610624f045f",
    duration: 56.096,
    source: "owned PSE CORE local library asset",
  },
  {
    id: "cloth_rustle",
    path: "/Users/dusty/SFX/PSE/CLOTHMvmt_Cloth Rustle Close Up Heavy Fabric Movement 01_PSE_GEN2_QN1BA.wav",
    sha256: "a20e79d16ba04eff3ab8d3dd7845a3861baea8b76cc2c217abf67d721dde8a7b",
    duration: 2.304,
    source: "owned PSE CORE local library asset",
  },
  {
    id: "fan_rattle",
    path: "/Users/dusty/SFX/PSE/AMBRoom_Vent Rattle Hallway Air Conditioning Shaking CU_PSE_GEN_gYLeA.wav",
    sha256: "11231f36ea56cf4ff3a5686ff4c6ba311ddfbbe7176de9f6015dd8057d9c4465",
    duration: 55.013333,
    source: "owned PSE CORE local library asset; mechanical fan proxy",
  },
  {
    id: "seat_scrape",
    path: "/Users/dusty/SFX/PSE/WOODMvmt_Wood Scrape Chair Cement_PSE_GEN_R61Oy.wav",
    sha256: "f2b3236b5d1eda2b41bce031b861ec9168ff722fdbf375cd638b621355b87aee",
    duration: 25.248,
    source: "owned PSE CORE local library asset",
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

let numberField = (json: Js.Json.t, key: string): float =>
  json
  ->Js.Json.decodeObject
  ->Belt.Option.flatMap(object_ => Js.Dict.get(object_, key))
  ->Belt.Option.flatMap(Js.Json.decodeNumber)
  ->Belt.Option.getWithDefault(-1.0)

let arrayField = (json: Js.Json.t, key: string): array<Js.Json.t> =>
  json
  ->Js.Json.decodeObject
  ->Belt.Option.flatMap(object_ => Js.Dict.get(object_, key))
  ->Belt.Option.flatMap(Js.Json.decodeArray)
  ->Belt.Option.getWithDefault([])

let memberFor = (speaker: speaker): castMember => switch Belt.Array.getBy(cast, member => member.speaker == speaker) {
| Some(member) => member
| None => fail("cast has no " ++ speakerName(speaker))
}

let providerText = (line: dialogueLine): string => line.tag == "" ? line.text : line.tag ++ " " ++ line.text

let wordsIn = (value: string): int =>
  value->trim == ""
    ? 0
    : value->trim->Js.String2.replaceByRe(%re("/\s+/g"), " ")->Js.String2.split(" ")->Belt.Array.length

let totalDialogueCharacters = (): int =>
  lines->Belt.Array.reduce(0, (sum, line) => sum + Js.String2.length(providerText(line)))

let castSignature = (): string =>
  cast
  ->Belt.Array.map(member => speakerName(member.speaker) ++ "=" ++ member.voiceId ++ "=" ++
    member.publicOwnerId->Belt.Option.getWithDefault("account"))
  ->Js.Array2.joinWith("|")

let dialogueRequestSignature = (): string => Js.Array2.joinWith([
  "endpoint=/v1/text-to-dialogue/with-timestamps",
  "model=eleven_v3",
  "output_format=mp3_44100_128",
  lines->Belt.Array.map(line =>
    line.id ++ "=" ++ speakerName(line.speaker) ++ "=" ++ memberFor(line.speaker).voiceId ++ "=" ++ providerText(line)
  )->Js.Array2.joinWith("||"),
], "###")

let dialogueRequestHash = (): string => sha256Text(dialogueRequestSignature())
let dialogueRawPath = (): string => rawDialogueDir ++ "/opening_" ++ shortHash(dialogueRequestHash()) ++ ".mp3"
let dialogueTimingPath = (): string => dialogueRawPath() ++ ".timings.json"
let dialogueReceiptPath = (): string => dialogueRawPath() ++ ".receipt.json"

let sfxRequestSignature = (spec: generatedSfxSpec): string => Js.Array2.joinWith([
  "endpoint=/v1/sound-generation",
  "model=eleven_text_to_sound_v2",
  "output_format=mp3_44100_128",
  "loop=false",
  "seconds=" ++ Js.Float.toString(spec.seconds),
  "prompt_influence=" ++ Js.Float.toString(spec.influence),
  "text=" ++ spec.prompt,
], "|")

let sfxRequestHash = (spec: generatedSfxSpec): string => sha256Text(sfxRequestSignature(spec))
let sfxRawPath = (spec: generatedSfxSpec): string =>
  rawSfxDir ++ "/" ++ spec.id ++ "_" ++ shortHash(sfxRequestHash(spec)) ++ ".mp3"
let sfxReceiptPath = (spec: generatedSfxSpec): string => sfxRawPath(spec) ++ ".receipt.json"

let validateAudio = (path: string, label: string): float => {
  if !exists(Path(path)) {
    fail(label ++ " is missing: " ++ path)
  }
  let decode = run(~cmd="ffmpeg", ~args=["-nostdin", "-v", "error", "-i", path, "-f", "null", "-"])
  if decode.code != 0 {
    fail(label ++ " does not decode: " ++ Js.String2.slice(decode.stderr, ~from=0, ~to_=360))
  }
  let duration = probeDuration(Path(path))->secondsValue
  if duration <= 0.2 {
    fail(label ++ " has invalid duration")
  }
  duration
}

let validateCanon = (): unit => {
  if !exists(Path(scriptPath)) {
    fail("canonical train scene is missing")
  }
  let actual = sha256File(Path(scriptPath))
  if actual != approvedScriptSha256 {
    fail("canonical train scene changed; expected " ++ approvedScriptSha256 ++ ", got " ++ actual)
  }
  let script = readText(Path(scriptPath))
  lines->Belt.Array.forEach(line => {
    // AP04 contains a non-spoken performance parenthetical between its two
    // clauses in the canonical page. Validate both exact spoken fragments
    // without sending the action note to the dialogue provider.
    let sourceExact = if line.id == "AP04" {
      contains(script, "उई, ये मक्खियाँ कहाँ से आ गईं इतनी।") &&
      contains(script, "बहन, तुम्हारे ही ऊपर भिनभिना रही हैं। कुछ मीठा रखा है क्या साथ में?")
    } else {
      contains(script, line.text)
    }
    if !sourceExact {
      fail(line.id ++ " is not exact dialogue from the canonical scene")
    }
    if Js.String2.length(providerText(line)) > 5000 {
      fail(line.id ++ " exceeds the Text-to-Dialogue input ceiling")
    }
    ["[quiet", "[whisper", "[slow", "[tense", "[mysterious", "[sad", "[dramatic"]
    ->Belt.Array.forEach(forbidden =>
      if contains(lower(providerText(line)), forbidden) {
        fail(line.id ++ " contains a forbidden sleepy or editorial performance tag")
      }
    )
  })
  if Belt.Array.length(lines) != 11 ||
     Belt.Array.getExn(lines, 0).id != "AP01" ||
     Belt.Array.getExn(lines, 10).id != "AP11" {
    fail("opening proof dialogue sequence changed")
  }
  let providerBlock = lines->Belt.Array.map(providerText)->Js.Array2.joinWith(" ")->lower
  ["ratan", "रतन", "deva", "देवा", "narrator"]->Belt.Array.forEach(fragment =>
    if contains(providerBlock, fragment) {
      fail("opening proof illegally introduces " ++ fragment)
    }
  )
  if totalDialogueCharacters() > maxNewDialogueCharacters {
    fail("opening proof dialogue exceeds the paid character ceiling")
  }
}

let validateCast = (): unit => {
  if Belt.Array.length(cast) != 4 {
    fail("opening proof requires exactly four cast voices")
  }
  cast->Belt.Array.forEachWithIndex((index, member) => {
    if trim(member.voiceId) == "" || trim(member.accountName) == "" {
      fail("incomplete cast member " ++ speakerName(member.speaker))
    }
    if index > 0 && Belt.Array.some(Js.Array2.slice(cast, ~start=0, ~end_=index), prior => prior.voiceId == member.voiceId) {
      fail("two opening characters share voice " ++ member.voiceId)
    }
  })
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
    fail("owned PSE duration changed: " ++ asset.id)
  }
})

let validateSfxPrompts = (): unit => {
  generatedSfx->Belt.Array.forEach(spec => {
    let prompt = lower(trim(spec.prompt))
    if starts(prompt, "no ") || contains(prompt, " no ") || contains(prompt, "without ") {
      fail("SFX prompts must positively describe only what should be heard: " ++ spec.id)
    }
    if spec.seconds < 0.5 || spec.seconds > 30.0 || spec.influence < 0.0 || spec.influence > 1.0 {
      fail("invalid generated SFX settings for " ++ spec.id)
    }
  })
  let totalSeconds = generatedSfx->Belt.Array.reduce(0.0, (sum, spec) => sum +. spec.seconds)
  if Belt.Array.length(generatedSfx) > maxNewSfxRequests || totalSeconds > maxNewSfxSeconds +. 0.001 {
    fail("generated SFX design exceeds the hard paid ceiling")
  }
}

let timedLineJson = (row: timedLine): Js.Json.t => {
  let root = Js.Dict.empty()
  addString(root, "id", row.id)
  addNumber(root, "start_seconds", row.start)
  addNumber(root, "end_seconds", row.end_)
  Js.Json.object_(root)
}

let validateTimings = (~rows: array<timedLine>, ~duration: float): unit => {
  if Belt.Array.length(rows) != Belt.Array.length(lines) {
    fail("dialogue timing cardinality mismatch")
  }
  let priorEnd = ref(-1.0)
  rows->Belt.Array.forEachWithIndex((index, row) => {
    let expected = Belt.Array.getExn(lines, index)
    if row.id != expected.id {
      fail("dialogue timing order changed at " ++ expected.id)
    }
    if row.start < 0.0 || row.end_ <= row.start || row.end_ > duration +. 0.10 {
      fail("invalid provider timing for " ++ row.id)
    }
    if row.start +. 0.05 < priorEnd.contents {
      fail("provider dialogue segments overlap out of order at " ++ row.id)
    }
    priorEnd := row.end_
  })
}

let dialogueTimingJson = (~rows: array<timedLine>, ~audioPath: string, ~duration: float): string => {
  let root = Js.Dict.empty()
  addString(root, "schema", "amal.dialogue-timings/v1")
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "request_sha256", dialogueRequestHash())
  addString(root, "audio", audioPath)
  addString(root, "audio_sha256", sha256File(Path(audioPath)))
  addNumber(root, "audio_duration_seconds", duration)
  Js.Dict.set(root, "voice_segments", Js.Json.array(rows->Belt.Array.map(timedLineJson)))
  Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n"
}

let loadTimings = (~path: string, ~audioPath: string, ~duration: float): array<timedLine> => {
  let json = Js.Json.parseExn(readText(Path(path)))
  if stringField(json, "request_sha256") != dialogueRequestHash() ||
     stringField(json, "audio_sha256") != sha256File(Path(audioPath)) ||
     Js.Math.abs_float(numberField(json, "audio_duration_seconds") -. duration) > 0.10 {
    fail("dialogue timing sidecar does not match its content-addressed audio")
  }
  let rows = arrayField(json, "voice_segments")->Belt.Array.map(row => ({
    id: stringField(row, "id"),
    start: numberField(row, "start_seconds"),
    end_: numberField(row, "end_seconds"),
  }))
  validateTimings(~rows, ~duration)
  rows
}

let verifyDialogueCache = (): option<dialogueCache> => {
  let rawPath = dialogueRawPath()
  let timingPath = dialogueTimingPath()
  let receiptPath = dialogueReceiptPath()
  let present = [exists(Path(rawPath)), exists(Path(timingPath)), exists(Path(receiptPath))]
  let count = present->Belt.Array.reduce(0, (sum, value) => sum + (value ? 1 : 0))
  if count == 0 {
    None
  } else if count != 3 {
    fail("dialogue cache is incomplete; paid retry is forbidden: " ++ rawPath)
  } else {
    let duration = validateAudio(rawPath, "cached opening dialogue")
    let timingHash = sha256File(Path(timingPath))
    let receipt = Js.Json.parseExn(readText(Path(receiptPath)))
    if stringField(receipt, "request_sha256") != dialogueRequestHash() ||
       stringField(receipt, "asset_sha256") != sha256File(Path(rawPath)) ||
       stringField(receipt, "timings_sha256") != timingHash ||
       Js.Math.abs_float(numberField(receipt, "duration_seconds") -. duration) > 0.10 {
      fail("dialogue provider receipt does not match cached bytes")
    }
    let timings = loadTimings(~path=timingPath, ~audioPath=rawPath, ~duration)
    Some({rawPath, duration, timings})
  }
}

let verifySfxCache = (spec: generatedSfxSpec): option<audioAsset> => {
  let path = sfxRawPath(spec)
  let receiptPath = sfxReceiptPath(spec)
  let hasAudio = exists(Path(path))
  let hasReceipt = exists(Path(receiptPath))
  if !hasAudio && !hasReceipt {
    None
  } else if hasAudio != hasReceipt {
    fail("generated SFX cache is incomplete; paid retry is forbidden: " ++ spec.id)
  } else {
    let duration = validateAudio(path, "cached SFX " ++ spec.id)
    if duration < spec.seconds -. 0.35 || duration > spec.seconds +. 2.0 {
      fail("generated SFX duration is implausible: " ++ spec.id)
    }
    let receipt = Js.Json.parseExn(readText(Path(receiptPath)))
    let hash = sha256File(Path(path))
    if stringField(receipt, "request_sha256") != sfxRequestHash(spec) ||
       stringField(receipt, "asset_sha256") != hash ||
       Js.Math.abs_float(numberField(receipt, "duration_seconds") -. duration) > 0.10 {
      fail("generated SFX receipt does not match cached bytes: " ++ spec.id)
    }
    Some({id: spec.id, path, sha256: hash, duration, source: "ElevenLabs eleven_text_to_sound_v2"})
  }
}

let pseById = (id: string): pseAsset => switch Belt.Array.getBy(pseAssets, asset => asset.id == id) {
| Some(asset) => asset
| None => fail("unknown PSE asset " ++ id)
}

let generatedSpecById = (id: string): generatedSfxSpec => switch Belt.Array.getBy(generatedSfx, spec => spec.id == id) {
| Some(spec) => spec
| None => fail("unknown generated SFX asset " ++ id)
}

let audioAssetFor = (id: string): audioAsset => switch Belt.Array.getBy(pseAssets, asset => asset.id == id) {
| Some(asset) => {
    id: asset.id,
    path: asset.path,
    sha256: asset.sha256,
    duration: asset.duration,
    source: asset.source,
  }
| None => {
    let spec = generatedSpecById(id)
    switch verifySfxCache(spec) {
    | Some(asset) => asset
    | None => {
        id: spec.id,
        path: sfxRawPath(spec),
        sha256: sfxRequestHash(spec),
        duration: spec.seconds,
        source: "planned ElevenLabs eleven_text_to_sound_v2 request",
      }
    }
  }
}

let estimateLineDuration = (line: dialogueLine): float =>
  floatMax(0.80, Belt.Int.toFloat(wordsIn(line.text)) /. 2.20)

let estimatedInputs = (): array<Core.turnInput> => lines->Belt.Array.map(line => {
  let row: Core.turnInput = {
    id: line.id,
    duration: estimateLineDuration(line),
    gapAfter: line.gapAfter,
  }
  row
})

let masterDurationFor = (timeline: array<Core.turnWindow>): float =>
  Belt.Array.getExn(timeline, Belt.Array.length(timeline) - 1).end_ +. reviewTail

let speechOverlap = (~timeline: array<Core.turnWindow>, ~start: float, ~end_: float): float =>
  timeline->Belt.Array.reduce(0.0, (sum, turn) =>
    sum +. Core.intersection(~aStart=start, ~aEnd=end_, ~bStart=turn.start, ~bEnd=turn.end_)
  )

let ambienceMode = (~timeline: array<Core.turnWindow>, ~start: float, ~end_: float): Core.cueMode => {
  let duration = end_ -. start
  let overlap = speechOverlap(~timeline, ~start, ~end_)
  let exposed = duration -. overlap
  let finalTurn = Belt.Array.getExn(timeline, Belt.Array.length(timeline) - 1)
  if overlap /. duration >= 0.80 {
    Core.Bed
  } else if overlap > 0.05 && exposed <= 4.0 {
    Core.Transition
  } else if start +. 0.001 >= finalTurn.end_ {
    Core.Tail
  } else {
    fail("continuous ambience window cannot satisfy overlap rules at " ++ Js.Float.toString(start))
  }
}

let continuousBedCues = (
  ~timeline: array<Core.turnWindow>,
  ~masterDuration: float,
  ~prefix: string,
  ~assetId: string,
  ~sourceSeconds: float,
  ~crossfade: float,
  ~gainDb: float,
): array<Core.clipCue> => {
  let rows: array<Core.clipCue> = []
  let start = ref(0.0)
  let index = ref(1)
  while start.contents < masterDuration -. 0.01 {
    let duration = floatMin(sourceSeconds, masterDuration -. start.contents)
    if duration < 0.50 {
      start := masterDuration
    } else {
      let end_ = start.contents +. duration
      let fade = floatMin(crossfade, duration /. 3.0)
      Js.Array2.push(rows, {
        id: prefix ++ Belt.Int.toString(index.contents),
        assetId,
        mode: ambienceMode(~timeline, ~start=start.contents, ~end_),
        anchor: Core.Absolute(start.contents),
        length: Core.Fixed(duration),
        trimStart: 0.0,
        gainDb,
        fadeIn: fade,
        fadeOut: fade,
      })->ignore
      start := start.contents +. sourceSeconds -. crossfade
      index := index.contents + 1
    }
  }
  rows
}

let cueSpecs = (
  ~timeline: array<Core.turnWindow>,
  ~masterDuration: float,
): array<Core.clipCue> => {
  let trainCue: Core.clipCue = {
    id: "S001_TRAIN_INTERIOR",
    assetId: "train_interior",
    mode: ambienceMode(~timeline, ~start=0.0, ~end_=masterDuration),
    anchor: Core.Absolute(0.0),
    length: Core.Fixed(masterDuration),
    trimStart: 0.0,
    gainDb: -7.5,
    fadeIn: 0.30,
    fadeOut: 0.90,
  }
  let fixedCues: array<Core.clipCue> = [{
    id: "S008_LUGGAGE_JOLT",
    assetId: "metal_luggage_jolt",
    mode: Core.Hit,
    anchor: Core.TurnStart("AP02", -0.15),
    length: Core.Fixed(1.55),
    trimStart: 4.0,
    gainDb: -17.0,
    fadeIn: 0.04,
    fadeOut: 0.35,
  },
  {
    id: "S009_FLIES_BEFORE_NOTICE",
    assetId: "close_houseflies",
    mode: Core.Hit,
    anchor: Core.TurnStart("AP04", -0.85),
    length: Core.Fixed(1.20),
    trimStart: 0.0,
    gainDb: -20.0,
    fadeIn: 0.12,
    fadeOut: 0.25,
  },
  {
    id: "S010_FLIES_FIRST",
    assetId: "close_houseflies",
    mode: Core.Hit,
    anchor: Core.TurnStart("AP04", 0.40),
    length: Core.Fixed(2.20),
    trimStart: 1.20,
    gainDb: -12.0,
    fadeIn: 0.10,
    fadeOut: 0.30,
  },
  {
    id: "S011_FLIES_RETURN",
    assetId: "close_houseflies",
    mode: Core.Hit,
    anchor: Core.TurnStart("AP06", 0.30),
    length: Core.Fixed(2.0),
    trimStart: 3.80,
    gainDb: -14.0,
    fadeIn: 0.10,
    fadeOut: 0.28,
  },
  {
    id: "S012_CLOTH_TURN",
    assetId: "cloth_rustle",
    mode: Core.Hit,
    anchor: Core.TurnEnd("AP08", 0.35),
    length: Core.Fixed(1.20),
    trimStart: 0.20,
    gainDb: -15.0,
    fadeIn: 0.05,
    fadeOut: 0.20,
  },
  {
    id: "S013_SEAT_MOVEMENT",
    assetId: "seat_scrape",
    mode: Core.Hit,
    anchor: Core.TurnEnd("AP08", 1.65),
    length: Core.Fixed(1.45),
    trimStart: 0.20,
    gainDb: -17.0,
    fadeIn: 0.04,
    fadeOut: 0.25,
  },
  {
    id: "S014_CLOTH_ROTATE",
    assetId: "cloth_rustle",
    mode: Core.Hit,
    anchor: Core.TurnEnd("AP08", 2.65),
    length: Core.Fixed(1.10),
    trimStart: 1.10,
    gainDb: -16.0,
    fadeIn: 0.04,
    fadeOut: 0.18,
  }]
  Belt.Array.concatMany([
  [trainCue],
  continuousBedCues(
    ~timeline,
    ~masterDuration,
    ~prefix="S002_WALLA_LOOP_",
    ~assetId="adult_passenger_walla",
    ~sourceSeconds=12.0,
    ~crossfade=1.00,
    ~gainDb=-14.0,
  ),
  continuousBedCues(
    ~timeline,
    ~masterDuration,
    ~prefix="S003_FAN_LOOP_",
    ~assetId="fan_rattle",
    ~sourceSeconds=52.0,
    ~crossfade=2.00,
    ~gainDb=-13.0,
  ),
  fixedCues,
  ])
}

let resolveCues = (
  ~timeline: array<Core.turnWindow>,
  ~masterDuration: float,
): (array<Core.resolvedClip>, float) => {
  let clips = cueSpecs(~timeline, ~masterDuration)->Belt.Array.map(spec =>
    Core.resolveClip(~turns=timeline, ~masterDuration, spec)
  )
  clips->Belt.Array.forEach(clip => {
    let asset = audioAssetFor(clip.spec.assetId)
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

let cueSignature = (spec: Core.clipCue): string => Js.Array2.joinWith([
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

let linePlanJson = (line: dialogueLine): Js.Json.t => {
  let root = Js.Dict.empty()
  addString(root, "id", line.id)
  addString(root, "speaker", speakerName(line.speaker))
  addString(root, "voice_id", memberFor(line.speaker).voiceId)
  addString(root, "expression_tag", line.tag)
  addString(root, "source_text", line.text)
  addString(root, "provider_text", providerText(line))
  addNumber(root, "characters", Belt.Int.toFloat(Js.String2.length(providerText(line))))
  addNumber(root, "estimated_seconds", estimateLineDuration(line))
  addNumber(root, "dry_timeline_gap_after_seconds", line.gapAfter)
  Js.Json.object_(root)
}

let castJson = (member: castMember): Js.Json.t => {
  let root = Js.Dict.empty()
  addString(root, "speaker", speakerName(member.speaker))
  addString(root, "account_name", member.accountName)
  addString(root, "voice_id", member.voiceId)
  switch member.publicOwnerId {
  | Some(owner) => {
      addString(root, "public_owner_id", owner)
      addBool(root, "shared_voice_add_if_missing", true)
    }
  | None => addBool(root, "shared_voice_add_if_missing", false)
  }
  Js.Json.object_(root)
}

let generatedSfxJson = (spec: generatedSfxSpec): Js.Json.t => {
  let root = Js.Dict.empty()
  addString(root, "id", spec.id)
  addString(root, "model", "eleven_text_to_sound_v2")
  addString(root, "output_format", "mp3_44100_128")
  addString(root, "request_sha256", sfxRequestHash(spec))
  addString(root, "raw_cache", sfxRawPath(spec))
  addNumber(root, "duration_seconds", spec.seconds)
  addNumber(root, "prompt_influence", spec.influence)
  addString(root, "prompt", spec.prompt)
  Js.Json.object_(root)
}

let pseJson = (asset: pseAsset): Js.Json.t => {
  let root = Js.Dict.empty()
  addString(root, "id", asset.id)
  addString(root, "path", asset.path)
  addString(root, "sha256", asset.sha256)
  addNumber(root, "duration_seconds", asset.duration)
  addString(root, "source", asset.source)
  Js.Json.object_(root)
}

let cueJson = (spec: Core.clipCue): Js.Json.t => {
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

let missingGeneratedSfx = (): array<generatedSfxSpec> =>
  generatedSfx->Belt.Array.keep(spec => verifySfxCache(spec) == None)

let planSignature = (
  ~estimatedTimeline: array<Core.turnWindow>,
  ~estimatedMaster: float,
  ~dialogueMissing: bool,
  ~missingSfx: array<generatedSfxSpec>,
): string => Js.Array2.joinWith([
  pipelineVersion,
  assemblyVersion,
  approvedScriptSha256,
  castSignature(),
  dialogueRequestHash(),
  lines->Belt.Array.map(line => line.id ++ "=" ++ providerText(line) ++ "=" ++ Js.Float.toString(line.gapAfter))->Js.Array2.joinWith("||"),
  generatedSfx->Belt.Array.map(sfxRequestSignature)->Js.Array2.joinWith("||"),
  pseAssets->Belt.Array.map(asset => asset.id ++ "=" ++ asset.sha256)->Js.Array2.joinWith("||"),
  cueSpecs(~timeline=estimatedTimeline, ~masterDuration=estimatedMaster)->Belt.Array.map(cueSignature)->Js.Array2.joinWith("||"),
  "dialogue_missing=" ++ (dialogueMissing ? dialogueRequestHash() : "none"),
  "sfx_missing=" ++ missingSfx->Belt.Array.map(sfxRequestHash)->Js.Array2.joinWith("|"),
  "initial_lead=" ++ Js.Float.toString(initialLead),
  "ap08_target_gap=3.8",
  "review_tail=" ++ Js.Float.toString(reviewTail),
  Core.masterMixConfig,
], "###")

let writePlan = (
  ~estimatedTimeline: array<Core.turnWindow>,
  ~estimatedMaster: float,
  ~estimatedOverlap: float,
  ~dialogueMissing: bool,
  ~missingSfx: array<generatedSfxSpec>,
): string => {
  let signature = planSignature(~estimatedTimeline, ~estimatedMaster, ~dialogueMissing, ~missingSfx)
  let planHash = sha256Text(signature)
  let path = planDir ++ "/AMAL_TRAIN_AUDIO_PROOF_PLAN_" ++ shortHash(planHash) ++ ".json"
  ensureDirPath(Path(planDir))
  let missingSfxSeconds = missingSfx->Belt.Array.reduce(0.0, (sum, spec) => sum +. spec.seconds)
  let root = Js.Dict.empty()
  addString(root, "schema", "amal.train-audio-proof-plan/v1")
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "assembly_version", assemblyVersion)
  addString(root, "canonical_script", scriptPath)
  addString(root, "canonical_script_sha256", approvedScriptSha256)
  addString(root, "plan_sha256", planHash)
  addString(root, "scope", "Opening compartment movement only, AP01 through AP11; no narrator and no action-line TTS.")
  addString(root, "dialogue_model", "eleven_v3 Text to Dialogue with timestamps")
  addString(root, "dialogue_output_format", "mp3_44100_128")
  addString(root, "dialogue_request_sha256", dialogueRequestHash())
  addString(root, "dialogue_raw_cache", dialogueRawPath())
  addNumber(root, "estimated_master_seconds", estimatedMaster)
  addNumber(root, "estimated_ambience_overlap_fraction", estimatedOverlap)
  addNumber(root, "initial_ambience_lead_seconds", initialLead)
  addNumber(root, "ap08_to_ap09_target_gap_seconds", 3.80)
  addNumber(root, "review_tail_seconds", reviewTail)
  addNumber(root, "missing_dialogue_requests", dialogueMissing ? 1.0 : 0.0)
  addNumber(root, "missing_dialogue_characters", dialogueMissing ? Belt.Int.toFloat(totalDialogueCharacters()) : 0.0)
  addNumber(root, "maximum_new_dialogue_requests", Belt.Int.toFloat(maxNewDialogueRequests))
  addNumber(root, "maximum_new_dialogue_characters", Belt.Int.toFloat(maxNewDialogueCharacters))
  addNumber(root, "missing_sfx_requests", Belt.Int.toFloat(Belt.Array.length(missingSfx)))
  addNumber(root, "missing_sfx_seconds", missingSfxSeconds)
  addNumber(root, "maximum_new_sfx_requests", Belt.Int.toFloat(maxNewSfxRequests))
  addNumber(root, "maximum_new_sfx_seconds", maxNewSfxSeconds)
  addNumber(root, "estimated_sfx_credits_at_40_per_second", missingSfxSeconds *. 40.0)
  addString(root, "paid_gate", "PAID=1 plus the required per-kind GENERATE flag plus APPROVED_PLAN_SHA256 exactly equal to this plan; DRY=1 always wins.")
  addString(root, "retry_policy", "Every paid call is claimed exclusively before request. A claim without an immutable cache blocks automatic retry.")
  addString(root, "timing_policy", "Preserve provider timing intact; insert only enough local ambience after AP08 to make its natural AP08-to-AP09 gap total 3.8 seconds.")
  addString(root, "mix_policy", "Continuous train, walla, and fan beds; detail cues overlap dialogue; SFX sidechains under voices and never advances the voice cursor.")
  Js.Dict.set(root, "cast", Js.Json.array(cast->Belt.Array.map(castJson)))
  Js.Dict.set(root, "dialogue", Js.Json.array(lines->Belt.Array.map(linePlanJson)))
  Js.Dict.set(root, "generated_sfx", Js.Json.array(generatedSfx->Belt.Array.map(generatedSfxJson)))
  Js.Dict.set(root, "owned_pse_assets", Js.Json.array(pseAssets->Belt.Array.map(pseJson)))
  Js.Dict.set(root, "cues", Js.Json.array(cueSpecs(~timeline=estimatedTimeline, ~masterDuration=estimatedMaster)->Belt.Array.map(cueJson)))
  let text = Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n"
  if exists(Path(path)) {
    if readText(Path(path)) != text {
      fail("content-addressed plan path contains different bytes: " ++ path)
    }
  } else if !writeTextExclusive(Path(path), text) {
    fail("could not publish content-addressed plan")
  }
  Js.log("PLAN -> " ++ path)
  Js.log("PLAN SHA-256 -> " ++ planHash)
  Js.log("MISSING DIALOGUE -> " ++ (dialogueMissing ? "1 request / " ++ Belt.Int.toString(totalDialogueCharacters()) ++ " characters" : "0"))
  Js.log("MISSING SFX -> " ++ Belt.Int.toString(Belt.Array.length(missingSfx)) ++ " requests / " ++ Js.Float.toString(missingSfxSeconds) ++ " seconds")
  planHash
}

let requirePaidPlan = (
  ~planHash: string,
  ~dialogueMissing: bool,
  ~missingSfx: array<generatedSfxSpec>,
): unit => {
  let dialogueRequests = dialogueMissing ? 1 : 0
  let dialogueChars = dialogueMissing ? totalDialogueCharacters() : 0
  let sfxSeconds = missingSfx->Belt.Array.reduce(0.0, (sum, spec) => sum +. spec.seconds)
  if dialogueRequests > maxNewDialogueRequests || dialogueChars > maxNewDialogueCharacters ||
     Belt.Array.length(missingSfx) > maxNewSfxRequests || sfxSeconds > maxNewSfxSeconds +. 0.001 {
    fail("missing provider work exceeds the approved paid ceilings")
  }
  if envDry == Some("1") || envPaid != Some("1") {
    fail("paid generation is locked; require PAID=1 with DRY unset")
  }
  if dialogueMissing && envGenerateDialogue != Some("1") {
    fail("missing dialogue requires GENERATE_DIALOGUE=1")
  }
  if Belt.Array.length(missingSfx) > 0 && envGenerateSfx != Some("1") {
    fail("missing sound effects require GENERATE_SFX=1")
  }
  if envApprovedPlan != Some(planHash) {
    fail("APPROVED_PLAN_SHA256 does not match this exact missing-work plan")
  }
}

let claimPaid = (~kind: string, ~id: string, ~hash: string): unit => {
  ensureDirPath(Path(claimDir))
  let path = claimDir ++ "/" ++ kind ++ "_" ++ hash ++ ".claim.json"
  let root = Js.Dict.empty()
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "kind", kind)
  addString(root, "id", id)
  addString(root, "request_sha256", hash)
  addString(root, "policy", "Claim written immediately before provider call. Existing claim plus missing cache is uncertain spend; automatic retry forbidden.")
  if !writeTextExclusive(Path(path), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n") {
    fail("paid attempt already claimed and cache is absent: " ++ kind ++ " " ++ id)
  }
}

let publishFetched = (
  ~audio: blob,
  ~extension: string,
  ~destination: string,
  ~label: string,
): float => {
  let scratch = tempDir("amal-train-provider-")->pathString
  let temporary = scratch ++ "/asset." ++ extension
  writeBytes(Path(temporary), audio)->ignore
  let duration = validateAudio(temporary, label)
  if !publishFileExclusive(Path(temporary), Path(destination)) {
    fail("refusing to overwrite immutable provider asset: " ++ destination)
  }
  duration
}

let prepareCast = async (): unit => {
  let index = ref(0)
  while index.contents < Belt.Array.length(cast) {
    let member = Belt.Array.getExn(cast, index.contents)
    let voice = VoiceId(member.voiceId)
    let available = await voiceAvailable(~voice)
    if !available {
      switch member.publicOwnerId {
      | Some(owner) => {
          Js.log("ADDING APPROVED SHARED VOICE -> " ++ speakerName(member.speaker) ++ " / " ++ member.voiceId)
          await addSharedVoice(
            ~publicOwner=PublicOwnerId(owner),
            ~voice,
            ~name=member.accountName,
          )
          if !(await voiceAvailable(~voice)) {
            fail("approved shared voice is still unavailable after add: " ++ member.voiceId)
          }
        }
      | None => fail("approved account voice is unavailable: " ++ member.voiceId)
      }
    }
    index := index.contents + 1
  }
}

let writeDialogueReceipt = (~cache: dialogueCache): unit => {
  let root = Js.Dict.empty()
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "kind", "dialogue")
  addString(root, "model", "eleven_v3")
  addString(root, "endpoint", "/v1/text-to-dialogue/with-timestamps")
  addString(root, "output_format", "mp3_44100_128")
  addString(root, "request_sha256", dialogueRequestHash())
  addString(root, "asset", cache.rawPath)
  addString(root, "asset_sha256", sha256File(Path(cache.rawPath)))
  addString(root, "timings", dialogueTimingPath())
  addString(root, "timings_sha256", sha256File(Path(dialogueTimingPath())))
  addNumber(root, "duration_seconds", cache.duration)
  if !writeTextExclusive(Path(dialogueReceiptPath()), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n") {
    fail("dialogue provider receipt already exists unexpectedly")
  }
}

let renderDialogue = async (): dialogueCache => switch verifyDialogueCache() {
| Some(cache) => cache
| None => {
    await prepareCast()
    let hash = dialogueRequestHash()
    claimPaid(~kind="dialogue", ~id="opening", ~hash)
    Js.log("PAID TEXT TO DIALOGUE -> 1 request / " ++ Belt.Int.toString(totalDialogueCharacters()) ++ " characters")
    let inputs = lines->Belt.Array.map(line => (
      Text(providerText(line)),
      VoiceId(memberFor(line.speaker).voiceId),
    ))
    let (audio, providerTimings) = await dialogueTimed(inputs)
    let rawPath = dialogueRawPath()
    let duration = publishFetched(~audio, ~extension="mp3", ~destination=rawPath, ~label="opening dialogue")
    let timings = providerTimings->Belt.Array.mapWithIndex((index, timing) => {
      let (start, end_) = timing
      {id: Belt.Array.getExn(lines, index).id, start, end_}
    })
    validateTimings(~rows=timings, ~duration)
    let timingText = dialogueTimingJson(~rows=timings, ~audioPath=rawPath, ~duration)
    if !writeTextExclusive(Path(dialogueTimingPath()), timingText) {
      fail("dialogue timing sidecar already exists unexpectedly")
    }
    let cache = {rawPath, duration, timings}
    writeDialogueReceipt(~cache)
    cache
  }
}

let writeSfxReceipt = (~spec: generatedSfxSpec, ~path: string, ~duration: float): unit => {
  let root = Js.Dict.empty()
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "kind", "sfx")
  addString(root, "id", spec.id)
  addString(root, "model", "eleven_text_to_sound_v2")
  addString(root, "output_format", "mp3_44100_128")
  addString(root, "request_sha256", sfxRequestHash(spec))
  addString(root, "asset", path)
  addString(root, "asset_sha256", sha256File(Path(path)))
  addNumber(root, "duration_seconds", duration)
  if !writeTextExclusive(Path(sfxReceiptPath(spec)), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n") {
    fail("SFX provider receipt already exists unexpectedly: " ++ spec.id)
  }
}

let renderGeneratedSfx = async (): unit => {
  ensureDirPath(Path(rawSfxDir))
  let index = ref(0)
  while index.contents < Belt.Array.length(generatedSfx) {
    let spec = Belt.Array.getExn(generatedSfx, index.contents)
    switch verifySfxCache(spec) {
    | Some(_) => ()
    | None => {
        let hash = sfxRequestHash(spec)
        claimPaid(~kind="sfx", ~id=spec.id, ~hash)
        Js.log("PAID SFX " ++ spec.id ++ " / " ++ Js.Float.toString(spec.seconds) ++ " seconds")
        let audio = await soundEffect(
          ~prompt=Prompt(spec.prompt),
          ~seconds=spec.seconds,
          ~influence=spec.influence,
        )
        let path = sfxRawPath(spec)
        let duration = publishFetched(~audio, ~extension="mp3", ~destination=path, ~label="SFX " ++ spec.id)
        writeSfxReceipt(~spec, ~path, ~duration)
      }
    }
    index := index.contents + 1
  }
}

let timingFor = (cache: dialogueCache, id: string): timedLine => switch Belt.Array.getBy(cache.timings, row => row.id == id) {
| Some(row) => row
| None => fail("dialogue cache has no timing for " ++ id)
}

let insertedActionGap = (cache: dialogueCache): float => {
  let before = timingFor(cache, "AP08")
  let after = timingFor(cache, "AP09")
  let natural = floatMax(0.0, after.start -. before.end_)
  floatMax(0.0, 3.80 -. natural)
}

let actualTimeline = (cache: dialogueCache): array<Core.turnWindow> => {
  let inserted = insertedActionGap(cache)
  cache.timings->Belt.Array.mapWithIndex((index, timing) => {
    let shift = index >= 8 ? inserted : 0.0
    let row: Core.turnWindow = {
      id: timing.id,
      start: initialLead +. timing.start +. shift,
      end_: initialLead +. timing.end_ +. shift,
    }
    row
  })
}

let actualMasterDuration = (cache: dialogueCache): float =>
  initialLead +. cache.duration +. insertedActionGap(cache) +. reviewTail

let derivativeManifest = path => path ++ ".manifest.json"

let verifyDerivative = (~path: string, ~fingerprint: string): bool => {
  let manifest = derivativeManifest(path)
  if !exists(Path(path)) && !exists(Path(manifest)) {
    false
  } else if !exists(Path(path)) || !exists(Path(manifest)) {
    fail("content-addressed derivative is incomplete: " ++ path)
  } else {
    let json = Js.Json.parseExn(readText(Path(manifest)))
    if stringField(json, "fingerprint_sha256") != fingerprint ||
       stringField(json, "audio_sha256") != sha256File(Path(path)) {
      fail("content-addressed derivative does not match its manifest: " ++ path)
    }
    validateAudio(path, "cached derivative")->ignore
    true
  }
}

let publishDerivative = (
  ~temporary: string,
  ~path: string,
  ~fingerprint: string,
  ~kind: string,
): unit => {
  let duration = validateAudio(temporary, kind)
  if !publishFileExclusive(Path(temporary), Path(path)) {
    fail("refusing to overwrite derivative: " ++ path)
  }
  let root = Js.Dict.empty()
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "kind", kind)
  addString(root, "fingerprint_sha256", fingerprint)
  addString(root, "audio", path)
  addString(root, "audio_sha256", sha256File(Path(path)))
  addNumber(root, "duration_seconds", duration)
  if !writeTextExclusive(Path(derivativeManifest(path)), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n") {
    fail("refusing to overwrite derivative manifest: " ++ derivativeManifest(path))
  }
}

let buildVoiceLane = (
  ~cache: dialogueCache,
  ~masterDuration: float,
): string => {
  ensureDirPath(Path(outDir))
  let ap08 = timingFor(cache, "AP08")
  let ap09 = timingFor(cache, "AP09")
  let split = (ap08.end_ +. ap09.start) /. 2.0
  if split <= 0.0 || split >= cache.duration {
    fail("provider timing cannot form the AP08/AP09 action edit")
  }
  let inserted = insertedActionGap(cache)
  let config = "voice|dialogueTimed-native|single-gap-edit|48k-stereo|highpass55|assembled-loudnorm=-18/-3/11"
  let fingerprint = sha256Text(Js.Array2.joinWith([
    assemblyVersion,
    config,
    sha256File(Path(cache.rawPath)),
    sha256File(Path(dialogueTimingPath())),
    Js.Float.toString(split),
    Js.Float.toString(inserted),
    Js.Float.toString(masterDuration),
  ], "###"))
  let path = outDir ++ "/voice_" ++ shortHash(fingerprint) ++ ".wav"
  if !verifyDerivative(~path, ~fingerprint) {
    let scratch = tempDir("amal-train-voice-")->pathString
    let temporary = scratch ++ "/voice.wav"
    let postDelay = initialLead +. split +. inserted
    let graph =
      "[0:a]asplit=2[pre_source][post_source];" ++
      "[pre_source]atrim=start=0:end=" ++ Js.Float.toString(split) ++ ",asetpts=PTS-STARTPTS," ++
      "aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo,highpass=f=55," ++
      "adelay=" ++ Belt.Int.toString(Belt.Float.toInt(initialLead *. 1000.0)) ++ ":all=1[pre];" ++
      "[post_source]atrim=start=" ++ Js.Float.toString(split) ++ ":end=" ++ Js.Float.toString(cache.duration) ++
      ",asetpts=PTS-STARTPTS,aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo,highpass=f=55," ++
      "adelay=" ++ Belt.Int.toString(Belt.Float.toInt(postDelay *. 1000.0)) ++ ":all=1[post];" ++
      "anullsrc=r=48000:cl=stereo:d=" ++ Js.Float.toString(masterDuration) ++ "[clock];" ++
      "[clock][pre][post]amix=inputs=3:duration=first:normalize=0:dropout_transition=0," ++
      "loudnorm=I=-18:TP=-3:LRA=11,atrim=0:" ++ Js.Float.toString(masterDuration) ++ "[out]"
    ffmpeg([
      "-nostdin", "-v", "error", "-n", "-i", cache.rawPath,
      "-filter_complex", graph, "-map", "[out]", "-ar", "48000", "-ac", "2", "-c:a", "pcm_s24le", temporary,
    ])
    publishDerivative(~temporary, ~path, ~fingerprint, ~kind="assembled dialogue voice lane")
  }
  path
}

let clipFingerprint = (clip: Core.resolvedClip): string => {
  let asset = audioAssetFor(clip.spec.assetId)
  Js.Array2.joinWith([
    cueSignature(clip.spec),
    asset.sha256,
    Js.Float.toString(clip.start),
    Js.Float.toString(clip.end_),
  ], "|")
}

let buildSfxLane = (
  ~clips: array<Core.resolvedClip>,
  ~masterDuration: float,
): string => {
  ensureDirPath(Path(outDir))
  let config = "sfx|per-source-loudnorm=-24/-4/11|highpass35|48k-stereo|limit=.88"
  let fingerprint = sha256Text(Js.Array2.joinWith([
    assemblyVersion,
    config,
    Js.Float.toString(masterDuration),
    clips->Belt.Array.map(clipFingerprint)->Js.Array2.joinWith("||"),
  ], "###"))
  let path = outDir ++ "/sfx_" ++ shortHash(fingerprint) ++ ".wav"
  if !verifyDerivative(~path, ~fingerprint) {
    let scratch = tempDir("amal-train-sfx-")->pathString
    let temporary = scratch ++ "/sfx.wav"
    let inputs = clips->Belt.Array.map(clip => ["-i", audioAssetFor(clip.spec.assetId).path])->Belt.Array.concatMany
    let chains = clips->Belt.Array.mapWithIndex((index, clip) => {
      let duration = clip.end_ -. clip.start
      let fadeOutStart = duration -. clip.spec.fadeOut
      let fadeIn = clip.spec.fadeIn > 0.0
        ? "afade=t=in:st=0:d=" ++ Js.Float.toString(clip.spec.fadeIn) ++ ","
        : ""
      let fadeOut = clip.spec.fadeOut > 0.0
        ? "afade=t=out:st=" ++ Js.Float.toString(fadeOutStart) ++ ":d=" ++ Js.Float.toString(clip.spec.fadeOut) ++ ","
        : ""
      "[" ++ Belt.Int.toString(index) ++ ":a]" ++
      "atrim=start=" ++ Js.Float.toString(clip.spec.trimStart) ++ ":end=" ++
      Js.Float.toString(clip.spec.trimStart +. duration) ++ ",asetpts=PTS-STARTPTS," ++
      "aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo," ++
      "highpass=f=35,loudnorm=I=-24:TP=-4:LRA=11," ++ fadeIn ++ fadeOut ++
      "volume=" ++ Js.Float.toString(clip.spec.gainDb) ++ "dB," ++
      "adelay=" ++ Belt.Int.toString(Belt.Float.toInt(clip.start *. 1000.0)) ++ ":all=1[c" ++
      Belt.Int.toString(index) ++ "]"
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
    publishDerivative(~temporary, ~path, ~fingerprint, ~kind="layered ambience and SFX lane")
  }
  path
}

let buildSilentMusicLane = (~masterDuration: float): string => {
  ensureDirPath(Path(outDir))
  let fingerprint = sha256Text(assemblyVersion ++ "|intentional-silent-music|" ++ Js.Float.toString(masterDuration))
  let path = outDir ++ "/music_silent_" ++ shortHash(fingerprint) ++ ".wav"
  if !verifyDerivative(~path, ~fingerprint) {
    let scratch = tempDir("amal-train-music-")->pathString
    let temporary = scratch ++ "/music.wav"
    ffmpeg([
      "-nostdin", "-v", "error", "-n", "-f", "lavfi", "-i",
      "anullsrc=r=48000:cl=stereo", "-t", Js.Float.toString(masterDuration),
      "-c:a", "pcm_s24le", temporary,
    ])
    publishDerivative(~temporary, ~path, ~fingerprint, ~kind="intentional silent music lane")
  }
  path
}

let buildMaster = (
  ~voicePath: string,
  ~sfxPath: string,
  ~musicPath: string,
  ~masterDuration: float,
): (string, string, string) => {
  ensureDirPath(Path(reviewDir))
  let fingerprint = sha256Text(Js.Array2.joinWith([
    assemblyVersion,
    Core.masterMixConfig,
    Js.Float.toString(masterDuration),
    sha256File(Path(voicePath)),
    sha256File(Path(sfxPath)),
    sha256File(Path(musicPath)),
  ], "###"))
  let wavPath = outDir ++ "/master_" ++ shortHash(fingerprint) ++ ".wav"
  if !verifyDerivative(~path=wavPath, ~fingerprint) {
    let scratch = tempDir("amal-train-master-")->pathString
    let temporary = scratch ++ "/master.wav"
    ffmpeg([
      "-nostdin", "-v", "error", "-n", "-i", voicePath, "-i", sfxPath, "-i", musicPath,
      "-filter_complex", Core.masterMixGraph(~duration=masterDuration), "-map", "[out]",
      "-ar", "48000", "-ac", "2", "-c:a", "pcm_s24le", temporary,
    ])
    publishDerivative(~temporary, ~path=wavPath, ~fingerprint, ~kind="final WAV master")
  }
  let m4aFingerprint = sha256Text(fingerprint ++ "|" ++ sha256File(Path(wavPath)) ++ "|aac-256k-48k-stereo")
  let m4aPath = reviewDir ++ "/AMAL_THE_TRAIN_OPENING_PROOF_" ++ shortHash(m4aFingerprint) ++ ".m4a"
  if !verifyDerivative(~path=m4aPath, ~fingerprint=m4aFingerprint) {
    let scratch = tempDir("amal-train-review-")->pathString
    let temporary = scratch ++ "/review.m4a"
    ffmpeg([
      "-nostdin", "-v", "error", "-n", "-i", wavPath,
      "-map", "0:a:0", "-map_metadata", "-1", "-c:a", "aac", "-b:a", "256k",
      "-ar", "48000", "-ac", "2", "-movflags", "+faststart",
      "-metadata", "title=AMAL — The Train — Opening Proof", temporary,
    ])
    publishDerivative(~temporary, ~path=m4aPath, ~fingerprint=m4aFingerprint, ~kind="review M4A")
  }
  (wavPath, m4aPath, fingerprint)
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
  if stats.integrated < -16.8 || stats.integrated > -15.2 {
    fail(label ++ " integrated loudness is outside -16.0 ±0.8 LUFS")
  }
  if stats.truePeak > peakCeiling {
    fail(label ++ " true peak exceeds " ++ Js.Float.toString(peakCeiling) ++ " dBTP")
  }
  if stats.lra < 2.0 || stats.lra > 12.0 {
    fail(label ++ " loudness range is outside 2–12 LU")
  }
}

let finalQc = (
  ~wavPath: string,
  ~m4aPath: string,
  ~masterDuration: float,
): (loudnessStats, loudnessStats) => {
  let wavDuration = validateAudio(wavPath, "final WAV")
  let m4aDuration = validateAudio(m4aPath, "review M4A")
  if masterDuration < 35.0 || masterDuration > 120.0 {
    fail("opening proof runtime is outside the honest 35–120 second envelope")
  }
  if Js.Math.abs_float(wavDuration -. masterDuration) > 0.10 ||
     Js.Math.abs_float(m4aDuration -. masterDuration) > 0.10 ||
     Js.Math.abs_float(wavDuration -. m4aDuration) > 0.10 {
    fail("final duration QC failed")
  }
  let silence = run(
    ~cmd="ffmpeg",
    ~args=["-nostdin", "-hide_banner", "-i", wavPath, "-af", "silencedetect=noise=-55dB:d=2.5", "-f", "null", "-"],
  )
  let unexpected = silence.stderr->Js.String2.split("\n")->Belt.Array.keep(line => contains(line, "silence_duration:"))
  if Belt.Array.length(unexpected) > 0 {
    fail("continuous compartment master contains unintended silence longer than 2.5 seconds")
  }
  let wavStats = analyzeLoudness(wavPath, "WAV")
  let m4aStats = analyzeLoudness(m4aPath, "M4A")
  validateLoudness(~stats=wavStats, ~label="WAV", ~peakCeiling=-1.5)
  validateLoudness(~stats=m4aStats, ~label="M4A", ~peakCeiling=-1.0)
  Js.log("QC PASS -> " ++ Js.Float.toString(masterDuration) ++ " seconds / " ++
    Js.Float.toString(m4aStats.integrated) ++ " LUFS / " ++ Js.Float.toString(m4aStats.truePeak) ++ " dBTP")
  (wavStats, m4aStats)
}

let resolvedCueJson = (clip: Core.resolvedClip): Js.Json.t => {
  let root = cueJson(clip.spec)->Js.Json.decodeObject->Belt.Option.getExn
  let asset = audioAssetFor(clip.spec.assetId)
  addNumber(root, "start_seconds", clip.start)
  addNumber(root, "end_seconds", clip.end_)
  addString(root, "source", asset.path)
  addString(root, "source_sha256", asset.sha256)
  Js.Json.object_(root)
}

let writeMasterManifest = (
  ~cache: dialogueCache,
  ~timeline: array<Core.turnWindow>,
  ~clips: array<Core.resolvedClip>,
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
  ~newDialogueRequests: int,
  ~newSfxRequests: int,
  ~newSfxSeconds: float,
): string => {
  let path = projectDir ++ "/AMAL_TRAIN_AUDIO_PROOF_MASTER_" ++ shortHash(masterFingerprint) ++ ".manifest.json"
  let root = Js.Dict.empty()
  addString(root, "schema", "amal.train-audio-proof-master/v1")
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "assembly_version", assemblyVersion)
  addString(root, "canonical_script", scriptPath)
  addString(root, "canonical_script_sha256", approvedScriptSha256)
  addString(root, "plan_sha256", planHash)
  addString(root, "master_fingerprint_sha256", masterFingerprint)
  addString(root, "scope", "Canonical AP01–AP11 opening; no Ratan, Deva, narrator, or action-line speech.")
  addNumber(root, "duration_seconds", masterDuration)
  addNumber(root, "ambience_overlap_fraction", overlap)
  addNumber(root, "provider_natural_ap08_ap09_gap_seconds", timingFor(cache, "AP09").start -. timingFor(cache, "AP08").end_)
  addNumber(root, "inserted_action_gap_seconds", insertedActionGap(cache))
  addString(root, "dialogue_provider_asset", cache.rawPath)
  addString(root, "dialogue_provider_asset_sha256", sha256File(Path(cache.rawPath)))
  addString(root, "dialogue_timings", dialogueTimingPath())
  addString(root, "dialogue_timings_sha256", sha256File(Path(dialogueTimingPath())))
  addString(root, "dialogue_request_sha256", dialogueRequestHash())
  addString(root, "voice_lane", voicePath)
  addString(root, "voice_lane_sha256", sha256File(Path(voicePath)))
  addString(root, "sfx_lane", sfxPath)
  addString(root, "sfx_lane_sha256", sha256File(Path(sfxPath)))
  addString(root, "music_lane", musicPath)
  addString(root, "music_policy", "Intentional silence: the proof tests dialogue and diegetic compartment sound before score.")
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
  addNumber(root, "new_dialogue_requests", Belt.Int.toFloat(newDialogueRequests))
  addNumber(root, "new_sfx_requests", Belt.Int.toFloat(newSfxRequests))
  addNumber(root, "new_sfx_seconds", newSfxSeconds)
  Js.Dict.set(root, "cast", Js.Json.array(cast->Belt.Array.map(castJson)))
  Js.Dict.set(root, "dialogue", Js.Json.array(lines->Belt.Array.mapWithIndex((index, line) => {
    let providerTiming = Belt.Array.getExn(cache.timings, index)
    let window = Belt.Array.getExn(timeline, index)
    let row = Js.Dict.empty()
    addString(row, "id", line.id)
    addString(row, "speaker", speakerName(line.speaker))
    addString(row, "voice_id", memberFor(line.speaker).voiceId)
    addString(row, "source_text", line.text)
    addString(row, "provider_text", providerText(line))
    addNumber(row, "provider_start_seconds", providerTiming.start)
    addNumber(row, "provider_end_seconds", providerTiming.end_)
    addNumber(row, "master_start_seconds", window.start)
    addNumber(row, "master_end_seconds", window.end_)
    Js.Json.object_(row)
  })))
  Js.Dict.set(root, "generated_sfx", Js.Json.array(generatedSfx->Belt.Array.map(spec => {
    let asset = verifySfxCache(spec)->Belt.Option.getExn
    let row = generatedSfxJson(spec)->Js.Json.decodeObject->Belt.Option.getExn
    addString(row, "provider_asset", asset.path)
    addString(row, "provider_asset_sha256", asset.sha256)
    addNumber(row, "provider_duration_seconds", asset.duration)
    Js.Json.object_(row)
  })))
  Js.Dict.set(root, "owned_pse_assets", Js.Json.array(pseAssets->Belt.Array.map(pseJson)))
  Js.Dict.set(root, "cues", Js.Json.array(clips->Belt.Array.map(resolvedCueJson)))
  let text = Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n"
  if exists(Path(path)) {
    if readText(Path(path)) != text {
      fail("content-addressed master manifest contains different bytes")
    }
  } else if !writeTextExclusive(Path(path), text) {
    fail("could not publish content-addressed master manifest")
  }
  path
}

let main = async (): unit => {
  validateCanon()
  validateCast()
  validatePseAssets()
  validateSfxPrompts()

  let cachedDialogue = verifyDialogueCache()
  let dialogueMissing = cachedDialogue == None
  let missingSfx = missingGeneratedSfx()
  let newDialogueRequests = dialogueMissing ? 1 : 0
  let newSfxRequests = Belt.Array.length(missingSfx)
  let newSfxSeconds = missingSfx->Belt.Array.reduce(0.0, (sum, spec) => sum +. spec.seconds)

  let estimateInputs = estimatedInputs()
  let estimatedTimeline = Core.buildTurnTimeline(~turns=estimateInputs, ~initialLead)
  let estimatedMaster = masterDurationFor(estimatedTimeline)
  let (_, estimatedOverlap) = resolveCues(~timeline=estimatedTimeline, ~masterDuration=estimatedMaster)
  let planHash = writePlan(
    ~estimatedTimeline,
    ~estimatedMaster,
    ~estimatedOverlap,
    ~dialogueMissing,
    ~missingSfx,
  )

  if envDry == Some("1") {
    Js.log("DRY PASS — canon, cast, owned assets, timing design, overlap, exact missing work, and paid ceilings validated; zero network or provider calls.")
  } else {
    if dialogueMissing || Belt.Array.length(missingSfx) > 0 {
      requirePaidPlan(~planHash, ~dialogueMissing, ~missingSfx)
    }
    let cache = await renderDialogue()
    await renderGeneratedSfx()
    let timeline = actualTimeline(cache)
    let masterDuration = actualMasterDuration(cache)
    let (clips, overlap) = resolveCues(~timeline, ~masterDuration)
    let voicePath = buildVoiceLane(~cache, ~masterDuration)
    let sfxPath = buildSfxLane(~clips, ~masterDuration)
    let musicPath = buildSilentMusicLane(~masterDuration)
    let (wavPath, m4aPath, masterFingerprint) = buildMaster(
      ~voicePath,
      ~sfxPath,
      ~musicPath,
      ~masterDuration,
    )
    let (wavStats, m4aStats) = finalQc(~wavPath, ~m4aPath, ~masterDuration)
    let manifest = writeMasterManifest(
      ~cache,
      ~timeline,
      ~clips,
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
      ~newDialogueRequests,
      ~newSfxRequests,
      ~newSfxSeconds,
    )
    Js.log("MASTER WAV -> " ++ wavPath)
    Js.log("REVIEW M4A -> " ++ m4aPath)
    Js.log("MANIFEST -> " ++ manifest)
  }
}

main()
->Js.Promise2.catch(error => {
  Js.log2("AMAL TRAIN AUDIO PROOF FAILED:", error)
  exit(1)
  Js.Promise.resolve()
})
->ignore
