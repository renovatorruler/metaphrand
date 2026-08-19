module B = Cinema_Backends
module W = Production_WorkOrder
module S = Production_State
module A = Production_ArtifactStore
module C = Production_Credentials
module R = Production_References
module J = Production_ExecutionJournal
module L = Production_Lease

exception GatewayError(string)

type authorizationData = {
  id: string,
  order: W.workOrder,
  stateDir: string,
  providerId: string,
  providerPrincipalId: string,
  authorizerPrincipalId: string,
  commandId: string,
  authorizedEventId: string,
  dependencies: array<Production_Preflight.dependencyProof>,
  references: array<W.reference>,
}
type authorization = Authorization(authorizationData)
type request = {
  authorizationId: string,
  packetHash: string,
  workOrderHash: string,
  targetId: string,
  operation: string,
  canonicalWorkOrder: string,
  references: array<W.reference>,
}
type providerOutput = {content: string, contentType: string, providerReceipt: string}
type provider = {
  id: string,
  principalId: string,
  submit: request => result<providerOutput, string>,
}
type execution = {
  candidate: A.candidate,
  attempt: int,
  receiptHash: string,
  reused: bool,
  quarantinedStale: bool,
}
type recovery = {changed: bool, message: string}

let die = message => raise(GatewayError(message))

let safeTargetId = id => {
  if Js.String2.trim(id) == "" || Js.String2.includes(id, "/") ||
    Js.String2.includes(id, "\\") || Js.String2.includes(id, "..") {
    die("unsafe execution target id '" ++ id ++ "'")
  }
  id
}

let registerProvider = (~packetPath, ~adapterId, ~credentialText, ~submit) => {
  safeTargetId(adapterId)->ignore
  let credential = try {
    C.verifyPrincipal(
      ~packetPath,
      ~raw=credentialText,
      ~role=Production_Domain.Producer,
      ~action="register_provider_adapter",
      ~bindingHash=C.bindingHash(["provider_adapter", adapterId]),
    )
  } catch {
  | C.CredentialError(message) => die("provider adapter credential refused: " ++ message)
  }
  {id: adapterId, principalId: C.principalId(credential), submit}
}

let current = (~stateDir, ~targetId) =>
  S.load(~stateDir).targets->Belt.Array.getBy(row => row.targetId == targetId)

let dependencyProofKey = (proof: Production_Preflight.dependencyProof) =>
  Js.Array2.joinWith(
    [proof.targetId, proof.eventId, proof.packetHash, proof.workOrderHash],
    "\u{1f}",
  )

let sameDependencyProofs = (left, right) =>
  Belt.Array.length(left) == Belt.Array.length(right) &&
  left->Belt.Array.map(dependencyProofKey)->Js.Array2.joinWith("\n") ==
    right->Belt.Array.map(dependencyProofKey)->Js.Array2.joinWith("\n")

let dependencySetHash = proofs =>
  C.bindingHash([
    "production.dependency-proof-set/v1",
    proofs->Belt.Array.map(dependencyProofKey)->Js.Array2.joinWith("\n"),
  ])

let referenceSetHash = (references: array<W.reference>) =>
  C.bindingHash([
    "production.immutable-reference-set/v1",
    references
    ->Belt.Array.map(reference =>
      Js.Array2.joinWith([reference.assetId, reference.path, reference.sha256], "\u{001f}")
    )
    ->Js.Array2.joinWith("\n"),
  ])

let copyReferences = (references: array<W.reference>) =>
  references->Belt.Array.map(reference => ({
    assetId: reference.assetId,
    path: reference.path,
    sha256: reference.sha256,
  }: W.reference))

let currentDependencyProofs = (~order: W.workOrder, ~stateDir) => {
  try {
    let snapshot = S.load(~stateDir)
    let proofs: array<Production_Preflight.dependencyProof> = []
    let valid = ref(true)
    order.dependencyTargetIds->Belt.Array.forEach(targetId =>
      switch snapshot.targets->Belt.Array.getBy(row => row.targetId == targetId) {
      | Some(row) if row.state == S.Approved || row.state == S.Released =>
        switch W.compile(~packetPath=order.packetPath, ~targetId).workOrder {
        | Some(dependencyOrder)
          if row.lastEvent.packetHash == Some(order.packetHash) &&
            row.lastEvent.workOrderHash == Some(dependencyOrder.hash) =>
          proofs
          ->Js.Array2.push({
            targetId,
            eventId: row.lastEvent.id,
            packetHash: order.packetHash,
            workOrderHash: dependencyOrder.hash,
          })
          ->ignore
        | _ => valid := false
        }
      | _ => valid := false
      }
    )
    proofs->Js.Array2.sortInPlaceWith((left, right) => compare(left.targetId, right.targetId))->ignore
    valid.contents && Belt.Array.length(proofs) == Belt.Array.length(order.dependencyTargetIds)
      ? Some(proofs)
      : None
  } catch {
  | _ => None
  }
}

