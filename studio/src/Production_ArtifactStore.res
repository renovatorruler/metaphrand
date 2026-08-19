module B = Cinema_Backends
module Safety = Production_OutputSafety
module L = Production_Lease

exception StoreError(string)

type store = {root: string, reviewBatchSize: int}

type contentKind = Text | File
type inspectionVerdict = Pass | Fail | Unknown
type dispositionKind = Rejected | Stale | Quarantined | Superseded | Reusable
type reviewDecision = Approve | Reject

type candidate = {
  candidateHash: string,
  producerId: string,
  targetId: string,
  authorizationId: string,
  attempt: int,
  providerReceiptHash: string,
  packetHash: string,
  workOrderHash: string,
  artifactHash: string,
  contentKind: contentKind,
  objectPath: string,
}

type inspection = {
  inspectionHash: string,
  candidateHash: string,
  packetHash: string,
  workOrderHash: string,
  artifactHash: string,
  reportHash: string,
  inspectorId: string,
  verdict: inspectionVerdict,
}

type disposition = {
  dispositionHash: string,
  candidateHash: string,
  packetHash: string,
  workOrderHash: string,
  artifactHash: string,
  kind: dispositionKind,
  reason: string,
  supersededBy: option<string>,
  reportHashes: array<string>,
}

type reviewEntry = {
  candidateHash: string,
  targetId: string,
  packetHash: string,
  workOrderHash: string,
  artifactHash: string,
  reportHashes: array<string>,
}

type reviewBatch = {batchHash: string, targetId: string, entries: array<reviewEntry>}

type reviewRecord = {
  reviewHash: string,
  batchHash: string,
  candidateHash: string,
  targetId: string,
  packetHash: string,
  workOrderHash: string,
  artifactHash: string,
  reportHashes: array<string>,
  reviewerId: string,
  decision: reviewDecision,
  note: string,
}

@module("path") external dirname: string => string = "dirname"
@module("path") external resolvePath: string => string = "resolve"

let fail = message => raise(StoreError(message))
let q = value => Js.Json.stringify(Js.Json.string(value))

let validHash = value =>
  Js.String2.length(value) == 64 &&
    value
    ->Js.String2.split("")
    ->Belt.Array.every(character =>
      (character >= "0" && character <= "9") || (character >= "a" && character <= "f")
    )

let requireHash = (label, value) =>
  if !validHash(value) {
    fail(label ++ " must be a lowercase SHA-256 hex digest")
  }

let requireAuthorizationId = (label, value) =>
  if (
    !Js.String2.startsWith(value, "AUTH-") ||
    !validHash(Js.String2.sliceToEnd(value, ~from=5))
  ) {
    fail(label ++ " must be AUTH- followed by a lowercase SHA-256 hex digest")
  }

let requirePositiveAttempt = (label, value) =>
  if value < 1 {
    fail(label ++ " must be a positive global attempt number")
  }

let requireNonempty = (label, value) =>
  if Js.String2.trim(value) == "" {
    fail(label ++ " must not be empty")
  }

let kindString = kind =>
  switch kind {
  | Text => "text"
  | File => "file"
  }

let kindFromString = value =>
  switch value {
  | "text" => Text
  | "file" => File
  | other => fail("unknown content kind " ++ other)
  }

let verdictString = verdict =>
  switch verdict {
  | Pass => "pass"
  | Fail => "fail"
  | Unknown => "unknown"
  }

let verdictFromString = value =>
  switch value {
  | "pass" => Pass
  | "fail" => Fail
  | "unknown" => Unknown
  | other => fail("unknown inspection verdict " ++ other)
  }

let dispositionString = kind =>
  switch kind {
  | Rejected => "rejected"
  | Stale => "stale"
  | Quarantined => "quarantined"
  | Superseded => "superseded"
  | Reusable => "reusable"
  }

let dispositionFromString = value =>
  switch value {
  | "rejected" => Rejected
  | "stale" => Stale
  | "quarantined" => Quarantined
  | "superseded" => Superseded
  | "reusable" => Reusable
  | other => fail("unknown disposition " ++ other)
  }

let decisionString = decision =>
  switch decision {
  | Approve => "approve"
  | Reject => "reject"
  }

let decisionFromString = value =>
  switch value {
  | "approve" => Approve
  | "reject" => Reject
  | other => fail("unknown review decision " ++ other)
  }

let sortedStrings = (values: array<string>): array<string> =>
  values->Belt.Array.map(value => value)->Js.Array2.sortInPlace

let stringArrayJson = (values: array<string>): string =>
  values->sortedStrings->Belt.Array.map(q)->Js.Array2.joinWith(",")

let safePath = (store: store, relativePath: string, label: string): string =>
  Safety.manifestOutputPath(~baseDir=store.root, ~relativePath, ~label)

let ensureSafeParent = (store: store, relativePath: string, label: string): string => {
  let first = safePath(store, relativePath, label)
  B.ensureDirPath(B.Path(dirname(first)))
  /* Re-resolve after mkdir so a pre-existing symlink cannot be hidden by a
   lexical check performed before its parent existed. */
  safePath(store, relativePath, label)
}

