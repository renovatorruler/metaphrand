module B = Cinema_Backends
module L = Production_Lease

exception SyntheticFailure

@val @scope("process") external processPid: int = "pid"

let fail = message => {
  Js.Console.error("production lease test: " ++ message)
  assert(false)
}

let expectLeaseError = (label, work) => {
  let refused = try {
    work()
    false
  } catch {
  | L.LeaseError(_) => true
  }
  if !refused {
    fail(label ++ " did not fail closed")
  }
}

let fixture = label => {
  let B.Path(root) = B.tempDir("production-lease-" ++ label ++ "-")
  let stateDir = root ++ "/control"
  B.ensureDirPath(B.Path(stateDir))
  stateDir
}

let exclusiveAndOwnerBoundRelease = () => {
  let stateDir = fixture("owner")
  let first = L.acquire(
    ~stateDir,
    ~relativePath="leases/test.sqlite",
    ~resource="synthetic test resource",
  )
  if !Js.String2.startsWith(L.ownerToken(first), "LEASE-") {
    fail("opaque owner token lacks its stable namespace")
  }
  expectLeaseError("overlapping owner", () =>
    L.acquire(
      ~stateDir,
      ~relativePath="leases/test.sqlite",
      ~resource="synthetic test resource",
    )->ignore
  )
  L.release(first)

  let successor = L.acquire(
    ~stateDir,
    ~relativePath="leases/test.sqlite",
    ~resource="synthetic test resource",
  )
  if L.ownerToken(successor) == L.ownerToken(first) {
    fail("successor reused the old owner token")
  }
  /* The old implementation unlinked a shared pathname here and could erase
     its successor. Releasing an old opaque handle again must be harmless. */
  L.release(first)
  expectLeaseError("old owner deleting successor", () =>
    L.acquire(
      ~stateDir,
      ~relativePath="leases/test.sqlite",
      ~resource="synthetic test resource",
    )->ignore
  )
  L.release(successor)
  let after = L.acquire(
    ~stateDir,
    ~relativePath="leases/test.sqlite",
    ~resource="synthetic test resource",
  )
  L.release(after)
  Js.log("ok - lease ownership is exclusive and an old owner cannot release its successor")
}

let exceptionsRelease = () => {
  let stateDir = fixture("exception")
  let shouldRaise = ref(true)
  let propagated = try {
    L.withLease(
      ~stateDir,
      ~relativePath="leases/test.sqlite",
      ~resource="synthetic exception resource",
      () => shouldRaise.contents ? raise(SyntheticFailure) : (),
    )
    false
  } catch {
  | SyntheticFailure => true
  }
  if !propagated {
    fail("withLease did not preserve the work exception")
  }
  let next = L.acquire(
    ~stateDir,
    ~relativePath="leases/test.sqlite",
    ~resource="synthetic exception resource",
  )
  L.release(next)
  Js.log("ok - arbitrary work exceptions release the exact lease and propagate")
}

let boundedWait = () => {
  let stateDir = fixture("bounded")
  let owner = L.acquire(
    ~stateDir,
    ~relativePath="leases/test.sqlite",
    ~resource="synthetic bounded resource",
  )
  let started = Js.Date.now()
  expectLeaseError("bounded competing acquisition", () =>
    L.acquire(
      ~stateDir,
      ~relativePath="leases/test.sqlite",
      ~resource="synthetic bounded resource",
      ~waitMs=25,
    )->ignore
  )
  let elapsed = Js.Date.now() -. started
  if elapsed > 1000.0 {
    fail("bounded lease wait exceeded one second")
  }
  L.release(owner)
  Js.log("ok - competing lease waits are explicitly bounded")
}

let legacyCompatibility = () => {
  let dead = fixture("legacy-dead")
  B.writeText(B.Path(dead ++ "/old.lock"), "{\"pid\":99999999}\n")
  let recovered = L.acquire(
    ~stateDir=dead,
    ~relativePath="leases/test.sqlite",
    ~legacyRelativePath="old.lock",
    ~resource="synthetic legacy resource",
  )
  L.release(recovered)
  if !B.exists(B.Path(dead ++ "/old.lock")) {
    fail("dead compatibility marker was deleted despite no safety need")
  }

  let live = fixture("legacy-live")
  B.writeText(
    B.Path(live ++ "/old.lock"),
    "{\"pid\":" ++ Belt.Int.toString(processPid) ++ "}\n",
  )
  expectLeaseError("live legacy owner", () =>
    L.acquire(
      ~stateDir=live,
      ~relativePath="leases/test.sqlite",
      ~legacyRelativePath="old.lock",
      ~resource="synthetic legacy resource",
    )->ignore
  )

  let unreadable = fixture("legacy-unreadable")
  B.writeText(B.Path(unreadable ++ "/old.lock"), "not-json\n")
  expectLeaseError("unreadable legacy owner", () =>
    L.acquire(
      ~stateDir=unreadable,
      ~relativePath="leases/test.sqlite",
      ~legacyRelativePath="old.lock",
      ~resource="synthetic legacy resource",
    )->ignore
  )
  Js.log("ok - dead legacy owners recover while live or unreadable owners fail closed")
}

exclusiveAndOwnerBoundRelease()
exceptionsRelease()
boundedWait()
legacyCompatibility()