let authorizationContextMatches = (
  ~packetPath,
  ~stateDir,
  ~authorization: J.authorizationRecord,
) =>
  switch W.compile(~packetPath, ~targetId=authorization.targetId).workOrder {
  | Some(order)
    if order.packetHash == authorization.packetHash && order.hash == authorization.workOrderHash &&
      order.maxAttempts == authorization.maxAttempts =>
    switch currentDependencyProofs(~order, ~stateDir) {
    | Some(proofs) if dependencySetHash(proofs) == authorization.dependencyProofHash =>
      try {
        let references = R.rehydrate(~stateDir, ~workOrder=order)
        referenceSetHash(references) == authorization.referenceSetHash
      } catch {
      | R.ReferenceError(_) => false
      }
    | _ => false
    }
  | _ => false
  }

let authorizationBinding = (~cleared, ~provider) => {
  let order = Production_Preflight.workOrder(cleared)
  C.bindingHash([
    "authorize_execution",
    order.packetHash,
    order.hash,
    order.targetId,
    provider.id,
    provider.principalId,
    Production_Preflight.readyEventId(cleared),
    Production_Preflight.dependencyProofs(cleared)
      ->Belt.Array.map(dependencyProofKey)
      ->Js.Array2.joinWith("\n"),
  ])
}

let ensureAuthorizationSlot = (~stateDir, ~order: W.workOrder) => {
  let snapshot = try J.load(~stateDir) catch {
  | J.JournalError(message) => die("execution journal is invalid: " ++ message)
  }
  let authorizations = snapshot.authorizations->Belt.Array.keep(row =>
    row.targetId == order.targetId && row.workOrderHash == order.hash
  )
  let authorizationIds = authorizations->Belt.Array.map(row => row.authorizationId)
  let attempts = snapshot.attempts->Belt.Array.keep(row =>
    authorizationIds->Belt.Array.some(id => id == row.authorizationId)
  )
  if authorizations->Belt.Array.some(authorization =>
    !(attempts->Belt.Array.some(attempt => attempt.authorizationId == authorization.authorizationId))
  ) {
    die("an earlier execution authorization is still unclaimed and must be recovered")
  }
  if Belt.Array.length(attempts) >= order.maxAttempts {
    die(
      order.targetId ++ " has consumed its " ++ Belt.Int.toString(order.maxAttempts) ++
      " execution attempts; changed reviewed authority is required",
    )
  }
  let ordered = Js.Array2.copy(attempts)
  ordered->Js.Array2.sortInPlaceWith((left, right) => left.attempt - right.attempt)->ignore
  switch Belt.Array.get(ordered, Belt.Array.length(ordered) - 1) {
  | Some(last) if last.current.status != J.Failed && last.current.status != J.BlockedPreSubmit =>
    die(
      "prior execution ended in " ++ J.statusName(last.current.status) ++
      "; the same work-order authority cannot be authorized again",
    )
  | _ => ()
  }
}

let authorize = (~cleared, ~provider, ~commandText) => {
  let providerId = provider.id
  let order = Production_Preflight.workOrder(cleared)
  let stateDir = Production_Preflight.stateDirectory(cleared)
  let dependencyProofs = Production_Preflight.dependencyProofs(cleared)
  if !order.requiresExplicitAuthorization {
    die("work order lacks the mandatory explicit-authorization policy")
  }
  let fresh = Production_Preflight.evaluate(
    ~packetPath=order.packetPath,
    ~stateDir,
    ~targetId=order.targetId,
  )
  let freshCleared = switch fresh.cleared {
  | None => die("preflight changed before authorization:\n" ++ Production_Preflight.explain(fresh))
  | Some(value) => value
  }
  if Production_Preflight.readyEventId(cleared) !=
    Production_Preflight.readyEventId(freshCleared) {
    die("ready event changed before authorization")
  }
  if !sameDependencyProofs(
    dependencyProofs,
    Production_Preflight.dependencyProofs(freshCleared),
  ) {
    die("dependency authority changed before authorization")
  }
  ensureAuthorizationSlot(~stateDir, ~order)
  let commandBinding = authorizationBinding(~cleared, ~provider)
  let command = try {
    C.verifyHumanCommand(
      ~packetPath=order.packetPath,
      ~raw=commandText,
      ~role=Production_Domain.Authorizer,
      ~action="authorize_execution",
      ~bindingHash=commandBinding,
    )
  } catch {
  | C.CredentialError(message) => die("execution authorization refused: " ++ message)
  }
  let references = try R.snapshot(~stateDir, ~workOrder=order) catch {
  | R.ReferenceError(message) => die("reference snapshot refused: " ++ message)
  }
  try C.consumeHumanCommand(~stateDir, ~command) catch {
  | C.CredentialError(message) => die("execution authorization refused: " ++ message)
  }
  let event = try {
    S.append(
      ~stateDir,
      ~targetId=order.targetId,
      ~state=S.Authorized,
      ~actor=S.Human,
      ~packetHash=order.packetHash,
      ~workOrderHash=order.hash,
      ~reason="explicit command " ++ C.commandId(command) ++ " authorized provider " ++ providerId,
    )
  } catch {
  | S.StateError(message) => die("could not record authorization: " ++ message)
  }
  let journalRecord = try {
    let intent = J.createAuthorizationIntent(
      ~targetId=order.targetId,
      ~packetHash=order.packetHash,
      ~workOrderHash=order.hash,
      ~providerId,
      ~providerPrincipalId=provider.principalId,
      ~authorizerPrincipalId=C.commandPrincipalId(command),
      ~commandId=C.commandId(command),
      ~authorizedEventId=event.id,
      ~dependencyProofHash=dependencySetHash(dependencyProofs),
      ~referenceSetHash=referenceSetHash(references),
      ~maxAttempts=order.maxAttempts,
    )
    J.persistAuthorization(~stateDir, ~intent)
  } catch {
  | J.JournalError(message) =>
    die("could not persist execution authorization journal: " ++ message)
  }
  Authorization({
    id: journalRecord.authorizationId,
    order,
    stateDir,
    providerId,
    providerPrincipalId: provider.principalId,
    authorizerPrincipalId: C.commandPrincipalId(command),
    commandId: C.commandId(command),
    authorizedEventId: event.id,
    dependencies: dependencyProofs,
    references,
  })
}

