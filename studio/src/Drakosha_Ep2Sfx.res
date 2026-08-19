/* Selective sound-effects mixing for the Episode 2 table read.

   This module is deliberately provider-free. It reads local audio, validates a
   block timing manifest, and invokes ffmpeg only through Cinema_Backends. The
   spoken master is immutable input: `mix` rejects an output path that resolves
   to the same file.

   Timing contract:
     {audio, duration_seconds,
      blocks:[{block_id,start_seconds,end_seconds}]}

   Cue times are block starts plus configured offsets. The finished manifest
   records the exact source, checksum, fallback status, trim, gain and absolute
   timestamp used for every effect. */

module B = Cinema_Backends

@module("node:path") external dirname: string => string = "dirname"
@module("node:path") external resolve1: string => string = "resolve"
@module("node:path") external resolve2: (string, string) => string = "resolve"

exception SfxError(string)

type sourceSpec = {
  id: string,
  file: string,
  fallbackFile: option<string>,
  required: bool,
  license: string,
}

type cueSpec = {
  id: string,
  blockId: string,
  sourceId: string,
  offsetSeconds: float,
  trimStartSeconds: float,
  trimEndSeconds: float,
  gainDb: float,
}

type config = {
  schema: string,
  sources: array<sourceSpec>,
  cues: array<cueSpec>,
}

type resolvedSource = {
  spec: sourceSpec,
  path: string,
  usedFallback: bool,
  durationSeconds: float,
}

type validation = {
  config: config,
  validBlockIds: array<string>,
  sources: array<resolvedSource>,
  warnings: array<string>,
}

type timingBlock = {
  blockId: string,
  startSeconds: float,
  endSeconds: float,
}

type timingManifest = {
  audio: string,
  durationSeconds: float,
  blocks: array<timingBlock>,
}

type resolvedCue = {
  spec: cueSpec,
  source: resolvedSource,
  blockStartSeconds: float,
  timestampSeconds: float,
  renderedDurationSeconds: float,
}

type mixPlan = {
  spoken: timingManifest,
  cues: array<resolvedCue>,
  warnings: array<string>,
}

let get = (object_: Js.Dict.t<Js.Json.t>, key: string): option<Js.Json.t> =>
  Js.Dict.get(object_, key)

let objectOf = (json: Js.Json.t, where: string): Js.Dict.t<Js.Json.t> =>
  switch Js.Json.decodeObject(json) {
  | Some(object_) => object_
  | None => raise(SfxError(where ++ " must be an object"))
  }

let arrayOf = (json: Js.Json.t, where: string): array<Js.Json.t> =>
  switch Js.Json.decodeArray(json) {
  | Some(array) => array
  | None => raise(SfxError(where ++ " must be an array"))
  }

let requiredJson = (object_, key, where): Js.Json.t =>
  switch get(object_, key) {
  | Some(value) => value
  | None => raise(SfxError(where ++ "." ++ key ++ " is required"))
  }

let stringField = (object_, key, where): string =>
  switch requiredJson(object_, key, where)->Js.Json.decodeString {
  | Some(value) => value
  | None => raise(SfxError(where ++ "." ++ key ++ " must be a string"))
  }

let optionalStringField = (object_, key, where): option<string> =>
  switch get(object_, key) {
  | None => None
  | Some(json) =>
    switch Js.Json.decodeString(json) {
    | Some("") => None
    | Some(value) => Some(value)
    | None => raise(SfxError(where ++ "." ++ key ++ " must be a string"))
    }
  }

let numberField = (object_, key, where): float =>
  switch requiredJson(object_, key, where)->Js.Json.decodeNumber {
  | Some(value) => value
  | None => raise(SfxError(where ++ "." ++ key ++ " must be a number"))
  }

let boolField = (object_, key, where): bool =>
  switch requiredJson(object_, key, where)->Js.Json.decodeBoolean {
  | Some(value) => value
  | None => raise(SfxError(where ++ "." ++ key ++ " must be a boolean"))
  }

