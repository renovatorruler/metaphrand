/* THE FOUR OLDS audio play — Mixer v2. Re-mixes a scene's CACHED assets
   (no API calls) on a real timeline instead of a concat queue:
   - overlapping tails: a line may start while an effect decays
   - per-role loudness normalization (dialogue -18 / fx -22 LUFS)
   - beds duck under dialogue via sidechain compression
   - master normalized to -16 LUFS / -1.5 dBTP, ebur128 printed (the gate)
   - overlong generated effects trimmed with a fade
   Run: node src/FourOlds_Mix2.res.mjs <scene.txt> <renderDir> <out.wav> */

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
  Js.Float.fromString(
    Js.String2.trim(shOut(ffprobe ++ " -v error -show_entries format=duration -of csv=p=0 " ++ wav)),
  )

/* same classifiers as the production renderer — the mix must match the
   assets that were actually generated */
let bedRe = %re(
  "/(hum|wind |room tone|walla|murmur|applause climbs|stand quiet|rain|griddle hisses|stove ticks|fan hums|fluorescent)/i"
)
let embeddedRe = %re("/^([A-Z][A-Z .'#-]+?)\s*\((PA|RADIO|TV|ON TV)\):\s*(.+)$/")

type ev = {idx: int, kind: string, dur: float, start: float}

let pad = i => (i < 10 ? "00" : i < 100 ? "0" : "") ++ Belt.Int.toString(i)