let lockRelative = targetId => "execution/" ++ safeTargetId(targetId) ++ "/active.lock"

let withLock = (stateDir, targetId, work) => {
  let safeId = safeTargetId(targetId)
  try {
    L.withLease(
      ~stateDir,
      ~relativePath="leases/execution/" ++ safeId ++ ".sqlite",
      ~legacyRelativePath=lockRelative(safeId),
      ~resource="execution target " ++ safeId,
      work,
    )
  } catch {
  | L.LeaseError(message) => die("another execution cannot acquire its target lease: " ++ message)
  | GatewayError(message) => raise(GatewayError(message))
  | S.StateError(message) => die("lifecycle state refused execution: " ++ message)
  | A.StoreError(message) => die("artifact store refused execution: " ++ message)
  | J.JournalError(message) => die("execution journal refused operation: " ++ message)
  | B.BackendError(message) => die("execution filesystem operation failed: " ++ message)
  | Js.Exn.Error(error) =>
    die(
      "unexpected execution failure: " ++
      Js.Exn.message(error)->Belt.Option.getWithDefault("unknown JavaScript error"),
    )
  }
}

let journalAuthorization = (snapshot: J.snapshot, authorizationId) =>
  snapshot.authorizations->Belt.Array.getBy(row => row.authorizationId == authorizationId)

let currentAuthorizedFor = (~stateDir, ~authorization: J.authorizationRecord) =>
  switch current(~stateDir, ~targetId=authorization.targetId) {
  | Some(row)
    if row.state == S.Authorized && row.lastEvent.id == authorization.authorizedEventId &&
      row.lastEvent.packetHash == Some(authorization.packetHash) &&
      row.lastEvent.workOrderHash == Some(authorization.workOrderHash) => true
  | _ => false
  }

let journalMatchesOpaqueAuthorization = (
  ~authorization: J.authorizationRecord,
  ~auth: authorizationData,
) =>
  authorization.authorizationId == auth.id &&
  authorization.targetId == auth.order.targetId &&
  authorization.packetHash == auth.order.packetHash &&
  authorization.workOrderHash == auth.order.hash &&
  authorization.providerId == auth.providerId &&
  authorization.providerPrincipalId == auth.providerPrincipalId &&
  authorization.authorizerPrincipalId == auth.authorizerPrincipalId &&
  authorization.commandId == auth.commandId &&
  authorization.authorizedEventId == auth.authorizedEventId &&
  authorization.dependencyProofHash == dependencySetHash(auth.dependencies) &&
  authorization.referenceSetHash == referenceSetHash(auth.references) &&
  authorization.maxAttempts == auth.order.maxAttempts

let requireOpaqueAuthorizationRecord = (~stateDir, ~auth: authorizationData) => {
  let snapshot = J.load(~stateDir)
  switch snapshot.authorizations->Belt.Array.getBy(row => row.authorizationId == auth.id) {
  | Some(authorization) if journalMatchesOpaqueAuthorization(~authorization, ~auth) => authorization
  | Some(_) => die("opaque authorization differs from its immutable execution journal")
  | None => die("opaque authorization has no immutable execution journal record")
  }
}

let journalCandidate = (
  ~store,
  ~authorization: J.authorizationRecord,
  ~attempt,
  ~candidateHash,
  ~artifactHash,
  ~providerReceiptHash,
) => {
  let matches = A.listCandidates(store)->Belt.Array.keep(candidate =>
    candidate.candidateHash == candidateHash &&
    candidate.authorizationId == authorization.authorizationId && candidate.attempt == attempt &&
    candidate.targetId == authorization.targetId &&
    candidate.packetHash == authorization.packetHash &&
    candidate.workOrderHash == authorization.workOrderHash &&
    candidate.artifactHash == artifactHash &&
    candidate.providerReceiptHash == providerReceiptHash
  )
  switch matches {
  | [candidate] => candidate
  | [] => die("execution journal points to a missing or mismatched candidate")
  | _ => die("execution journal candidate identity is ambiguous")
  }
}

