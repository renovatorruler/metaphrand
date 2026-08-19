/* Zero-cost validation and end-to-end ffmpeg tests for Episode 2 SFX. */

module B = Cinema_Backends

@module("node:path") external resolve1: string => string = "resolve"
@val @scope("process") external exit: int => unit = "exit"

exception TestFailure(string)

let check = (condition: bool, message: string): unit =>
  if !condition {
    raise(TestFailure(message))
  }

let field = (object_, key) => Js.Dict.get(object_, key)->Belt.Option.getExn
let asObject = json => json->Js.Json.decodeObject->Belt.Option.getExn
let asArray = json => json->Js.Json.decodeArray->Belt.Option.getExn
let asString = json => json->Js.Json.decodeString->Belt.Option.getExn

let jsonString = (object_, key) => field(object_, key)->asString

let objectJson = (fields: array<(string, Js.Json.t)>): Js.Json.t => {
  let object_ = Js.Dict.empty()
  fields->Belt.Array.forEach(((key, value)) => Js.Dict.set(object_, key, value))
  Js.Json.object_(object_)
}

let writeJson = (path, json) =>
  B.writeText(B.Path(path), Js.Json.stringifyWithSpace(json, 1) ++ "\n")

let makeTone = (path, frequency, seconds) => {
  B.ffmpeg([
    "-nostdin", "-loglevel", "error", "-y", "-f", "lavfi",
    "-i", "sine=frequency=" ++ Belt.Int.toString(frequency) ++ ":duration=" ++ Js.Float.toString(seconds),
    "-c:a", "pcm_s16le", path,
  ])
}

let expectSfxError = (action: unit => unit, needle: string): unit => {
  let got = ref("")
  try action() catch {
  | Drakosha_Ep2Sfx.SfxError(message) => got := message
  }
  check(Js.String2.includes(got.contents, needle), "expected SFX error containing " ++ needle)
}

