/* Preserve the original, unnormalized ElevenLabs responses behind the approved
   Kuku EP9 table read. This is an archive operation only: it never calls a
   provider, synthesizer, aligner, or model.

   The V2 render reused five continuous takes from V1, so provenance is explicit
   rather than guessed from filenames. Only the eighteen scenes 1-10 chunks that
   require production-dialogue alignment are eligible. Cold-open/title chunks,
   the isolated chorus, narration-only takes, and the mimic/SFX are excluded.

   The currently discovered macOS temp directories are defaults so the rescue is
   immediately reproducible. Override them if the directories have been moved:

     KUKU_EP9_V2_RAW_DIR=/absolute/v2/raw/dir
     KUKU_EP9_V1_RAW_DIR=/absolute/v1/raw/dir

   Run through Kuku_Ep9RawProviderArchiveCli.res.mjs from studio/:

     DRY=1 node src/Kuku_Ep9RawProviderArchiveCli.res.mjs
     ARCHIVE=1 node src/Kuku_Ep9RawProviderArchiveCli.res.mjs

   DRY writes nothing. Publication first makes a byte-for-byte scratch copy,
   verifies it, then uses exclusive hard-link publication. Existing archive
   objects and inventories are reused only after their content is revalidated. */

open Cinema_Backends

exception RawProviderArchive(string)

let pipelineVersion = "kuku-ep9-raw-provider-archive-v1"
let defaultV2RawDir =
  "/private/var/folders/6q/wvypn99j78l44mt2y_670l9c0000gn/T/kuku-ep9-table-read-VpA2Jd"
let defaultV1RawDir =
  "/private/var/folders/6q/wvypn99j78l44mt2y_670l9c0000gn/T/kuku-ep9-table-read-ler5WB"
let archiveDir =
  "../stories/kuku/ep9prod/finale/audio/alignment/raw_provider"
let durationToleranceSeconds = 0.12

type roots = {v2: string, v1: string}
type origin = V2Direct | V1Reused

type rawSpec = {
  chunkId: string,
  rawChunkId: string,
  origin: origin,
}

type fileInspectors = {
  exists_: string => bool,
  duration: string => float,
  sha256: string => string,
}

type archiveEntry = {
  chunkId: string,
  scene: int,
  origin: origin,
  rawChunkId: string,
  rawSourcePath: string,
  rawSha256: string,
  rawDuration: float,
  normalizedPath: string,
  normalizedSha256: string,
  normalizedDuration: float,
  archivedPath: string,
}

type inspection = {
  entries: array<archiveEntry>,
  missingRaw: array<string>,
  missingNormalized: array<string>,
  missingArchive: array<string>,
  issues: array<string>,
}

type inventoryContext = {
  roots: roots,
  planSha256: string,
  manifestSha256: string,
}

type archiveResult = {
  archivedCount: int,
  reusedCount: int,
  inventoryPath: string,
  inventorySha256: string,
  inventoryReused: bool,
}

let fail = message => raise(RawProviderArchive(message))

let rawSpecs: array<rawSpec> = [
  {chunkId: "chunk_006", rawChunkId: "chunk_006", origin: V2Direct},
  {chunkId: "chunk_007", rawChunkId: "chunk_007", origin: V2Direct},
  {chunkId: "chunk_008", rawChunkId: "chunk_008", origin: V2Direct},
  {chunkId: "chunk_009", rawChunkId: "chunk_009", origin: V2Direct},
  {chunkId: "chunk_010", rawChunkId: "chunk_010", origin: V2Direct},
  {chunkId: "chunk_011", rawChunkId: "chunk_006", origin: V1Reused},
  {chunkId: "chunk_013", rawChunkId: "chunk_013", origin: V2Direct},
  {chunkId: "chunk_014", rawChunkId: "chunk_014", origin: V2Direct},
  {chunkId: "chunk_015", rawChunkId: "chunk_015", origin: V2Direct},
  {chunkId: "chunk_016", rawChunkId: "chunk_011", origin: V1Reused},
  {chunkId: "chunk_017", rawChunkId: "chunk_017", origin: V2Direct},
  {chunkId: "chunk_019", rawChunkId: "chunk_019", origin: V2Direct},
  {chunkId: "chunk_020", rawChunkId: "chunk_020", origin: V2Direct},
  {chunkId: "chunk_021", rawChunkId: "chunk_016", origin: V1Reused},
  {chunkId: "chunk_022", rawChunkId: "chunk_022", origin: V2Direct},
  {chunkId: "chunk_023", rawChunkId: "chunk_018", origin: V1Reused},
  {chunkId: "chunk_024", rawChunkId: "chunk_024", origin: V2Direct},
  {chunkId: "chunk_026", rawChunkId: "chunk_021", origin: V1Reused},
]

