/* Typed assembly plan — the last untyped stretch of the pipeline.

   The bugs this makes unrepresentable (each cost real review time):
   - the same dialogue line used twice, or a line silently dropped
     (the crayon scene: line15 played 3x, mama's line never appeared);
   - a one-shot sound effect looped to fill a segment
     (the ВЖУХ repeating 7x under Yaga's spell);
   - a clip restarted once per line instead of playing through once;
   - a rendered segment whose duration doesn't match its inputs.

   Nothing here spawns ffmpeg. It validates a plan and EMITS the commands,
   the same way Drakosha_SeedanceBatch emits prompts. */

type lineId = LineId(int)

type visual =
  | Frame(string) // a still, e.g. "f27"
  | Clip(string) // approved footage, played ONCE per segment

type cue =
  | NoCue
  | OneShot(string, float) // plays exactly once — chimes, ВЖУХ, whomp
  | Ambience(string, float) // may loop to fill — clock, stove, scooter

type motion =
  | Still
  | Push // slow zoom in — energy for action beats
  | Pull // slow zoom out — reveals

type segment = {
  segId: string,
  visual: visual,
  lines: array<lineId>, // ordered; each line belongs to exactly one segment
  hold: option<float>, // silent beat length (only when lines is empty)
  word: option<string>, // large on-screen teaching card
  cue: cue,
  motion: motion,
}

type plan = {
  segments: array<segment>,
  scriptLines: array<lineId>, // every spoken line in the episode
}

exception AssemblyError(string)

let idNum = (LineId(n)) => n

/* ---- validation: the compiler catches types, these catch the rest ---- */

let validate = (p: plan): unit => {
  let seen = Js.Dict.empty()
  p.segments->Belt.Array.forEach(s => {
    if Belt.Array.length(s.lines) == 0 {
      switch (s.visual, s.hold) {
      | (Frame(_), None) =>
        raise(AssemblyError(s.segId ++ ": frame segment has neither lines nor a hold duration"))
      | _ => ()
      }
    }
    switch (Belt.Array.length(s.lines), s.hold) {
    | (n, Some(_)) if n > 0 =>
      raise(AssemblyError(s.segId ++ ": a segment may have lines OR a hold, not both"))
    | _ => ()
    }
    s.lines->Belt.Array.forEach(l => {
      let k = Belt.Int.toString(idNum(l))
      switch Js.Dict.get(seen, k) {
      | Some(other) =>
        raise(AssemblyError("line " ++ k ++ " used twice: " ++ other ++ " and " ++ s.segId))
      | None => Js.Dict.set(seen, k, s.segId)
      }
    })
  })
  p.scriptLines->Belt.Array.forEach(l => {
    let k = Belt.Int.toString(idNum(l))
    switch Js.Dict.get(seen, k) {
    | None => raise(AssemblyError("line " ++ k ++ " is in the script but in no segment"))
    | Some(_) => ()
    }
  })
  /* a clip may back only one segment: a second segment would restart it */
  let clips = Js.Dict.empty()
  p.segments->Belt.Array.forEach(s =>
    switch s.visual {
    | Clip(c) =>
      switch Js.Dict.get(clips, c) {
      | Some(other) =>
        raise(AssemblyError("clip " ++ c ++ " reused by " ++ other ++ " and " ++ s.segId))
      | None => Js.Dict.set(clips, c, s.segId)
      }
    | Frame(_) => ()
    }
  )
}

/* ---- emission ---- */

let audioGlob = (l: lineId): string => {
  let n = idNum(l)
  let padded = n < 10 ? "0" ++ Belt.Int.toString(n) : Belt.Int.toString(n)
  "audio/line" ++ padded ++ "_*.mp3"
}

let dubCommand = (s: segment): string => {
  let n = Belt.Array.length(s.lines)
  let inputs =
    s.lines->Belt.Array.map(l => "-i \"$(ls " ++ audioGlob(l) ++ " | head -1)\"")->Js.Array2.joinWith(" ")
  let pads =
    s.lines
    ->Belt.Array.mapWithIndex((i, _) =>
      "[" ++ Belt.Int.toString(i) ++ ":a]apad=pad_dur=0.6[a" ++ Belt.Int.toString(i) ++ "];"
    )
    ->Js.Array2.joinWith("")
  let refs =
    s.lines
    ->Belt.Array.mapWithIndex((i, _) => "[a" ++ Belt.Int.toString(i) ++ "]")
    ->Js.Array2.joinWith("")
  "ffmpeg -y -v error " ++
  inputs ++
  " -filter_complex \"" ++
  pads ++
  refs ++
  "concat=n=" ++
  Belt.Int.toString(n) ++
  ":v=0:a=1\" -ac 1 -ar 44100 seg/" ++
  s.segId ++ "_dub.m4a"
}

