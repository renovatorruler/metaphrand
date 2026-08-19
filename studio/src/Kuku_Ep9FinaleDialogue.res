/* Kuku EP9 finale production-dialogue recovery.

   The approved table read is the only performance source. This module never
   synthesizes a voice. It aligns mixed table-read chunks to the complete text
   already present in each chunk, then cuts only dialogue/chorus lines from
   finale scenes 1-10. Scenes 0, 100, and 1000 are already locked inside the
   cold-open/title assets. The one-syllable mimic beat remains an SFX cue.

   Run from studio/ through Kuku_Ep9FinaleDialogueCli.res.mjs:
     DRY=1 node src/Kuku_Ep9FinaleDialogueCli.res.mjs
     LOCAL_ALIGN=1 VAKYANSH_ALIGNER=/absolute/local-aligner \
       VAKYANSH_MODEL=/absolute/model.pt VAKYANSH_VOCAB=/absolute/vocab.json \
       WHISPER_MODEL=/absolute/whisper-model.bin \
       node src/Kuku_Ep9FinaleDialogueCli.res.mjs

   DRY=1 always wins and makes no provider request. Local Vakyansh CTC alignment
   plus a separate no-prompt Whisper review is the default route. Execution
   requires LOCAL_ALIGN=1 and already-installed artifacts with approved hashes;
   this code never downloads a model. The legacy ElevenLabs selector is retained
   only so old invocations fail before a provider call; it has no execution or
   publication route. Published stems, caches, and the production manifest are
   immutable. */

open Cinema_Backends

exception DialogueRecovery(string)

let pipelineVersion = "kuku-ep9-finale-dialogue-v5-candidate-content-bound"
let planPath = "../stories/kuku/ep9prod/ep9_table_read_plan_v2_dream.json"
let sourceManifestPath =
  "../stories/kuku/ep9prod/EP9_FULL_CAST_TABLE_READ_V2_DREAM.manifest.json"
let audioDir = "../stories/kuku/ep9prod/finale/audio"
let alignmentDir = audioDir ++ "/alignment"
let stemDir = audioDir ++ "/dialogue_stems"
let outputManifestPath = audioDir ++ "/EP9_PRODUCTION_DIALOGUE.manifest.json"
let whisperBinary = "/opt/homebrew/bin/whisper-cli"
let approvedWhisperBinarySha256 = "40bca494d49af736058eb3f33cbcebaa020eacf6d0087b623f334946e1ab2128"
let approvedWhisperVersion = "whisper.cpp version: 1.9.2"
let pinnedFfmpegBinary = "/opt/homebrew/bin/ffmpeg"
let pinnedFfprobeBinary = "/opt/homebrew/bin/ffprobe"
let approvedFfmpegSha256 = "feaee5cd168960437853cdacabe314b08c8498600177301687b9ef2ff76abc28"
let approvedFfprobeSha256 = "ec2933fc30fed334a43b9d260fdfb9b523a24179d89cd18c7ce7e09714483598"
let localRawDir = alignmentDir ++ "/local_raw"
let localDerivedDir = alignmentDir ++ "/local_derived"
let localWhisperConfig =
  "whisper.cpp|-ng|input=pcm_s16le_16khz_mono|-l hi|-ojf|-sow|no-fallback|temperature=0|beam=5|best-of=5|prompt=known-transcript"
let vakyanshRawDir = alignmentDir ++ "/vakyansh_raw"
let stemValidationRawDir = alignmentDir ++ "/stem_validation/raw"
let stemValidationDerivedDir = alignmentDir ++ "/stem_validation/derived"
let manualReviewDir = audioDir ++ "/manual_review"
let manualReviewManifestPath =
  audioDir ++ "/EP9_DIALOGUE_MANUAL_REVIEW_" ++ pipelineVersion ++ ".json"
let vakyanshAuditDir = alignmentDir ++ "/vakyansh_audit"
let vakyanshAuditLicensePath = vakyanshAuditDir ++ "/LICENSE_VAKYANSH_MIT.txt"
let vakyanshAuditVocabPath = vakyanshAuditDir ++ "/vocab.json"
let vakyanshAuditProvenancePath = vakyanshAuditDir ++ "/VAKYANSH_PROVENANCE.json"
let whisperAuditLicensePath = vakyanshAuditDir ++ "/LICENSE_WHISPER_CPP_MIT.txt"
let whisperAuditProvenancePath = vakyanshAuditDir ++ "/WHISPER_VALIDATOR_PROVENANCE.json"
let audioToolchainLicensePath = vakyanshAuditDir ++ "/LICENSE_FFMPEG.md"
let audioToolchainSbomPath = vakyanshAuditDir ++ "/FFMPEG_8.0.1_HOMEBREW_SBOM.spdx.json"
let audioToolchainProvenancePath = vakyanshAuditDir ++ "/LOCAL_AUDIO_TOOLCHAIN_PROVENANCE.json"
let approvedVakyanshToolVersion = "metaphrand-vakyansh-aligner-v1"
let approvedVakyanshToolSha256 = "429e6f1d67d598f44b16fd2d4c432300cebb8307840f1e7e5b201c28fc811779"
let approvedVakyanshModelSha256 = "91cebcf2ecb61f8676878abc20ba2e86053e8269d8bcbf2f0f794a9dce9eaa72"
let approvedVakyanshVocabSha256 = "817609988bc99a7a3ef238472309ee284768b7d171f75a0b183d0d8c5e83b4bd"
let approvedVakyanshLicenseSha256 = "a58558caea6163766444d6ad1dbefe2a4f8a6353569d5182f95e33202bdf9dc2"
let approvedVakyanshProvenanceSha256 = "76b16f6c0a322a2b408eca95f61fcdd60e587ccf7102fa77eafe253035da9acb"
let approvedWhisperLicenseSha256 = "94f29bbed6a22c35b992c5c6ebf0e7c92f13b836b90f36f461c9cf2f0f1d010d"
let approvedWhisperProvenanceSha256 = "1ee5c0986590c38fe3758c5fb13f71d5e01c0e44065ea33026ac8c4bc13cb19b"
let approvedAudioToolchainLicenseSha256 = "2e1d16c72fd74e12063776371da757322f8b77589386532f4fd8634bde7de1af"
let approvedAudioToolchainSbomSha256 = "0b151ac767b97bf5a83e43e4b738737375195bd88ce480b9fe9babedeee7df2e"
let approvedAudioToolchainProvenanceSha256 = "6a62d04359284447ed0d7bef5fe9ab348d840472a840c5dadfe5d3f93672e2cd"
let approvedWhisperModelSha256 = "394221709cd5ad1f40c46e6031ca61bce88931e6e088c188294c6d5a55ffa7e2"
let approvedPlanSha256 = "49a39f0f3708e012a32951d482454f4cb807008082f1492724f3d45fb58756c7"
let approvedSourceManifestSha256 = "fd59a4e9b4d6b096bc533e023a2110fa676e28a581ff36faa8bf4f043bd4512d"
let approvedSourceIdentitiesPath = alignmentDir ++ "/APPROVED_PRODUCTION_SOURCE_IDENTITIES.v1.json"
let approvedSourceIdentitiesSha256 = "eca73d31c2d7ea8426f3c194cda5882b11b2869f11dd1e7fd134e7a980297e6a"
let rawProviderInventoryPath = alignmentDir ++
  "/raw_provider/inventory_7e95184e4b7a95cd6646659b4ae2e1cd68370c6a057e94d52e07697de99fc5e2.json"
let rawProviderInventorySha256 = "7e95184e4b7a95cd6646659b4ae2e1cd68370c6a057e94d52e07697de99fc5e2"
let timingEquivalenceInventoryPath = alignmentDir ++
  "/raw_provider/timing_equivalence_3fadd0cb84f89f7f5d105dcad6197fffd9bc399e4eafa4580bb3daba7621793e.json"
let timingEquivalenceInventorySha256 = "3fadd0cb84f89f7f5d105dcad6197fffd9bc399e4eafa4580bb3daba7621793e"
let vakyanshConfig =
  "vakyansh-hindi-him-4200-quant|torch=2.8.0|torchaudio=2.8.0|qnnpack|pcm16-mono-16khz|core=20|context=3|ctc-blank=0|separator=4"
let stemWhisperConfig =
  "whisper.cpp|-ng|pcm16-mono-16khz|-l hi|-ojf|-sow|-mc 0|no-fallback|temperature=0|beam=5|best-of=5|no-prompt"
let silenceConfig = "silencedetect=noise=-38dB:d=0.12"
let preHandleSeconds = 0.08
let postHandleSeconds = 0.12
let productionSceneFirst = 1
let productionSceneLast = 10
let expectedProductionStemCount = 137
let lockedAssetChunkIds = [
  "chunk_000",
  "chunk_001",
  "chunk_002",
  "chunk_003",
  "chunk_004",
  "chunk_005",
]

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
type charTiming = {text: string, start: float, end_: float}
type alignment = {characters: array<charTiming>, loss: float}
type blockTiming = {order: int, start: float, end_: float}
type alignmentMode = LocalVakyansh | ElevenForced

type localContext = {
  modelPath: string,
  modelSha256: string,
  whisperVersion: string,
}

type vakyanshContext = {
  toolPath: string,
  toolSha256: string,
  toolVersion: string,
  modelPath: string,
  modelSha256: string,
  vocabPath: string,
  vocabSha256: string,
  whisperModelPath: string,
  whisperModelSha256: string,
  whisperVersion: string,
}

type vakyanshResult = {
  blocks: array<blockTiming>,
  cachePath: string,
  cacheSha256: string,
  sourceSha256: string,
  quality: Kuku_LocalWordAlign.quality,
}

type stemValidation = {
  rawPath: string,
  rawSha256: string,
  derivedPath: string,
  derivedSha256: string,
  candidateMp3Sha256: string,
  candidateWavSha256: string,
  quality: Kuku_LocalWordAlign.quality,
}

type localPaths = {rawPath: string, rawSignature: string}

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

type stemRow = {
  segment: segment,
  chunk: chunkPlan,
  take: sourceTake,
  sourceSha256: string,
  sourceStart: float,
  sourceEnd: float,
  speechStart: float,
  speechEnd: float,
  path: string,
  duration: float,
  validation: option<stemValidation>,
}

type preparedStem = {
  row: stemRow,
  temporaryMp3: string,
  temporaryMp3Sha256: string,
  temporaryWav: string,
  temporaryWavSha256: string,
}

type validationException = {
  prepared: preparedStem,
  reason: string,
  rawPath: option<string>,
}

let fail = message => raise(DialogueRecovery(message))
let trim = Js.String2.trim
let pathString = (Path(value)): string => value

let jsonObject = (json: Js.Json.t, label: string): Js.Dict.t<Js.Json.t> =>
  switch Js.Json.decodeObject(json) {
  | Some(value) => value
  | None => fail(label ++ " must be a JSON object")
  }

let field = (object_: Js.Dict.t<Js.Json.t>, key: string): option<Js.Json.t> =>
  Js.Dict.get(object_, key)

let stringField = (object_, key, label): string =>
  switch field(object_, key)->Belt.Option.flatMap(Js.Json.decodeString) {
  | Some(value) => value
  | None => fail(label ++ "." ++ key ++ " must be a string")
  }

let numberField = (object_, key, label): float =>
  switch field(object_, key)->Belt.Option.flatMap(Js.Json.decodeNumber) {
  | Some(value) => value
  | None => fail(label ++ "." ++ key ++ " must be a number")
  }

let arrayField = (object_, key, label): array<Js.Json.t> =>
  switch field(object_, key)->Belt.Option.flatMap(Js.Json.decodeArray) {
  | Some(value) => value
  | None => fail(label ++ "." ++ key ++ " must be an array")
  }

let assertExactFile = (label: string, path: string, expectedSha256: string): unit => {
  if !exists(Path(path)) {
    fail(label ++ " is missing: " ++ path)
  }
  let actual = sha256File(Path(path))
  if actual != expectedSha256 {
    fail(label ++ " SHA-256 mismatch: " ++ actual ++ " != " ++ expectedSha256)
  }
}

let verifyLocalAudioToolchain = (): unit => {
  assertExactFile("ffmpeg", pinnedFfmpegBinary, approvedFfmpegSha256)
  assertExactFile("ffprobe", pinnedFfprobeBinary, approvedFfprobeSha256)
  assertExactFile("FFmpeg license audit", audioToolchainLicensePath, approvedAudioToolchainLicenseSha256)
  assertExactFile("FFmpeg SBOM audit", audioToolchainSbomPath, approvedAudioToolchainSbomSha256)
  assertExactFile(
    "FFmpeg provenance audit",
    audioToolchainProvenancePath,
    approvedAudioToolchainProvenanceSha256,
  )
  let provenance = readText(Path(audioToolchainProvenancePath))->Js.Json.parseExn->jsonObject(
    "local audio toolchain provenance",
  )
  if stringField(provenance, "ffmpeg_binary_sha256", "local audio toolchain provenance") !=
       approvedFfmpegSha256 ||
     stringField(provenance, "ffprobe_binary_sha256", "local audio toolchain provenance") !=
       approvedFfprobeSha256 ||
     stringField(provenance, "homebrew_sbom_sha256", "local audio toolchain provenance") !=
       approvedAudioToolchainSbomSha256 {
    fail("local audio toolchain provenance identity mismatch")
  }
}

let pinnedFfmpeg = (args: array<string>): unit => {
  verifyLocalAudioToolchain()
  let result = run(~cmd=pinnedFfmpegBinary, ~args)
  verifyLocalAudioToolchain()
  if result.code != 0 {
    fail("pinned ffmpeg failed: " ++ result.stderr)
  }
}

