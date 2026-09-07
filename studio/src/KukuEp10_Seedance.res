// KukuEp10_Seedance.res — the author's request: the dialogue shots generated as
// video by Seedance 2.5 with every reference attached, for dubbing our own audio.
//
// The vendor is Higgsfield, not Krea: the Krea token on this machine is rejected
// (401) and Krea's billing already failed once on this account with 402 despite
// funds. Both platforms resell the SAME model with the same stated ceilings —
// at most 50 reference media, at most 30 images counting the start frame — so
// nothing about the picture changes with the vendor.
//
//   node src/KukuEp10_Seedance.res.mjs plan s06     # the prompt and the law, free
//   node src/KukuEp10_Seedance.res.mjs cost s06     # Higgsfield's own price, free
//   node src/KukuEp10_Seedance.res.mjs go s06 5     # generate, receipted and booked

@module("process") external cwd: unit => string = "cwd"
@module("process") external argv: array<string> = "argv"
@module("child_process") external execFileSync: (string, array<string>, {"encoding": string}) => string = "execFileSync"

module P = Kuku_PromptSpec

let root = cwd() ++ "/../stories/kuku/ep10/"
let () = PromptGate.setStrict(true)
let () = P.useStyleKey(root ++ "style/ep10_style_key.png")
let plate = root ++ "sets/courtyard_plate.png"
let clipsDir = root ++ "clips/"

/* THE DIALOGUE SHOT. Motion only: the start frame is an approved, receipted
   still, so the picture is already decided and the model is asked for movement
   and mouths — never for the world. Every actor is named in every sentence,
   which is the prompt law this project pays for. */
let s06: P.videoSpec = {
  scene: "दादी speaks warmly at the lamp niche while कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर sit and listen, and कालू sleeps on the flagstones.",
  cameraTravels: false,
  cast: [
    P.Dadi({doing: "दादी stands at the niche and speaks, दादी's mouth opening and closing on the words, दादी's head turning gently toward कुकु"}),
    P.Dragon({name: P.Kuku, form: P.Small, doing: "कुकु sits and looks up at दादी with a closed mouth, कुकु's head lifting a little as कुकु listens"}),
    P.Dragon({name: P.Fyuria, form: P.Small, doing: "फ्यूरिया sits beside कुकु with a closed mouth and watches दादी, फ्यूरिया's wings settling once"}),
    P.Dragon({name: P.Leda, form: P.Small, doing: "लेडा sits with a closed mouth and watches दादी, लेडा's head tilting slightly"}),
    P.Dragon({name: P.Castor, form: P.Small, doing: "कैस्टर sits with a closed mouth and watches दादी, कैस्टर's tail giving one slow sweep"}),
    P.Dragon({name: P.Vesper, form: P.Small, doing: "वैस्पर sits near the door with a closed mouth and watches दादी, वैस्पर's eyelids heavy"}),
    P.Kalu({doing: "कालू lies curled on the flagstones asleep, कालू's flank rising and falling with slow breathing"}),
  ],
  blocking: [
    "दादी stands at the wall niche in the middle of the courtyard, upright, facing कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर.",
    "कुकु sits on the flagstones to the right of the niche, close to दादी.",
    "फ्यूरिया sits to the right of कुकु.",
    "लेडा sits to the right of फ्यूरिया.",
    "कैस्टर sits at the right edge of the courtyard.",
    "वैस्पर sits at the left, beside the wooden door.",
    "कालू lies asleep on the flagstones in front of लेडा.",
    "The small clay lamp burns in the niche behind दादी.",
  ],
  beats: [
    "Through the whole take दादी speaks steadily, दादी's mouth moving on every word.",
    "कुकु watches दादी throughout and lifts कुकु's head once, slowly.",
    "फ्यूरिया, लेडा, कैस्टर and वैस्पर each keep watching दादी, each with small idle motion.",
    "The lamp flame wavers softly and stays alight for the whole take.",
    "कालू keeps sleeping through the whole take.",
  ],
  camera: "The camera holds exactly where the start image stands, locked off for the whole take, with a very slight settle.",
  physics: [
    "Each character moves as one continuous body, with the weight of thick cut paper.",
    "दादी's mouth is the only mouth that opens.",
  ],
  lighting: "Evening gold from the left across the courtyard, and the warm small glow of the burning lamp in the niche.",
  audio: "दादी speaks steadily in a warm elderly voice; a light evening wind moves across the courtyard.",
  extraRules: [
    "THE START IMAGE IS THE WORLD: the same courtyard, the same wall, the same niche, the same seven characters in the same places, the same evening light.",
    "दादी KEEPS SPEAKING FOR THE WHOLE TAKE, दादी's mouth opening and closing on the words.",
    "कुकु, फ्यूरिया, लेडा, कैस्टर and वैस्पर each keep a closed mouth for the whole take.",
    "EVERY SURFACE STAYS CUT PAPER, with soft rounded cut edges and visible paper grain.",
  ],
}