let parseJsonFile = (path: string, label: string): Js.Json.t => {
  if !B.exists(B.Path(path)) {
    raise(SfxError(label ++ " does not exist: " ++ path))
  }
  try Js.Json.parseExn(B.readText(B.Path(path))) catch {
  | _ => raise(SfxError(label ++ " is not valid JSON: " ++ path))
  }
}

let assertUnique = (values: array<string>, label: string): unit => {
  let seen = Js.Dict.empty()
  values->Belt.Array.forEach(value => {
    if value == "" {
      raise(SfxError(label ++ " contains an empty ID"))
    }
    if Js.Dict.get(seen, value) == Some(true) {
      raise(SfxError(label ++ " contains duplicate ID " ++ value))
    }
    Js.Dict.set(seen, value, true)
  })
}

let loadConfig = (path: string): config => {
  let root = parseJsonFile(path, "SFX config")->objectOf("SFX config")
  let schema = stringField(root, "schema", "SFX config")
  if schema != "drakosha.sfx-plan/v1" {
    raise(SfxError("unsupported SFX config schema " ++ schema))
  }
  let sources = requiredJson(root, "sources", "SFX config")->arrayOf("SFX config.sources")
  ->Belt.Array.mapWithIndex((index, json) => {
    let where = "SFX config.sources[" ++ Belt.Int.toString(index) ++ "]"
    let object_ = objectOf(json, where)
    {
      id: stringField(object_, "id", where),
      file: stringField(object_, "file", where),
      fallbackFile: optionalStringField(object_, "fallback_file", where),
      required: boolField(object_, "required", where),
      license: stringField(object_, "license", where),
    }
  })
  let cues = requiredJson(root, "cues", "SFX config")->arrayOf("SFX config.cues")
  ->Belt.Array.mapWithIndex((index, json) => {
    let where = "SFX config.cues[" ++ Belt.Int.toString(index) ++ "]"
    let object_ = objectOf(json, where)
    {
      id: stringField(object_, "id", where),
      blockId: stringField(object_, "block_id", where),
      sourceId: stringField(object_, "source_id", where),
      offsetSeconds: numberField(object_, "offset_seconds", where),
      trimStartSeconds: numberField(object_, "trim_start_seconds", where),
      trimEndSeconds: numberField(object_, "trim_end_seconds", where),
      gainDb: numberField(object_, "gain_db", where),
    }
  })
  assertUnique(sources->Belt.Array.map(source => source.id), "SFX source IDs")
  assertUnique(cues->Belt.Array.map(cue => cue.id), "SFX cue IDs")
  {schema, sources, cues}
}

let loadValidBlockIds = (path: string): array<string> => {
  let root = parseJsonFile(path, "spoken block plan")->objectOf("spoken block plan")
  let ids = requiredJson(root, "segments", "spoken block plan")
  ->arrayOf("spoken block plan.segments")
  ->Belt.Array.mapWithIndex((index, json) => {
    let where = "spoken block plan.segments[" ++ Belt.Int.toString(index) ++ "]"
    stringField(objectOf(json, where), "block_id", where)
  })
  if Belt.Array.length(ids) == 0 {
    raise(SfxError("spoken block plan has no segments"))
  }
  assertUnique(ids, "spoken block IDs")
  ids
}

let sourceById = (sources: array<sourceSpec>, id: string): option<sourceSpec> =>
  Belt.Array.getBy(sources, source => source.id == id)

let resolvedSourceById = (sources: array<resolvedSource>, id: string): option<resolvedSource> =>
  Belt.Array.getBy(sources, source => source.spec.id == id)

let resolveCandidate = (base: string, value: string): string => resolve2(base, value)

