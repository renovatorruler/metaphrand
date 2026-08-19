/* Cross-process contract worker for the production execution lease. The
   companion shell test starts two instances against one synthetic Ready
   target. No network, media, or real provider capability exists here. */

module B = Cinema_Backends
module F = Production_TestFixtures
module C = Production_Controller
module P = Production_Preflight
module G = Production_Gateway
module L = Production_Lease
module S = Production_State

@val @scope("process") external argv: array<string> = "argv"
@val @scope("process") external processPid: int = "pid"

let fail = message => {
  Js.Console.error("production concurrency test: " ++ message)
  assert(false)
}

let arg = index =>
  switch Belt.Array.get(argv, index) {
  | Some(value) => value
  | None => fail("missing argument " ++ Belt.Int.toString(index))
  }

let setup = descriptorPath => {
  let fixture = F.create()
  let reconciliation = C.reconcile(
    ~packetPath=fixture.packetPath,
    ~stateDir=fixture.stateDir,
    ~targetId="T-SYNTHETIC",
  )
  switch reconciliation.status {
  | C.ReadyForExecution => ()
  | _ => fail("synthetic target did not reconcile ready")
  }
  B.writeText(
    B.Path(descriptorPath),
    fixture.packetPath ++ "\n" ++ fixture.stateDir ++ "\n" ++ fixture.root ++ "\n" ++
    fixture.firstReferencePath ++ "\n",
  )
}

let waitForGate = gatePath => {
  let deadline = Js.Date.now() +. 10000.0
  while !B.exists(B.Path(gatePath)) && Js.Date.now() < deadline {
    ()
  }
  if !B.exists(B.Path(gatePath)) {
    fail("timed out waiting for cross-process start gate")
  }
}

let worker = (~packetPath, ~stateDir, ~callDir, ~readyPath, ~gatePath, ~resultPath) => {
  let evaluated = P.evaluate(~packetPath, ~stateDir, ~targetId="T-SYNTHETIC")
  let cleared = switch evaluated.cleared {
  | Some(value) => value
  | None => fail("worker preflight did not clear: " ++ P.explain(evaluated))
  }
  if !B.writeTextExclusive(B.Path(readyPath), "ready\n") {
    fail("worker ready marker collided")
  }
  waitForGate(gatePath)
  let outcome = try {
    let provider = F.registerFakeProviderAt(
      ~packetPath,
      ~adapterId="concurrency-fake-provider",
      ~submit=_request => {
        let callPath = callDir ++ "/" ++ Belt.Int.toString(processPid) ++ ".call"
        if !B.writeTextExclusive(B.Path(callPath), "fake provider called\n") {
          fail("fake provider call marker collided")
        }
        Ok({
          content: "synthetic concurrent candidate",
          contentType: "text/plain",
          providerReceipt: "concurrency-fake-receipt",
        })
      },
    )
    let authorization = G.authorize(
      ~cleared,
      ~provider,
      ~commandText=F.executionCommand(
        ~cleared,
        ~provider,
        ~assertionId="CMD-CONCURRENT-" ++ Belt.Int.toString(processPid),
      ),
    )
    let execution = G.execute(~authorization, ~provider)
    "success " ++ execution.candidate.candidateHash ++ "\n"
  } catch {
  | G.GatewayError(message) => "refused " ++ message ++ "\n"
  }
  if !B.writeTextExclusive(B.Path(resultPath), outcome) {
    fail("worker result marker collided")
  }
}

let mark = (path, body) =>
  if !B.writeTextExclusive(B.Path(path), body) {
    fail("marker collided at " ++ path)
  }

let leasePath = "leases/concurrency-contract.sqlite"

/* The shell harness kills this process after the ready marker. SQLite owns the
   actual kernel lease, so abrupt process death—not PID-file deletion—is the
   stale-owner recovery boundary under test. */
let holdLease = (~stateDir, ~readyPath, ~releaseGatePath) =>
  L.withLease(
    ~stateDir,
    ~relativePath=leasePath,
    ~resource="synthetic cross-process lease",
    () => {
      mark(readyPath, "held\n")
      waitForGate(releaseGatePath)
    },
  )

