module B = Cinema_Backends
module D = Production_Domain
module O = Production_OutputSafety
module L = Production_Lease

exception JournalError(string)

type status =
  | Claimed
  | Submitting
  | CandidateQuarantine
  | StaleQuarantine
  | Failed
  | BlockedPreSubmit
  | InterruptedUnknown

type authorizationRecord = {
  authorizationId: string,
  recordHash: string,
  targetId: string,
  packetHash: string,
  workOrderHash: string,
  providerId: string,
  providerPrincipalId: string,
  authorizerPrincipalId: string,
  commandId: string,
  authorizedEventId: string,
  dependencyProofHash: string,
  referenceSetHash: string,
  maxAttempts: int,
}
type authorizationIntent = AuthorizationIntent(authorizationRecord)

type transition = {
  transitionId: string,
  recordHash: string,
  authorizationId: string,
  targetId: string,
  packetHash: string,
  workOrderHash: string,
  attempt: int,
  sequence: int,
  previousTransitionId: option<string>,
  status: status,
  candidateHash: option<string>,
  artifactHash: option<string>,
  providerReceiptHash: option<string>,
  reason: string,
}

type attemptRecord = {
  authorizationId: string,
  targetId: string,
  attempt: int,
  transitions: array<transition>,
  current: transition,
}

type snapshot = {
  authorizations: array<authorizationRecord>,
  attempts: array<attemptRecord>,
}

type recoveryKind =
  | UnclaimedAuthorization
  | InterruptedBeforeSubmit
  | InterruptedDuringSubmit
  | Terminal(status)

type recoveryClassification = {
  authorizationId: string,
  targetId: string,
  attempt: option<int>,
  kind: recoveryKind,
}

@module("node:path") external dirname: string => string = "dirname"
@module("node:path") external join2: (string, string) => string = "join"

let die = message => raise(JournalError(message))

let statusName = status =>
  switch status {
  | Claimed => "claimed"
  | Submitting => "submitting"
  | CandidateQuarantine => "candidate_quarantine"
  | StaleQuarantine => "stale_quarantine"
  | Failed => "failed"
  | BlockedPreSubmit => "blocked_pre_submit"
  | InterruptedUnknown => "interrupted_unknown"
  }

let statusOf = value =>
  switch value {
  | "claimed" => Claimed
  | "submitting" => Submitting
  | "candidate_quarantine" => CandidateQuarantine
  | "stale_quarantine" => StaleQuarantine
  | "failed" => Failed
  | "blocked_pre_submit" => BlockedPreSubmit
  | "interrupted_unknown" => InterruptedUnknown
  | other => die("unknown execution-journal status '" ++ other ++ "'")
  }

let recoveryKindName = kind =>
  switch kind {
  | UnclaimedAuthorization => "unclaimed_authorization"
  | InterruptedBeforeSubmit => "interrupted_before_submit"
  | InterruptedDuringSubmit => "interrupted_during_submit"
  | Terminal(status) => "terminal:" ++ statusName(status)
  }

let isTerminal = status =>
  switch status {
  | CandidateQuarantine
  | StaleQuarantine
  | Failed
  | BlockedPreSubmit
  | InterruptedUnknown => true
  | Claimed | Submitting => false
  }

let retryableTerminal = status => status == Failed || status == BlockedPreSubmit

let isHexHash = value =>
  Js.String2.length(value) == 64 &&
    value
    ->Js.String2.split("")
    ->Belt.Array.every(character => Js.String2.includes("0123456789abcdef", character))

let requireHash = (value, label) => {
  if !isHexHash(value) {
    die(label ++ " must be a lowercase SHA-256 hash")
  }
  value
}

let requireText = (value, label) => {
  if Js.String2.trim(value) == "" || Js.String2.includes(value, "\u{0000}") {
    die(label ++ " must be a nonempty string without NUL bytes")
  }
  value
}

let safeAuthorizationId = value => {
  if !Js.String2.startsWith(value, "AUTH-") || !isHexHash(Js.String2.sliceToEnd(value, ~from=5)) {
    die("authorizationId must be AUTH- followed by its lowercase SHA-256 hash")
  }
  value
}

let safeTransitionId = value => {
  if !Js.String2.startsWith(value, "JEV-") || !isHexHash(Js.String2.sliceToEnd(value, ~from=4)) {
    die("transitionId must be JEV- followed by its lowercase SHA-256 hash")
  }
  value
}

let authSemanticJson = (
  ~targetId,
  ~packetHash,
  ~workOrderHash,
  ~providerId,
  ~providerPrincipalId,
  ~authorizerPrincipalId,
  ~commandId,
  ~authorizedEventId,
  ~dependencyProofHash,
  ~referenceSetHash,
  ~maxAttempts,
) => {
  let row = Js.Dict.empty()
  Js.Dict.set(row, "schema", Js.Json.string("production.execution-authorization/v1"))
  Js.Dict.set(row, "targetId", Js.Json.string(targetId))
  Js.Dict.set(row, "packetHash", Js.Json.string(packetHash))
  Js.Dict.set(row, "workOrderHash", Js.Json.string(workOrderHash))
  Js.Dict.set(row, "providerId", Js.Json.string(providerId))
  Js.Dict.set(row, "providerPrincipalId", Js.Json.string(providerPrincipalId))
  Js.Dict.set(row, "authorizerPrincipalId", Js.Json.string(authorizerPrincipalId))
  Js.Dict.set(row, "commandId", Js.Json.string(commandId))
  Js.Dict.set(row, "authorizedEventId", Js.Json.string(authorizedEventId))
  Js.Dict.set(row, "dependencyProofHash", Js.Json.string(dependencyProofHash))
  Js.Dict.set(row, "referenceSetHash", Js.Json.string(referenceSetHash))
  Js.Dict.set(row, "maxAttempts", Js.Json.number(Belt.Int.toFloat(maxAttempts)))
  Js.Json.object_(row)
}

