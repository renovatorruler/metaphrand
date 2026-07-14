/* THE FOUR OLDS trailer — character sheets. One canonical portrait per
   principal, generated once and then used as the REFERENCE image for every
   composed frame (the consistency lock). House look: Kodak Portra 400 film
   still, prosperous plains, real faces — never glossy, never CG. Text ban:
   no words, no logos, no lettering anywhere in frame.
   Run: node src/FourOlds_CharSheets.res.mjs */

@module("fs") external existsSync: string => bool = "existsSync"
@module("fs") external mkdirSync: (string, 'a) => unit = "mkdirSync"

let dir = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/trailer/sheets/"

/* a character SHEET is a reference board: the same man in three views on one
   canvas — full-body front, full-body profile, close-up head — identical
   wardrobe in every view, so downstream shots can lock the identity. */
let sheetOf = (desc: string): string =>
  "Character reference sheet, one single image containing THREE views of the SAME man arranged side by side on a plain light-gray studio background, even soft lighting: (1) full-body front view standing relaxed, (2) full-body left profile view, (3) close-up head-and-shoulders detail. IDENTICAL face, identical clothing, identical hair in all three views — the same human being photographed three ways. Photorealistic, true skin and fabric texture, not CG, not illustration, not cartoon. STRICT: no text, no labels, no lettering, no logos, no watermarks anywhere. The man: " ++ desc

let sheets = [
  (
    "cricket",
    sheetOf(
      "79 years old, Nebraska farmer, tall and lean and a little stooped, weathered sun-creased face, silver stubble, calm level gray eyes that give nothing away, short white hair pressed flat by a cap, wearing a clean tan canvas work jacket over a faded plaid shirt, worn blue jeans, leather work boots, a seed cap held in one hand.",
    ),
  ),
  (
    "dutch",
    sheetOf(
      "76 years old, retired aerospace engineer, slight precise build, thin silver hair combed exactly, wire-rimmed glasses, clean-shaven, pressed gray work shirt buttoned at the cuffs with two pens and a mechanical pencil in the breast pocket, gray slacks, polished plain shoes, stands very straight.",
    ),
  ),
  (
    "stitch",
    sheetOf(
      "74 years old, Texan aircraft restorer, sturdy build, easy warm grin, bright eyes, silver hair pushed back, denim shirt with sleeves rolled to the elbow, a gray shop rag over the left shoulder, canvas work pants, scuffed brown boots, stands loose with weight on one hip.",
    ),
  ),
  (
    "gunny",
    sheetOf(
      "71 years old, retired Navy submariner, broad and squared, iron posture, short white hair, heavy weathered jaw, plain navy-blue ballcap with no lettering, khaki work shirt buttoned to the collar, dark work trousers, black boots, hands at his sides like a man at parade rest.",
    ),
  ),
]

let main = async () => {
  mkdirSync(dir, {"recursive": true})
  let n = Belt.Array.length(sheets)
  let rec go = async i =>
    if i < n {
      let (name, prompt) = Belt.Array.getExn(sheets, i)
      let out = dir ++ name ++ ".png"
      if existsSync(out) {
        Js.log("SKIP " ++ name)
      } else {
        try {
          let b = await Cinema_Backends.image(~prompt=Cinema_Backends.Prompt(prompt), ~refs=[], ~pro=true)
          let _ = Cinema_Backends.writeBytes(Cinema_Backends.Path(out), b)
          Js.log("OK   " ++ name)
        } catch {
        | Cinema_Backends.BackendError(m) => Js.log("FAIL " ++ name ++ " — " ++ m)
        | _ => Js.log("FAIL " ++ name)
        }
      }
      await go(i + 1)
    }
  await go(0)
  Js.log("SHEETS DONE -> " ++ dir)
}
main()->ignore
