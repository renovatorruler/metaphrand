module B = Cinema_Backends
module J = Production_ExecutionJournal
module O = Production_OutputSafety

let fail = message => {
  Js.log("FAIL - " ++ message)
  assert(false)
}

let check = (condition, message) =>
  if !condition {
    fail(message)
  }

let expectJournalError = (label, work) => {
  let refused = try {
    work()
    false
  } catch {
  | J.JournalError(_) => true
  }
  check(refused, label ++ ": expected JournalError")
}

let hash = label => B.sha256Text("synthetic execution journal: " ++ label)

let newState = label => {
  let B.Path(root) = B.tempDir("production-execution-journal-" ++ label ++ "-")
  let stateDir = root ++ "/state"
  B.ensureDirPath(B.Path(stateDir))
  stateDir
}

let intent = (~commandId="CMD-1", ~targetId="TARGET-SYNTHETIC", ~maxAttempts=3) =>
  J.createAuthorizationIntent(
    ~targetId,
    ~packetHash=hash("packet"),
    ~workOrderHash=hash("work order"),
    ~providerId="FAKE-ADAPTER",
    ~providerPrincipalId="PR-FAKE-PRODUCER",
    ~authorizerPrincipalId="PR-FAKE-AUTHORIZER",
    ~commandId,
    ~authorizedEventId="EVT-SYNTHETIC-AUTHORIZED",
    ~dependencyProofHash=hash("dependency proof set"),
    ~referenceSetHash=hash("immutable reference set"),
    ~maxAttempts,
  )

let authorizationDir = stateDir => stateDir ++ "/execution-journal/authorizations"
let transitionDir = stateDir => stateDir ++ "/execution-journal/transitions"

let committed = directory =>
  B.readDir(B.Path(directory))
  ->Belt.Array.keep(name => Js.String2.endsWith(name, ".json"))
  ->Js.Array2.sortInPlaceWith(compare)

let journalFingerprint = stateDir => {
  let authRows =
    committed(authorizationDir(stateDir))->Belt.Array.map(name =>
      name ++ "\n" ++ B.readText(B.Path(authorizationDir(stateDir) ++ "/" ++ name))
    )
  let transitionRows =
    committed(transitionDir(stateDir))->Belt.Array.map(name =>
      name ++ "\n" ++ B.readText(B.Path(transitionDir(stateDir) ++ "/" ++ name))
    )
  Belt.Array.concat(authRows, transitionRows)->Js.Array2.joinWith("\n---\n")->B.sha256Text
}

let current = (snapshot: J.snapshot, authorizationId, attempt) =>
  snapshot.attempts
  ->Belt.Array.getBy(row => row.authorizationId == authorizationId && row.attempt == attempt)
  ->Belt.Option.map(row => row.current)

