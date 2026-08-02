/* Uses the fake model: "slow" times out, then "fast" must come from a fresh
   process and must not receive the old process's late result. */

let main = async () => {
  let timedOut = ref(false)
  try {
    let _ = await Session.ask("slow")
  } catch {
  | Session.SessionError(m) => {
      timedOut := Js.String2.includes(m, "timed out")
    }
  | _ => ()
  }
  assert(timedOut.contents)
  let fast = await Session.ask("fast")
  assert(fast == "echo:fast")
  assert(Session.callsMade() == 2)
  Session.close()
  Js.log("OK - timeout cannot leak a late result into the next turn")
}

main()->ignore
