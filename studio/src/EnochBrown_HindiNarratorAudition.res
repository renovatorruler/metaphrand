/* Hindi oral-historian narrator comparison reel.

   House format: each candidate identifies himself in Hindi and reads the same
   Hindustani passage. No music, SFX, announcer, or voice-specific processing.

   Dry inventory:
     node src/EnochBrown_HindiNarratorAudition.res.mjs

   Authorized generation:
     PAID=1 GENERATE=1 node src/EnochBrown_HindiNarratorAudition.res.mjs
*/
open Cinema_Backends

@val @scope(("process", "env")) external envPaid: option<string> = "PAID"
@val @scope(("process", "env")) external envGenerate: option<string> = "GENERATE"

exception AuditionError(string)

type candidate = {
  key: string,
  catalogName: string,
  spokenName: string,
  voiceId: string,
}

type rendered = {
  candidate: candidate,
  rawPath: path,
  normalizedPath: path,
  requestText: string,
  requestHash: string,
  rawSha256: string,
  normalizedSha256: string,
  normalizedDuration: float,
}

let candidates = [
  {
    key: "01-natraj",
    catalogName: "Natraj - Gripping Suspense Narrator",
    spokenName: "नटराज",
    voiceId: "XSBqeYvLRWlUwJ57A64w",
  },
  {
    key: "02-shyam",
    catalogName: "Shyam - Natural & Clear Assistant",
    spokenName: "श्याम",
    voiceId: "5ycO0zpSCEkvR4Ri6gk9",
  },
  {
    key: "03-ajay",
    catalogName: "Ajay - Cinematic Suspense Narrator",
    spokenName: "अजय",
    voiceId: "HtKVOQM66dc5A1XMu8Np",
  },
  {
    key: "04-kuber",
    catalogName: "Kuber - Ramayana & Mahabharata Narrator",
    spokenName: "कुबेर",
    voiceId: "sZk20flPPGUa0sDxsZ8t",
  },
  {
    key: "05-ash",
    catalogName: "Ash - Story, Instruction & Information",
    spokenName: "ऐश",
    voiceId: "XYJilqzgZnnmkbEWyhtr",
  },
]

let excerpt =
  "[curious] ज़रा सोचिए। आप एक स्कूल के पास से गुज़र रहे हैं। आम दिनों में वहाँ से बच्चों का शोर सुनाई देता है। " ++
  "मगर आज कुछ नहीं। शायद छुट्टी जल्दी हो गई हो। आप यही मानना चाहेंगे, क्योंकि तब दिन मामूली रहता है। " ++
  "लेकिन अगर नहीं? क्या आप भीतर जाते? एक आदमी गया। वहाँ मास्टर ब्राउन और बच्चे मारे गए थे। " ++
  "एक बच्चा बुरी तरह घायल था, मगर ज़िंदा। अब बताइए—आपको लगा था यह किस साल की बात है? " ++
  "तारीख़ थी छब्बीस जुलाई, सत्रह सौ चौंसठ। यूनाइटेड स्टेट्स अभी बना भी नहीं था।"

let productionDir = "../stories/enoch-brown/production/hindi_narrator_audition_v1"
let cacheDir = productionDir ++ "/cache"
let reviewDir = productionDir ++ "/review"
let outputPath = reviewDir ++ "/ENOCH_BROWN_HINDI_NARRATOR_AUDITION_V1.mp3"
let manifestPath = reviewDir ++ "/ENOCH_BROWN_HINDI_NARRATOR_AUDITION_V1.manifest.json"
let fixedSeed = 17640830
let settings: productionVoiceSettings = {stability: 0.5, speed: 0.94}
let languageCode = "hi"
let model = "eleven_v3"
let gapMillis = 1800
let leadMillis = 400

let textFor = candidate => "मेरा नाम " ++ candidate.spokenName ++ " है।\n\n" ++ excerpt