let main = async () => {
  let scenePath = Belt.Array.get(argv, 2)->Belt.Option.getWithDefault("")
  let dir = Belt.Array.get(argv, 3)->Belt.Option.getWithDefault("")
  let out = Belt.Array.get(argv, 4)->Belt.Option.getWithDefault("")
  if scenePath == "" || dir == "" || out == "" {
    Js.log("usage: node src/FourOlds_Mix2.res.mjs <scene.txt> <renderDir> <out.wav>")
  } else {
    switch Write.read(Cinema_Backends.Path(scenePath)) {
    | Error(m) => Js.log("REFUSED — " ++ m)
    | Ok(lns) => {
        /* ---- classify each line the way the renderer did, keep only
           lines whose asset exists ---- */
        let entries = [] /* (idx, kind) kind: dlg | sfx | bed */
        let bedCount = ref(0)
        let actionIdx = ref(0)
        lns->Belt.Array.forEachWithIndex((i, l) =>
          switch l {
          | Write.Dialogue(_) => Js.Array2.push(entries, (i, "dlg"))->ignore
          | Write.Action(t) =>
            if Js.Re.test_(embeddedRe, t) {
              Js.Array2.push(entries, (i, "dlg"))->ignore
            } else {
              let isBed =
                bedCount.contents < 2 && actionIdx.contents < 3 && Js.Re.test_(bedRe, t)
              actionIdx := actionIdx.contents + 1
              if isBed {
                bedCount := bedCount.contents + 1
              }
              Js.Array2.push(entries, (i, isBed ? "bed" : "sfx"))->ignore
            }
          }
        )
        let present = entries->Belt.Array.keep(((i, _)) => existsSync(dir ++ "/" ++ pad(i) ++ ".wav"))

        /* ---- per-role loudness normalization into cached copies ---- */
        present->Belt.Array.forEach(((i, k)) => {
          let src = dir ++ "/" ++ pad(i) ++ ".wav"
          let dst = dir ++ "/" ++ pad(i) ++ "_n.wav"
          if !existsSync(dst) {
            let target = k == "dlg" ? "-18" : k == "bed" ? "-27" : "-22"
            /* overlong generated effects get trimmed with a fade; beds stay full */
            let trim = k == "sfx" ? " -t 6.5 -af \"loudnorm=I=" ++ target ++ ":LRA=11:TP=-2,afade=t=out:st=6.0:d=0.5\"" : " -af \"loudnorm=I=" ++ target ++ ":LRA=11:TP=-2\""
            sh(ffmpeg ++ " -y -loglevel error -i " ++ src ++ trim ++ " -ar 44100 -ac 2 " ++ dst)
          }
        })

        /* ---- timeline ---- */
        let evs = []
        let t = ref(1.2) /* the bed establishes before the first event */
        let prevKind = ref("")
        let prevStart = ref(0.0)
        let prevDur = ref(0.0)
        present->Belt.Array.forEach(((i, k)) =>
          if k != "bed" {
            let d = durationOf(dir ++ "/" ++ pad(i) ++ "_n.wav")
            let start = switch (prevKind.contents, k) {
            | ("", _) => t.contents
            | ("dlg", "dlg") => prevStart.contents +. prevDur.contents +. 0.18
            | ("dlg", "sfx") => prevStart.contents +. prevDur.contents +. 0.35
            | ("sfx", _) =>
              /* ride in on the effect's tail: start when 65% of it has played */
              prevStart.contents +. prevDur.contents *. 0.65
            | (_, _) => prevStart.contents +. prevDur.contents +. 0.3
            }
            Js.Array2.push(evs, {idx: i, kind: k, dur: d, start})->ignore
            prevKind := k
            prevStart := start
            prevDur := d
          }
        )
        let total =
          evs->Belt.Array.reduce(0.0, (acc, e) =>
            e.start +. e.dur > acc ? e.start +. e.dur : acc
          ) +. 1.8
        let beds = present->Belt.Array.keep(((_, k)) => k == "bed")

        /* ---- one filter graph: events delayed + mixed -> dialogue bus keys
           the bed ducking -> master loudnorm ---- */
        let inputs = ref("")
        let n = ref(0)
        let evLabels = []
        let dlgLabels = []
        let filters = []
        evs->Belt.Array.forEach(e => {
          inputs := inputs.contents ++ " -i " ++ dir ++ "/" ++ pad(e.idx) ++ "_n.wav"
          let ms = Belt.Int.toString(Belt.Float.toInt(e.start *. 1000.0))
          let lbl = "e" ++ Belt.Int.toString(n.contents)
          Js.Array2.push(
            filters,
            `[${Belt.Int.toString(n.contents)}:a]adelay=${ms}|${ms}[${lbl}]`,
          )->ignore
          Js.Array2.push(evLabels, "[" ++ lbl ++ "]")->ignore
          if e.kind == "dlg" {
            Js.Array2.push(dlgLabels, "[" ++ lbl ++ "]")->ignore
          }
          n := n.contents + 1
        })
        beds->Belt.Array.forEach(((i, _)) => {
          inputs :=
            inputs.contents ++ " -stream_loop -1 -i " ++ dir ++ "/" ++ pad(i) ++ "_n.wav"
          n := n.contents + 1
        })
        let nEv = Belt.Array.length(evs)
        let nDlg = Belt.Array.length(dlgLabels)
        let totalS = Js.Float.toFixedWithPrecision(total, ~digits=2)
        Js.Array2.push(
          filters,
          evLabels->Belt.Array.joinWith("", x => x) ++
          `amix=inputs=${Belt.Int.toString(nEv)}:duration=longest:normalize=0[events]`,
        )->ignore
        ignore(nDlg)
        let graph = if Belt.Array.length(beds) > 0 {
          let bedIdxs = Belt.Array.makeBy(Belt.Array.length(beds), b => nEv + b)
          let bedMix = if Belt.Array.length(beds) == 2 {
            let b0 = Belt.Int.toString(Belt.Array.getExn(bedIdxs, 0))
            let b1 = Belt.Int.toString(Belt.Array.getExn(bedIdxs, 1))
            `[${b0}:a]volume=0.9[w0];[${b1}:a]volume=0.7[w1];[w0][w1]amix=inputs=2:duration=longest:normalize=0,atrim=0:${totalS}[bedraw]`
          } else {
            let b0 = Belt.Int.toString(Belt.Array.getExn(bedIdxs, 0))
            `[${b0}:a]atrim=0:${totalS}[bedraw]`
          }
          Js.Array2.push(filters, bedMix)->ignore
          /* split the events bus: one copy to the master, one keys the bed
             ducking — never re-consume raw inputs (that leaves pads unwired) */
          Js.Array2.push(filters, `[events]asplit=2[evmain][evkey]`)->ignore
          Js.Array2.push(
            filters,
            `[bedraw][evkey]sidechaincompress=threshold=0.02:ratio=6:attack=120:release=600:makeup=1[bed]`,
          )->ignore
          Js.Array2.push(
            filters,
            `[evmain][bed]amix=inputs=2:duration=first:normalize=0,loudnorm=I=-16:LRA=11:TP=-1.5[out]`,
          )->ignore
          filters->Belt.Array.joinWith(";", x => x)
        } else {
          Js.Array2.push(filters, `[events]loudnorm=I=-16:LRA=11:TP=-1.5[out]`)->ignore
          filters->Belt.Array.joinWith(";", x => x)
        }
        sh(
          ffmpeg ++
          " -y -loglevel error" ++
          inputs.contents ++
          " -filter_complex \"" ++
          graph ++ "\" -map \"[out]\" -t " ++ totalS ++ " -ar 44100 -ac 2 " ++ out,
        )
        /* ---- the gate: measure what we made ---- */
        let meter = shOut(
          ffmpeg ++ " -i " ++ out ++ " -af ebur128 -f null - 2>&1 | tail -12",
        )
        Js.log("MIX2 " ++ out ++ " — " ++ Belt.Int.toString(nEv) ++ " events, " ++ Belt.Int.toString(Belt.Array.length(beds)) ++ " bed(s), " ++ totalS ++ "s")
        Js.log(meter)
      }
    }
  }
}
main()->ignore
