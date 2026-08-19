module B = Cinema_Backends
module L = Production_Lease

exception StateError(string)

type lifecycle =
  | Draft
  | Locked
  | Compiled
  | Blocked
  | Ready
  | Authorized
  | CandidateQuarantine
  | Unknown
  | ReviewReady
  | Approved
  | Rejected
  | Superseded
  | Released

type actor = System | Human | Provider | Inspector

type event = {
  id: string,
  sequence: int,
  previousEventId: option<string>,
  targetId: string,
  state: lifecycle,
  actor: actor,
  packetHash: option<string>,
  workOrderHash: option<string>,
  artifactHash: option<string>,
  reportHash: option<string>,
  reason: string,
}

type targetState = {targetId: string, state: lifecycle, lastEvent: event}
type snapshot = {events: array<event>, targets: array<targetState>, nextSequence: int}

type headAnchor = {
  schema: string,
  eventCount: int,
  headEventId: string,
  id: string,
}

@module("node:path") external join2: (string, string) => string = "join"

let die = message => raise(StateError(message))

let lifecycleName = state =>
  switch state {
  | Draft => "draft"
  | Locked => "locked"
  | Compiled => "compiled"
  | Blocked => "blocked"
  | Ready => "ready"
  | Authorized => "authorized"
  | CandidateQuarantine => "candidate_quarantine"
  | Unknown => "unknown"
  | ReviewReady => "review_ready"
  | Approved => "approved"
  | Rejected => "rejected"
  | Superseded => "superseded"
  | Released => "released"
  }

let actorName = actor =>
  switch actor {
  | System => "system"
  | Human => "human"
  | Provider => "provider"
  | Inspector => "inspector"
  }

let lifecycleOf = value =>
  switch value {
  | "draft" => Draft
  | "locked" => Locked
  | "compiled" => Compiled
  | "blocked" => Blocked
  | "ready" => Ready
  | "authorized" => Authorized
  | "candidate_quarantine" => CandidateQuarantine
  | "unknown" => Unknown
  | "review_ready" => ReviewReady
  | "approved" => Approved
  | "rejected" => Rejected
  | "superseded" => Superseded
  | "released" => Released
  | other => die("unknown lifecycle state '" ++ other ++ "'")
  }

let actorOf = value =>
  switch value {
  | "system" => System
  | "human" => Human
  | "provider" => Provider
  | "inspector" => Inspector
  | other => die("unknown lifecycle actor '" ++ other ++ "'")
  }

let obj = (json, where) =>
  switch Js.Json.decodeObject(json) {
  | Some(value) => value
  | None => die(where ++ " must be an object")
  }

let get = (object, key) => Js.Dict.get(object, key)

let reqString = (object, key, where) =>
  switch get(object, key)->Belt.Option.flatMap(Js.Json.decodeString) {
  | Some(value) if Js.String2.trim(value) != "" => value
  | _ => die(where ++ "." ++ key ++ " must be a nonempty string")
  }

let optString = (object, key, where) =>
  switch get(object, key) {
  | None => None
  | Some(value) =>
    switch Js.Json.decodeString(value) {
    | Some(text) if Js.String2.trim(text) != "" => Some(text)
    | _ => die(where ++ "." ++ key ++ " must be a nonempty string when present")
    }
  }

let reqInt = (object, key, where) =>
  switch get(object, key)->Belt.Option.flatMap(Js.Json.decodeNumber) {
  | Some(value) =>
    let integer = Js.Math.floor_int(value)
    if Belt.Int.toFloat(integer) != value || integer < 1 {
      die(where ++ "." ++ key ++ " must be a positive integer")
    }
    integer
  | None => die(where ++ "." ++ key ++ " must be a positive integer")
  }

