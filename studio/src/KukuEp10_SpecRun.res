/* KukuEp10_SpecRun.res — EP10 review-notes round 1, run through the JSON prompt law.

     S011 — cue-specific variant of h22_castor_calm with the cart and cow removed
            (the original stays untouched for its scene-2 use).
     S014 — Seedance 2.0 Mini clip: Fyuria launches off her mark, loops the ring,
            lands back on the same mark. Anchored to the approved still.

   Run from studio/ after `npm run build`:
     node src/KukuEp10_SpecRun.res.mjs            # dry — print prompts + refs, spend nothing
     node src/KukuEp10_SpecRun.res.mjs go-s011    # nano_banana_pro edit
     node src/KukuEp10_SpecRun.res.mjs go-s014    # seedance_2_0_mini clip */

type execOpts = {"encoding": string, "timeout": int}
@module("child_process")
external execFileSync: (string, array<string>, execOpts) => string = "execFileSync"
@module("fs") external existsSync: string => bool = "existsSync"
@scope("process") @val external argv: array<string> = "argv"

let opts = {"encoding": "utf8", "timeout": 900000}
let ep10 = Kuku_PromptSpec.kukuRoot ++ "ep10prod/"

/* ---- S011: remove cart + cow from Castor's line frame ---------------------- */
let s011: Kuku_PromptSpec.editSpec = {
  change: "Remove the wooden hay cart and the brown-and-white cow entirely. Fill the space they occupied by continuing the existing papercraft valley naturally — the dirt path, grass tufts, bushes and river, matching the surrounding layers.",
  keep: ["the golden-yellow paper dragon exactly as he is — pose, face, wings, golden bracelet"],
  extraRules: [],
}
let s011Src = ep10 ++ "stills/h22_castor_calm.png"
let s011Dst = ep10 ++ "stills/s011_castor_calm_solo.png"

/* ---- S014: Fyuria's ring flight, Seedance 2.0 Mini ------------------------- */
let s014: Kuku_PromptSpec.videoSpec = {
  scene: "FYURIA, a towering orange-red paper dragon, flies her training drill: from her marked circular flagstone she launches, flies THREE full loops around the courtyard sky, and returns to land on the same mark, delighted.",
  cameraTravels: false,
  cast: [Kuku_PromptSpec.Dragon({name: Kuku_PromptSpec.Fyuria, form: Kuku_PromptSpec.Great, doing: "flying her ring drill"})],
  blocking: [
    "Fyuria starts standing upright on the circular flagstone mark at frame center, wings half-raised, chin lifted — exactly as in the start image",
    "the bronze paper bell hangs at the top right of frame and never moves from there",
    "the circular stone mark stays fixed at the bottom center of frame for the whole clip",
    "she is the only character in the shot",
  ],
  beats: [
    "0.0-1.5s: she bends her hind legs, crouches and launches upward off the mark with one strong wingbeat; paper dust curls from the flagstones",
    "1.5-4.0s: FIRST full loop — she banks left and flies one smooth wide circle around the courtyard sky, wings at full stretch",
    "4.0-6.0s: SECOND full loop, tighter and faster, passing near the hanging bell without touching it",
    "6.0-8.0s: THIRD full loop, confident and joyful, her tail tracing the curve",
    "8.0-10.0s: she glides back down and lands on the same circular mark, legs absorbing the weight, wings settling, chin lifted, pleased",
  ],
  camera: "locked static camera, no camera movement, no cuts; the circular mark remains visible at the bottom of frame throughout",
  physics: ["her take-off and landing both have real weight — bent legs, a beat to settle"],
  lighting: "constant warm golden dusk, identical to the start image, no flicker, no time change",
  audio: "no dialogue, no music",
  extraRules: [],
}
let s014Start = ep10 ++ "inbetweens/h03_furia_mark__b_look_up.png"
let s014Board = ep10 ++ "elements/future_fyuria_board_bracelet.png"
let s014Dst = ep10 ++ "clips/S014_furia_ring_flight.mp4"

/* ---- runner ---------------------------------------------------------------- */
let firstUrl = (raw, ext) =>
  switch Js.String2.match_(raw, Js.Re.fromString("https://[^\"\\s]*\\." ++ ext)) {
  | Some(m) => m[0]
  | None => None
  }

let download = (url, dst) => {
  let _ = execFileSync("curl", ["-sL", "--retry", "3", "--create-dirs", "-o", dst, url], opts)
  Js.log("saved " ++ dst)
}

/* RETIRED (2026-08-28): generation belongs to Kuku_Engine — this driver's jobs
   were delivered and its provider path is closed. The dry printer remains. */
let generate = (_args, _dst, _ext) =>
  Js.Exn.raiseError("retired driver: route generation through Kuku_Engine")
let _unused = (args, dst, ext) => {
  let raw = execFileSync("higgsfield", args, opts)
  switch firstUrl(raw, ext) {
  | Some(url) => download(url, dst)
  | None => Js.log("NO RESULT URL — raw output:\n" ++ Js.String2.slice(raw, ~from=0, ~to_=400))
  }
}

let mode = Js.Array2.length(argv) > 2 ? argv[2] : "dry"

let editArgs = [
  "generate",
  "create",
  "nano_banana_pro",
  "--prompt",
  Kuku_PromptSpec.editPrompt(s011),
  "--image",
  s011Src,
  "--aspect_ratio",
  "16:9",
  "--resolution",
  "2k",
  "--wait",
  "--json",
]

let videoArgs = [
  "generate",
  "create",
  "seedance_2_0_mini",
  "--prompt",
  Kuku_PromptSpec.videoPrompt(s014),
  "--start-image",
  s014Start,
  "--image",
  s014Board,
  "--duration",
  "10",
  "--wait",
  "--json",
]

switch mode {
| "go-s011" => generate(editArgs, s011Dst, "(png|webp|jpg)")
| "go-s014" => generate(videoArgs, s014Dst, "(mp4|webm|mov)")
| _ => {
    Js.log("=== S011 edit prompt (nano_banana_pro) ===")
    Js.log(Kuku_PromptSpec.editPrompt(s011))
    Js.log("refs: " ++ s011Src ++ " -> " ++ s011Dst)
    Js.log("src exists: " ++ (existsSync(s011Src) ? "yes" : "NO"))
    Js.log("")
    Js.log("=== S014 video prompt (seedance_2_0_mini) ===")
    Js.log(Kuku_PromptSpec.videoPrompt(s014))
    Js.log("start: " ++ s014Start ++ " (exists: " ++ (existsSync(s014Start) ? "yes" : "NO") ++ ")")
    Js.log("board: " ++ s014Board ++ " (exists: " ++ (existsSync(s014Board) ? "yes" : "NO") ++ ")")
    Js.log("dst:   " ++ s014Dst)
  }
}