let deriveAuthorizationData = (
  ~targetId,
  ~packetHash,
  ~workOrderHash,
  ~providerId,
  ~providerPrincipalId,
  ~authorizerPrincipalId,
  ~commandId,
  ~authorizedEventId,
  ~dependencyProofHash,
  ~referenceSetHash,
  ~maxAttempts,
) => {
  let targetId = requireText(targetId, "authorization targetId")
  let packetHash = requireHash(packetHash, "authorization packetHash")
  let workOrderHash = requireHash(workOrderHash, "authorization workOrderHash")
  let providerId = requireText(providerId, "authorization providerId")
  let providerPrincipalId = requireText(providerPrincipalId, "authorization providerPrincipalId")
  let authorizerPrincipalId = requireText(
    authorizerPrincipalId,
    "authorization authorizerPrincipalId",
  )
  let commandId = requireText(commandId, "authorization commandId")
  let authorizedEventId = requireText(authorizedEventId, "authorization authorizedEventId")
  let dependencyProofHash = requireHash(dependencyProofHash, "authorization dependencyProofHash")
  let referenceSetHash = requireHash(referenceSetHash, "authorization referenceSetHash")
  if maxAttempts < 1 {
    die("authorization maxAttempts must be a positive integer")
  }
  let semantic = authSemanticJson(
    ~targetId,
    ~packetHash,
    ~workOrderHash,
    ~providerId,
    ~providerPrincipalId,
    ~authorizerPrincipalId,
    ~commandId,
    ~authorizedEventId,
    ~dependencyProofHash,
    ~referenceSetHash,
    ~maxAttempts,
  )
  let recordHash = B.sha256Text(D.canonicalJson(semantic))
  {
    authorizationId: "AUTH-" ++ recordHash,
    recordHash,
    targetId,
    packetHash,
    workOrderHash,
    providerId,
    providerPrincipalId,
    authorizerPrincipalId,
    commandId,
    authorizedEventId,
    dependencyProofHash,
    referenceSetHash,
    maxAttempts,
  }
}

let createAuthorizationIntent = (
  ~targetId,
  ~packetHash,
  ~workOrderHash,
  ~providerId,
  ~providerPrincipalId,
  ~authorizerPrincipalId,
  ~commandId,
  ~authorizedEventId,
  ~dependencyProofHash,
  ~referenceSetHash,
  ~maxAttempts,
) => AuthorizationIntent(
  deriveAuthorizationData(
    ~targetId,
    ~packetHash,
    ~workOrderHash,
    ~providerId,
    ~providerPrincipalId,
    ~authorizerPrincipalId,
    ~commandId,
    ~authorizedEventId,
    ~dependencyProofHash,
    ~referenceSetHash,
    ~maxAttempts,
  ),
)

let intentId = intent => {
  let AuthorizationIntent(data) = intent
  data.authorizationId
}

let authRecordJson = (record: authorizationRecord) => {
  let semantic = authSemanticJson(
    ~targetId=record.targetId,
    ~packetHash=record.packetHash,
    ~workOrderHash=record.workOrderHash,
    ~providerId=record.providerId,
    ~providerPrincipalId=record.providerPrincipalId,
    ~authorizerPrincipalId=record.authorizerPrincipalId,
    ~commandId=record.commandId,
    ~authorizedEventId=record.authorizedEventId,
    ~dependencyProofHash=record.dependencyProofHash,
    ~referenceSetHash=record.referenceSetHash,
    ~maxAttempts=record.maxAttempts,
  )
  let row = semantic->Js.Json.decodeObject->Belt.Option.getExn
  Js.Dict.set(row, "authorizationId", Js.Json.string(record.authorizationId))
  Js.Dict.set(row, "recordHash", Js.Json.string(record.recordHash))
  Js.Json.object_(row)
}

let encodeAuthorization = record => D.canonicalJson(authRecordJson(record)) ++ "\n"

let transitionSemanticJson = (
  ~authorizationId,
  ~targetId,
  ~packetHash,
  ~workOrderHash,
  ~attempt,
  ~sequence,
  ~previousTransitionId,
  ~status,
  ~candidateHash,
  ~artifactHash,
  ~providerReceiptHash,
  ~reason,
) => {
  let row = Js.Dict.empty()
  Js.Dict.set(row, "schema", Js.Json.string("production.execution-transition/v1"))
  Js.Dict.set(row, "authorizationId", Js.Json.string(authorizationId))
  Js.Dict.set(row, "targetId", Js.Json.string(targetId))
  Js.Dict.set(row, "packetHash", Js.Json.string(packetHash))
  Js.Dict.set(row, "workOrderHash", Js.Json.string(workOrderHash))
  Js.Dict.set(row, "attempt", Js.Json.number(Belt.Int.toFloat(attempt)))
  Js.Dict.set(row, "sequence", Js.Json.number(Belt.Int.toFloat(sequence)))
  switch previousTransitionId {
  | Some(value) => Js.Dict.set(row, "previousTransitionId", Js.Json.string(value))
  | None => ()
  }
  Js.Dict.set(row, "status", Js.Json.string(statusName(status)))
  switch candidateHash {
  | Some(value) => Js.Dict.set(row, "candidateHash", Js.Json.string(value))
  | None => ()
  }
  switch artifactHash {
  | Some(value) => Js.Dict.set(row, "artifactHash", Js.Json.string(value))
  | None => ()
  }
  switch providerReceiptHash {
  | Some(value) => Js.Dict.set(row, "providerReceiptHash", Js.Json.string(value))
  | None => ()
  }
  Js.Dict.set(row, "reason", Js.Json.string(reason))
  Js.Json.object_(row)
}

