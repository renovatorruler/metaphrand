/* THE FOUR OLDS audio play — the general per-scene renderer.
   Generalizes the approved sc03 pipeline: reads a verified audio scene,
   casts every cue from the full voice map (v13-approved + provisional),
   TTS via ElevenLabs v3, every ACTION line via sound-generation, radio
   filter on (RADIO)/(PA) lines, keyword beds looped under, kind-aware
   gaps, per-scene mix + performance JSON. Resumable per asset; an
   existing mix.wav is never recomputed (protects approved renders)
   unless REMIX=1.
   Run:  SCENES=a01_cold_open,a02_bank node src/FourOlds_AudioRender.res.mjs
   All:  node src/FourOlds_AudioRender.res.mjs   (Part One default)
   Then: ASSEMBLE=/abs/out.mp3 node src/FourOlds_AudioRender.res.mjs */

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
@val @scope("process") external env: Js.Dict.t<string> = "env"

let audioDir = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/audio/"
let ffmpeg = "/opt/homebrew/bin/ffmpeg"

/* ---- casting ----
   v13-approved voices carried over from the table reads; the rest are
   PROVISIONAL picks from the account inventory, flagged for the
   director's ear to recast. */
let voiceOf = who =>
  switch who {
  /* approved (v13 table reads) */
  | "CRICKET" => Some("sP6cqUGhZxuStGV0pn9o") /* Ken */
  | "DUTCH" => Some("TqOasn6BO225ydKxXhaK") /* David */
  | "STITCH" => Some("FPofnDi5DdNeTktLQ0u9") /* Jim Cox */
  | "GUNNY" => Some("9oa4l5rZznK9dXRwFpSB") /* Moe M */
  | "PELL" => Some("FhztqDnr1aPqLSEpGz3v") /* Reginald */
  | "WADE" => Some("GxlyuhtF6MwdhQmwZ3cu") /* Dave */
  | "DANNY" => Some("BgKhVteUTnSGoNk6fizV")
  | "HOLLOWAY" => Some("VkL7Dlo4mlO2YXRw09M7") /* Wesley */
  | "MARWANI" => Some("ZF7Ng6hYSXU5QiOXbbSZ") /* Clinton */
  | "ANCHOR" => Some("QyCGbzzEtSqHWJ8rNRMK") /* Alexandria */
  | "OFFICER" => Some("bO5h0vChrZCBN2GYUhC5") /* Ryan */
  | "BUCK" => Some("pqHfZKP75CvOlQylNhV4") /* Bill */
  | "HALE" => Some("onwK4e9ZLuTAKqWW03F9") /* Daniel */
  | "COMMENTATOR" => Some("TX3LPaxmHKxFdv7VOQHJ") /* Liam */
  | "SENATOR" => Some("2EiwWnXFnvU5JabPnv8n") /* Clyde */
  | "RADIO" => Some("XrExE9yKIg1WjnnlVkGX") /* Matilda */
  /* provisional (account inventory; recast by ear) */
  | "MACK" => Some("8iPB8F25Y94jdslCQJuC") /* Deacon - Ray, deep calm */
  | "VESS" => Some("lVpo6IOLjDX4LxkYRZyj") /* Deborah, authoritative */
  | "JOSS" => Some("mWRBtRP92mUXZzi4RZ0Y") /* Blake, late 20s */
  | "TITO" => Some("LxsCEphJBnRAyXU02gTG") /* Joshua, soft gentle */
  | "EARLENE" => Some("aIu5oHglU5AHNc2x0AZu") /* Jane Hackett */
  | "LITA" => Some("wGcFBfKz5yUQqhqr0mVy") /* Maria Moody, octogenarian */
  | "BENNING" | "JUDGE BENNING" => Some("HSBWXljo3oivWhybh3YX") /* Mr Wellington */
  | "COOK" => Some("rMxoUiufNLar6QLKTnA2") /* Vincent W. Davis */
  | "ANNOUNCER" => Some("QTn7zgOqA9G2UKp3tNJb") /* Keith Hinton, radio */
  | "PA" => Some("Mjyxcc6ZQEN1TKqM9pbR") /* Romeo Valentino, clear */
  | "WORKER" | "MOVER" | "DRIVER" | "GUARD" => Some("iP95p4xoKVk53GoZ742B") /* Chris */
  | "MARSH" => Some("WwLGR2UgbhuTNMpk6oHi") /* Bishop - Matt */
  | "FACILITATOR" => Some("hpp4J3VqNfWAUOO0d1Us") /* Bella */
  | "BAY TWO MAN" => Some("dIa7afHH94O36L8tjJ0L") /* Dejuan */
  | "STREAMER" => Some("IkksQWAjbvt9CKa7hRkh") /* Weissman, eager */
  | "LAWYER #1" => Some("cjVigY5qzO86Huf0OWal") /* Eric */
  | "LAWYER #2" => Some("nPczCjzI2devNBz1zQrb") /* Brian */
  | "BRANDT" => Some("JcwFVpR60FiOW4cPEqI2") /* SUP-B Gunner */
  | "LINDQVIST" => Some("a1TnjruAs5jTzdrjL8Vd") /* Frank (Euro provisional) */
  | "SHEN" => Some("dPah2VEoifKnZT37774q") /* Knox Dark */
  | "BOY" => Some("sUzXYdokj3o9QQ91yPRF") /* Brooks, young */
  | "CROWD" => Some("bIHbv24MWmeRgasZH58o") /* Will — chorused in the mix */
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

/* a bed is early ambience worth looping under the scene: only within the
   first three ACTION lines, at most two per scene, and only if it reads
   as continuous room tone rather than an event */
let bedRe = %re(
  "/(hum|wind |room tone|walla|murmur|applause climbs|stand quiet|rain|griddle hisses|stove ticks|fan hums|fluorescent)/i"
)

/* dialogue the engine embedded inside an ACTION line, e.g.
   "ACTION: VESS (PA): Bay Two closes today..." — rescue it as radio-class speech */
let embeddedRe = %re("/^([A-Z][A-Z .'#-]+?)\s*\((PA|RADIO|TV|ON TV)\):\s*(.+)$/")

let radioFilter = (src: string, dst: string): unit =>
  sh(
    ffmpeg ++
    " -y -loglevel error -i " ++
    src ++
    " -af \"highpass=f=350,lowpass=f=3200,acompressor=threshold=-18dB:ratio=4,volume=1.1\" -ar 44100 -ac 2 " ++
    dst,
  )

let plainWav = (src: string, dst: string): unit =>
  sh(ffmpeg ++ " -y -loglevel error -i " ++ src ++ " -ar 44100 -ac 2 " ++ dst)

/* CROWD: one voice chorused into a small crowd — three detuned, delayed copies */
let crowdWav = (src: string, dst: string): unit =>
  sh(
    ffmpeg ++
    " -y -loglevel error -i " ++
    src ++
    " -filter_complex \"[0:a]asetrate=44100*0.96,aresample=44100,adelay=0|0[a];[0:a]asetrate=44100*1.04,aresample=44100,adelay=70|70[b];[0:a]adelay=130|130[c];[a][b][c]amix=inputs=3:normalize=0,volume=1.2\" -ar 44100 -ac 2 " ++
    dst,
  )

let renderScene = async (base: string): bool => {
  let scenePath = audioDir ++ base ++ ".scene.txt"
  /* a03's approved assets live in render_sc03 — reuse, never respend */
  let renderDir = base == "a03_barn_net" ? audioDir ++ "render_sc03/" : audioDir ++ "render_" ++ Js.String2.slice(base, ~from=0, ~to_=3) ++ "/"
  mkdirSync(renderDir, {"recursive": true})
  switch Write.read(Cinema_Backends.Path(scenePath)) {
  | Error(m) => {
      Js.log("REFUSED " ++ base ++ " — " ++ m)
      false
    }
  | Ok(lns) => {
      let entries = [] /* (kind, wavPath); kind: "dlg" | "sfx" | "bed" */
      let perf = []
      let castUsed = Js.Dict.empty()
      let bedCount = ref(0)
      let actionIdx = ref(0)
      let failed = ref(0)
      let n = Belt.Array.length(lns)
      let doDlg = async (i, who, radioClass, whisper, text) =>
        switch voiceOf(who) {
        | None => Js.log("UNCAST " ++ pad(i) ++ " " ++ who ++ " — line dropped")
        | Some(v) => {
            Js.Dict.set(castUsed, who, Js.Json.string(v))
            let mp3 = renderDir ++ pad(i) ++ "_dlg.mp3"
            let speak = (whisper ? "[whispers] " : "") ++ text
            let ok = await tts(v, speak, mp3)
            if ok {
              let wav = renderDir ++ pad(i) ++ ".wav"
              if !existsSync(wav) {
                if who == "CROWD" {
                  crowdWav(mp3, wav)
                } else if radioClass {
                  radioFilter(mp3, wav)
                } else {
                  plainWav(mp3, wav)
                }
              }
              Js.Array2.push(entries, ("dlg", wav))->ignore
              Js.Array2.push(
                perf,
                `{"i":${Belt.Int.toString(i)},"role":"${who}","radio":${radioClass ? "true" : "false"},"text":${Js.Json.stringify(Js.Json.string(speak))}}`,
              )->ignore
              Js.log("dlg  " ++ pad(i) ++ " " ++ who)
            } else {
              failed := failed.contents + 1
              Js.log("FAIL dlg " ++ pad(i) ++ " " ++ who)
            }
          }
        }
      let rec go = async i =>
        if i < n {
          switch Belt.Array.getExn(lns, i) {
          | Write.Dialogue({who, radio, whisper, text}) => await doDlg(i, who, radio, whisper, text)
          | Write.Action(t) =>
            switch Js.Re.exec_(embeddedRe, t) {
            | Some(r) => {
                /* dialogue hiding in an ACTION line */
                let g = Js.Re.captures(r)
                let who = Js.Nullable.toOption(Belt.Array.getExn(g, 1))->Belt.Option.getWithDefault("")
                let text = Js.Nullable.toOption(Belt.Array.getExn(g, 3))->Belt.Option.getWithDefault("")
                await doDlg(i, Js.String2.trim(who), true, false, text)
              }
            | None => {
                let isBed =
                  bedCount.contents < 2 &&
                  actionIdx.contents < 3 &&
                  Js.Re.test_(bedRe, t)
                actionIdx := actionIdx.contents + 1
                let mp3 = renderDir ++ pad(i) ++ "_sfx.mp3"
                let ok = await sfx(t, isBed ? 20.0 : 4.0, mp3)
                if ok {
                  let wav = renderDir ++ pad(i) ++ ".wav"
                  if !existsSync(wav) {
                    plainWav(mp3, wav)
                  }
                  if isBed {
                    bedCount := bedCount.contents + 1
                  }
                  Js.Array2.push(entries, (isBed ? "bed" : "sfx", wav))->ignore
                  Js.Array2.push(
                    perf,
                    `{"i":${Belt.Int.toString(i)},"sfx":${Js.Json.stringify(Js.Json.string(t))},"bed":${isBed ? "true" : "false"}}`,
                  )->ignore
                  Js.log("sfx  " ++ pad(i) ++ (isBed ? " (bed)" : ""))
                } else {
                  failed := failed.contents + 1
                  Js.log("FAIL sfx " ++ pad(i))
                }
              }
            }
          }
          await go(i + 1)
        }
      await go(0)

      /* ---- mix ---- */
      let final = renderDir ++ "mix.wav"
      let remix = Js.Dict.get(env, "REMIX") != None
      if existsSync(final) && !remix {
        Js.log("mix  " ++ base ++ " (kept existing)")
      } else {
        let evts = entries->Belt.Array.keep(((k, _)) => k != "bed")
        let beds = entries->Belt.Array.keep(((k, _)) => k == "bed")
        let gapS = renderDir ++ "gap_s.wav"
        let gapM = renderDir ++ "gap_m.wav"
        if !existsSync(gapS) {
          sh(ffmpeg ++ " -y -loglevel error -f lavfi -i anullsrc=r=44100:cl=stereo -t 0.15 " ++ gapS)
        }
        if !existsSync(gapM) {
          sh(ffmpeg ++ " -y -loglevel error -f lavfi -i anullsrc=r=44100:cl=stereo -t 0.5 " ++ gapM)
        }
        let nEvts = Belt.Array.length(evts)
        let listFile = renderDir ++ "concat.txt"
        let lines =
          evts
          ->Belt.Array.mapWithIndex((ix, (k, w)) => {
            if ix == nEvts - 1 {
              "file '" ++ w ++ "'"
            } else {
              let (nk, _) = Belt.Array.getExn(evts, ix + 1)
              let g = k == "dlg" && nk == "dlg" ? gapS : gapM
              "file '" ++ w ++ "'\nfile '" ++ g ++ "'"
            }
          })
          ->Belt.Array.joinWith("\n", x => x)
        writeFileSync(listFile, bufferFrom(lines))
        let eventsWav = renderDir ++ "events.wav"
        sh(
          ffmpeg ++
          " -y -loglevel error -f concat -safe 0 -i " ++
          listFile ++ " -ar 44100 -ac 2 " ++ eventsWav,
        )
        switch beds {
        | [(_, b1), (_, b2)] =>
          sh(
            ffmpeg ++
            " -y -loglevel error -i " ++
            eventsWav ++
            " -stream_loop -1 -i " ++
            b1 ++
            " -stream_loop -1 -i " ++
            b2 ++
            " -filter_complex \"[1:a]volume=0.18[w];[2:a]volume=0.14[h];[0:a][w][h]amix=inputs=3:duration=first:normalize=0[out]\" -map \"[out]\" " ++
            final,
          )
        | [(_, b1)] =>
          sh(
            ffmpeg ++
            " -y -loglevel error -i " ++
            eventsWav ++
            " -stream_loop -1 -i " ++
            b1 ++
            " -filter_complex \"[1:a]volume=0.18[w];[0:a][w]amix=inputs=2:duration=first:normalize=0[out]\" -map \"[out]\" " ++
            final,
          )
        | _ => sh("/bin/cp " ++ eventsWav ++ " " ++ final)
        }
      }
      writeFileSync(
        renderDir ++ "performance_" ++ Js.String2.slice(base, ~from=0, ~to_=3) ++ ".json",
        bufferFrom(
          `{"title":"THE FOUR OLDS audio play — ${base}","model_id":"eleven_v3","cast":${Js.Json.stringify(Js.Json.object_(castUsed))},"lines":[` ++
          perf->Belt.Array.joinWith(",", x => x) ++ `]}`,
        ),
      )
      Js.log(
        "SCENE " ++
        base ++
        " — " ++
        Belt.Int.toString(Belt.Array.length(entries)) ++
        " entries, " ++
        Belt.Int.toString(failed.contents) ++ " failed",
      )
      failed.contents == 0
    }
  }
}

let partOne = [
  "a01_cold_open",
  "a02_bank",
  "a03_barn_net",
  "a04_accord",
  "a06_seizure",
  "a07_fireworks",
  "a08_diner",
  "a09_grave",
  "a10_legion",
  "a11_baytwo",
  "a12_promotion",
  "a13_shop",
]

let main = async () => {
  let scenes = switch Js.Dict.get(env, "SCENES") {
  | Some(s) => Js.String2.split(s, ",")
  | None => partOne
  }
  let bad = ref(0)
  let rec go = async i =>
    if i < Belt.Array.length(scenes) {
      let ok = await renderScene(Js.String2.trim(Belt.Array.getExn(scenes, i)))
      if !ok {
        bad := bad.contents + 1
      }
      await go(i + 1)
    }
  await go(0)
  /* ---- part assembly: scene mixes joined by 1.5s of silence ---- */
  switch Js.Dict.get(env, "ASSEMBLE") {
  | Some(out) if bad.contents == 0 => {
      let gap = audioDir ++ "gap_scene.wav"
      if !existsSync(gap) {
        sh(ffmpeg ++ " -y -loglevel error -f lavfi -i anullsrc=r=44100:cl=stereo -t 1.5 " ++ gap)
      }
      let listFile = audioDir ++ "part_concat.txt"
      let nSc = Belt.Array.length(scenes)
      let lines =
        scenes
        ->Belt.Array.mapWithIndex((ix, b) => {
          let bb = Js.String2.trim(b)
          let dir = bb == "a03_barn_net" ? audioDir ++ "render_sc03/" : audioDir ++ "render_" ++ Js.String2.slice(bb, ~from=0, ~to_=3) ++ "/"
          let f = "file '" ++ dir ++ "mix.wav'"
          ix == nSc - 1 ? f : f ++ "\nfile '" ++ gap ++ "'"
        })
        ->Belt.Array.joinWith("\n", x => x)
      writeFileSync(listFile, bufferFrom(lines))
      sh(
        ffmpeg ++
        " -y -loglevel error -f concat -safe 0 -i " ++
        listFile ++ " -b:a 192k " ++ out,
      )
      Js.log("ASSEMBLED -> " ++ out)
    }
  | Some(_) => Js.log("assembly skipped — " ++ Belt.Int.toString(bad.contents) ++ " scene(s) failed")
  | None => ()
  }
  Js.log("RENDER WAVE DONE — " ++ Belt.Int.toString(bad.contents) ++ " scene(s) with failures")
}
main()->ignore