let candidateForInterrupted = (~store, ~authorizationId, ~attempt) => {
  let candidates = A.listCandidates(store)->Belt.Array.keep(candidate =>
    candidate.authorizationId == authorizationId && candidate.attempt == attempt
  )
  switch candidates {
  | [] => None
  | [candidate] => Some(candidate)
  | _ => die("interrupted execution produced more than one candidate")
  }
}

let sameCandidate = (left: A.candidate, right: A.candidate) =>
  left.candidateHash == right.candidateHash && left.producerId == right.producerId &&
  left.targetId == right.targetId && left.authorizationId == right.authorizationId &&
  left.attempt == right.attempt && left.providerReceiptHash == right.providerReceiptHash &&
  left.packetHash == right.packetHash && left.workOrderHash == right.workOrderHash &&
  left.artifactHash == right.artifactHash && left.contentKind == right.contentKind &&
  left.objectPath == right.objectPath

let candidateAuthorityCurrent = (~packetPath, ~stateDir, ~candidate: A.candidate) => {
  try {
    let snapshot = J.load(~stateDir)
    let authorization = switch snapshot.authorizations->Belt.Array.getBy(row =>
      row.authorizationId == candidate.authorizationId
    ) {
    | Some(value) => value
    | None => die("candidate authorization is absent from the immutable execution journal")
    }
    if authorization.targetId != candidate.targetId ||
      authorization.packetHash != candidate.packetHash ||
      authorization.workOrderHash != candidate.workOrderHash {
      die("candidate authority differs from its immutable execution authorization")
    }
    let attempt = switch snapshot.attempts->Belt.Array.keep(row =>
      row.authorizationId == authorization.authorizationId
    ) {
    | [value] if value.attempt == candidate.attempt => value
    | [] => die("candidate authorization has no execution attempt")
    | _ => die("candidate authorization has ambiguous execution attempts")
    }
    switch (
      attempt.current.status,
      attempt.current.candidateHash,
      attempt.current.artifactHash,
      attempt.current.providerReceiptHash,
    ) {
    | (J.CandidateQuarantine, Some(candidateHash), Some(artifactHash), Some(providerReceiptHash))
      if candidateHash == candidate.candidateHash && artifactHash == candidate.artifactHash &&
        providerReceiptHash == candidate.providerReceiptHash => ()
    | _ => die("candidate lacks an exact candidate-quarantine execution receipt")
    }
    let store = A.openStore(~root=stateDir ++ "/store", ~reviewBatchSize=1)
    let durable = journalCandidate(
      ~store,
      ~authorization,
      ~attempt=attempt.attempt,
      ~candidateHash=candidate.candidateHash,
      ~artifactHash=candidate.artifactHash,
      ~providerReceiptHash=candidate.providerReceiptHash,
    )
    if !sameCandidate(durable, candidate) {
      die("candidate value differs from its immutable artifact ledger record")
    }
    authorizationContextMatches(~packetPath, ~stateDir, ~authorization)
  } catch {
  | GatewayError(message) => raise(GatewayError(message))
  | J.JournalError(message) => die("execution journal is invalid: " ++ message)
  | A.StoreError(message) => die("artifact ledger is invalid: " ++ message)
  | S.StateError(message) => die("lifecycle authority is invalid: " ++ message)
  }
}

let recordRecoveryDisposition = (~store, ~candidate: A.candidate, ~kind, ~reason) => {
  let existing = A.listDispositions(store)->Belt.Array.keep(row =>
    row.candidateHash == candidate.candidateHash
  )
  if Belt.Array.length(existing) == 0 {
    A.recordDisposition(~store, ~candidate, ~kind, ~reason, ~supersededBy=None)->ignore
  } else if existing->Belt.Array.some(row => row.kind == kind || row.kind == A.Rejected) {
    ()
  } else {
    die("candidate has a contradictory disposition during restart recovery")
  }
}

