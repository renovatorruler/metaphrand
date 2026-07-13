/* Mix3 — the DME stem mixer (see AUDIO_MIX.md). Reads a cue-annotated scene
   and the render dir's per-line wavs, builds four stems as separate ffmpeg
   passes — DIALOGUE (leveled, perspective-futzed, per-space reverb), ATMOS
   (continuous beds, looped to span, crossfaded), SPOT (synced hard fx +
   transitions), MUSIC — then combines them with the atmos/music buses
   sidechain-ducked under the dialogue, into a −16 LUFS master.
   Run: node src/Mix3.res.mjs <scene.txt> <renderDir> <out.wav> */

@val @scope("process") external argv: array<string> = "argv"
@module("fs") external existsSync: string => bool = "existsSync"
@module("child_process") external execSync: (string, 'a) => 'b = "execSync"

let ffmpeg = "/opt/homebrew/bin/ffmpeg"
let ffprobe = "/opt/homebrew/bin/ffprobe"

let shOut = (cmd: string): string => {
  let opts = Js.Dict.empty()
  Js.Dict.set(opts, "stdio", Obj.magic(["pipe", "pipe", "pipe"]))
  Js.Dict.set(opts, "encoding", Obj.magic("utf8"))
  Obj.magic(execSync(cmd, opts))
}
let sh = (cmd: string): unit => shOut(cmd)->ignore
let durationOf = (wav: string): float =>
  switch Belt.Float.fromString(
    Js.String2.trim(shOut(ffprobe ++ " -v error -show_entries format=duration -of csv=p=0 " ++ wav)),
  ) {
  | Some(d) => d
  | None => 0.0
  }
let pad = i => (i < 10 ? "00" : i < 100 ? "0" : "") ++ Belt.Int.toString(i)

/* perspective futz — how a voice sits relative to the mic. Close voices get
   a BROADCAST CHAIN (tight compression + presence) so the desk sounds like
   television, not a podcast mic. */
let futz = (p: Cue.persp, space: string): string =>
  switch p {
  | Cue.Close =>
    space == "diner"
      ? "highpass=f=90" /* the diner human is a real room voice, not on-air */
      : "highpass=f=100,acompressor=threshold=-19dB:ratio=3.5:attack=6:release=140:makeup=2,equalizer=f=3200:t=q:w=1.2:g=2.5,alimiter=limit=0.95"
  | Cue.Off => "lowpass=f=4200,volume=0.72"
  | Cue.Radio | Cue.Pa | Cue.Tv =>
    space == "diner"
      ? "highpass=f=440,lowpass=f=2600,acompressor=threshold=-20dB:ratio=6,volume=1.05" /* the tinny finale */
      : "highpass=f=360,lowpass=f=3400,acompressor=threshold=-18dB:ratio=4,volume=1.15"
  | Cue.Neutral => "anull"
  }

/* per-space reverb (aecho approximation until we add convolution IRs) */
let reverb = (space: string): string =>
  switch space {
  | "arena" => "aecho=0.8:0.85:60|130:0.4|0.28"
  | "cargobay" => "aecho=0.8:0.82:38|76:0.35|0.24"
  | "hearing" => "aecho=0.9:0.9:20:0.14"
  | "studio" | "diner" => "anull"
  | _ => "aecho=0.9:0.9:28:0.16"
  }

type placed = {idx: int, start: float, dur: float, space: string, persp: Cue.persp}

let main = () => {
  let scenePath = Belt.Array.get(argv, 2)->Belt.Option.getWithDefault("")
  let renderDir = Belt.Array.get(argv, 3)->Belt.Option.getWithDefault("")
  let out = Belt.Array.get(argv, 4)->Belt.Option.getWithDefault("")
  if scenePath == "" || renderDir == "" || out == "" {
    Js.log("usage: node src/Mix3.res.mjs <scene.txt> <renderDir> <out.wav>")
  } else {
    switch Write.read(Cinema_Backends.Path(scenePath)) {
    | Error(m) => Js.log("REFUSED — " ++ m)
    | Ok(lns) => {
        let cues = Cue.parse(lns)
        let wavOf = c => renderDir ++ "/" ++ pad(Cue.idxOf(c)) ++ ".wav"
        /* ---- timeline ---- */
        let dlgs = []
        let spots = []
        let beds = []
        let musics = []
        let clock = ref(0.6)
        cues->Belt.Array.forEach(c => {
          let w = wavOf(c)
          let ok = existsSync(w)
          switch c {
          | Cue.Dlg({idx, space, persp}) =>
            if ok {
              let d = durationOf(w)
              Js.Array2.push(dlgs, {idx, start: clock.contents, dur: d, space, persp})->ignore
              clock := clock.contents +. d +. 0.22
            }
          | Cue.Spot({idx, space}) =>
            if ok {
              let d = durationOf(w)
              Js.Array2.push(spots, {idx, start: clock.contents, dur: d, space, persp: Cue.Neutral})->ignore
              clock := clock.contents +. (d < 0.5 ? d : 0.5)
            }
          | Cue.Transition({idx, space}) =>
            if ok {
              let d = durationOf(w)
              /* the static STRADDLES the seam: it starts while the outgoing
                 bed is still up and the next segment begins under its tail */
              let s = clock.contents -. 0.35 < 0.0 ? 0.0 : clock.contents -. 0.35
              Js.Array2.push(spots, {idx, start: s, dur: d, space, persp: Cue.Neutral})->ignore
              clock := clock.contents +. (d < 0.55 ? d : 0.55)
            }
          | Cue.Bed({idx, space}) =>
            if ok {
              /* pre-roll the bed under the transition so the rooms overlap */
              let s = clock.contents -. 0.8 < 0.0 ? 0.0 : clock.contents -. 0.8
              Js.Array2.push(beds, {idx, start: s, dur: 0.0, space, persp: Cue.Neutral})->ignore
            }
          | Cue.Music({idx}) =>
            if ok {
              let d = durationOf(w)
              Js.Array2.push(musics, {idx, start: clock.contents, dur: d, space: "", persp: Cue.Neutral})->ignore
              clock := clock.contents +. d
            }
          }
        })
        let total = clock.contents +. 1.5
        let totalS = Js.Float.toFixedWithPrecision(total, ~digits=2)

        /* ---- DIALOGUE stem ---- */
        let dstem = renderDir ++ "/stem_dialogue.wav"
        if Belt.Array.length(dlgs) > 0 {
          let ins = dlgs->Belt.Array.map(d => " -i " ++ renderDir ++ "/" ++ pad(d.idx) ++ ".wav")->Belt.Array.joinWith("", x => x)
          let fs = dlgs->Belt.Array.mapWithIndex((k, d) => {
            let ms = Belt.Int.toString(Belt.Float.toInt(d.start *. 1000.0))
            `[${Belt.Int.toString(k)}:a]${futz(d.persp, d.space)},${reverb(d.space)},adelay=${ms}|${ms}[d${Belt.Int.toString(k)}]`
          })
          let labels = dlgs->Belt.Array.mapWithIndex((k, _) => "[d" ++ Belt.Int.toString(k) ++ "]")->Belt.Array.joinWith("", x => x)
          let graph = Belt.Array.concat(fs, [labels ++ `amix=inputs=${Belt.Int.toString(Belt.Array.length(dlgs))}:duration=longest:normalize=0,loudnorm=I=-18:LRA=11:TP=-2[out]`])->Belt.Array.joinWith(";", x => x)
          sh(ffmpeg ++ " -y -loglevel error" ++ ins ++ " -filter_complex \"" ++ graph ++ "\" -map \"[out]\" -t " ++ totalS ++ " -ar 44100 -ac 2 " ++ dstem)
        }

        /* ---- ATMOS stem: beds looped to span, crossfaded, low ---- */
        let astem = renderDir ++ "/stem_atmos.wav"
        let nBeds = Belt.Array.length(beds)
        if nBeds > 0 {
          let ins = beds->Belt.Array.map(b => " -stream_loop -1 -i " ++ renderDir ++ "/" ++ pad(b.idx) ++ ".wav")->Belt.Array.joinWith("", x => x)
          let fs = beds->Belt.Array.mapWithIndex((k, b) => {
            let endT = k + 1 < nBeds ? Belt.Array.getExn(beds, k + 1).start : total
            let span = endT -. b.start +. 1.0 < 1.4 ? 1.4 : endT -. b.start +. 1.0 /* generous overlap: true crossfade through the static */
            let spanS = Js.Float.toFixedWithPrecision(span, ~digits=2)
            let fo = Js.Float.toFixedWithPrecision(span -. 1.0, ~digits=2)
            let ms = Belt.Int.toString(Belt.Float.toInt(b.start *. 1000.0))
            `[${Belt.Int.toString(k)}:a]atrim=0:${spanS},${reverb(b.space)},afade=t=in:d=0.8,afade=t=out:st=${fo}:d=1.0,volume=0.5,adelay=${ms}|${ms}[b${Belt.Int.toString(k)}]`
          })
          let labels = beds->Belt.Array.mapWithIndex((k, _) => "[b" ++ Belt.Int.toString(k) ++ "]")->Belt.Array.joinWith("", x => x)
          let graph = Belt.Array.concat(fs, [labels ++ `amix=inputs=${Belt.Int.toString(nBeds)}:duration=longest:normalize=0[out]`])->Belt.Array.joinWith(";", x => x)
          sh(ffmpeg ++ " -y -loglevel error" ++ ins ++ " -filter_complex \"" ++ graph ++ "\" -map \"[out]\" -t " ++ totalS ++ " -ar 44100 -ac 2 " ++ astem)
        }

        /* ---- SPOT stem: hard fx + transitions ---- */
        let sstem = renderDir ++ "/stem_spot.wav"
        let nSpots = Belt.Array.length(spots)
        if nSpots > 0 {
          let ins = spots->Belt.Array.map(s => " -i " ++ renderDir ++ "/" ++ pad(s.idx) ++ ".wav")->Belt.Array.joinWith("", x => x)
          let fs = spots->Belt.Array.mapWithIndex((k, s) => {
            let ms = Belt.Int.toString(Belt.Float.toInt(s.start *. 1000.0))
            `[${Belt.Int.toString(k)}:a]${reverb(s.space)},volume=0.85,adelay=${ms}|${ms}[s${Belt.Int.toString(k)}]`
          })
          let labels = spots->Belt.Array.mapWithIndex((k, _) => "[s" ++ Belt.Int.toString(k) ++ "]")->Belt.Array.joinWith("", x => x)
          let graph = Belt.Array.concat(fs, [labels ++ `amix=inputs=${Belt.Int.toString(nSpots)}:duration=longest:normalize=0[out]`])->Belt.Array.joinWith(";", x => x)
          sh(ffmpeg ++ " -y -loglevel error" ++ ins ++ " -filter_complex \"" ++ graph ++ "\" -map \"[out]\" -t " ++ totalS ++ " -ar 44100 -ac 2 " ++ sstem)
        }

        /* ---- MUSIC stem ---- */
        let mstem = renderDir ++ "/stem_music.wav"
        let nMus = Belt.Array.length(musics)
        if nMus > 0 {
          let ins = musics->Belt.Array.map(m => " -i " ++ renderDir ++ "/" ++ pad(m.idx) ++ ".wav")->Belt.Array.joinWith("", x => x)
          let fs = musics->Belt.Array.mapWithIndex((k, m) => {
            let ms = Belt.Int.toString(Belt.Float.toInt(m.start *. 1000.0))
            `[${Belt.Int.toString(k)}:a]volume=0.8,adelay=${ms}|${ms}[m${Belt.Int.toString(k)}]`
          })
          let labels = musics->Belt.Array.mapWithIndex((k, _) => "[m" ++ Belt.Int.toString(k) ++ "]")->Belt.Array.joinWith("", x => x)
          let graph = Belt.Array.concat(fs, [labels ++ `amix=inputs=${Belt.Int.toString(nMus)}:duration=longest:normalize=0[out]`])->Belt.Array.joinWith(";", x => x)
          sh(ffmpeg ++ " -y -loglevel error" ++ ins ++ " -filter_complex \"" ++ graph ++ "\" -map \"[out]\" -t " ++ totalS ++ " -ar 44100 -ac 2 " ++ mstem)
        }

        /* ---- COMBINE: duck atmos + music under dialogue, sum, master ---- */
        let haveD = existsSync(dstem)
        let haveA = existsSync(astem)
        let haveS = existsSync(sstem)
        let haveM = existsSync(mstem)
        let ins = ref("")
        let idxOfStem = Js.Dict.empty()
        let n = ref(0)
        let add = (path, key) => {
          if existsSync(path) {
            ins := ins.contents ++ " -i " ++ path
            Js.Dict.set(idxOfStem, key, Belt.Int.toString(n.contents))
            n := n.contents + 1
          }
        }
        add(dstem, "d")
        add(astem, "a")
        add(sstem, "s")
        add(mstem, "m")
        let g = []
        let mixLabels = []
        if haveD {
          let di = Js.Dict.get(idxOfStem, "d")->Belt.Option.getExn
          /* split the dialogue for the master + one duck key per ducked stem */
          let nKeys = (haveA ? 1 : 0) + (haveM ? 1 : 0)
          if nKeys > 0 {
            Js.Array2.push(g, `[${di}:a]asplit=${Belt.Int.toString(nKeys + 1)}[dmain]${haveA ? "[dka]" : ""}${haveM ? "[dkm]" : ""}`)->ignore
          } else {
            Js.Array2.push(g, `[${di}:a]anull[dmain]`)->ignore
          }
          Js.Array2.push(mixLabels, "[dmain]")->ignore
        }
        if haveA {
          let ai = Js.Dict.get(idxOfStem, "a")->Belt.Option.getExn
          if haveD {
            Js.Array2.push(g, `[${ai}:a][dka]sidechaincompress=threshold=0.04:ratio=8:attack=60:release=450:makeup=1[aduck]`)->ignore
            Js.Array2.push(mixLabels, "[aduck]")->ignore
          } else {
            Js.Array2.push(mixLabels, "[" ++ ai ++ ":a]")->ignore
          }
        }
        if haveS {
          let si = Js.Dict.get(idxOfStem, "s")->Belt.Option.getExn
          Js.Array2.push(mixLabels, "[" ++ si ++ ":a]")->ignore
        }
        if haveM {
          let mi = Js.Dict.get(idxOfStem, "m")->Belt.Option.getExn
          if haveD {
            Js.Array2.push(g, `[${mi}:a][dkm]sidechaincompress=threshold=0.04:ratio=10:attack=40:release=600:makeup=1[mduck]`)->ignore
            Js.Array2.push(mixLabels, "[mduck]")->ignore
          } else {
            Js.Array2.push(mixLabels, "[" ++ mi ++ ":a]")->ignore
          }
        }
        let nMix = Belt.Array.length(mixLabels)
        Js.Array2.push(
          g,
          mixLabels->Belt.Array.joinWith("", x => x) ++
          `amix=inputs=${Belt.Int.toString(nMix)}:duration=longest:normalize=0,loudnorm=I=-16:LRA=11:TP=-1.5,alimiter=limit=0.97[out]`,
        )->ignore
        sh(ffmpeg ++ " -y -loglevel error" ++ ins.contents ++ " -filter_complex \"" ++ g->Belt.Array.joinWith(";", x => x) ++ "\" -map \"[out]\" -ar 44100 -ac 2 " ++ out)
        Js.log(
          "MIX3 " ++
          out ++
          " — dlg:" ++ Belt.Int.toString(Belt.Array.length(dlgs)) ++
          " atmos:" ++ Belt.Int.toString(nBeds) ++
          " spot:" ++ Belt.Int.toString(nSpots) ++
          " music:" ++ Belt.Int.toString(nMus) ++
          " / " ++ totalS ++ "s",
        )
      }
    }
  }
}
main()