let pinnedProbeDuration = (path: string): float => {
  verifyLocalAudioToolchain()
  let result = run(
    ~cmd=pinnedFfprobeBinary,
    ~args=["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path],
  )
  verifyLocalAudioToolchain()
  if result.code != 0 {
    fail("pinned ffprobe failed for " ++ path ++ ": " ++ result.stderr)
  }
  switch Belt.Float.fromString(trim(result.stdout)) {
  | Some(value) if Js.Float.isFinite(value) && value > 0.0 => value
  | _ => fail("pinned ffprobe returned an invalid duration for " ++ path)
  }
}

let parseSegment = (json: Js.Json.t): segment => {
  let object_ = jsonObject(json, "segment")
  {
    order: numberField(object_, "order", "segment")->Belt.Float.toInt,
    scene: numberField(object_, "scene", "segment")->Belt.Float.toInt,
    dialogueIdx: numberField(object_, "dialogue_idx", "segment")->Belt.Float.toInt,
    kind: stringField(object_, "kind", "segment"),
    speaker: stringField(object_, "speaker", "segment"),
    direction: stringField(object_, "direction", "segment"),
    tag: stringField(object_, "tag", "segment"),
    text: stringField(object_, "text", "segment"),
  }
}

let segmentForOrder = (segments: array<segment>, order: int): segment =>
  switch Belt.Array.getBy(segments, segment => segment.order == order) {
  | Some(segment) => segment
  | None => fail("chunk refers to missing segment order " ++ Belt.Int.toString(order))
  }

let parseChunkPlan = (segments: array<segment>, json: Js.Json.t): chunkPlan => {
  let object_ = jsonObject(json, "chunk")
  let segmentOrders = arrayField(object_, "segment_orders", "chunk")->Belt.Array.map(value =>
    switch Js.Json.decodeNumber(value) {
    | Some(number) => Belt.Float.toInt(number)
    | None => fail("chunk.segment_orders must contain numbers")
    }
  )
  {
    id: stringField(object_, "id", "chunk"),
    scene: numberField(object_, "scene", "chunk")->Belt.Float.toInt,
    kind: stringField(object_, "kind", "chunk"),
    segmentOrders,
    segments: segmentOrders->Belt.Array.map(order => segmentForOrder(segments, order)),
  }
}

let parseTake = (json: Js.Json.t): sourceTake => {
  let object_ = jsonObject(json, "source chunk")
  {
    id: stringField(object_, "id", "source chunk"),
    scene: numberField(object_, "scene", "source chunk")->Belt.Float.toInt,
    kind: stringField(object_, "kind", "source chunk"),
    path: stringField(object_, "path", "source chunk"),
    duration: numberField(object_, "duration_seconds", "source chunk"),
  }
}

let loadApprovedSources = (): Js.Dict.t<approvedSource> => {
  if !exists(Path(approvedSourceIdentitiesPath)) ||
     sha256File(Path(approvedSourceIdentitiesPath)) != approvedSourceIdentitiesSha256 {
    fail("approved production-source identity inventory is missing or changed")
  }
  if !exists(Path(rawProviderInventoryPath)) ||
     sha256File(Path(rawProviderInventoryPath)) != rawProviderInventorySha256 ||
     !exists(Path(timingEquivalenceInventoryPath)) ||
     sha256File(Path(timingEquivalenceInventoryPath)) != timingEquivalenceInventorySha256 {
    fail("raw-provider or timing-equivalence provenance is missing or changed")
  }
  let root = readText(Path(approvedSourceIdentitiesPath))->Js.Json.parseExn->jsonObject(
    "approved source identities",
  )
  if stringField(root, "schema", "approved source identities") !=
       "kuku-ep9-approved-production-sources-v1" ||
     stringField(root, "source_plan_sha256", "approved source identities") != approvedPlanSha256 ||
     stringField(root, "source_manifest_sha256", "approved source identities") != approvedSourceManifestSha256 ||
     stringField(root, "raw_provider_inventory_sha256", "approved source identities") !=
       rawProviderInventorySha256 ||
     stringField(root, "timing_equivalence_inventory_sha256", "approved source identities") !=
       timingEquivalenceInventorySha256 ||
     numberField(root, "entry_count", "approved source identities") != 19.0 {
    fail("approved production-source inventory identity mismatch")
  }
  let sources: Js.Dict.t<approvedSource> = Js.Dict.empty()
  arrayField(root, "entries", "approved source identities")->Belt.Array.forEach(json => {
    let row = jsonObject(json, "approved source entry")
    let id = stringField(row, "chunk_id", "approved source entry")
    if Js.Dict.get(sources, id) != None {
      fail("duplicate approved source identity for " ++ id)
    }
    let sha256 = stringField(row, "sha256", "approved source entry")
    if Js.String2.length(sha256) != 64 {
      fail("invalid approved source SHA-256 for " ++ id)
    }
    Js.Dict.set(sources, id, {
      path: stringField(row, "path", "approved source entry"),
      duration: numberField(row, "duration_seconds", "approved source entry"),
      sha256,
    })
  })
  if Js.Dict.keys(sources)->Belt.Array.length != 19 {
    fail("approved production-source inventory must contain exactly 19 unique chunks")
  }
  sources
}

let loadInputs = (): inputs => {
  if !exists(Path(planPath)) {
    fail("missing approved table-read plan: " ++ planPath)
  }
  if !exists(Path(sourceManifestPath)) {
    fail("missing approved table-read manifest: " ++ sourceManifestPath)
  }
  let plan = readText(Path(planPath))->Js.Json.parseExn->jsonObject("table-read plan")
  let segments = arrayField(plan, "segments", "table-read plan")->Belt.Array.map(parseSegment)
  let chunks = arrayField(plan, "chunks", "table-read plan")->Belt.Array.map(json =>
    parseChunkPlan(segments, json)
  )
  let source =
    readText(Path(sourceManifestPath))->Js.Json.parseExn->jsonObject("table-read manifest")
  let takes = arrayField(source, "chunks", "table-read manifest")->Belt.Array.map(parseTake)
  {segments, chunks, takes, approvedSources: loadApprovedSources()}
}

let isKnownSourceKind = (kind: string): bool =>
  kind == "narration" || kind == "dialogue" || kind == "chorus" || kind == "mimic"

let isSelectedKind = (kind: string): bool => kind == "dialogue" || kind == "chorus"

let isProductionScene = (scene: int): bool =>
  scene >= productionSceneFirst && scene <= productionSceneLast

let isLockedAssetScene = (scene: int): bool => scene == 0 || scene == 100 || scene == 1000

let isLockedAssetChunkId = (id: string): bool => Belt.Array.some(lockedAssetChunkIds, value => value == id)

let isProductionChunk = (chunk: chunkPlan): bool =>
  isProductionScene(chunk.scene) && !isLockedAssetChunkId(chunk.id)

let isProductionSegment = (segment: segment): bool => isProductionScene(segment.scene)

let isSelectedProductionSegment = (segment: segment): bool =>
  isProductionSegment(segment) && isSelectedKind(segment.kind)

let productionChunks = (input: inputs): array<chunkPlan> =>
  input.chunks->Belt.Array.keep(isProductionChunk)

let productionSegments = (input: inputs): array<segment> =>
  input.segments->Belt.Array.keep(isProductionSegment)

let isMixedChunk = (chunk: chunkPlan): bool =>
  Belt.Array.some(chunk.segments, segment => segment.kind == "narration") &&
  Belt.Array.some(chunk.segments, segment => isSelectedKind(segment.kind))

let requiresAlignment = (chunk: chunkPlan): bool => {
  let selectedCount =
    chunk.segments->Belt.Array.keep(segment => isSelectedKind(segment.kind))->Belt.Array.length
  /* All mixed chunks must be aligned. The sole pure multi-line character take
     is aligned too: silence-only splitting would confuse pauses inside Dadi's
     four-sentence line with the actual speaker handoff. */
  isMixedChunk(chunk) || selectedCount > 1
}

let takeForChunk = (takes: array<sourceTake>, id: string): sourceTake =>
  switch Belt.Array.getBy(takes, take => take.id == id) {
  | Some(take) => take
  | None => fail("source manifest has no take for " ++ id)
  }

let approvedSourceFor = (input: inputs, id: string): approvedSource =>
  switch Js.Dict.get(input.approvedSources, id) {
  | Some(value) => value
  | None => fail("approved production-source inventory has no entry for " ++ id)
  }

let removeTags = (text: string): string =>
  text->Js.String2.replaceByRe(%re("/\[[^\]]+\]\s*/g"), "")->trim

let spokenText = (segment: segment): string => removeTags(segment.text)

let transcriptMap = (segments: array<segment>): transcriptMap => {
  let buffer = ref("")
  let spans: array<textSpan> = []
  segments->Belt.Array.forEach(segment => {
    if buffer.contents != "" {
      buffer := buffer.contents ++ " "
    }
    let from = Js.String2.length(buffer.contents)
    let spoken = spokenText(segment)
    if spoken == "" {
      fail("empty spoken transcript at segment " ++ Belt.Int.toString(segment.order))
    }
    buffer := buffer.contents ++ spoken
    let _ = Js.Array2.push(spans, {
      order: segment.order,
      from,
      to_: Js.String2.length(buffer.contents),
    })
  })
  {text: buffer.contents, spans}
}

let cachePathFor = (
  chunk: chunkPlan,
  take: sourceTake,
  transcript: transcriptMap,
  approvedSourceSha256: string,
): (string, string, string) => {
  let sourceSha256 = sha256File(Path(take.path))
  if sourceSha256 != approvedSourceSha256 {
    fail("approved source bytes changed for " ++ chunk.id)
  }
  let transcriptSha256 = sha256Text(transcript.text)
  let signature =
    pipelineVersion ++ "|" ++ chunk.id ++ "|" ++ sourceSha256 ++ "|" ++ transcriptSha256
  (
    alignmentDir ++ "/" ++ chunk.id ++ "_" ++ sha256Text(signature) ++ ".json",
    sourceSha256,
    transcriptSha256,
  )
}

let alignmentNeeds = (input: inputs): array<alignmentNeed> =>
  productionChunks(input)
  ->Belt.Array.keep(requiresAlignment)
  ->Belt.Array.map(chunk => {
    let take = takeForChunk(input.takes, chunk.id)
    let approved = approvedSourceFor(input, chunk.id)
    let transcript = transcriptMap(chunk.segments)
    let (cachePath, sourceSha256, transcriptSha256) = cachePathFor(
      chunk,
      take,
      transcript,
      approved.sha256,
    )
    {chunk, take, transcript, cachePath, sourceSha256, transcriptSha256}
  })

let validateInputs = (input: inputs): unit => {
  assertExactFile(
    "approved production-source identity inventory",
    approvedSourceIdentitiesPath,
    approvedSourceIdentitiesSha256,
  )
  assertExactFile("raw-provider inventory", rawProviderInventoryPath, rawProviderInventorySha256)
  assertExactFile(
    "timing-equivalence inventory",
    timingEquivalenceInventoryPath,
    timingEquivalenceInventorySha256,
  )
  if sha256File(Path(planPath)) != approvedPlanSha256 ||
     sha256File(Path(sourceManifestPath)) != approvedSourceManifestSha256 {
    fail("approved EP9 table-read plan or source manifest changed")
  }
  if Belt.Array.length(input.segments) != 328 {
    fail(
      "expected 328 table-read segments, got " ++
      Belt.Int.toString(Belt.Array.length(input.segments)),
    )
  }
  if Belt.Array.length(input.chunks) != 27 || Belt.Array.length(input.takes) != 27 {
    fail("expected 27 planned chunks and 27 source takes")
  }
  let relevantSourceIds = productionChunks(input)
    ->Belt.Array.keep(chunk =>
      requiresAlignment(chunk) || Belt.Array.some(chunk.segments, segment => isSelectedKind(segment.kind))
    )
    ->Belt.Array.map(chunk => chunk.id)
  if Belt.Array.length(relevantSourceIds) != 19 ||
     Js.Dict.keys(input.approvedSources)->Belt.Array.length != 19 {
    fail("approved production-source scope changed")
  }
  Js.Dict.keys(input.approvedSources)->Belt.Array.forEach(id => {
    if !Belt.Array.some(relevantSourceIds, expected => expected == id) {
      fail("approved production-source inventory contains out-of-scope chunk " ++ id)
    }
    let approved = approvedSourceFor(input, id)
    let take = takeForChunk(input.takes, id)
    if approved.path != take.path || abs_float(approved.duration -. take.duration) > 0.000001 ||
       !exists(Path(take.path)) || sha256File(Path(take.path)) != approved.sha256 {
      fail("approved production-source identity mismatch for " ++ id)
    }
  })
  if input.segments->Belt.Array.some(segment =>
      !isProductionScene(segment.scene) && !isLockedAssetScene(segment.scene)
    ) || input.chunks->Belt.Array.some(chunk =>
      !isProductionScene(chunk.scene) && !isLockedAssetScene(chunk.scene)
    ) {
    fail("source contains a scene outside finale scenes 1-10 and locked scenes 0/100/1000")
  }
  let seenOrders = Js.Dict.empty()
  input.segments->Belt.Array.forEach(segment => {
    let key = Belt.Int.toString(segment.order)
    if Js.Dict.get(seenOrders, key) != None {
      fail("duplicate segment order " ++ key)
    }
    Js.Dict.set(seenOrders, key, true)
    if !isKnownSourceKind(segment.kind) {
      fail("unsupported segment kind " ++ segment.kind ++ " at " ++ key)
    }
  })
  let coveredOrders = Js.Dict.empty()
  input.chunks->Belt.Array.forEach(chunk => {
    let take = takeForChunk(input.takes, chunk.id)
    if chunk.scene != take.scene || chunk.kind != take.kind {
      fail("plan/source metadata mismatch for " ++ chunk.id)
    }
    if !exists(Path(take.path)) {
      fail("missing approved source take: " ++ take.path)
    }
    if take.duration <= 0.0 || fileSizeMb(Path(take.path)) < 0.001 {
      fail("implausible approved source take: " ++ take.path)
    }
    let actualDuration = pinnedProbeDuration(take.path)
    if abs_float(actualDuration -. take.duration) > 0.12 {
      fail(
        "source duration no longer matches approved manifest for " ++ chunk.id ++
        " (declared " ++ Js.Float.toString(take.duration) ++ ", actual " ++
        Js.Float.toString(actualDuration) ++ ")",
      )
    }
    chunk.segments->Belt.Array.forEach(segment => {
      let key = Belt.Int.toString(segment.order)
      if Js.Dict.get(coveredOrders, key) != None {
        fail("segment appears in more than one chunk: " ++ key)
      }
      Js.Dict.set(coveredOrders, key, true)
      if segment.scene != chunk.scene {
        fail("scene mismatch in " ++ chunk.id ++ " at segment " ++ key)
      }
    })
  })
  if Js.Dict.keys(coveredOrders)->Belt.Array.length != Belt.Array.length(input.segments) {
    fail("chunk coverage does not include every segment exactly once")
  }
  let scopedChunks = productionChunks(input)
  let scopedSegments = productionSegments(input)
  let selected = input.segments->Belt.Array.keep(isSelectedProductionSegment)
  if Belt.Array.length(scopedChunks) != 21 || Belt.Array.length(scopedSegments) != 262 {
    fail("expected scenes 1-10 to contain 21 chunks and 262 source segments")
  }
  if Belt.Array.length(selected) != expectedProductionStemCount {
    fail(
      "expected " ++ Belt.Int.toString(expectedProductionStemCount) ++
      " production dialogue/chorus lines in scenes 1-10, got " ++
      Belt.Int.toString(Belt.Array.length(selected)),
    )
  }
  if scopedChunks->Belt.Array.some(chunk => isLockedAssetChunkId(chunk.id)) ||
     selected->Belt.Array.some(segment => !isProductionScene(segment.scene)) {
    fail("locked cold-open/title material entered the finale production scope")
  }
  if scopedChunks->Belt.Array.keep(isMixedChunk)->Belt.Array.length != 17 ||
     alignmentNeeds(input)->Belt.Array.length != 18 {
    fail("expected 17 mixed chunks plus one pure multi-line chunk in scenes 1-10")
  }
}

let alignmentJson = (need: alignmentNeed, value: alignment): Js.Json.t => {
  let root = Js.Dict.empty()
  Js.Dict.set(root, "pipeline_version", Js.Json.string(pipelineVersion))
  Js.Dict.set(root, "chunk_id", Js.Json.string(need.chunk.id))
  Js.Dict.set(root, "source_audio", Js.Json.string(need.take.path))
  Js.Dict.set(root, "source_sha256", Js.Json.string(need.sourceSha256))
  Js.Dict.set(root, "transcript", Js.Json.string(need.transcript.text))
  Js.Dict.set(root, "transcript_sha256", Js.Json.string(need.transcriptSha256))
  Js.Dict.set(root, "loss", Js.Json.number(value.loss))
  Js.Dict.set(root, "characters", Js.Json.array(value.characters->Belt.Array.map(character => {
    let row = Js.Dict.empty()
    Js.Dict.set(row, "text", Js.Json.string(character.text))
    Js.Dict.set(row, "start", Js.Json.number(character.start))
    Js.Dict.set(row, "end", Js.Json.number(character.end_))
    Js.Json.object_(row)
  })))
  Js.Json.object_(root)
}

let parseAlignment = (need: alignmentNeed, raw: string): alignment => {
  let root = raw->Js.Json.parseExn->jsonObject("alignment cache " ++ need.chunk.id)
  if stringField(root, "pipeline_version", "alignment cache") != pipelineVersion ||
     stringField(root, "chunk_id", "alignment cache") != need.chunk.id ||
     stringField(root, "source_audio", "alignment cache") != need.take.path ||
     stringField(root, "source_sha256", "alignment cache") != need.sourceSha256 ||
     stringField(root, "transcript", "alignment cache") != need.transcript.text ||
     stringField(root, "transcript_sha256", "alignment cache") != need.transcriptSha256 {
    fail("alignment cache identity mismatch for " ++ need.chunk.id)
  }
  let value: alignment = {
    loss: numberField(root, "loss", "alignment cache"),
    characters: arrayField(root, "characters", "alignment cache")->Belt.Array.map(json => {
      let row = jsonObject(json, "alignment character")
      {
        text: stringField(row, "text", "alignment character"),
        start: numberField(row, "start", "alignment character"),
        end_: numberField(row, "end", "alignment character"),
      }
    }),
  }
  let rebuilt = value.characters->Belt.Array.map(character => character.text)->Js.Array2.joinWith("")
  if rebuilt != need.transcript.text {
    fail("alignment transcript mismatch for " ++ need.chunk.id)
  }
  let previousStart = ref(-1.0)
  let previousEnd = ref(-1.0)
  value.characters->Belt.Array.forEach(character => {
    if !Js.Float.isFinite(character.start) || !Js.Float.isFinite(character.end_) ||
       character.start < 0.0 || character.end_ < character.start ||
       character.end_ > need.take.duration +. 0.25 {
      fail("invalid alignment timing for " ++ need.chunk.id)
    }
    if character.start +. 0.001 < previousStart.contents ||
       character.end_ +. 0.001 < previousEnd.contents {
      fail("non-monotonic alignment timing for " ++ need.chunk.id)
    }
    previousStart := character.start
    previousEnd := character.end_
  })
  value
}

let cachedAlignment = (need: alignmentNeed): option<alignment> =>
  exists(Path(need.cachePath))
    ? Some(parseAlignment(need, readText(Path(need.cachePath))))
    : None

let elevenDryReport = (input: inputs): dryReport => {
  let scopedSegments = productionSegments(input)
  let scopedChunks = productionChunks(input)
  let selected = input.segments->Belt.Array.keep(isSelectedProductionSegment)
  let needs = alignmentNeeds(input)
  let missingAlignmentIds = needs->Belt.Array.keepMap(need =>
    switch cachedAlignment(need) {
    | Some(_) => None
    | None => Some(need.chunk.id)
    }
  )
  {
    alignmentMethod: "legacy eleven-forced-alignment selector (disabled)",
    alignerStatus: "disabled before provider call; use local Vakyansh",
    segmentCount: Belt.Array.length(input.segments),
    chunkCount: Belt.Array.length(input.chunks),
    productionSegmentCount: Belt.Array.length(scopedSegments),
    productionChunkCount: Belt.Array.length(scopedChunks),
    lockedSegmentCount: Belt.Array.length(input.segments) - Belt.Array.length(scopedSegments),
    lockedChunkCount: Belt.Array.length(input.chunks) - Belt.Array.length(scopedChunks),
    selectedCount: Belt.Array.length(selected),
    dialogueCount: selected->Belt.Array.keep(segment => segment.kind == "dialogue")->Belt.Array.length,
    chorusCount: selected->Belt.Array.keep(segment => segment.kind == "chorus")->Belt.Array.length,
    narrationExcluded:
      scopedSegments->Belt.Array.keep(segment => segment.kind == "narration")->Belt.Array.length,
    mimicExcluded:
      scopedSegments->Belt.Array.keep(segment => segment.kind == "mimic")->Belt.Array.length,
    mixedChunkCount: scopedChunks->Belt.Array.keep(isMixedChunk)->Belt.Array.length,
    alignmentChunkCount: Belt.Array.length(needs),
    rawCachedCount: 0,
    cachedAlignmentCount: Belt.Array.length(needs) - Belt.Array.length(missingAlignmentIds),
    missingAlignmentIds,
  }
}

let printDryReport = (report: dryReport): unit => {
  Js.log("KUKU EP9 PRODUCTION DIALOGUE — DRY")
  Js.log("alignment method: " ++ report.alignmentMethod)
  Js.log("aligner status: " ++ report.alignerStatus)
  Js.log(
    "source inventory: " ++ Belt.Int.toString(report.segmentCount) ++ " segments / " ++
    Belt.Int.toString(report.chunkCount) ++ " chunks",
  )
  Js.log(
    "production scope: scenes 1-10; " ++ Belt.Int.toString(report.productionSegmentCount) ++
    " segments / " ++ Belt.Int.toString(report.productionChunkCount) ++ " chunks; locked " ++
    "cold-open/title excluded " ++ Belt.Int.toString(report.lockedSegmentCount) ++
    " segments / " ++ Belt.Int.toString(report.lockedChunkCount) ++ " chunks",
  )
  Js.log(
    "production stems: " ++ Belt.Int.toString(report.selectedCount) ++ " (dialogue " ++
    Belt.Int.toString(report.dialogueCount) ++ ", chorus " ++
    Belt.Int.toString(report.chorusCount) ++ "); scoped narration excluded " ++
    Belt.Int.toString(report.narrationExcluded) ++ "; mimic/SFX excluded " ++
    Belt.Int.toString(report.mimicExcluded),
  )
  Js.log(
    "alignment inputs: " ++ Belt.Int.toString(report.alignmentChunkCount) ++ " (" ++
    Belt.Int.toString(report.mixedChunkCount) ++ " mixed + 1 pure multi-line); raw cached " ++
    Belt.Int.toString(report.rawCachedCount) ++ "; derived cached " ++
    Belt.Int.toString(report.cachedAlignmentCount) ++ "; missing " ++
    Belt.Int.toString(Belt.Array.length(report.missingAlignmentIds)),
  )
  report.missingAlignmentIds->Belt.Array.forEach(id => Js.log("  missing " ++ id))
  Js.log("DRY=1 — zero provider calls, zero model runs; no stems or production manifest written.")
}

let paidAllowed = (~dry: bool, ~paid: bool): bool => paid && !dry

let alignmentModeFor = (~localRequested: bool, ~elevenRequested: bool): alignmentMode => {
  if localRequested && elevenRequested {
    fail("LOCAL_ALIGN=1 and ELEVEN_ALIGN=1 are mutually exclusive")
  }
  elevenRequested ? ElevenForced : LocalVakyansh
}

let alignmentModeName = mode =>
  switch mode {
  | LocalVakyansh => "local-vakyansh-ctc-plus-whisper-validation"
  | ElevenForced => "eleven-forced-alignment"
  }

let detectedWhisperVersion = (): string => {
  assertExactFile("whisper-cli", whisperBinary, approvedWhisperBinarySha256)
  let result = run(~cmd=whisperBinary, ~args=["--version"])
  assertExactFile("whisper-cli", whisperBinary, approvedWhisperBinarySha256)
  if result.code != 0 {
    fail("whisper-cli --version failed: " ++ result.stderr)
  }
  let lines = (result.stdout ++ "\n" ++ result.stderr)->Js.String2.split("\n")
  switch Belt.Array.getBy(lines, line => Js.String2.includes(line, "whisper.cpp version:")) {
  | Some(line) if trim(line) == approvedWhisperVersion => approvedWhisperVersion
  | Some(line) => fail("unexpected local whisper-cli version: " ++ trim(line))
  | None => fail("could not identify local whisper-cli version")
  }
}

let exactToolVersion = (path: string): string => {
  let result = run(~cmd=path, ~args=["--version"])
  if result.code != 0 {
    fail("Vakyansh aligner --version failed: " ++ result.stderr)
  }
  let value = trim(result.stdout)
  if value != approvedVakyanshToolVersion {
    fail(
      "Vakyansh aligner version mismatch: " ++ value ++ " != " ++
      approvedVakyanshToolVersion,
    )
  }
  value
}

let verifyVakyanshAudit = (): unit => {
  if !exists(Path(vakyanshAuditLicensePath)) ||
     sha256File(Path(vakyanshAuditLicensePath)) != approvedVakyanshLicenseSha256 {
    fail("approved Vakyansh MIT license audit copy is missing or changed")
  }
  if !exists(Path(vakyanshAuditVocabPath)) ||
     sha256File(Path(vakyanshAuditVocabPath)) != approvedVakyanshVocabSha256 {
    fail("approved Vakyansh vocabulary audit copy is missing or changed")
  }
  if !exists(Path(vakyanshAuditProvenancePath)) ||
     sha256File(Path(vakyanshAuditProvenancePath)) != approvedVakyanshProvenanceSha256 {
    fail("approved Vakyansh provenance inventory is missing or changed")
  }
  assertExactFile("whisper.cpp MIT license audit", whisperAuditLicensePath, approvedWhisperLicenseSha256)
  assertExactFile(
    "Whisper validator provenance audit",
    whisperAuditProvenancePath,
    approvedWhisperProvenanceSha256,
  )
  let whisperProvenance = readText(Path(whisperAuditProvenancePath))->Js.Json.parseExn->jsonObject(
    "Whisper validator provenance",
  )
  if stringField(whisperProvenance, "version", "Whisper validator provenance") !=
       approvedWhisperVersion ||
     stringField(whisperProvenance, "binary_sha256", "Whisper validator provenance") !=
       approvedWhisperBinarySha256 ||
     stringField(whisperProvenance, "model_sha256", "Whisper validator provenance") !=
       approvedWhisperModelSha256 ||
     stringField(whisperProvenance, "validation_config", "Whisper validator provenance") !=
       stemWhisperConfig {
    fail("Whisper validator provenance identity mismatch")
  }
  verifyLocalAudioToolchain()
  let provenance = readText(Path(vakyanshAuditProvenancePath))->Js.Json.parseExn->jsonObject(
    "Vakyansh provenance",
  )
  if stringField(provenance, "license", "Vakyansh provenance") != "MIT" ||
     stringField(provenance, "model_sha256", "Vakyansh provenance") != approvedVakyanshModelSha256 ||
     stringField(provenance, "vocab_sha256", "Vakyansh provenance") != approvedVakyanshVocabSha256 ||
     stringField(provenance, "license_sha256", "Vakyansh provenance") != approvedVakyanshLicenseSha256 ||
     stringField(provenance, "local_aligner_version", "Vakyansh provenance") != approvedVakyanshToolVersion ||
     stringField(provenance, "local_aligner_sha256", "Vakyansh provenance") != approvedVakyanshToolSha256 ||
     stringField(provenance, "alignment_config", "Vakyansh provenance") != vakyanshConfig {
    fail("Vakyansh provenance identities changed")
  }
}

let vakyanshContextIfReady = (
  ~toolPath: option<string>,
  ~modelPath: option<string>,
  ~vocabPath: option<string>,
  ~whisperModelPath: option<string>,
): option<vakyanshContext> =>
  switch (toolPath, modelPath, vocabPath, whisperModelPath) {
  | (Some(tool), Some(model), Some(vocab), Some(whisperModel))
      if tool != "" && model != "" && vocab != "" && whisperModel != "" &&
        exists(Path(tool)) && exists(Path(model)) && exists(Path(vocab)) &&
        exists(Path(whisperBinary)) && exists(Path(whisperModel)) &&
        sha256File(Path(whisperBinary)) == approvedWhisperBinarySha256 &&
        sha256File(Path(tool)) == approvedVakyanshToolSha256 &&
        sha256File(Path(model)) == approvedVakyanshModelSha256 &&
        sha256File(Path(vocab)) == approvedVakyanshVocabSha256 &&
        sha256File(Path(whisperModel)) == approvedWhisperModelSha256 =>
    Some({
      toolPath: tool,
      toolSha256: approvedVakyanshToolSha256,
      toolVersion: exactToolVersion(tool),
      modelPath: model,
      modelSha256: approvedVakyanshModelSha256,
      vocabPath: vocab,
      vocabSha256: approvedVakyanshVocabSha256,
      whisperModelPath: whisperModel,
      whisperModelSha256: approvedWhisperModelSha256,
      whisperVersion: detectedWhisperVersion(),
    })
  | _ => None
  }

let requireVakyanshContext = (
  ~toolPath: option<string>,
  ~modelPath: option<string>,
  ~vocabPath: option<string>,
  ~whisperModelPath: option<string>,
): vakyanshContext => {
  let required = (label: string, value: option<string>): string =>
    switch value {
    | Some(path) if path != "" => path
    | _ => fail(label ++ " must name an already-installed absolute local path")
    }
  let tool = required("VAKYANSH_ALIGNER", toolPath)
  let model = required("VAKYANSH_MODEL", modelPath)
  let vocab = required("VAKYANSH_VOCAB", vocabPath)
  let whisperModel = required("WHISPER_MODEL", whisperModelPath)
  ;[
    ("VAKYANSH_ALIGNER", tool),
    ("VAKYANSH_MODEL", model),
    ("VAKYANSH_VOCAB", vocab),
    ("WHISPER_MODEL", whisperModel),
    ("whisper-cli", whisperBinary),
  ]->Belt.Array.forEach(((label, path)) => {
    if !Js.String2.startsWith(path, "/") || !exists(Path(path)) {
      fail(label ++ " is not an existing absolute path: " ++ path)
    }
  })
  let assertHash = (label, path, expected) => {
    let actual = sha256File(Path(path))
    if actual != expected {
      fail(label ++ " SHA-256 mismatch: " ++ actual ++ " != " ++ expected)
    }
  }
  assertHash("VAKYANSH_ALIGNER", tool, approvedVakyanshToolSha256)
  assertHash("VAKYANSH_MODEL", model, approvedVakyanshModelSha256)
  assertHash("VAKYANSH_VOCAB", vocab, approvedVakyanshVocabSha256)
  assertHash("WHISPER_MODEL", whisperModel, approvedWhisperModelSha256)
  assertHash("whisper-cli", whisperBinary, approvedWhisperBinarySha256)
  verifyVakyanshAudit()
  {
    toolPath: tool,
    toolSha256: approvedVakyanshToolSha256,
    toolVersion: exactToolVersion(tool),
    modelPath: model,
    modelSha256: approvedVakyanshModelSha256,
    vocabPath: vocab,
    vocabSha256: approvedVakyanshVocabSha256,
    whisperModelPath: whisperModel,
    whisperModelSha256: approvedWhisperModelSha256,
    whisperVersion: detectedWhisperVersion(),
  }
}

let whisperVersion = (): string => {
  if !exists(Path(whisperBinary)) {
    fail("local Whisper binary is missing: " ++ whisperBinary)
  }
  let result = run(~cmd=whisperBinary, ~args=["--version"])
  if result.code != 0 {
    fail("whisper-cli --version failed: " ++ result.stderr)
  }
  let lines = (result.stdout ++ "\n" ++ result.stderr)->Js.String2.split("\n")
  switch Belt.Array.getBy(lines, line => Js.String2.includes(line, "whisper.cpp version:")) {
  | Some(line) => trim(line)
  | None => fail("could not identify local whisper-cli version")
  }
}

let localContextIfReady = (modelPath: option<string>): option<localContext> =>
  switch modelPath {
  | Some(path) if path != "" && exists(Path(whisperBinary)) && exists(Path(path)) &&
      fileSizeMb(Path(path)) >= 10.0 =>
    Some({modelPath: path, modelSha256: sha256File(Path(path)), whisperVersion: whisperVersion()})
  | _ => None
  }

let requireLocalContext = (modelPath: option<string>): localContext =>
  switch modelPath {
  | None | Some("") => fail(
      "local alignment requires WHISPER_MODEL=/absolute/path/to/an/already-downloaded-model.bin; " ++
      "this program never downloads models",
    )
  | Some(_) if !exists(Path(whisperBinary)) =>
    fail("local Whisper binary is missing: " ++ whisperBinary)
  | Some(path) if !exists(Path(path)) => fail("WHISPER_MODEL does not exist: " ++ path)
  | Some(path) if fileSizeMb(Path(path)) < 10.0 =>
    fail("WHISPER_MODEL is implausibly small or still downloading: " ++ path)
  | Some(path) =>
    {modelPath: path, modelSha256: sha256File(Path(path)), whisperVersion: whisperVersion()}
  }

/* Convert transcript UTF-16 offsets to alignment rows by accumulating the text
   returned in each row. This remains correct for Devanagari combining marks and
   for providers that group more than one code unit into a timing row. */
let blockTimings = (
  mapped: transcriptMap,
  aligned: alignment,
  label: string,
): array<blockTiming> =>
  mapped.spans->Belt.Array.map(span => {
    let cursor = ref(0)
    let first: ref<option<charTiming>> = ref(None)
    let last: ref<option<charTiming>> = ref(None)
    aligned.characters->Belt.Array.forEach(character => {
      let rowFrom = cursor.contents
      let rowTo = rowFrom + Js.String2.length(character.text)
      let overlaps = rowTo > span.from && rowFrom < span.to_
      if overlaps && trim(character.text) != "" {
        if first.contents == None {
          first := Some(character)
        }
        last := Some(character)
      }
      cursor := rowTo
    })
    switch (first.contents, last.contents) {
    | (Some(first), Some(last)) if last.end_ > first.start =>
      {order: span.order, start: first.start, end_: last.end_}
    | _ => fail(label ++ " has no valid timing for segment " ++ Belt.Int.toString(span.order))
    }
  })

let timingForOrder = (rows: array<blockTiming>, order: int, label: string): blockTiming =>
  switch Belt.Array.getBy(rows, row => row.order == order) {
  | Some(row) => row
  | None => fail(label ++ " has no timing for segment " ++ Belt.Int.toString(order))
  }

let localPathsFor = (need: alignmentNeed, context: localContext): localPaths => {
  let rawSignature =
    pipelineVersion ++ "|local-whisper|" ++ context.whisperVersion ++ "|" ++
    context.modelSha256 ++ "|" ++ localWhisperConfig ++ "|" ++ need.sourceSha256 ++ "|" ++
    need.transcriptSha256
  {
    rawSignature,
    rawPath: localRawDir ++ "/" ++ need.chunk.id ++ "_" ++ sha256Text(rawSignature) ++
      ".whisper.json",
  }
}

let localDerivedPath = (
  need: alignmentNeed,
  context: localContext,
  rawPath: string,
): string => {
  if !exists(Path(rawPath)) {
    fail("cannot identify derived cache before raw Whisper JSON exists for " ++ need.chunk.id)
  }
  let signature =
    pipelineVersion ++ "|" ++ Kuku_LocalWordAlign.algorithmVersion ++ "|" ++ silenceConfig ++
    "|" ++ context.modelSha256 ++ "|" ++ need.sourceSha256 ++ "|" ++ need.transcriptSha256 ++
    "|" ++ sha256File(Path(rawPath))
  localDerivedDir ++ "/" ++ need.chunk.id ++ "_" ++ sha256Text(signature) ++ ".json"
}

let floatAfter = (line: string, marker: string): option<float> => {
  let index = Js.String2.indexOf(line, marker)
  index < 0
    ? None
    : Js.String2.sliceToEnd(line, ~from=index + Js.String2.length(marker))
      ->trim
      ->Js.String2.split(" ")
      ->Belt.Array.get(0)
      ->Belt.Option.flatMap(Belt.Float.fromString)
}

let localSilenceGaps = (take: sourceTake): array<Kuku_LocalWordAlign.silenceGap> => {
  verifyLocalAudioToolchain()
  let result = run(
    ~cmd=pinnedFfmpegBinary,
    ~args=[
      "-nostdin", "-hide_banner", "-i", take.path,
      "-af", silenceConfig, "-f", "null", "-",
    ],
  )
  verifyLocalAudioToolchain()
  if result.code != 0 {
    fail("local silence analysis failed for " ++ take.id ++ ": " ++ result.stderr)
  }
  let gaps: array<Kuku_LocalWordAlign.silenceGap> = []
  let pending: ref<option<float>> = ref(None)
  result.stderr->Js.String2.split("\n")->Belt.Array.forEach(line => {
    switch floatAfter(line, "silence_start:") {
    | Some(start) => pending := Some(start)
    | None => ()
    }
    switch (pending.contents, floatAfter(line, "silence_end:")) {
    | (Some(start), Some(end_)) => {
        if start > 0.02 && end_ < take.duration -. 0.02 && end_ > start {
          let _ = Js.Array2.push(gaps, {start, end_})
        }
        pending := None
      }
    | _ => ()
    }
  })
  gaps
}

let runLocalWhisper = (
  need: alignmentNeed,
  context: localContext,
): string => {
  let paths = localPathsFor(need, context)
  if exists(Path(paths.rawPath)) {
    let _ = Kuku_LocalWordAlign.parseWhisperJson(readText(Path(paths.rawPath)))
    paths.rawPath
  } else {
    ensureDirPath(Path(localRawDir))
    let scratch = tempDir("kuku-ep9-local-whisper-")
    let whisperInput = pathString(scratch) ++ "/" ++ need.chunk.id ++ "_16k_mono.wav"
    let outputBase = pathString(scratch) ++ "/" ++ need.chunk.id
    let outputJson = outputBase ++ ".json"
    ffmpeg([
      "-nostdin", "-loglevel", "error", "-y", "-i", need.take.path,
      "-vn", "-ac", "1", "-ar", "16000", "-c:a", "pcm_s16le", whisperInput,
    ])
    let Seconds(wavDuration) = probeDuration(Path(whisperInput))
    if abs_float(wavDuration -. need.take.duration) > 0.12 {
      fail("16 kHz Whisper input duration drift for " ++ need.chunk.id)
    }
    let result = run(
      ~cmd=whisperBinary,
      ~args=[
        "-ng",
        "-m", context.modelPath,
        "-l", "hi",
        "-f", whisperInput,
        "-ojf",
        "-sow",
        "-np",
        "--no-fallback",
        "--temperature", "0",
        "--beam-size", "5",
        "--best-of", "5",
        "--prompt", need.transcript.text,
        "-of", outputBase,
      ],
    )
    if result.code != 0 {
      fail(
        "local whisper-cli failed for " ++ need.chunk.id ++ ": " ++
        Js.String2.sliceToEnd(result.stderr, ~from=max(0, Js.String2.length(result.stderr) - 1200)),
      )
    }
    if !exists(Path(outputJson)) {
      fail("whisper-cli produced no full JSON for " ++ need.chunk.id)
    }
    let _ = Kuku_LocalWordAlign.parseWhisperJson(readText(Path(outputJson)))
    if !publishFileExclusive(Path(outputJson), Path(paths.rawPath)) {
      fail("immutable raw Whisper cache appeared during publication: " ++ paths.rawPath)
    }
    paths.rawPath
  }
}

let localDerivedJson = (
  need: alignmentNeed,
  context: localContext,
  rawPath: string,
  value: Kuku_LocalWordAlign.derived,
): Js.Json.t => {
  let root = Js.Dict.empty()
  Js.Dict.set(root, "pipeline_version", Js.Json.string(pipelineVersion))
  Js.Dict.set(root, "algorithm_version", Js.Json.string(Kuku_LocalWordAlign.algorithmVersion))
  Js.Dict.set(root, "alignment_method", Js.Json.string("local-whisper-fuzzy-sequence"))
  Js.Dict.set(root, "chunk_id", Js.Json.string(need.chunk.id))
  Js.Dict.set(root, "source_audio", Js.Json.string(need.take.path))
  Js.Dict.set(root, "source_sha256", Js.Json.string(need.sourceSha256))
  Js.Dict.set(root, "transcript_sha256", Js.Json.string(need.transcriptSha256))
  Js.Dict.set(root, "model_path", Js.Json.string(context.modelPath))
  Js.Dict.set(root, "model_sha256", Js.Json.string(context.modelSha256))
  Js.Dict.set(root, "whisper_version", Js.Json.string(context.whisperVersion))
  Js.Dict.set(root, "whisper_config", Js.Json.string(localWhisperConfig))
  Js.Dict.set(root, "silence_config", Js.Json.string(silenceConfig))
  Js.Dict.set(root, "raw_whisper_json", Js.Json.string(rawPath))
  Js.Dict.set(root, "raw_whisper_sha256", Js.Json.string(sha256File(Path(rawPath))))
  let quality = Js.Dict.empty()
  Js.Dict.set(quality, "expected_words", Js.Json.number(Belt.Int.toFloat(value.quality.expectedWords)))
  Js.Dict.set(quality, "observed_words", Js.Json.number(Belt.Int.toFloat(value.quality.observedWords)))
  Js.Dict.set(quality, "matched_words", Js.Json.number(Belt.Int.toFloat(value.quality.matchedWords)))
  Js.Dict.set(quality, "coverage", Js.Json.number(value.quality.coverage))
  Js.Dict.set(quality, "observed_precision", Js.Json.number(value.quality.observedPrecision))
  Js.Dict.set(quality, "mean_similarity", Js.Json.number(value.quality.meanSimilarity))
  Js.Dict.set(quality, "sequence_score", Js.Json.number(value.quality.sequenceScore))
  Js.Dict.set(quality, "average_token_probability", Js.Json.number(value.quality.averageTokenProbability))
  Js.Dict.set(
    quality,
    "silence_supported_boundaries",
    Js.Json.number(Belt.Int.toFloat(value.quality.silenceSupportedBoundaries)),
  )
  Js.Dict.set(quality, "boundary_count", Js.Json.number(Belt.Int.toFloat(value.quality.boundaryCount)))
  Js.Dict.set(quality, "confidence", Js.Json.number(value.quality.confidence))
  Js.Dict.set(root, "quality", Js.Json.object_(quality))
  Js.Dict.set(root, "blocks", Js.Json.array(value.blocks->Belt.Array.map(block => {
    let row = Js.Dict.empty()
    Js.Dict.set(row, "order", Js.Json.number(Belt.Int.toFloat(block.order)))
    Js.Dict.set(row, "start", Js.Json.number(block.start))
    Js.Dict.set(row, "end", Js.Json.number(block.end_))
    Js.Dict.set(row, "expected_words", Js.Json.number(Belt.Int.toFloat(block.expectedWords)))
    Js.Dict.set(row, "matched_words", Js.Json.number(Belt.Int.toFloat(block.matchedWords)))
    Js.Dict.set(row, "coverage", Js.Json.number(block.coverage))
    Js.Json.object_(row)
  })))
  Js.Json.object_(root)
}

let parseLocalDerived = (
  need: alignmentNeed,
  context: localContext,
  rawPath: string,
  raw: string,
): array<blockTiming> => {
  let root = raw->Js.Json.parseExn->jsonObject("local derived cache " ++ need.chunk.id)
  if stringField(root, "pipeline_version", "local derived cache") != pipelineVersion ||
     stringField(root, "algorithm_version", "local derived cache") != Kuku_LocalWordAlign.algorithmVersion ||
     stringField(root, "alignment_method", "local derived cache") != "local-whisper-fuzzy-sequence" ||
     stringField(root, "chunk_id", "local derived cache") != need.chunk.id ||
     stringField(root, "source_audio", "local derived cache") != need.take.path ||
     stringField(root, "source_sha256", "local derived cache") != need.sourceSha256 ||
     stringField(root, "transcript_sha256", "local derived cache") != need.transcriptSha256 ||
     stringField(root, "model_sha256", "local derived cache") != context.modelSha256 ||
     stringField(root, "whisper_version", "local derived cache") != context.whisperVersion ||
     stringField(root, "whisper_config", "local derived cache") != localWhisperConfig ||
     stringField(root, "silence_config", "local derived cache") != silenceConfig ||
     stringField(root, "raw_whisper_json", "local derived cache") != rawPath ||
     stringField(root, "raw_whisper_sha256", "local derived cache") != sha256File(Path(rawPath)) {
    fail("local derived cache identity mismatch for " ++ need.chunk.id)
  }
  let quality = switch field(root, "quality")->Belt.Option.flatMap(Js.Json.decodeObject) {
  | Some(value) => value
  | None => fail("local derived cache has no quality object")
  }
  let confidence = numberField(quality, "confidence", "local derived quality")
  let coverage = numberField(quality, "coverage", "local derived quality")
  let precision = numberField(quality, "observed_precision", "local derived quality")
  let similarity = numberField(quality, "mean_similarity", "local derived quality")
  let sequenceScore = numberField(quality, "sequence_score", "local derived quality")
  let tokenProbability = numberField(quality, "average_token_probability", "local derived quality")
  if confidence < 0.0 || confidence > 1.0 || coverage < Kuku_LocalWordAlign.minOverallCoverage ||
     precision < Kuku_LocalWordAlign.minObservedPrecision ||
     similarity < Kuku_LocalWordAlign.minMeanSimilarity ||
     sequenceScore < Kuku_LocalWordAlign.minSequenceScore ||
     (tokenProbability >= 0.0 && tokenProbability < Kuku_LocalWordAlign.minAverageTokenProbability) {
    fail("local derived cache no longer passes confidence gates for " ++ need.chunk.id)
  }
  let blockJsons = arrayField(root, "blocks", "local derived cache")
  if Belt.Array.length(blockJsons) != Belt.Array.length(need.chunk.segments) {
    fail("local derived block count mismatch for " ++ need.chunk.id)
  }
  let blocks = blockJsons->Belt.Array.mapWithIndex((index, json) => {
    let row = jsonObject(json, "local derived block")
    let timing = {
      order: numberField(row, "order", "local derived block")->Belt.Float.toInt,
      start: numberField(row, "start", "local derived block"),
      end_: numberField(row, "end", "local derived block"),
    }
    let expected = Belt.Array.getExn(need.chunk.segments, index)
    let expectedWords = numberField(row, "expected_words", "local derived block")->Belt.Float.toInt
    let matchedWords = numberField(row, "matched_words", "local derived block")->Belt.Float.toInt
    let blockCoverage = numberField(row, "coverage", "local derived block")
    let actualExpectedWords =
      Kuku_LocalWordAlign.normalizedWords(spokenText(expected))->Belt.Array.length
    let minimumCoverage = actualExpectedWords <= 1 ? 1.0 : actualExpectedWords == 2 ? 0.50 : 0.40
    if timing.order != expected.order || timing.start < 0.0 || timing.end_ <= timing.start ||
       timing.end_ > need.take.duration +. 0.25 || expectedWords != actualExpectedWords ||
       matchedWords <= 0 || matchedWords > expectedWords || blockCoverage < minimumCoverage ||
       abs_float(blockCoverage -. Belt.Int.toFloat(matchedWords) /. Belt.Int.toFloat(expectedWords)) > 0.01 {
      fail("invalid or reordered local derived block for " ++ need.chunk.id)
    }
    timing
  })
  blocks->Belt.Array.forEachWithIndex((index, block) => {
    if index > 0 && block.start +. 0.20 < Belt.Array.getExn(blocks, index - 1).start {
      fail("non-monotonic local derived blocks for " ++ need.chunk.id)
    }
  })
  blocks
}

let cachedLocalBlocks = (
  need: alignmentNeed,
  context: localContext,
): option<array<blockTiming>> => {
  let paths = localPathsFor(need, context)
  if !exists(Path(paths.rawPath)) {
    None
  } else {
    let derivedPath = localDerivedPath(need, context, paths.rawPath)
    exists(Path(derivedPath))
      ? Some(parseLocalDerived(need, context, paths.rawPath, readText(Path(derivedPath))))
      : None
  }
}

let obtainLocalBlockTimings = (
  input: inputs,
  context: localContext,
): Js.Dict.t<array<blockTiming>> => {
  let results: Js.Dict.t<array<blockTiming>> = Js.Dict.empty()
  let needs = alignmentNeeds(input)
  for index in 0 to Belt.Array.length(needs) - 1 {
    let need = Belt.Array.getExn(needs, index)
    let blocks = switch cachedLocalBlocks(need, context) {
    | Some(value) => value
    | None => {
        let rawPath = runLocalWhisper(need, context)
        let observed = Kuku_LocalWordAlign.parseWhisperJson(readText(Path(rawPath)))
        let known: array<Kuku_LocalWordAlign.knownSegment> = need.chunk.segments->Belt.Array.map(
          segment => ({
            order: segment.order,
            text: spokenText(segment),
          }: Kuku_LocalWordAlign.knownSegment),
        )
        let derived = try Kuku_LocalWordAlign.derive(
          known,
          observed,
          localSilenceGaps(need.take),
        ) catch {
        | Kuku_LocalWordAlign.LocalWordAlignment(message) =>
          fail(need.chunk.id ++ " local alignment rejected: " ++ message)
        }
        let derivedPath = localDerivedPath(need, context, rawPath)
        let body = localDerivedJson(need, context, rawPath, derived)->Js.Json.stringifyWithSpace(1)
        let validated = parseLocalDerived(need, context, rawPath, body)
        ensureDirPath(Path(localDerivedDir))
        if !writeTextExclusive(Path(derivedPath), body) {
          fail("immutable local derived cache appeared during publication: " ++ derivedPath)
        }
        validated
      }
    }
    Js.Dict.set(results, need.chunk.id, blocks)
  }
  results
}

let localDryReport = (input: inputs, modelPath: option<string>): dryReport => {
  let needs = alignmentNeeds(input)
  let scopedSegments = productionSegments(input)
  let scopedChunks = productionChunks(input)
  let context = localContextIfReady(modelPath)
  let rawCachedCount = ref(0)
  let cachedAlignmentCount = ref(0)
  let missingAlignmentIds: array<string> = []
  needs->Belt.Array.forEach(need => {
    let cached = switch context {
    | Some(context) => {
        let paths = localPathsFor(need, context)
        if exists(Path(paths.rawPath)) {
          rawCachedCount := rawCachedCount.contents + 1
        }
        cachedLocalBlocks(need, context) != None
      }
    | None => false
    }
    if cached {
      cachedAlignmentCount := cachedAlignmentCount.contents + 1
    } else {
      let _ = Js.Array2.push(missingAlignmentIds, need.chunk.id)
    }
  })
  let status = if !exists(Path(whisperBinary)) {
    "whisper-cli missing at " ++ whisperBinary
  } else {
    switch modelPath {
    | None | Some("") => "WHISPER_MODEL is not set; model download is never automatic"
    | Some(path) if !exists(Path(path)) => "WHISPER_MODEL not found: " ++ path
    | Some(path) if fileSizeMb(Path(path)) < 10.0 => "WHISPER_MODEL is still downloading or too small: " ++ path
    | Some(path) => "ready: " ++ path
    }
  }
  let selected = input.segments->Belt.Array.keep(isSelectedProductionSegment)
  {
    alignmentMethod: "local-whisper (default, zero provider)",
    alignerStatus: status,
    segmentCount: Belt.Array.length(input.segments),
    chunkCount: Belt.Array.length(input.chunks),
    productionSegmentCount: Belt.Array.length(scopedSegments),
    productionChunkCount: Belt.Array.length(scopedChunks),
    lockedSegmentCount: Belt.Array.length(input.segments) - Belt.Array.length(scopedSegments),
    lockedChunkCount: Belt.Array.length(input.chunks) - Belt.Array.length(scopedChunks),
    selectedCount: Belt.Array.length(selected),
    dialogueCount: selected->Belt.Array.keep(segment => segment.kind == "dialogue")->Belt.Array.length,
    chorusCount: selected->Belt.Array.keep(segment => segment.kind == "chorus")->Belt.Array.length,
    narrationExcluded:
      scopedSegments->Belt.Array.keep(segment => segment.kind == "narration")->Belt.Array.length,
    mimicExcluded:
      scopedSegments->Belt.Array.keep(segment => segment.kind == "mimic")->Belt.Array.length,
    mixedChunkCount: scopedChunks->Belt.Array.keep(isMixedChunk)->Belt.Array.length,
    alignmentChunkCount: Belt.Array.length(needs),
    rawCachedCount: rawCachedCount.contents,
    cachedAlignmentCount: cachedAlignmentCount.contents,
    missingAlignmentIds,
  }
}

let vakyanshJobJson = (need: alignmentNeed, context: vakyanshContext): string => {
  let root = Js.Dict.empty()
  Js.Dict.set(root, "schema", Js.Json.string("metaphrand-vakyansh-job-v1"))
  Js.Dict.set(root, "chunk_id", Js.Json.string(need.chunk.id))
  Js.Dict.set(root, "source_audio", Js.Json.string(need.take.path))
  Js.Dict.set(root, "source_sha256", Js.Json.string(need.sourceSha256))
  Js.Dict.set(root, "transcript_sha256", Js.Json.string(need.transcriptSha256))
  Js.Dict.set(root, "source_plan_sha256", Js.Json.string(approvedPlanSha256))
  Js.Dict.set(root, "source_manifest_sha256", Js.Json.string(approvedSourceManifestSha256))
  Js.Dict.set(root, "tool_sha256", Js.Json.string(context.toolSha256))
  Js.Dict.set(root, "model_sha256", Js.Json.string(context.modelSha256))
  Js.Dict.set(root, "vocab_sha256", Js.Json.string(context.vocabSha256))
  Js.Dict.set(root, "config", Js.Json.string(vakyanshConfig))
  Js.Dict.set(root, "segments", Js.Json.array(need.chunk.segments->Belt.Array.map(segment => {
    let row = Js.Dict.empty()
    Js.Dict.set(row, "order", Js.Json.number(Belt.Int.toFloat(segment.order)))
    Js.Dict.set(row, "text", Js.Json.string(spokenText(segment)))
    Js.Json.object_(row)
  })))
  Js.Json.object_(root)->Js.Json.stringifyWithSpace(1)
}

let vakyanshRawPath = (need: alignmentNeed, context: vakyanshContext): string => {
  let signature =
    pipelineVersion ++ "|" ++ Kuku_LocalWordAlign.algorithmVersion ++ "|" ++
    vakyanshConfig ++ "|" ++ context.toolSha256 ++ "|" ++ context.modelSha256 ++ "|" ++
    context.vocabSha256 ++ "|" ++ approvedPlanSha256 ++ "|" ++
    approvedSourceManifestSha256 ++ "|" ++ approvedSourceIdentitiesSha256 ++ "|" ++
    approvedFfmpegSha256 ++ "|" ++ approvedFfprobeSha256 ++ "|" ++ need.sourceSha256 ++ "|" ++
    need.transcriptSha256
  vakyanshRawDir ++ "/" ++ need.chunk.id ++ "_" ++ sha256Text(signature) ++ ".ctc.json"
}

let qualityJson = (value: Kuku_LocalWordAlign.quality): Js.Json.t => {
  let row = Js.Dict.empty()
  Js.Dict.set(row, "expected_words", Js.Json.number(Belt.Int.toFloat(value.expectedWords)))
  Js.Dict.set(row, "observed_words", Js.Json.number(Belt.Int.toFloat(value.observedWords)))
  Js.Dict.set(row, "matched_words", Js.Json.number(Belt.Int.toFloat(value.matchedWords)))
  Js.Dict.set(row, "coverage", Js.Json.number(value.coverage))
  Js.Dict.set(row, "observed_precision", Js.Json.number(value.observedPrecision))
  Js.Dict.set(row, "mean_similarity", Js.Json.number(value.meanSimilarity))
  Js.Dict.set(row, "sequence_score", Js.Json.number(value.sequenceScore))
  Js.Dict.set(row, "average_token_probability", Js.Json.number(value.averageTokenProbability))
  Js.Dict.set(
    row,
    "silence_supported_boundaries",
    Js.Json.number(Belt.Int.toFloat(value.silenceSupportedBoundaries)),
  )
  Js.Dict.set(row, "boundary_count", Js.Json.number(Belt.Int.toFloat(value.boundaryCount)))
  Js.Dict.set(row, "confidence", Js.Json.number(value.confidence))
  Js.Json.object_(row)
}

let parseQuality = (json: Js.Json.t, label: string): Kuku_LocalWordAlign.quality => {
  let row = jsonObject(json, label)
  let value: Kuku_LocalWordAlign.quality = {
    expectedWords: numberField(row, "expected_words", label)->Belt.Float.toInt,
    observedWords: numberField(row, "observed_words", label)->Belt.Float.toInt,
    matchedWords: numberField(row, "matched_words", label)->Belt.Float.toInt,
    coverage: numberField(row, "coverage", label),
    observedPrecision: numberField(row, "observed_precision", label),
    meanSimilarity: numberField(row, "mean_similarity", label),
    sequenceScore: numberField(row, "sequence_score", label),
    averageTokenProbability: numberField(row, "average_token_probability", label),
    silenceSupportedBoundaries:
      numberField(row, "silence_supported_boundaries", label)->Belt.Float.toInt,
    boundaryCount: numberField(row, "boundary_count", label)->Belt.Float.toInt,
    confidence: numberField(row, "confidence", label),
  }
  if value.coverage < Kuku_LocalWordAlign.minOverallCoverage ||
     value.observedPrecision < Kuku_LocalWordAlign.minObservedPrecision ||
     value.meanSimilarity < Kuku_LocalWordAlign.minMeanSimilarity ||
     value.sequenceScore < Kuku_LocalWordAlign.minSequenceScore ||
     (value.averageTokenProbability >= 0.0 &&
      value.averageTokenProbability < Kuku_LocalWordAlign.minAverageTokenProbability) ||
     value.confidence < 0.0 || value.confidence > 1.0 {
    fail(label ++ " no longer passes unchanged confidence gates")
  }
  value
}

let parseVakyanshRaw = (
  need: alignmentNeed,
  context: vakyanshContext,
  rawPath: string,
  raw: string,
  ~expectedWavSha256: option<string>,
): vakyanshResult => {
  let root = raw->Js.Json.parseExn->jsonObject("Vakyansh cache " ++ need.chunk.id)
  let jobBody = vakyanshJobJson(need, context)
  if stringField(root, "schema", "Vakyansh cache") != "metaphrand-vakyansh-alignment-v1" ||
     stringField(root, "tool_version", "Vakyansh cache") != context.toolVersion ||
     stringField(root, "job_schema", "Vakyansh cache") != "metaphrand-vakyansh-job-v1" ||
     stringField(root, "job_sha256", "Vakyansh cache") != sha256Text(jobBody) ||
     stringField(root, "chunk_id", "Vakyansh cache") != need.chunk.id ||
     stringField(root, "source_audio", "Vakyansh cache") != need.take.path ||
     stringField(root, "source_sha256", "Vakyansh cache") != need.sourceSha256 ||
     stringField(root, "transcript_sha256", "Vakyansh cache") != need.transcriptSha256 ||
     stringField(root, "source_plan_sha256", "Vakyansh cache") != approvedPlanSha256 ||
     stringField(root, "source_manifest_sha256", "Vakyansh cache") != approvedSourceManifestSha256 ||
     stringField(root, "tool_sha256", "Vakyansh cache") != context.toolSha256 ||
     stringField(root, "model_sha256", "Vakyansh cache") != context.modelSha256 ||
     stringField(root, "vocab_sha256", "Vakyansh cache") != context.vocabSha256 ||
     stringField(root, "config", "Vakyansh cache") != vakyanshConfig ||
     stringField(root, "license", "Vakyansh cache") != "MIT" ||
     stringField(root, "torch_version", "Vakyansh cache") != "2.8.0" ||
     stringField(root, "torchaudio_version", "Vakyansh cache") != "2.8.0" ||
     stringField(root, "quantized_engine", "Vakyansh cache") != "qnnpack" {
    fail("Vakyansh cache identity mismatch for " ++ need.chunk.id)
  }
  let wavSha = stringField(root, "normalized_wav_sha256", "Vakyansh cache")
  if Js.String2.length(wavSha) != 64 ||
     (switch expectedWavSha256 {
      | Some(expected) => expected != wavSha
      | None => false
      }) {
    fail("normalized WAV identity mismatch for " ++ need.chunk.id)
  }
  if numberField(root, "sample_rate", "Vakyansh cache") != 16000.0 ||
     numberField(root, "emission_classes", "Vakyansh cache") != 67.0 ||
     numberField(root, "blank_token_id", "Vakyansh cache") != 0.0 ||
     numberField(root, "separator_token_id", "Vakyansh cache") != 4.0 ||
     abs_float(numberField(root, "duration_seconds", "Vakyansh cache") -. need.take.duration) > 0.12 {
    fail("Vakyansh acoustic contract mismatch for " ++ need.chunk.id)
  }
  let observed: array<Kuku_LocalWordAlign.timedWord> =
    arrayField(root, "observed_for_rescript", "Vakyansh cache")->Belt.Array.map(json => {
      let row = jsonObject(json, "Vakyansh word")
      ({
        text: stringField(row, "text", "Vakyansh word"),
        start: numberField(row, "start", "Vakyansh word"),
        end_: numberField(row, "end", "Vakyansh word"),
        probability: numberField(row, "probability", "Vakyansh word"),
      }: Kuku_LocalWordAlign.timedWord)
    })
  let previousStart = ref(-1.0)
  observed->Belt.Array.forEach(word => {
    if !Js.Float.isFinite(word.start) || !Js.Float.isFinite(word.end_) ||
       !Js.Float.isFinite(word.probability) || word.start +. 0.001 < previousStart.contents ||
       word.end_ < word.start || word.end_ > need.take.duration +. 0.12 ||
       word.probability < 0.0 || word.probability > 1.0 {
      fail("invalid Vakyansh word evidence for " ++ need.chunk.id)
    }
    previousStart := word.start
  })
  let known: array<Kuku_LocalWordAlign.knownSegment> = need.chunk.segments->Belt.Array.map(
    segment => ({order: segment.order, text: spokenText(segment)}: Kuku_LocalWordAlign.knownSegment),
  )
  let derived = try Kuku_LocalWordAlign.derive(known, observed, localSilenceGaps(need.take)) catch {
  | Kuku_LocalWordAlign.LocalWordAlignment(message) =>
    fail(need.chunk.id ++ " Vakyansh evidence rejected: " ++ message)
  }
  let segmentRows = arrayField(root, "segments", "Vakyansh cache")
  if Belt.Array.length(segmentRows) != Belt.Array.length(need.chunk.segments) ||
     Belt.Array.length(derived.blocks) != Belt.Array.length(need.chunk.segments) {
    fail("Vakyansh segment count mismatch for " ++ need.chunk.id)
  }
  segmentRows->Belt.Array.forEachWithIndex((index, json) => {
    let row = jsonObject(json, "Vakyansh segment")
    let expected = Belt.Array.getExn(need.chunk.segments, index)
    let block = Belt.Array.getExn(derived.blocks, index)
    let start = numberField(row, "start", "Vakyansh segment")
    let end_ = numberField(row, "end", "Vakyansh segment")
    if numberField(row, "order", "Vakyansh segment")->Belt.Float.toInt != expected.order ||
       stringField(row, "text", "Vakyansh segment") != spokenText(expected) ||
       abs_float(start -. block.start) > 0.03 || abs_float(end_ -. block.end_) > 0.03 {
      fail("Vakyansh segment projection mismatch for " ++ need.chunk.id)
    }
  })
  {
    blocks: derived.blocks->Belt.Array.map(block => ({
      order: block.order,
      start: block.start,
      end_: block.end_,
    })),
    cachePath: rawPath,
    cacheSha256: sha256Text(raw),
    sourceSha256: need.sourceSha256,
    quality: derived.quality,
  }
}

let cachedVakyansh = (
  need: alignmentNeed,
  context: vakyanshContext,
): option<vakyanshResult> => {
  let path = vakyanshRawPath(need, context)
  exists(Path(path))
    ? Some(parseVakyanshRaw(need, context, path, readText(Path(path)), ~expectedWavSha256=None))
    : None
}

let obtainVakyanshBlockTimings = (
  input: inputs,
  context: vakyanshContext,
): (Js.Dict.t<array<blockTiming>>, Js.Dict.t<vakyanshResult>) => {
  let timings: Js.Dict.t<array<blockTiming>> = Js.Dict.empty()
  let evidence: Js.Dict.t<vakyanshResult> = Js.Dict.empty()
  ensureDirPath(Path(vakyanshRawDir))
  alignmentNeeds(input)->Belt.Array.forEach(need => {
    if sha256File(Path(need.take.path)) != need.sourceSha256 {
      fail("source changed before Vakyansh alignment: " ++ need.chunk.id)
    }
    let value = switch cachedVakyansh(need, context) {
    | Some(value) => value
    | None => {
        let scratch = tempDir("kuku-ep9-vakyansh-")
        let base = pathString(scratch) ++ "/" ++ need.chunk.id
        let wavPath = base ++ ".wav"
        let jobPath = base ++ ".job.json"
        let outputPath = base ++ ".alignment.json"
        pinnedFfmpeg([
          "-nostdin", "-loglevel", "error", "-y", "-i", need.take.path,
          "-vn", "-ac", "1", "-ar", "16000", "-c:a", "pcm_s16le", wavPath,
        ])
        let wavDuration = pinnedProbeDuration(wavPath)
        if abs_float(wavDuration -. need.take.duration) > 0.12 {
          fail("Vakyansh normalized WAV duration drift for " ++ need.chunk.id)
        }
        let jobBody = vakyanshJobJson(need, context)
        writeText(Path(jobPath), jobBody)
        let result = run(
          ~cmd=context.toolPath,
          ~args=[
            "--model", context.modelPath,
            "--vocab", context.vocabPath,
            "--wav", wavPath,
            "--job", jobPath,
            "--output", outputPath,
          ],
        )
        if result.code != 0 || !exists(Path(outputPath)) {
          fail("Vakyansh aligner failed for " ++ need.chunk.id ++ ": " ++ result.stderr)
        }
        if sha256File(Path(need.take.path)) != need.sourceSha256 ||
           sha256File(Path(context.toolPath)) != context.toolSha256 ||
           sha256File(Path(context.modelPath)) != context.modelSha256 ||
           sha256File(Path(context.vocabPath)) != context.vocabSha256 {
          fail("source or local aligner artifacts changed during " ++ need.chunk.id)
        }
        let body = readText(Path(outputPath))
        let rawPath = vakyanshRawPath(need, context)
        let parsed = parseVakyanshRaw(
          need,
          context,
          rawPath,
          body,
          ~expectedWavSha256=Some(sha256File(Path(wavPath))),
        )
        if !writeTextExclusive(Path(rawPath), body) && readText(Path(rawPath)) != body {
          fail("conflicting immutable Vakyansh cache appeared for " ++ need.chunk.id)
        }
        Js.log("VAKYANSH ALIGNED " ++ need.chunk.id ++ " -> " ++ rawPath)
        parsed
      }
    }
    Js.Dict.set(timings, need.chunk.id, value.blocks)
    Js.Dict.set(evidence, need.chunk.id, value)
  })
  (timings, evidence)
}

let vakyanshDryReport = (
  input: inputs,
  ~toolPath: option<string>,
  ~modelPath: option<string>,
  ~vocabPath: option<string>,
  ~whisperModelPath: option<string>,
): dryReport => {
  let needs = alignmentNeeds(input)
  let context = vakyanshContextIfReady(~toolPath, ~modelPath, ~vocabPath, ~whisperModelPath)
  let cachedCount = ref(0)
  let missingAlignmentIds: array<string> = []
  needs->Belt.Array.forEach(need => {
    let cached = switch context {
    | Some(context) => cachedVakyansh(need, context) != None
    | None => false
    }
    if cached {
      cachedCount := cachedCount.contents + 1
    } else {
      let _ = Js.Array2.push(missingAlignmentIds, need.chunk.id)
    }
  })
  let scopedSegments = productionSegments(input)
  let scopedChunks = productionChunks(input)
  let selected = input.segments->Belt.Array.keep(isSelectedProductionSegment)
  {
    alignmentMethod: "local Vakyansh CTC + independent local Whisper (zero provider)",
    alignerStatus: switch context {
    | Some(_) => "ready; approved hashes and versions match"
    | None => "requires VAKYANSH_ALIGNER, VAKYANSH_MODEL, VAKYANSH_VOCAB, and WHISPER_MODEL"
    },
    segmentCount: Belt.Array.length(input.segments),
    chunkCount: Belt.Array.length(input.chunks),
    productionSegmentCount: Belt.Array.length(scopedSegments),
    productionChunkCount: Belt.Array.length(scopedChunks),
    lockedSegmentCount: Belt.Array.length(input.segments) - Belt.Array.length(scopedSegments),
    lockedChunkCount: Belt.Array.length(input.chunks) - Belt.Array.length(scopedChunks),
    selectedCount: Belt.Array.length(selected),
    dialogueCount: selected->Belt.Array.keep(segment => segment.kind == "dialogue")->Belt.Array.length,
    chorusCount: selected->Belt.Array.keep(segment => segment.kind == "chorus")->Belt.Array.length,
    narrationExcluded:
      scopedSegments->Belt.Array.keep(segment => segment.kind == "narration")->Belt.Array.length,
    mimicExcluded:
      scopedSegments->Belt.Array.keep(segment => segment.kind == "mimic")->Belt.Array.length,
    mixedChunkCount: scopedChunks->Belt.Array.keep(isMixedChunk)->Belt.Array.length,
    alignmentChunkCount: Belt.Array.length(needs),
    rawCachedCount: cachedCount.contents,
    cachedAlignmentCount: cachedCount.contents,
    missingAlignmentIds,
  }
}

let remoteBlockTimings = (
  input: inputs,
  alignments: Js.Dict.t<alignment>,
): Js.Dict.t<array<blockTiming>> => {
  let results: Js.Dict.t<array<blockTiming>> = Js.Dict.empty()
  alignmentNeeds(input)->Belt.Array.forEach(need => {
    let aligned = switch Js.Dict.get(alignments, need.chunk.id) {
    | Some(value) => value
    | None => fail("missing cloud alignment for " ++ need.chunk.id)
    }
    Js.Dict.set(results, need.chunk.id, blockTimings(need.transcript, aligned, need.chunk.id))
  })
  results
}

/* A single-line chorus take is already an individual stem. This local path
   remains deliberately limited to one-line pure takes. */
let localPureTimings = (chunk: chunkPlan, take: sourceTake): array<blockTiming> => {
  let count = Belt.Array.length(chunk.segments)
  if count == 1 {
    [{order: Belt.Array.getExn(chunk.segments, 0).order, start: 0.0, end_: take.duration}]
  } else {
    fail("pure multi-line chunk must use forced alignment: " ++ chunk.id)
  }
}

let safeCutRange = (
  rows: array<blockTiming>,
  order: int,
  sourceDuration: float,
  label: string,
): (float, float, blockTiming) => {
  let index = switch Belt.Array.getIndexBy(rows, row => row.order == order) {
  | Some(index) => index
  | None => fail(label ++ " has no timing for segment " ++ Belt.Int.toString(order))
  }
  let current = Belt.Array.getExn(rows, index)
  let lowerBoundary = if index == 0 {
    0.0
  } else {
    let previous = Belt.Array.getExn(rows, index - 1)
    previous.end_ <= current.start
      ? (previous.end_ +. current.start) /. 2.0
      : current.start
  }
  let upperBoundary = if index == Belt.Array.length(rows) - 1 {
    sourceDuration
  } else {
    let next = Belt.Array.getExn(rows, index + 1)
    next.start >= current.end_
      ? (current.end_ +. next.start) /. 2.0
      : current.end_
  }
  let start = max(lowerBoundary, current.start -. preHandleSeconds)
  let end_ = min(upperBoundary, min(sourceDuration, current.end_ +. postHandleSeconds))
  if start < 0.0 || end_ <= start || end_ > sourceDuration +. 0.01 {
    fail(label ++ " produced an unsafe cut for segment " ++ Belt.Int.toString(order))
  }
  (start, end_, current)
}

let pad3 = (number: int): string => {
  let value = Belt.Int.toString(number)
  switch Js.String2.length(value) {
  | 1 => "00" ++ value
  | 2 => "0" ++ value
  | _ => value
  }
}

let stemPathFor = (
  segment: segment,
  start: float,
  end_: float,
  ~sourceSha256: string,
  ~candidateMp3Sha256: string,
): string => {
  let signature =
    pipelineVersion ++ "|" ++ sourceSha256 ++ "|" ++
    Js.Float.toString(start) ++ "|" ++ Js.Float.toString(end_) ++ "|" ++
    Belt.Int.toString(segment.order) ++ "|" ++ segment.kind ++ "|" ++ segment.speaker ++ "|" ++
    candidateMp3Sha256
  stemDir ++ "/" ++ pad3(segment.order) ++ "_" ++ segment.kind ++ "_" ++
  segment.speaker ++ "_" ++ sha256Text(signature) ++ ".mp3"
}

let ctcIdentityFor = (
  evidence: Js.Dict.t<vakyanshResult>,
  chunk: chunkPlan,
  take: sourceTake,
): string => {
  if requiresAlignment(chunk) {
    switch Js.Dict.get(evidence, chunk.id) {
    | Some(value) => value.cacheSha256
    | None => fail("missing Vakyansh evidence identity for " ++ chunk.id)
    }
  } else {
    "isolated-whole-take|" ++ sha256File(Path(take.path))
  }
}

let validationSignature = (
  prepared: preparedStem,
  context: vakyanshContext,
  ctcIdentity: string,
): string =>
  pipelineVersion ++ "|" ++ Kuku_LocalWordAlign.algorithmVersion ++ "|" ++
  stemWhisperConfig ++ "|" ++ context.whisperVersion ++ "|" ++
  approvedWhisperBinarySha256 ++ "|" ++ context.whisperModelSha256 ++ "|" ++
  approvedFfmpegSha256 ++ "|" ++ approvedFfprobeSha256 ++ "|" ++
  approvedSourceIdentitiesSha256 ++ "|" ++ prepared.row.take.path ++ "|" ++
  prepared.row.sourceSha256 ++ "|" ++ Js.Float.toString(prepared.row.sourceStart) ++
  "|" ++ Js.Float.toString(prepared.row.sourceEnd) ++ "|" ++
  sha256Text(spokenText(prepared.row.segment)) ++ "|" ++ ctcIdentity ++ "|" ++
  prepared.temporaryWavSha256 ++ "|" ++ prepared.temporaryMp3Sha256

let stemValidationRawPath = (
  prepared: preparedStem,
  context: vakyanshContext,
  ctcIdentity: string,
): string => {
  let signature = validationSignature(prepared, context, ctcIdentity)
  stemValidationRawDir ++ "/" ++ pad3(prepared.row.segment.order) ++ "_" ++
  sha256Text(signature) ++ ".whisper.json"
}

let stemValidationDerivedPath = (
  prepared: preparedStem,
  context: vakyanshContext,
  ctcIdentity: string,
  rawSha256: string,
): string => {
  let signature = validationSignature(prepared, context, ctcIdentity) ++ "|" ++ rawSha256
  stemValidationDerivedDir ++ "/" ++ pad3(prepared.row.segment.order) ++ "_" ++
  sha256Text(signature) ++ ".json"
}

let stemValidationJson = (
  prepared: preparedStem,
  context: vakyanshContext,
  ctcIdentity: string,
  rawPath: string,
  rawSha256: string,
  quality: Kuku_LocalWordAlign.quality,
): string => {
  let root = Js.Dict.empty()
  Js.Dict.set(root, "pipeline_version", Js.Json.string(pipelineVersion))
  Js.Dict.set(root, "algorithm_version", Js.Json.string(Kuku_LocalWordAlign.algorithmVersion))
  Js.Dict.set(root, "validation_method", Js.Json.string("independent-local-whisper-no-prompt"))
  Js.Dict.set(root, "validation_config", Js.Json.string(stemWhisperConfig))
  Js.Dict.set(root, "whisper_version", Js.Json.string(context.whisperVersion))
  Js.Dict.set(root, "whisper_binary_sha256", Js.Json.string(approvedWhisperBinarySha256))
  Js.Dict.set(root, "whisper_model_sha256", Js.Json.string(context.whisperModelSha256))
  Js.Dict.set(root, "ffmpeg_sha256", Js.Json.string(approvedFfmpegSha256))
  Js.Dict.set(root, "ffprobe_sha256", Js.Json.string(approvedFfprobeSha256))
  Js.Dict.set(root, "approved_source_inventory_sha256", Js.Json.string(
    approvedSourceIdentitiesSha256,
  ))
  Js.Dict.set(root, "order", Js.Json.number(Belt.Int.toFloat(prepared.row.segment.order)))
  Js.Dict.set(root, "chunk_id", Js.Json.string(prepared.row.chunk.id))
  Js.Dict.set(root, "source_audio", Js.Json.string(prepared.row.take.path))
  Js.Dict.set(root, "source_sha256", Js.Json.string(prepared.row.sourceSha256))
  Js.Dict.set(root, "source_start", Js.Json.number(prepared.row.sourceStart))
  Js.Dict.set(root, "source_end", Js.Json.number(prepared.row.sourceEnd))
  Js.Dict.set(root, "expected_text", Js.Json.string(spokenText(prepared.row.segment)))
  Js.Dict.set(root, "expected_text_sha256", Js.Json.string(sha256Text(spokenText(prepared.row.segment))))
  Js.Dict.set(root, "ctc_evidence_identity", Js.Json.string(ctcIdentity))
  Js.Dict.set(root, "candidate_wav_sha256", Js.Json.string(prepared.temporaryWavSha256))
  Js.Dict.set(root, "candidate_mp3_sha256", Js.Json.string(prepared.temporaryMp3Sha256))
  Js.Dict.set(root, "raw_whisper_json", Js.Json.string(rawPath))
  Js.Dict.set(root, "raw_whisper_sha256", Js.Json.string(rawSha256))
  Js.Dict.set(root, "quality", qualityJson(quality))
  Js.Json.object_(root)->Js.Json.stringifyWithSpace(1)
}

let parseStemValidation = (
  prepared: preparedStem,
  context: vakyanshContext,
  ctcIdentity: string,
  rawPath: string,
  rawSha256: string,
  derivedPath: string,
  body: string,
): stemValidation => {
  let root = body->Js.Json.parseExn->jsonObject(
    "stem validation " ++ Belt.Int.toString(prepared.row.segment.order),
  )
  if stringField(root, "pipeline_version", "stem validation") != pipelineVersion ||
     stringField(root, "algorithm_version", "stem validation") != Kuku_LocalWordAlign.algorithmVersion ||
     stringField(root, "validation_method", "stem validation") !=
       "independent-local-whisper-no-prompt" ||
     stringField(root, "validation_config", "stem validation") != stemWhisperConfig ||
     stringField(root, "whisper_version", "stem validation") != context.whisperVersion ||
     stringField(root, "whisper_binary_sha256", "stem validation") != approvedWhisperBinarySha256 ||
     stringField(root, "whisper_model_sha256", "stem validation") != context.whisperModelSha256 ||
     stringField(root, "ffmpeg_sha256", "stem validation") != approvedFfmpegSha256 ||
     stringField(root, "ffprobe_sha256", "stem validation") != approvedFfprobeSha256 ||
     stringField(root, "approved_source_inventory_sha256", "stem validation") !=
       approvedSourceIdentitiesSha256 ||
     numberField(root, "order", "stem validation")->Belt.Float.toInt != prepared.row.segment.order ||
     stringField(root, "chunk_id", "stem validation") != prepared.row.chunk.id ||
     stringField(root, "source_audio", "stem validation") != prepared.row.take.path ||
     stringField(root, "source_sha256", "stem validation") != prepared.row.sourceSha256 ||
     abs_float(numberField(root, "source_start", "stem validation") -. prepared.row.sourceStart) > 0.000001 ||
     abs_float(numberField(root, "source_end", "stem validation") -. prepared.row.sourceEnd) > 0.000001 ||
     stringField(root, "expected_text", "stem validation") != spokenText(prepared.row.segment) ||
     stringField(root, "expected_text_sha256", "stem validation") !=
       sha256Text(spokenText(prepared.row.segment)) ||
     stringField(root, "ctc_evidence_identity", "stem validation") != ctcIdentity ||
     stringField(root, "candidate_wav_sha256", "stem validation") != prepared.temporaryWavSha256 ||
     stringField(root, "candidate_mp3_sha256", "stem validation") != prepared.temporaryMp3Sha256 ||
     stringField(root, "raw_whisper_json", "stem validation") != rawPath ||
     stringField(root, "raw_whisper_sha256", "stem validation") != rawSha256 {
    fail("stem validation identity mismatch at order " ++ Belt.Int.toString(prepared.row.segment.order))
  }
  let quality = switch field(root, "quality") {
  | Some(value) => parseQuality(value, "stem validation quality")
  | None => fail("stem validation has no quality")
  }
  {
    rawPath,
    rawSha256,
    derivedPath,
    derivedSha256: sha256Text(body),
    candidateMp3Sha256: prepared.temporaryMp3Sha256,
    candidateWavSha256: prepared.temporaryWavSha256,
    quality,
  }
}

let cachedStemValidation = (
  prepared: preparedStem,
  context: vakyanshContext,
  ctcIdentity: string,
): option<stemValidation> => {
  let rawPath = stemValidationRawPath(prepared, context, ctcIdentity)
  if !exists(Path(rawPath)) {
    None
  } else {
    let raw = readText(Path(rawPath))
    let rawSha256 = sha256File(Path(rawPath))
    let derivedPath = stemValidationDerivedPath(prepared, context, ctcIdentity, rawSha256)
    if !exists(Path(derivedPath)) {
      None
    } else {
      let observed = Kuku_LocalWordAlign.parseWhisperJson(raw)
      let known: array<Kuku_LocalWordAlign.knownSegment> = [{
        order: prepared.row.segment.order,
        text: spokenText(prepared.row.segment),
      }]
      let rederived = Kuku_LocalWordAlign.derive(known, observed, [])
      let expectedBody = stemValidationJson(
        prepared,
        context,
        ctcIdentity,
        rawPath,
        rawSha256,
        rederived.quality,
      )
      let actualBody = readText(Path(derivedPath))
      if actualBody != expectedBody {
        fail(
          "derived validation cache does not match independently re-derived raw evidence at order " ++
          Belt.Int.toString(prepared.row.segment.order),
        )
      }
      Some(parseStemValidation(
        prepared,
        context,
        ctcIdentity,
        rawPath,
        rawSha256,
        derivedPath,
        actualBody,
      ))
    }
  }
}

/* Re-open and independently validate every byte that authorizes publication.
   This is deliberately stronger than trusting the in-memory records gathered
   earlier in the run: CTC caches are parsed again, Whisper results are derived
   again from raw JSON, and every pinned inventory/tool/source/candidate is
   rehashed. */
let verifyReleaseEvidence = (
  input: inputs,
  prepared: array<preparedStem>,
  stems: array<stemRow>,
  context: vakyanshContext,
  evidence: Js.Dict.t<vakyanshResult>,
): unit => {
  if Belt.Array.length(prepared) != expectedProductionStemCount ||
     Belt.Array.length(stems) != expectedProductionStemCount ||
     Js.Dict.keys(evidence)->Belt.Array.length != 18 {
    fail("release evidence is incomplete")
  }
  validateInputs(input)
  verifyVakyanshAudit()
  assertExactFile("Vakyansh aligner", context.toolPath, context.toolSha256)
  assertExactFile("Vakyansh model", context.modelPath, context.modelSha256)
  assertExactFile("Vakyansh vocabulary", context.vocabPath, context.vocabSha256)
  assertExactFile("whisper-cli", whisperBinary, approvedWhisperBinarySha256)
  assertExactFile("Whisper model", context.whisperModelPath, context.whisperModelSha256)

  alignmentNeeds(input)->Belt.Array.forEach(need => {
    let expected = switch Js.Dict.get(evidence, need.chunk.id) {
    | Some(value) => value
    | None => fail("missing in-memory CTC evidence for " ++ need.chunk.id)
    }
    let current = switch cachedVakyansh(need, context) {
    | Some(value) => value
    | None => fail("CTC evidence disappeared for " ++ need.chunk.id)
    }
    if current.cachePath != expected.cachePath ||
       current.cacheSha256 != expected.cacheSha256 ||
       current.sourceSha256 != expected.sourceSha256 {
      fail("CTC evidence changed after acceptance for " ++ need.chunk.id)
    }
    assertExactFile("CTC evidence " ++ need.chunk.id, current.cachePath, current.cacheSha256)
  })

  stems->Belt.Array.forEach(row => {
    let order = row.segment.order
    let staged = switch Belt.Array.getBy(prepared, item => item.row.segment.order == order) {
    | Some(value) => value
    | None => fail("missing staged candidate for accepted order " ++ Belt.Int.toString(order))
    }
    if staged.row.chunk.id != row.chunk.id ||
       staged.row.sourceStart != row.sourceStart ||
       staged.row.sourceEnd != row.sourceEnd ||
       staged.row.sourceSha256 != row.sourceSha256 {
      fail("accepted row no longer matches staged candidate at order " ++ Belt.Int.toString(order))
    }
    assertExactFile("approved source at order " ++ Belt.Int.toString(order), row.take.path, row.sourceSha256)
    assertExactFile(
      "staged MP3 at order " ++ Belt.Int.toString(order),
      staged.temporaryMp3,
      staged.temporaryMp3Sha256,
    )
    assertExactFile(
      "validation WAV at order " ++ Belt.Int.toString(order),
      staged.temporaryWav,
      staged.temporaryWavSha256,
    )
    let ctcIdentity = ctcIdentityFor(evidence, row.chunk, row.take)
    let expectedValidation = switch row.validation {
    | Some(value) => value
    | None => fail("accepted row lacks validation at order " ++ Belt.Int.toString(order))
    }
    let currentValidation = switch cachedStemValidation(staged, context, ctcIdentity) {
    | Some(value) => value
    | None => fail("validation evidence disappeared at order " ++ Belt.Int.toString(order))
    }
    if currentValidation.rawPath != expectedValidation.rawPath ||
       currentValidation.rawSha256 != expectedValidation.rawSha256 ||
       currentValidation.derivedPath != expectedValidation.derivedPath ||
       currentValidation.derivedSha256 != expectedValidation.derivedSha256 ||
       currentValidation.candidateMp3Sha256 != expectedValidation.candidateMp3Sha256 ||
       currentValidation.candidateWavSha256 != expectedValidation.candidateWavSha256 {
      fail("validation evidence changed after acceptance at order " ++ Belt.Int.toString(order))
    }
    assertExactFile(
      "raw Whisper evidence at order " ++ Belt.Int.toString(order),
      currentValidation.rawPath,
      currentValidation.rawSha256,
    )
    assertExactFile(
      "derived Whisper evidence at order " ++ Belt.Int.toString(order),
      currentValidation.derivedPath,
      currentValidation.derivedSha256,
    )
    let expectedPath = stemPathFor(
      row.segment,
      row.sourceStart,
      row.sourceEnd,
      ~sourceSha256=row.sourceSha256,
      ~candidateMp3Sha256=expectedValidation.candidateMp3Sha256,
    )
    if row.path != expectedPath {
      fail("accepted stem path is not content-bound at order " ++ Belt.Int.toString(order))
    }
    if exists(Path(row.path)) {
      assertExactFile(
        "published stem at order " ++ Belt.Int.toString(order),
        row.path,
        expectedValidation.candidateMp3Sha256,
      )
    }
  })

  /* Catch artifacts replaced while the preceding evidence set was inspected. */
  assertExactFile(
    "approved production-source identity inventory",
    approvedSourceIdentitiesPath,
    approvedSourceIdentitiesSha256,
  )
  assertExactFile("raw-provider inventory", rawProviderInventoryPath, rawProviderInventorySha256)
  assertExactFile(
    "timing-equivalence inventory",
    timingEquivalenceInventoryPath,
    timingEquivalenceInventorySha256,
  )
  assertExactFile("Vakyansh aligner", context.toolPath, context.toolSha256)
  assertExactFile("Vakyansh model", context.modelPath, context.modelSha256)
  assertExactFile("Vakyansh vocabulary", context.vocabPath, context.vocabSha256)
  assertExactFile("whisper-cli", whisperBinary, approvedWhisperBinarySha256)
  assertExactFile("Whisper model", context.whisperModelPath, context.whisperModelSha256)
  alignmentNeeds(input)->Belt.Array.forEach(need => {
    let value = Js.Dict.get(evidence, need.chunk.id)->Belt.Option.getExn
    assertExactFile("final CTC evidence " ++ need.chunk.id, value.cachePath, value.cacheSha256)
  })
  stems->Belt.Array.forEach(row => {
    let staged = Belt.Array.getBy(prepared, item => item.row.segment.order == row.segment.order)
      ->Belt.Option.getExn
    let validation = row.validation->Belt.Option.getExn
    assertExactFile(
      "final approved source at order " ++ Belt.Int.toString(row.segment.order),
      row.take.path,
      row.sourceSha256,
    )
    assertExactFile(
      "final staged MP3 at order " ++ Belt.Int.toString(row.segment.order),
      staged.temporaryMp3,
      validation.candidateMp3Sha256,
    )
    assertExactFile(
      "final validation WAV at order " ++ Belt.Int.toString(row.segment.order),
      staged.temporaryWav,
      validation.candidateWavSha256,
    )
    assertExactFile(
      "final raw Whisper evidence at order " ++ Belt.Int.toString(row.segment.order),
      validation.rawPath,
      validation.rawSha256,
    )
    assertExactFile(
      "final derived Whisper evidence at order " ++ Belt.Int.toString(row.segment.order),
      validation.derivedPath,
      validation.derivedSha256,
    )
    if exists(Path(row.path)) {
      assertExactFile(
        "final published stem at order " ++ Belt.Int.toString(row.segment.order),
        row.path,
        validation.candidateMp3Sha256,
      )
    }
  })
}

let prepareStems = (
  input: inputs,
  timingsByChunk: Js.Dict.t<array<blockTiming>>,
  evidence: Js.Dict.t<vakyanshResult>,
  scratch: string,
): array<preparedStem> => {
  let prepared: array<preparedStem> = []
  productionChunks(input)->Belt.Array.forEach(chunk => {
    let selected = chunk.segments->Belt.Array.keep(segment => isSelectedKind(segment.kind))
    if Belt.Array.length(selected) > 0 {
      let take = takeForChunk(input.takes, chunk.id)
      let expectedSourceSha256 = if requiresAlignment(chunk) {
        switch Js.Dict.get(evidence, chunk.id) {
        | Some(value) => value.sourceSha256
        | None => fail("missing source identity for " ++ chunk.id)
        }
      } else {
        approvedSourceFor(input, chunk.id).sha256
      }
      let rows = if requiresAlignment(chunk) {
        switch Js.Dict.get(timingsByChunk, chunk.id) {
        | Some(value) => value
        | None => fail("missing loaded Vakyansh timings for " ++ chunk.id)
        }
      } else {
        localPureTimings(chunk, take)
      }
      selected->Belt.Array.forEach(segment => {
        if sha256File(Path(take.path)) != expectedSourceSha256 {
          fail("approved source changed while preparing " ++ chunk.id)
        }
        let (sourceStart, sourceEnd, speech) = safeCutRange(
          rows,
          segment.order,
          take.duration,
          chunk.id,
        )
        let expectedDuration = sourceEnd -. sourceStart
        let base = scratch ++ "/" ++ pad3(segment.order)
        let temporaryWav = base ++ ".wav"
        let temporaryMp3 = base ++ ".mp3"
        /* Encode the exact deliverable first. Whisper validates a PCM decode of
           this MP3, never a parallel cut that merely shares timestamps. */
        pinnedFfmpeg([
          "-nostdin", "-loglevel", "error", "-y", "-i", take.path,
          "-ss", Js.Float.toString(sourceStart), "-t", Js.Float.toString(expectedDuration),
          "-c:a", "libmp3lame", "-q:a", "3", "-ac", "1", temporaryMp3,
        ])
        let temporaryMp3Sha256 = sha256File(Path(temporaryMp3))
        pinnedFfmpeg([
          "-nostdin", "-loglevel", "error", "-y", "-i", temporaryMp3,
          "-vn", "-ac", "1", "-ar", "16000", "-c:a", "pcm_s16le", temporaryWav,
        ])
        let temporaryWavSha256 = sha256File(Path(temporaryWav))
        let wavDuration = pinnedProbeDuration(temporaryWav)
        let mp3Duration = pinnedProbeDuration(temporaryMp3)
        if abs_float(wavDuration -. expectedDuration) > 0.12 ||
           abs_float(mp3Duration -. expectedDuration) > 0.12 ||
           sha256File(Path(temporaryMp3)) != temporaryMp3Sha256 ||
           sha256File(Path(temporaryWav)) != temporaryWavSha256 ||
           sha256File(Path(take.path)) != expectedSourceSha256 {
          fail("candidate duration/source drift for order " ++ Belt.Int.toString(segment.order))
        }
        let _ = Js.Array2.push(prepared, {
          row: {
            segment,
            chunk,
            take,
            sourceSha256: expectedSourceSha256,
            sourceStart,
            sourceEnd,
            speechStart: speech.start,
            speechEnd: speech.end_,
            path: stemPathFor(
              segment,
              sourceStart,
              sourceEnd,
              ~sourceSha256=expectedSourceSha256,
              ~candidateMp3Sha256=temporaryMp3Sha256,
            ),
            duration: mp3Duration,
            validation: None,
          },
          temporaryMp3,
          temporaryMp3Sha256,
          temporaryWav,
          temporaryWavSha256,
        })
      })
    }
  })
  if Belt.Array.length(prepared) != expectedProductionStemCount {
    fail("prepared stem count changed")
  }
  prepared
}

let deriveStemValidation = (
  prepared: preparedStem,
  context: vakyanshContext,
  ctcIdentity: string,
  rawPath: string,
  raw: string,
): stemValidation => {
  let observed = Kuku_LocalWordAlign.parseWhisperJson(raw)
  let known: array<Kuku_LocalWordAlign.knownSegment> = [{
    order: prepared.row.segment.order,
    text: spokenText(prepared.row.segment),
  }]
  let derived = Kuku_LocalWordAlign.derive(known, observed, [])
  if Belt.Array.length(derived.blocks) != 1 ||
     Belt.Array.getExn(derived.blocks, 0).order != prepared.row.segment.order {
    fail("independent Whisper returned the wrong line order")
  }
  let rawSha256 = sha256Text(raw)
  let derivedPath = stemValidationDerivedPath(prepared, context, ctcIdentity, rawSha256)
  let body = stemValidationJson(
    prepared,
    context,
    ctcIdentity,
    rawPath,
    rawSha256,
    derived.quality,
  )
  let parsed = parseStemValidation(
    prepared,
    context,
    ctcIdentity,
    rawPath,
    rawSha256,
    derivedPath,
    body,
  )
  ensureDirPath(Path(stemValidationDerivedDir))
  if !writeTextExclusive(Path(derivedPath), body) && readText(Path(derivedPath)) != body {
    fail("conflicting immutable validation cache at order " ++ Belt.Int.toString(prepared.row.segment.order))
  }
  parsed
}

let runWhisperValidationBatch = (
  batch: array<preparedStem>,
  context: vakyanshContext,
): unit => {
  if Belt.Array.length(batch) > 0 {
    assertExactFile("whisper-cli", whisperBinary, approvedWhisperBinarySha256)
    assertExactFile("Whisper model", context.whisperModelPath, context.whisperModelSha256)
    batch->Belt.Array.forEach(prepared => {
      if sha256File(Path(prepared.row.take.path)) != prepared.row.sourceSha256 ||
         sha256File(Path(prepared.temporaryMp3)) != prepared.temporaryMp3Sha256 ||
         sha256File(Path(prepared.temporaryWav)) != prepared.temporaryWavSha256 {
        fail("validation input changed before Whisper at order " ++ Belt.Int.toString(
          prepared.row.segment.order,
        ))
      }
    })
    let args = [
      "-ng", "-m", context.whisperModelPath,
      "-l", "hi", "-ojf", "-sow", "-np", "-mc", "0",
      "--no-fallback", "--temperature", "0", "--beam-size", "5", "--best-of", "5",
    ]
    batch->Belt.Array.forEach(prepared => {
      let _ = Js.Array2.push(args, prepared.temporaryWav)
    })
    let result = run(~cmd=whisperBinary, ~args)
    assertExactFile("whisper-cli", whisperBinary, approvedWhisperBinarySha256)
    assertExactFile("Whisper model", context.whisperModelPath, context.whisperModelSha256)
    if result.code != 0 {
      fail("independent local Whisper batch failed: " ++ result.stderr)
    }
    batch->Belt.Array.forEach(prepared => {
      if sha256File(Path(prepared.row.take.path)) != prepared.row.sourceSha256 ||
         sha256File(Path(prepared.temporaryMp3)) != prepared.temporaryMp3Sha256 ||
         sha256File(Path(prepared.temporaryWav)) != prepared.temporaryWavSha256 {
        fail("validation input changed during Whisper at order " ++ Belt.Int.toString(
          prepared.row.segment.order,
        ))
      }
      if !exists(Path(prepared.temporaryWav ++ ".json")) {
        fail("Whisper produced no JSON for order " ++ Belt.Int.toString(prepared.row.segment.order))
      }
    })
  }
}

let validatePreparedStems = (
  prepared: array<preparedStem>,
  context: vakyanshContext,
  evidence: Js.Dict.t<vakyanshResult>,
): (array<stemRow>, array<validationException>) => {
  let accepted: array<stemRow> = []
  let exceptions: array<validationException> = []
  let pending: array<preparedStem> = []
  prepared->Belt.Array.forEach(item => {
    let ctcIdentity = ctcIdentityFor(evidence, item.row.chunk, item.row.take)
    switch cachedStemValidation(item, context, ctcIdentity) {
    | Some(validation) => {
        let _ = Js.Array2.push(accepted, {...item.row, validation: Some(validation)})
    }
    | None => {
        let rawPath = stemValidationRawPath(item, context, ctcIdentity)
        if exists(Path(rawPath)) {
          /* A raw cache without a derived cache is normally a prior strict
             rejection. Re-evaluate those exact bytes instead of rerunning a
             nondeterministic recognizer and then conflicting with immutable
             evidence. */
          if sha256File(Path(item.row.take.path)) != item.row.sourceSha256 ||
             sha256File(Path(item.temporaryMp3)) != item.temporaryMp3Sha256 ||
             sha256File(Path(item.temporaryWav)) != item.temporaryWavSha256 ||
             sha256File(Path(context.whisperModelPath)) != context.whisperModelSha256 ||
             sha256File(Path(whisperBinary)) != approvedWhisperBinarySha256 {
            fail("cached validation inputs changed at order " ++ Belt.Int.toString(
              item.row.segment.order,
            ))
          }
          let raw = readText(Path(rawPath))
          try {
            let validation = deriveStemValidation(item, context, ctcIdentity, rawPath, raw)
            let _ = Js.Array2.push(accepted, {...item.row, validation: Some(validation)})
          } catch {
          | Kuku_LocalWordAlign.LocalWordAlignment(message) => {
              let _ = Js.Array2.push(exceptions, {
                prepared: item,
                reason: message,
                rawPath: Some(rawPath),
              })
            }
          }
        } else {
          let _ = Js.Array2.push(pending, item)
        }
      }
    }
  })
  let batchSize = 32
  let cursor = ref(0)
  while cursor.contents < Belt.Array.length(pending) {
    let stop = min(Belt.Array.length(pending), cursor.contents + batchSize)
    let batch = Js.Array2.slice(pending, ~start=cursor.contents, ~end_=stop)
    Js.log(
      "WHISPER VALIDATION BATCH " ++ Belt.Int.toString(cursor.contents + 1) ++ "-" ++
      Belt.Int.toString(stop) ++ " / " ++ Belt.Int.toString(Belt.Array.length(pending)),
    )
    runWhisperValidationBatch(batch, context)
    batch->Belt.Array.forEach(item => {
      if sha256File(Path(item.row.take.path)) != item.row.sourceSha256 ||
         sha256File(Path(item.temporaryMp3)) != item.temporaryMp3Sha256 ||
         sha256File(Path(item.temporaryWav)) != item.temporaryWavSha256 ||
         sha256File(Path(context.whisperModelPath)) != context.whisperModelSha256 ||
         sha256File(Path(whisperBinary)) != approvedWhisperBinarySha256 {
        fail("validation evidence changed before cache publication at order " ++ Belt.Int.toString(
          item.row.segment.order,
        ))
      }
      let ctcIdentity = ctcIdentityFor(evidence, item.row.chunk, item.row.take)
      let generatedRaw = item.temporaryWav ++ ".json"
      let raw = readText(Path(generatedRaw))
      let rawPath = stemValidationRawPath(item, context, ctcIdentity)
      ensureDirPath(Path(stemValidationRawDir))
      if !writeTextExclusive(Path(rawPath), raw) && readText(Path(rawPath)) != raw {
        fail("conflicting immutable Whisper JSON at order " ++ Belt.Int.toString(item.row.segment.order))
      }
      try {
        let validation = deriveStemValidation(item, context, ctcIdentity, rawPath, raw)
        let _ = Js.Array2.push(accepted, {...item.row, validation: Some(validation)})
      } catch {
      | Kuku_LocalWordAlign.LocalWordAlignment(message) => {
          let _ = Js.Array2.push(exceptions, {
            prepared: item,
            reason: message,
            rawPath: Some(rawPath),
          })
        }
      }
    })
    cursor := stop
  }
  accepted->Js.Array2.sortInPlaceWith((left, right) => left.segment.order - right.segment.order)->ignore
  (accepted, exceptions)
}

let publishManualReview = (
  exceptions: array<validationException>,
  context: vakyanshContext,
  evidence: Js.Dict.t<vakyanshResult>,
): unit => {
  if Belt.Array.length(exceptions) > 0 {
    ensureDirPath(Path(manualReviewDir))
    let rows = exceptions->Belt.Array.map(exception_ => {
      let order = exception_.prepared.row.segment.order
      let destination = manualReviewDir ++ "/" ++ pad3(order) ++ "_" ++
        sha256Text(validationSignature(
          exception_.prepared,
          context,
          "manual-review",
        )) ++ ".mp3"
      let candidateSha256 = exception_.prepared.temporaryMp3Sha256
      if sha256File(Path(exception_.prepared.temporaryMp3)) != candidateSha256 {
        fail("manual-review candidate changed at order " ++ Belt.Int.toString(order))
      }
      if !publishFileExclusive(Path(exception_.prepared.temporaryMp3), Path(destination)) &&
         sha256File(Path(destination)) != candidateSha256 {
        fail("conflicting manual-review candidate at order " ++ Belt.Int.toString(order))
      }
      let row = Js.Dict.empty()
      Js.Dict.set(row, "order", Js.Json.number(Belt.Int.toFloat(order)))
      Js.Dict.set(row, "scene", Js.Json.number(Belt.Int.toFloat(exception_.prepared.row.segment.scene)))
      Js.Dict.set(row, "speaker", Js.Json.string(exception_.prepared.row.segment.speaker))
      Js.Dict.set(row, "text", Js.Json.string(exception_.prepared.row.segment.text))
      Js.Dict.set(row, "reason", Js.Json.string(exception_.reason))
      Js.Dict.set(row, "candidate", Js.Json.string(destination))
      Js.Dict.set(row, "candidate_sha256", Js.Json.string(candidateSha256))
      Js.Dict.set(row, "candidate_duration_seconds", Js.Json.number(exception_.prepared.row.duration))
      Js.Dict.set(row, "candidate_validation_wav_sha256", Js.Json.string(
        exception_.prepared.temporaryWavSha256,
      ))
      Js.Dict.set(row, "source_audio", Js.Json.string(exception_.prepared.row.take.path))
      Js.Dict.set(row, "source_audio_sha256", Js.Json.string(exception_.prepared.row.sourceSha256))
      Js.Dict.set(row, "source_start_seconds", Js.Json.number(exception_.prepared.row.sourceStart))
      Js.Dict.set(row, "source_end_seconds", Js.Json.number(exception_.prepared.row.sourceEnd))
      Js.Dict.set(row, "ctc_evidence_identity", Js.Json.string(ctcIdentityFor(
        evidence,
        exception_.prepared.row.chunk,
        exception_.prepared.row.take,
      )))
      switch exception_.rawPath {
      | Some(path) => {
          Js.Dict.set(row, "whisper_json", Js.Json.string(path))
          Js.Dict.set(row, "whisper_json_sha256", Js.Json.string(sha256File(Path(path))))
        }
      | None => ()
      }
      Js.Json.object_(row)
    })
    let root = Js.Dict.empty()
    Js.Dict.set(root, "pipeline_version", Js.Json.string(pipelineVersion))
    Js.Dict.set(root, "status", Js.Json.string("manual-review-required"))
    Js.Dict.set(root, "production_authorization", Js.Json.boolean(false))
    Js.Dict.set(
      root,
      "approval_contract",
      Js.Json.string(
        "Candidates remain non-production. Any later approval must identify this manifest, exact candidate SHA-256, source range, CTC evidence, and Whisper evidence.",
      ),
    )
    Js.Dict.set(root, "approved_source_inventory", Js.Json.string(approvedSourceIdentitiesPath))
    Js.Dict.set(root, "approved_source_inventory_sha256", Js.Json.string(approvedSourceIdentitiesSha256))
    Js.Dict.set(root, "whisper_binary_sha256", Js.Json.string(approvedWhisperBinarySha256))
    Js.Dict.set(root, "whisper_model_sha256", Js.Json.string(context.whisperModelSha256))
    Js.Dict.set(root, "whisper_version", Js.Json.string(context.whisperVersion))
    Js.Dict.set(root, "whisper_config", Js.Json.string(stemWhisperConfig))
    Js.Dict.set(root, "exception_count", Js.Json.number(Belt.Int.toFloat(Belt.Array.length(exceptions))))
    Js.Dict.set(root, "exceptions", Js.Json.array(rows))
    let body = Js.Json.object_(root)->Js.Json.stringifyWithSpace(1)
    if !writeTextExclusive(Path(manualReviewManifestPath), body) &&
       readText(Path(manualReviewManifestPath)) != body {
      fail("conflicting manual-review manifest")
    }
  }
}

let publishValidatedStems = (
  prepared: array<preparedStem>,
  accepted: array<stemRow>,
): array<stemRow> => {
  if Belt.Array.length(accepted) != expectedProductionStemCount {
    fail("refusing to publish fewer than 137 independently validated stems")
  }
  ensureDirPath(Path(stemDir))
  accepted->Belt.Array.forEach(row => {
    let staged = switch Belt.Array.getBy(prepared, item => item.row.segment.order == row.segment.order) {
    | Some(value) => value
    | None => fail("missing staged MP3 at order " ++ Belt.Int.toString(row.segment.order))
    }
    if sha256File(Path(row.take.path)) != row.sourceSha256 {
      fail("approved source changed before publishing order " ++ Belt.Int.toString(row.segment.order))
    }
    if sha256File(Path(staged.temporaryMp3)) != staged.temporaryMp3Sha256 ||
       sha256File(Path(staged.temporaryWav)) != staged.temporaryWavSha256 {
      fail("staged candidate changed at order " ++ Belt.Int.toString(row.segment.order))
    }
    switch row.validation {
    | Some(validation)
        if validation.candidateMp3Sha256 == staged.temporaryMp3Sha256 &&
          validation.candidateWavSha256 == staged.temporaryWavSha256 => ()
    | _ => fail("validation does not bind staged bytes at order " ++ Belt.Int.toString(row.segment.order))
    }
  })
  let published = accepted->Belt.Array.map(row => {
    let staged = Belt.Array.getBy(prepared, item => item.row.segment.order == row.segment.order)
      ->Belt.Option.getExn
    if exists(Path(row.path)) {
      if sha256File(Path(row.path)) != staged.temporaryMp3Sha256 {
        fail("existing immutable stem bytes conflict at order " ++ Belt.Int.toString(row.segment.order))
      }
    } else if !publishFileExclusive(Path(staged.temporaryMp3), Path(row.path)) {
      fail("immutable stem appeared during publication at order " ++ Belt.Int.toString(row.segment.order))
    }
    row
  })
  published->Belt.Array.forEach(row => {
    let validation = row.validation->Belt.Option.getExn
    if sha256File(Path(row.path)) != validation.candidateMp3Sha256 {
      fail("published stem changed during batch publication at order " ++ Belt.Int.toString(row.segment.order))
    }
  })
  published
}

let stemJson = (row: stemRow): Js.Json.t => {
  let object_ = Js.Dict.empty()
  Js.Dict.set(object_, "order", Js.Json.number(Belt.Int.toFloat(row.segment.order)))
  Js.Dict.set(object_, "scene", Js.Json.number(Belt.Int.toFloat(row.segment.scene)))
  Js.Dict.set(object_, "kind", Js.Json.string(row.segment.kind))
  Js.Dict.set(object_, "speaker", Js.Json.string(row.segment.speaker))
  Js.Dict.set(object_, "text", Js.Json.string(row.segment.text))
  Js.Dict.set(object_, "source_chunk_id", Js.Json.string(row.chunk.id))
  Js.Dict.set(object_, "source_audio", Js.Json.string(row.take.path))
  if sha256File(Path(row.take.path)) != row.sourceSha256 {
    fail("source changed while writing manifest at order " ++ Belt.Int.toString(row.segment.order))
  }
  Js.Dict.set(object_, "source_audio_sha256", Js.Json.string(row.sourceSha256))
  Js.Dict.set(object_, "source_start_seconds", Js.Json.number(row.sourceStart))
  Js.Dict.set(object_, "source_end_seconds", Js.Json.number(row.sourceEnd))
  Js.Dict.set(object_, "speech_start_seconds", Js.Json.number(row.speechStart))
  Js.Dict.set(object_, "speech_end_seconds", Js.Json.number(row.speechEnd))
  Js.Dict.set(object_, "path", Js.Json.string(row.path))
  Js.Dict.set(object_, "duration_seconds", Js.Json.number(row.duration))
  let outputSha256 = sha256File(Path(row.path))
  switch row.validation {
  | Some(validation) if outputSha256 != validation.candidateMp3Sha256 =>
    fail("published stem no longer matches validated MP3 at order " ++ Belt.Int.toString(row.segment.order))
  | _ => ()
  }
  Js.Dict.set(object_, "sha256", Js.Json.string(outputSha256))
  switch row.validation {
  | Some(validation) => {
      let audit = Js.Dict.empty()
      Js.Dict.set(audit, "method", Js.Json.string("independent-local-whisper-no-prompt"))
      Js.Dict.set(audit, "raw_path", Js.Json.string(validation.rawPath))
      Js.Dict.set(audit, "raw_sha256", Js.Json.string(validation.rawSha256))
      Js.Dict.set(audit, "derived_path", Js.Json.string(validation.derivedPath))
      Js.Dict.set(audit, "derived_sha256", Js.Json.string(validation.derivedSha256))
      Js.Dict.set(audit, "candidate_mp3_sha256", Js.Json.string(validation.candidateMp3Sha256))
      Js.Dict.set(audit, "candidate_validation_wav_sha256", Js.Json.string(validation.candidateWavSha256))
      Js.Dict.set(audit, "quality", qualityJson(validation.quality))
      Js.Dict.set(object_, "independent_validation", Js.Json.object_(audit))
    }
  | None => ()
  }
  Js.Json.object_(object_)
}

let buildManifestBody = (
  input: inputs,
  stems: array<stemRow>,
  mode: alignmentMode,
  ~context: option<vakyanshContext>,
  ~evidence: option<Js.Dict.t<vakyanshResult>>,
): string => {
  if Belt.Array.length(stems) != expectedProductionStemCount {
    fail(
      "refusing incomplete manifest: expected " ++
      Belt.Int.toString(expectedProductionStemCount) ++ " stems",
    )
  }
  stems->Belt.Array.forEachWithIndex((index, row) => {
    if !isProductionScene(row.segment.scene) || isLockedAssetChunkId(row.chunk.id) ||
       !isSelectedKind(row.segment.kind) {
      fail("refusing out-of-scope stem at order " ++ Belt.Int.toString(row.segment.order))
    }
    if index > 0 {
      let previous = Belt.Array.getExn(stems, index - 1)
      if previous.segment.order >= row.segment.order {
        fail("stem rows are not in screenplay order")
      }
    }
    switch row.validation {
    | None => fail("production stem lacks independent validation at order " ++ Belt.Int.toString(row.segment.order))
    | Some(_) => ()
    }
  })
  let root = Js.Dict.empty()
  Js.Dict.set(root, "pipeline_version", Js.Json.string(pipelineVersion))
  Js.Dict.set(root, "source_plan", Js.Json.string(planPath))
  Js.Dict.set(root, "source_plan_sha256", Js.Json.string(approvedPlanSha256))
  Js.Dict.set(root, "source_manifest", Js.Json.string(sourceManifestPath))
  Js.Dict.set(root, "source_manifest_sha256", Js.Json.string(approvedSourceManifestSha256))
  Js.Dict.set(root, "approved_source_inventory", Js.Json.string(approvedSourceIdentitiesPath))
  Js.Dict.set(root, "approved_source_inventory_sha256", Js.Json.string(approvedSourceIdentitiesSha256))
  Js.Dict.set(root, "raw_provider_inventory", Js.Json.string(rawProviderInventoryPath))
  Js.Dict.set(root, "raw_provider_inventory_sha256", Js.Json.string(rawProviderInventorySha256))
  Js.Dict.set(root, "timing_equivalence_inventory", Js.Json.string(timingEquivalenceInventoryPath))
  Js.Dict.set(root, "timing_equivalence_inventory_sha256", Js.Json.string(
    timingEquivalenceInventorySha256,
  ))
  Js.Dict.set(root, "scene_scope", Js.Json.string("1-10 only; locked scenes 0/100/1000 excluded"))
  Js.Dict.set(
    root,
    "excluded_locked_chunks",
    Js.Json.array(lockedAssetChunkIds->Belt.Array.map(Js.Json.string)),
  )
  Js.Dict.set(root, "voice_synthesis", Js.Json.string("none; approved table-read performances only"))
  Js.Dict.set(
    root,
    "alignment",
    Js.Json.string(alignmentModeName(mode) ++ "; complete known transcript in screenplay order"),
  )
  Js.Dict.set(root, "narration_included", Js.Json.boolean(false))
  Js.Dict.set(root, "mimic_sfx_included", Js.Json.boolean(false))
  switch (context, evidence) {
  | (Some(context), Some(evidence)) => {
      verifyVakyanshAudit()
      let provenance = Js.Dict.empty()
      Js.Dict.set(provenance, "tool_version", Js.Json.string(context.toolVersion))
      Js.Dict.set(provenance, "tool_sha256", Js.Json.string(context.toolSha256))
      Js.Dict.set(provenance, "model_sha256", Js.Json.string(context.modelSha256))
      Js.Dict.set(provenance, "vocab_sha256", Js.Json.string(context.vocabSha256))
      Js.Dict.set(provenance, "config", Js.Json.string(vakyanshConfig))
      Js.Dict.set(provenance, "license", Js.Json.string("MIT"))
      Js.Dict.set(provenance, "license_path", Js.Json.string(vakyanshAuditLicensePath))
      Js.Dict.set(provenance, "license_sha256", Js.Json.string(approvedVakyanshLicenseSha256))
      Js.Dict.set(provenance, "vocab_audit_path", Js.Json.string(vakyanshAuditVocabPath))
      Js.Dict.set(provenance, "provenance_inventory", Js.Json.string(vakyanshAuditProvenancePath))
      Js.Dict.set(provenance, "provenance_inventory_sha256", Js.Json.string(approvedVakyanshProvenanceSha256))
      Js.Dict.set(provenance, "whisper_version", Js.Json.string(context.whisperVersion))
      Js.Dict.set(provenance, "whisper_binary_sha256", Js.Json.string(approvedWhisperBinarySha256))
      Js.Dict.set(provenance, "whisper_model_sha256", Js.Json.string(context.whisperModelSha256))
      Js.Dict.set(provenance, "whisper_config", Js.Json.string(stemWhisperConfig))
      Js.Dict.set(provenance, "whisper_provenance", Js.Json.string(whisperAuditProvenancePath))
      Js.Dict.set(provenance, "whisper_provenance_sha256", Js.Json.string(
        approvedWhisperProvenanceSha256,
      ))
      Js.Dict.set(provenance, "audio_toolchain_provenance", Js.Json.string(
        audioToolchainProvenancePath,
      ))
      Js.Dict.set(provenance, "audio_toolchain_provenance_sha256", Js.Json.string(
        approvedAudioToolchainProvenanceSha256,
      ))
      Js.Dict.set(provenance, "ffmpeg_sha256", Js.Json.string(approvedFfmpegSha256))
      Js.Dict.set(provenance, "ffprobe_sha256", Js.Json.string(approvedFfprobeSha256))
      Js.Dict.set(root, "local_alignment_provenance", Js.Json.object_(provenance))
      let rows = alignmentNeeds(input)->Belt.Array.map(need => {
        let value = switch Js.Dict.get(evidence, need.chunk.id) {
        | Some(value) => value
        | None => fail("manifest lacks Vakyansh evidence for " ++ need.chunk.id)
        }
        let row = Js.Dict.empty()
        Js.Dict.set(row, "chunk_id", Js.Json.string(need.chunk.id))
        Js.Dict.set(row, "source_sha256", Js.Json.string(need.sourceSha256))
        Js.Dict.set(row, "transcript_sha256", Js.Json.string(need.transcriptSha256))
        Js.Dict.set(row, "cache_path", Js.Json.string(value.cachePath))
        Js.Dict.set(row, "cache_sha256", Js.Json.string(value.cacheSha256))
        Js.Dict.set(row, "quality", qualityJson(value.quality))
        Js.Json.object_(row)
      })
      Js.Dict.set(root, "alignment_evidence", Js.Json.array(rows))
    }
  | (None, None) => fail("production publication requires local alignment and validation provenance")
  | _ => fail("alignment context and evidence must be supplied together")
  }
  Js.Dict.set(root, "stem_count", Js.Json.number(Belt.Int.toFloat(Belt.Array.length(stems))))
  Js.Dict.set(root, "stems", Js.Json.array(stems->Belt.Array.map(stemJson)))
  let body = Js.Json.object_(root)->Js.Json.stringifyWithSpace(1)
  stems->Belt.Array.forEach(row => {
    let validation = row.validation->Belt.Option.getExn
    if sha256File(Path(row.take.path)) != row.sourceSha256 ||
       sha256File(Path(row.path)) != validation.candidateMp3Sha256 {
      fail("source or stem changed before manifest publication at order " ++ Belt.Int.toString(row.segment.order))
    }
  })
  stems->Belt.Array.forEach(row => {
    let validation = row.validation->Belt.Option.getExn
    if sha256File(Path(row.take.path)) != row.sourceSha256 ||
       sha256File(Path(row.path)) != validation.candidateMp3Sha256 {
      fail("source or stem changed during manifest publication at order " ++ Belt.Int.toString(row.segment.order))
    }
  })
  body
}

let recover = async (
  ~dry: bool,
  ~paid: bool,
  ~mode: alignmentMode,
  ~localRequested: bool,
  ~vakyanshToolPath: option<string>,
  ~vakyanshModelPath: option<string>,
  ~vakyanshVocabPath: option<string>,
  ~whisperModelPath: option<string>,
): unit => {
  ignore(paid)
  let input = loadInputs()
  validateInputs(input)
  let report = switch mode {
  | LocalVakyansh => vakyanshDryReport(
      input,
      ~toolPath=vakyanshToolPath,
      ~modelPath=vakyanshModelPath,
      ~vocabPath=vakyanshVocabPath,
      ~whisperModelPath,
    )
  | ElevenForced => elevenDryReport(input)
  }
  if dry {
    printDryReport(report)
  } else {
    if exists(Path(outputManifestPath)) {
      fail("production dialogue manifest already exists; immutable output will not be replaced")
    }
    switch mode {
    | LocalVakyansh => {
        if !localRequested {
          fail(
            "local Vakyansh is the default alignment route, but execution requires LOCAL_ALIGN=1; " ++
            "run DRY=1 first",
          )
        }
        let context = requireVakyanshContext(
          ~toolPath=vakyanshToolPath,
          ~modelPath=vakyanshModelPath,
          ~vocabPath=vakyanshVocabPath,
          ~whisperModelPath,
        )
        let (timingsByChunk, evidence) = obtainVakyanshBlockTimings(input, context)
        let scratch = tempDir("kuku-ep9-validation-")->pathString
        let prepared = prepareStems(input, timingsByChunk, evidence, scratch)
        let (accepted, exceptions) = validatePreparedStems(prepared, context, evidence)
        if Belt.Array.length(exceptions) > 0 {
          publishManualReview(exceptions, context, evidence)
          fail(
            Belt.Int.toString(Belt.Array.length(exceptions)) ++
            " proposed stems failed independent Whisper validation; approved stems were not published",
          )
        }
        if sha256File(Path(planPath)) != approvedPlanSha256 ||
           sha256File(Path(sourceManifestPath)) != approvedSourceManifestSha256 ||
           sha256File(Path(context.toolPath)) != context.toolSha256 ||
           sha256File(Path(context.modelPath)) != context.modelSha256 ||
           sha256File(Path(context.vocabPath)) != context.vocabSha256 ||
           sha256File(Path(context.whisperModelPath)) != context.whisperModelSha256 ||
           sha256File(Path(whisperBinary)) != approvedWhisperBinarySha256 {
          fail("source or local evidence artifacts changed before publication")
        }
        validateInputs(input)
        verifyVakyanshAudit()
        verifyReleaseEvidence(input, prepared, accepted, context, evidence)
        let stems = publishValidatedStems(prepared, accepted)
        verifyReleaseEvidence(input, prepared, stems, context, evidence)
        let publishedManifestBody = buildManifestBody(
          input,
          stems,
          mode,
          ~context=Some(context),
          ~evidence=Some(evidence),
        )
        let manifestSha256 = sha256Text(publishedManifestBody)
        let stagedManifestPath = scratch ++ "/EP9_PRODUCTION_DIALOGUE_" ++
          manifestSha256 ++ ".manifest.json"
        writeText(Path(stagedManifestPath), publishedManifestBody)
        assertExactFile("staged production manifest", stagedManifestPath, manifestSha256)
        verifyReleaseEvidence(input, prepared, stems, context, evidence)
        /* The authoritative path appears only after every long-running evidence
           check succeeds. A failed post-body audit therefore cannot leave a
           nominal production manifest behind. */
        assertExactFile("staged production manifest", stagedManifestPath, manifestSha256)
        if !publishFileExclusive(Path(stagedManifestPath), Path(outputManifestPath)) {
          fail("production dialogue manifest appeared before final publication")
        }
        if readText(Path(outputManifestPath)) != publishedManifestBody {
          fail("production dialogue manifest exact-body readback failed")
        }
        Js.log(
          "KUKU EP9 PRODUCTION DIALOGUE -> " ++ outputManifestPath ++ " (" ++
          Belt.Int.toString(Belt.Array.length(stems)) ++
          " approved-performance stems; Vakyansh + independent Whisper; no synthesis)",
        )
      }
    | ElevenForced => {
        fail(
          "Eleven forced alignment publication is disabled because it is not wired to the " ++
          "content-bound independent validation contract; no paid request was made",
        )
      }
    }
  }
}