let recover = (~packetPath, ~stateDir, ~targetId) =>
  withLock(stateDir, targetId, () => {
    let changed = ref(0)
    let store = A.openStore(~root=stateDir ++ "/store", ~reviewBatchSize=1)
    let before = J.load(~stateDir)

    /* This target lease proves no provider call for the target is active while
       dangling journal states are classified and made terminal. */
    J.classify(before)->Belt.Array.forEach(classification => {
      if classification.targetId == targetId {
        switch (classification.kind, classification.attempt) {
        | (J.UnclaimedAuthorization, None) =>
          switch journalAuthorization(before, classification.authorizationId) {
          | Some(authorization) if currentAuthorizedFor(~stateDir, ~authorization) => {
              let contextCurrent = authorizationContextMatches(
                ~packetPath,
                ~stateDir,
                ~authorization,
              )
              let claim = J.claimNextAttempt(
                ~stateDir,
                ~authorizationId=authorization.authorizationId,
                ~reason="restart recovery claimed an abandoned authorization",
              )
              J.recordStatus(
                ~stateDir,
                ~authorizationId=authorization.authorizationId,
                ~attempt=claim.attempt,
                ~status=J.BlockedPreSubmit,
                ~reason=contextCurrent
                  ? "restart recovery: authorization ended before provider submission"
                  : "restart recovery: authorization authority became stale before provider submission",
              )->ignore
              changed := changed.contents + 1
            }
          | _ => ()
          }
        | (J.InterruptedBeforeSubmit, Some(attempt)) => {
            J.recordStatus(
              ~stateDir,
              ~authorizationId=classification.authorizationId,
              ~attempt,
              ~status=J.BlockedPreSubmit,
              ~reason="restart recovery: execution stopped before provider submission",
            )->ignore
            changed := changed.contents + 1
          }
        | (J.InterruptedDuringSubmit, Some(attempt)) => {
            J.recordStatus(
              ~stateDir,
              ~authorizationId=classification.authorizationId,
              ~attempt,
              ~status=J.InterruptedUnknown,
              ~reason="restart recovery: provider outcome is unknown; retry is forbidden",
            )->ignore
            changed := changed.contents + 1
          }
        | _ => ()
        }
      }
    })

    let after = J.load(~stateDir)
    after.attempts->Belt.Array.forEach(attemptRecord => {
      if attemptRecord.targetId == targetId {
        let authorization = journalAuthorization(after, attemptRecord.authorizationId)
        ->Belt.Option.getExn
        let transition = attemptRecord.current
        switch transition.status {
        | J.CandidateQuarantine =>
          switch (
            transition.candidateHash,
            transition.artifactHash,
            transition.providerReceiptHash,
          ) {
          | (Some(candidateHash), Some(artifactHash), Some(providerReceiptHash)) => {
              let candidate = journalCandidate(
                ~store,
                ~authorization,
                ~attempt=attemptRecord.attempt,
                ~candidateHash,
                ~artifactHash,
                ~providerReceiptHash,
              )
              let contextCurrent = authorizationContextMatches(
                ~packetPath,
                ~stateDir,
                ~authorization,
              )
              let currentRow = current(~stateDir, ~targetId)
              let lifecycleOwnsCandidate = switch currentRow {
              | Some(_) if currentAuthorizedFor(~stateDir, ~authorization) => true
              | Some(row) =>
                row.lastEvent.packetHash == Some(authorization.packetHash) &&
                row.lastEvent.workOrderHash == Some(authorization.workOrderHash) &&
                row.lastEvent.artifactHash == Some(candidate.artifactHash)
              | None => false
              }
              if contextCurrent && currentAuthorizedFor(~stateDir, ~authorization) {
                S.append(
                  ~stateDir,
                  ~targetId,
                  ~state=S.CandidateQuarantine,
                  ~actor=S.Provider,
                  ~packetHash=authorization.packetHash,
                  ~workOrderHash=authorization.workOrderHash,
                  ~artifactHash=candidate.artifactHash,
                  ~reason="restart recovery restored committed candidate quarantine",
                )->ignore
                changed := changed.contents + 1
              } else if !contextCurrent && lifecycleOwnsCandidate {
                recordRecoveryDisposition(
                  ~store,
                  ~candidate,
                  ~kind=A.Stale,
                  ~reason="restart recovery found candidate authority had changed",
                )
                switch currentRow {
                | Some(row) if row.state != S.Rejected && row.state != S.Superseded => {
                    S.append(
                      ~stateDir,
                      ~targetId,
                      ~state=S.Superseded,
                      ~actor=S.System,
                      ~packetHash=authorization.packetHash,
                      ~workOrderHash=authorization.workOrderHash,
                      ~artifactHash=candidate.artifactHash,
                      ~reason="restart recovery stale-quarantined a candidate under changed authority",
                    )->ignore
                    changed := changed.contents + 1
                  }
                | _ => ()
                }
              }
            }
          | _ => die("terminal candidate journal entry lacks required evidence")
          }
        | J.StaleQuarantine =>
          switch (
            transition.candidateHash,
            transition.artifactHash,
            transition.providerReceiptHash,
          ) {
          | (Some(candidateHash), Some(artifactHash), Some(providerReceiptHash)) => {
              let candidate = journalCandidate(
                ~store,
                ~authorization,
                ~attempt=attemptRecord.attempt,
                ~candidateHash,
                ~artifactHash,
                ~providerReceiptHash,
              )
              recordRecoveryDisposition(
                ~store,
                ~candidate,
                ~kind=A.Stale,
                ~reason="restart recovery preserved stale provider output",
              )
              if currentAuthorizedFor(~stateDir, ~authorization) {
                S.append(
                  ~stateDir,
                  ~targetId,
                  ~state=S.Superseded,
                  ~actor=S.System,
                  ~packetHash=authorization.packetHash,
                  ~workOrderHash=authorization.workOrderHash,
                  ~artifactHash=candidate.artifactHash,
                  ~reason="stale provider output cannot advance under current authority",
                )->ignore
                changed := changed.contents + 1
              }
            }
          | _ => die("terminal stale journal entry lacks required evidence")
          }
        | J.Failed | J.BlockedPreSubmit =>
          if currentAuthorizedFor(~stateDir, ~authorization) {
            S.append(
              ~stateDir,
              ~targetId,
              ~state=S.Blocked,
              ~actor=S.System,
              ~packetHash=authorization.packetHash,
              ~workOrderHash=authorization.workOrderHash,
              ~reason=transition.reason,
            )->ignore
            changed := changed.contents + 1
          }
        | J.InterruptedUnknown => {
            let candidate = candidateForInterrupted(
              ~store,
              ~authorizationId=authorization.authorizationId,
              ~attempt=attemptRecord.attempt,
            )
            switch candidate {
            | Some(candidate) =>
              recordRecoveryDisposition(
                ~store,
                ~candidate,
                ~kind=A.Quarantined,
                ~reason="provider outcome was interrupted and cannot be trusted or retried",
              )
            | None => ()
            }
            let currentRow = current(~stateDir, ~targetId)
            let currentMatches = switch currentRow {
            | Some(row) if row.state == S.Superseded => false
            | Some(row) if row.state == S.Authorized => currentAuthorizedFor(~stateDir, ~authorization)
            | Some(row) =>
              row.lastEvent.packetHash == Some(authorization.packetHash) &&
              row.lastEvent.workOrderHash == Some(authorization.workOrderHash) &&
              candidate->Belt.Option.mapWithDefault(true, value =>
                row.lastEvent.artifactHash == Some(value.artifactHash)
              )
            | None => false
            }
            if currentMatches {
              S.append(
                ~stateDir,
                ~targetId,
                ~state=S.Superseded,
                ~actor=S.System,
                ~packetHash=authorization.packetHash,
                ~workOrderHash=authorization.workOrderHash,
                ~artifactHash=?candidate->Belt.Option.map(value => value.artifactHash),
                ~reason="provider outcome is unknown after interruption; retry is forbidden",
              )->ignore
              changed := changed.contents + 1
            }
          }
        | J.Claimed | J.Submitting => die("restart recovery left a nonterminal attempt")
        }
      }
    })

    /* An Authorized lifecycle event without its immutable journal record is a
       crash boundary, never permission to reconstruct a token from memory. */
    switch current(~stateDir, ~targetId) {
    | Some(row) if row.state == S.Authorized => {
        let hasRecord = after.authorizations->Belt.Array.some(authorization =>
          authorization.targetId == targetId &&
          authorization.authorizedEventId == row.lastEvent.id &&
          authorization.packetHash == row.lastEvent.packetHash->Belt.Option.getWithDefault("") &&
          authorization.workOrderHash == row.lastEvent.workOrderHash->Belt.Option.getWithDefault("")
        )
        if !hasRecord {
          S.append(
            ~stateDir,
            ~targetId,
            ~state=S.Blocked,
            ~actor=S.System,
            ~packetHash=?row.lastEvent.packetHash,
            ~workOrderHash=?row.lastEvent.workOrderHash,
            ~reason="authorization lifecycle has no immutable execution-journal record",
          )->ignore
          changed := changed.contents + 1
        }
      }
    | _ => ()
    }
    {
      changed: changed.contents > 0,
      message: changed.contents == 0
        ? "no interrupted execution required recovery"
        : "recovered " ++ Belt.Int.toString(changed.contents) ++ " interrupted execution records",
    }
  })