let transitionJson = (transition: transition) => {
  let semantic = transitionSemanticJson(
    ~authorizationId=transition.authorizationId,
    ~targetId=transition.targetId,
    ~packetHash=transition.packetHash,
    ~workOrderHash=transition.workOrderHash,
    ~attempt=transition.attempt,
    ~sequence=transition.sequence,
    ~previousTransitionId=transition.previousTransitionId,
    ~status=transition.status,
    ~candidateHash=transition.candidateHash,
    ~artifactHash=transition.artifactHash,
    ~providerReceiptHash=transition.providerReceiptHash,
    ~reason=transition.reason,
  )
  let row = semantic->Js.Json.decodeObject->Belt.Option.getExn
  Js.Dict.set(row, "transitionId", Js.Json.string(transition.transitionId))
  Js.Dict.set(row, "recordHash", Js.Json.string(transition.recordHash))
  Js.Json.object_(row)
}

let encodeTransition = transition => D.canonicalJson(transitionJson(transition)) ++ "\n"

let safe = (~stateDir, ~relative, ~label) => {
  B.ensureDirPath(B.Path(stateDir))
  try O.manifestOutputPath(~baseDir=stateDir, ~relativePath=relative, ~label) catch {
  | O.OutputSafetyError(message) => die(message)
  }
}

let journalRoot = stateDir =>
  safe(~stateDir, ~relative="execution-journal", ~label="execution journal directory")

let authorizationDir = stateDir =>
  safe(
    ~stateDir,
    ~relative="execution-journal/authorizations",
    ~label="execution authorization directory",
  )

let transitionDir = stateDir =>
  safe(
    ~stateDir,
    ~relative="execution-journal/transitions",
    ~label="execution transition directory",
  )

let ensureLayout = stateDir => {
  B.ensureDirPath(B.Path(stateDir))
  B.ensureDirPath(B.Path(journalRoot(stateDir)))
  B.ensureDirPath(B.Path(authorizationDir(stateDir)))
  B.ensureDirPath(B.Path(transitionDir(stateDir)))
}

let withLock = (stateDir, work) => {
  ensureLayout(stateDir)
  try {
    L.withLease(
      ~stateDir,
      ~relativePath="leases/execution-journal.sqlite",
      ~legacyRelativePath="execution-journal/journal.lock",
      ~resource="execution journal",
      work,
    )
  } catch {
  | L.LeaseError(message) => die("execution journal lease refused: " ++ message)
  }
}

let writeImmutableAtomic = (~stateDir, ~directory, ~filename, ~body, ~label) => {
  let destination = safe(
    ~stateDir,
    ~relative="execution-journal/" ++ directory ++ "/" ++ filename,
    ~label,
  )
  let pending = safe(
    ~stateDir,
    ~relative="execution-journal/" ++ directory ++ "/." ++ filename ++ ".pending",
    ~label="pending " ++ label,
  )
  B.ensureDirPath(B.Path(dirname(destination)))
  if B.exists(B.Path(destination)) {
    if B.readText(B.Path(destination)) != body {
      die(label ++ " collides with different immutable content")
    }
  } else {
    if (
      !B.writeTextExclusive(B.Path(pending), body) &&
      (!B.exists(B.Path(pending)) || B.readText(B.Path(pending)) != body)
    ) {
      die("pending " ++ label ++ " collides with different immutable content")
    }
    try O.atomicRename(~temporaryPath=pending, ~destinationPath=destination) catch {
    | Js.Exn.Error(error) =>
      die(
        "could not atomically commit " ++
        label ++
        ": " ++
        Js.Exn.message(error)->Belt.Option.getWithDefault("unknown filesystem error"),
      )
    }
    if !B.exists(B.Path(destination)) || B.readText(B.Path(destination)) != body {
      die(label ++ " did not commit byte-for-byte")
    }
  }
}

let obj = (json, where) =>
  switch Js.Json.decodeObject(json) {
  | Some(value) => value
  | None => die(where ++ " must be a JSON object")
  }

let parse = (raw, where) =>
  try Js.Json.parseExn(raw)->obj(where) catch {
  | JournalError(message) => raise(JournalError(message))
  | _ => die(where ++ " must be valid JSON")
  }

let requireAllowedKeys = (row, allowed, required, where) => {
  Js.Dict.keys(row)->Belt.Array.forEach(key =>
    if !(allowed->Belt.Array.some(candidate => candidate == key)) {
      die(where ++ " contains unknown field '" ++ key ++ "'")
    }
  )
  required->Belt.Array.forEach(key =>
    if Js.Dict.get(row, key) == None {
      die(where ++ " is missing required field '" ++ key ++ "'")
    }
  )
}