let originName = origin =>
  switch origin {
  | V2Direct => "v2-direct-raw"
  | V1Reused => "v1-reused-raw"
  }

let rawDirFor = (roots, origin) =>
  switch origin {
  | V2Direct => roots.v2
  | V1Reused => roots.v1
  }

let rawSourcePath = (roots: roots, spec: rawSpec): string =>
  rawDirFor(roots, spec.origin) ++ "/" ++ spec.rawChunkId ++ "_dialogue_raw.mp3"

let archivedPathForHash = (sha256: string): string => archiveDir ++ "/" ++ sha256 ++ ".mp3"

let inventoryPathForBody = (body: string): string =>
  archiveDir ++ "/inventory_" ++ sha256Text(body) ++ ".json"

let expectedAlignmentIds = (input: Kuku_Ep9FinaleDialogue.inputs): array<string> =>
  Kuku_Ep9FinaleDialogue.alignmentNeeds(input)->Belt.Array.map(need => need.chunk.id)

let validateMappings = (input: Kuku_Ep9FinaleDialogue.inputs): unit => {
  let expected = expectedAlignmentIds(input)
  let actual = rawSpecs->Belt.Array.map(spec => spec.chunkId)
  if Belt.Array.length(rawSpecs) != 18 ||
     Js.Array2.joinWith(expected, ",") != Js.Array2.joinWith(actual, ",") {
    fail(
      "raw-provider map must exactly equal the eighteen scenes 1-10 alignment chunks; expected " ++
      Js.Array2.joinWith(expected, ",") ++ ", got " ++ Js.Array2.joinWith(actual, ","),
    )
  }
  let seen = Js.Dict.empty()
  rawSpecs->Belt.Array.forEach(spec => {
    if Js.Dict.get(seen, spec.chunkId) != None {
      fail("duplicate raw-provider mapping for " ++ spec.chunkId)
    }
    Js.Dict.set(seen, spec.chunkId, true)
    let take = Kuku_Ep9FinaleDialogue.takeForChunk(input.takes, spec.chunkId)
    if take.scene < 1 || take.scene > 10 || take.kind != "dialogue" ||
       Kuku_Ep9FinaleDialogue.isLockedAssetChunkId(spec.chunkId) {
      fail("out-of-scope raw-provider mapping for " ++ spec.chunkId)
    }
    switch spec.origin {
    | V2Direct if spec.rawChunkId != spec.chunkId =>
      fail("direct V2 mapping changed chunk identity for " ++ spec.chunkId)
    | _ => ()
    }
  })
}

let productionInspectors: fileInspectors = {
  exists_: path => exists(Path(path)),
  duration: path => {
    let Seconds(value) = probeDuration(Path(path))
    value
  },
  sha256: path => sha256File(Path(path)),
}

