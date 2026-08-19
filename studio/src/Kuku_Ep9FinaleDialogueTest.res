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
let approvedSourceIds = Js.Dict.keys(input.approvedSources)->Js.Array2.sortInPlace
let expectedApprovedSourceIds = [
  "chunk_006", "chunk_007", "chunk_008", "chunk_009", "chunk_010", "chunk_011",
  "chunk_012", "chunk_013", "chunk_014", "chunk_015", "chunk_016", "chunk_017",
  "chunk_019", "chunk_020", "chunk_021", "chunk_022", "chunk_023", "chunk_024",
  "chunk_026",
]
check(
  approvedSourceIds->Js.Array2.joinWith(",") == expectedApprovedSourceIds->Js.Array2.joinWith(","),
  "only aligned chunks plus the isolated chorus have approved byte identities",
)
approvedSourceIds->Belt.Array.forEach(id => {
  let approved = Js.Dict.get(input.approvedSources, id)->Belt.Option.getExn
  let take = Kuku_Ep9FinaleDialogue.takeForChunk(input.takes, id)
  check(approved.path == take.path, "approved source path " ++ id)
  check(
    Cinema_Backends.sha256File(Cinema_Backends.Path(take.path)) == approved.sha256,
    "approved source bytes " ++ id,
  )
})
let report = Kuku_Ep9FinaleDialogue.vakyanshDryReport(
  input,
  ~toolPath=None,
  ~modelPath=None,
  ~vocabPath=None,
  ~whisperModelPath=None,
)

check(report.segmentCount == 328, "source segment count")
check(report.chunkCount == 27, "source chunk count")
check(report.productionSegmentCount == 262, "scenes 1-10 source segment count")
check(report.productionChunkCount == 21, "scenes 1-10 source chunk count")
check(report.lockedSegmentCount == 66, "locked cold-open/title segment count")
check(report.lockedChunkCount == 6, "locked cold-open/title chunk count")
check(report.selectedCount == 137, "selected production-line count")
check(report.dialogueCount == 136, "dialogue count")
check(report.chorusCount == 1, "chorus count")
check(report.narrationExcluded == 124, "scoped narration exclusion count")
check(report.mimicExcluded == 1, "mimic/SFX exclusion count")
check(report.mixedChunkCount == 17, "mixed-chunk alignment count")
check(report.alignmentChunkCount == 18, "total alignment input count")
check(report.rawCachedCount == 0, "no local raw cache without a model identity")
check(
  report.cachedAlignmentCount + Belt.Array.length(report.missingAlignmentIds) == 18,
  "cached plus missing alignment accounting",
)
check(
  !Kuku_Ep9FinaleDialogue.paidAllowed(~dry=true, ~paid=true),
  "DRY must override PAID",
)
check(
  !Kuku_Ep9FinaleDialogue.paidAllowed(~dry=false, ~paid=false),
  "alignment must require PAID=1",
)
check(
  Kuku_Ep9FinaleDialogue.paidAllowed(~dry=false, ~paid=true),
  "explicit paid non-dry mode",
)
check(
  Kuku_Ep9FinaleDialogue.alignmentModeFor(~localRequested=false, ~elevenRequested=false) ==
    Kuku_Ep9FinaleDialogue.LocalVakyansh,
  "local Vakyansh must be the default route",
)
check(
  Kuku_Ep9FinaleDialogue.alignmentModeFor(~localRequested=false, ~elevenRequested=true) ==
    Kuku_Ep9FinaleDialogue.ElevenForced,
  "cloud alignment requires an explicit selector",
)

let needs = Kuku_Ep9FinaleDialogue.alignmentNeeds(input)
let expectedAlignmentIds = [
  "chunk_006",
  "chunk_007",
  "chunk_008",
  "chunk_009",
  "chunk_010",
  "chunk_011",
  "chunk_013",
  "chunk_014",
  "chunk_015",
  "chunk_016",
  "chunk_017",
  "chunk_019",
  "chunk_020",
  "chunk_021",
  "chunk_022",
  "chunk_023",
  "chunk_024",
  "chunk_026",
]
check(
  needs->Belt.Array.map(need => need.chunk.id)->Js.Array2.joinWith(",") ==
    expectedAlignmentIds->Js.Array2.joinWith(","),
  "only the exact scenes 1-10 chunks requiring alignment may be scheduled",
)
check(
  report.missingAlignmentIds->Js.Array2.joinWith(",") ==
    expectedAlignmentIds->Js.Array2.joinWith(","),
  "dry report must name every missing scenes 1-10 alignment exactly",
)
needs->Belt.Array.forEach(need => {
  check(
    need.chunk.scene >= 1 && need.chunk.scene <= 10,
    "alignment inputs must remain inside scenes 1-10",
  )
  check(
    !Kuku_Ep9FinaleDialogue.isLockedAssetChunkId(need.chunk.id),
    "chunks 000-005 must never be aligned",
  )
  check(
    Js.String2.startsWith(
      need.cachePath,
      "../stories/kuku/ep9prod/finale/audio/alignment/",
    ),
    "alignment cache must stay in finale audio/alignment",
  )
  check(
    need.transcript.text ==
      need.chunk.segments
      ->Belt.Array.map(Kuku_Ep9FinaleDialogue.spokenText)
      ->Js.Array2.joinWith(" "),
    "alignment transcript must contain every spoken block in chunk order",
  )
  check(!Js.String2.includes(need.transcript.text, "["), "alignment transcript excludes tags")
})

let selected = input.segments->Belt.Array.keep(Kuku_Ep9FinaleDialogue.isSelectedProductionSegment)
check(
  Belt.Array.every(selected, segment => segment.kind != "narration"),
  "production selection must exclude narration",
)
check(
  Belt.Array.every(selected, segment => segment.kind != "mimic"),
  "the mimic sound beat must remain outside the dialogue manifest",
)
check(
  Belt.Array.every(selected, segment => segment.scene >= 1 && segment.scene <= 10),
  "production selection must remain inside scenes 1-10",
)

Js.log(
  "KUKU EP9 FINALE DIALOGUE TESTS PASSED — 137 approved-performance stems planned; " ++
  Belt.Int.toString(Belt.Array.length(report.missingAlignmentIds)) ++
  " alignment caches currently missing; zero provider calls",
)