let eventToJson = (event: event) => {
  let row = Js.Dict.empty()
  Js.Dict.set(row, "id", Js.Json.string(event.id))
  Js.Dict.set(row, "sequence", Js.Json.number(Belt.Int.toFloat(event.sequence)))
  switch event.previousEventId {
  | Some(value) => Js.Dict.set(row, "previousEventId", Js.Json.string(value))
  | None => ()
  }
  Js.Dict.set(row, "targetId", Js.Json.string(event.targetId))
  Js.Dict.set(row, "state", Js.Json.string(lifecycleName(event.state)))
  Js.Dict.set(row, "actor", Js.Json.string(actorName(event.actor)))
  switch event.packetHash {
  | Some(value) => Js.Dict.set(row, "packetHash", Js.Json.string(value))
  | None => ()
  }
  switch event.workOrderHash {
  | Some(value) => Js.Dict.set(row, "workOrderHash", Js.Json.string(value))
  | None => ()
  }
  switch event.artifactHash {
  | Some(value) => Js.Dict.set(row, "artifactHash", Js.Json.string(value))
  | None => ()
  }
  switch event.reportHash {
  | Some(value) => Js.Dict.set(row, "reportHash", Js.Json.string(value))
  | None => ()
  }
  Js.Dict.set(row, "reason", Js.Json.string(event.reason))
  Js.Json.object_(row)
}

let decodeEvent = (json, index) => {
  let where = "events[" ++ Belt.Int.toString(index) ++ "]"
  let row = obj(json, where)
  {
    id: reqString(row, "id", where),
    sequence: reqInt(row, "sequence", where),
    previousEventId: optString(row, "previousEventId", where),
    targetId: reqString(row, "targetId", where),
    state: lifecycleOf(reqString(row, "state", where)),
    actor: actorOf(reqString(row, "actor", where)),
    packetHash: optString(row, "packetHash", where),
    workOrderHash: optString(row, "workOrderHash", where),
    artifactHash: optString(row, "artifactHash", where),
    reportHash: optString(row, "reportHash", where),
    reason: reqString(row, "reason", where),
  }
}

let decodeEvents = raw => {
  let json = try Js.Json.parseExn(raw) catch {
  | _ => die("event ledger must be valid JSON")
  }
  switch Js.Json.decodeArray(json) {
  | Some(rows) => rows->Belt.Array.mapWithIndex((index, row) => decodeEvent(row, index))
  | None => die("event ledger must be a JSON array")
  }
}

let encodeEvents = events =>
  Js.Json.stringifyWithSpace(Js.Json.array(events->Belt.Array.map(eventToJson)), 2) ++ "\n"

let headSchema = "production.lifecycle-head/v1"

let derivedHeadId = (~eventCount, ~headEventId) =>
  "HEAD-" ++
  B.sha256Text(
    headSchema ++ "\n" ++ Belt.Int.toString(eventCount) ++ "\n" ++ headEventId,
  )

let anchorForEvent = (~eventCount, ~headEventId): headAnchor => {
  schema: headSchema,
  eventCount,
  headEventId,
  id: derivedHeadId(~eventCount, ~headEventId),
}

let headToJson = (anchor: headAnchor) => {
  let row = Js.Dict.empty()
  Js.Dict.set(row, "schema", Js.Json.string(anchor.schema))
  Js.Dict.set(row, "eventCount", Js.Json.number(Belt.Int.toFloat(anchor.eventCount)))
  Js.Dict.set(row, "headEventId", Js.Json.string(anchor.headEventId))
  Js.Dict.set(row, "id", Js.Json.string(anchor.id))
  Js.Json.object_(row)
}

let encodeHead = anchor => Js.Json.stringifyWithSpace(headToJson(anchor), 2) ++ "\n"

let decodeHead = raw => {
  let json = try Js.Json.parseExn(raw) catch {
  | _ => die("lifecycle head anchor must be valid JSON")
  }
  let row = obj(json, "lifecycle head anchor")
  let anchor = {
    schema: reqString(row, "schema", "lifecycle head anchor"),
    eventCount: reqInt(row, "eventCount", "lifecycle head anchor"),
    headEventId: reqString(row, "headEventId", "lifecycle head anchor"),
    id: reqString(row, "id", "lifecycle head anchor"),
  }
  if anchor.schema != headSchema {
    die("unsupported lifecycle head anchor schema '" ++ anchor.schema ++ "'")
  }
  let expectedId = derivedHeadId(
    ~eventCount=anchor.eventCount,
    ~headEventId=anchor.headEventId,
  )
  if anchor.id != expectedId {
    die("lifecycle head anchor fails its canonical content hash; expected " ++ expectedId)
  }
  anchor
}