/* THE VIDEO-TO-VIDEO SHOT — what the author actually asked for. Seedance 2.5's
   'video_edit' mode takes exactly one video reference: our own puppet cut goes
   in, carrying the staging, the timing and the mouth movement we already own,
   and the model restyles the motion instead of inventing the performance. The
   prompt therefore describes what the input video already does, so the model
   has nothing to reconcile. */
let s06v: P.videoSpec = {
  ...s06,
  scene: "दादी speaks warmly at the lamp niche while कुकु stands and listens and फ्यूरिया watches, exactly as the reference video already shows.",
  cast: [
    P.Dadi({doing: "दादी stands at the niche and speaks, दादी's mouth opening and closing on the words"}),
    P.Dragon({name: P.Kuku, form: P.Small, doing: "कुकु stands and looks up at दादी with a closed mouth"}),
    P.Dragon({name: P.Fyuria, form: P.Small, doing: "फ्यूरिया stands at the left with a closed mouth and watches दादी"}),
  ],
  blocking: [
    "दादी stands at the wall niche on the right, upright, facing कुकु.",
    "कुकु stands on the flagstones in the middle of the courtyard, facing दादी.",
    "फ्यूरिया stands on the flagstones at the left, facing दादी.",
    "The small clay lamp burns in the niche behind दादी.",
  ],
  beats: [
    "Every position and every movement follows the reference video frame for frame.",
    "दादी's mouth moves on the words exactly when the reference video moves it.",
    "कुकु and फ्यूरिया keep watching दादी exactly as the reference video shows.",
  ],
  camera: "The camera follows the reference video exactly.",
  extraRules: [
    "THE REFERENCE VIDEO IS THE PERFORMANCE: every position, every movement and every moment of speech follows the reference video frame for frame.",
    "THE ATTACHED SHEETS ARE THE CHARACTERS: दादी keeps the build, the colour and the markings of दादी's attached sheet; कुकु keeps the build, the colour and the markings of कुकु's attached sheet; फ्यूरिया keeps the build, the colour and the markings of फ्यूरिया's attached sheet.",
    "EVERY SURFACE STAYS CUT PAPER, with soft rounded cut edges, real thickness and visible paper grain, in warm evening light.",
  ],
}

let shots = [("s06", s06, "s06_dadi_explains.png"), ("s06v", s06v, "s06_dadi_explains.png")]

/* the puppet cut that goes in as the one video reference */
let sourceVideo = root ++ "cutout/out/proof_lines_008_010.mp4"

let find = key =>
  switch Js.Array2.find(shots, ((k, _, _)) => k == key) {
  | Some(t) => Some(t)
  | None => None
  }