let resolveSource = (
  ~base: string,
  ~spec: sourceSpec,
): (option<resolvedSource>, option<string>) => {
  let primary = spec.file == "" ? None : Some(resolveCandidate(base, spec.file))
  let fallback = spec.fallbackFile->Belt.Option.map(path => resolveCandidate(base, path))
  let chosen = switch primary {
  | Some(path) if B.exists(B.Path(path)) => Some((path, false))
  | _ =>
    switch fallback {
    | Some(path) if B.exists(B.Path(path)) => Some((path, true))
    | _ => None
    }
  }
  switch chosen {
  | Some((path, usedFallback)) => {
      let B.Seconds(durationSeconds) = B.probeDuration(B.Path(path))
      if durationSeconds <= 0.0 {
        raise(SfxError("SFX source has no duration: " ++ path))
      }
      (Some({spec, path, usedFallback, durationSeconds}), None)
    }
  | None => {
      let requested = switch (primary, fallback) {
      | (Some(p), Some(f)) => p ++ " (fallback " ++ f ++ ")"
      | (Some(p), None) => p
      | (None, Some(f)) => f
      | (None, None) => "no path configured"
      }
      let message = "source " ++ spec.id ++ " unavailable: " ++ requested
      spec.required ? raise(SfxError(message)) : (None, Some(message ++ "; related cues will be skipped"))
    }
  }
}

let validateConfig = (~configPath: string, ~blockPlanPath: string): validation => {
  let absoluteConfig = resolve1(configPath)
  let config = loadConfig(absoluteConfig)
  let validBlockIds = loadValidBlockIds(resolve1(blockPlanPath))
  let validBlockSet = Js.Dict.empty()
  validBlockIds->Belt.Array.forEach(id => Js.Dict.set(validBlockSet, id, true))

  config.cues->Belt.Array.forEach(cue => {
    if Js.Dict.get(validBlockSet, cue.blockId) != Some(true) {
      raise(SfxError("cue " ++ cue.id ++ " targets unknown block ID " ++ cue.blockId))
    }
    if sourceById(config.sources, cue.sourceId) == None {
      raise(SfxError("cue " ++ cue.id ++ " uses unknown source ID " ++ cue.sourceId))
    }
    if cue.offsetSeconds < 0.0 {
      raise(SfxError("cue " ++ cue.id ++ " has a negative offset"))
    }
    if cue.trimStartSeconds < 0.0 || cue.trimEndSeconds <= cue.trimStartSeconds {
      raise(SfxError("cue " ++ cue.id ++ " has an invalid source trim"))
    }
    if cue.gainDb > 0.0 || cue.gainDb < -60.0 {
      raise(SfxError("cue " ++ cue.id ++ " gain must be between -60 and 0 dB"))
    }
  })

  let sources: array<resolvedSource> = []
  let warnings: array<string> = []
  let base = dirname(absoluteConfig)
  config.sources->Belt.Array.forEach(spec => {
    let (resolved, warning) = resolveSource(~base, ~spec)
    switch resolved {
    | Some(source) => {
        let _ = Js.Array2.push(sources, source)
      }
    | None => ()
    }
    switch warning {
    | Some(message) => {
        let _ = Js.Array2.push(warnings, message)
      }
    | None => ()
    }
  })

  config.cues->Belt.Array.forEach(cue => {
    switch resolvedSourceById(sources, cue.sourceId) {
    | Some(source) if cue.trimEndSeconds > source.durationSeconds +. 0.001 =>
      raise(SfxError(
        "cue " ++ cue.id ++ " trim ends at " ++ Js.Float.toString(cue.trimEndSeconds) ++
        "s but source " ++ source.path ++ " is only " ++
        Js.Float.toString(source.durationSeconds) ++ "s",
      ))
    | _ => ()
    }
  })
  {config, validBlockIds, sources, warnings}
}

