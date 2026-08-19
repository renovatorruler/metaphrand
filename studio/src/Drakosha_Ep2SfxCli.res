/* Episode 2 table-read SFX command line.

   Default mode is validation only and never writes audio. MIX=1 requires the
   V2 timing manifest and writes a new suffixed master plus its cue manifest.
   No provider API is called in either mode. */

@val @scope(("process", "env")) external envMix: option<string> = "MIX"
@val @scope(("process", "env")) external envTiming: option<string> = "TIMING_MANIFEST"
@val @scope("process") external exit: int => unit = "exit"

let dir = "../stories/drakosha/audio/ep2_table_read"
let configPath = dir ++ "/ep2_sfx_plan.json"
let blockPlanPath = dir ++ "/ep2_table_read_plan.json"
let defaultTimingPath = dir ++ "/EP2_FULL_CAST_TABLE_READ_V2.manifest.json"
let outputPath = dir ++ "/EP2_FULL_CAST_TABLE_READ_V2_WITH_SFX.mp3"
let manifestPath = dir ++ "/EP2_FULL_CAST_TABLE_READ_V2_WITH_SFX.manifest.json"

let main = () => {
  let validation = Drakosha_Ep2Sfx.validateConfig(~configPath, ~blockPlanPath)
  Js.log(
    "SFX CONFIG OK: " ++ Belt.Int.toString(Belt.Array.length(validation.config.cues)) ++
    " cues; " ++ Belt.Int.toString(Belt.Array.length(validation.sources)) ++
    " installed sources; " ++ Belt.Int.toString(Belt.Array.length(validation.warnings)) ++
    " optional-source warnings",
  )
  validation.warnings->Belt.Array.forEach(warning => Js.log("  warning: " ++ warning))
  if envMix == Some("1") {
    let timingPath = envTiming->Belt.Option.getWithDefault(defaultTimingPath)
    let plan = Drakosha_Ep2Sfx.validateTiming(~timingPath, ~validation)
    Drakosha_Ep2Sfx.mix(~plan, ~outputPath, ~manifestPath)
    Js.log("SFX MIX -> " ++ outputPath)
    Js.log("SFX MANIFEST -> " ++ manifestPath)
  } else {
    Js.log("VALIDATION ONLY — no mix was written. Run mix:ep2-sfx after the V2 manifest exists.")
  }
}

try main() catch {
| Drakosha_Ep2Sfx.SfxError(message) => {
    Js.log("EP2 SFX FAILED: " ++ message)
    exit(1)
  }
| Cinema_Backends.BackendError(message) => {
    Js.log("EP2 SFX BACKEND FAILED: " ++ message)
    exit(1)
  }
}
