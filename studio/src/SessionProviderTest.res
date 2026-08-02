/* A positive legacy budget is not permission to choose Claude. Without an
   explicit native handoff, fake flag, or legacy CLI opt-in, Session fails
   before spawning any process. */

let main = async () => {
  let refused = ref(false)
  try {
    let _ = await Session.ask("must not select a provider")
  } catch {
  | Session.SessionError(message) =>
    refused :=
      Js.String2.includes(message, "refusing to choose or spawn a model provider") ||
      Js.String2.includes(message, "must be 'codex' or 'claude'")
  | _ => ()
  }
  assert(refused.contents)
  assert(Session.callsMade() == 0)
  Session.close()
  Js.log("OK - Session cannot select a real provider implicitly")
}

main()->ignore
