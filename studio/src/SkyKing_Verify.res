/* The wall you can check. `node src/SkyKing_Verify.res.mjs <scene.txt>` recomputes
   the scene hash, confronts it with the receipt, and re-runs the gate. If I
   hand-edited the scene, or wrote one with no engine behind it, this says so. */
@val @scope("process") external argv: array<string> = "argv"

let () =
  switch Belt.Array.get(argv, 2) {
  | None => Js.log("usage: SkyKing_Verify <scene.txt>")
  | Some(p) =>
    switch Write.verify(Cinema_Backends.Path(p)) {
    | Ok() => Js.log("VERIFY OK — " ++ p ++ " matches its receipt and passes the gate")
    | Error(msg) => Js.log("VERIFY FAILED — " ++ msg)
    }
  }
