/* See Session.resi for the contract. The default integration is now a
   provider-neutral native-worker handoff. A host agent prepares a job here,
   delegates it through its own native subagent mechanism, and places the
   response at the job's declared responsePath. The legacy Claude process is
   available only behind an explicit legacy opt-in; tests use an explicit fake. */

type childProcess
type writable
type readable
type timerId

type spawnOpts = {stdio: array<string>}
@module("child_process") external spawn: (string, array<string>, spawnOpts) => childProcess = "spawn"

@get external stdinOf: childProcess => writable = "stdin"
@get external stdoutOf: childProcess => readable = "stdout"
@send external write: (writable, string) => bool = "write"
@send external endStream: writable => unit = "end"
@send external kill: childProcess => bool = "kill"
@send external setEncoding: (readable, string) => unit = "setEncoding"
@send external onData: (readable, @as("data") _, string => unit) => unit = "on"
@send external onProcExit: (childProcess, @as("exit") _, Js.Nullable.t<int> => unit) => unit = "on"
@send external unrefChild: childProcess => unit = "unref"
@send external unrefR: readable => unit = "unref"
@send external unrefW: writable => unit = "unref"

@val external setTimeout: (unit => unit, int) => timerId = "setTimeout"
@val external clearTimeout: timerId => unit = "clearTimeout"
@val @scope("process") external env: Js.Dict.t<string> = "env"

type hash
@module("crypto") external createHash: string => hash = "createHash"
@send external hUpdate: (hash, string) => hash = "update"
@send external hDigest: (hash, string) => string = "digest"

exception SessionError(string)

type nativeMode = {provider: string, jobDir: string}
type executionMode =
  | Native(nativeMode)
  | FakeProcess(string)
  | LegacyClaudeProcess(string)
  | RefuseProcess(string)

let envIs = (key, expected) => Js.Dict.get(env, key) == Some(expected)

/* Provider identity is asserted by the trusted host/orchestrator and recorded
   in the handoff. This module validates the closed set but never selects a
   different provider on the host's behalf. */
let executionMode = switch Js.Dict.get(env, "STUDIO_NATIVE_WORKER_PROVIDER") {
| Some(provider) if provider == "codex" || provider == "claude" =>
  switch Js.Dict.get(env, "STUDIO_NATIVE_JOB_DIR") {
  | Some(jobDir) if Js.String2.trim(jobDir) != "" => Native({provider, jobDir})
  | _ => RefuseProcess("STUDIO_NATIVE_JOB_DIR is required for native-worker handoff")
  }
| Some(provider) =>
  RefuseProcess(
    "STUDIO_NATIVE_WORKER_PROVIDER must be 'codex' or 'claude'; got '" ++ provider ++ "'",
  )
| None if envIs("STUDIO_FAKE_WORKER", "1") =>
  switch Js.Dict.get(env, "STUDIO_FAKE_WORKER_BIN") {
  | Some(bin) if Js.String2.trim(bin) != "" => FakeProcess(bin)
  | _ => RefuseProcess("STUDIO_FAKE_WORKER=1 requires STUDIO_FAKE_WORKER_BIN")
  }
| None if envIs("STUDIO_ALLOW_CLAUDE_CLI", "1") =>
  LegacyClaudeProcess(Js.Dict.get(env, "CLAUDE_STUDIO_BIN")->Belt.Option.getWithDefault("claude"))
| None =>
  RefuseProcess(
    "no native worker handoff is configured; refusing to choose or spawn a model provider",
  )
}

let budgetName = switch executionMode {
| Native(_) | FakeProcess(_) | RefuseProcess(_) => "STUDIO_WORKER_BUDGET"
| LegacyClaudeProcess(_) => "CLAUDE_STUDIO_BUDGET"
}

/* The hard call cap is deliberately NOT defaulted. A run without a human-held
   budget refuses before it emits a native job or starts an opted-in process. */
let cap: result<int, string> = switch Js.Dict.get(env, budgetName) {
| None => Error(budgetName ++ " is not set; refusing a model call")
| Some(s) =>
  switch Belt.Int.fromString(s) {
  | Some(n) if n > 0 => Ok(n)
  | _ => Error(budgetName ++ " must be a positive integer; got '" ++ s ++ "'")
  }
}