let readDirectory = (store: store, relativeDir: string, label: string): array<string> => {
  let sentinel = safePath(store, relativeDir ++ "/.read-guard", label)
  B.readDir(B.Path(dirname(sentinel)))
}

let writeImmutableText = (
  store: store,
  relativePath: string,
  label: string,
  body: string,
): string => {
  let path = ensureSafeParent(store, relativePath, label)
  if B.writeTextExclusive(B.Path(path), body) {
    path
  } else if B.exists(B.Path(path)) && B.readText(B.Path(path)) == body {
    path
  } else {
    fail(label ++ " collides with different immutable content at " ++ path)
  }
}

let objectRelativePath = (artifactHash: string, kind: contentKind): string => {
  let prefix = Js.String2.slice(artifactHash, ~from=0, ~to_=2)
  "objects/sha256/" ++ prefix ++ "/" ++ artifactHash ++ (kind == Text ? ".txt" : ".blob")
}

let candidateBody = (
  ~producerId: string,
  ~targetId: string,
  ~authorizationId: string,
  ~attempt: int,
  ~providerReceiptHash: string,
  ~packetHash: string,
  ~workOrderHash: string,
  ~artifactHash: string,
  ~kind: contentKind,
): string =>
  "{" ++
  "\"schema\":\"production-candidate/v2\"," ++
  "\"producerId\":" ++
  q(producerId) ++
  "," ++
  "\"targetId\":" ++
  q(targetId) ++
  "," ++
  "\"authorizationId\":" ++
  q(authorizationId) ++
  "," ++
  "\"attempt\":" ++
  Belt.Int.toString(attempt) ++
  "," ++
  "\"providerReceiptHash\":" ++
  q(providerReceiptHash) ++
  "," ++
  "\"packetHash\":" ++
  q(packetHash) ++
  "," ++
  "\"workOrderHash\":" ++
  q(workOrderHash) ++
  "," ++
  "\"artifactHash\":" ++
  q(artifactHash) ++
  "," ++
  "\"contentKind\":" ++
  q(kindString(kind)) ++ "}"

let candidateFromBody = (~store: store, ~expectedHash: string, body: string): candidate => {
  if B.sha256Text(body) != expectedHash {
    fail("candidate record hash mismatch for " ++ expectedHash)
  }
  let object_ = body->Js.Json.parseExn->Js.Json.decodeObject->Belt.Option.getExn
  let field = name =>
    Js.Dict.get(object_, name)
    ->Belt.Option.flatMap(Js.Json.decodeString)
    ->Belt.Option.getWithDefault("")
  if field("schema") != "production-candidate/v2" {
    fail("candidate record has an unsupported schema")
  }
  let packetHash = field("packetHash")
  let producerId = field("producerId")
  let targetId = field("targetId")
  let authorizationId = field("authorizationId")
  let providerReceiptHash = field("providerReceiptHash")
  let attempt = switch Js.Dict.get(object_, "attempt")->Belt.Option.flatMap(Js.Json.decodeNumber) {
  | Some(value) => {
      let integer = Js.Math.floor_int(value)
      if Belt.Int.toFloat(integer) != value {
        fail("candidate attempt must be a positive global attempt number")
      }
      integer
    }
  | None => fail("candidate attempt must be a positive global attempt number")
  }
  let workOrderHash = field("workOrderHash")
  let artifactHash = field("artifactHash")
  requireHash("candidate packetHash", packetHash)
  requireHash("candidate workOrderHash", workOrderHash)
  requireHash("candidate artifactHash", artifactHash)
  requireAuthorizationId("candidate authorizationId", authorizationId)
  requirePositiveAttempt("candidate attempt", attempt)
  requireHash("candidate providerReceiptHash", providerReceiptHash)
  requireNonempty("candidate producerId", producerId)
  requireNonempty("candidate targetId", targetId)
  let contentKind = field("contentKind")->kindFromString
  let objectPath = safePath(
    store,
    objectRelativePath(artifactHash, contentKind),
    "candidate object " ++ artifactHash,
  )
  if !B.exists(B.Path(objectPath)) || B.sha256File(B.Path(objectPath)) != artifactHash {
    fail("candidate object is missing or corrupt for " ++ expectedHash)
  }
  {
    candidateHash: expectedHash,
    producerId,
    targetId,
    authorizationId,
    attempt,
    providerReceiptHash,
    packetHash,
    workOrderHash,
    artifactHash,
    contentKind,
    objectPath,
  }
}

