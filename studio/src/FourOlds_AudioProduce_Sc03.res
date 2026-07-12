/* THE FOUR OLDS audio play — produce sc03 (the audition scene) as audio.
   Reads the VERIFIED engine scene, casts from the approved v13 table-read
   voices, generates dialogue via ElevenLabs v3 and every sound line via
   the ElevenLabs sound-generation endpoint, radio-filters (RADIO) lines,
   loops the first two sounds as beds, mixes sequentially with ffmpeg, and
   emits an MP3 + the per-line performance JSON (the maintained artifact).
   Resumable: existing asset files are reused, not regenerated.
   Run: node src/FourOlds_AudioProduce_Sc03.res.mjs */

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
@module("child_process") external execSync: (string, 'a) => 'b = "execSync"

let scenePath = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/audio/a03_barn_net.scene.txt"
let outDir = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/audio/render_sc03/"

/* approved casting, carried over from the v13 table reads (performance_*.json) */
let voiceOf = who =>
  switch who {
  | "CRICKET" => Some("sP6cqUGhZxuStGV0pn9o") /* Ken */
  | "DUTCH" => Some("TqOasn6BO225ydKxXhaK") /* David */
  | "STITCH" => Some("FPofnDi5DdNeTktLQ0u9") /* Jim Cox */
  | "GUNNY" => Some("9oa4l5rZznK9dXRwFpSB") /* Moe M */
  | _ => None
  }

let apiKey = Js.String2.trim(readFileSync("/Users/dusty/.elevenlabs_api_key", "utf8"))

let post = async (url: string, body: Js.Json.t): option<'buf> => {
  let headers = Js.Dict.empty()
  Js.Dict.set(headers, "xi-api-key", apiKey)
  Js.Dict.set(headers, "Content-Type", "application/json")
  let opts = Js.Dict.empty()
  Js.Dict.set(opts, "method", Obj.magic("POST"))
  Js.Dict.set(opts, "headers", Obj.magic(headers))
  Js.Dict.set(opts, "body", Obj.magic(Js.Json.stringify(body)))
  let resp = await fetch(url, opts)
  let status = statusOf(resp)
  if status == 200 {
    let ab = await arrayBuffer(resp)
    Some(bufferFrom(ab))
  } else {
    let t = await textOf(resp)
    Js.log("HTTP " ++ Belt.Int.toString(status) ++ " — " ++ Js.String2.slice(t, ~from=0, ~to_=200))
    None
  }
}

let tts = async (voiceId: string, text: string, out: string): bool =>
  if existsSync(out) {
    true
  } else {
    let body = Js.Dict.empty()
    Js.Dict.set(body, "text", Js.Json.string(text))
    Js.Dict.set(body, "model_id", Js.Json.string("eleven_v3"))
    switch await post(
      "https://api.elevenlabs.io/v1/text-to-speech/" ++ voiceId ++ "?output_format=mp3_44100_128",
      Js.Json.object_(body),
    ) {
    | Some(buf) => {
        writeFileSync(out, buf)
        true
      }
    | None => false
    }
  }

let sfx = async (text: string, seconds: float, out: string): bool =>
  if existsSync(out) {
    true
  } else {
    let body = Js.Dict.empty()
    Js.Dict.set(body, "text", Js.Json.string(text))
    Js.Dict.set(body, "duration_seconds", Js.Json.number(seconds))
    switch await post("https://api.elevenlabs.io/v1/sound-generation", Js.Json.object_(body)) {
    | Some(buf) => {
        writeFileSync(out, buf)
        true
      }
    | None => false
    }
  }

let sh = (cmd: string): unit => {
  let opts = Js.Dict.empty()
  Js.Dict.set(opts, "stdio", Obj.magic("pipe"))
  let _ = execSync(cmd, opts)
}

let pad = i => (i < 10 ? "00" : i < 100 ? "0" : "") ++ Belt.Int.toString(i)

