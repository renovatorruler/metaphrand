/* THE FOUR OLDS trailer — character sheets, set three: WADE, MACK, TITO,
   BUCK. Off-model casting law: perturb each archetype off its average.
   Likeness vet required before delivery. Run: node src/FourOlds_CharSheets3.res.mjs */

@module("fs") external existsSync: string => bool = "existsSync"
@module("fs") external mkdirSync: (string, 'a) => unit = "mkdirSync"

let dir = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/trailer/sheets/"

let sheetOf = (desc: string): string =>
  "Character reference sheet, one single image containing THREE views of the SAME person arranged side by side on a plain light-gray studio background, even soft lighting: (1) full-body front view standing relaxed, (2) full-body left profile view, (3) close-up head-and-shoulders detail. IDENTICAL face, identical clothing, identical hair in all three views — the same human being photographed three ways. Photorealistic, true skin and fabric texture, not CG, not illustration, not cartoon. STRICT: no text, no labels, no lettering, no logos, no watermarks anywhere. An original face resembling no real actor or public figure. The person: " ++ desc

let sheets = [
  (
    "wade",
    sheetOf(
      "a county sheriff in his late 50s cast against type: very tall and narrow, built like a librarian, neat silver crew cut, small wire-rimmed glasses, a long mild face with deep gentle lines, clean-shaven, tan county sheriff uniform shirt with a plain star-shaped badge with no lettering, dark trousers, duty belt worn like it embarrasses him, plain boots — a peace officer whose whole authority is kindness.",
    ),
  ),
  (
    "mack",
    sheetOf(
      "a freight-and-salvage broker, 55, cast against type: short and wiry with a filing clerk's neatness, thinning dark hair combed flat, salt-and-pepper stubble goatee, reading glasses hanging on a cord against his chest, a knit vest over a pressed flannel shirt, canvas work pants with a folded manifest sticking from the thigh pocket, small quick hands — a man whose native country is paperwork.",
    ),
  ),
  (
    "tito",
    sheetOf(
      "a 24-year-old Mexican-American welder cast against type: slight and precise rather than burly, long black hair tied back low, a quiet studious face with careful dark eyes, faint burn freckles on the forearms, a gray welder's cap pushed back on his head, heavy leather welding jacket open over a plain white t-shirt, work jeans, steel-toe boots, thin careful hands — the best bead in the county from precision, not strength.",
    ),
  ),
  (
    "buck",
    sheetOf(
      "a diner regular in his late 70s cast against type: rail-thin and very tall, slightly stooped, a long weathered clean-shaven face with hooded deadpan eyes, large ears, sun spots, wispy white hair flat under a plain unlettered feed cap, buffalo-plaid flannel shirt buttoned at the wrists, thin frame swimming in worn carpenter jeans, orthopedic white sneakers — a man who has out-sat every opinion in the county.",
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
  Js.log("SET THREE DONE")
}
main()->ignore
