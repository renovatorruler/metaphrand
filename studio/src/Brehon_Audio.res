/* BREHON walkthrough — narration render through the performance law.
   Perform.run tags the 19 narrator lines (eleven_v3 vocabulary, director's
   register notes) -> Perf.load re-runs words-are-law -> Perf.tts per line
   (Eric, US) -> measured durations to brehon_audio_cuts.json -> one preview
   MP3 (beats + breaths, -16 LUFS).
   Run: CLAUDE_STUDIO_BUDGET=3 node src/Brehon_Audio.res.mjs */

@module("fs") external mkdirSync: (string, 'a) => unit = "mkdirSync"
@module("fs") external writeFileSync: (string, 'a) => unit = "writeFileSync"
@val @scope("Buffer") external bufferFrom: 'a => 'b = "from"
@module("child_process") external execSync: (string, 'a) => 'b = "execSync"

let base = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/brehon"
let sourcePath = base ++ "/audio/walkthrough.vo.txt"
let perfPath = base ++ "/audio/walkthrough.voperf.json"
let beats = base ++ "/audio/beats/"
let preview = base ++ "/BREHON-NARRATION_2026-07-15_1610_v1.mp3"
let eric = "cjVigY5qzO86Huf0OWal"

/* line index -> beat id (the cut sheet key; b0 spans three lines, b3/b7/b12 two) */
let ids = [
  "b0a_wiki", "b0b_rart", "b0c_whatif", "b1_record", "b2_signin", "b3a_game",
  "b3b_rule", "b4_jaws", "b5_rate", "b6_reveal", "b7a_mark", "b7b_wand",
  "b8_thread", "b9_demand", "b10_bond", "b11_transcript", "b12a_ruling",
  "b12b_lineage", "b13_return",
]

let direction =
  "Single-narrator product walkthrough (documentary explainer, US English, warm and dry). " ++
  "These are long paragraph lines: use 2 to 4 tags per line, placed where the register turns, " ++
  "never stacked. Registers by line number: " ++
  "0 storyteller, dry - the absurdity does the work; " ++
  "1 level, quietly damning; " ++
  "2 the pivot - measured hope, ending on a real question; " ++
  "3 quiet, letting the strangeness land; " ++
  "4 unceremonious, moving along; " ++
  "5 light; 6 engaged, precise on rule two; " ++
  "7 amused at the wordplay, then measured on the ruling; " ++
  "8 mischievous setup, then hand the wheel to the listener; " ++
  "9 calm verdict, then a door opening; " ++
  "10 warm; 11 light and crisp on the gesture; " ++
  "12 at home now, a hook at the end; " ++
  "13 practical and exact; 14 serious, plain; " ++
  "15 tension held low; " ++
  "16 grave, then the mechanism explained with quiet relish; " ++
  "17 quiet pride, plain - history, not a sales line; " ++
  "18 plain warmth, end flat with no reach."

let sh = (cmd: string): string => {
  let opts = Js.Dict.empty()
  Js.Dict.set(opts, "encoding", Obj.magic("utf8"))
  execSync(cmd, opts)
}

let dur = (path: string): float =>
  Js.Float.fromString(
    Js.String2.trim(
      sh("/opt/homebrew/bin/ffprobe -v error -show_entries format=duration -of csv=p=0 \"" ++ path ++ "\""),
    ),
  )

let main = async () => {
  mkdirSync(beats, {"recursive": true})

  /* 1 - the VO performance pass; idempotent — a valid performance is reused */
  let prepared = switch Vo.load(~sourcePath, ~perfPath) {
  | Ok(l) => {
      Js.log("performance reused (" ++ Belt.Int.toString(Belt.Array.length(l)) ++ " lines, gate green)")
      Ok(l)
    }
  | Error(_) =>
    switch await Vo.prepare(~sourcePath, ~outPerf=perfPath, ~direction) {
    | Error(m) => Error(m)
    | Ok(n) => {
        Js.log("performed " ++ Belt.Int.toString(n) ++ " lines")
        Vo.load(~sourcePath, ~perfPath)
      }
    }
  }
  switch prepared {
  | Error(m) => Js.log("VO GATE — " ++ m)
  | Ok(_) => {
      switch prepared {
      | Error(m) => Js.log("GATE — " ++ m)
      | Ok(lines) => {
          /* 3 - render each line, cached by sidecar */
          let cuts = []
          let ok = ref(0)
          let nL = Belt.Array.length(lines)
          let rec go = async i =>
            if i < nL {
              let p = Belt.Array.getExn(lines, i)
              let idx = Vo.indexOf(p)
              let id = ids->Belt.Array.get(idx)->Belt.Option.getWithDefault("x" ++ Belt.Int.toString(idx))
              let pad = idx < 10 ? "0" ++ Belt.Int.toString(idx) : Belt.Int.toString(idx)
              let mp3 = beats ++ pad ++ "_" ++ id ++ ".mp3"
              /* pronunciation, user-canon: Brehon -> bree-hun (Brehons ->
                 bree-huns falls out of the prefix). The account dictionary
                 rides the request AND the respell applies client-side, so
                 the vowel holds even where v3 ignores dictionaries. */
              let done_ = await Vo.tts(
                p,
                ~voiceId=eric,
                ~outMp3=mp3,
                ~say=[("Brehon", "bree-hun"), ("brehon", "bree-hun")],
                ~dict=[("oy18LLir2PYwHfqcof3S", "l8ZdGgOD4LSwJ81dSaMh")],
              )
              if done_ {
                ok := ok.contents + 1
                let d = dur(mp3)
                Js.Array2.push(cuts, (id, mp3, d))->ignore
                Js.log("OK   " ++ id ++ "  " ++ Js.Float.toFixedWithPrecision(d, ~digits=1) ++ "s")
              } else {
                Js.log("TTS FAIL " ++ id)
              }
              await go(i + 1)
            }
          await go(0)

          if ok.contents == nL {
            /* 4 - measured cut sheet for the video re-time */
            let sheet =
              cuts
              ->Belt.Array.map(((id, mp3, d)) =>
                `{"beat":"${id}","mp3":${Js.Json.stringify(Js.Json.string(mp3))},"sec":${Js.Float.toString(d)}}`
              )
              ->Belt.Array.joinWith(",\n  ", x => x)
            writeFileSync(base ++ "/brehon_audio_cuts.json", bufferFrom("[\n  " ++ sheet ++ "\n]"))

            /* 5 - preview: beats + 0.55s breaths, loudnormed, one MP3 */
            let ins = cuts->Belt.Array.joinWith("", ((_, mp3, _)) => " -i \"" ++ mp3 ++ "\"")
            let silIdx = Belt.Int.toString(nL)
            let split = "[" ++ silIdx ++ ":a]asplit=" ++ Belt.Int.toString(nL - 1) ++
              Belt.Array.makeBy(nL - 1, k => "[s" ++ Belt.Int.toString(k) ++ "]")->Belt.Array.joinWith("", x => x) ++ ";"
            let chain =
              Belt.Array.makeBy(nL, k => k)
              ->Belt.Array.map(k =>
                "[" ++ Belt.Int.toString(k) ++ ":a]" ++ (k < nL - 1 ? "[s" ++ Belt.Int.toString(k) ++ "]" : "")
              )
              ->Belt.Array.joinWith("", x => x)
            let filter =
              split ++
              chain ++
              "concat=n=" ++ Belt.Int.toString(2 * nL - 1) ++ ":v=0:a=1,loudnorm=I=-16:LRA=11:TP=-1.5[out]"
            let _ = sh(
              "/opt/homebrew/bin/ffmpeg -y -loglevel error" ++
              ins ++
              " -f lavfi -t 0.55 -i anullsrc=r=44100:cl=mono -filter_complex \"" ++
              filter ++ "\" -map \"[out]\" -b:a 192k \"" ++ preview ++ "\"",
            )
            let total = cuts->Belt.Array.reduce(0.0, (a, (_, _, d)) => a +. d)
            Js.log("PREVIEW -> " ++ preview)
            Js.log("narration total " ++ Js.Float.toFixedWithPrecision(total, ~digits=0) ++ "s + breaths")
          } else {
            Js.log("INCOMPLETE — " ++ Belt.Int.toString(ok.contents) ++ "/" ++ Belt.Int.toString(nL) ++ " rendered; no preview built")
          }
        }
      }
    }
  }
}
main()->ignore