let existingSuccess = (~store, ~stateDir, ~order: W.workOrder, ~authId) => {
  let snapshot = J.load(~stateDir)
  let authorization = snapshot.authorizations->Belt.Array.getBy(row =>
    row.authorizationId == authId
  )
  switch authorization {
  | None => die("opaque authorization has no immutable journal record")
  | Some(authorization)
    if authorization.targetId != order.targetId || authorization.packetHash != order.packetHash ||
      authorization.workOrderHash != order.hash =>
    die("execution authorization journal does not match its work order")
  | Some(authorization) => {
      let attempts = snapshot.attempts->Belt.Array.keep(row => row.authorizationId == authId)
      switch attempts {
      | [] => None
      | [attempt] =>
        switch (
          attempt.current.status,
          attempt.current.candidateHash,
          attempt.current.artifactHash,
          attempt.current.providerReceiptHash,
        ) {
        | (J.CandidateQuarantine, Some(candidateHash), Some(artifactHash), Some(providerReceiptHash)) => {
            let candidate = journalCandidate(
              ~store,
              ~authorization,
              ~attempt=attempt.attempt,
              ~candidateHash,
              ~artifactHash,
              ~providerReceiptHash,
            )
            if A.listDispositions(store)->Belt.Array.some(row =>
              row.candidateHash == candidate.candidateHash
            ) {
              die("journal candidate has a terminal disposition and cannot be reused")
            }
            switch current(~stateDir, ~targetId=order.targetId) {
            | Some(row)
              if row.state != S.Blocked && row.state != S.Rejected &&
                row.state != S.Superseded &&
                row.lastEvent.packetHash == Some(candidate.packetHash) &&
                row.lastEvent.workOrderHash == Some(candidate.workOrderHash) &&
                row.lastEvent.artifactHash == Some(candidate.artifactHash) => ()
            | _ => die("journal candidate is not the current lifecycle artifact")
            }
            Some({
              candidate,
              attempt: attempt.attempt,
              receiptHash: attempt.current.recordHash,
              reused: true,
              quarantinedStale: false,
            })
          }
        | (J.StaleQuarantine, Some(candidateHash), Some(artifactHash), Some(providerReceiptHash)) => {
            let candidate = journalCandidate(
              ~store,
              ~authorization,
              ~attempt=attempt.attempt,
              ~candidateHash,
              ~artifactHash,
              ~providerReceiptHash,
            )
            Some({
              candidate,
              attempt: attempt.attempt,
              receiptHash: attempt.current.recordHash,
              reused: true,
              quarantinedStale: true,
            })
          }
        | (J.Claimed, _, _, _) | (J.Submitting, _, _, _) =>
          die("single-use authorization already has an unfinished execution attempt")
        | (J.Failed, _, _, _) | (J.BlockedPreSubmit, _, _, _) =>
          die("single-use authorization already ended without a candidate")
        | (J.InterruptedUnknown, _, _, _) =>
          die("single-use authorization has an unknown provider outcome and cannot be retried")
        | _ => die("execution journal terminal evidence is malformed")
        }
      | _ => die("single-use authorization was associated with more than one attempt")
      }
    }
  }
}

