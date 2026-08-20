/* Zero-provider delivery mastering for the immutable Episode 10 V4 table read.

   The production master is preserved byte-for-byte. This publishes a separate
   phone-friendly MP3 with dialogue loudness held near -18 LUFS and true peak
   capped at -1.5 dBTP. Run from studio/:

     node src/Kuku_Ep10AudioFirstDelivery.res.mjs
*/

open Cinema_Backends

exception DeliveryError(string)
@val @scope("process") external exit: int => unit = "exit"

let dir = "../stories/kuku/ep10prod/audio_first_table_read_v4"
let sourcePath = dir ++ "/EP10_AUDIO_FIRST_FULL_CAST_TABLE_READ_V4.mp3"
let sourceManifestPath = dir ++ "/EP10_AUDIO_FIRST_FULL_CAST_TABLE_READ_V4.manifest.json"
let planPath = dir ++ "/EP10_AUDIO_FIRST_FULL_CAST_TABLE_READ_V4.plan.json"
let outputPath = dir ++ "/EP10_AUDIO_FIRST_TABLE_READ_DELIVERY_V1.mp3"
let outputManifestPath = dir ++ "/EP10_AUDIO_FIRST_TABLE_READ_DELIVERY_V1.manifest.json"

let expectedSourceSha256 = "51cef0849e6ffb7edd287de223c3123e398eb3bae4dc2578ac7a58330668a0fc"
let expectedSourceManifestSha256 = "a69fbb645aceb071da812194f4eb93ce6e6d00a791ad1082bddaa82c25d75701"
let expectedPlanSha256 = "bb952140f176b37c09db5a0f0b4c48cdcd4fb02af8317e584a81aa64eaf4091c"
let filter = "loudnorm=I=-18:TP=-1.5:LRA=11"

let fail = message => raise(DeliveryError(message))

let requireHash = (path, expected) => {
  if !exists(Path(path)) {
    fail("missing immutable input: " ++ path)
  }
  let actual = sha256File(Path(path))
  if actual != expected {
    fail("immutable input hash mismatch: " ++ path ++ " expected " ++ expected ++ " got " ++ actual)
  }
}

let requireDecodedAudio = path => {
  let decoded = run(~cmd="ffmpeg", ~args=["-nostdin", "-v", "error", "-i", path, "-f", "null", "-"])
  if decoded.code != 0 {
    fail("full audio decode failed: " ++ path ++ " " ++ decoded.stderr)
  }
  let Seconds(seconds) = probeDuration(Path(path))
  if seconds < 280.80 || seconds > 281.20 {
    fail("unexpected delivery duration: " ++ Js.Float.toString(seconds))
  }
  seconds
}

let manifestBody = (~audioSha256, ~durationSeconds) => {
  let row = Js.Dict.empty()
  Js.Dict.set(row, "schema", Js.Json.string("kuku.ep10.audio_first.table_read.delivery.v1"))
  Js.Dict.set(row, "source_path", Js.Json.string(sourcePath))
  Js.Dict.set(row, "source_sha256", Js.Json.string(expectedSourceSha256))
  Js.Dict.set(row, "source_manifest_path", Js.Json.string(sourceManifestPath))
  Js.Dict.set(row, "source_manifest_sha256", Js.Json.string(expectedSourceManifestSha256))
  Js.Dict.set(row, "production_plan_path", Js.Json.string(planPath))
  Js.Dict.set(row, "production_plan_sha256", Js.Json.string(expectedPlanSha256))
  Js.Dict.set(row, "output_path", Js.Json.string(outputPath))
  Js.Dict.set(row, "output_sha256", Js.Json.string(audioSha256))
  Js.Dict.set(row, "duration_seconds", Js.Json.number(durationSeconds))
  Js.Dict.set(row, "codec", Js.Json.string("mp3"))
  Js.Dict.set(row, "sample_rate_hz", Js.Json.number(48000.0))
  Js.Dict.set(row, "channels", Js.Json.number(1.0))
  Js.Dict.set(row, "bitrate_kbps", Js.Json.number(128.0))
  Js.Dict.set(row, "mastering_filter", Js.Json.string(filter))
  Js.Dict.set(row, "target_integrated_lufs", Js.Json.number(-18.0))
  Js.Dict.set(row, "target_true_peak_dbtp", Js.Json.number(-1.5))
  Js.Dict.set(row, "provider_calls", Js.Json.number(0.0))
  Js.Dict.set(row, "ordinary_action_narration", Js.Json.boolean(false))
  Js.Dict.set(row, "dialogue_cues", Js.Json.number(63.0))
  Js.Dict.set(row, "guide_sfx_cues", Js.Json.number(22.0))
  Js.Json.object_(row)->Js.Json.stringifyWithSpace(1)
}

