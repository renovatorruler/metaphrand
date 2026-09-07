// KukuEp10_Sfx.res — the sound pass for «द से दीया».
//
// A rendered scene carries its dialogue; this lays the world's sounds under
// and around it from the libraries earlier episodes already paid for (EP6,
// EP7): crickets and wind as beds, steps, the door, leaves, the chime, the
// forge whoosh. Nothing here is generated. The result is <scene>_sfx.mp4
// beside the scene, video copied, and the episode runner prefers it.
//
//   node src/KukuEp10_Sfx.res.mjs scene <name>    # one scene
//   node src/KukuEp10_Sfx.res.mjs all             # every scene that has a design

@module("fs") external existsSync: string => bool = "existsSync"
@module("process") external cwd: unit => string = "cwd"
@module("process") external argv: array<string> = "argv"

let root = cwd() ++ "/../stories/kuku/ep10/"
let scenes = root ++ "scenes/"
let lib6 = cwd() ++ "/../stories/kuku/ep6prod/sfx/"
let lib7 = cwd() ++ "/../stories/kuku/ep7prod/sfx/"

/* the library, by what a scene asks for */
let file = name =>
  switch name {
  | "crickets" => lib6 ++ "evening_crickets.mp3"
  | "wind" => lib7 ++ "wind_only_silence.mp3"
  | "reeds" => lib6 ++ "reeds_wind.mp3"
  | "leaves" => lib6 ++ "leaves_rustle.mp3"
  | "dadi_steps" => lib6 ++ "dadi_stick_steps.mp3"
  | "papa_steps" => lib6 ++ "papa_heavy_steps.mp3"
  | "run_arrive" => lib6 ++ "running_steps_arrive.mp3"
  | "kids_steps" => lib6 ++ "kids_playing_steps.mp3"
  | "leda_steps" => lib6 ++ "leda_small_steps.mp3"
  | "door_creak" => lib6 ++ "door_creak_small.mp3"
  | "door_close" => lib6 ++ "door_close_soft.mp3"
  | "chime" => lib6 ++ "chime_act.mp3"
  | "whoosh" => lib6 ++ "forge_whoosh_land.mp3"
  | "tak" => lib7 ++ "soft_tak.mp3"
  | "laugh" => lib6 ++ "group_laugh.mp3"
  | "bark" => lib7 ++ "kalu_bark.mp3"
  | other => Js.Exn.raiseError("no sound named " ++ other)
  }

/* a bed loops under the whole scene at a low level; an event plays once at
   its moment; `cut` trims an event to a length */
type sound = Bed({name: string, gain: float}) | Event({name: string, at: float, gain: float, cut: option<float>})

/* THE DESIGN, scene by scene. Times are the scenes' own: read them off the
   scene modules, never guessed. Levels: beds 0.18–0.3, events 0.5–0.9. */
let design = name =>
  switch name {
  | "s01_lamp" => [
      Bed({name: "crickets", gain: 0.22}),
      Event({name: "dadi_steps", at: 0.8, gain: 0.6, cut: Some(4.8)}),
      Event({name: "tak", at: 6.6, gain: 0.5, cut: None}),
    ]
  | "s02_lamp_talk" => [
      Bed({name: "crickets", gain: 0.2}),
      Event({name: "run_arrive", at: 0.3, gain: 0.7, cut: Some(4.2)}),
      Event({name: "kids_steps", at: 1.2, gain: 0.5, cut: Some(3.0)}),
    ]
  | "s03_first_gust" => [
      Bed({name: "crickets", gain: 0.18}),
      Event({name: "reeds", at: 0.6, gain: 0.8, cut: Some(3.6)}),
      Event({name: "leaves", at: 0.9, gain: 0.7, cut: Some(2.8)}),
    ]
  | "s04_dadi_goes_in" => [
      Bed({name: "crickets", gain: 0.2}),
      Event({name: "dadi_steps", at: 5.6, gain: 0.55, cut: Some(4.0)}),
      Event({name: "dadi_steps", at: 18.6, gain: 0.5, cut: Some(2.4)}),
      Event({name: "door_creak", at: 18.9, gain: 0.5, cut: None}),
      Event({name: "door_close", at: 21.1, gain: 0.7, cut: None}),
    ]
  | _ => []
  }

let apply = name => {
  let src = scenes ++ name ++ ".mp4"
  let sounds = design(name)
  if !existsSync(src) {
    Js.log("no render yet for " ++ name)
  } else if Js.Array2.length(sounds) == 0 {
    Js.log("no sound design for " ++ name)
  } else {
    let dur = Cinema_Backends.probeDuration(Cinema_Backends.Path(src))
    let Cinema_Backends.Seconds(secs) = dur
    /* inputs: 0 is the scene; beds loop for the scene's length; events are trimmed */
    let inputs = Js.Array2.reduce(sounds, (acc, s) =>
      switch s {
      | Bed({name}) => Js.Array2.concat(acc, ["-stream_loop", "-1", "-t", Js.Float.toString(secs), "-i", file(name)])
      | Event({name, cut}) =>
        Js.Array2.concat(acc, switch cut {
        | Some(c) => ["-t", Js.Float.toString(c), "-i", file(name)]
        | None => ["-i", file(name)]
        })
      }
    , [])
    let chains = Js.Array2.mapi(sounds, (s, i) => {
      let idx = Belt.Int.toString(i + 1)
      switch s {
      | Bed({gain}) => "[" ++ idx ++ ":a]volume=" ++ Js.Float.toString(gain) ++ ",afade=t=in:d=1.5,afade=t=out:st=" ++ Js.Float.toString(secs -. 1.5) ++ ":d=1.5[s" ++ idx ++ "]"
      | Event({at, gain}) => {
          let ms = Belt.Int.toString(Belt.Float.toInt(at *. 1000.0))
          "[" ++ idx ++ ":a]volume=" ++ Js.Float.toString(gain) ++ ",adelay=" ++ ms ++ "|" ++ ms ++ "[s" ++ idx ++ "]"
        }
      }
    })
    let labels = Js.Array2.joinWith(Js.Array2.mapi(sounds, (_, i) => "[s" ++ Belt.Int.toString(i + 1) ++ "]"), "")
    let graph = Js.Array2.joinWith(Js.Array2.concat(chains, ["[0:a]" ++ labels ++ "amix=inputs=" ++ Belt.Int.toString(Js.Array2.length(sounds) + 1) ++ ":normalize=0:duration=first[out]"]), ";")
    let out = scenes ++ name ++ "_sfx.mp4"
    Cinema_Backends.ffmpeg(
      Js.Array2.concatMany(
        ["-y", "-v", "error", "-i", src],
        [inputs, ["-filter_complex", graph, "-map", "0:v", "-map", "[out]", "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-t", Js.Float.toString(secs), out]],
      ),
    )
    Js.log("sound on " ++ name ++ " → " ++ out ++ " (" ++ Belt.Int.toString(Js.Array2.length(sounds)) ++ " sounds)")
  }
}

let () =
  switch (Belt.Array.get(argv, 2), Belt.Array.get(argv, 3)) {
  | (Some("scene"), Some(n)) => apply(n)
  | (Some("all"), _) =>
    Js.Array2.forEach(["s01_lamp", "s02_lamp_talk", "s03_first_gust", "s04_dadi_goes_in"], apply)
  | _ => Js.log("usage: scene <name> | all")
  }