/* PLAN: the exact prompt and every finding of the law. Free. */
let plan = key =>
  switch find(key) {
  | Some((k, spec, _)) => {
      PromptGate.setStrict(false)
      let txt = P.videoPrompt(spec)
      let found = Js.Array2.concat(PromptGate.scan(txt), PromptGate.scanStrict(txt))
      PromptGate.setStrict(true)
      Js.log("== " ++ k ++ " ==\n" ++ txt)
      Js.log(
        Js.Array2.length(found) == 0
          ? "\nGATE CLEAN"
          : "\n" ++ Js.Array2.joinWith(found, "\n") ++ "\n" ++ Belt.Int.toString(Js.Array2.length(found)) ++ " findings",
      )
    }
  | None => Js.log("no shot " ++ key)
  }

/* the references this shot attaches: the style key, the set plate, and one
   locked sheet per character in frame — the same list the receipt will carry */
let refsOf = spec =>
  Js.Array2.concat(
    [P.styleKey(), plate],
    Js.Array2.reduce(spec.P.cast, (acc, s) =>
      switch P.boardOf(s) {
      | Some(b) => Js.Array2.includes(acc, b) ? acc : Js.Array2.concat(acc, [b])
      | None => acc
      }
    , []),
  )

/* COST: Higgsfield prices the exact job before it exists. Free, and there is
   no reason to submit an unpriced job. A key ending in v is video-to-video:
   one video reference, no start frame, mode video_edit. */
let isV2v = key => Js.String2.endsWith(key, "v")
let cost = (key, secs) =>
  switch find(key) {
  | Some((_, spec, still)) => {
      let refs = refsOf(spec)
      let media = isV2v(key)
        ? Js.Array2.concat(
            ["--video-references", sourceVideo],
            Js.Array2.reduce(refs, (acc, r) => Js.Array2.concat(acc, ["--image-references", r]), []),
          )
        : Js.Array2.concat(
            ["--start-image", root ++ "stills/" ++ still],
            Js.Array2.reduce(refs, (acc, r) => Js.Array2.concat(acc, ["--image-references", r]), []),
          )
      let args = Js.Array2.concatMany(
        ["generate", "cost", "seedance_2_5", "--prompt", P.videoPrompt(spec), "--mode", isV2v(key) ? "video_edit" : "omni_reference"],
        [
          ["--duration", secs, "--resolution", "720p", "--aspect_ratio", "16:9", "--generate_audio", "true"],
          media,
          ["--json"],
        ],
      )
      Js.log(
        (isV2v(key) ? "video-to-video: 1 video reference + " : "image-to-video: 1 start frame + ") ++
        Belt.Int.toString(Js.Array2.length(refs)) ++ " image references",
      )
      Js.log(execFileSync("higgsfield", args, {"encoding": "utf8"}))
    }
  | None => Js.log("no shot " ++ key)
  }

/* GO: through the engine, so the prompt is gated, the spend is guarded and
   booked, and the receipt records every reference that reached the provider. */
let go = (key, secs) =>
  switch find(key) {
  | Some((k, spec, still)) =>
    ignore(
      Kuku_Engine.clip(
        ~episode="EP10",
        ~id=k ++ "_seedance_dialogue",
        ~spec,
        ~model="seedance_2_5",
        ~secs,
        ~start=Kuku_Engine.StartFrame(root ++ "stills/" ++ still),
        ~setRefs=[plate],
        ~videoRefs=isV2v(k) ? [sourceVideo] : [],
        ~generateAudio=true,
        ~dst=clipsDir ++ "EP10_" ++ k ++ "_seedance.mp4",
        (),
      ),
    )
  | None => Js.log("no shot " ++ key)
  }

let () =
  switch (Belt.Array.get(argv, 2), Belt.Array.get(argv, 3), Belt.Array.get(argv, 4)) {
  | (Some("plan"), Some(k), _) => plan(k)
  | (Some("cost"), Some(k), Some(s)) => cost(k, s)
  | (Some("cost"), Some(k), None) => cost(k, "5")
  | (Some("go"), Some(k), Some(s)) =>
    switch Belt.Int.fromString(s) {
    | Some(n) => go(k, n)
    | None => Js.log("duration must be a whole number of seconds")
    }
  | _ => Js.log("usage: plan <shot> | cost <shot> [secs] | go <shot> <secs>")
  }
