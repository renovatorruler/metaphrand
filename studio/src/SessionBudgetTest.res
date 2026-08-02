/* Run once with STUDIO_WORKER_BUDGET absent and once with an invalid value.
   Neither case may spawn a process. */

let main = async () => {
  let refused = ref(false)
  try {
    let _ = await Session.ask("must not run")
  } catch {
  | Session.SessionError(m) => {
      refused :=
        Js.String2.includes(m, "STUDIO_WORKER_BUDGET is not set") ||
        Js.String2.includes(m, "must be a positive integer")
    }
  | _ => ()
  }
  assert(refused.contents)
  assert(Session.callsMade() == 0)
  Session.close()
  Js.log("OK - missing/invalid model budget refused before spawn")
}

main()->ignore