let processBin = switch executionMode {
| FakeProcess(bin) | LegacyClaudeProcess(bin) => bin
| Native(_) | RefuseProcess(_) => ""
}
/* Overridable so the fake-process tests can prove timeout isolation in
   milliseconds rather than waiting two and a half minutes. */
let timeoutSetting = switch Js.Dict.get(env, "STUDIO_WORKER_TIMEOUT_MS") {
| Some(s) => Some(s)
| None => Js.Dict.get(env, "CLAUDE_STUDIO_TIMEOUT_MS")
}
let timeoutMs = switch timeoutSetting {
| Some(s) =>
  switch Belt.Int.fromString(s) {
  | Some(n) if n > 0 => n
  | _ => 150000
  }
| None => 150000
}
let calls = ref(0)

/* ---- the one warm process, lazily spawned, reused for every turn ---- */
let child: ref<option<childProcess>> = ref(None)
let buf = ref("")
/* Each spawned process gets a generation. Callbacks from a killed/timed-out
   generation are ignored, so a late result can never settle the next turn. */
let generation = ref(0)
/* there is only ever ONE turn in flight (serialized below), so a single slot
   for its resolver/rejecter/timeout is all that's needed. */
let pending: ref<option<string => unit>> = ref(None)
let pendingErr: ref<option<exn => unit>> = ref(None)
let pendingTimer: ref<option<timerId>> = ref(None)

let clearPendingTimer = () =>
  switch pendingTimer.contents {
  | Some(t) => clearTimeout(t); pendingTimer := None
  | None => ()
  }

let settleOk = (text: string) => {
  clearPendingTimer()
  let r = pending.contents
  pending := None
  pendingErr := None
  switch r {
  | Some(f) => f(text)
  | None => ()
  }
}

let settleErr = (msg: string) => {
  clearPendingTimer()
  let r = pendingErr.contents
  pending := None
  pendingErr := None
  switch r {
  | Some(f) => f(SessionError(msg))
  | None => ()
  }
}

/* ---- json helpers ---- */
let field = (obj, k) => Js.Dict.get(obj, k)
let asStr = j => j->Belt.Option.flatMap(Js.Json.decodeString)
let asNum = j => j->Belt.Option.flatMap(Js.Json.decodeNumber)
let asObj = j => j->Belt.Option.flatMap(Js.Json.decodeObject)
let asBool = j => j->Belt.Option.flatMap(Js.Json.decodeBoolean)

/* finally: real per-turn cost, straight from the model's own report. */
let logUsage = obj =>
  switch field(obj, "usage")->asObj {
  | None => ()
  | Some(u) =>
    let n = k => field(u, k)->asNum->Belt.Option.getWithDefault(0.0)->Belt.Float.toInt
    let cost = field(obj, "total_cost_usd")->asNum->Belt.Option.getWithDefault(0.0)
    Js.log(
      "[session] turn " ++
      Belt.Int.toString(calls.contents) ++
      " in=" ++
      Belt.Int.toString(n("input_tokens")) ++
      " out=" ++
      Belt.Int.toString(n("output_tokens")) ++
      " cacheRead=" ++
      Belt.Int.toString(n("cache_read_input_tokens")) ++
      " cacheWrite=" ++
      Belt.Int.toString(n("cache_creation_input_tokens")) ++
      " cost=$" ++
      Js.Float.toString(cost),
    )
  }

/* one full event line off the stream. We only act on the terminal `result`
   event; init/assistant/partial events flow past untouched. */
let interpret = (line: string): unit => {
  let parsed = try Some(Js.Json.parseExn(line)) catch {
  | _ => None
  }
  switch parsed->Belt.Option.flatMap(Js.Json.decodeObject) {
  | None => ()
  | Some(obj) =>
    switch field(obj, "type")->asStr {
    | Some("result") =>
      logUsage(obj)
      let isErr = field(obj, "is_error")->asBool->Belt.Option.getWithDefault(false)
      let text = field(obj, "result")->asStr->Belt.Option.getWithDefault("")
      if isErr {
        settleErr("model returned an error: " ++ text)
      } else {
        settleOk(Js.String2.trim(text))
      }
    | _ => ()
    }
  }
}

