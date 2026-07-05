/* SKY KING — extend a finished scene with a new beat WITHOUT re-rolling it.
   Usage: node src/SkyKing_Extend.res.mjs <scene-id> <afterLineIndex> <brief-file>
   Generates the beat in context, gates the spliced whole, re-emits PENDING
   (run SkyKing_Lift afterward — the doctrine pass stays unskippable). */
@val @scope("process") external argv: array<string> = "argv"

let dir = "/Users/dusty/dev/brehon-law/stories/sky-king"

let main = async () => {
  let id = Belt.Array.get(argv, 2)->Belt.Option.getWithDefault("")
  let after = Belt.Array.get(argv, 3)->Belt.Option.flatMap(Belt.Int.fromString)
  let briefFile = Belt.Array.get(argv, 4)->Belt.Option.getWithDefault("")
  switch (id, after, briefFile) {
  | ("", _, _) | (_, None, _) | (_, _, "") =>
    Js.log("usage: node src/SkyKing_Extend.res.mjs <scene-id> <afterLineIndex> <brief-file>")
  | (id, Some(n), bf) =>
    try {
      let path = Cinema_Backends.Path(dir ++ "/" ++ id ++ ".scene.txt")
      let brief = Cinema_Backends.readText(Cinema_Backends.Path(bf))
      let sc = await Write.extendScene(~path, ~afterLine=n, ~brief, ~maxTries=4)
      let _ = Write.emit(sc, ~txt=path)
      Js.log("=== EXTENDED: " ++ id ++ " (after line " ++ Belt.Int.toString(n) ++ ") ===\n")
      Js.log(Cinema_Backends.readText(path))
      Js.log("\n=== VERIFY (expect PENDING until lift) ===")
      switch Write.verify(path) {
      | Ok() => Js.log("VERIFY OK")
      | Error(m) => Js.log("VERIFY: " ++ m)
      }
    } catch {
    | Write.WriteError(m) => Js.log("EXTEND FAILED:\n" ++ m)
    | Session.SessionError(m) => Js.log("SESSION: " ++ m)
    }
    Session.close()
  }
}

main()->ignore
