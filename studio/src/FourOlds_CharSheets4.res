/* THE FOUR OLDS trailer — character sheets, final set: DOCKWORKER, STREAMER,
   WHITE HOUSE LAWYER + the MUSEUM SUIT wardrobe board. Off-model casting law;
   likeness vet before delivery. Run: node src/FourOlds_CharSheets4.res.mjs */

@module("fs") external existsSync: string => bool = "existsSync"
@module("fs") external mkdirSync: (string, 'a) => unit = "mkdirSync"

let dir = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/trailer/sheets/"

let sheetOf = (desc: string): string =>
  "Character reference sheet, one single image containing THREE views of the SAME person arranged side by side on a plain light-gray studio background, even soft lighting: (1) full-body front view standing relaxed, (2) full-body left profile view, (3) close-up head-and-shoulders detail. IDENTICAL face, identical clothing, identical hair in all three views — the same human being photographed three ways. Photorealistic, true skin and fabric texture, not CG, not illustration, not cartoon. STRICT: no text, no labels, no lettering, no logos, no watermarks anywhere. An original face resembling no real actor or public figure. The person: " ++ desc

let sheets = [
  (
    "dockworker",
    sheetOf(
      "an integration-floor dockworker in his mid 50s cast against type: medium height but yoked through the shoulders from thirty years of pallets, a settled unhurried bearing, gray-streaked black hair under a plain unlettered hard hat held in one hand, a graying push-broom mustache, deep smile lines around wary eyes, a plain high-visibility vest with no printing over a faded gray work shirt, a badge clip on a lanyard wound thick with twenty years of tape — the badge face turned away so nothing reads, canvas trousers, scuffed composite-toe boots.",
    ),
  ),
  (
    "streamer",
    sheetOf(
      "a conspiracy livestreamer in his late 30s cast against type: doughy and soft rather than wired-thin, pale ring-light complexion, a patchy chinstrap beard, thinning hair pulled into a small hopeful ponytail, red-rimmed eager eyes, an open zip hoodie over a faded black t-shirt with no printing, cargo shorts despite the season, white crew socks and slides, a gaming headset worn around the neck like a collar — fifteen years of being almost right radiating off him.",
    ),
  ),
  (
    "lawyer",
    sheetOf(
      "a White House counsel in her late 40s cast against type: short and round-shouldered with reading stoop, graying auburn hair pinned up hastily with a pencil through the bun, smart tortoiseshell glasses pushed up on her forehead, sleeves of a wrinkled white oxford shirt rolled past the elbow, a blank unlettered lanyard, charcoal skirt, flat practical shoes, a legal pad hugged to her chest — the one person in the building who has actually read the file, controlled alarm on her face.",
    ),
  ),
]

/* the wardrobe board: not a person — the restored Apollo-era museum suit the
   four olds wear; one canonical reference so all four suited shots match */
let suitPrompt = "Wardrobe reference sheet, one single image containing THREE views of the SAME vintage spacesuit displayed on an invisible mannequin against a plain light-gray studio background, even soft lighting: (1) full front view, (2) left profile view, (3) close-up of the chest and helmet-ring detail. A 1970s Apollo-era lunar EVA spacesuit, museum-restored by hand: aged off-white outer fabric gone slightly ivory with fifty years, visible careful hand-stitched repair seams in slightly newer white thread, gray-blue anodized wrist and neck ring fittings with fine scratches, red fabric pull-tabs, clear bubble helmet with faint gold visor tint carried beside the suit in the front view, worn gray lunar-overshoe boots, generic color-block fabric patches with NO letters or emblems — shapes only. Museum-authentic, lovingly repaired, not futuristic, not sci-fi, not modern. Photorealistic fabric weave and metal texture. STRICT: no text, no labels, no lettering, no logos, no watermarks anywhere."

let main = async () => {
  mkdirSync(dir, {"recursive": true})
  let items = Belt.Array.concat(sheets, [("museum_suit", suitPrompt)])
  let n = Belt.Array.length(items)
  let rec go = async i =>
    if i < n {
      let (name, prompt) = Belt.Array.getExn(items, i)
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
  Js.log("FINAL SET DONE")
}
main()->ignore
