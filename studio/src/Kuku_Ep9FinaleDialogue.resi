/* Public surface is intentionally read-only apart from the single guarded
   recovery entry point. In particular, no provider operation, raw cutter, or
   unvalidated publication helper is externally callable. */

exception DialogueRecovery(string)

let planPath: string
let sourceManifestPath: string

type segment = {
  order: int,
  scene: int,
  dialogueIdx: int,
  kind: string,
  speaker: string,
  direction: string,
  tag: string,
  text: string,
}

type chunkPlan = {
  id: string,
  scene: int,
  kind: string,
  segmentOrders: array<int>,
  segments: array<segment>,
}

type sourceTake = {
  id: string,
  scene: int,
  kind: string,
  path: string,
  duration: float,
}

type approvedSource = {path: string, duration: float, sha256: string}

type inputs = {
  segments: array<segment>,
  chunks: array<chunkPlan>,
  takes: array<sourceTake>,
  approvedSources: Js.Dict.t<approvedSource>,
}

type textSpan = {order: int, from: int, to_: int}
type transcriptMap = {text: string, spans: array<textSpan>}

type alignmentNeed = {
  chunk: chunkPlan,
  take: sourceTake,
  transcript: transcriptMap,
  cachePath: string,
  sourceSha256: string,
  transcriptSha256: string,
}

type dryReport = {
  alignmentMethod: string,
  alignerStatus: string,
  segmentCount: int,
  chunkCount: int,
  productionSegmentCount: int,
  productionChunkCount: int,
  lockedSegmentCount: int,
  lockedChunkCount: int,
  selectedCount: int,
  dialogueCount: int,
  chorusCount: int,
  narrationExcluded: int,
  mimicExcluded: int,
  mixedChunkCount: int,
  alignmentChunkCount: int,
  rawCachedCount: int,
  cachedAlignmentCount: int,
  missingAlignmentIds: array<string>,
}

type alignmentMode = LocalVakyansh | ElevenForced

let loadInputs: unit => inputs
let validateInputs: inputs => unit
let takeForChunk: (array<sourceTake>, string) => sourceTake
let vakyanshDryReport: (
  inputs,
  ~toolPath: option<string>,
  ~modelPath: option<string>,
  ~vocabPath: option<string>,
  ~whisperModelPath: option<string>,
) => dryReport
let paidAllowed: (~dry: bool, ~paid: bool) => bool
let alignmentModeFor: (~localRequested: bool, ~elevenRequested: bool) => alignmentMode
let alignmentNeeds: inputs => array<alignmentNeed>
let isLockedAssetChunkId: string => bool
let spokenText: segment => string
let isSelectedProductionSegment: segment => bool

let recover: (
  ~dry: bool,
  ~paid: bool,
  ~mode: alignmentMode,
  ~localRequested: bool,
  ~vakyanshToolPath: option<string>,
  ~vakyanshModelPath: option<string>,
  ~vakyanshVocabPath: option<string>,
  ~whisperModelPath: option<string>,
) => promise<unit>
