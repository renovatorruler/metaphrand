/* Kuku_Intact — a spend-free census of receipts under a directory.

   Usage: node src/Kuku_Intact.res.mjs <dir>

   For every <asset>.gen.json found under <dir> it reports whether the sibling
   asset is INTACT under Kuku_Engine.receiptIntact: the receipt exists, every
   reference it was generated from still hashes the same at the recorded path,
   and the asset's own pixels are the ones the receipt recorded. It generates
   nothing and spends nothing, so it is the right check after a move or a
   rename: run it before, run it after, the two lists must agree. */
@module("fs") external readdirSync: (string, {"recursive": bool}) => array<string> = "readdirSync"
@module("path") external join: (string, string) => string = "join"
@val @scope("process") external argv: array<string> = "argv"

let () = {
  let dir = switch Belt.Array.get(argv, 2) {
  | Some(d) => d
  | None => "."
  }
  let receipts = Js.Array2.filter(readdirSync(dir, {"recursive": true}), f =>
    Js.String2.endsWith(f, ".gen.json")
  )
  let bad: array<string> = []
  Js.Array2.forEach(receipts, f => {
    let asset = join(dir, Js.String2.slice(f, ~from=0, ~to_=Js.String2.length(f) - 9))
    if !Kuku_Engine.receiptIntact(asset) {
      ignore(Js.Array2.push(bad, asset))
    }
  })
  Js.Array2.forEach(Js.Array2.sortInPlace(bad), b => Js.log("NOT INTACT " ++ b))
  Js.log(
    Belt.Int.toString(Js.Array2.length(receipts) - Js.Array2.length(bad)) ++
    " intact, " ++
    Belt.Int.toString(Js.Array2.length(bad)) ++
    " not, of " ++
    Belt.Int.toString(Js.Array2.length(receipts)) ++
    " receipts under " ++
    dir,
  )
}