let reqString = (row, key, where) =>
  switch Js.Dict.get(row, key)->Belt.Option.flatMap(Js.Json.decodeString) {
  | Some(value) => requireText(value, where ++ "." ++ key)
  | None => die(where ++ "." ++ key ++ " must be a string")
  }

let optString = (row, key, where) =>
  switch Js.Dict.get(row, key) {
  | None => None
  | Some(json) =>
    switch Js.Json.decodeString(json) {
    | Some(value) => Some(requireText(value, where ++ "." ++ key))
    | None => die(where ++ "." ++ key ++ " must be a string when present")
    }
  }

let reqPositiveInt = (row, key, where) =>
  switch Js.Dict.get(row, key)->Belt.Option.flatMap(Js.Json.decodeNumber) {
  | Some(value) => {
      let integer = Js.Math.floor_int(value)
      if integer < 1 || Belt.Int.toFloat(integer) != value {
        die(where ++ "." ++ key ++ " must be a positive integer")
      }
      integer
    }
  | None => die(where ++ "." ++ key ++ " must be a positive integer")
  }

let requireSchema = (row, expected, where) => {
  if reqString(row, "schema", where) != expected {
    die(where ++ " has an unsupported schema")
  }
}

let authorizationAllowedFields = [
  "schema",
  "authorizationId",
  "recordHash",
  "targetId",
  "packetHash",
  "workOrderHash",
  "providerId",
  "providerPrincipalId",
  "authorizerPrincipalId",
  "commandId",
  "authorizedEventId",
  "dependencyProofHash",
  "referenceSetHash",
  "maxAttempts",
]

let decodeAuthorization = (~raw, ~filename) => {
  let where = "execution authorization " ++ filename
  let row = parse(raw, where)
  requireAllowedKeys(row, authorizationAllowedFields, authorizationAllowedFields, where)
  requireSchema(row, "production.execution-authorization/v1", where)
  let declaredId = reqString(row, "authorizationId", where)->safeAuthorizationId
  let declaredHash = reqString(row, "recordHash", where)->requireHash(where ++ ".recordHash")
  let derived = deriveAuthorizationData(
    ~targetId=reqString(row, "targetId", where),
    ~packetHash=reqString(row, "packetHash", where),
    ~workOrderHash=reqString(row, "workOrderHash", where),
    ~providerId=reqString(row, "providerId", where),
    ~providerPrincipalId=reqString(row, "providerPrincipalId", where),
    ~authorizerPrincipalId=reqString(row, "authorizerPrincipalId", where),
    ~commandId=reqString(row, "commandId", where),
    ~authorizedEventId=reqString(row, "authorizedEventId", where),
    ~dependencyProofHash=reqString(row, "dependencyProofHash", where),
    ~referenceSetHash=reqString(row, "referenceSetHash", where),
    ~maxAttempts=reqPositiveInt(row, "maxAttempts", where),
  )
  if declaredId != derived.authorizationId || declaredHash != derived.recordHash {
    die(where ++ " fails its canonical content hash")
  }
  let expectedFilename = derived.authorizationId ++ ".json"
  if filename != expectedFilename {
    die(where ++ " filename must be " ++ expectedFilename)
  }
  let record: authorizationRecord = derived
  if raw != encodeAuthorization(record) {
    die(where ++ " is not byte-for-byte canonical JSON")
  }
  record
}

let transitionAllowedFields = [
  "schema",
  "transitionId",
  "recordHash",
  "authorizationId",
  "targetId",
  "packetHash",
  "workOrderHash",
  "attempt",
  "sequence",
  "previousTransitionId",
  "status",
  "candidateHash",
  "artifactHash",
  "providerReceiptHash",
  "reason",
]

let transitionRequiredFields = [
  "schema",
  "transitionId",
  "recordHash",
  "authorizationId",
  "targetId",
  "packetHash",
  "workOrderHash",
  "attempt",
  "sequence",
  "status",
  "reason",
]

let validateEvidence = (~status, ~candidateHash, ~artifactHash, ~providerReceiptHash, ~where) => {
  switch status {
  | CandidateQuarantine | StaleQuarantine =>
    switch (candidateHash, artifactHash, providerReceiptHash) {
    | (Some(candidate), Some(artifact), Some(receipt)) => {
        requireHash(candidate, where ++ ".candidateHash")->ignore
        requireHash(artifact, where ++ ".artifactHash")->ignore
        requireHash(receipt, where ++ ".providerReceiptHash")->ignore
      }
    | _ =>
      die(
        where ++
        " in " ++
        statusName(status) ++ " requires candidateHash, artifactHash, and providerReceiptHash",
      )
    }
  | Claimed | Submitting | Failed | BlockedPreSubmit | InterruptedUnknown =>
    if candidateHash != None || artifactHash != None || providerReceiptHash != None {
      die(where ++ " in " ++ statusName(status) ++ " must not claim candidate evidence")
    }
  }
}