let inspectWith = (
  input: Kuku_Ep9FinaleDialogue.inputs,
  roots: roots,
  inspectors: fileInspectors,
): inspection => {
  validateMappings(input)
  let entries: array<archiveEntry> = []
  let missingRaw: array<string> = []
  let missingNormalized: array<string> = []
  let missingArchive: array<string> = []
  let issues: array<string> = []

  rawSpecs->Belt.Array.forEach(spec => {
    let take = Kuku_Ep9FinaleDialogue.takeForChunk(input.takes, spec.chunkId)
    let rawPath = rawSourcePath(roots, spec)
    let rawExists = inspectors.exists_(rawPath)
    let normalizedExists = inspectors.exists_(take.path)
    if !rawExists {
      let _ = Js.Array2.push(missingRaw, spec.chunkId ++ " <- " ++ rawPath)
    }
    if !normalizedExists {
      let _ = Js.Array2.push(missingNormalized, spec.chunkId ++ " <- " ++ take.path)
    }
    if rawExists && normalizedExists {
      let rawDuration = inspectors.duration(rawPath)
      let normalizedDuration = inspectors.duration(take.path)
      if !Js.Float.isFinite(rawDuration) || rawDuration <= 0.0 {
        let _ = Js.Array2.push(issues, spec.chunkId ++ " has invalid raw duration")
      }
      if !Js.Float.isFinite(normalizedDuration) || normalizedDuration <= 0.0 {
        let _ = Js.Array2.push(issues, spec.chunkId ++ " has invalid normalized duration")
      }
      if abs_float(normalizedDuration -. take.duration) > durationToleranceSeconds {
        let _ = Js.Array2.push(
          issues,
          spec.chunkId ++ " normalized duration differs from approved manifest: " ++
          Js.Float.toString(normalizedDuration) ++ " versus " ++ Js.Float.toString(take.duration),
        )
      }
      if abs_float(rawDuration -. normalizedDuration) > durationToleranceSeconds {
        let _ = Js.Array2.push(
          issues,
          spec.chunkId ++ " raw/normalized duration mismatch: " ++
          Js.Float.toString(rawDuration) ++ " versus " ++ Js.Float.toString(normalizedDuration),
        )
      }
      let rawSha256 = inspectors.sha256(rawPath)
      let normalizedSha256 = inspectors.sha256(take.path)
      let archivedPath = archivedPathForHash(rawSha256)
      if inspectors.exists_(archivedPath) {
        let archivedSha256 = inspectors.sha256(archivedPath)
        if archivedSha256 != rawSha256 {
          let _ = Js.Array2.push(
            issues,
            spec.chunkId ++ " archive hash mismatch at " ++ archivedPath,
          )
        }
        let archivedDuration = inspectors.duration(archivedPath)
        if abs_float(archivedDuration -. rawDuration) > durationToleranceSeconds {
          let _ = Js.Array2.push(
            issues,
            spec.chunkId ++ " archive duration mismatch at " ++ archivedPath,
          )
        }
      } else {
        let _ = Js.Array2.push(missingArchive, spec.chunkId ++ " -> " ++ archivedPath)
      }
      let _ = Js.Array2.push(entries, {
        chunkId: spec.chunkId,
        scene: take.scene,
        origin: spec.origin,
        rawChunkId: spec.rawChunkId,
        rawSourcePath: rawPath,
        rawSha256,
        rawDuration,
        normalizedPath: take.path,
        normalizedSha256,
        normalizedDuration,
        archivedPath,
      })
    }
  })
  {entries, missingRaw, missingNormalized, missingArchive, issues}
}

let inspect = (input, roots): inspection => inspectWith(input, roots, productionInspectors)

let hasBlockingIssue = inspection =>
  Belt.Array.length(inspection.missingRaw) > 0 ||
  Belt.Array.length(inspection.missingNormalized) > 0 ||
  Belt.Array.length(inspection.issues) > 0 ||
  Belt.Array.length(inspection.entries) != 18

let addString = (object_, key, value) => Js.Dict.set(object_, key, Js.Json.string(value))
let addNumber = (object_, key, value) => Js.Dict.set(object_, key, Js.Json.number(value))

let entryJson = (entry: archiveEntry): Js.Json.t => {
  let object_ = Js.Dict.empty()
  addString(object_, "chunk_id", entry.chunkId)
  addNumber(object_, "scene", Belt.Int.toFloat(entry.scene))
  addString(object_, "provenance", originName(entry.origin))
  addString(object_, "raw_render_chunk_id", entry.rawChunkId)
  addString(object_, "raw_source_path", entry.rawSourcePath)
  addString(object_, "raw_sha256", entry.rawSha256)
  addNumber(object_, "raw_duration_seconds", entry.rawDuration)
  addString(object_, "normalized_source_path", entry.normalizedPath)
  addString(object_, "normalized_sha256", entry.normalizedSha256)
  addNumber(object_, "normalized_duration_seconds", entry.normalizedDuration)
  addString(object_, "archived_path", entry.archivedPath)
  addString(object_, "archived_sha256", entry.rawSha256)
  Js.Json.object_(object_)
}

let inventoryBody = (
  context: inventoryContext,
  entries: array<archiveEntry>,
): string => {
  let root = Js.Dict.empty()
  addString(root, "schema", "kuku-ep9-raw-provider-archive/v1")
  addString(root, "pipeline_version", pipelineVersion)
  addString(root, "scope", "scenes 1-10; eighteen alignment chunks only")
  addString(root, "source_plan", Kuku_Ep9FinaleDialogue.planPath)
  addString(root, "source_plan_sha256", context.planSha256)
  addString(root, "source_manifest", Kuku_Ep9FinaleDialogue.sourceManifestPath)
  addString(root, "source_manifest_sha256", context.manifestSha256)
  addString(root, "v2_raw_root", context.roots.v2)
  addString(root, "v1_raw_root", context.roots.v1)
  addString(
    root,
    "publication",
    "byte-for-byte scratch copy, SHA-256 verification, exclusive immutable publication",
  )
  addNumber(root, "entry_count", Belt.Int.toFloat(Belt.Array.length(entries)))
  Js.Dict.set(root, "entries", Js.Json.array(entries->Belt.Array.map(entryJson)))
  Js.Json.object_(root)->Js.Json.stringifyWithSpace(1)
}