let restartAndRecoveryTest = () => {
  let stateDir = newState("restart")
  let pendingIntent = intent()
  let authorization = J.persistAuthorization(~stateDir, ~intent=pendingIntent)
  let sameAuthorization = J.persistAuthorization(~stateDir, ~intent=pendingIntent)
  check(
    authorization.authorizationId == sameAuthorization.authorizationId &&
      authorization.recordHash == sameAuthorization.recordHash,
    "persisting identical authorization content must be idempotent",
  )
  let initial = J.load(~stateDir)
  check(
    Belt.Array.length(initial.authorizations) == 1 && Belt.Array.length(initial.attempts) == 0,
    "restart load must reconstruct an unclaimed authorization",
  )
  switch J.classify(initial) {
  | [{kind: J.UnclaimedAuthorization, attempt: None}] => ()
  | _ => fail("unclaimed authorization classification was not deterministic")
  }

  let claimed = J.claimNextAttempt(
    ~stateDir,
    ~authorizationId=authorization.authorizationId,
    ~reason="synthetic attempt claimed",
  )
  let claimedAgain = J.claimNextAttempt(
    ~stateDir,
    ~authorizationId=authorization.authorizationId,
    ~reason="synthetic attempt claimed",
  )
  check(
    claimed.transitionId == claimedAgain.transitionId &&
      Belt.Array.length(committed(transitionDir(stateDir))) == 1,
    "replaying the exact current transition must not append another record",
  )
  switch J.classify(J.load(~stateDir)) {
  | [{kind: J.InterruptedBeforeSubmit, attempt: Some(1)}] => ()
  | _ => fail("claimed attempt must classify as interrupted before submit on restart")
  }

  /* An arbitrary crash-left pending file is not committed authority. */
  B.writeText(
    B.Path(transitionDir(stateDir) ++ "/.orphan-crash-write.pending"),
    "not committed and deliberately malformed",
  )
  check(
    Belt.Array.length(J.load(~stateDir).attempts) == 1,
    "orphan pending file must be ignored by reconstruction",
  )

  let recovered = J.recoverInterrupted(~stateDir)
  switch current(recovered, authorization.authorizationId, 1) {
  | Some(row) =>
    check(
      row.status == J.BlockedPreSubmit,
      "restart must prove a merely claimed attempt was blocked before submission",
    )
  | None => fail("recovered claimed attempt disappeared")
  }
  let firstRecoveryFingerprint = journalFingerprint(stateDir)
  let recoveredAgain = J.recoverInterrupted(~stateDir)
  check(
    journalFingerprint(stateDir) == firstRecoveryFingerprint &&
      Belt.Array.length(recoveredAgain.attempts) == Belt.Array.length(recovered.attempts),
    "restart recovery must be state-idempotent",
  )
  expectJournalError("one authorization cannot claim two attempts", () =>
    J.recordStatus(
      ~stateDir,
      ~authorizationId=authorization.authorizationId,
      ~attempt=2,
      ~status=J.Claimed,
      ~reason="reuse the same authorization",
    )->ignore
  )

  /* A pre-submit block may be retried only with a new, independently authorized
   single-use command; its attempt count continues under the work order. */
  let retryAuthorization = J.persistAuthorization(~stateDir, ~intent=intent(~commandId="CMD-RETRY"))
  let secondClaim = J.claimNextAttempt(
    ~stateDir,
    ~authorizationId=retryAuthorization.authorizationId,
    ~reason="synthetic retry claimed",
  )
  check(secondClaim.attempt == 2, "new authorization must receive the next work-order attempt")
  J.recordStatus(
    ~stateDir,
    ~authorizationId=retryAuthorization.authorizationId,
    ~attempt=2,
    ~status=J.Submitting,
    ~reason="provider boundary about to be crossed",
  )->ignore
  switch J.classify(J.load(~stateDir))->Belt.Array.getBy(row =>
    row.authorizationId == retryAuthorization.authorizationId
  ) {
  | Some({kind: J.InterruptedDuringSubmit}) => ()
  | _ => fail("submitting attempt must classify as an unknown provider outcome")
  }
  let recoveredSubmission = J.recoverInterrupted(~stateDir)
  switch current(recoveredSubmission, retryAuthorization.authorizationId, 2) {
  | Some(row) =>
    check(
      row.status == J.InterruptedUnknown,
      "restart must quarantine an interrupted submission as unknown",
    )
  | None => fail("interrupted submission disappeared during recovery")
  }
  let unsafeRetryAuthorization = J.persistAuthorization(
    ~stateDir,
    ~intent=intent(~commandId="CMD-UNSAFE-RETRY"),
  )
  expectJournalError("unknown provider outcome cannot be retried", () =>
    J.claimNextAttempt(
      ~stateDir,
      ~authorizationId=unsafeRetryAuthorization.authorizationId,
      ~reason="unsafe retry",
    )->ignore
  )
}