let deriveTransition = (
  ~authorization: authorizationRecord,
  ~attempt,
  ~sequence,
  ~previousTransitionId,
  ~status,
  ~candidateHash,
  ~artifactHash,
  ~providerReceiptHash,
  ~reason,
) => {
  if attempt < 1 || sequence < 1 {
    die("execution transition attempt and sequence must be positive integers")
  }
  switch previousTransitionId {
  | Some(value) => safeTransitionId(value)->ignore
  | None => ()
  }
  let reason = requireText(reason, "execution transition reason")
  validateEvidence(
    ~status,
    ~candidateHash,
    ~artifactHash,
    ~providerReceiptHash,
    ~where="execution transition",
  )
  let semantic = transitionSemanticJson(
    ~authorizationId=authorization.authorizationId,
    ~targetId=authorization.targetId,
    ~packetHash=authorization.packetHash,
    ~workOrderHash=authorization.workOrderHash,
    ~attempt,
    ~sequence,
    ~previousTransitionId,
    ~status,
    ~candidateHash,
    ~artifactHash,
    ~providerReceiptHash,
    ~reason,
  )
  let recordHash = B.sha256Text(D.canonicalJson(semantic))
  {
    transitionId: "JEV-" ++ recordHash,
    recordHash,
    authorizationId: authorization.authorizationId,
    targetId: authorization.targetId,
    packetHash: authorization.packetHash,
    workOrderHash: authorization.workOrderHash,
    attempt,
    sequence,
    previousTransitionId,
    status,
    candidateHash,
    artifactHash,
    providerReceiptHash,
    reason,
  }
}

let transitionFilename = (transition: transition) =>
  transition.authorizationId ++
  "-attempt-" ++
  Belt.Int.toString(transition.attempt) ++
  "-step-" ++
  Belt.Int.toString(transition.sequence) ++
  "-" ++
  transition.transitionId ++ ".json"

let decodeTransition = (~raw, ~filename) => {
  let where = "execution transition " ++ filename
  let row = parse(raw, where)
  requireAllowedKeys(row, transitionAllowedFields, transitionRequiredFields, where)
  requireSchema(row, "production.execution-transition/v1", where)
  let transitionId = reqString(row, "transitionId", where)->safeTransitionId
  let recordHash = reqString(row, "recordHash", where)->requireHash(where ++ ".recordHash")
  let authorizationId = reqString(row, "authorizationId", where)->safeAuthorizationId
  let previousTransitionId = optString(row, "previousTransitionId", where)
  switch previousTransitionId {
  | Some(value) => safeTransitionId(value)->ignore
  | None => ()
  }
  let status = statusOf(reqString(row, "status", where))
  let candidateHash = optString(row, "candidateHash", where)
  let artifactHash = optString(row, "artifactHash", where)
  let providerReceiptHash = optString(row, "providerReceiptHash", where)
  validateEvidence(~status, ~candidateHash, ~artifactHash, ~providerReceiptHash, ~where)
  let rawTransition: transition = {
    transitionId,
    recordHash,
    authorizationId,
    targetId: reqString(row, "targetId", where),
    packetHash: reqString(row, "packetHash", where)->requireHash(where ++ ".packetHash"),
    workOrderHash: reqString(row, "workOrderHash", where)->requireHash(where ++ ".workOrderHash"),
    attempt: reqPositiveInt(row, "attempt", where),
    sequence: reqPositiveInt(row, "sequence", where),
    previousTransitionId,
    status,
    candidateHash,
    artifactHash,
    providerReceiptHash,
    reason: reqString(row, "reason", where),
  }
  let semantic = transitionSemanticJson(
    ~authorizationId=rawTransition.authorizationId,
    ~targetId=rawTransition.targetId,
    ~packetHash=rawTransition.packetHash,
    ~workOrderHash=rawTransition.workOrderHash,
    ~attempt=rawTransition.attempt,
    ~sequence=rawTransition.sequence,
    ~previousTransitionId=rawTransition.previousTransitionId,
    ~status=rawTransition.status,
    ~candidateHash=rawTransition.candidateHash,
    ~artifactHash=rawTransition.artifactHash,
    ~providerReceiptHash=rawTransition.providerReceiptHash,
    ~reason=rawTransition.reason,
  )
  let expectedHash = B.sha256Text(D.canonicalJson(semantic))
  if (
    rawTransition.recordHash != expectedHash || rawTransition.transitionId != "JEV-" ++ expectedHash
  ) {
    die(where ++ " fails its canonical content hash")
  }
  let expectedFilename = transitionFilename(rawTransition)
  if filename != expectedFilename {
    die(where ++ " filename must be " ++ expectedFilename)
  }
  if raw != encodeTransition(rawTransition) {
    die(where ++ " is not byte-for-byte canonical JSON")
  }
  rawTransition
}

let committedFiles = (~directory, ~label) => {
  B.readDir(B.Path(directory))
  ->Belt.Array.keepMap(name => {
    if Js.String2.startsWith(name, ".") && Js.String2.endsWith(name, ".pending") {
      None
    } else if Js.String2.endsWith(name, ".json") {
      Some(name)
    } else {
      die(label ++ " contains unexpected entry '" ++ name ++ "'")
    }
  })
  ->Js.Array2.sortInPlaceWith(compare)
}

let legalTransition = (from, next) =>
  switch (from, next) {
  | (Claimed, Submitting)
  | (Claimed, BlockedPreSubmit)
  | (Submitting, CandidateQuarantine)
  | (Submitting, StaleQuarantine)
  | (Submitting, Failed)
  | (Submitting, InterruptedUnknown) => true
  | _ => false
  }

