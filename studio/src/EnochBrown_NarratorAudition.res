/* Enoch Brown V4 narrator comparison reel.

   Each candidate identifies himself, then reads the same verbatim cold-open
   excerpt with the same Eleven v3 expression tag and voice settings. The final
   deliverable is one MP3 with clean silence between candidates.

   Run from studio/:
     PAID=1 node src/EnochBrown_NarratorAudition.res.mjs

   Cached provider WAVs make a rerun free unless the text, voice, seed, or
   settings change. */
open Cinema_Backends

@val @scope(("process", "env")) external envPaid: option<string> = "PAID"

exception AuditionError(string)

type candidate = {
  key: string,
  spokenName: string,
  voiceId: string,
}

let candidates = [
  {key: "01-jacob-michael", spokenName: "Jacob Michael", voiceId: "PKu46bbccMP1b22TyeI0"},
  {key: "02-jeff-feller", spokenName: "Jeff Feller", voiceId: "lnFzEtvLAfx8I9DtiJTS"},
  {key: "03-corey", spokenName: "Corey", voiceId: "lZtucxLlxRTm0qWZ3pI2"},
  {key: "04-apollo-benz", spokenName: "Apollo Benz", voiceId: "kcRa39aRSoOSv6fa7PQ3"},
  {key: "05-pj", spokenName: "P. J.", voiceId: "z1qPOZqNGeHVkqPLGwJV"},
]

let excerpt =
  "[curious] That is what makes one sentence in a colonial newspaper so hard to shake. " ++
  "The writer gives us no alarm and no warning from the road; by the time his unnamed " ++
  "passerby appears, whatever happened inside is already over, and all the man has to go " ++
  "on is that he is close enough to hear a school and the school is making no sound."

let productionDir = "../stories/enoch-brown/production/narrator_audition_v4"
let cacheDir = productionDir ++ "/cache"
let reviewDir = productionDir ++ "/review"
let outputPath = reviewDir ++ "/ENOCH_BROWN_NARRATOR_AUDITION_V4.mp3"
let fixedSeed = 17640829
let settings: productionVoiceSettings = {stability: 0.5, speed: 0.94}

let textFor = candidate => "My name is " ++ candidate.spokenName ++ ".\n\n" ++ excerpt

let requirePaid = (): unit =>
  switch envPaid {
  | Some("1") => ()
  | _ => raise(AuditionError("Set PAID=1 to authorize the five Eleven v3 audition requests."))
  }

let rawPathFor = candidate => {
  let requestIdentity =
    Js.Array2.joinWith([
      "eleven_v3",
      candidate.voiceId,
      Belt.Int.toString(fixedSeed),
      Js.Float.toString(settings.stability),
      Js.Float.toString(settings.speed),
      textFor(candidate),
    ], "|")
  let requestHash = sha256Text(requestIdentity)->Js.String2.slice(~from=0, ~to_=16)
  cacheDir ++ "/" ++ candidate.key ++ "-" ++ requestHash ++ ".wav"
}

let normalizedPathFor = candidate => cacheDir ++ "/" ++ candidate.key ++ "-normalized.mp3"

let renderCandidate = async candidate => {
  let rawPath = rawPathFor(candidate)
  if !exists(Path(rawPath)) {
    requirePaid()
    Js.log(
      "Eleven v3: " ++ candidate.spokenName ++ " (" ++
      Belt.Int.toString(Js.String2.length(textFor(candidate))) ++ " characters)",
    )
    let audio = await productionTts(
      ~text=Text(textFor(candidate)),
      ~voice=VoiceId(candidate.voiceId),
      ~seed=fixedSeed,
      ~settings,
    )
    writeBytes(Path(rawPath), audio)->ignore
  } else {
    Js.log("Cached: " ++ candidate.spokenName)
  }

  let normalizedPath = normalizedPathFor(candidate)
  ffmpeg([
    "-nostdin",
    "-loglevel",
    "error",
    "-y",
    "-i",
    rawPath,
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
    normalizedPath,
  ])
  Path(normalizedPath)
}

let rec renderAll = async (index, parts) => {
  if index >= Belt.Array.length(candidates) {
    parts
  } else {
    let candidate = Belt.Array.getExn(candidates, index)
    let clip = await renderCandidate(candidate)
    let gap = silence(Millis(1800), Path(cacheDir))
    await renderAll(index + 1, Belt.Array.concatMany([parts, [clip, gap]]))
  }
}

let main = async () => {
  let lead = silence(Millis(400), Path(cacheDir))
  let parts = await renderAll(0, [lead])
  concatAudio(parts, Path(outputPath))->ignore
  let Seconds(duration) = durationSec(Path(outputPath))
  Js.log(
    "ENOCH NARRATOR AUDITION -> " ++ outputPath ++ " (" ++
    Js.Float.toFixedWithPrecision(duration, ~digits=1) ++ "s)",
  )
}

main()->ignore