let terminalEvidenceAndContractTest = () => {
  let stateDir = newState("terminal")
  let authorization = J.persistAuthorization(~stateDir, ~intent=intent(~commandId="CMD-TERMINAL"))
  J.recordStatus(
    ~stateDir,
    ~authorizationId=authorization.authorizationId,
    ~attempt=1,
    ~status=J.Claimed,
    ~reason="claim",
  )->ignore
  expectJournalError("candidate cannot appear before submitting", () =>
    J.recordStatus(
      ~stateDir,
      ~authorizationId=authorization.authorizationId,
      ~attempt=1,
      ~status=J.CandidateQuarantine,
      ~candidateHash=hash("candidate"),
      ~artifactHash=hash("artifact"),
      ~providerReceiptHash=hash("receipt"),
      ~reason="illegal skip",
    )->ignore
  )
  J.recordStatus(
    ~stateDir,
    ~authorizationId=authorization.authorizationId,
    ~attempt=1,
    ~status=J.Submitting,
    ~reason="submit",
  )->ignore
  expectJournalError("candidate evidence is mandatory", () =>
    J.recordStatus(
      ~stateDir,
      ~authorizationId=authorization.authorizationId,
      ~attempt=1,
      ~status=J.CandidateQuarantine,
      ~reason="missing hashes",
    )->ignore
  )
  J.recordStatus(
    ~stateDir,
    ~authorizationId=authorization.authorizationId,
    ~attempt=1,
    ~status=J.CandidateQuarantine,
    ~candidateHash=hash("candidate"),
    ~artifactHash=hash("artifact"),
    ~providerReceiptHash=hash("receipt"),
    ~reason="candidate preserved in quarantine",
  )->ignore
  expectJournalError("terminal candidate cannot be overwritten", () =>
    J.recordStatus(
      ~stateDir,
      ~authorizationId=authorization.authorizationId,
      ~attempt=1,
      ~status=J.Failed,
      ~reason="contradictory terminal state",
    )->ignore
  )
  switch J.classify(J.load(~stateDir)) {
  | [{kind: J.Terminal(J.CandidateQuarantine)}] => ()
  | _ => fail("candidate quarantine must be terminal and stable")
  }
  let before = journalFingerprint(stateDir)
  J.recoverInterrupted(~stateDir)->ignore
  check(journalFingerprint(stateDir) == before, "recovery must not rewrite terminal evidence")
}

let tamperedAuthorizationTest = () => {
  let stateDir = newState("tampered-authorization")
  let authorization = J.persistAuthorization(
    ~stateDir,
    ~intent=intent(~commandId="CMD-TAMPER-AUTH"),
  )
  let path = authorizationDir(stateDir) ++ "/" ++ authorization.authorizationId ++ ".json"
  let original = B.readText(B.Path(path))
  B.writeText(
    B.Path(path),
    Js.String2.replace(original, "TARGET-SYNTHETIC", "TARGET-SILENTLY-CHANGED"),
  )
  expectJournalError("authorization content tamper", () => J.load(~stateDir)->ignore)
}

let renamedTransitionTest = () => {
  let stateDir = newState("renamed-transition")
  let authorization = J.persistAuthorization(~stateDir, ~intent=intent(~commandId="CMD-RENAME"))
  J.recordStatus(
    ~stateDir,
    ~authorizationId=authorization.authorizationId,
    ~attempt=1,
    ~status=J.Claimed,
    ~reason="claim",
  )->ignore
  let name = committed(transitionDir(stateDir))->Belt.Array.get(0)->Belt.Option.getExn
  O.atomicRename(
    ~temporaryPath=transitionDir(stateDir) ++ "/" ++ name,
    ~destinationPath=transitionDir(stateDir) ++ "/renamed.json",
  )
  expectJournalError("transition filename tamper", () => J.load(~stateDir)->ignore)
}

let missingMiddleTransitionTest = () => {
  let stateDir = newState("missing-middle")
  let authorization = J.persistAuthorization(~stateDir, ~intent=intent(~commandId="CMD-MISSING"))
  J.recordStatus(
    ~stateDir,
    ~authorizationId=authorization.authorizationId,
    ~attempt=1,
    ~status=J.Claimed,
    ~reason="claim",
  )->ignore
  J.recordStatus(
    ~stateDir,
    ~authorizationId=authorization.authorizationId,
    ~attempt=1,
    ~status=J.Submitting,
    ~reason="submit",
  )->ignore
  let names = committed(transitionDir(stateDir))
  let first =
    names->Belt.Array.getBy(name => Js.String2.includes(name, "-step-1-"))->Belt.Option.getExn
  B.removeFile(B.Path(transitionDir(stateDir) ++ "/" ++ first))
  expectJournalError("missing middle transition", () => J.load(~stateDir)->ignore)
}