let persistCandidate = (
  ~store: store,
  ~producerId: string,
  ~targetId: string,
  ~authorizationId: string,
  ~attempt: int,
  ~providerReceiptHash: string,
  ~packetHash: string,
  ~workOrderHash: string,
  ~artifactHash: string,
  ~kind: contentKind,
): candidate => {
  requireHash("packetHash", packetHash)
  requireHash("workOrderHash", workOrderHash)
  requireHash("artifactHash", artifactHash)
  requireAuthorizationId("authorizationId", authorizationId)
  requirePositiveAttempt("attempt", attempt)
  requireHash("providerReceiptHash", providerReceiptHash)
  requireNonempty("producerId", producerId)
  requireNonempty("targetId", targetId)
  let body = candidateBody(
    ~producerId,
    ~targetId,
    ~authorizationId,
    ~attempt,
    ~providerReceiptHash,
    ~packetHash,
    ~workOrderHash,
    ~artifactHash,
    ~kind,
  )
  let candidateHash = B.sha256Text(body)
  let _ = writeImmutableText(
    store,
    "records/candidates/" ++ candidateHash ++ ".json",
    "candidate record " ++ candidateHash,
    body,
  )
  candidateFromBody(~store, ~expectedHash=candidateHash, body)
}

let openStore = (~root, ~reviewBatchSize) => {
  if reviewBatchSize <= 0 {
    fail("reviewBatchSize must be greater than zero")
  }
  let absolute = resolvePath(root)
  B.ensureDirPath(B.Path(absolute))
  {root: absolute, reviewBatchSize}
}

let putTextCandidate = (
  ~store,
  ~producerId,
  ~targetId,
  ~authorizationId,
  ~attempt,
  ~providerReceiptHash,
  ~packetHash,
  ~workOrderHash,
  ~text,
) => {
  requireAuthorizationId("authorizationId", authorizationId)
  requirePositiveAttempt("attempt", attempt)
  requireHash("providerReceiptHash", providerReceiptHash)
  let artifactHash = B.sha256Text(text)
  let _ = writeImmutableText(
    store,
    objectRelativePath(artifactHash, Text),
    "text object " ++ artifactHash,
    text,
  )
  persistCandidate(
    ~store,
    ~producerId,
    ~targetId,
    ~authorizationId,
    ~attempt,
    ~providerReceiptHash,
    ~packetHash,
    ~workOrderHash,
    ~artifactHash,
    ~kind=Text,
  )
}

let putFileCandidate = (
  ~store,
  ~producerId,
  ~targetId,
  ~authorizationId,
  ~attempt,
  ~providerReceiptHash,
  ~packetHash,
  ~workOrderHash,
  ~sourcePath,
) => {
  requireAuthorizationId("authorizationId", authorizationId)
  requirePositiveAttempt("attempt", attempt)
  requireHash("providerReceiptHash", providerReceiptHash)
  requireHash("packetHash", packetHash)
  requireHash("workOrderHash", workOrderHash)
  if !B.exists(B.Path(sourcePath)) {
    fail("candidate source file does not exist: " ++ sourcePath)
  }
  let artifactHash = B.sha256File(B.Path(sourcePath))
  let relativePath = objectRelativePath(artifactHash, File)
  let destination = ensureSafeParent(store, relativePath, "file object " ++ artifactHash)
  if B.exists(B.Path(destination)) {
    if B.sha256File(B.Path(destination)) != artifactHash {
      fail("file object path collides with different bytes for " ++ artifactHash)
    }
  } else {
    /* The permanent claim makes one writer the sole owner. A crash leaves a
       visible, fail-closed claim/corrupt object rather than permitting another
       process to overwrite unknown bytes. */
    let claimBody =
      "{\"schema\":\"production-object-claim/v1\",\"artifactHash\":" ++ q(artifactHash) ++ "}"
    let claimPath = ensureSafeParent(
      store,
      "claims/objects/" ++ artifactHash ++ ".json",
      "file object claim " ++ artifactHash,
    )
    if !B.writeTextExclusive(B.Path(claimPath), claimBody) {
      if !B.exists(B.Path(destination)) {
        fail("file object has an incomplete immutable claim for " ++ artifactHash)
      }
      if B.sha256File(B.Path(destination)) != artifactHash {
        fail("claimed file object is corrupt for " ++ artifactHash)
      }
    } else {
      /* Reserve the destination exclusively before the byte-for-byte copy.
       Only this claim owner may replace its own zero-byte reservation. */
      if !B.writeTextExclusive(B.Path(destination), "") {
        fail("file object destination was occupied after its claim: " ++ destination)
      }
      B.copyFile(B.Path(sourcePath), B.Path(destination))
      if B.sha256File(B.Path(destination)) != artifactHash {
        fail("file object changed during import: " ++ sourcePath)
      }
    }
  }
  persistCandidate(
    ~store,
    ~producerId,
    ~targetId,
    ~authorizationId,
    ~attempt,
    ~providerReceiptHash,
    ~packetHash,
    ~workOrderHash,
    ~artifactHash,
    ~kind=File,
  )
}

