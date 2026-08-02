/* कुकु और अक्षर — character reference sheets.

   Every episode still is generated with the cast sheets attached as locked design
   references, so a character who has no sheet drifts from shot to shot. तानसेन the
   parrot joined the cast in Ep6 and has none — this makes his, in the same frame,
   pose and background as the existing seven so it sits in the same set.

   Run from studio/:  node src/Kuku_CharSheet.res.mjs [name ...]   (DRY=1 to check) */

open Cinema_Backends

@val @scope("process") external argv: array<string> = "argv"
@val @scope(("process", "env")) external envDry: option<string> = "DRY"

let dir = "/Users/dusty/Dev/metaphrand/stories/kuku/charsheets"
let styleKey = "0c47270d-70f7-4dd0-887f-c06c88ef5fd9"

let style = "STYLE REFERENCE: Match the attached reference image EXACTLY. 3D papercraft, layered cut-paper illustration, soft matte construction-paper textures, visible paper edges and folds, warm storybook palette, soft studio lighting, non-photorealistic, illustrated, not a photo, no live-action, no realism. CHARACTER REFERENCE SHEET: one single character, full body, standing in a friendly relaxed 3/4 pose, centered, on a plain soft cream paper background with a simple paper ground shadow, no scenery, no props except those named, no other characters."

let negative = "NEGATIVE: no text, no letters, no captions, no watermark, no logos, no extra characters, no background scenery, no photorealism, no human features except those named."

/* Sheets to make. The existing seven are already on disk and are skipped; this
   table exists so a future addition is one row, not a new script. */
let sheets = [
  (
    "tansen",
    "SUBJECT: Tansen, a bright green cut-paper parrot, medium sized, perched calmly; a curved RED beak, a pale ring around the neck, round bright knowing eyes, layered paper wing feathers in two greens, a long tapering tail of stacked paper strips, small grey claws gripping a short plain wooden perch. Cheerful and characterful, a little bit pleased with himself. He is a PARROT, not a dragon: no horns, no dragon snout, feathers not scales.",
  ),
  (
    "leda",
    "SUBJECT: Leda, the tiniest cut-paper toddler dragon of all, smaller than every other character; soft pink-lilac paper body, round baby proportions, huge curious eyes, the stubbiest little wings, sitting on her bottom, delighted open-mouthed baby smile.",
  ),
]

let main = async () => {
  let dry = envDry == Some("1")
  let wanted = Belt.Array.sliceToEnd(argv, 2)
  let todo = Belt.Array.length(wanted) == 0
    ? sheets
    : sheets->Belt.Array.keep(((n, _)) => Belt.Array.some(wanted, w => w == n))

  for i in 0 to Belt.Array.length(todo) - 1 {
    switch Belt.Array.get(todo, i) {
    | None => ()
    | Some((name, desc)) => {
        let out = Path(dir ++ "/" ++ name ++ ".png")
        if exists(out) && fileSizeMb(out) *. 1.0e6 > 20000.0 {
          Js.log("SKIP " ++ name ++ " (already drawn)")
        } else if dry {
          Js.log("would draw " ++ name)
        } else {
          /* the CLI is the only path to this model; it fails when run in bursts, so
             sheets are made one at a time */
          let r = run(
            ~cmd="higgsfield",
            ~args=[
              "generate", "create", "nano_banana_pro",
              "--prompt", style ++ " " ++ desc ++ " " ++ negative,
              "--image", styleKey,
              "--aspect_ratio", "3:4",
              "--resolution", "2k",
              "--wait", "--json",
            ],
          )
          if r.code != 0 {
            Js.log("FAIL " ++ name ++ ": higgsfield exit " ++ Belt.Int.toString(r.code))
          } else {
            /* the CLI returns either a bare object or a one-element array */
            let j = Js.Json.parseExn(r.stdout)
            let obj = switch Js.Json.decodeArray(j) {
            | Some(a) => Belt.Array.get(a, 0)->Belt.Option.getWithDefault(j)
            | None => j
            }
            switch obj
            ->Js.Json.decodeObject
            ->Belt.Option.flatMap(o => Js.Dict.get(o, "result_url"))
            ->Belt.Option.flatMap(Js.Json.decodeString) {
            | Some(url) if url != "" => {
                let d = run(~cmd="curl", ~args=["-s", "-o", dir ++ "/" ++ name ++ ".png", url])
                Js.log(d.code == 0 ? "OK " ++ name : "FAIL download " ++ name)
              }
            | _ => Js.log("FAIL " ++ name ++ ": no result_url in response")
            }
          }
        }
      }
    }
  }
  Js.log("sheets on disk: " ++ Belt.Int.toString(Belt.Array.length(readDir(Path(dir))->Belt.Array.keep(f => Js.String2.endsWith(f, ".png")))))
}

main()
->Js.Promise2.catch(e => {
  Js.log2("CHARSHEET FAILED:", e)
  Js.Promise.resolve()
})
->ignore
