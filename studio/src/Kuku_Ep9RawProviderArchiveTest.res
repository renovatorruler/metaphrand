@val @scope("process") external exit: int => unit = "exit"

let fail = message => {
  Js.log("FAIL: " ++ message)
  exit(1)
}

let check = (condition: bool, message: string): unit =>
  if !condition {
    fail(message)
  }

let input = Kuku_Ep9FinaleDialogue.loadInputs()
Kuku_Ep9FinaleDialogue.validateInputs(input)
Kuku_Ep9RawProviderArchive.validateMappings(input)

let specs = Kuku_Ep9RawProviderArchive.rawSpecs
check(Belt.Array.length(specs) == 18, "exact raw-provider spec count")
check(
  specs->Belt.Array.map(spec => spec.chunkId)->Js.Array2.joinWith(",") ==
    Kuku_Ep9RawProviderArchive.expectedAlignmentIds(input)->Js.Array2.joinWith(","),
  "archive specs must exactly match alignment chunks",
)
check(
  specs->Belt.Array.keep(spec => spec.origin == Kuku_Ep9RawProviderArchive.V2Direct)->Belt.Array.length == 13,
  "thirteen direct V2 raws",
)
check(
  specs->Belt.Array.keep(spec => spec.origin == Kuku_Ep9RawProviderArchive.V1Reused)->Belt.Array.length == 5,
  "five V1-reused raws",
)

let reused =
  specs
  ->Belt.Array.keep(spec => spec.origin == Kuku_Ep9RawProviderArchive.V1Reused)
  ->Belt.Array.map(spec => spec.chunkId ++ "<-" ++ spec.rawChunkId)
  ->Js.Array2.joinWith(",")
check(
  reused ==
    "chunk_011<-chunk_006,chunk_016<-chunk_011,chunk_021<-chunk_016,chunk_023<-chunk_018,chunk_026<-chunk_021",
  "V1 reuse provenance",
)
check(
  Belt.Array.every(specs, spec =>
    !Kuku_Ep9FinaleDialogue.isLockedAssetChunkId(spec.chunkId) &&
    spec.chunkId != "chunk_012" && spec.chunkId != "chunk_018" && spec.chunkId != "chunk_025"
  ),
  "cold-open/title, chorus, narration-only, and mimic chunks excluded",
)

let roots: Kuku_Ep9RawProviderArchive.roots = {
  v2: "/fixture/v2",
  v1: "/fixture/v1",
}
let durations = Js.Dict.empty()
input.takes->Belt.Array.forEach(take => Js.Dict.set(durations, take.path, take.duration))
specs->Belt.Array.forEach(spec => {
  let take = Kuku_Ep9FinaleDialogue.takeForChunk(input.takes, spec.chunkId)
  Js.Dict.set(
    durations,
    Kuku_Ep9RawProviderArchive.rawSourcePath(roots, spec),
    take.duration,
  )
})

let fakeDuration = path =>
  switch Js.Dict.get(durations, path) {
  | Some(value) => value
  | None => fail("unexpected duration lookup: " ++ path); 0.0
  }

let fakeInspectors: Kuku_Ep9RawProviderArchive.fileInspectors = {
  exists_: path => !Js.String2.startsWith(path, Kuku_Ep9RawProviderArchive.archiveDir),
  duration: fakeDuration,
  sha256: path => Cinema_Backends.sha256Text(path),
}
let inspection = Kuku_Ep9RawProviderArchive.inspectWith(input, roots, fakeInspectors)
check(Belt.Array.length(inspection.entries) == 18, "fake inspection entry count")
check(Belt.Array.length(inspection.missingRaw) == 0, "fake inspection raw sources")
check(Belt.Array.length(inspection.missingNormalized) == 0, "fake inspection normalized sources")
check(Belt.Array.length(inspection.issues) == 0, "fake inspection issues")
check(Belt.Array.length(inspection.missingArchive) == 18, "dry inspection reports all missing archive objects")
check(!Kuku_Ep9RawProviderArchive.hasBlockingIssue(inspection), "missing archive is not a source failure")
inspection.entries->Belt.Array.forEach(entry => {
  check(Js.String2.length(entry.rawSha256) == 64, "raw hash shape")
  check(
    entry.archivedPath ==
      Kuku_Ep9RawProviderArchive.archiveDir ++ "/" ++ entry.rawSha256 ++ ".mp3",
    "content-addressed audio path",
  )
})

let missingPaths = [
  Kuku_Ep9RawProviderArchive.rawSourcePath(roots, Belt.Array.getExn(specs, 0)),
  Kuku_Ep9RawProviderArchive.rawSourcePath(roots, Belt.Array.getExn(specs, 10)),
]
let missingInspectors: Kuku_Ep9RawProviderArchive.fileInspectors = {
  exists_: path =>
    !Js.String2.startsWith(path, Kuku_Ep9RawProviderArchive.archiveDir) &&
    !Belt.Array.some(missingPaths, missing => missing == path),
  duration: fakeDuration,
  sha256: path => Cinema_Backends.sha256Text(path),
}
let missingInspection = Kuku_Ep9RawProviderArchive.inspectWith(input, roots, missingInspectors)
check(Belt.Array.length(missingInspection.missingRaw) == 2, "all missing raws accumulated")
check(
  missingInspection.missingRaw->Belt.Array.map(row =>
    Js.String2.slice(row, ~from=0, ~to_=9)
  )->Js.Array2.joinWith(",") == "chunk_006,chunk_017",
  "missing report identifies exact chunks in order",
)
check(Kuku_Ep9RawProviderArchive.hasBlockingIssue(missingInspection), "missing raw blocks publication")

let context: Kuku_Ep9RawProviderArchive.inventoryContext = {
  roots,
  planSha256: Cinema_Backends.sha256Text("plan"),
  manifestSha256: Cinema_Backends.sha256Text("manifest"),
}
let body1 = Kuku_Ep9RawProviderArchive.inventoryBody(context, inspection.entries)
let body2 = Kuku_Ep9RawProviderArchive.inventoryBody(context, inspection.entries)
check(body1 == body2, "inventory JSON is deterministic")
check(
  Kuku_Ep9RawProviderArchive.inventoryPathForBody(body1) ==
    Kuku_Ep9RawProviderArchive.archiveDir ++ "/inventory_" ++
    Cinema_Backends.sha256Text(body1) ++ ".json",
  "content-addressed inventory path",
)
check(Js.String2.includes(body1, "\"entry_count\": 18"), "inventory count")
check(Js.String2.includes(body1, "v1-reused-raw"), "inventory preserves reuse provenance")

Js.log(
  "KUKU EP9 RAW PROVIDER ARCHIVE TESTS PASSED — exact 13+5 mapping, deterministic inventory, zero archive writes",
)
