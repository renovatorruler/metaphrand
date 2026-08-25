/* KukuEp10_ChaseClip.res — one Seedance 2.5 test: does MOTION carry the chase
   where a slideshow of stills cannot?

   The prompt is rendered by Kuku_PromptSpec.videoPrompt from a typed spec, like
   every other prompt in this pipeline, and the clip is anchored to an approved
   frame so the set cannot be reinvented. The lane's own metric data supplies the
   distances, so the move is BOUNDED — the lesson from the first survey, where an
   unbounded dolly toward a dead-end wall made the wall breathe.

   Run from studio/:
     node src/KukuEp10_ChaseClip.res.mjs            # print the prompt + price it
     node src/KukuEp10_ChaseClip.res.mjs --go       # spend and download */

module P = Kuku_PromptSpec
module S = Kuku_Ep10Sets

@module("fs") external existsSync: string => bool = "existsSync"
type execOpts = {"encoding": string, "timeout": int}
@module("child_process")
external execFileSync: (string, array<string>, execOpts) => string = "execFileSync"
@scope("process") @val external argv: array<string> = "argv"

let opts = {"encoding": "utf8", "timeout": 1800000}
let ep10 = P.kukuRoot ++ "ep10prod/"
let startFrame = ep10 ++ "stills/h15_cart_runs.png"
let dst = ep10 ++ "clips/CHASE_TEST_seedance25.mp4"
let seconds = 10

/* the cart travels from marker 1 to marker 3 — 24 metres of the 60 metre lane —
   so the move is bounded and the wall stays far away */
let spec: P.videoSpec = {
  scene: "The runaway hay cart races down the gurukul's straight flight-lane at golden dusk with गौरी the paper cow braced inside it, while फ्यूरिया the towering orange-red paper dragon flies alongside trying to slow it. " ++ S.setProse(S.Lane),
  blocking: [
    "the start image IS this lane and this cart — the same flagstones, the same low kerbs, the same rubble wall along the right, the same stone post behind, the same horizon",
    "the cart runs along the CENTRELINE of the lane and never crosses onto either kerb",
    "गौरी stays aboard the cart for every frame, braced in the hay, never falling out and never absent",
    "the three red paper markers are set into the centreline at 12, 24 and 36 metres; the cart begins just past the FIRST marker",
    "the closed stone end wall stays far away in the distance for the whole clip and never comes near",
  ],
  beats: [
    "0.0-2.0s: the cart is running, wheels turning fast, loose hay lifting; the camera tracks alongside at cart height",
    "2.0-5.0s: it passes the SECOND red marker, which slides past the wheels and away behind",
    "5.0-8.0s: फ्यूरिया sweeps in from behind and flies backwards ahead of the cart, wings beating against it, paper dust rolling up",
    "8.0-10.0s: the cart is still running but visibly slower as it nears the THIRD marker; it has covered about twenty-four metres in total and no more",
  ],
  camera: "one continuous tracking shot travelling alongside the cart at its own speed, held at cart height — no orbit, no cut, no zoom, and the camera never overtakes the cart or turns to face back up the lane",
  physics: [
    "the cart travels about twenty-four metres in total — roughly from the first marker to the third — and no further; it must never reach the end wall",
    "the lane is RIGID: kerbs, markers, post and wall keep their positions; the lane never lengthens, the wall never recedes, and no marker ever reappears once passed",
    "wheels turn at a speed that matches the ground moving past them",
  ],
  lighting: "constant warm golden dusk exactly as in the start image, low sun, long soft shadows — no time change, no flicker",
  audio: "no dialogue, no music, no narration",
  extraRules: [
    "गौरी is present in the cart in EVERY frame — a cart running empty is wrong",
    "exactly ONE dragon in the clip, and she is orange-red — no other dragon enters frame",
  ],
}

let prompt = P.videoPrompt(spec)
let args = [
  "generate", "create", "seedance_2_5",
  "--prompt", prompt,
  "--mode", "omni_reference",
  "--start-image", startFrame,
  "--image", ep10 ++ "elements/future_fyuria_board_bracelet.png",
  "--duration", Belt.Int.toString(seconds),
  "--resolution", "1080p",
  "--aspect_ratio", "16:9",
  "--wait", "--json",
]

if Js.Array2.some(argv, a => a == "--go") {
  let raw = execFileSync("higgsfield", args, opts)
  switch Js.String2.match_(raw, Js.Re.fromString("https://[^\"\\s]*\\.(mp4|webm|mov)")) {
  | Some(m) =>
    switch m[0] {
    | Some(url) => {
        let _ = execFileSync("curl", ["-sL", "--retry", "3", "--create-dirs", "-o", dst, url], opts)
        Js.log("saved " ++ dst)
      }
    | None => Js.log("no url")
    }
  | None => Js.log("FAIL — " ++ Js.String2.slice(raw, ~from=0, ~to_=300))
  }
} else {
  Js.log(prompt)
  Js.log("\nstart frame: " ++ startFrame ++ " (exists: " ++ (existsSync(startFrame) ? "yes" : "NO") ++ ")")
  let costArgs = Js.Array2.copy(args)
  costArgs[0] = "generate"
  costArgs[1] = "cost"
  let _ = Js.Array2.removeCountInPlace(costArgs, ~pos=Js.Array2.length(costArgs) - 2, ~count=2)
  Js.log("price check: " ++ execFileSync("higgsfield", costArgs, opts))
}