let onChunk = (chunk: string) => {
  buf := buf.contents ++ chunk
  let rec drain = () =>
    switch Js.String2.indexOf(buf.contents, "\n") {
    | -1 => ()
    | i =>
      let line = Js.String2.slice(buf.contents, ~from=0, ~to_=i)
      buf := Js.String2.sliceToEnd(buf.contents, ~from=i + 1)
      interpret(line)
      drain()
    }
  drain()
}

let ensureChild = (): childProcess =>
  switch child.contents {
  | Some(c) => c
  | None =>
    generation := generation.contents + 1
    let mine = generation.contents
    let c = spawn(
      processBin,
      [
        "-p",
        "--input-format",
        "stream-json",
        "--output-format",
        "stream-json",
        "--verbose",
        /* lean: no tools (~15k of schemas), no dynamic memory/git sections, a
           minimal neutral system prompt. The remaining ~10k harness base is
           cached on turn 1 and reused thereafter (that's the warm win). The
           real persona + task ride in each user message. */
        "--tools",
        "",
        "--exclude-dynamic-system-prompt-sections",
        "--system-prompt",
        "You are a precise assistant. Follow the user's instructions exactly. Output only what is asked, with no preamble or commentary.",
      ],
      {stdio: ["pipe", "pipe", "inherit"]},
    )
    setEncoding(stdoutOf(c), "utf8")
    onData(stdoutOf(c), chunk => {
      if generation.contents == mine {
        onChunk(chunk)
      }
    })
    onProcExit(c, _ => {
      if generation.contents == mine {
        child := None
        buf := ""
        settleErr("the claude process exited before answering")
      }
    })
    /* unref so a forgotten `close` can't hang the run forever; an in-flight
       turn is kept alive by its own timeout timer, so events still arrive. */
    unrefChild(c)
    unrefR(stdoutOf(c))
    unrefW(stdinOf(c))
    child := Some(c)
    c
  }

/* Invalidate before killing: the process can emit more data, or its exit event
   can arrive after a replacement has already started. Both callbacks then carry
   an old generation and are harmless. */
let abortChild = (c: childProcess, mine: int): unit => {
  if generation.contents == mine {
    child := None
    buf := ""
    generation := generation.contents + 1
    kill(c)->ignore
  }
}

/* one user message in -> one result line out. */
let userMsg = (prompt: string): string => {
  let blk = Js.Dict.empty()
  Js.Dict.set(blk, "type", Js.Json.string("text"))
  Js.Dict.set(blk, "text", Js.Json.string(prompt))
  let m = Js.Dict.empty()
  Js.Dict.set(m, "role", Js.Json.string("user"))
  Js.Dict.set(m, "content", Js.Json.array([Js.Json.object_(blk)]))
  let o = Js.Dict.empty()
  Js.Dict.set(o, "type", Js.Json.string("user"))
  Js.Dict.set(o, "message", Js.Json.object_(m))
  Js.Json.stringify(Js.Json.object_(o)) ++ "\n"
}

let waitForResult = (prompt: string): promise<string> =>
  Js.Promise.make((~resolve, ~reject) => {
    let c = ensureChild()
    let mine = generation.contents
    pending := Some(text => resolve(. text))
    pendingErr := Some(e => reject(. e))
    pendingTimer := Some(
      setTimeout(() => {
        abortChild(c, mine)
        settleErr("model turn timed out")
      }, timeoutMs),
    )
    write(stdinOf(c), userMsg(prompt))->ignore
  })

let sha256 = s => createHash("sha256")->hUpdate(s)->hDigest("hex")

let unresolvedJobOtherThan = (~jobDir, ~currentName): option<string> => {
  let jobSuffix = ".job.json"
  Cinema_Backends.readDir(Cinema_Backends.Path(jobDir))->Belt.Array.getBy(name => {
    if name == currentName || !Js.String2.endsWith(name, jobSuffix) {
      false
    } else {
      let stem = Js.String2.slice(
        name,
        ~from=0,
        ~to_=Js.String2.length(name) - Js.String2.length(jobSuffix),
      )
      !Cinema_Backends.exists(Cinema_Backends.Path(jobDir ++ "/" ++ stem ++ ".response.txt"))
    }
  })
}