let inspectionBody = (
  ~candidate: candidate,
  ~reportHash: string,
  ~inspectorId: string,
  ~verdict: inspectionVerdict,
): string =>
  "{" ++
  "\"schema\":\"production-inspection/v1\"," ++
  "\"candidateHash\":" ++
  q(candidate.candidateHash) ++
  "," ++
  "\"packetHash\":" ++
  q(candidate.packetHash) ++
  "," ++
  "\"workOrderHash\":" ++
  q(candidate.workOrderHash) ++
  "," ++
  "\"artifactHash\":" ++
  q(candidate.artifactHash) ++
  "," ++
  "\"reportHash\":" ++
  q(reportHash) ++
  "," ++
  "\"inspectorId\":" ++
  q(inspectorId) ++
  "," ++
  "\"verdict\":" ++
  q(verdictString(verdict)) ++ "}"

let inspectionFromBody = (~expectedHash: string, body: string): inspection => {
  if B.sha256Text(body) != expectedHash {
    fail("inspection record hash mismatch for " ++ expectedHash)
  }
  let object_ = body->Js.Json.parseExn->Js.Json.decodeObject->Belt.Option.getExn
  let field = name =>
    Js.Dict.get(object_, name)
    ->Belt.Option.flatMap(Js.Json.decodeString)
    ->Belt.Option.getWithDefault("")
  let row = {
    inspectionHash: expectedHash,
    candidateHash: field("candidateHash"),
    packetHash: field("packetHash"),
    workOrderHash: field("workOrderHash"),
    artifactHash: field("artifactHash"),
    reportHash: field("reportHash"),
    inspectorId: field("inspectorId"),
    verdict: field("verdict")->verdictFromString,
  }
  requireHash("inspection candidateHash", row.candidateHash)
  requireHash("inspection packetHash", row.packetHash)
  requireHash("inspection workOrderHash", row.workOrderHash)
  requireHash("inspection artifactHash", row.artifactHash)
  requireHash("inspection reportHash", row.reportHash)
  requireNonempty("inspection inspectorId", row.inspectorId)
  row
}

let candidateBindingsMatch = (
  candidate: candidate,
  packetHash: string,
  workOrderHash: string,
  artifactHash: string,
) =>
  candidate.packetHash == packetHash &&
  candidate.workOrderHash == workOrderHash &&
  candidate.artifactHash == artifactHash

let ensureKnownCandidate = (store: store, candidate: candidate) => {
  let path = safePath(
    store,
    "records/candidates/" ++ candidate.candidateHash ++ ".json",
    "candidate record " ++ candidate.candidateHash,
  )
  if !B.exists(B.Path(path)) {
    fail("candidate is not recorded in this store: " ++ candidate.candidateHash)
  }
  let stored = candidateFromBody(
    ~store,
    ~expectedHash=candidate.candidateHash,
    B.readText(B.Path(path)),
  )
  if (
    !candidateBindingsMatch(
      stored,
      candidate.packetHash,
      candidate.workOrderHash,
      candidate.artifactHash,
    ) ||
    stored.producerId != candidate.producerId ||
    stored.targetId != candidate.targetId ||
    stored.authorizationId != candidate.authorizationId ||
    stored.attempt != candidate.attempt ||
    stored.providerReceiptHash != candidate.providerReceiptHash
  ) {
    fail("candidate bindings do not match the immutable store record")
  }
}

let recordInspection = (
  ~store: store,
  ~candidate: candidate,
  ~reportText: string,
  ~inspectorId: string,
  ~verdict: inspectionVerdict,
): inspection => {
  ensureKnownCandidate(store, candidate)
  requireNonempty("inspectorId", inspectorId)
  let reportHash = B.sha256Text(reportText)
  let _ = writeImmutableText(
    store,
    "reports/sha256/" ++
    Js.String2.slice(reportHash, ~from=0, ~to_=2) ++
    "/" ++
    reportHash ++ ".txt",
    "inspection report " ++ reportHash,
    reportText,
  )
  let body = inspectionBody(~candidate, ~reportHash, ~inspectorId, ~verdict)
  let inspectionHash = B.sha256Text(body)
  let _ = writeImmutableText(
    store,
    "records/inspections/" ++ inspectionHash ++ ".json",
    "inspection record " ++ inspectionHash,
    body,
  )
  inspectionFromBody(~expectedHash=inspectionHash, body)
}

let decodeStringArray = (object_, name) =>
  Js.Dict.get(object_, name)
  ->Belt.Option.flatMap(Js.Json.decodeArray)
  ->Belt.Option.getWithDefault([])
  ->Belt.Array.map(value => value->Js.Json.decodeString->Belt.Option.getWithDefault(""))

let recordFiles = (store: store, relativeDir: string, label: string): array<string> =>
  readDirectory(store, relativeDir, label)
  ->Belt.Array.keep(name => Js.String2.endsWith(name, ".json"))
  ->Js.Array2.sortInPlace

let hashFromRecordName = name => Js.String2.slice(name, ~from=0, ~to_=Js.String2.length(name) - 5)

let listCandidates = (store: store): array<candidate> =>
  recordFiles(store, "records/candidates", "candidate records")->Belt.Array.map(name => {
    let expectedHash = hashFromRecordName(name)
    requireHash("candidate record filename", expectedHash)
    let path = safePath(store, "records/candidates/" ++ name, "candidate record " ++ name)
    candidateFromBody(~store, ~expectedHash, B.readText(B.Path(path)))
  })