let requestHashFor = candidate =>
  sha256Text(
    Js.Array2.joinWith([
      model,
      languageCode,
      candidate.voiceId,
      Belt.Int.toString(fixedSeed),
      Js.Float.toString(settings.stability),
      Js.Float.toString(settings.speed),
      textFor(candidate),
    ], "|"),
  )

let rawPathFor = candidate =>
  cacheDir ++ "/" ++ candidate.key ++ "-" ++
  requestHashFor(candidate)->Js.String2.slice(~from=0, ~to_=16) ++ ".wav"

let normalizedPathFor = candidate => cacheDir ++ "/" ++ candidate.key ++ "-normalized.mp3"

let authorized = (): bool =>
  switch (envPaid, envGenerate) {
  | (Some("1"), Some("1")) => true
  | _ => false
  }

let missingCandidates = () => candidates->Belt.Array.keep(candidate => !exists(Path(rawPathFor(candidate))))

let printInventory = (): unit => {
  let missing = missingCandidates()
  let chars = missing->Belt.Array.reduce(0, (sum, candidate) => sum + Js.String2.length(textFor(candidate)))
  Js.log(
    "HINDI NARRATOR AUDITION DRY INVENTORY: " ++ Belt.Int.toString(Belt.Array.length(missing)) ++
    " missing Eleven v3 request(s), " ++ Belt.Int.toString(chars) ++ " characters total",
  )
  missing->Belt.Array.forEach(candidate =>
    Js.log(
      "MISSING\t" ++ candidate.catalogName ++ "\t" ++ candidate.voiceId ++ "\t" ++
      Belt.Int.toString(Js.String2.length(textFor(candidate))) ++ " characters",
    )
  )
}

let renderCandidate = async candidate => {
  let requestText = textFor(candidate)
  let requestHash = requestHashFor(candidate)
  let rawPathString = rawPathFor(candidate)
  if !exists(Path(rawPathString)) {
    if !authorized() {
      raise(AuditionError("Generation requires PAID=1 and GENERATE=1."))
    }
    Js.log(
      "Eleven v3 Hindi: " ++ candidate.catalogName ++ " (" ++
      Belt.Int.toString(Js.String2.length(requestText)) ++ " characters)",
    )
    let audio = await productionTtsForLanguage(
      ~text=Text(requestText),
      ~voice=VoiceId(candidate.voiceId),
      ~languageCode,
      ~seed=fixedSeed,
      ~settings,
    )
    writeBytes(Path(rawPathString), audio)->ignore
  } else {
    Js.log("Cached: " ++ candidate.catalogName)
  }

  let normalizedPathString = normalizedPathFor(candidate)
  ffmpeg([
    "-nostdin",
    "-loglevel",
    "error",
    "-y",
    "-i",
    rawPathString,
    "-af",
    "loudnorm=I=-18:TP=-2:LRA=7",
    "-ar",
    "44100",
    "-ac",
    "1",
    "-codec:a",
    "libmp3lame",
    "-b:a",
    "128k",
    normalizedPathString,
  ])
  let Seconds(normalizedDuration) = durationSec(Path(normalizedPathString))
  if normalizedDuration < 8.0 {
    raise(AuditionError(candidate.catalogName ++ " rendered implausibly short or silent."))
  }
  {
    candidate,
    rawPath: Path(rawPathString),
    normalizedPath: Path(normalizedPathString),
    requestText,
    requestHash,
    rawSha256: sha256File(Path(rawPathString)),
    normalizedSha256: sha256File(Path(normalizedPathString)),
    normalizedDuration,
  }
}

let rec renderAll = async (index, results) => {
  if index >= Belt.Array.length(candidates) {
    results
  } else {
    let candidate = Belt.Array.getExn(candidates, index)
    let result = await renderCandidate(candidate)
    await renderAll(index + 1, Belt.Array.concatMany([results, [result]]))
  }
}

let assemblyParts = (results: array<rendered>): array<path> => {
  let lead = silence(Millis(leadMillis), Path(cacheDir))
  let gap = silence(Millis(gapMillis), Path(cacheDir))
  let parts = ref([lead])
  results->Belt.Array.forEachWithIndex((index, result) => {
    if index > 0 {
      parts := Belt.Array.concatMany([parts.contents, [gap]])
    }
    parts := Belt.Array.concatMany([parts.contents, [result.normalizedPath]])
  })
  parts.contents
}

