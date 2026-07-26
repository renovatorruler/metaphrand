/* BREHON walkthrough — two quiet music beds via the ElevenLabs Music API
   (no artist names, house law). Cached per cue; stems stay separate so a
   music-free re-mux never re-renders anything.
   Run: node src/Brehon_Music.res.mjs */

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

let dir = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/brehon/audio/music/"
let apiKey = Js.String2.trim(readFileSync("/Users/dusty/.elevenlabs_api_key", "utf8"))

let cues = [
  (
    "bed_problem",
    96000,
    "Sparse pensive instrumental bed for spoken narration: minimal felt piano and a low sustained string drone, slow pulse, understated unease, no drums, no melody hooks, very quiet dynamics, long even texture that never draws attention.",
  ),
  (
    "bed_resolve",
    52000,
    "Warm quiet resolve instrumental bed for spoken narration: soft strings and sparse piano, patient and dignified, gently hopeful without ever swelling, no drums, no melody hooks, very quiet dynamics, ends settled.",
  ),
]

let gen = async (name: string, ms: int, prompt: string): bool => {
  let out = dir ++ name ++ ".mp3"
  if existsSync(out) {
    Js.log("SKIP " ++ name)
    true
  } else {
    let body = Js.Dict.empty()
    Js.Dict.set(body, "prompt", Js.Json.string(prompt))
    Js.Dict.set(body, "music_length_ms", Js.Json.number(Belt.Int.toFloat(ms)))
    let headers = Js.Dict.empty()
    Js.Dict.set(headers, "xi-api-key", apiKey)
    Js.Dict.set(headers, "Content-Type", "application/json")
    let opts = Js.Dict.empty()
    Js.Dict.set(opts, "method", Obj.magic("POST"))
    Js.Dict.set(opts, "headers", Obj.magic(headers))
    Js.Dict.set(opts, "body", Obj.magic(Js.Json.stringify(Js.Json.object_(body))))
    let resp = await fetch("https://api.elevenlabs.io/v1/music", opts)
    if statusOf(resp) == 200 {
      let ab = await arrayBuffer(resp)
      writeFileSync(out, bufferFrom(ab))
      Js.log("OK   " ++ name)
      true
    } else {
      let t = await textOf(resp)
      Js.log("FAIL " ++ name ++ " HTTP " ++ Belt.Int.toString(statusOf(resp)) ++ " " ++ Js.String2.slice(t, ~from=0, ~to_=200))
      false
    }
  }
}

let main = async () => {
  mkdirSync(dir, {"recursive": true})
  let n = Belt.Array.length(cues)
  let rec go = async i =>
    if i < n {
      let (name, ms, p) = Belt.Array.getExn(cues, i)
      let _ = await gen(name, ms, p)
      await go(i + 1)
    }
  await go(0)
  Js.log("MUSIC DONE")
}
main()->ignore