let loadTiming = (path: string): timingManifest => {
  let absolute = resolve1(path)
  let root = parseJsonFile(absolute, "spoken timing manifest")->objectOf("spoken timing manifest")
  let audioField = stringField(root, "audio", "spoken timing manifest")
  /* The table-read generator records paths relative to the studio invocation,
     while hand-authored manifests are commonly relative to their own file.
     Support both contracts deterministically and prefer the existing path. */
  let invocationRelative = resolve1(audioField)
  let manifestRelative = resolveCandidate(dirname(absolute), audioField)
  let audio = B.exists(B.Path(invocationRelative)) ? invocationRelative : manifestRelative
  let durationSeconds = numberField(root, "duration_seconds", "spoken timing manifest")
  let blocks = requiredJson(root, "blocks", "spoken timing manifest")
  ->arrayOf("spoken timing manifest.blocks")
  ->Belt.Array.mapWithIndex((index, json) => {
    let where = "spoken timing manifest.blocks[" ++ Belt.Int.toString(index) ++ "]"
    let object_ = objectOf(json, where)
    {
      blockId: stringField(object_, "block_id", where),
      startSeconds: numberField(object_, "start_seconds", where),
      endSeconds: numberField(object_, "end_seconds", where),
    }
  })
  {audio, durationSeconds, blocks}
}

let timingBlockById = (blocks: array<timingBlock>, id: string): option<timingBlock> =>
  Belt.Array.getBy(blocks, block => block.blockId == id)

let validateTiming = (~timingPath: string, ~validation: validation): mixPlan => {
  let spoken = loadTiming(timingPath)
  if !B.exists(B.Path(spoken.audio)) {
    raise(SfxError("spoken master does not exist: " ++ spoken.audio))
  }
  if spoken.durationSeconds <= 0.0 {
    raise(SfxError("spoken timing manifest duration must be positive"))
  }
  let B.Seconds(actualDuration) = B.probeDuration(B.Path(spoken.audio))
  if Js.Math.abs_float(actualDuration -. spoken.durationSeconds) > 0.25 {
    raise(SfxError(
      "spoken timing duration " ++ Js.Float.toString(spoken.durationSeconds) ++
      "s does not match audio duration " ++ Js.Float.toString(actualDuration) ++ "s",
    ))
  }
  if Belt.Array.length(spoken.blocks) != Belt.Array.length(validation.validBlockIds) {
    raise(SfxError(
      "spoken timing manifest must map every block: expected " ++
      Belt.Int.toString(Belt.Array.length(validation.validBlockIds)) ++ ", got " ++
      Belt.Int.toString(Belt.Array.length(spoken.blocks)),
    ))
  }
  assertUnique(spoken.blocks->Belt.Array.map(block => block.blockId), "timed block IDs")
  spoken.blocks->Belt.Array.forEachWithIndex((index, block) => {
    let expected = Belt.Array.getExn(validation.validBlockIds, index)
    if block.blockId != expected {
      raise(SfxError(
        "timed block order differs at index " ++ Belt.Int.toString(index) ++
        ": expected " ++ expected ++ ", got " ++ block.blockId,
      ))
    }
    if block.startSeconds < 0.0 || block.endSeconds <= block.startSeconds {
      raise(SfxError("timed block " ++ block.blockId ++ " has an invalid time range"))
    }
    if block.endSeconds > spoken.durationSeconds +. 0.05 {
      raise(SfxError("timed block " ++ block.blockId ++ " extends beyond the spoken master"))
    }
    if index > 0 {
      let previous = Belt.Array.getExn(spoken.blocks, index - 1)
      if block.startSeconds +. 0.001 < previous.endSeconds {
        raise(SfxError("timed blocks overlap at " ++ block.blockId))
      }
    }
  })

  let cues: array<resolvedCue> = []
  validation.config.cues->Belt.Array.forEach(spec => {
    let block = switch timingBlockById(spoken.blocks, spec.blockId) {
    | Some(block) => block
    | None => raise(SfxError("timing manifest is missing cue block " ++ spec.blockId))
    }
    switch resolvedSourceById(validation.sources, spec.sourceId) {
    | None => () /* a declared optional source was not installed */
    | Some(source) => {
        let timestampSeconds = block.startSeconds +. spec.offsetSeconds
        let renderedDurationSeconds = spec.trimEndSeconds -. spec.trimStartSeconds
        if timestampSeconds +. renderedDurationSeconds > spoken.durationSeconds +. 0.001 {
          raise(SfxError("cue " ++ spec.id ++ " would extend beyond the spoken master"))
        }
        let _ = Js.Array2.push(cues, {
          spec,
          source,
          blockStartSeconds: block.startSeconds,
          timestampSeconds,
          renderedDurationSeconds,
        })
      }
    }
  })
  if Belt.Array.length(cues) == 0 {
    raise(SfxError("no SFX cues resolve to installed source files"))
  }
  {spoken, cues, warnings: validation.warnings}
}