let legal = (from, next) =>
  switch (from, next) {
  | (Draft, Locked)
  | (Draft, Blocked)
  | (Locked, Compiled)
  | (Locked, Blocked)
  | (Locked, Superseded)
  | (Compiled, Ready)
  | (Compiled, Blocked)
  | (Compiled, Superseded)
  | (Ready, Authorized)
  | (Ready, Blocked)
  | (Ready, Superseded)
  | (Authorized, CandidateQuarantine)
  | (Authorized, Blocked)
  | (Authorized, Superseded)
  | (CandidateQuarantine, ReviewReady)
  | (CandidateQuarantine, Unknown)
  | (CandidateQuarantine, Rejected)
  | (CandidateQuarantine, Superseded)
  | (Unknown, ReviewReady)
  | (Unknown, Rejected)
  | (Unknown, Superseded)
  | (ReviewReady, Approved)
  | (ReviewReady, Rejected)
  | (ReviewReady, Superseded)
  | (Approved, Released)
  | (Approved, Superseded)
  | (Released, Superseded)
  | (Blocked, Locked)
  | (Blocked, Compiled)
  | (Rejected, Compiled)
  | (Rejected, Superseded)
  | (Superseded, Compiled) => true
  | _ => false
  }

let requireHashes = (event: event) => {
  let require = (value, label) =>
    if value == None {
      die(lifecycleName(event.state) ++ " event requires " ++ label)
    }
  switch event.state {
  | Draft | Locked | Blocked => ()
  | Compiled | Ready | Authorized => {
      require(event.packetHash, "packetHash")
      require(event.workOrderHash, "workOrderHash")
    }
  | CandidateQuarantine => {
      require(event.packetHash, "packetHash")
      require(event.workOrderHash, "workOrderHash")
      require(event.artifactHash, "artifactHash")
    }
  | Unknown | ReviewReady | Approved | Rejected | Released => {
      require(event.packetHash, "packetHash")
      require(event.workOrderHash, "workOrderHash")
      require(event.artifactHash, "artifactHash")
      require(event.reportHash, "reportHash")
    }
  | Superseded => ()
  }
}

let requireActor = (event: event) =>
  switch event.state {
  | Authorized if event.actor != Human => die("only a human may authorize execution")
  | CandidateQuarantine if event.actor != Provider =>
    die("only the provider gateway may record a candidate")
  | Approved | Rejected if event.actor != Human =>
    die("only a human may approve or reject a candidate")
  | ReviewReady | Unknown if event.actor != System =>
    die("inspection evidence must be adjudicated by the system")
  | Released if event.actor != System => die("only the system may record release")
  | _ => ()
  }

let sortedEvents = events => {
  let copy = Js.Array2.copy(events)
  copy->Js.Array2.sortInPlaceWith((left, right) => left.sequence - right.sequence)->ignore
  copy
}

let derivedEventId = (event: event) => {
  let seed = Js.Array2.joinWith(
    [
      Belt.Int.toString(event.sequence),
      event.previousEventId->Belt.Option.getWithDefault(""),
      event.targetId,
      lifecycleName(event.state),
      actorName(event.actor),
      event.packetHash->Belt.Option.getWithDefault(""),
      event.workOrderHash->Belt.Option.getWithDefault(""),
      event.artifactHash->Belt.Option.getWithDefault(""),
      event.reportHash->Belt.Option.getWithDefault(""),
      event.reason,
    ],
    "\n",
  )
  "EVT-" ++ B.sha256Text(seed)
}