let validateAuthorizedState = (auth: authorizationData, order: W.workOrder, stateDir) =>
  switch current(~stateDir, ~targetId=order.targetId) {
  | Some(row) if row.state == S.Authorized && row.lastEvent.id == auth.authorizedEventId &&
      row.lastEvent.packetHash == Some(order.packetHash) &&
      row.lastEvent.workOrderHash == Some(order.hash) => ()
  | _ => die("authorization is not the current exact lifecycle state")
  }

let execute = (~authorization, ~provider) => {
  let Authorization(auth) = authorization
  if provider.id != auth.providerId || provider.principalId != auth.providerPrincipalId {
    die("provider does not match the explicitly authorized providerId")
  }
  let order = auth.order
  let stateDir = auth.stateDir
  withLock(stateDir, order.targetId, () => {
    let store = A.openStore(~root=stateDir ++ "/store", ~reviewBatchSize=order.reviewBatchSize)
    let journalAuthorization = requireOpaqueAuthorizationRecord(~stateDir, ~auth)
    switch existingSuccess(~store, ~stateDir, ~order, ~authId=auth.id) {
    | Some(existing) => {
        if !authorizationContextMatches(
          ~packetPath=order.packetPath,
          ~stateDir,
          ~authorization=journalAuthorization,
        ) {
          A.recordDisposition(
            ~store,
            ~candidate=existing.candidate,
            ~kind=A.Stale,
            ~reason="authority changed after the successful execution receipt was committed",
            ~supersededBy=None,
          )->ignore
          S.append(
            ~stateDir,
            ~targetId=order.targetId,
            ~state=S.Superseded,
            ~actor=S.System,
            ~packetHash=order.packetHash,
            ~workOrderHash=order.hash,
            ~artifactHash=existing.candidate.artifactHash,
            ~reason="idempotent candidate became stale under changed authority",
          )->ignore
          die("the idempotent execution result is stale under current authority")
        }
        if !candidateAuthorityCurrent(
          ~packetPath=order.packetPath,
          ~stateDir,
          ~candidate=existing.candidate,
        ) {
          die("the idempotent execution result is stale under current authority")
        }
        existing
      }
    | None => {
        let claim = try {
          J.claimNextAttempt(
            ~stateDir,
            ~authorizationId=auth.id,
            ~reason="gateway atomically consumed single-use authorization",
          )
        } catch {
        | J.JournalError(message) => die("execution attempt refused: " ++ message)
        }
        let attempt = claim.attempt
        let blockPreSubmit = message => {
          J.recordStatus(
            ~stateDir,
            ~authorizationId=auth.id,
            ~attempt,
            ~status=J.BlockedPreSubmit,
            ~reason=message ++ "; provider was not called",
          )->ignore
          if currentAuthorizedFor(
            ~stateDir,
            ~authorization=J.load(~stateDir).authorizations
            ->Belt.Array.getBy(row => row.authorizationId == auth.id)
            ->Belt.Option.getExn,
          ) {
            S.append(
              ~stateDir,
              ~targetId=order.targetId,
              ~state=S.Blocked,
              ~actor=S.System,
              ~packetHash=order.packetHash,
              ~workOrderHash=order.hash,
              ~reason=message ++ "; provider was not called",
            )->ignore
          }
          die(message ++ "; provider was not called")
        }
        try validateAuthorizedState(auth, order, stateDir) catch {
        | GatewayError(message) => blockPreSubmit(message)
        }
        let claimedAuthorization = try requireOpaqueAuthorizationRecord(~stateDir, ~auth) catch {
        | GatewayError(message) => blockPreSubmit(message)
        }
        if !authorizationContextMatches(
          ~packetPath=order.packetPath,
          ~stateDir,
          ~authorization=claimedAuthorization,
        ) {
          blockPreSubmit("packet, dependencies, references, or work order changed before submission")
        }
        try R.verify(~stateDir, ~references=auth.references) catch {
        | R.ReferenceError(message) => blockPreSubmit("immutable reference verification failed: " ++ message)
        }
        let request = {
          authorizationId: auth.id,
          packetHash: order.packetHash,
          workOrderHash: order.hash,
          targetId: order.targetId,
          operation: order.operation,
          canonicalWorkOrder: order.canonical,
          references: copyReferences(auth.references),
        }
        /* No filesystem, validation, or orchestration work may be inserted
           between this durable boundary and the adapter invocation. */
        J.recordStatus(
          ~stateDir,
          ~authorizationId=auth.id,
          ~attempt,
          ~status=J.Submitting,
          ~reason="crossing the sole provider boundary",
        )->ignore
        let unknownOutcome = message => {
          J.recordStatus(
            ~stateDir,
            ~authorizationId=auth.id,
            ~attempt,
            ~status=J.InterruptedUnknown,
            ~reason=message ++ "; external outcome is unknown and retry is forbidden",
          )->ignore
          S.append(
            ~stateDir,
            ~targetId=order.targetId,
            ~state=S.Superseded,
            ~actor=S.System,
            ~packetHash=order.packetHash,
            ~workOrderHash=order.hash,
            ~reason=message ++ "; external outcome is unknown",
          )->ignore
          die(message ++ "; external outcome is unknown and retry is forbidden")
        }
        let submitted = try provider.submit(request) catch {
        | _ => unknownOutcome("provider adapter raised after the submission boundary")
        }
        let failAttempt = message => {
          J.recordStatus(
            ~stateDir,
            ~authorizationId=auth.id,
            ~attempt,
            ~status=J.Failed,
            ~reason="provider failed: " ++ message,
          )->ignore
          S.append(
            ~stateDir,
            ~targetId=order.targetId,
            ~state=S.Blocked,
            ~actor=S.System,
            ~packetHash=order.packetHash,
            ~workOrderHash=order.hash,
            ~reason="provider failed: " ++ message,
          )->ignore
          die("provider failed: " ++ message)
        }
        switch submitted {
        | Error(message) =>
          unknownOutcome("provider adapter returned an unproved failure: " ++ message)
        | Ok(output) => {
            if output.content == "" || Js.String2.trim(output.contentType) == "" ||
              Js.String2.trim(output.providerReceipt) == "" {
              failAttempt("response lacks content, contentType, or providerReceipt")
            }
            let providerReceiptHash = B.sha256Text(output.providerReceipt)
            /* The candidate is durable before terminal journal/state records;
               its provenance lets restart recovery quarantine this exact output
               if the process stops at either later boundary. */
            let candidate = A.putTextCandidate(
              ~store,
              ~producerId=provider.principalId,
              ~authorizationId=auth.id,
              ~attempt,
              ~providerReceiptHash,
              ~targetId=order.targetId,
              ~packetHash=order.packetHash,
              ~workOrderHash=order.hash,
              ~text=output.content,
            )
            let postSubmitAuthorization = requireOpaqueAuthorizationRecord(~stateDir, ~auth)
            let stale = !currentAuthorizedFor(~stateDir, ~authorization=postSubmitAuthorization) ||
              !authorizationContextMatches(
                ~packetPath=order.packetPath,
                ~stateDir,
                ~authorization=postSubmitAuthorization,
              )
            if stale {
              A.recordDisposition(
                ~store,
                ~candidate,
                ~kind=A.Stale,
                ~reason="authority changed while provider work was running",
                ~supersededBy=None,
              )->ignore
            }
            let journalStatus = stale ? J.StaleQuarantine : J.CandidateQuarantine
            let terminal = J.recordStatus(
              ~stateDir,
              ~authorizationId=auth.id,
              ~attempt,
              ~status=journalStatus,
              ~candidateHash=candidate.candidateHash,
              ~artifactHash=candidate.artifactHash,
              ~providerReceiptHash,
              ~reason=stale
                ? "candidate preserved under stale authority"
                : "candidate preserved pending independent inspection",
            )
            S.append(
              ~stateDir,
              ~targetId=order.targetId,
              ~state=stale ? S.Superseded : S.CandidateQuarantine,
              ~actor=stale ? S.System : S.Provider,
              ~packetHash=order.packetHash,
              ~workOrderHash=order.hash,
              ~artifactHash=candidate.artifactHash,
              ~reason=stale
                ? "candidate preserved in stale quarantine; authority was superseded"
                : "candidate preserved pending independent inspection",
            )->ignore
            {
              candidate,
              attempt,
              receiptHash: terminal.recordHash,
              reused: false,
              quarantinedStale: stale,
            }
          }
        }
      }
    }
  })
}