let fixed = (value: float): string => Js.Float.toFixedWithPrecision(value, ~digits=3)

let mix = (~plan: mixPlan, ~outputPath: string, ~manifestPath: string): unit => {
  let spokenPath = resolve1(plan.spoken.audio)
  let output = resolve1(outputPath)
  let manifest = resolve1(manifestPath)
  if output == spokenPath {
    raise(SfxError("SFX output must not overwrite the spoken master"))
  }
  if manifest == spokenPath || manifest == output {
    raise(SfxError("SFX manifest path must be distinct from audio paths"))
  }

  let args: array<string> = ["-nostdin", "-loglevel", "error", "-y", "-i", spokenPath]
  plan.cues->Belt.Array.forEach(cue => {
    let _ = Js.Array2.push(args, "-i")
    let _ = Js.Array2.push(args, cue.source.path)
  })

  let filters: array<string> = [
    "[0:a]aformat=sample_rates=44100:channel_layouts=stereo,asplit=2[voice_main][voice_key]",
  ]
  plan.cues->Belt.Array.forEachWithIndex((index, cue) => {
    let fadeOutStart = max(0.0, cue.renderedDurationSeconds -. 0.04)
    let delayMs = Js.Math.round(cue.timestampSeconds *. 1000.0)->Belt.Float.toInt
    let filter =
      "[" ++ Belt.Int.toString(index + 1) ++ ":a]" ++
      "aformat=sample_rates=44100:channel_layouts=stereo," ++
      "atrim=start=" ++ fixed(cue.spec.trimStartSeconds) ++
      ":end=" ++ fixed(cue.spec.trimEndSeconds) ++ "," ++
      "asetpts=PTS-STARTPTS," ++
      "afade=t=in:st=0:d=0.015," ++
      "afade=t=out:st=" ++ fixed(fadeOutStart) ++ ":d=0.040," ++
      "volume=" ++ fixed(cue.spec.gainDb) ++ "dB," ++
      "adelay=" ++ Belt.Int.toString(delayMs) ++ ":all=1[s" ++ Belt.Int.toString(index) ++ "]"
    let _ = Js.Array2.push(filters, filter)
  })
  let cueLabels = Belt.Array.mapWithIndex(plan.cues, (index, _) =>
    "[s" ++ Belt.Int.toString(index) ++ "]"
  )->Js.Array2.joinWith("")
  let sfxMix = Belt.Array.length(plan.cues) == 1
    ? cueLabels ++ "anull[sfx_sum]"
    : cueLabels ++ "amix=inputs=" ++ Belt.Int.toString(Belt.Array.length(plan.cues)) ++
      ":duration=longest:normalize=0[sfx_sum]"
  let _ = Js.Array2.push(filters, sfxMix)
  let _ = Js.Array2.push(
    filters,
    "[sfx_sum][voice_key]sidechaincompress=threshold=0.025:ratio=12:attack=5:release=260:makeup=1[ducked_sfx]",
  )
  let _ = Js.Array2.push(
    filters,
    "[voice_main][ducked_sfx]amix=inputs=2:duration=first:normalize=0,alimiter=limit=0.92[out]",
  )
  let _ = Js.Array2.push(args, "-filter_complex")
  let _ = Js.Array2.push(args, filters->Js.Array2.joinWith(";"))
  let _ = Js.Array2.push(args, "-map")
  let _ = Js.Array2.push(args, "[out]")
  let _ = Js.Array2.push(args, "-t")
  let _ = Js.Array2.push(args, fixed(plan.spoken.durationSeconds))
  let _ = Js.Array2.push(args, "-c:a")
  let _ = Js.Array2.push(args, "libmp3lame")
  let _ = Js.Array2.push(args, "-q:a")
  let _ = Js.Array2.push(args, "2")
  let _ = Js.Array2.push(args, output)
  B.ffmpeg(args)

  let B.Seconds(mixedDuration) = B.probeDuration(B.Path(output))
  if Js.Math.abs_float(mixedDuration -. plan.spoken.durationSeconds) > 0.25 {
    raise(SfxError("mixed output duration does not match the spoken master"))
  }

  let cueRows = plan.cues->Belt.Array.map(cue => {
    let row = Js.Dict.empty()
    Js.Dict.set(row, "cue_id", Js.Json.string(cue.spec.id))
    Js.Dict.set(row, "block_id", Js.Json.string(cue.spec.blockId))
    Js.Dict.set(row, "source_id", Js.Json.string(cue.source.spec.id))
    Js.Dict.set(row, "source_path", Js.Json.string(cue.source.path))
    Js.Dict.set(row, "source_sha256", Js.Json.string(B.sha256File(B.Path(cue.source.path))))
    Js.Dict.set(row, "source_license", Js.Json.string(cue.source.spec.license))
    Js.Dict.set(row, "used_fallback", Js.Json.boolean(cue.source.usedFallback))
    Js.Dict.set(row, "source_duration_seconds", Js.Json.number(cue.source.durationSeconds))
    Js.Dict.set(row, "trim_start_seconds", Js.Json.number(cue.spec.trimStartSeconds))
    Js.Dict.set(row, "trim_end_seconds", Js.Json.number(cue.spec.trimEndSeconds))
    Js.Dict.set(row, "gain_db", Js.Json.number(cue.spec.gainDb))
    Js.Dict.set(row, "block_start_seconds", Js.Json.number(cue.blockStartSeconds))
    Js.Dict.set(row, "offset_seconds", Js.Json.number(cue.spec.offsetSeconds))
    Js.Dict.set(row, "timestamp_seconds", Js.Json.number(cue.timestampSeconds))
    Js.Dict.set(row, "rendered_duration_seconds", Js.Json.number(cue.renderedDurationSeconds))
    Js.Json.object_(row)
  })
  let settings = Js.Dict.empty()
  Js.Dict.set(settings, "dialogue_policy", Js.Json.string("spoken master remains full-level; SFX are gain-reduced and sidechain-ducked under speech"))
  Js.Dict.set(settings, "sidechain_threshold", Js.Json.number(0.025))
  Js.Dict.set(settings, "sidechain_ratio", Js.Json.number(12.0))
  Js.Dict.set(settings, "attack_ms", Js.Json.number(5.0))
  Js.Dict.set(settings, "release_ms", Js.Json.number(260.0))
  Js.Dict.set(settings, "limiter", Js.Json.number(0.92))

  let root = Js.Dict.empty()
  Js.Dict.set(root, "schema", Js.Json.string("drakosha.sfx-mix-manifest/v1"))
  Js.Dict.set(root, "spoken_master", Js.Json.string(spokenPath))
  Js.Dict.set(root, "spoken_master_sha256", Js.Json.string(B.sha256File(B.Path(spokenPath))))
  Js.Dict.set(root, "output", Js.Json.string(output))
  Js.Dict.set(root, "output_sha256", Js.Json.string(B.sha256File(B.Path(output))))
  Js.Dict.set(root, "duration_seconds", Js.Json.number(mixedDuration))
  Js.Dict.set(root, "mix_settings", Js.Json.object_(settings))
  Js.Dict.set(root, "warnings", Js.Json.array(plan.warnings->Belt.Array.map(Js.Json.string)))
  Js.Dict.set(root, "cues", Js.Json.array(cueRows))
  B.writeText(B.Path(manifest), Js.Json.stringifyWithSpace(Js.Json.object_(root), 1) ++ "\n")
}