let verifyExisting = () => {
  if exists(Path(outputPath)) || exists(Path(outputManifestPath)) {
    if !exists(Path(outputPath)) || !exists(Path(outputManifestPath)) {
      fail("delivery audio/manifest publication is incomplete")
    }
    let duration = requireDecodedAudio(outputPath)
    let body = manifestBody(~audioSha256=sha256File(Path(outputPath)), ~durationSeconds=duration)
    if readText(Path(outputManifestPath)) != body {
      fail("existing delivery manifest does not match delivery audio")
    }
    Js.log("EP10 AUDIO-FIRST DELIVERY already verified -> " ++ outputPath)
    true
  } else {
    false
  }
}

let main = () => {
  requireHash(sourcePath, expectedSourceSha256)
  requireHash(sourceManifestPath, expectedSourceManifestSha256)
  requireHash(planPath, expectedPlanSha256)
  ignore(requireDecodedAudio(sourcePath))

  if !verifyExisting() {
    let Path(scratch) = tempDir("kuku-ep10-audio-first-delivery-")
    let stagedAudio = scratch ++ "/delivery.mp3"
    let stagedManifest = scratch ++ "/delivery.manifest.json"
    ffmpeg([
      "-nostdin", "-v", "error", "-y", "-i", sourcePath,
      "-af", filter, "-ar", "48000", "-ac", "1", "-c:a", "libmp3lame", "-b:a", "128k",
      "-metadata", "title=Kuku aur Akshar - Episode 10 Audio-First Table Read",
      stagedAudio,
    ])
    let duration = requireDecodedAudio(stagedAudio)
    let audioSha256 = sha256File(Path(stagedAudio))
    let body = manifestBody(~audioSha256, ~durationSeconds=duration)
    writeText(Path(stagedManifest), body)

    if !publishFileExclusive(Path(stagedAudio), Path(outputPath)) {
      fail("delivery audio already exists; refusing overwrite")
    }
    if !publishFileExclusive(Path(stagedManifest), Path(outputManifestPath)) {
      removeFile(Path(outputPath))
      fail("delivery manifest already exists; rolled new audio back to trash")
    }
    if sha256File(Path(outputPath)) != audioSha256 || readText(Path(outputManifestPath)) != body {
      fail("delivery readback failed after atomic publication")
    }
    Js.log("EP10 AUDIO-FIRST DELIVERY -> " ++ outputPath)
    Js.log("SHA256 -> " ++ audioSha256)
    Js.log("DURATION -> " ++ Js.Float.toFixedWithPrecision(duration, ~digits=3) ++ "s")
  }
}

try main() catch {
| DeliveryError(message) => {
    Js.log("EP10 AUDIO-FIRST DELIVERY FAILED: " ++ message)
    exit(1)
  }
| BackendError(message) => {
    Js.log("EP10 AUDIO-FIRST DELIVERY FAILED: " ++ message)
    exit(1)
  }
| Js.Exn.Error(error) => {
    Js.log("EP10 AUDIO-FIRST DELIVERY FAILED: " ++ Js.Exn.message(error)->Belt.Option.getWithDefault("unknown JavaScript error"))
    exit(1)
  }
}