let loadUnlocked = (~stateDir) => {
  ensureLayout(stateDir)
  let authorizations =
    committedFiles(
      ~directory=authorizationDir(stateDir),
      ~label="execution authorization directory",
    )->Belt.Array.map(filename =>
      decodeAuthorization(
        ~raw=B.readText(B.Path(join2(authorizationDir(stateDir), filename))),
        ~filename,
      )
    )
  authorizations
  ->Js.Array2.sortInPlaceWith((left, right) => compare(left.authorizationId, right.authorizationId))
  ->ignore
  let authorizationById = Js.Dict.empty()
  authorizations->Belt.Array.forEach(record => {
    if Js.Dict.get(authorizationById, record.authorizationId) != None {
      die("duplicate execution authorization '" ++ record.authorizationId ++ "'")
    }
    Js.Dict.set(authorizationById, record.authorizationId, record)
  })

  let transitions =
    committedFiles(
      ~directory=transitionDir(stateDir),
      ~label="execution transition directory",
    )->Belt.Array.map(filename =>
      decodeTransition(~raw=B.readText(B.Path(join2(transitionDir(stateDir), filename))), ~filename)
    )
  let transitionIds = Js.Dict.empty()
  let grouped: Js.Dict.t<array<transition>> = Js.Dict.empty()
  transitions->Belt.Array.forEach(transition => {
    if Js.Dict.get(transitionIds, transition.transitionId) != None {
      die("duplicate execution transition '" ++ transition.transitionId ++ "'")
    }
    Js.Dict.set(transitionIds, transition.transitionId, true)
    let authorization = switch Js.Dict.get(authorizationById, transition.authorizationId) {
    | Some(value) => value
    | None =>
      die("transition refers to missing authorization '" ++ transition.authorizationId ++ "'")
    }
    if transition.attempt > authorization.maxAttempts {
      die("execution transition exceeds its immutable authorization attempt ceiling")
    }
    if (
      transition.targetId != authorization.targetId ||
      transition.packetHash != authorization.packetHash ||
      transition.workOrderHash != authorization.workOrderHash
    ) {
      die("transition authority does not match its immutable authorization")
    }
    let key = transition.authorizationId ++ "\u{001f}" ++ Belt.Int.toString(transition.attempt)
    let rows = Js.Dict.get(grouped, key)->Belt.Option.getWithDefault([])
    Js.Dict.set(grouped, key, Belt.Array.concat(rows, [transition]))
  })

  let attempts = Js.Dict.values(grouped)->Belt.Array.map(rows => {
    rows->Js.Array2.sortInPlaceWith((left, right) => left.sequence - right.sequence)->ignore
    let first = rows->Belt.Array.get(0)->Belt.Option.getExn
    let previous = ref(None)
    rows->Belt.Array.forEachWithIndex((index, transition) => {
      let expectedSequence = index + 1
      if transition.sequence != expectedSequence {
        die(
          "attempt " ++
          Belt.Int.toString(first.attempt) ++
          " for " ++
          first.authorizationId ++ " has a missing or ambiguous transition sequence",
        )
      }
      if transition.previousTransitionId != previous.contents {
        die("execution transition chain is branched or does not name its exact predecessor")
      }
      if index == 0 {
        if transition.status != Claimed {
          die("the first transition of every execution attempt must be claimed")
        }
      } else {
        let prior = rows->Belt.Array.get(index - 1)->Belt.Option.getExn
        if !legalTransition(prior.status, transition.status) {
          die(
            "illegal execution transition " ++
            statusName(prior.status) ++
            " -> " ++
            statusName(transition.status),
          )
        }
      }
      previous := Some(transition.transitionId)
    })
    {
      authorizationId: first.authorizationId,
      targetId: first.targetId,
      attempt: first.attempt,
      transitions: rows,
      current: rows->Belt.Array.get(Belt.Array.length(rows) - 1)->Belt.Option.getExn,
    }
  })
  attempts
  ->Js.Array2.sortInPlaceWith((left, right) => {
    let byAuthorization = compare(left.authorizationId, right.authorizationId)
    byAuthorization == 0 ? left.attempt - right.attempt : byAuthorization
  })
  ->ignore

  authorizations->Belt.Array.forEach(authorization => {
    let own =
      attempts->Belt.Array.keep(attempt => attempt.authorizationId == authorization.authorizationId)
    if Belt.Array.length(own) > 1 {
      die(
        "single-use authorization " ++
        authorization.authorizationId ++ " was consumed by more than one attempt",
      )
    }
  })
  let attemptsByAuthority: Js.Dict.t<array<attemptRecord>> = Js.Dict.empty()
  attempts->Belt.Array.forEach(attempt => {
    let authorization = Js.Dict.get(authorizationById, attempt.authorizationId)->Belt.Option.getExn
    let key = authorization.targetId ++ "\u{001f}" ++ authorization.workOrderHash
    let rows = Js.Dict.get(attemptsByAuthority, key)->Belt.Option.getWithDefault([])
    Js.Dict.set(attemptsByAuthority, key, Belt.Array.concat(rows, [attempt]))
  })
  Js.Dict.values(attemptsByAuthority)->Belt.Array.forEach(own => {
    own->Js.Array2.sortInPlaceWith((left, right) => left.attempt - right.attempt)->ignore
    own->Belt.Array.forEachWithIndex((index, attempt) => {
      let expectedAttempt = index + 1
      if attempt.attempt != expectedAttempt {
        die("target/work-order authority has a missing or ambiguous attempt number")
      }
      if index < Belt.Array.length(own) - 1 && !retryableTerminal(attempt.current.status) {
        die(
          "target/work-order authority continued after status " ++
          statusName(attempt.current.status),
        )
      }
    })
    let inFlight = own->Belt.Array.keep(attempt => !isTerminal(attempt.current.status))
    if Belt.Array.length(inFlight) > 1 {
      die("target/work-order authority has ambiguous in-flight attempts")
    }
    switch Belt.Array.get(inFlight, 0) {
    | Some(openAttempt) if openAttempt.attempt != Belt.Array.length(own) =>
      die("target/work-order authority has an older unfinished attempt followed by another attempt")
    | _ => ()
    }
  })
  {authorizations, attempts}
}