let listInspections = (store: store): array<inspection> =>
  recordFiles(store, "records/inspections", "inspection records")->Belt.Array.map(name => {
    let expectedHash = hashFromRecordName(name)
    requireHash("inspection record filename", expectedHash)
    let path = safePath(store, "records/inspections/" ++ name, "inspection record " ++ name)
    let inspection = inspectionFromBody(~expectedHash, B.readText(B.Path(path)))
    let reportPath = safePath(
      store,
      "reports/sha256/" ++
      Js.String2.slice(inspection.reportHash, ~from=0, ~to_=2) ++
      "/" ++
      inspection.reportHash ++ ".txt",
      "inspection report " ++ inspection.reportHash,
    )
    if !B.exists(B.Path(reportPath)) || B.sha256File(B.Path(reportPath)) != inspection.reportHash {
      fail("inspection report is missing or corrupt for " ++ inspection.inspectionHash)
    }
    let candidatePath = safePath(
      store,
      "records/candidates/" ++ inspection.candidateHash ++ ".json",
      "inspection candidate " ++ inspection.candidateHash,
    )
    if !B.exists(B.Path(candidatePath)) {
      fail("inspection refers to an unknown candidate " ++ inspection.candidateHash)
    }
    let candidate = candidateFromBody(
      ~store,
      ~expectedHash=inspection.candidateHash,
      B.readText(B.Path(candidatePath)),
    )
    if (
      !candidateBindingsMatch(
        candidate,
        inspection.packetHash,
        inspection.workOrderHash,
        inspection.artifactHash,
      )
    ) {
      fail("inspection authority bindings differ from its candidate " ++ inspection.inspectionHash)
    }
    inspection
  })

let reportHashesFor = (store: store, candidateHash: string): array<string> =>
  listInspections(store)
  ->Belt.Array.keep(row => row.candidateHash == candidateHash)
  ->Belt.Array.map(row => row.reportHash)
  ->sortedStrings

let dispositionBody = (
  ~candidate: candidate,
  ~kind: dispositionKind,
  ~reason: string,
  ~supersededBy: option<string>,
  ~reportHashes: array<string>,
): string =>
  "{" ++
  "\"schema\":\"production-disposition/v1\"," ++
  "\"candidateHash\":" ++
  q(candidate.candidateHash) ++
  "," ++
  "\"packetHash\":" ++
  q(candidate.packetHash) ++
  "," ++
  "\"workOrderHash\":" ++
  q(candidate.workOrderHash) ++
  "," ++
  "\"artifactHash\":" ++
  q(candidate.artifactHash) ++
  "," ++
  "\"reportHashes\":[" ++
  stringArrayJson(reportHashes) ++
  "]," ++
  "\"kind\":" ++
  q(dispositionString(kind)) ++
  "," ++
  "\"reason\":" ++
  q(reason) ++
  "," ++
  "\"supersededBy\":" ++
  switch supersededBy {
  | Some(hash) => q(hash)
  | None => "null"
  } ++ "}"

let dispositionFromBody = (~expectedHash: string, body: string): disposition => {
  if B.sha256Text(body) != expectedHash {
    fail("disposition record hash mismatch for " ++ expectedHash)
  }
  let object_ = body->Js.Json.parseExn->Js.Json.decodeObject->Belt.Option.getExn
  let field = name =>
    Js.Dict.get(object_, name)
    ->Belt.Option.flatMap(Js.Json.decodeString)
    ->Belt.Option.getWithDefault("")
  let supersededBy = Js.Dict.get(object_, "supersededBy")->Belt.Option.flatMap(Js.Json.decodeString)
  let row = {
    dispositionHash: expectedHash,
    candidateHash: field("candidateHash"),
    packetHash: field("packetHash"),
    workOrderHash: field("workOrderHash"),
    artifactHash: field("artifactHash"),
    kind: field("kind")->dispositionFromString,
    reason: field("reason"),
    supersededBy,
    reportHashes: decodeStringArray(object_, "reportHashes")->sortedStrings,
  }
  requireHash("disposition candidateHash", row.candidateHash)
  requireHash("disposition packetHash", row.packetHash)
  requireHash("disposition workOrderHash", row.workOrderHash)
  requireHash("disposition artifactHash", row.artifactHash)
  row.reportHashes->Belt.Array.forEach(hash => requireHash("disposition reportHash", hash))
  row
}

let listDispositions = (store: store): array<disposition> => {
  let candidates = listCandidates(store)
  recordFiles(store, "records/dispositions", "disposition records")->Belt.Array.map(name => {
    let expectedHash = hashFromRecordName(name)
    requireHash("disposition record filename", expectedHash)
    let path = safePath(store, "records/dispositions/" ++ name, "disposition record " ++ name)
    let row = dispositionFromBody(~expectedHash, B.readText(B.Path(path)))
    switch candidates->Belt.Array.getBy(candidate => candidate.candidateHash == row.candidateHash) {
    | None => fail("disposition refers to an unknown candidate " ++ row.candidateHash)
    | Some(candidate)
      if !candidateBindingsMatch(candidate, row.packetHash, row.workOrderHash, row.artifactHash) =>
      fail("disposition authority bindings differ from its candidate " ++ row.dispositionHash)
    | Some(_) => ()
    }
    row
  })
}

