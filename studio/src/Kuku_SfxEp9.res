/* कुकु और अक्षर — Episode 9 main-story sound effects.

   Reads finale/manifests/ep9_sfx_cues.v1.json (cues anchored to EDL v4 beat ids plus
   an offset, never to absolute timecode, so a retime carries them with their picture),
   generates each cue through ElevenLabs /v1/sound-generation, levels events to
   −20 LUFS, and writes finale/manifests/ep9_sfx_timeline.v1.json with each cue
   resolved to an absolute start second for the mixer.

   Same disciplines as Kuku_SfxEp7: skip-if-exists so a rerun costs nothing, DRY
   pricing before spending, and every failure reported rather than swallowed.

   Run from studio/:  node src/Kuku_SfxEp9.res.mjs        (generate)
                      DRY=1 node src/Kuku_SfxEp9.res.mjs  (price only) */

open Cinema_Backends

@val @scope(("process", "env")) external envDry: option<string> = "DRY"

let root = "../stories/kuku/ep9prod/finale"
let sfxDir = root ++ "/audio/sfx"

exception SfxError(string)
let fail = m => raise(SfxError(m))

let obj = (j, w) =>
  switch Js.Json.decodeObject(j) {
  | Some(o) => o
  | None => fail(w ++ " is not an object")
  }
let get = (o, k, w) =>
  switch Js.Dict.get(o, k) {
  | Some(v) => v
  | None => fail(w ++ " missing " ++ k)
  }
let str = (o, k, w) =>
  switch Js.Json.decodeString(get(o, k, w)) {
  | Some(s) => s
  | None => fail(w ++ "." ++ k ++ " is not a string")
  }
let num = (o, k, w) =>
  switch Js.Json.decodeNumber(get(o, k, w)) {
  | Some(n) => n
  | None => fail(w ++ "." ++ k ++ " is not a number")
  }
let arr = (o, k, w) =>
  switch Js.Json.decodeArray(get(o, k, w)) {
  | Some(a) => a
  | None => fail(w ++ "." ++ k ++ " is not an array")
  }

/* a cue counts as already made only if the file is real, not a truncated stub */
let present = (p: path, minBytes: float): bool =>
  exists(p) && fileSizeMb(p) *. 1.0e6 > minBytes

let parseTc = tc =>
  switch Js.String2.split(tc, ":") {
  | [m, s] =>
    switch (Belt.Int.fromString(m), Belt.Int.fromString(s)) {
    | (Some(mm), Some(ss)) => mm * 60 + ss
    | _ => fail("bad timecode " ++ tc)
    }
  | _ => fail("bad timecode " ++ tc)
  }

type cue = {
  id: string,
  beat: string,
  offset: float,
  seconds: float,
  gain: float,
  prompt: string,
}

