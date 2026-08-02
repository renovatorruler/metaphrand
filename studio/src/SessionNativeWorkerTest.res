/* Zero-spend proof of the native-worker handoff. The first ask emits a job and
   refuses. Supplying the declared response lets the exact same turn complete;
   no provider process is spawned by Session. */

open Cinema_Backends

@val @scope("process") external env: Js.Dict.t<string> = "env"

let fail = message => {
  Js.log("FAIL - " ++ message)
  assert(false)
}

let jsonString = (o, key) =>
  Js.Dict.get(o, key)
  ->Belt.Option.flatMap(Js.Json.decodeString)
  ->Belt.Option.getWithDefault("")

let main = async () => {
  let jobDir = Js.Dict.get(env, "STUDIO_NATIVE_JOB_DIR")->Belt.Option.getExn
  assert(Session.workerProvider() == "codex")
  let requested = ref(false)
  try {
    let _ = await Session.ask("write one bounded native-worker response")
  } catch {
  | Session.SessionError(message) =>
    requested := Js.String2.includes(message, "NATIVE_WORKER_REQUIRED")
  | _ => ()
  }
  if !requested.contents {
    fail("missing native response must emit a job and refuse")
  }
  assert(Session.callsMade() == 0)

  let jobs =
    readDir(Path(jobDir))->Belt.Array.keep(name => Js.String2.endsWith(name, ".job.json"))
  if Belt.Array.length(jobs) != 1 {
    fail("expected exactly one native-worker job")
  }
  let job =
    readText(Path(jobDir ++ "/" ++ Belt.Array.getExn(jobs, 0)))
    ->Js.Json.parseExn
    ->Js.Json.decodeObject
    ->Belt.Option.getExn
  assert(jsonString(job, "provider") == "codex")
  assert(jsonString(job, "prompt") == "write one bounded native-worker response")
  assert(Js.String2.length(jsonString(job, "promptHash")) == 64)
  let responsePath = jsonString(job, "responsePath")
  if responsePath == "" {
    fail("job must declare its response path")
  }

  let pending = ref(false)
  try {
    let _ = await Session.ask("must wait behind the unresolved native job")
  } catch {
  | Session.SessionError(message) =>
    pending := Js.String2.includes(message, "NATIVE_WORKER_PENDING")
  | _ => ()
  }
  if !pending.contents {
    fail("a second prompt must wait behind the unresolved native job")
  }
  assert(Session.callsMade() == 0)
  let remainingJobs =
    readDir(Path(jobDir))->Belt.Array.keep(name => Js.String2.endsWith(name, ".job.json"))
  assert(Belt.Array.length(remainingJobs) == 1)

  writeText(Path(responsePath), "native worker answer\n")
  let answer = await Session.ask("write one bounded native-worker response")
  assert(answer == "native worker answer")
  assert(Session.callsMade() == 1)

  let capped = ref(false)
  try {
    let _ = await Session.ask("another turn")
  } catch {
  | Session.SessionError(message) => capped := Js.String2.includes(message, "model cap reached")
  | _ => ()
  }
  assert(capped.contents)
  Session.close()
  Js.log("OK - native worker handoff is provider-bound, resumable, and capped")
}

main()->ignore