let recordDisposition = (
  ~store: store,
  ~candidate: candidate,
  ~kind: dispositionKind,
  ~reason: string,
  ~supersededBy: option<string>,
): disposition => {
  ensureKnownCandidate(store, candidate)
  requireNonempty("disposition reason", reason)
  switch (kind, supersededBy) {
  | (Superseded, Some(hash)) => requireHash("supersededBy", hash)
  | (Superseded, None) => fail("a superseded disposition requires supersededBy")
  | (_, Some(_)) => fail("supersededBy is allowed only for a superseded disposition")
  | (_, None) => ()
  }
  let reportHashes = reportHashesFor(store, candidate.candidateHash)
  let body = dispositionBody(~candidate, ~kind, ~reason, ~supersededBy, ~reportHashes)
  let dispositionHash = B.sha256Text(body)
  let _ = writeImmutableText(
    store,
    "records/dispositions/" ++ dispositionHash ++ ".json",
    "disposition record " ++ dispositionHash,
    body,
  )
  dispositionFromBody(~expectedHash=dispositionHash, body)
}

let entryBody = (entry: reviewEntry): string =>
  "{" ++
  "\"candidateHash\":" ++
  q(entry.candidateHash) ++
  "," ++
  "\"targetId\":" ++
  q(entry.targetId) ++
  "," ++
  "\"packetHash\":" ++
  q(entry.packetHash) ++
  "," ++
  "\"workOrderHash\":" ++
  q(entry.workOrderHash) ++
  "," ++
  "\"artifactHash\":" ++
  q(entry.artifactHash) ++
  "," ++
  "\"reportHashes\":[" ++
  stringArrayJson(entry.reportHashes) ++
  "]" ++ "}"

let batchBody = (~targetId, ~entries: array<reviewEntry>): string =>
  "{\"schema\":\"production-review-batch/v1\",\"targetId\":" ++ q(targetId) ++ ",\"entries\":[" ++
  entries->Belt.Array.map(entryBody)->Js.Array2.joinWith(",") ++ "]}"

let entryFromJson = (value: Js.Json.t): reviewEntry => {
  let object_ = value->Js.Json.decodeObject->Belt.Option.getExn
  let field = name =>
    Js.Dict.get(object_, name)
    ->Belt.Option.flatMap(Js.Json.decodeString)
    ->Belt.Option.getWithDefault("")
  let entry = {
    candidateHash: field("candidateHash"),
    targetId: field("targetId"),
    packetHash: field("packetHash"),
    workOrderHash: field("workOrderHash"),
    artifactHash: field("artifactHash"),
    reportHashes: decodeStringArray(object_, "reportHashes")->sortedStrings,
  }
  requireHash("review entry candidateHash", entry.candidateHash)
  requireNonempty("review entry targetId", entry.targetId)
  requireHash("review entry packetHash", entry.packetHash)
  requireHash("review entry workOrderHash", entry.workOrderHash)
  requireHash("review entry artifactHash", entry.artifactHash)
  entry.reportHashes->Belt.Array.forEach(hash => requireHash("review entry reportHash", hash))
  entry
}

let batchFromBody = (~expectedHash: string, body: string): reviewBatch => {
  if B.sha256Text(body) != expectedHash {
    fail("review batch hash mismatch for " ++ expectedHash)
  }
  let object_ = body->Js.Json.parseExn->Js.Json.decodeObject->Belt.Option.getExn
  let targetId = Js.Dict.get(object_, "targetId")
    ->Belt.Option.flatMap(Js.Json.decodeString)
    ->Belt.Option.getWithDefault("")
  requireNonempty("review batch targetId", targetId)
  let entries =
    Js.Dict.get(object_, "entries")
    ->Belt.Option.flatMap(Js.Json.decodeArray)
    ->Belt.Option.getWithDefault([])
    ->Belt.Array.map(entryFromJson)
  if !(entries->Belt.Array.every(entry => entry.targetId == targetId)) {
    fail("review batch contains an entry for a different target")
  }
  {batchHash: expectedHash, targetId, entries}
}

let listReviewBatches = (store: store): array<reviewBatch> => {
  let batches =
    recordFiles(store, "records/review-batches", "review batch records")->Belt.Array.map(name => {
    let expectedHash = hashFromRecordName(name)
    requireHash("review batch filename", expectedHash)
    let path = safePath(store, "records/review-batches/" ++ name, "review batch " ++ name)
    batchFromBody(~expectedHash, B.readText(B.Path(path)))
  })
  let claimedBy: Js.Dict.t<string> = Js.Dict.empty()
  batches->Belt.Array.forEach(batch =>
    batch.entries->Belt.Array.forEach(entry => {
      switch Js.Dict.get(claimedBy, entry.candidateHash) {
      | Some(existingBatch) =>
        fail(
          "candidate " ++ entry.candidateHash ++ " is claimed by multiple review-batch entries: " ++
          existingBatch ++ " and " ++ batch.batchHash,
        )
      | None => Js.Dict.set(claimedBy, entry.candidateHash, batch.batchHash)
      }
    })
  )
  batches
}