let reduce = events => {
  let ordered = sortedEvents(events)
  let ids = Js.Dict.empty()
  let sequences = Js.Dict.empty()
  let targets = Js.Dict.empty()
  let previousId = ref(None)
  ordered->Belt.Array.forEachWithIndex((index, event) => {
    let expectedSequence = index + 1
    if event.sequence != expectedSequence {
      die(
        "event sequences must be contiguous from 1; expected " ++
        Belt.Int.toString(expectedSequence) ++ " but found " ++ Belt.Int.toString(event.sequence),
      )
    }
    if event.previousEventId != previousId.contents {
      die(
        "event " ++ event.id ++ " does not chain to the preceding event",
      )
    }
    let expectedId = derivedEventId(event)
    if event.id != expectedId {
      die("event " ++ event.id ++ " fails its canonical content hash; expected " ++ expectedId)
    }
    if Js.Dict.get(ids, event.id) != None {
      die("duplicate event id '" ++ event.id ++ "'")
    }
    let sequenceKey = Belt.Int.toString(event.sequence)
    if Js.Dict.get(sequences, sequenceKey) != None {
      die("duplicate event sequence " ++ sequenceKey)
    }
    Js.Dict.set(ids, event.id, true)
    Js.Dict.set(sequences, sequenceKey, true)
    requireHashes(event)
    requireActor(event)
    let current = switch Js.Dict.get(targets, event.targetId) {
    | Some(value) => value.state
    | None => Draft
    }
    if !legal(current, event.state) {
      die(
        "illegal lifecycle transition for " ++ event.targetId ++ ": " ++
        lifecycleName(current) ++ " -> " ++ lifecycleName(event.state),
      )
    }
    Js.Dict.set(targets, event.targetId, {targetId: event.targetId, state: event.state, lastEvent: event})
    previousId := Some(event.id)
  })
  let targetRows = Js.Dict.values(targets)
  targetRows->Js.Array2.sortInPlaceWith((left, right) => compare(left.targetId, right.targetId))->ignore
  let nextSequence = switch Belt.Array.get(ordered, Belt.Array.length(ordered) - 1) {
  | Some(last) => last.sequence + 1
  | None => 1
  }
  {events: ordered, targets: targetRows, nextSequence}
}

let transition = (~events, ~event) => {
  let candidate = Belt.Array.concat(events, [event])
  reduce(candidate)->ignore
  candidate
}

let safeChild = (~stateDir, ~relative, ~label) => {
  try {
    Production_OutputSafety.manifestOutputPath(~baseDir=stateDir, ~relativePath=relative, ~label)
  } catch {
  | Production_OutputSafety.OutputSafetyError(message) => die(message)
  }
}

let eventsDir = stateDir => safeChild(~stateDir, ~relative="events", ~label="event directory")

let headPath = stateDir =>
  safeChild(~stateDir, ~relative="lifecycle-head.json", ~label="lifecycle head anchor")

let pendingHeadPath = stateDir =>
  safeChild(
    ~stateDir,
    ~relative=".lifecycle-head.pending",
    ~label="pending lifecycle head anchor",
  )

let withLock = (stateDir, work) => {
  try {
    L.withLease(
      ~stateDir,
      ~relativePath="leases/state-ledger.sqlite",
      ~legacyRelativePath="ledger.lock",
      ~resource="event ledger",
      ~waitMs=10000,
      work,
    )
  } catch {
  | L.LeaseError(message) => die("event ledger lease refused: " ++ message)
  }
}

let loadEvents = stateDir => {
  B.ensureDirPath(B.Path(eventsDir(stateDir)))
  B.readDir(B.Path(eventsDir(stateDir)))
  ->Belt.Array.keep(name => Js.String2.endsWith(name, ".json"))
  ->Belt.Array.map(name => {
    let raw = B.readText(B.Path(join2(eventsDir(stateDir), name)))
    let rows = decodeEvents("[" ++ raw ++ "]")
    switch Belt.Array.get(rows, 0) {
    | Some(row) => {
        let expectedName = Belt.Int.toString(row.sequence) ++ "-" ++ row.id ++ ".json"
        if name != expectedName {
          die(
            "event filename '" ++ name ++ "' does not match its sequence and content id '" ++
            expectedName ++ "'",
          )
        }
        row
      }
    | None => die("empty event file " ++ name)
    }
  })
}

let sameHead = (left: headAnchor, right: headAnchor) =>
  left.schema == right.schema &&
  left.eventCount == right.eventCount &&
  left.headEventId == right.headEventId &&
  left.id == right.id

let expectedHead = (snapshot: snapshot): option<headAnchor> =>
  switch Belt.Array.get(snapshot.events, Belt.Array.length(snapshot.events) - 1) {
  | Some(last) => Some(anchorForEvent(~eventCount=Belt.Array.length(snapshot.events), ~headEventId=last.id))
  | None => None
  }

let readHeadIfPresent = path =>
  B.exists(B.Path(path)) ? Some(decodeHead(B.readText(B.Path(path)))) : None

