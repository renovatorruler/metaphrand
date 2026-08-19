module B = Cinema_Backends
module S = Production_State

let fail = message => {
  Js.log("FAIL - " ++ message)
  assert(false)
}

let expectStateError = (label, work) => {
  let refused = try {
    work()
    false
  } catch {
  | S.StateError(_) => true
  }
  if !refused {
    fail(label ++ ": expected StateError")
  }
}

let hashes = (
  Some("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"),
  Some("bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"),
  Some("cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"),
  Some("dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"),
)

let eventFile = (stateDir, event: S.event) =>
  stateDir ++ "/events/" ++ Belt.Int.toString(event.sequence) ++ "-" ++ event.id ++ ".json"

let snapshotSignature = (snapshot: S.snapshot) => {
  let targets = snapshot.targets
    ->Belt.Array.map(target =>
      target.targetId ++ "|" ++ S.lifecycleName(target.state) ++ "|" ++ target.lastEvent.id
    )
    ->Js.Array2.joinWith("\n")
  S.encodeEvents(snapshot.events) ++
  "next=" ++ Belt.Int.toString(snapshot.nextSequence) ++ "\n" ++
  targets
}

let replaceExactlyOnce = (~label, ~raw, ~needle, ~replacement) => {
  if !Js.String2.includes(raw, needle) {
    fail(label ++ ": fixture did not contain the expected source text")
  }
  let changed = Js.String2.replace(raw, needle, replacement)
  if changed == raw {
    fail(label ++ ": fixture mutation did not change the durable bytes")
  }
  changed
}

type durableLedger = {stateDir: string, events: array<S.event>}

let makeDurableLedger = label => {
  let B.Path(root) = B.tempDir("production-state-" ++ label ++ "-")
  let stateDir = root ++ "/control"
  B.ensureDirPath(B.Path(stateDir))
  let (packetHash, workOrderHash, _, _) = hashes
  let locked = S.append(
    ~stateDir,
    ~targetId="TARGET-A",
    ~state=S.Locked,
    ~actor=S.System,
    ~reason="packet decisions locked",
  )
  let compiled = S.append(
    ~stateDir,
    ~targetId="TARGET-A",
    ~state=S.Compiled,
    ~actor=S.System,
    ~packetHash=packetHash->Belt.Option.getExn,
    ~workOrderHash=workOrderHash->Belt.Option.getExn,
    ~reason="work order compiled",
  )
  let ready = S.append(
    ~stateDir,
    ~targetId="TARGET-A",
    ~state=S.Ready,
    ~actor=S.System,
    ~packetHash=packetHash->Belt.Option.getExn,
    ~workOrderHash=workOrderHash->Belt.Option.getExn,
    ~reason="all deterministic preflight checks passed",
  )
  {stateDir, events: [locked, compiled, ready]}
}

let event = (
  ~sequence,
  ~previousEventId=?,
  ~state,
  ~actor,
  ~packetHash=?,
  ~workOrderHash=?,
  ~artifactHash=?,
  ~reportHash=?,
) => {
  let reason = "synthetic lifecycle event"
  let seed = [
    Belt.Int.toString(sequence),
    previousEventId->Belt.Option.getWithDefault(""),
    "TARGET-A",
    S.lifecycleName(state),
    S.actorName(actor),
    packetHash->Belt.Option.getWithDefault(""),
    workOrderHash->Belt.Option.getWithDefault(""),
    artifactHash->Belt.Option.getWithDefault(""),
    reportHash->Belt.Option.getWithDefault(""),
    reason,
  ]->Js.Array2.joinWith("\n")
  {
    S.id: "EVT-" ++ B.sha256Text(seed),
    sequence,
    previousEventId,
    targetId: "TARGET-A",
    state,
    actor,
    packetHash,
    workOrderHash,
    artifactHash,
    reportHash,
    reason,
  }
}

