/* Kuku_Spend.res — a local, append-only ledger of everything we pay for.

   The provider's job records carry no cost and no folder, and the account is
   shared with other sessions, so a balance delta measures the whole household
   rather than this episode. Every generation this engine makes therefore writes
   its own line here, tagged with the episode and the shot it belongs to. The
   question "what has EP10 cost" is then a local query that no other session can
   disturb.

   One JSON object per line, appended, never rewritten:
     {"at":"…","episode":"EP10","shot":"h13_bell_taken","kind":"still",
      "model":"nano_banana_pro","credits":2,"note":"…"}

   Report:  node src/Kuku_Spend.res.mjs report [episode] */

@module("fs") external appendFileSync: (string, string) => unit = "appendFileSync"
@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external existsSync: string => bool = "existsSync"
@scope("process") @val external argv: array<string> = "argv"
@scope("Date") @val external now: unit => float = "now"
@new external mkDate: float => Js.Date.t = "Date"

let ledger = "../stories/kuku/EPISODE_SPEND.jsonl"

let str = Js.Json.string
let num = Js.Json.number

/* Called at the moment of spend. `credits` is what the provider quoted for
   these exact parameters, so the ledger records intent as well as fact. */
let record = (~episode, ~shot, ~kind, ~model, ~credits: float, ~note="", ()) => {
  let line =
    Js.Json.stringify(
      Js.Json.object_(
        Js.Dict.fromArray([
          ("at", str(Js.Date.toISOString(mkDate(now())))),
          ("episode", str(episode)),
          ("shot", str(shot)),
          ("kind", str(kind)),
          ("model", str(model)),
          ("credits", num(credits)),
          ("note", str(note)),
        ]),
      ),
    ) ++ "\n"
  appendFileSync(ledger, line)
}

/* what a model costs us, so a driver never has to hard-code a price */
let priceOf = model =>
  switch model {
  | "nano_banana_pro" => 2.0
  | "seedance_2_0" => 22.5
  | "seedance_2_0_mini" => 12.5
  | "seedance_2_5" => 32.5
  | "hunyuan3d_v3_image_to_3d" => 11.0
  | "tripo_h3_1_image_to_3d" => 9.0
  | _ => 0.0
  }

let report = episode => {
  if !existsSync(ledger) {
    Js.log("no ledger yet at " ++ ledger)
  } else {
    let rows =
      Js.Array2.filter(Js.String2.split(readFileSync(ledger, "utf8"), "\n"), l => Js.String2.trim(l) != "")
      ->Js.Array2.map(l =>
        switch Js.Json.decodeObject(Js.Json.parseExn(l)) {
        | Some(o) => o
        | None => Js.Dict.empty()
        }
      )
    let field = (o, k) =>
      switch Js.Dict.get(o, k)->Belt.Option.flatMap(Js.Json.decodeString) {
      | Some(v) => v
      | None => ""
      }
    let credits = o =>
      switch Js.Dict.get(o, "credits")->Belt.Option.flatMap(Js.Json.decodeNumber) {
      | Some(v) => v
      | None => 0.0
      }
    let mine = Js.Array2.filter(rows, o => episode == "" || field(o, "episode") == episode)
    let total = Js.Array2.reduce(mine, (a, o) => a +. credits(o), 0.0)
    let byModel = Js.Dict.empty()
    let byShot = Js.Dict.empty()
    Js.Array2.forEach(mine, o => {
      let m = field(o, "model")
      let sh = field(o, "shot")
      Js.Dict.set(byModel, m, Belt.Option.getWithDefault(Js.Dict.get(byModel, m), 0.0) +. credits(o))
      Js.Dict.set(byShot, sh, Belt.Option.getWithDefault(Js.Dict.get(byShot, sh), 0.0) +. credits(o))
    })
    Js.log(
      "spend for " ++
      (episode == "" ? "all episodes" : episode) ++
      ": " ++
      Js.Float.toString(total) ++
      " credits across " ++
      Belt.Int.toString(Js.Array2.length(mine)) ++ " generations\n",
    )
    Js.log("by model:")
    Js.Array2.forEach(Js.Dict.entries(byModel), ((m, c)) =>
      Js.log("  " ++ m ++ " — " ++ Js.Float.toString(c))
    )
    let shots = Js.Dict.entries(byShot)
    let sorted = Js.Array2.sortInPlaceWith(Js.Array2.copy(shots), ((_, a), (_, b)) => b > a ? 1 : -1)
    Js.log("\nmost expensive shots:")
    Js.Array2.forEach(Js.Array2.slice(sorted, ~start=0, ~end_=10), ((sh, c)) =>
      Js.log("  " ++ sh ++ " — " ++ Js.Float.toString(c))
    )
  }
}

if Js.Array2.length(argv) > 2 && argv[2] == "report" {
  report(Js.Array2.length(argv) > 3 ? argv[3] : "EP10")
}