let nativeResult = ({provider, jobDir}: nativeMode, prompt: string, turn: int): string => {
  let promptHash = sha256(prompt)
  let shortHash = Js.String2.slice(promptHash, ~from=0, ~to_=12)
  let stem = "turn-" ++ Belt.Int.toString(turn) ++ "-" ++ shortHash
  let jobName = stem ++ ".job.json"
  let jobPath = jobDir ++ "/" ++ jobName
  let responsePath = jobDir ++ "/" ++ stem ++ ".response.txt"
  let response = Cinema_Backends.Path(responsePath)
  if Cinema_Backends.exists(response) {
    let text = Cinema_Backends.readText(response)->Js.String2.trim
    if text == "" {
      raise(SessionError("native worker response is empty: " ++ responsePath))
    }
    text
  } else {
    Cinema_Backends.ensureDirPath(Cinema_Backends.Path(jobDir))
    switch unresolvedJobOtherThan(~jobDir, ~currentName=jobName) {
    | Some(pendingJob) =>
      raise(
        SessionError(
          "NATIVE_WORKER_PENDING — complete " ++
          jobDir ++ "/" ++ pendingJob ++ " before requesting another worker job",
        ),
      )
    | None =>
      if !Cinema_Backends.exists(Cinema_Backends.Path(jobPath)) {
        let job = Js.Dict.empty()
        Js.Dict.set(job, "schemaVersion", Js.Json.number(1.0))
        Js.Dict.set(job, "provider", Js.Json.string(provider))
        Js.Dict.set(job, "turn", Js.Json.number(Belt.Int.toFloat(turn)))
        Js.Dict.set(job, "promptHash", Js.Json.string(promptHash))
        Js.Dict.set(job, "prompt", Js.Json.string(prompt))
        Js.Dict.set(job, "responsePath", Js.Json.string(responsePath))
        Js.Dict.set(
          job,
          "instruction",
          Js.Json.string(
            "Use one native " ++
            provider ++
            " worker for this bounded job. Write only its final response to responsePath; do not use another provider or a command-line model worker.",
          ),
        )
        Cinema_Backends.writeText(
          Cinema_Backends.Path(jobPath),
          Js.Json.stringifyWithSpace(Js.Json.object_(job), 2),
        )
      }
      raise(
        SessionError(
          "NATIVE_WORKER_REQUIRED — delegate " ++
          jobPath ++ " through a native " ++ provider ++ " worker, then retry this turn",
        ),
      )
    }
  }
}

/* the actual work of one turn; runs only when its place in the queue comes up,
   so the cap is counted against turns that truly execute, in order. */
let doTurn = async (prompt: string): string => {
  let limit = switch cap {
  | Error(m) => raise(SessionError(m))
  | Ok(n) => n
  }
  if calls.contents + 1 > limit {
    raise(SessionError("model cap reached (" ++ Belt.Int.toString(limit) ++ ")"))
  }
  switch executionMode {
  | Native(mode) => {
      let answer = nativeResult(mode, prompt, calls.contents + 1)
      calls := calls.contents + 1
      answer
    }
  | FakeProcess(_) | LegacyClaudeProcess(_) => {
      calls := calls.contents + 1 /* count only turns that actually reach the model */
      await waitForResult(prompt)
    }
  | RefuseProcess(reason) => raise(SessionError(reason))
  }
}

/* the serialization queue. `gate` resolves when the previous turn is fully
   settled. Each `ask` reads it, chains its work after it, and installs its own
   completion as the new gate -- all synchronously -- so even two asks fired in
   the same tick run strictly one after the other. There is no parallel path. */
let gate: ref<promise<unit>> = ref(Js.Promise.resolve())

let ask = (prompt: string): promise<string> => {
  let prev = gate.contents
  let run = async () => {
    try await prev catch {
    | _ => ()
    }
    await doTurn(prompt)
  }
  let result = run()
  gate :=
    (
      async () =>
        switch await result {
        | _ => ()
        | exception _ => ()
        }
    )()
  result
}

let callsMade = () => calls.contents

let workerProvider = () =>
  switch executionMode {
  | Native({provider}) => provider
  | FakeProcess(_) => "fake"
  | LegacyClaudeProcess(_) => "claude-cli"
  | RefuseProcess(_) => "none"
  }

let close = () =>
  switch child.contents {
  | None => ()
  | Some(c) =>
    child := None
    buf := ""
    generation := generation.contents + 1
    endStream(stdinOf(c))
    kill(c)->ignore
  }
