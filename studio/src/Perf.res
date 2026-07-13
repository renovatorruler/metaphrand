/* See Perf.resi — the performance law, made structural. */

@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external writeFileSync: (string, 'a) => unit = "writeFileSync"
@module("fs") external existsSync: string => bool = "existsSync"
@val @scope("Buffer") external bufferFrom: 'a => 'b = "from"

type response
@val external fetch: (string, 'a) => promise<response> = "fetch"
@get external statusOf: response => int = "status"
@send external arrayBuffer: response => promise<'ab> = "arrayBuffer"
@send external textOf: response => promise<string> = "text"

type performed = {i: int, role: string, text: string}

let roleOf = p => p.role
let indexOf = p => p.i

let load = (~perfPath, ~scenePath) =>
  if !existsSync(perfPath) {
    Error(
      "NO PERFORMANCE — " ++
      perfPath ++
      " missing. Run the performance pass first (FourOlds_PerformWave); unperformed dialogue does not render.",
    )
  } else {
    switch Write.read(Cinema_Backends.Path(scenePath)) {
    | Error(m) => Error("scene refused — " ++ m)
    | Ok(lns) => {
        let json = Js.Json.parseExn(readFileSync(perfPath, "utf8"))
        let rejects: option<float> = Obj.magic(json)["rejects"]->Js.Nullable.toOption
        if rejects->Belt.Option.getWithDefault(0.0) > 0.0 {
          Error(
            "PERFORMANCE GATE — " ++
            perfPath ++ " carries gate rejects; re-run the performance pass before rendering.",
          )
        } else {
        let lines: array<performed> = Obj.magic(json)["lines"]
        let byIdx = Js.Dict.empty()
        lines->Belt.Array.forEach(l => Js.Dict.set(byIdx, Belt.Int.toString(l.i), l))
        /* the gate, re-run at load: words are law, coverage is total */
        let err = ref(None)
        let check = (i, text) =>
          switch Js.Dict.get(byIdx, Belt.Int.toString(i)) {
          | None => err := Some("line " ++ Belt.Int.toString(i) ++ " unperformed")
          | Some(p) =>
            if Perform.stripTags(p.text) != Perform.stripTags(text) {
              err := Some("line " ++ Belt.Int.toString(i) ++ " words differ from canon")
            }
          }
        lns->Belt.Array.forEachWithIndex((i, l) =>
          switch (err.contents, l) {
          | (None, Write.Dialogue({text})) => check(i, text)
          | (None, Write.Action(t)) =>
            switch Perform.embeddedOf(t) {
            | Some((_, text)) => check(i, text)
            | None => ()
            }
          | _ => ()
          }
        )
        switch err.contents {
        | Some(m) => Error("PERFORMANCE GATE — " ++ m ++ " (" ++ perfPath ++ ")")
        | None => Ok(lines)
        }
        }
      }
    }
  }

let apiKey = Js.String2.trim(readFileSync("/Users/dusty/.elevenlabs_api_key", "utf8"))

let tts = async (p: performed, ~voiceId, ~outMp3) => {
  let sidecar = outMp3 ++ ".txt"
  let fresh =
    existsSync(outMp3) &&
    existsSync(sidecar) &&
    readFileSync(sidecar, "utf8") == p.text
  if fresh {
    true
  } else {
    let body = Js.Dict.empty()
    Js.Dict.set(body, "text", Js.Json.string(p.text))
    Js.Dict.set(body, "model_id", Js.Json.string("eleven_v3"))
    let headers = Js.Dict.empty()
    Js.Dict.set(headers, "xi-api-key", apiKey)
    Js.Dict.set(headers, "Content-Type", "application/json")
    let opts = Js.Dict.empty()
    Js.Dict.set(opts, "method", Obj.magic("POST"))
    Js.Dict.set(opts, "headers", Obj.magic(headers))
    Js.Dict.set(opts, "body", Obj.magic(Js.Json.stringify(Js.Json.object_(body))))
    let resp = await fetch(
      "https://api.elevenlabs.io/v1/text-to-speech/" ++ voiceId ++ "?output_format=mp3_44100_128",
      opts,
    )
    if statusOf(resp) == 200 {
      let ab = await arrayBuffer(resp)
      writeFileSync(outMp3, bufferFrom(ab))
      writeFileSync(sidecar, bufferFrom(p.text))
      true
    } else {
      let t = await textOf(resp)
      Js.log(
        "HTTP " ++ Belt.Int.toString(statusOf(resp)) ++ " — " ++ Js.String2.slice(t, ~from=0, ~to_=160),
      )
      false
    }
  }
}
