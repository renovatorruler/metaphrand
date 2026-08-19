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

let validateConfig: (~configPath: string, ~blockPlanPath: string) => validation
let validateTiming: (~timingPath: string, ~validation: validation) => mixPlan
let mix: (~plan: mixPlan, ~outputPath: string, ~manifestPath: string) => unit