let load = (~stateDir) => loadUnlocked(~stateDir)

let persistAuthorization = (~stateDir, ~intent) => {
  let AuthorizationIntent(data) = intent
  let record: authorizationRecord = data
  withLock(stateDir, () => {
    let snapshot = loadUnlocked(~stateDir)
    switch snapshot.authorizations->Belt.Array.getBy(existing =>
      existing.authorizationId == record.authorizationId
    ) {
    | Some(existing) => {
        if encodeAuthorization(existing) != encodeAuthorization(record) {
          die("authorization id collides with different immutable content")
        }
        existing
      }
    | None => {
        writeImmutableAtomic(
          ~stateDir,
          ~directory="authorizations",
          ~filename=record.authorizationId ++ ".json",
          ~body=encodeAuthorization(record),
          ~label="execution authorization",
        )
        loadUnlocked(~stateDir)->ignore
        record
      }
    }
  })
}

let sameRequestedTransition = (
  current: transition,
  ~status,
  ~candidateHash,
  ~artifactHash,
  ~providerReceiptHash,
  ~reason,
) =>
  current.status == status &&
  current.candidateHash == candidateHash &&
  current.artifactHash == artifactHash &&
  current.providerReceiptHash == providerReceiptHash &&
  current.reason == reason

let recordStatusUnlocked = (
  ~stateDir,
  ~authorizationId,
  ~attempt,
  ~status,
  ~candidateHash,
  ~artifactHash,
  ~providerReceiptHash,
  ~reason,
) => {
  safeAuthorizationId(authorizationId)->ignore
  if attempt < 1 {
    die("execution attempt must be a positive integer")
  }
  validateEvidence(
    ~status,
    ~candidateHash,
    ~artifactHash,
    ~providerReceiptHash,
    ~where="requested execution transition",
  )
  let snapshot = loadUnlocked(~stateDir)
  let authorization = switch snapshot.authorizations->Belt.Array.getBy(record =>
    record.authorizationId == authorizationId
  ) {
  | Some(value) => value
  | None => die("cannot record an attempt for missing authorization '" ++ authorizationId ++ "'")
  }
  if attempt > authorization.maxAttempts {
    die("execution attempt exceeds its immutable authorization attempt ceiling")
  }
  let own = snapshot.attempts->Belt.Array.keep(row => row.authorizationId == authorizationId)
  let authorityAttempts = snapshot.attempts->Belt.Array.keep(row => {
    let rowAuthorization =
      snapshot.authorizations
      ->Belt.Array.getBy(candidate => candidate.authorizationId == row.authorizationId)
      ->Belt.Option.getExn
    rowAuthorization.targetId == authorization.targetId &&
      rowAuthorization.workOrderHash == authorization.workOrderHash
  })
  let existing = own->Belt.Array.getBy(row => row.attempt == attempt)
  let transition = switch existing {
  | None => {
      if status != Claimed {
        die("a new execution attempt must begin with claimed")
      }
      if Belt.Array.length(own) != 0 {
        die("a single-use authorization cannot claim another attempt")
      }
      if attempt != Belt.Array.length(authorityAttempts) + 1 {
        die("target/work-order attempts must be claimed contiguously")
      }
      switch Belt.Array.get(authorityAttempts, Belt.Array.length(authorityAttempts) - 1) {
      | Some(previousAttempt) if !retryableTerminal(previousAttempt.current.status) =>
        die(
          "a new attempt cannot follow " ++
          statusName(
            previousAttempt.current.status,
          ) ++ " under the same target/work-order authority",
        )
      | _ => ()
      }
      deriveTransition(
        ~authorization,
        ~attempt,
        ~sequence=1,
        ~previousTransitionId=None,
        ~status,
        ~candidateHash,
        ~artifactHash,
        ~providerReceiptHash,
        ~reason,
      )
    }
  | Some(row) => {
      let current = row.current
      if (
        sameRequestedTransition(
          current,
          ~status,
          ~candidateHash,
          ~artifactHash,
          ~providerReceiptHash,
          ~reason,
        )
      ) {
        current
      } else {
        if isTerminal(current.status) {
          die("cannot append after terminal execution status " ++ statusName(current.status))
        }
        if !legalTransition(current.status, status) {
          die(
            "illegal execution transition " ++
            statusName(current.status) ++
            " -> " ++
            statusName(status),
          )
        }
        deriveTransition(
          ~authorization,
          ~attempt,
          ~sequence=current.sequence + 1,
          ~previousTransitionId=Some(current.transitionId),
          ~status,
          ~candidateHash,
          ~artifactHash,
          ~providerReceiptHash,
          ~reason,
        )
      }
    }
  }
  let alreadyCommitted = switch existing {
  | Some(row) => row.current.transitionId == transition.transitionId
  | None => false
  }
  if !alreadyCommitted {
    writeImmutableAtomic(
      ~stateDir,
      ~directory="transitions",
      ~filename=transitionFilename(transition),
      ~body=encodeTransition(transition),
      ~label="execution transition",
    )
    loadUnlocked(~stateDir)->ignore
  }
  transition
}