let main = () => {
  let B.Path(tmp) = B.tempDir("drakosha-ep2-sfx-test-")
  let spoken = tmp ++ "/spoken.mp3"
  let effect = tmp ++ "/effect.wav"
  makeTone(tmp ++ "/spoken.wav", 440, 2.0)
  B.ffmpeg([
    "-nostdin", "-loglevel", "error", "-y", "-i", tmp ++ "/spoken.wav",
    "-c:a", "libmp3lame", "-q:a", "3", spoken,
  ])
  makeTone(effect, 880, 0.5)

  let blockPlan = tmp ++ "/blocks.json"
  writeJson(blockPlan, objectJson([
    ("segments", Js.Json.array([
      objectJson([("block_id", Js.Json.string("E2SP001"))]),
      objectJson([("block_id", Js.Json.string("E2SP002"))]),
    ])),
  ]))

  let config = tmp ++ "/sfx.json"
  let validConfig = objectJson([
    ("schema", Js.Json.string("drakosha.sfx-plan/v1")),
    ("sources", Js.Json.array([
      objectJson([
        ("id", Js.Json.string("tone")),
        ("file", Js.Json.string("effect.wav")),
        ("required", Js.Json.boolean(true)),
        ("license", Js.Json.string("test fixture")),
      ]),
      objectJson([
        ("id", Js.Json.string("optional")),
        ("file", Js.Json.string("missing.wav")),
        ("required", Js.Json.boolean(false)),
        ("license", Js.Json.string("test fixture")),
      ]),
    ])),
    ("cues", Js.Json.array([
      objectJson([
        ("id", Js.Json.string("cue")),
        ("block_id", Js.Json.string("E2SP002")),
        ("source_id", Js.Json.string("tone")),
        ("offset_seconds", Js.Json.number(0.05)),
        ("trim_start_seconds", Js.Json.number(0.0)),
        ("trim_end_seconds", Js.Json.number(0.3)),
        ("gain_db", Js.Json.number(-18.0)),
      ]),
    ])),
  ])
  writeJson(config, validConfig)

  let validation = Drakosha_Ep2Sfx.validateConfig(~configPath=config, ~blockPlanPath=blockPlan)
  check(Belt.Array.length(validation.sources) == 1, "optional missing source should be skipped")
  check(Belt.Array.length(validation.warnings) == 1, "optional missing source should warn")

  let badConfig = tmp ++ "/bad-sfx.json"
  let badRoot = validConfig->asObject
  let badCues = field(badRoot, "cues")->asArray
  let badCue = Belt.Array.getExn(badCues, 0)->asObject
  Js.Dict.set(badCue, "block_id", Js.Json.string("E2SP999"))
  writeJson(badConfig, validConfig)
  expectSfxError(
    () => ignore(Drakosha_Ep2Sfx.validateConfig(~configPath=badConfig, ~blockPlanPath=blockPlan)),
    "unknown block ID",
  )
  Js.Dict.set(badCue, "block_id", Js.Json.string("E2SP002"))

  let B.Seconds(spokenDuration) = B.probeDuration(B.Path(spoken))
  let timing = tmp ++ "/timing.json"
  writeJson(timing, objectJson([
    ("audio", Js.Json.string("spoken.mp3")),
    ("duration_seconds", Js.Json.number(spokenDuration)),
    ("blocks", Js.Json.array([
      objectJson([
        ("block_id", Js.Json.string("E2SP001")),
        ("start_seconds", Js.Json.number(0.0)),
        ("end_seconds", Js.Json.number(0.6)),
      ]),
      objectJson([
        ("block_id", Js.Json.string("E2SP002")),
        ("start_seconds", Js.Json.number(0.8)),
        ("end_seconds", Js.Json.number(1.4)),
      ]),
    ])),
  ]))
  let plan = Drakosha_Ep2Sfx.validateTiming(~timingPath=timing, ~validation)
  check(Belt.Array.length(plan.cues) == 1, "expected one resolved cue")
  check(Js.Math.abs_float(Belt.Array.getExn(plan.cues, 0).timestampSeconds -. 0.85) < 0.001, "cue timestamp should be block start plus offset")

  let output = tmp ++ "/with-sfx.mp3"
  let manifest = tmp ++ "/with-sfx.manifest.json"
  Drakosha_Ep2Sfx.mix(~plan, ~outputPath=output, ~manifestPath=manifest)
  check(B.exists(B.Path(output)), "mix output missing")
  check(B.exists(B.Path(manifest)), "mix manifest missing")
  check(B.sha256File(B.Path(spoken)) != B.sha256File(B.Path(output)), "mixed output should differ from spoken master")
  let rendered = B.readText(B.Path(manifest))->Js.Json.parseExn->asObject
  check(jsonString(rendered, "spoken_master") == resolve1(spoken), "manifest should record spoken master")
  let renderedCues = field(rendered, "cues")->asArray
  check(Belt.Array.length(renderedCues) == 1, "manifest cue count")
  let renderedCue = Belt.Array.getExn(renderedCues, 0)->asObject
  check(jsonString(renderedCue, "cue_id") == "cue", "manifest cue ID")
  check(jsonString(renderedCue, "source_sha256") == B.sha256File(B.Path(effect)), "manifest source checksum")

  expectSfxError(
    () => Drakosha_Ep2Sfx.mix(~plan, ~outputPath=spoken, ~manifestPath=manifest),
    "must not overwrite",
  )

  let incompleteTiming = tmp ++ "/incomplete.json"
  writeJson(incompleteTiming, objectJson([
    ("audio", Js.Json.string("spoken.mp3")),
    ("duration_seconds", Js.Json.number(spokenDuration)),
    ("blocks", Js.Json.array([
      objectJson([
        ("block_id", Js.Json.string("E2SP001")),
        ("start_seconds", Js.Json.number(0.0)),
        ("end_seconds", Js.Json.number(0.6)),
      ]),
    ])),
  ]))
  expectSfxError(
    () => ignore(Drakosha_Ep2Sfx.validateTiming(~timingPath=incompleteTiming, ~validation)),
    "map every block",
  )
  Js.log("Drakosha Episode 2 SFX tests passed")
}

try main() catch {
| TestFailure(message) => {
    Js.log("EP2 SFX TEST FAILED: " ++ message)
    exit(1)
  }
| Drakosha_Ep2Sfx.SfxError(message) => {
    Js.log("EP2 SFX TEST FAILED WITH SFX ERROR: " ++ message)
    exit(1)
  }
| Cinema_Backends.BackendError(message) => {
    Js.log("EP2 SFX TEST FAILED WITH BACKEND ERROR: " ++ message)
    exit(1)
  }
}

