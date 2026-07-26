/* अमल — the Charan ballad (cinematic noir variant) via the ElevenLabs Music
   API. No artist names (house law). Cached: skips if the output exists.
   Run: node src/Amal_BalladMusic.res.mjs */

type response
@val external fetch: (string, 'a) => promise<response> = "fetch"
@get external statusOf: response => int = "status"
@send external arrayBuffer: response => promise<'ab> = "arrayBuffer"
@send external textOf: response => promise<string> = "text"
@val @scope("Buffer") external bufferFrom: 'a => 'b = "from"
@module("fs") external writeFileSync: (string, 'a) => unit = "writeFileSync"
@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external existsSync: string => bool = "existsSync"

let out = "/Users/dusty/Dev/metaphrand/stories/amal/AMAL-CHARAN-BALLAD_2026-07-16_1520_v1_noir.mp3"
let apiKey = Js.String2.trim(readFileSync("/Users/dusty/.elevenlabs_api_key", "utf8"))

let prompt =
  "A dark cinematic folk ballad for a prestige television title sequence: a Rajasthani war ballad meets western noir. " ++
  "Sung by a WEATHERED ELDERLY MALE VOICE - gravelly, hoarse, cracked with age, close-miked and intimate, trembling sustained notes. " ++
  "Instrumentation: ravanhatta (Rajasthani bowed folk fiddle) over low cello drones, sparse deep percussion with a slow floor-tom heartbeat, " ++
  "a twangy baritone guitar tremolo, vast spacious reverb. Slow brooding tempo; grief and defiance; builds from a whisper to a restrained powerful finish, " ++
  "then falls away to a lone ravanhatta drone at the end. NO pop polish, no autotune, no young smooth vocals, no EDM, no heavy distortion.\n\n" ++
  "The lyrics are in Hindi (Devanagari). Sing them exactly as written, in this structure:\n\n" ++
  "SPOKEN INTRO (old voice reciting over cello and ravanhatta drone):\n" ++
  "गढ़ गिरा जिस भोर को, सूरज निकला लाल।\n" ++
  "सिर धरती पर गिर पड़ा, पर उठी रही तलवार॥\n\n" ++
  "VERSE 1 (intimate aged voice, heartbeat percussion enters):\n" ++
  "संवत की वो काली रैना, गढ़ पर घिर आई रात,\n" ++
  "दुश्मन की फ़ौजें उमड़ीं, जैसे सावन की बरसात।\n" ++
  "गढ़पति ने केसरिया बाँधा, खोले गढ़ के द्वार,\n" ++
  "अमल घोल के पी गए योद्धा, चढ़ गए असवार।\n\n" ++
  "CHORUS (restrained power, the voice cracks with age):\n" ++
  "सिर कट गया रण में, पर घोड़ा ना रुका,\n" ++
  "हाथ में तलवार चली, झुझार ना झुका।\n" ++
  "सिर कट गया रण में, पर घोड़ा ना रुका,\n" ++
  "हाथ में तलवार चली, झुझार ना झुका।\n\n" ++
  "VERSE 2 (stripped back, cello alone, mournful):\n" ++
  "धड़ लड़ता रहा गली-गली, सिर देखे आसमान,\n" ++
  "माटी पी गई लोहू सारा, माटी रखे मान।\n" ++
  "पत्थर पर था नाम खुदा, मिट गया निशान,\n" ++
  "गीतों में वो ज़िंदा है, पत्थर बेज़ुबान।\n\n" ++
  "BRIDGE (whispered, tremolo guitar swelling):\n" ++
  "कागज़ झूठ लिखे तो लिखे…\n" ++
  "पत्थर नाम भुलाए तो भुलाए…\n\n" ++
  "FINAL CHORUS (full but held back, grief and defiance, aged voice straining):\n" ++
  "पत्थर का नाम मिटे तो मिटे, गीत ना मिटने पाए,\n" ++
  "जब तक भाट की साँस चले, झुझार जिया जाए।\n" ++
  "सिर कट गया रण में, पर घोड़ा ना रुका,\n" ++
  "हाथ में तलवार चली, झुझार ना झुका।\n\n" ++
  "OUTRO (everything falls away, lone ravanhatta drone, the voice fading and cracking):\n" ++
  "जब तक भाट की साँस चले… झुझार जिया जाए…"

let main = async () => {
  if existsSync(out) {
    Js.log("SKIP - exists: " ++ out)
  } else {
    let body = Js.Dict.empty()
    Js.Dict.set(body, "prompt", Js.Json.string(prompt))
    Js.Dict.set(body, "music_length_ms", Js.Json.number(180000.0))
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
      Js.log("OK -> " ++ out)
    } else {
      let t = await textOf(resp)
      Js.log("FAIL HTTP " ++ Belt.Int.toString(statusOf(resp)) ++ " - " ++ Js.String2.slice(t, ~from=0, ~to_=300))
    }
  }
}
main()->ignore