let lifecycleFixture = () => {
  let (packetHash, workOrderHash, artifactHash, reportHash) = hashes
  let e1 = event(~sequence=1, ~state=S.Locked, ~actor=S.System)
  let e2 = event(
    ~sequence=2,
    ~previousEventId=e1.id,
    ~state=S.Compiled,
    ~actor=S.System,
    ~packetHash?,
    ~workOrderHash?,
  )
  let e3 = event(
    ~sequence=3,
    ~previousEventId=e2.id,
    ~state=S.Ready,
    ~actor=S.System,
    ~packetHash?,
    ~workOrderHash?,
  )
  let e4 = event(
    ~sequence=4,
    ~previousEventId=e3.id,
    ~state=S.Authorized,
    ~actor=S.Human,
    ~packetHash?,
    ~workOrderHash?,
  )
  let e5 = event(
      ~sequence=5,
      ~previousEventId=e4.id,
      ~state=S.CandidateQuarantine,
      ~actor=S.Provider,
      ~packetHash?,
      ~workOrderHash?,
      ~artifactHash?,
    )
  let e6 = event(
      ~sequence=6,
      ~previousEventId=e5.id,
      ~state=S.ReviewReady,
      ~actor=S.System,
      ~packetHash?,
      ~workOrderHash?,
      ~artifactHash?,
      ~reportHash?,
    )
  let e7 = event(
      ~sequence=7,
      ~previousEventId=e6.id,
      ~state=S.Approved,
      ~actor=S.Human,
      ~packetHash?,
      ~workOrderHash?,
      ~artifactHash?,
      ~reportHash?,
    )
  let e8 = event(
      ~sequence=8,
      ~previousEventId=e7.id,
      ~state=S.Released,
      ~actor=S.System,
      ~packetHash?,
      ~workOrderHash?,
      ~artifactHash?,
      ~reportHash?,
    )
  let events = [e1, e2, e3, e4, e5, e6, e7, e8]
  let snapshot = S.reduce(events)
  if snapshot.nextSequence != 9 || Belt.Array.length(snapshot.targets) != 1 {
    fail("legal lifecycle did not reduce deterministically")
  }
  let roundTrip = S.decodeEvents(S.encodeEvents(events))->S.reduce
  if S.encodeEvents(roundTrip.events) != S.encodeEvents(snapshot.events) ||
    roundTrip.targets != snapshot.targets || roundTrip.nextSequence != snapshot.nextSequence {
    fail("event ledger round trip changed its state")
  }

  expectStateError("provider cannot approve", () =>
    S.reduce(
      Belt.Array.concat(
        events->Belt.Array.slice(~offset=0, ~len=6),
        [
          event(
            ~sequence=7,
            ~previousEventId=e6.id,
            ~state=S.Approved,
            ~actor=S.Provider,
            ~packetHash?,
            ~workOrderHash?,
            ~artifactHash?,
            ~reportHash?,
          ),
        ],
      ),
    )->ignore
  )
  expectStateError("inspector cannot self-promote", () =>
    S.reduce(
      Belt.Array.concat(
        events->Belt.Array.slice(~offset=0, ~len=5),
        [
          event(
            ~sequence=6,
            ~previousEventId=e5.id,
            ~state=S.ReviewReady,
            ~actor=S.Inspector,
            ~packetHash?,
            ~workOrderHash?,
            ~artifactHash?,
            ~reportHash?,
          ),
        ],
      ),
    )->ignore
  )
  expectStateError("illegal skip to candidate", () => {
    let invalidFirst = event(~sequence=1, ~state=S.Locked, ~actor=S.System)
    S.reduce([
      invalidFirst,
      event(
        ~sequence=2,
        ~previousEventId=invalidFirst.id,
        ~state=S.CandidateQuarantine,
        ~actor=S.Provider,
        ~packetHash?,
        ~workOrderHash?,
        ~artifactHash?,
      ),
    ])->ignore
  })
}

let durableFixture = () => {
  let B.Path(root) = B.tempDir("production-state-")
  let stateDir = root ++ "/control"
  B.ensureDirPath(B.Path(stateDir))
  let (packetHash, workOrderHash, _, _) = hashes
  S.append(
    ~stateDir,
    ~targetId="TARGET-A",
    ~state=S.Locked,
    ~actor=S.System,
    ~reason="packet decisions locked",
  )->ignore
  S.append(
    ~stateDir,
    ~targetId="TARGET-A",
    ~state=S.Compiled,
    ~actor=S.System,
    ~packetHash=packetHash->Belt.Option.getExn,
    ~workOrderHash=workOrderHash->Belt.Option.getExn,
    ~reason="work order compiled",
  )->ignore
  let first = S.load(~stateDir)
  let second = S.load(~stateDir)
  if S.encodeEvents(first.events) != S.encodeEvents(second.events) {
    fail("fresh load did not reconstruct identical lifecycle authority")
  }
  if !B.exists(B.Path(stateDir ++ "/current.json")) {
    fail("append did not maintain the generated current-state view")
  }

  /* A dead owner is recoverable; an active owner remains fail-closed. */
  B.writeText(B.Path(stateDir ++ "/ledger.lock"), "{\"pid\":99999999}\n")
  S.append(
    ~stateDir,
    ~targetId="TARGET-A",
    ~state=S.Ready,
    ~actor=S.System,
    ~packetHash=packetHash->Belt.Option.getExn,
    ~workOrderHash=workOrderHash->Belt.Option.getExn,
    ~reason="recovered stale lock and reconciled readiness",
  )->ignore
  if S.load(~stateDir).nextSequence != 4 {
    fail("stale-lock recovery did not preserve append-only sequence")
  }
}