let discardAbortedPendingHead = (~stateDir, ~current: option<headAnchor>) => {
  let pendingPath = pendingHeadPath(stateDir)
  switch readHeadIfPresent(pendingPath) {
  | None => ()
  | Some(pending) => {
      let expectedCount = switch current {
      | Some(anchor) => anchor.eventCount + 1
      | None => 1
      }
      if pending.eventCount != expectedCount {
        die(
          "pending lifecycle head anchor has unexpected high-water mark " ++
          Belt.Int.toString(pending.eventCount) ++ "; expected " ++
          Belt.Int.toString(expectedCount),
        )
      }
      /* The authoritative event was never renamed into place. Under the state
         lease this pending head can only be crash residue, not a live writer. */
      B.removeFile(B.Path(pendingPath))
    }
  }
}

let loadAnchoredUnlocked = stateDir => {
  B.ensureDirPath(B.Path(stateDir))
  let snapshot = reduce(loadEvents(stateDir))
  let durable = readHeadIfPresent(headPath(stateDir))
  let expected = expectedHead(snapshot)
  switch (durable, expected) {
  | (None, None) => {
      discardAbortedPendingHead(~stateDir, ~current=None)
      snapshot
    }
  | (None, Some(expected)) => {
      let pendingPath = pendingHeadPath(stateDir)
      switch readHeadIfPresent(pendingPath) {
      | Some(pending) if sameHead(pending, expected) => {
          /* Crash recovery: the event rename completed, and the already-durable
             pending high-water record proves the exact head that was intended. */
          Production_OutputSafety.atomicRename(
            ~temporaryPath=pendingPath,
            ~destinationPath=headPath(stateDir),
          )
          snapshot
        }
      | Some(_) => die("event ledger does not match its pending lifecycle head anchor")
      | None =>
        die("event ledger has events but its durable lifecycle head anchor is missing")
      }
    }
  | (Some(_), None) =>
    die("durable lifecycle head anchor exists but the event ledger is empty")
  | (Some(durable), Some(expected)) if sameHead(durable, expected) => {
      discardAbortedPendingHead(~stateDir, ~current=Some(durable))
      snapshot
    }
  | (Some(durable), Some(expected))
    if expected.eventCount == durable.eventCount + 1 => {
      let pendingPath = pendingHeadPath(stateDir)
      switch readHeadIfPresent(pendingPath) {
      | Some(pending) if sameHead(pending, expected) => {
          Production_OutputSafety.atomicRename(
            ~temporaryPath=pendingPath,
            ~destinationPath=headPath(stateDir),
          )
          snapshot
        }
      | Some(_) => die("event ledger tail does not match its pending lifecycle head anchor")
      | None => die("event ledger contains an unanchored lifecycle tail event")
      }
    }
  | (Some(durable), Some(expected)) =>
    die(
      "event ledger high-water mismatch: durable head records " ++
      Belt.Int.toString(durable.eventCount) ++ " event(s) ending at " ++
      durable.headEventId ++ ", but disk contains " ++ Belt.Int.toString(expected.eventCount) ++
      " event(s) ending at " ++ expected.headEventId,
    )
  }
}

let load = (~stateDir) =>
  withLock(stateDir, () => loadAnchoredUnlocked(stateDir))

let withConsistentSnapshot = (~stateDir, work) =>
  withLock(stateDir, () => work(loadAnchoredUnlocked(stateDir)))

let materializedBody = snapshot => {
  let targetRows = snapshot.targets->Belt.Array.map(target => {
    let row = Js.Dict.empty()
    Js.Dict.set(row, "targetId", Js.Json.string(target.targetId))
    Js.Dict.set(row, "state", Js.Json.string(lifecycleName(target.state)))
    Js.Dict.set(row, "lastEventId", Js.Json.string(target.lastEvent.id))
    Js.Json.object_(row)
  })
  let root = Js.Dict.empty()
  Js.Dict.set(root, "schema", Js.Json.string("production.materialized-state/v2"))
  Js.Dict.set(root, "eventCount", Js.Json.number(Belt.Int.toFloat(Belt.Array.length(snapshot.events))))
  Js.Dict.set(root, "nextSequence", Js.Json.number(Belt.Int.toFloat(snapshot.nextSequence)))
  switch expectedHead(snapshot) {
  | Some(anchor) => {
      Js.Dict.set(root, "headEventId", Js.Json.string(anchor.headEventId))
      Js.Dict.set(root, "headAnchorId", Js.Json.string(anchor.id))
    }
  | None => ()
  }
  Js.Dict.set(root, "targets", Js.Json.array(targetRows))
  Js.Json.stringifyWithSpace(Js.Json.object_(root), 2) ++ "\n"
}

