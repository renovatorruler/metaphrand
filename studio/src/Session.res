/* See Session.resi for the contract. This is the warm-session implementation:
   ONE long-lived `claude` process, booted once, fed many turns over a pipe. */

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

exception SessionError(string)

/* the hard call cap, read from the environment so YOU own it. Low default. */
let cap = switch Js.Dict.get(env, "CLAUDE_STUDIO_BUDGET") {
| Some(s) => Belt.Int.fromString(s)->Belt.Option.getWithDefault(8)
| None => 8
}
/* the binary; overridable only so tests can point at a fake model (zero spend). */
let bin = switch Js.Dict.get(env, "CLAUDE_STUDIO_BIN") {
| Some(b) => b
| None => "claude"
}
let timeoutMs = 150000
let calls = ref(0)

/* ---- the one warm process, lazily spawned, reused for every turn ---- */
let child: ref<option<childProcess>> = ref(None)
let buf = ref("")
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
    let c = spawn(
      bin,
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
    onData(stdoutOf(c), onChunk)
    onProcExit(c, _ => {
      child := None
      settleErr("the claude process exited before answering")
    })
    /* unref so a forgotten `close` can't hang the run forever; an in-flight
       turn is kept alive by its own timeout timer, so events still arrive. */
    unrefChild(c)
    unrefR(stdoutOf(c))
    unrefW(stdinOf(c))
    child := Some(c)
    c
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
    pending := Some(text => resolve(. text))
    pendingErr := Some(e => reject(. e))
    pendingTimer := Some(setTimeout(() => settleErr("model turn timed out"), timeoutMs))
    let c = ensureChild()
    write(stdinOf(c), userMsg(prompt))->ignore
  })

/* the actual work of one turn; runs only when its place in the queue comes up,
   so the cap is counted against turns that truly execute, in order. */
let doTurn = async (prompt: string): string => {
  if calls.contents + 1 > cap {
    raise(
      SessionError(
        "model cap reached (" ++
        Belt.Int.toString(cap) ++ "); set CLAUDE_STUDIO_BUDGET to allow more",
      ),
    )
  }
  calls := calls.contents + 1 /* count only turns that actually reach the model */
  await waitForResult(prompt)
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

let close = () =>
  switch child.contents {
  | None => ()
  | Some(c) =>
    endStream(stdinOf(c))
    kill(c)->ignore
    child := None
  }