let evidenceEntry = (candidate: candidate, inspections: array<inspection>): option<reviewEntry> => {
  let matching =
    inspections->Belt.Array.keep(row =>
      row.candidateHash == candidate.candidateHash &&
      row.packetHash == candidate.packetHash &&
      row.workOrderHash == candidate.workOrderHash &&
      row.artifactHash == candidate.artifactHash
    )
  let hasPass = matching->Belt.Array.some(row => row.verdict == Pass)
  let hasNonPass = matching->Belt.Array.some(row => row.verdict != Pass)
  if hasPass && !hasNonPass {
    Some({
      candidateHash: candidate.candidateHash,
      targetId: candidate.targetId,
      packetHash: candidate.packetHash,
      workOrderHash: candidate.workOrderHash,
      artifactHash: candidate.artifactHash,
      reportHashes: matching->Belt.Array.map(row => row.reportHash)->sortedStrings,
    })
  } else {
    None
  }
}

let entryEqual = (left: reviewEntry, right: reviewEntry): bool =>
  entryBody(left) == entryBody(right)

let createReviewBatchUnderLease = (~store, ~targetId, ~packetHash, ~workOrderHash) => {
  requireNonempty("review targetId", targetId)
  requireHash("review packetHash", packetHash)
  requireHash("review workOrderHash", workOrderHash)
  let inspections = listInspections(store)
  let dispositions = listDispositions(store)
  let alreadyBatched =
    listReviewBatches(store)
    ->Belt.Array.flatMap(batch => batch.entries)
    ->Belt.Array.map(entry => entry.candidateHash)
  let entries =
    listCandidates(store)
    ->Belt.Array.keep(candidate =>
      candidate.targetId == targetId && candidate.packetHash == packetHash &&
      candidate.workOrderHash == workOrderHash &&
      !(alreadyBatched->Belt.Array.some(hash => hash == candidate.candidateHash)) &&
      !(dispositions->Belt.Array.some(row => row.candidateHash == candidate.candidateHash))
    )
    ->Belt.Array.keepMap(candidate => evidenceEntry(candidate, inspections))
    ->Js.Array2.sortInPlaceWith((left, right) =>
      left.candidateHash < right.candidateHash
        ? -1
        : left.candidateHash > right.candidateHash
        ? 1
        : 0
    )
    ->Belt.Array.slice(~offset=0, ~len=store.reviewBatchSize)
  if Belt.Array.length(entries) == 0 {
    None
  } else {
    let body = batchBody(~targetId, ~entries)
    let batchHash = B.sha256Text(body)
    let _ = writeImmutableText(
      store,
      "records/review-batches/" ++ batchHash ++ ".json",
      "review batch " ++ batchHash,
      body,
    )
    Some({batchHash, targetId, entries})
  }
}

let createReviewBatch = (~store, ~targetId, ~packetHash, ~workOrderHash) =>
  try {
    L.withLease(
      ~stateDir=store.root,
      ~relativePath="leases/review-batches.sqlite",
      ~resource="artifact review-batch claim",
      ~waitMs=10000,
      () => createReviewBatchUnderLease(~store, ~targetId, ~packetHash, ~workOrderHash),
    )
  } catch {
  | L.LeaseError(message) => fail("review batch claim could not be serialized: " ++ message)
  }

let reviewBody = (
  ~batchHash: string,
  ~entry: reviewEntry,
  ~reviewerId: string,
  ~decision: reviewDecision,
  ~note: string,
): string =>
  "{" ++
  "\"schema\":\"production-review/v1\"," ++
  "\"batchHash\":" ++
  q(batchHash) ++
  "," ++
  "\"candidateHash\":" ++
  q(entry.candidateHash) ++
  "," ++
  "\"targetId\":" ++
  q(entry.targetId) ++
  "," ++
  "\"packetHash\":" ++
  q(entry.packetHash) ++
  "," ++
  "\"workOrderHash\":" ++
  q(entry.workOrderHash) ++
  "," ++
  "\"artifactHash\":" ++
  q(entry.artifactHash) ++
  "," ++
  "\"reportHashes\":[" ++
  stringArrayJson(entry.reportHashes) ++
  "]," ++
  "\"reviewerId\":" ++
  q(reviewerId) ++
  "," ++
  "\"decision\":" ++
  q(decisionString(decision)) ++
  "," ++
  "\"note\":" ++
  q(note) ++ "}"