let addString = (dict, key, value) => Js.Dict.set(dict, key, Js.Json.string(value))
let addNumber = (dict, key, value) => Js.Dict.set(dict, key, Js.Json.number(value))

let renderedJson = result => {
  let row = Js.Dict.empty()
  addString(row, "catalog_name", result.candidate.catalogName)
  addString(row, "spoken_name", result.candidate.spokenName)
  addString(row, "voice_id", result.candidate.voiceId)
  addString(row, "request_sha256", result.requestHash)
  addNumber(row, "request_characters", Belt.Int.toFloat(Js.String2.length(result.requestText)))
  addString(row, "raw_path", switch result.rawPath { | Path(value) => value })
  addString(row, "raw_sha256", result.rawSha256)
  addString(row, "normalized_path", switch result.normalizedPath { | Path(value) => value })
  addString(row, "normalized_sha256", result.normalizedSha256)
  addNumber(row, "normalized_duration_seconds", result.normalizedDuration)
  Js.Json.object_(row)
}

let writeManifest = (~results, ~duration, ~expectedDuration): unit => {
  let root = Js.Dict.empty()
  addString(root, "status", "COMPLETE NAMED HINDI NARRATOR AUDITION")
  addString(root, "speech_model", model)
  addString(root, "language_code", languageCode)
  addNumber(root, "seed", Belt.Int.toFloat(fixedSeed))
  addNumber(root, "stability", settings.stability)
  addNumber(root, "speed", settings.speed)
  addString(root, "excerpt", excerpt)
  addString(root, "excerpt_sha256", sha256Text(excerpt))
  addNumber(root, "candidate_count", Belt.Int.toFloat(Belt.Array.length(results)))
  addNumber(root, "lead_milliseconds", Belt.Int.toFloat(leadMillis))
  addNumber(root, "between_candidate_gap_milliseconds", Belt.Int.toFloat(gapMillis))
  addString(root, "music", "none")
  addString(root, "sound_effects", "none")
  addString(root, "output_path", outputPath)
  addString(root, "output_sha256", sha256File(Path(outputPath)))
  addNumber(root, "output_duration_seconds", duration)
  addNumber(root, "expected_duration_seconds", expectedDuration)
  Js.Dict.set(root, "candidates", Js.Json.array(results->Belt.Array.map(renderedJson)))
  writeText(Path(manifestPath), Js.Json.stringify(Js.Json.object_(root)) ++ "\n")
}

let main = async () => {
  printInventory()
  if !authorized() {
    Js.log("DRY ONLY: no provider generation and no assembly performed.")
  } else {
    let results = await renderAll(0, [])
    concatAudio(assemblyParts(results), Path(outputPath))->ignore
    let Seconds(duration) = durationSec(Path(outputPath))
    let clipDuration = results->Belt.Array.reduce(0.0, (sum, result) => sum +. result.normalizedDuration)
    let expectedDuration =
      Belt.Int.toFloat(leadMillis) /. 1000.0 +. clipDuration +.
      Belt.Int.toFloat(gapMillis * (Belt.Array.length(results) - 1)) /. 1000.0
    if duration < 60.0 || Js.Math.abs_float(duration -. expectedDuration) > 1.0 {
      raise(
        AuditionError(
          "Final reel duration failed: got " ++ Js.Float.toString(duration) ++
          "s, expected " ++ Js.Float.toString(expectedDuration) ++ "s.",
        ),
      )
    }
    writeManifest(~results, ~duration, ~expectedDuration)
    Js.log(
      "HINDI NARRATOR AUDITION -> " ++ outputPath ++ " (" ++
      Js.Float.toFixedWithPrecision(duration, ~digits=2) ++ "s, sha256 " ++
      sha256File(Path(outputPath)) ++ ")",
    )
  }
}

main()->ignore
