/* KUKU Ep1 — production line manifest. Reads every scene through Write.read (the
   verify-first production door — an unverified or hand-edited scene is refused)
   and prints one JSON object per line for the audio pipeline.

   Run from inside studio/ (no model calls, no budget needed):
     node src/Kuku_ManifestEp1.res.mjs > ../stories/kuku/ep1/manifest.jsonl
*/

@val @scope("process") external cwd: unit => string = "cwd"

let dir = cwd() ++ "/../stories/kuku/ep1"

let ids = [
  "ep1-s0-teaser",
  "ep1-s1-akshar",
  "ep1-s2-pilla",
  "ep1-s3-chhupam",
  "ep1-s4-bachaav",
  "ep1-s5-kalu-ghar",
  "ep1-s6-topi",
]

let emit = (scene, kind, who, radio, whisper, text) => {
  let obj = Js.Dict.empty()
  Js.Dict.set(obj, "scene", Js.Json.string(scene))
  Js.Dict.set(obj, "kind", Js.Json.string(kind))
  Js.Dict.set(obj, "who", Js.Json.string(who))
  Js.Dict.set(obj, "radio", Js.Json.boolean(radio))
  Js.Dict.set(obj, "whisper", Js.Json.boolean(whisper))
  Js.Dict.set(obj, "text", Js.Json.string(text))
  Js.log(Js.Json.stringify(Js.Json.object_(obj)))
}

let main = () => {
  ids->Belt.Array.forEach(id => {
    let path = Cinema_Backends.Path(dir ++ "/" ++ id ++ ".scene.txt")
    switch Write.read(path) {
    | Error(m) => Js.Console.error("REFUSED " ++ id ++ ": " ++ m)
    | Ok(lines) =>
      lines->Belt.Array.forEach(sp =>
        switch sp {
        | Write.Action(t) => emit(id, "action", "NARRATOR", false, false, t)
        | Write.Dialogue({who, radio, whisper, text}) =>
          emit(id, "dialogue", who, radio, whisper, text)
        }
      )
    }
  })
}

main()