let main = async () => {
  let dry = switch envDry {
  | Some("1") => true
  | _ => false
  }

  /* beat id -> absolute start second, from the shipped v4 EDL */
  let edl = obj(Js.Json.parseExn(readText(Path(root ++ "/manifests/ep9_finale_animatic_edl.v4.json"))), "EDL")
  let starts: Js.Dict.t<int> = Js.Dict.empty()
  arr(edl, "beats", "EDL")->Belt.Array.forEach(bj => {
    let b = obj(bj, "beat")
    Js.Dict.set(starts, str(b, "id", "beat"), parseTc(str(b, "start", "beat")))
  })

  let manifest = obj(Js.Json.parseExn(readText(Path(root ++ "/manifests/ep9_sfx_cues.v1.json"))), "cues manifest")
  let influence = num(obj(get(manifest, "policy", "manifest"), "policy"), "influence", "policy")
  let cues = arr(manifest, "cues", "manifest")->Belt.Array.map(cj => {
    let c = obj(cj, "cue")
    {
      id: str(c, "id", "cue"),
      beat: str(c, "beat", "cue"),
      offset: num(c, "offset", "cue"),
      seconds: num(c, "seconds", "cue"),
      gain: num(c, "gain", "cue"),
      prompt: str(c, "prompt", "cue"),
    }
  })

  /* every cue must anchor to a beat that actually exists, checked before spending */
  cues->Belt.Array.forEach(c =>
    switch Js.Dict.get(starts, c.beat) {
    | Some(_) => ()
    | None => fail(c.id ++ " anchors to unknown beat " ++ c.beat)
    }
  )

  ensureDirPath(Path(sfxDir))
  Js.log(
    "EP9 SFX — " ++ Belt.Int.toString(Belt.Array.length(cues)) ++ " cues, " ++
    Js.Float.toFixedWithPrecision(
      cues->Belt.Array.reduce(0.0, (a, c) => a +. c.seconds), ~digits=1,
    ) ++ "s of effect audio",
  )

  let made = ref(0)
  let skipped = ref(0)
  let failed = ref(0)

  for i in 0 to Belt.Array.length(cues) - 1 {
    switch Belt.Array.get(cues, i) {
    | None => ()
    | Some(c) => {
        let p = Path(sfxDir ++ "/" ++ c.id ++ ".mp3")
        if present(p, 2000.0) {
          skipped := skipped.contents + 1
        } else if dry {
          Js.log("  would make " ++ c.id ++ " (" ++ Js.Float.toString(c.seconds) ++ "s)")
        } else {
          switch await soundEffect(~prompt=Prompt(c.prompt), ~seconds=c.seconds, ~influence) {
          | b => {
              let _ = writeBytes(p, b)
              made := made.contents + 1
              Js.log("  sfx OK " ++ c.id)
            }
          | exception BackendError(m) => {
              failed := failed.contents + 1
              Js.log("  sfx FAIL " ++ c.id ++ ": " ++ m)
            }
          }
        }
      }
    }
  }

  if !dry {
    /* level every new effect to −20 LUFS; the marker makes this idempotent */
    let levelled = ref(0)
    cues->Belt.Array.forEach(c => {
      let src = sfxDir ++ "/" ++ c.id ++ ".mp3"
      let marker = Path(sfxDir ++ "/." ++ c.id ++ ".leveled")
      if exists(Path(src)) && !exists(marker) {
        let tmp = sfxDir ++ "/." ++ c.id ++ ".tmp.mp3"
        ffmpeg([
          "-y", "-v", "error", "-i", src,
          "-af", "loudnorm=I=-20:TP=-1.5:LRA=11",
          "-c:a", "libmp3lame", "-q:a", "3", tmp,
        ])
        copyFile(Path(tmp), Path(src))
        removeFile(Path(tmp))
        writeText(marker, "-20 LUFS")
        levelled := levelled.contents + 1
      }
    })
    Js.log("levelled " ++ Belt.Int.toString(levelled.contents) ++ " effects to -20 LUFS")

    /* resolve every cue to an absolute start second for the mixer */
    let entries = cues->Belt.Array.keepMap(c => {
      let file = sfxDir ++ "/" ++ c.id ++ ".mp3"
      if !exists(Path(file)) {
        None
      } else {
        let start = switch Js.Dict.get(starts, c.beat) {
        | Some(s) => Belt.Int.toFloat(s) +. c.offset
        | None => fail("unresolved beat " ++ c.beat)
        }
        let Seconds(actual) = probeDuration(Path(file))
        let d = Js.Dict.empty()
        Js.Dict.set(d, "id", Js.Json.string(c.id))
        Js.Dict.set(d, "beat", Js.Json.string(c.beat))
        Js.Dict.set(d, "path", Js.Json.string("../audio/sfx/" ++ c.id ++ ".mp3"))
        Js.Dict.set(d, "startSeconds", Js.Json.number(start))
        Js.Dict.set(d, "durationSeconds", Js.Json.number(actual))
        Js.Dict.set(d, "gain", Js.Json.number(c.gain))
        Some(Js.Json.object_(d))
      }
    })
    let out = Js.Dict.empty()
    Js.Dict.set(out, "version", Js.Json.number(1.0))
    Js.Dict.set(
      out, "purpose",
      Js.Json.string(
        "Episode 9 sound effects resolved against EDL v4. startSeconds is absolute in the " ++
        "720s main story (which begins at 2:15 of the full episode). Regenerate with " ++
        "Kuku_SfxEp9 after any retime.",
      ),
    )
    Js.Dict.set(out, "cues", Js.Json.array(entries))
    writeText(
      Path(root ++ "/manifests/ep9_sfx_timeline.v1.json"),
      Js.Json.stringifyWithSpace(Js.Json.object_(out), 2),
    )
    Js.log("timeline carries " ++ Belt.Int.toString(Belt.Array.length(entries)) ++ " resolved cues")
  }

  Js.log(
    "\nmade=" ++ Belt.Int.toString(made.contents) ++
    " skipped=" ++ Belt.Int.toString(skipped.contents) ++
    " failed=" ++ Belt.Int.toString(failed.contents) ++
    (dry ? "\nDRY run — nothing generated, nothing spent." : ""),
  )
}

main()
->Js.Promise2.catch(e => {
  Js.log2("EP9 SFX FAILED:", e)
  Js.Promise.resolve()
})
->ignore