let reasonTamperFixture = () => {
  let fixture = makeDurableLedger("reason-tamper")
  let compiled = fixture.events[1]
  let path = eventFile(fixture.stateDir, compiled)
  let raw = B.readText(B.Path(path))
  let changed = replaceExactlyOnce(
    ~label="reason tamper",
    ~raw,
    ~needle=`"reason": "work order compiled"`,
    ~replacement=`"reason": "silently changed after commit"`,
  )
  B.writeText(B.Path(path), changed)
  expectStateError("reason edit without event-ID rehash", () =>
    S.load(~stateDir=fixture.stateDir)->ignore
  )
}

let authorityFieldTamperFixture = () => {
  let fixture = makeDurableLedger("authority-field-tamper")
  let compiled = fixture.events[1]
  let path = eventFile(fixture.stateDir, compiled)
  let raw = B.readText(B.Path(path))
  let changed = replaceExactlyOnce(
    ~label="packet authority hash tamper",
    ~raw,
    ~needle="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    ~replacement="eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee",
  )
  B.writeText(B.Path(path), changed)
  expectStateError("authority field edit without event-ID rehash", () =>
    S.load(~stateDir=fixture.stateDir)->ignore
  )
}

let filenameMismatchFixture = () => {
  let fixture = makeDurableLedger("filename-mismatch")
  let compiled = fixture.events[1]
  let original = eventFile(fixture.stateDir, compiled)
  let mismatched = fixture.stateDir ++
    "/events/2-EVT-ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff.json"
  B.copyFile(B.Path(original), B.Path(mismatched))
  B.removeFile(B.Path(original))
  expectStateError("filename and event-ID mismatch", () =>
    S.load(~stateDir=fixture.stateDir)->ignore
  )
}

let middleDeletionFixture = () => {
  let fixture = makeDurableLedger("middle-deletion")
  B.removeFile(B.Path(eventFile(fixture.stateDir, fixture.events[1])))
  expectStateError("missing middle event breaks contiguous sequence", () =>
    S.load(~stateDir=fixture.stateDir)->ignore
  )
}

let newestDeletionFixture = () => {
  let fixture = makeDurableLedger("newest-deletion")
  B.removeFile(B.Path(eventFile(fixture.stateDir, fixture.events[2])))
  expectStateError("missing newest event contradicts durable high-water anchor", () =>
    S.load(~stateDir=fixture.stateDir)->ignore
  )
}

let missingHeadFixture = () => {
  let fixture = makeDurableLedger("missing-head")
  B.removeFile(B.Path(fixture.stateDir ++ "/lifecycle-head.json"))
  expectStateError("eventful ledger cannot restart without its trusted head", () =>
    S.load(~stateDir=fixture.stateDir)->ignore
  )
}

let headTamperFixture = () => {
  let fixture = makeDurableLedger("head-tamper")
  let path = fixture.stateDir ++ "/lifecycle-head.json"
  let raw = B.readText(B.Path(path))
  let changed = replaceExactlyOnce(
    ~label="head high-water tamper",
    ~raw,
    ~needle=`"eventCount": 3`,
    ~replacement=`"eventCount": 2`,
  )
  B.writeText(B.Path(path), changed)
  expectStateError("head high-water edit without anchor-ID rehash", () =>
    S.load(~stateDir=fixture.stateDir)->ignore
  )
}

let interruptedHeadCommitFixture = () => {
  let fixture = makeDurableLedger("interrupted-head-commit")
  let headPath = fixture.stateDir ++ "/lifecycle-head.json"
  let priorHead = B.readText(B.Path(headPath))
  let (packetHash, workOrderHash, _, _) = hashes
  let authorized = S.append(
    ~stateDir=fixture.stateDir,
    ~targetId="TARGET-A",
    ~state=S.Authorized,
    ~actor=S.Human,
    ~packetHash=packetHash->Belt.Option.getExn,
    ~workOrderHash=workOrderHash->Belt.Option.getExn,
    ~reason="synthetic authorization committed before simulated crash",
  )
  let committedHead = B.readText(B.Path(headPath))
  B.writeText(B.Path(fixture.stateDir ++ "/.lifecycle-head.pending"), committedHead)
  B.writeText(B.Path(headPath), priorHead)
  let recovered = S.load(~stateDir=fixture.stateDir)
  if recovered.events->Belt.Array.length != 4 ||
    Belt.Array.getExn(recovered.events, 3).id != authorized.id ||
    B.readText(B.Path(headPath)) != committedHead {
    fail("restart did not finish the exact durable pending head commit")
  }
}

