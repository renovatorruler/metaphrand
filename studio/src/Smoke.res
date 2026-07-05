/* Zero-spend smoke test of the warm Session. Point CLAUDE_STUDIO_BIN at the fake
   model and run: `node src/Smoke.res.mjs`. Proves: one boot, two turns over the
   same process, serialization (despite the fake replying to turn 1 slowly), the
   usage telemetry, and a clean shutdown. */

let try_ = async (label, p) =>
  switch await p {
  | reply => Js.log(label ++ " = " ++ reply)
  | exception Session.SessionError(m) => Js.log(label ++ " REFUSED: " ++ m)
  | exception _ => Js.log(label ++ " failed")
  }

let main = async () => {
  /* fire BOTH in the same tick, on purpose: the queue, not luck, must order them */
  let a = Session.ask("hello")
  let b = Session.ask("world")
  await try_("reply A", a)
  await try_("reply B", b)
  Js.log("calls made = " ++ Belt.Int.toString(Session.callsMade()))
  Session.close()
}

main()->ignore