let ambiguousTransitionTest = () => {
  let stateDir = newState("ambiguous-main")
  let otherStateDir = newState("ambiguous-other")
  let sharedIntent = intent(~commandId="CMD-AMBIGUOUS")
  let firstAuthorization = J.persistAuthorization(~stateDir, ~intent=sharedIntent)
  let secondAuthorization = J.persistAuthorization(~stateDir=otherStateDir, ~intent=sharedIntent)
  check(
    firstAuthorization.authorizationId == secondAuthorization.authorizationId,
    "identical intents must have identical content-derived IDs",
  )
  J.recordStatus(
    ~stateDir,
    ~authorizationId=firstAuthorization.authorizationId,
    ~attempt=1,
    ~status=J.Claimed,
    ~reason="first valid branch",
  )->ignore
  J.recordStatus(
    ~stateDir=otherStateDir,
    ~authorizationId=secondAuthorization.authorizationId,
    ~attempt=1,
    ~status=J.Claimed,
    ~reason="second independently valid branch",
  )->ignore
  let otherName = committed(transitionDir(otherStateDir))->Belt.Array.get(0)->Belt.Option.getExn
  B.copyFile(
    B.Path(transitionDir(otherStateDir) ++ "/" ++ otherName),
    B.Path(transitionDir(stateDir) ++ "/" ++ otherName),
  )
  expectJournalError("two valid records for one sequence are ambiguous", () =>
    J.load(~stateDir)->ignore
  )
}

let unsafeAndUnknownEntryTest = () => {
  let stateDir = newState("unknown-entry")
  J.persistAuthorization(~stateDir, ~intent=intent(~commandId="CMD-ENTRY"))->ignore
  B.writeText(B.Path(authorizationDir(stateDir) ++ "/surprise.txt"), "hidden authority")
  expectJournalError("unknown committed directory entry", () => J.load(~stateDir)->ignore)

  expectJournalError("unsafe hash refused before persistence", () =>
    J.createAuthorizationIntent(
      ~targetId="TARGET",
      ~packetHash="not-a-hash",
      ~workOrderHash=hash("work"),
      ~providerId="FAKE",
      ~providerPrincipalId="PR-PRODUCER",
      ~authorizerPrincipalId="PR-AUTHORIZER",
      ~commandId="CMD",
      ~authorizedEventId="EVT",
      ~dependencyProofHash=hash("dependencies"),
      ~referenceSetHash=hash("references"),
      ~maxAttempts=3,
    )->ignore
  )
}

let lowerLevelAttemptCeilingTest = () => {
  let stateDir = newState("attempt-ceiling")
  let authorization = J.persistAuthorization(
    ~stateDir,
    ~intent=intent(~commandId="CMD-CEILING", ~maxAttempts=1),
  )
  J.recordStatus(
    ~stateDir,
    ~authorizationId=authorization.authorizationId,
    ~attempt=1,
    ~status=J.Claimed,
    ~reason="first and only claim",
  )->ignore
  J.recordStatus(
    ~stateDir,
    ~authorizationId=authorization.authorizationId,
    ~attempt=1,
    ~status=J.Submitting,
    ~reason="first and only submit",
  )->ignore
  J.recordStatus(
    ~stateDir,
    ~authorizationId=authorization.authorizationId,
    ~attempt=1,
    ~status=J.Failed,
    ~reason="known invalid response",
  )->ignore
  expectJournalError("recordStatus cannot bypass immutable attempt ceiling", () =>
    J.recordStatus(
      ~stateDir,
      ~authorizationId=authorization.authorizationId,
      ~attempt=2,
      ~status=J.Claimed,
      ~reason="forbidden second claim",
    )->ignore
  )
}

restartAndRecoveryTest()
terminalEvidenceAndContractTest()
tamperedAuthorizationTest()
renamedTransitionTest()
missingMiddleTransitionTest()
ambiguousTransitionTest()
unsafeAndUnknownEntryTest()
lowerLevelAttemptCeilingTest()
Js.log(
  "PASS - immutable execution journal, deterministic restart recovery, tamper detection, and zero provider surface",
)