let raceForLease = (
  ~stateDir,
  ~readyPath,
  ~startGatePath,
  ~releaseGatePath,
  ~acquiredPath,
  ~resultPath,
) => {
  mark(readyPath, "ready\n")
  waitForGate(startGatePath)
  let result = try {
    L.withLease(
      ~stateDir,
      ~relativePath=leasePath,
      ~resource="synthetic cross-process lease",
      () => {
        mark(acquiredPath, "acquired\n")
        waitForGate(releaseGatePath)
        "acquired\n"
      },
    )
  } catch {
  | L.LeaseError(_) => "refused\n"
  }
  mark(resultPath, result)
}

let holdConsistentStateView = (~stateDir, ~readyPath, ~releaseGatePath, ~resultPath) =>
  S.withConsistentSnapshot(~stateDir, snapshot => {
    let target = snapshot.targets->Belt.Array.getBy(row => row.targetId == "T-SYNTHETIC")
    switch target {
    | Some(row) if row.state == S.Ready => ()
    | _ => fail("queue-race holder did not capture the expected Ready snapshot")
    }
    mark(readyPath, "ready\n")
    waitForGate(releaseGatePath)
    let head = Belt.Array.getExn(snapshot.events, Belt.Array.length(snapshot.events) - 1)
    mark(resultPath, "released " ++ head.id ++ "\n")
  })

let queueField = (~stateDir, ~queueName, ~field) =>
  B.readText(B.Path(stateDir ++ "/queues/" ++ queueName ++ ".json"))
  ->Js.Json.parseExn
  ->Js.Json.decodeObject
  ->Belt.Option.getExn
  ->Js.Dict.get(field)

let reconcileAfterConsistentView = (
  ~packetPath,
  ~stateDir,
  ~referencePath,
  ~readyPath,
  ~resultPath,
) => {
  mark(readyPath, "ready\n")
  B.writeText(B.Path(referencePath), "synthetic concurrent authority drift\n")
  /* The changed immutable reference blocks the target and rematerializes both
     queues from the newer anchored snapshot after the older view releases. */
  C.reconcile(~packetPath, ~stateDir, ~targetId="T-SYNTHETIC")->ignore
  let snapshot = S.load(~stateDir)
  let head = Belt.Array.getExn(snapshot.events, Belt.Array.length(snapshot.events) - 1)
  let expectedCount = Belt.Array.length(snapshot.events)
  let verify = queueName => {
    let count = queueField(
      ~stateDir,
      ~queueName,
      ~field="lifecycleEventCount",
    )->Belt.Option.flatMap(Js.Json.decodeNumber)->Belt.Option.map(Js.Math.floor_int)
    let headId = queueField(
      ~stateDir,
      ~queueName,
      ~field="lifecycleHeadEventId",
    )->Belt.Option.flatMap(Js.Json.decodeString)
    if count != Some(expectedCount) || headId != Some(head.id) {
      fail(queueName ++ " queue was overwritten by an older lifecycle snapshot")
    }
  }
  verify("ready")
  verify("blocked")
  mark(resultPath, "current " ++ head.id ++ "\n")
}

let main = () =>
  switch arg(2) {
  | "setup" => setup(arg(3))
  | "worker" =>
    worker(
      ~packetPath=arg(3),
      ~stateDir=arg(4),
      ~callDir=arg(5),
      ~readyPath=arg(6),
      ~gatePath=arg(7),
      ~resultPath=arg(8),
    )
  | "lease-hold" =>
    holdLease(~stateDir=arg(3), ~readyPath=arg(4), ~releaseGatePath=arg(5))
  | "lease-race" =>
    raceForLease(
      ~stateDir=arg(3),
      ~readyPath=arg(4),
      ~startGatePath=arg(5),
      ~releaseGatePath=arg(6),
      ~acquiredPath=arg(7),
      ~resultPath=arg(8),
    )
  | "state-view-hold" =>
    holdConsistentStateView(
      ~stateDir=arg(3),
      ~readyPath=arg(4),
      ~releaseGatePath=arg(5),
      ~resultPath=arg(6),
    )
  | "state-append-refresh" =>
    reconcileAfterConsistentView(
      ~packetPath=arg(3),
      ~stateDir=arg(4),
      ~referencePath=arg(5),
      ~readyPath=arg(6),
      ~resultPath=arg(7),
    )
  | mode => fail("unknown mode " ++ mode)
  }

main()
