module B = Cinema_Backends
module O = Production_OutputSafety

exception LeaseError(string)

type database
type databaseOptions = {timeout: int}

@module("better-sqlite3") @new
external openDatabase: (string, databaseOptions) => database = "default"
@send external execute: (database, string) => unit = "exec"
@send external closeDatabase: database => unit = "close"
@get external errorCode: Js.Exn.t => Js.Nullable.t<string> = "code"

@val @scope("process") external processPid: int = "pid"
@val @scope("process") external processKill: (int, int) => unit = "kill"
@module("node:path") external dirname: string => string = "dirname"

type t = {
  database: database,
  token: string,
  path: string,
  resource: string,
  released: ref<bool>,
}

let die = message => raise(LeaseError(message))

let safe = (~stateDir, ~relativePath, ~label) => {
  B.ensureDirPath(B.Path(stateDir))
  try {
    O.manifestOutputPath(~baseDir=stateDir, ~relativePath, ~label)
  } catch {
  | O.OutputSafetyError(message) => die(message)
  }
}

let jsonObject = (raw, label) =>
  try {
    raw->Js.Json.parseExn->Js.Json.decodeObject->Belt.Option.getExn
  } catch {
  | _ => die(label ++ " is unreadable; refusing to guess ownership")
  }

let legacyPid = (raw, label) => {
  let row = jsonObject(raw, label)
  switch Js.Dict.get(row, "pid")->Belt.Option.flatMap(Js.Json.decodeNumber) {
  | Some(value) => {
      let pid = Js.Math.floor_int(value)
      if pid <= 0 || Belt.Int.toFloat(pid) != value {
        die(label ++ " has an invalid owner pid")
      }
      pid
    }
  | None => die(label ++ " has no valid owner pid")
  }
}

/* EPERM proves that the process exists but is owned by somebody else. Unknown
   probe errors fail closed as alive rather than converting uncertainty into
   permission to overlap an older implementation. */
let pidAlive = pid =>
  try {
    processKill(pid, 0)
    true
  } catch {
  | Js.Exn.Error(error) =>
    switch errorCode(error)->Js.Nullable.toOption {
    | Some("ESRCH") => false
    | _ => true
    }
  | _ => true
  }

let checkLegacyLease = (~stateDir, ~relativePath, ~resource) => {
  let path = safe(
    ~stateDir,
    ~relativePath,
    ~label=resource ++ " legacy lease compatibility path",
  )
  if B.exists(B.Path(path)) {
    let raw = try {
      Some(B.readText(B.Path(path)))
    } catch {
    | B.BackendError(_) => B.exists(B.Path(path)) ? None : Some("")
    }
    switch raw {
    | None => die(resource ++ " legacy lease cannot be read; refusing concurrent ownership")
    | Some("") if !B.exists(B.Path(path)) => ()
    | Some(value) => {
        let pid = legacyPid(value, resource ++ " legacy lease")
        if pidAlive(pid) {
          die(resource ++ " is held by a live legacy owner")
        }
        /* A dead legacy marker is intentionally left in place. New code no
           longer uses it for ownership, so deleting it would add a race while
           providing no safety. Its dead PID is rechecked on every acquisition. */
      }
    }
  }
}

let counter = ref(0)

let nextToken = (~path, ~resource) => {
  counter := counter.contents + 1
  "LEASE-" ++
  B.sha256Text(
    resource ++ "\u{001f}" ++ path ++ "\u{001f}" ++ Belt.Int.toString(processPid) ++
    "\u{001f}" ++ Js.Float.toString(Js.Date.now()) ++ "\u{001f}" ++
    Belt.Int.toString(counter.contents),
  )
}

let closeQuietly = database =>
  try {
    closeDatabase(database)
  } catch {
  | _ => ()
  }

let acquire = (
  ~stateDir,
  ~relativePath,
  ~resource,
  ~legacyRelativePath=?,
  ~waitMs=0,
) => {
  if Js.String2.trim(resource) == "" {
    die("lease resource must not be empty")
  }
  if waitMs < 0 || waitMs > 10000 {
    die("lease wait must be between 0 and 10000 milliseconds")
  }
  switch legacyRelativePath {
  | Some(relativePath) => checkLegacyLease(~stateDir, ~relativePath, ~resource)
  | None => ()
  }
  let path = safe(~stateDir, ~relativePath, ~label=resource ++ " lease database")
  B.ensureDirPath(B.Path(dirname(path)))
  /* Mint all fallible diagnostic data before crossing the acquisition
     boundary, leaving no userland operation between BEGIN IMMEDIATE and the
     returned opaque handle. */
  let token = nextToken(~path, ~resource)
  let database = try {
    openDatabase(path, {timeout: waitMs})
  } catch {
  | Js.Exn.Error(error) =>
    die(
      resource ++ " lease database could not be opened: " ++
      Js.Exn.message(error)->Belt.Option.getWithDefault("unknown SQLite error"),
    )
  }
  try {
    /* BEGIN IMMEDIATE obtains SQLite's cross-process RESERVED lock. Nothing is
       committed to the lease database: the live connection is the capability. */
    execute(database, "BEGIN IMMEDIATE")
    {
      database,
      token,
      path,
      resource,
      released: ref(false),
    }
  } catch {
  | Js.Exn.Error(error) => {
      closeQuietly(database)
      let code = errorCode(error)->Js.Nullable.toOption
      if code == Some("SQLITE_BUSY") || code == Some("SQLITE_LOCKED") {
        die(resource ++ " is held by another owner")
      }
      die(
        resource ++ " lease acquisition failed: " ++
        Js.Exn.message(error)->Belt.Option.getWithDefault("unknown SQLite error"),
      )
    }
  | exception_ => {
      closeQuietly(database)
      raise(exception_)
    }
  }
}

let release = lease => {
  if !lease.released.contents {
    /* close() rolls back the empty transaction and releases only this
       connection's kernel lock; no shared filesystem name is unlinked. */
    try {
      closeDatabase(lease.database)
      lease.released := true
    } catch {
    | Js.Exn.Error(error) =>
      die(
        lease.resource ++ " lease release failed: " ++
        Js.Exn.message(error)->Belt.Option.getWithDefault("unknown SQLite error"),
      )
    }
  }
}

let ownerToken = lease => lease.token

let withLease = (
  ~stateDir,
  ~relativePath,
  ~resource,
  ~legacyRelativePath=?,
  ~waitMs=?,
  work,
) => {
  let lease = acquire(~stateDir, ~relativePath, ~resource, ~legacyRelativePath?, ~waitMs?)
  try {
    let result = work()
    release(lease)
    result
  } catch {
  | exception_ => {
      try {
        release(lease)
      } catch {
      | _ => ()
      }
      raise(exception_)
    }
  }
}