let main = async () => {
  mkdirSync(outDir, {"recursive": true})
  switch Write.read(Cinema_Backends.Path(scenePath)) {
  | Error(m) => Js.log("REFUSED — " ++ m)
  | Ok(lns) => {
      /* ---- generate assets, in scene order ---- */
      let entries = [] /* (index, kind, wavPath) in order; kind: "bed" | "evt" */
      let perf = [] /* performance JSON lines */
      let bedCount = ref(0)
      let failed = ref(0)
      let n = Belt.Array.length(lns)
      let rec go = async i =>
        if i < n {
          let idx = pad(i)
          switch Belt.Array.getExn(lns, i) {
          | Write.Dialogue({who, radio, whisper, text}) => {
              switch voiceOf(who) {
              | Some(v) => {
                  let mp3 = outDir ++ idx ++ "_dlg.mp3"
                  /* whisper becomes a v3 delivery tag; wrylies already lead the text */
                  let speak = (whisper ? "[whispers] " : "") ++ text
                  let ok = await tts(v, speak, mp3)
                  if ok {
                    let wav = outDir ++ idx ++ ".wav"
                    if !existsSync(wav) {
                      if radio {
                        sh(
                          "/opt/homebrew/bin/ffmpeg -y -loglevel error -i " ++
                          mp3 ++
                          " -af \"highpass=f=350,lowpass=f=3200,acompressor=threshold=-18dB:ratio=4,volume=1.1\" -ar 44100 -ac 2 " ++
                          wav,
                        )
                      } else {
                        sh("/opt/homebrew/bin/ffmpeg -y -loglevel error -i " ++ mp3 ++ " -ar 44100 -ac 2 " ++ wav)
                      }
                    }
                    Js.Array2.push(entries, (i, "evt", wav))->ignore
                    Js.Array2.push(
                      perf,
                      `{"i":${Belt.Int.toString(i)},"role":"${who}","radio":${radio ? "true" : "false"},"text":${Js.Json.stringify(Js.Json.string(speak))}}`,
                    )->ignore
                    Js.log("dlg  " ++ idx ++ " " ++ who)
                  } else {
                    failed := failed.contents + 1
                    Js.log("FAIL dlg " ++ idx)
                  }
                }
              | None => Js.log("skip " ++ idx ++ " (uncast: " ++ who ++ ")")
              }
            }
          | Write.Action(t) => {
              let isBed = bedCount.contents < 2 /* the first two sounds are the beds: wind, hum */
              let mp3 = outDir ++ idx ++ "_sfx.mp3"
              let ok = await sfx(t, isBed ? 20.0 : 4.0, mp3)
              if ok {
                let wav = outDir ++ idx ++ ".wav"
                if !existsSync(wav) {
                  sh("/opt/homebrew/bin/ffmpeg -y -loglevel error -i " ++ mp3 ++ " -ar 44100 -ac 2 " ++ wav)
                }
                if isBed {
                  bedCount := bedCount.contents + 1
                  Js.Array2.push(entries, (i, "bed", wav))->ignore
                } else {
                  Js.Array2.push(entries, (i, "evt", wav))->ignore
                }
                Js.Array2.push(
                  perf,
                  `{"i":${Belt.Int.toString(i)},"sfx":${Js.Json.stringify(Js.Json.string(t))},"bed":${isBed ? "true" : "false"}}`,
                )->ignore
                Js.log("sfx  " ++ idx ++ (isBed ? " (bed)" : ""))
              } else {
                failed := failed.contents + 1
                Js.log("FAIL sfx " ++ idx)
              }
            }
          }
          await go(i + 1)
        }
      await go(0)

      /* ---- mix: events concatenated with gaps; beds looped under ---- */
      let evts = entries->Belt.Array.keep(((_, k, _)) => k == "evt")
      let beds = entries->Belt.Array.keep(((_, k, _)) => k == "bed")
      /* silence gap between events */
      let gap = outDir ++ "gap.wav"
      if !existsSync(gap) {
        sh("/opt/homebrew/bin/ffmpeg -y -loglevel error -f lavfi -i anullsrc=r=44100:cl=stereo -t 0.4 " ++ gap)
      }
      let listFile = outDir ++ "concat.txt"
      let lines =
        evts
        ->Belt.Array.map(((_, _, w)) => "file '" ++ w ++ "'\nfile '" ++ gap ++ "'")
        ->Belt.Array.joinWith("\n", x => x)
      writeFileSync(listFile, bufferFrom(lines))
      let eventsWav = outDir ++ "events.wav"
      sh(
        "/opt/homebrew/bin/ffmpeg -y -loglevel error -f concat -safe 0 -i " ++
        listFile ++ " -ar 44100 -ac 2 " ++ eventsWav,
      )
      let final = outDir ++ "mix.wav"
      switch beds {
      | [(_, _, b1), (_, _, b2)] =>
        sh(
          "/opt/homebrew/bin/ffmpeg -y -loglevel error -i " ++
          eventsWav ++
          " -stream_loop -1 -i " ++
          b1 ++
          " -stream_loop -1 -i " ++
          b2 ++
          " -filter_complex \"[1:a]volume=0.18[w];[2:a]volume=0.14[h];[0:a][w][h]amix=inputs=3:duration=first:normalize=0[out]\" -map \"[out]\" " ++
          final,
        )
      | _ => sh("/opt/homebrew/bin/cp " ++ eventsWav ++ " " ++ final)
      }
      let mp3out = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/audio/FOUR-OLDS_AUDIO_sc03_v1.mp3"
      sh("/opt/homebrew/bin/ffmpeg -y -loglevel error -i " ++ final ++ " -b:a 192k " ++ mp3out)
      /* the maintained artifact */
      writeFileSync(
        outDir ++ "performance_a03.json",
        bufferFrom(
          `{"title":"THE FOUR OLDS audio play — sc03 the barn net","model_id":"eleven_v3","cast":{"CRICKET":"sP6cqUGhZxuStGV0pn9o","DUTCH":"TqOasn6BO225ydKxXhaK","STITCH":"FPofnDi5DdNeTktLQ0u9","GUNNY":"9oa4l5rZznK9dXRwFpSB"},"lines":[` ++
          perf->Belt.Array.joinWith(",", x => x) ++ `]}`,
        ),
      )
      Js.log(
        "RENDER DONE — " ++
        Belt.Int.toString(Belt.Array.length(evts)) ++
        " events, " ++
        Belt.Int.toString(Belt.Array.length(beds)) ++
        " beds, " ++
        Belt.Int.toString(failed.contents) ++ " failed -> " ++ mp3out,
      )
    }
  }
}
main()->ignore
