// KukuEp10_Episode.res — renders «द से दीया» from its scene modules.
//
//   node src/KukuEp10_Episode.res.mjs scene <name>   # one scene, with its sheet
//   node src/KukuEp10_Episode.res.mjs act <n>        # every scene of an act, joined
//   node src/KukuEp10_Episode.res.mjs episode        # every act, joined
//
// Every scene renders deterministically to stories/kuku/ep10/scenes/<name>.mp4
// with its dialogue mixed from the takes; acts and the episode are joins with
// no re-encode, so a scene fixed later drops straight into the cut.

@module("process") external argv: array<string> = "argv"

open Puppet
open KukuEp10_Rigs
open KukuEp10_Stage

/* acts 2a, 2b, 2c and 3 are separate modules so their authors never touch one
   another; the runner joins them in script order */
let acts: array<(int, array<(string, unit => promise<scene>)>)> = [
  (1, KukuEp10_Act1.scenes),
  (2, KukuEp10_Act2a.scenes),
  (3, KukuEp10_Act2b.scenes),
  (4, KukuEp10_Act2c.scenes),
  (5, KukuEp10_Act3.scenes),
]

let allScenes = Js.Array2.reduce(acts, (acc, (_, ss)) => Js.Array2.concat(acc, ss), [])

let renderOne = async (name, build) => {
  let sc = await build()
  let out = renderScene(sc)
  Js.log("scene " ++ name ++ " → " ++ out ++ " (" ++ Js.Float.toFixedWithPrecision(sc.duration, ~digits=1) ++ " s, " ++ Belt.Int.toString(Js.Array2.length(sc.cues)) ++ " lines)")
  out
}

let renderAct = async n =>
  switch Js.Array2.find(acts, ((k, _)) => k == n) {
  | None => Js.log("no act " ++ Belt.Int.toString(n))
  | Some((_, ss)) => {
      let files: array<string> = []
      for i in 0 to Js.Array2.length(ss) - 1 {
        let (name, build) = ss[i]
        let f = await renderOne(name, build)
        /* the sound pass writes <name>_sfx.mp4 beside the scene; the cut prefers it */
        let withSound = sceneDir ++ name ++ "_sfx.mp4"
        ignore(Js.Array2.push(files, existsSync(withSound) ? withSound : f))
      }
      let actDir = root ++ "acts/"
      mkdirSync(actDir, {"recursive": true})
      let out = actDir ++ "act" ++ Belt.Int.toString(n) ++ ".mp4"
      concat(files, out)
      Js.log("act " ++ Belt.Int.toString(n) ++ " → " ++ out)
    }
  }

let () =
  switch (Belt.Array.get(argv, 2), Belt.Array.get(argv, 3)) {
  | (Some("scene"), Some(name)) =>
    switch Js.Array2.find(allScenes, ((k, _)) => k == name) {
    | Some((k, build)) => ignore(renderOne(k, build))
    | None => Js.log("no scene " ++ name ++ "; known: " ++ Js.Array2.joinWith(Js.Array2.map(allScenes, ((k, _)) => k), " "))
    }
  | (Some("act"), Some(n)) =>
    switch Belt.Int.fromString(n) {
    | Some(k) => ignore(renderAct(k))
    | None => Js.log("act takes a number")
    }
  | (Some("episode"), _) => {
      let go = async () => {
        for i in 0 to Js.Array2.length(acts) - 1 {
          let (k, _) = acts[i]
          await renderAct(k)
        }
      }
      ignore(go())
    }
  | _ => Js.log("usage: scene <name> | act <n> | episode")
  }