let writeMaterializedUnlocked = (~stateDir, ~snapshot) => {
  B.ensureDirPath(B.Path(stateDir))
  let path = safeChild(~stateDir, ~relative="current.json", ~label="materialized state")
  let temp = safeChild(~stateDir, ~relative="current.json.tmp", ~label="temporary materialized state")
  B.writeText(B.Path(temp), materializedBody(snapshot))
  Production_OutputSafety.atomicRename(~temporaryPath=temp, ~destinationPath=path)
}

let writeMaterialized = (~stateDir, ~snapshot) =>
  withLock(stateDir, () => {
    let current = loadAnchoredUnlocked(stateDir)
    let supplied = reduce(snapshot.events)
    if encodeEvents(supplied.events) != encodeEvents(current.events) ||
      supplied.targets != snapshot.targets || supplied.nextSequence != snapshot.nextSequence {
      die("refusing to materialize a stale or internally inconsistent lifecycle snapshot")
    }
    writeMaterializedUnlocked(~stateDir, ~snapshot=current)
  })

let append = (
  ~stateDir,
  ~targetId,
  ~state,
  ~actor,
  ~packetHash=?,
  ~workOrderHash=?,
  ~artifactHash=?,
  ~reportHash=?,
  ~reason,
) => {
  if Js.String2.trim(targetId) == "" || Js.String2.includes(targetId, "/") ||
    Js.String2.includes(targetId, "\\") || Js.String2.includes(targetId, "..") {
    die("unsafe target id '" ++ targetId ++ "'")
  }
  B.ensureDirPath(B.Path(stateDir))
  withLock(stateDir, () => {
    let snapshot = loadAnchoredUnlocked(stateDir)
    let previousEventId = Belt.Array.get(snapshot.events, Belt.Array.length(snapshot.events) - 1)
      ->Belt.Option.map(event => event.id)
    let eventWithoutId = {
      id: "pending",
      sequence: snapshot.nextSequence,
      previousEventId,
      targetId,
      state,
      actor,
      packetHash,
      workOrderHash,
      artifactHash,
      reportHash,
      reason,
    }
    let event = {...eventWithoutId, id: derivedEventId(eventWithoutId)}
    let events = transition(~events=snapshot.events, ~event)
    let file = safeChild(
      ~stateDir,
      ~relative="events/" ++ Belt.Int.toString(event.sequence) ++ "-" ++ event.id ++ ".json",
      ~label="lifecycle event",
    )
    let pending = safeChild(
      ~stateDir,
      ~relative="events/." ++ Belt.Int.toString(event.sequence) ++ "-" ++ event.id ++ ".pending",
      ~label="pending lifecycle event",
    )
    let body = Js.Json.stringifyWithSpace(eventToJson(event), 2) ++ "\n"
    if B.exists(B.Path(file)) {
      die("event file already exists for sequence " ++ Belt.Int.toString(event.sequence))
    }
    if !B.writeTextExclusive(B.Path(pending), body) &&
      (!B.exists(B.Path(pending)) || B.readText(B.Path(pending)) != body) {
      die("pending event file collides with different content")
    }
    let nextHead = anchorForEvent(~eventCount=event.sequence, ~headEventId=event.id)
    let pendingHead = pendingHeadPath(stateDir)
    let headBody = encodeHead(nextHead)
    if !B.writeTextExclusive(B.Path(pendingHead), headBody) &&
      (!B.exists(B.Path(pendingHead)) || B.readText(B.Path(pendingHead)) != headBody) {
      die("pending lifecycle head anchor collides with different content")
    }
    Production_OutputSafety.atomicRename(~temporaryPath=pending, ~destinationPath=file)
    Production_OutputSafety.atomicRename(
      ~temporaryPath=pendingHead,
      ~destinationPath=headPath(stateDir),
    )
    writeMaterializedUnlocked(~stateDir, ~snapshot=reduce(events))
    event
  })
}