let reviewFromBody = (~expectedHash: string, body: string): reviewRecord => {
  if B.sha256Text(body) != expectedHash {
    fail("review record hash mismatch for " ++ expectedHash)
  }
  let object_ = body->Js.Json.parseExn->Js.Json.decodeObject->Belt.Option.getExn
  let field = name =>
    Js.Dict.get(object_, name)
    ->Belt.Option.flatMap(Js.Json.decodeString)
    ->Belt.Option.getWithDefault("")
  let row = {
    reviewHash: expectedHash,
    batchHash: field("batchHash"),
    candidateHash: field("candidateHash"),
    targetId: field("targetId"),
    packetHash: field("packetHash"),
    workOrderHash: field("workOrderHash"),
    artifactHash: field("artifactHash"),
    reportHashes: decodeStringArray(object_, "reportHashes")->sortedStrings,
    reviewerId: field("reviewerId"),
    decision: field("decision")->decisionFromString,
    note: field("note"),
  }
  requireHash("review batchHash", row.batchHash)
  requireHash("review candidateHash", row.candidateHash)
  requireNonempty("review targetId", row.targetId)
  requireHash("review packetHash", row.packetHash)
  requireHash("review workOrderHash", row.workOrderHash)
  requireHash("review artifactHash", row.artifactHash)
  row.reportHashes->Belt.Array.forEach(hash => requireHash("review reportHash", hash))
  requireNonempty("review reviewerId", row.reviewerId)
  row
}

let listReviews = (store: store): array<reviewRecord> =>
  recordFiles(store, "records/reviews", "review records")->Belt.Array.map(name => {
    let candidateHash = hashFromRecordName(name)
    requireHash("review record filename", candidateHash)
    let path = safePath(store, "records/reviews/" ++ name, "review record " ++ name)
    let body = B.readText(B.Path(path))
    let object_ = body->Js.Json.parseExn->Js.Json.decodeObject->Belt.Option.getExn
    let expectedHash =
      Js.Dict.get(object_, "reviewHash")
      ->Belt.Option.flatMap(Js.Json.decodeString)
      ->Belt.Option.getWithDefault("")
    /* Stored review bodies deliberately omit their own recursive hash. The
       path is keyed by candidate for first-decision-wins, while this envelope
       carries the content hash beside the canonical body. */
    let canonical =
      Js.Dict.get(object_, "body")
      ->Belt.Option.flatMap(Js.Json.decodeString)
      ->Belt.Option.getWithDefault("")
    requireHash("stored reviewHash", expectedHash)
    reviewFromBody(~expectedHash, canonical)
  })

let recordReview = (~store, ~batchHash, ~candidateHash, ~reviewerId, ~decision, ~note) => {
  requireHash("batchHash", batchHash)
  requireHash("candidateHash", candidateHash)
  requireNonempty("reviewerId", reviewerId)
  let batch =
    listReviewBatches(store)
    ->Belt.Array.getBy(batch => batch.batchHash == batchHash)
    ->Belt.Option.getWithDefault({batchHash: "", targetId: "", entries: []})
  if batch.batchHash == "" {
    fail("unknown review batch " ++ batchHash)
  }
  let entry =
    batch.entries
    ->Belt.Array.getBy(entry => entry.candidateHash == candidateHash)
    ->Belt.Option.getWithDefault({
      candidateHash: "",
      targetId: "",
      packetHash: "",
      workOrderHash: "",
      artifactHash: "",
      reportHashes: [],
    })
  if entry.candidateHash == "" {
    fail("candidate " ++ candidateHash ++ " is not in review batch " ++ batchHash)
  }
  let candidate =
    listCandidates(store)
    ->Belt.Array.getBy(candidate => candidate.candidateHash == candidateHash)
    ->Belt.Option.getWithDefault({
      candidateHash: "",
      producerId: "",
      targetId: "",
      authorizationId: "",
      attempt: 0,
      providerReceiptHash: "",
      packetHash: "",
      workOrderHash: "",
      artifactHash: "",
      contentKind: Text,
      objectPath: "",
    })
  if candidate.candidateHash == "" {
    fail("review candidate no longer exists in the immutable store")
  }
  if listDispositions(store)->Belt.Array.some(row => row.candidateHash == candidateHash) {
    fail("candidate acquired a disposition after batching and cannot be reviewed")
  }
  let currentEntry = evidenceEntry(candidate, listInspections(store))
  switch currentEntry {
  | None => fail("candidate no longer has pass-only inspection evidence")
  | Some(current) if !entryEqual(current, entry) =>
    fail("candidate inspection evidence changed after batching")
  | Some(_) => ()
  }
  let body = reviewBody(~batchHash, ~entry, ~reviewerId, ~decision, ~note)
  let reviewHash = B.sha256Text(body)
  let envelope = "{\"reviewHash\":" ++ q(reviewHash) ++ ",\"body\":" ++ q(body) ++ "}"
  let _ = writeImmutableText(
    store,
    "records/reviews/" ++ candidateHash ++ ".json",
    "review decision for " ++ candidateHash,
    envelope,
  )
  reviewFromBody(~expectedHash=reviewHash, body)
}
