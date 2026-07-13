/* THE FOUR OLDS — render a scene from its PERFORMANCE JSON: dialogue is
   regenerated from the tagged text; sound assets are CLONED from the
   existing render dir (never re-billed). The result dir is Mix2-ready.
   Demo scope: the four-olds principals (the barn net). The full cast map
   moves to a shared Cast module when this graduates into the main renderer
   (FourOlds_AudioRender's map can't be imported — module mains run on import).
   Run: node src/FourOlds_RenderPerf.res.mjs <perf.json> <srcRenderDir> <outDir> */

type response
@val external fetch: (string, 'a) => promise<response> = "fetch"
@get external statusOf: response => int = "status"
@send external arrayBuffer: response => promise<'ab> = "arrayBuffer"
@send external textOf: response => promise<string> = "text"
@val @scope("Buffer") external bufferFrom: 'a => 'b = "from"
@module("fs") external writeFileSync: (string, 'a) => unit = "writeFileSync"
@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external existsSync: string => bool = "existsSync"
@module("fs") external mkdirSync: (string, 'a) => unit = "mkdirSync"
@module("fs") external readdirSync: string => array<string> = "readdirSync"
@module("fs") external copyFileSync: (string, string) => unit = "copyFileSync"
@module("child_process") external execSync: (string, 'a) => 'b = "execSync"
@val @scope("process") external argv: array<string> = "argv"

let voiceOf = who =>
  switch who {
  | "CRICKET" => Some("sP6cqUGhZxuStGV0pn9o")
  | "DUTCH" => Some("TqOasn6BO225ydKxXhaK")
  | "STITCH" => Some("FPofnDi5DdNeTktLQ0u9")
  | "GUNNY" => Some("9oa4l5rZznK9dXRwFpSB")
  | _ => None
  }

let apiKey = Js.String2.trim(readFileSync("/Users/dusty/.elevenlabs_api_key", "utf8"))

let tts = async (voiceId: string, text: string, outMp3: string): bool =>
  if existsSync(outMp3) {
    true
  } else {
    let body = Js.Dict.empty()
    Js.Dict.set(body, "text", Js.Json.string(text))
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
      true
    } else {
      let t = await textOf(resp)
      Js.log("HTTP " ++ Belt.Int.toString(statusOf(resp)) ++ " " ++ Js.String2.slice(t, ~from=0, ~to_=160))
      false
    }
  }

let sh = (cmd: string): unit => {
  let opts = Js.Dict.empty()
  Js.Dict.set(opts, "stdio", Obj.magic("pipe"))
  let _ = execSync(cmd, opts)
}

let pad = i => (i < 10 ? "00" : i < 100 ? "0" : "") ++ Belt.Int.toString(i)

let main = async () => {
  let perfPath = Belt.Array.get(argv, 2)->Belt.Option.getWithDefault("")
  let srcDir = Belt.Array.get(argv, 3)->Belt.Option.getWithDefault("")
  let outDir = Belt.Array.get(argv, 4)->Belt.Option.getWithDefault("")
  if perfPath == "" || srcDir == "" || outDir == "" {
    Js.log("usage: node src/FourOlds_RenderPerf.res.mjs <perf.json> <srcRenderDir> <outDir>")
  } else {
    mkdirSync(outDir, {"recursive": true})
    let perf = Js.Json.parseExn(readFileSync(perfPath, "utf8"))
    let lines: array<{"i": int, "role": string, "text": string}> = Obj.magic(perf)["lines"]
    let dlgIdx = Js.Dict.empty()
    lines->Belt.Array.forEach(l => Js.Dict.set(dlgIdx, pad(l["i"]), l))
    /* clone every non-dialogue wav from the source render (sfx, beds) */
    readdirSync(srcDir)
    ->Belt.Array.keep(f => Js.Re.test_(%re("/^\d{3}\.wav$/"), f))
    ->Belt.Array.forEach(f => {
      let idx = Js.String2.slice(f, ~from=0, ~to_=3)
      switch Js.Dict.get(dlgIdx, idx) {
      | Some(_) => () /* dialogue — regenerated below */
      | None =>
        if !existsSync(outDir ++ "/" ++ f) {
          copyFileSync(srcDir ++ "/" ++ f, outDir ++ "/" ++ f)
        }
      }
    })
    /* regenerate dialogue from the tagged text */
    let failed = ref(0)
    let n = Belt.Array.length(lines)
    let rec go = async k =>
      if k < n {
        let l = Belt.Array.getExn(lines, k)
        switch voiceOf(l["role"]) {
        | None => Js.log("UNCAST " ++ l["role"])
        | Some(v) => {
            let mp3 = outDir ++ "/" ++ pad(l["i"]) ++ "_dlg.mp3"
            let ok = await tts(v, l["text"], mp3)
            if ok {
              let wav = outDir ++ "/" ++ pad(l["i"]) ++ ".wav"
              if !existsSync(wav) {
                sh("/opt/homebrew/bin/ffmpeg -y -loglevel error -i " ++ mp3 ++ " -ar 44100 -ac 2 " ++ wav)
              }
              Js.log("dlg " ++ pad(l["i"]) ++ " " ++ l["role"])
            } else {
              failed := failed.contents + 1
            }
          }
        }
        await go(k + 1)
      }
    await go(0)
    Js.log(
      "PERF RENDER done — " ++
      Belt.Int.toString(n) ++
      " dialogue lines, " ++
      Belt.Int.toString(failed.contents) ++ " failed -> " ++ outDir,
    )
  }
}
main()->ignore