let printList = (label: string, values: array<string>): unit => {
  Js.log(label ++ ": " ++ Belt.Int.toString(Belt.Array.length(values)))
  values->Belt.Array.forEach(value => Js.log("  " ++ value))
}

let printInspection = (inspection: inspection): unit => {
  Js.log(
    "raw-provider preflight: " ++ Belt.Int.toString(Belt.Array.length(inspection.entries)) ++
    "/18 verified source pairs",
  )
  printList("missing raw sources", inspection.missingRaw)
  printList("missing normalized counterparts", inspection.missingNormalized)
  printList("invalid or conflicting artifacts", inspection.issues)
  printList("archive objects not yet present", inspection.missingArchive)
}

let validatePublishedObject = (entry: archiveEntry): unit => {
  if !exists(Path(entry.archivedPath)) || sha256File(Path(entry.archivedPath)) != entry.rawSha256 {
    fail("published archive object failed hash validation for " ++ entry.chunkId)
  }
  let Seconds(duration) = probeDuration(Path(entry.archivedPath))
  if abs_float(duration -. entry.rawDuration) > durationToleranceSeconds {
    fail("published archive object failed duration validation for " ++ entry.chunkId)
  }
}

let publish = (
  input: Kuku_Ep9FinaleDialogue.inputs,
  roots: roots,
  inspection: inspection,
): archiveResult => {
  if hasBlockingIssue(inspection) {
    fail("refusing raw-provider publication because preflight did not pass")
  }
  let scratch = tempDir("kuku-ep9-raw-provider-archive-")
  let Path(scratchRoot) = scratch
  let archivedCount = ref(0)
  let reusedCount = ref(0)
  inspection.entries->Belt.Array.forEach(entry => {
    if exists(Path(entry.archivedPath)) {
      validatePublishedObject(entry)
      reusedCount := reusedCount.contents + 1
    } else {
      let staged = scratchRoot ++ "/" ++ entry.rawSha256 ++ ".mp3"
      if !exists(Path(staged)) {
        copyFile(Path(entry.rawSourcePath), Path(staged))
      }
      if sha256File(Path(staged)) != entry.rawSha256 {
        fail("scratch copy changed bytes for " ++ entry.chunkId)
      }
      let Seconds(stagedDuration) = probeDuration(Path(staged))
      if abs_float(stagedDuration -. entry.rawDuration) > durationToleranceSeconds {
        fail("scratch copy changed duration for " ++ entry.chunkId)
      }
      if publishFileExclusive(Path(staged), Path(entry.archivedPath)) {
        archivedCount := archivedCount.contents + 1
      } else {
        /* Another archive process may have won the exclusive publication race.
           Accept it only when it is the same content-addressed object. */
        validatePublishedObject(entry)
        reusedCount := reusedCount.contents + 1
      }
      validatePublishedObject(entry)
    }
  })

  let context = {
    roots,
    planSha256: sha256File(Path(Kuku_Ep9FinaleDialogue.planPath)),
    manifestSha256: sha256File(Path(Kuku_Ep9FinaleDialogue.sourceManifestPath)),
  }
  let body = inventoryBody(context, inspection.entries)
  let inventorySha256 = sha256Text(body)
  let inventoryPath = inventoryPathForBody(body)
  let inventoryReused = if exists(Path(inventoryPath)) {
    if readText(Path(inventoryPath)) != body || sha256File(Path(inventoryPath)) != inventorySha256 {
      fail("content-addressed inventory is corrupt: " ++ inventoryPath)
    }
    true
  } else {
    if !writeTextExclusive(Path(inventoryPath), body) {
      if !exists(Path(inventoryPath)) || readText(Path(inventoryPath)) != body {
        fail("inventory appeared with different content: " ++ inventoryPath)
      }
      true
    } else {
      false
    }
  }
  if sha256File(Path(inventoryPath)) != inventorySha256 {
    fail("published inventory failed content-address validation")
  }
  ignore(input)
  {
    archivedCount: archivedCount.contents,
    reusedCount: reusedCount.contents,
    inventoryPath,
    inventorySha256,
    inventoryReused,
  }
}

let loadAndInspect = (roots: roots): (Kuku_Ep9FinaleDialogue.inputs, inspection) => {
  let input = Kuku_Ep9FinaleDialogue.loadInputs()
  Kuku_Ep9FinaleDialogue.validateInputs(input)
  let inspection = inspect(input, roots)
  (input, inspection)
}