let cueMix = (s: segment): string =>
  switch s.cue {
  | NoCue => ""
  | OneShot(name, vol) =>
    " && ffmpeg -y -v error -i seg/" ++
    s.segId ++
    "_raw.mp4 -i sfx/" ++
    name ++
    ".mp3 -filter_complex \"[1:a]volume=" ++
    Js.Float.toString(vol) ++
    ",apad,atrim=0:$D[s];[0:a][s]amix=inputs=2:duration=first[a]\" -map 0:v -map \"[a]\" -c:v copy -c:a aac -ac 1 -ar 44100 seg/" ++
    s.segId ++ ".mp4"
  | Ambience(name, vol) =>
    " && ffmpeg -y -v error -i seg/" ++
    s.segId ++
    "_raw.mp4 -stream_loop -1 -i sfx/" ++
    name ++
    ".mp3 -filter_complex \"[1:a]volume=" ++
    Js.Float.toString(vol) ++
    ",atrim=0:$D,afade=t=in:st=0:d=0.3[s];[0:a][s]amix=inputs=2:duration=first[a]\" -map 0:v -map \"[a]\" -c:v copy -c:a aac -ac 1 -ar 44100 seg/" ++
    s.segId ++ ".mp4"
  }

let motionFilter = (m: motion): string =>
  switch m {
  | Still => ""
  | Push => ",zoompan=z='min(zoom+0.0009,1.18)':d=1:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1280x720:fps=25"
  | Pull => ",zoompan=z='if(lte(zoom,1.0),1.18,max(1.001,zoom-0.0009))':d=1:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1280x720:fps=25"
  }

let renderCommand = (s: segment): string => {
  let dub = switch (Belt.Array.length(s.lines), s.hold) {
  | (0, Some(h)) =>
    "ffmpeg -y -v error -f lavfi -i anullsrc=r=44100:cl=mono -t " ++
    Js.Float.toString(h) ++ " -ac 1 -ar 44100 seg/" ++ s.segId ++ "_dub.m4a"
  | _ => dubCommand(s)
  }
  let dur = "D=$(ffprobe -v error -show_entries format=duration -of csv=p=0 seg/" ++ s.segId ++ "_dub.m4a)"
  let hasCue = switch s.cue {
  | NoCue => false
  | _ => true
  }
  let outName = hasCue ? s.segId ++ "_raw" : s.segId
  let visualPart = switch s.visual {
  | Frame(f) =>
    "ffmpeg -y -v error -loop 1 -i frames/" ++
    f ++
    ".png -i seg/" ++
    s.segId ++
    "_dub.m4a" ++
    (switch s.word {
    | Some(w) =>
      " -i words/" ++
      w ++
      ".png -filter_complex \"[0:v]scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,setsar=1" ++
      motionFilter(s.motion) ++ "[bg];[bg][2:v]overlay=0:0[v]\" -map \"[v]\" -map 1:a"
    | None =>
      " -vf \"scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,setsar=1" ++
      motionFilter(s.motion) ++ "\""
    }) ++
    " -t $D -c:v libx264 -pix_fmt yuv420p -c:a aac -ac 1 -ar 44100 -r 25 seg/" ++
    outName ++ ".mp4"
  | Clip(c) =>
    "ffmpeg -y -v error -i ../seedance_batch/output/" ++
    c ++
    " -i seg/" ++
    s.segId ++
    "_dub.m4a -filter_complex \"[0:v]scale=1280:720:force_original_aspect_ratio=increase,crop=1280:720,setsar=1,tpad=stop_mode=clone:stop_duration=60[v]\" -map \"[v]\" -map 1:a -t $D -c:v libx264 -pix_fmt yuv420p -c:a aac -ac 1 -ar 44100 -r 25 seg/" ++
    outName ++ ".mp4"
  }
  /* duration assertion: the rendered segment must match its dub within 0.35s */
  let assertion =
    " && R=$(ffprobe -v error -show_entries format=duration -of csv=p=0 seg/" ++
    s.segId ++
    ".mp4) && awk -v d=$D -v r=$R -v s=" ++
    s.segId ++
    " 'BEGIN{x=d-r; if(x<0)x=-x; if(x>0.35){print \"DURATION MISMATCH \" s \": dub \" d \" vs render \" r > \"/dev/stderr\"; exit 1}}'"
  dub ++ " && " ++ dur ++ " && " ++ visualPart ++ cueMix(s) ++ assertion
}

let emitScript = (p: plan): string => {
  validate(p)
  let head = "#!/usr/bin/env bash\n# GENERATED by Drakosha_Assembly — do not edit by hand.\nset -euo pipefail\ncd \"$(dirname \"$0\")\"\nmkdir -p seg\n"
  let body = p.segments->Belt.Array.map(renderCommand)->Js.Array2.joinWith("\n")
  let concat =
    "\n: > assembly.txt\n" ++
    p.segments
    ->Belt.Array.map(s => "echo \"file 'seg/" ++ s.segId ++ ".mp4'\" >> assembly.txt")
    ->Js.Array2.joinWith("\n") ++
    "\nffmpeg -y -v error -f concat -safe 0 -i assembly.txt -c:v libx264 -pix_fmt yuv420p -r 25 -c:a aac EP1_assembled.mp4\necho ASSEMBLY OK\n"
  head ++ body ++ concat
}