let staleMaterializationFixture = () => {
  let fixture = makeDurableLedger("stale-materialization")
  let stale = S.load(~stateDir=fixture.stateDir)
  let (packetHash, workOrderHash, _, _) = hashes
  S.append(
    ~stateDir=fixture.stateDir,
    ~targetId="TARGET-A",
    ~state=S.Authorized,
    ~actor=S.Human,
    ~packetHash=packetHash->Belt.Option.getExn,
    ~workOrderHash=workOrderHash->Belt.Option.getExn,
    ~reason="newer lifecycle authority",
  )->ignore
  let currentPath = fixture.stateDir ++ "/current.json"
  let current = B.readText(B.Path(currentPath))
  expectStateError("older snapshot cannot overwrite materialized current state", () =>
    S.writeMaterialized(~stateDir=fixture.stateDir, ~snapshot=stale)
  )
  if B.readText(B.Path(currentPath)) != current ||
    !Js.String2.includes(current, `"eventCount": 4`) {
    fail("rejected stale materialization changed the newer current-state view")
  }
}

let predecessorTamperFixture = () => {
  let fixture = makeDurableLedger("predecessor-tamper")
  let ready = fixture.events[2]
  let path = eventFile(fixture.stateDir, ready)
  let raw = B.readText(B.Path(path))
  let originalPrevious = ready.previousEventId->Belt.Option.getExn
  let changed = replaceExactlyOnce(
    ~label="predecessor tamper",
    ~raw,
    ~needle=`"previousEventId": "${originalPrevious}"`,
    ~replacement=`"previousEventId": "EVT-ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff"`,
  )
  B.writeText(B.Path(path), changed)
  expectStateError("predecessor edit breaks the hash chain", () =>
    S.load(~stateDir=fixture.stateDir)->ignore
  )
}

let orphanPendingFixture = () => {
  let fixture = makeDurableLedger("orphan-pending")
  let before = S.load(~stateDir=fixture.stateDir)
  let beforeSignature = snapshotSignature(before)
  let orphan = fixture.stateDir ++ "/events/.4-EVT-orphan.pending"
  B.writeText(B.Path(orphan), "not even valid JSON\n")
  let after = S.load(~stateDir=fixture.stateDir)
  if snapshotSignature(after) != beforeSignature {
    fail("orphan .pending file changed reconstructed state")
  }
  if !B.exists(B.Path(orphan)) {
    fail("load unexpectedly mutated the orphan .pending recovery evidence")
  }
}

let deterministicRehydrationFixture = () => {
  let fixture = makeDurableLedger("deterministic-rehydration")
  let first = S.load(~stateDir=fixture.stateDir)
  let expected = snapshotSignature(first)
  let currentPath = fixture.stateDir ++ "/current.json"

  /* current.json is a disposable materialized view, never lifecycle authority. */
  B.writeText(B.Path(currentPath), "corrupt and contradictory materialized state\n")
  let afterRestart = S.load(~stateDir=fixture.stateDir)
  if snapshotSignature(afterRestart) != expected {
    fail("restart trusted corrupt materialized state instead of the event ledger")
  }
  S.writeMaterialized(~stateDir=fixture.stateDir, ~snapshot=afterRestart)
  let firstMaterialization = B.readText(B.Path(currentPath))

  B.writeText(B.Path(currentPath), "different stale cache contents\n")
  let secondRestart = S.load(~stateDir=fixture.stateDir)
  S.writeMaterialized(~stateDir=fixture.stateDir, ~snapshot=secondRestart)
  let secondMaterialization = B.readText(B.Path(currentPath))
  if snapshotSignature(secondRestart) != expected || secondMaterialization != firstMaterialization {
    fail("repeated restart and materialization was not byte-for-byte deterministic")
  }
}

lifecycleFixture()
durableFixture()
reasonTamperFixture()
authorityFieldTamperFixture()
filenameMismatchFixture()
middleDeletionFixture()
newestDeletionFixture()
missingHeadFixture()
headTamperFixture()
interruptedHeadCommitFixture()
staleMaterializationFixture()
predecessorTamperFixture()
orphanPendingFixture()
deterministicRehydrationFixture()
Js.log("PASS - production lifecycle, durable event ledger, tamper rejection, and restart recovery")