let recordStatus = (
  ~stateDir,
  ~authorizationId,
  ~attempt,
  ~status,
  ~candidateHash=?,
  ~artifactHash=?,
  ~providerReceiptHash=?,
  ~reason,
) =>
  withLock(stateDir, () =>
    recordStatusUnlocked(
      ~stateDir,
      ~authorizationId,
      ~attempt,
      ~status,
      ~candidateHash,
      ~artifactHash,
      ~providerReceiptHash,
      ~reason,
    )
  )

let claimNextAttempt = (~stateDir, ~authorizationId, ~reason) =>
  withLock(stateDir, () => {
    let snapshot = loadUnlocked(~stateDir)
    let authorization = switch snapshot.authorizations->Belt.Array.getBy(record =>
      record.authorizationId == authorizationId
    ) {
    | Some(value) => value
    | None => die("cannot claim an attempt for missing authorization '" ++ authorizationId ++ "'")
    }
    let maxAttempts = authorization.maxAttempts
    let existing =
      snapshot.attempts->Belt.Array.getBy(row => row.authorizationId == authorizationId)
    switch existing {
    | Some(row) => {
        let originalClaim = row.transitions->Belt.Array.get(0)->Belt.Option.getExn
        if originalClaim.reason != reason {
          die("single-use authorization was already claimed with different immutable content")
        }
        if row.attempt > maxAttempts {
          die("recorded attempt exceeds the current attempt ceiling")
        }
        originalClaim
      }
    | None => {
        let authorityAttempts = snapshot.attempts->Belt.Array.keep(row => {
          let rowAuthorization =
            snapshot.authorizations
            ->Belt.Array.getBy(candidate => candidate.authorizationId == row.authorizationId)
            ->Belt.Option.getExn
          rowAuthorization.targetId == authorization.targetId &&
            rowAuthorization.workOrderHash == authorization.workOrderHash
        })
        let attempt = Belt.Array.length(authorityAttempts) + 1
        if attempt > maxAttempts {
          die(
            authorization.targetId ++
            " has consumed its " ++
            Belt.Int.toString(maxAttempts) ++ " execution attempts",
          )
        }
        recordStatusUnlocked(
          ~stateDir,
          ~authorizationId,
          ~attempt,
          ~status=Claimed,
          ~candidateHash=None,
          ~artifactHash=None,
          ~providerReceiptHash=None,
          ~reason,
        )
      }
    }
  })

let classify = snapshot => {
  let rows = Belt.Array.concatMany(
    snapshot.authorizations->Belt.Array.map(authorization => {
      let attempts =
        snapshot.attempts->Belt.Array.keep(attempt =>
          attempt.authorizationId == authorization.authorizationId
        )
      if Belt.Array.length(attempts) == 0 {
        [
          {
            authorizationId: authorization.authorizationId,
            targetId: authorization.targetId,
            attempt: None,
            kind: UnclaimedAuthorization,
          },
        ]
      } else {
        attempts->Belt.Array.map(attempt => {
          let kind = switch attempt.current.status {
          | Claimed => InterruptedBeforeSubmit
          | Submitting => InterruptedDuringSubmit
          | terminal => Terminal(terminal)
          }
          {
            authorizationId: authorization.authorizationId,
            targetId: authorization.targetId,
            attempt: Some(attempt.attempt),
            kind,
          }
        })
      }
    }),
  )
  rows
  ->Js.Array2.sortInPlaceWith((left, right) => {
    let byAuthorization = compare(left.authorizationId, right.authorizationId)
    if byAuthorization != 0 {
      byAuthorization
    } else {
      left.attempt->Belt.Option.getWithDefault(0) - right.attempt->Belt.Option.getWithDefault(0)
    }
  })
  ->ignore
  rows
}

let recoverInterrupted = (~stateDir) =>
  withLock(stateDir, () => {
    let before = loadUnlocked(~stateDir)
    classify(before)->Belt.Array.forEach(classification =>
      switch (classification.kind, classification.attempt) {
      | (InterruptedBeforeSubmit, Some(attempt)) =>
        recordStatusUnlocked(
          ~stateDir,
          ~authorizationId=classification.authorizationId,
          ~attempt,
          ~status=BlockedPreSubmit,
          ~candidateHash=None,
          ~artifactHash=None,
          ~providerReceiptHash=None,
          ~reason="restart recovery: execution stopped before provider submission",
        )->ignore
      | (InterruptedDuringSubmit, Some(attempt)) =>
        recordStatusUnlocked(
          ~stateDir,
          ~authorizationId=classification.authorizationId,
          ~attempt,
          ~status=InterruptedUnknown,
          ~candidateHash=None,
          ~artifactHash=None,
          ~providerReceiptHash=None,
          ~reason="restart recovery: provider outcome is unknown; retry is forbidden",
        )->ignore
      | _ => ()
      }
    )
    loadUnlocked(~stateDir)
  })
