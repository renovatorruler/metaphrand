/* AMAL — one Hindi dialogue line via ElevenLabs (v3), for the Seedance
   audio-reference lip-sync probe. Cached: skips if the output exists.
   Run: node src/Amal_LineProbe.res.mjs */

type response
@val external fetch: (string, 'a) => promise<response> = "fetch"
@get external statusOf: response => int = "status"
@send external arrayBuffer: response => promise<'ab> = "arrayBuffer"
@send external textOf: response => promise<string> = "text"
@val @scope("Buffer") external bufferFrom: 'a => 'b = "from"
@module("fs") external writeFileSync: (string, 'a) => unit = "writeFileSync"
@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external existsSync: string => bool = "existsSync"

let out = "/Users/dusty/dev/metaphrand/stories/amal/_soulid_probe/ratan_line_probe.mp3"
let apiKey = Js.String2.trim(readFileSync("/Users/dusty/.elevenlabs_api_key", "utf8"))
let voiceId = "XSBqeYvLRWlUwJ57A64w" /* Natraj — Ratan's CAST voice (recovered from git: amal_audio_hi.py VID map). NEVER use stock Adam. */

let text = "[low, weary] कागज़ पे तो सब ठीक है, साहब।"

let main = async () => {
  if existsSync(out) {
    Js.log("SKIP - exists: " ++ out)
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
    let url = "https://api.elevenlabs.io/v1/text-to-speech/" ++ voiceId ++ "?output_format=mp3_44100_128"
    let resp = await fetch(url, opts)
    if statusOf(resp) == 200 {
      let ab = await arrayBuffer(resp)
      writeFileSync(out, bufferFrom(ab))
      Js.log("OK -> " ++ out)
    } else {
      let t = await textOf(resp)
      Js.log("FAIL HTTP " ++ Belt.Int.toString(statusOf(resp)) ++ " - " ++ Js.String2.slice(t, ~from=0, ~to_=300))
    }
  }
}
main()->ignore
