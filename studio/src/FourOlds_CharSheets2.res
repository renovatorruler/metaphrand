/* THE FOUR OLDS trailer — character sheets, set two: MARWANI, HALE, VESS,
   BRANDT. Same three-view reference-board format as set one. All designs are
   original fictional characters; all patches/marks generic; strict no-text.
   Run: node src/FourOlds_CharSheets2.res.mjs */

@module("fs") external existsSync: string => bool = "existsSync"
@module("fs") external mkdirSync: (string, 'a) => unit = "mkdirSync"

let dir = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/trailer/sheets/"

let sheetOf = (desc: string): string =>
  "Character reference sheet, one single image containing THREE views of the SAME person arranged side by side on a plain light-gray studio background, even soft lighting: (1) full-body front view standing relaxed, (2) full-body left profile view, (3) close-up head-and-shoulders detail. IDENTICAL face, identical clothing, identical hair in all three views — the same human being photographed three ways. Photorealistic, true skin and fabric texture, not CG, not illustration, not cartoon. STRICT: no text, no labels, no lettering, no logos, no watermarks anywhere. The person: " ++ desc

let sheets = [
  (
    "marwani",
    sheetOf(
      "an American president in his early 40s, of South Asian descent, trim athletic build, short black hair neatly parted, clean-shaven, a warm confident smile that never fully leaves his face even at rest, immaculate slim-cut navy suit, crisp white shirt, plain dark tie, small plain flag-less lapel pin removed — bare lapel, polished black shoes, the easy upright posture of a man who has never been interrupted.",
    ),
  ),
  (
    "hale",
    sheetOf(
      "a rocket-company founder in his mid 50s, broad-shouldered and heavyset like a former wrestler, a full round face, thick bull neck, very short cropped steel-gray hair, clean-shaven, pale gray-blue eyes under heavy brows, an expensive charcoal blazer worn open over a plain black crew-neck t-shirt, dark jeans, plain leather boots, a heavy watch, planted stance — a man built like a foreman who happens to own the fleet.",
    ),
  ),
  (
    "vess",
    sheetOf(
      "a chief operating officer in her mid 40s, composed and exact, dark hair in a sharp shoulder-length cut, minimal makeup, level unreadable gaze, a perfectly tailored dark charcoal pantsuit over a plain silk blouse, no jewelry but a thin watch, low practical heels, standing absolutely square with hands loosely folded — the stillness of a person who never wastes a motion.",
    ),
  ),
  (
    "brandt",
    sheetOf(
      "a European mission commander in his early 50s, compact and fit, close-cropped gray hair, weathered pilot's squint lines, calm level jaw, wearing a white spacewalk EVA suit with the helmet OFF and held under one arm, generic unmarked mission patches — plain colored geometric shapes with no letters, off-white suit fabric with realistic seams and joints, in the close-up view his bare head above the suit's neck ring.",
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
  Js.log("SET TWO DONE")
}
main()->ignore
