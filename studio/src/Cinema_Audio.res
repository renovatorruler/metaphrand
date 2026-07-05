/* See Cinema_Audio.resi for the contract. Grouping + caching + manifest, exactly
   as the Python render does; every external call routes through Cinema_Backends.
   The performance is held as typed records and (de)serialized via Js.Json. */

@unboxed type title = Title(string)
@unboxed type role = Role(string)
@unboxed type voiceName = VoiceName(string)
@unboxed type sceneId = SceneId(string)
@unboxed type line = Line(string)

type castMember = {role: role, voiceName: voiceName, voiceId: Cinema_Backends.voiceId}
type scene = {id: sceneId, beats: array<(role, line)>}

/* a flattened segment, the unit the renderer groups over. */
type segment = {scene: sceneId, speaker: role, text: line}

type performance = {
  title: title,
  gapMs: Cinema_Backends.millis,
  cast: array<castMember>,
  segments: array<segment>,
  jsonPath: Cinema_Backends.path,
}

/* ---- crypto for the stable take digest (a real Node binding) -------------- */
type hash
@module("crypto") external createHash: string => hash = "createHash"
@send external hashUpdate: (hash, string) => hash = "update"
@send external hashDigest: (hash, string) => string = "digest"
let sha1Short = (s: string): string =>
  Js.String2.slice(hashDigest(hashUpdate(createHash("sha1"), s), "hex"), ~from=0, ~to_=16)

/* ---- json helpers -------------------------------------------------------- */
let str = Js.Json.string
let num = (i: int) => Js.Json.number(Belt.Int.toFloat(i))
let fld = (j, k) => j->Js.Json.decodeObject->Belt.Option.flatMap(o => Js.Dict.get(o, k))
let asStr = o => o->Belt.Option.flatMap(Js.Json.decodeString)->Belt.Option.getWithDefault("")
let asNum = o => o->Belt.Option.flatMap(Js.Json.decodeNumber)->Belt.Option.getWithDefault(0.0)
let asArr = o => o->Belt.Option.flatMap(Js.Json.decodeArray)->Belt.Option.getWithDefault([])

/* ---- build_performance --------------------------------------------------- */
let performanceJson = (p: performance): Js.Json.t => {
  let castObj = Js.Dict.empty()
  Belt.Array.forEach(p.cast, m => {
    let Role(r) = m.role
    let VoiceName(n) = m.voiceName
    let Cinema_Backends.VoiceId(v) = m.voiceId
    let e = Js.Dict.empty()
    Js.Dict.set(e, "voice", str(n))
    Js.Dict.set(e, "voice_id", str(v))
    Js.Dict.set(castObj, r, Js.Json.object_(e))
  })
  let segs = Belt.Array.map(p.segments, s => {
    let SceneId(sid) = s.scene
    let Role(sp) = s.speaker
    let Line(t) = s.text
    let d = Js.Dict.empty()
    Js.Dict.set(d, "scene", str(sid))
    Js.Dict.set(d, "frame", str(sid))
    Js.Dict.set(d, "speaker", str(sp))
    Js.Dict.set(d, "text", str(t))
    Js.Json.object_(d)
  })
  let Title(t) = p.title
  let Cinema_Backends.Millis(gap) = p.gapMs
  let gaps = Js.Dict.empty()
  Js.Dict.set(gaps, "group", num(gap))
  let top = Js.Dict.empty()
  Js.Dict.set(top, "title", str(t))
  Js.Dict.set(top, "model_id", str("eleven_v3"))
  Js.Dict.set(top, "output_format", str("mp3_44100_128"))
  Js.Dict.set(top, "gaps_ms", Js.Json.object_(gaps))
  Js.Dict.set(top, "cast", Js.Json.object_(castObj))
  Js.Dict.set(top, "segments", Js.Json.array(segs))
  Js.Json.object_(top)
}

let performance = (
  ~title: title,
  ~cast: array<castMember>,
  ~scenes: array<scene>,
  ~gapMs: Cinema_Backends.millis,
  ~out: Cinema_Backends.path,
): performance => {
  let segments = Belt.Array.concatMany(
    Belt.Array.map(scenes, sc =>
      Belt.Array.map(sc.beats, ((r, l)) => {scene: sc.id, speaker: r, text: l})
    ),
  )
  let p = {title, gapMs, cast, segments, jsonPath: out}
  Cinema_Backends.writeText(out, Js.Json.stringifyWithSpace(performanceJson(p), 1))
  Js.log(
    Belt.Int.toString(Array.length(scenes)) ++
    " scenes, " ++
    Belt.Int.toString(Array.length(segments)) ++
    " lines -> performance",
  )
  p
}

/* ---- load ---------------------------------------------------------------- */
let load = (path: Cinema_Backends.path): performance => {
  let j = Js.Json.parseExn(Cinema_Backends.readText(path))
  let castEntries = switch fld(j, "cast")->Belt.Option.flatMap(Js.Json.decodeObject) {
  | None => []
  | Some(o) =>
    Js.Dict.entries(o)->Belt.Array.map(((r, v)) => {
      role: Role(r),
      voiceName: VoiceName(asStr(fld(v, "voice"))),
      voiceId: Cinema_Backends.VoiceId(asStr(fld(v, "voice_id"))),
    })
  }
  let segs = asArr(fld(j, "segments"))->Belt.Array.map(s => {
    scene: SceneId(asStr(fld(s, "scene"))),
    speaker: Role(asStr(fld(s, "speaker"))),
    text: Line(asStr(fld(s, "text"))),
  })
  {
    title: Title(asStr(fld(j, "title"))),
    gapMs: Cinema_Backends.Millis(
      asNum(fld(j, "gaps_ms")->Belt.Option.flatMap(g => fld(g, "group")))->Belt.Float.toInt,
    ),
    cast: castEntries,
    segments: segs,
    jsonPath: path,
  }
}

/* ---- render -------------------------------------------------------------- */
/* the group key: the scene id up to an em-dash (the frame == that scene id). */
let groupKey = (s: segment): sceneId => {
  let SceneId(sid) = s.scene
  let base = switch Js.String2.indexOf(sid, "—") {
  | -1 => sid
  | i => Js.String2.slice(sid, ~from=0, ~to_=i)
  }
  SceneId(Js.String2.trim(base))
}

type group = {scene: sceneId, segs: array<segment>}

/* fold consecutive same-key segments into one take. */
let groupSegments = (segments: array<segment>): array<group> =>
  Belt.Array.reduce(segments, [], (groups, s) => {
    let SceneId(k) = groupKey(s)
    switch Belt.Array.get(groups, Array.length(groups) - 1) {
    | Some(g) when {
        let SceneId(gk) = g.scene
        gk == k
      } => {
        let merged = {...g, segs: Belt.Array.concat(g.segs, [s])}
        Belt.Array.concat(Belt.Array.slice(groups, ~offset=0, ~len=Array.length(groups) - 1), [merged])
      }
    | _ => Belt.Array.concat(groups, [{scene: SceneId(k), segs: [s]}])
    }
  })

let voiceIdFor = (cast: array<castMember>, r: role): Cinema_Backends.voiceId =>
  switch Belt.Array.getBy(cast, m => m.role == r) {
  | Some(m) => m.voiceId
  | None => {
      let Role(rn) = r
      raise(Cinema_Backends.BackendError("no voice for role " ++ rn))
    }
  }

/* one manifest row, as JSON. */
let manifestRow = (gi: int, g: group, path: Cinema_Backends.path, dur: float, gapAfter: int): Js.Json.t => {
  let Cinema_Backends.Path(p) = path
  let SceneId(k) = g.scene
  let d = Js.Dict.empty()
  Js.Dict.set(d, "group", num(gi))
  Js.Dict.set(d, "scene", str(k))
  Js.Dict.set(d, "frame", str(k))
  Js.Dict.set(d, "path", str(p))
  Js.Dict.set(d, "duration", Js.Json.number(dur))
  Js.Dict.set(d, "gap_after_ms", num(gapAfter))
  Js.Json.object_(d)
}

/* render one group to a cached mp3, returning (path, duration). */
let renderGroup = async (
  cache: string,
  cast: array<castMember>,
  g: group,
): (Cinema_Backends.path, float) => {
  let inputs = Belt.Array.map(g.segs, s => {
    let Line(t) = s.text
    let vid = voiceIdFor(cast, s.speaker)
    (Cinema_Backends.Text(t), vid)
  })
  /* a stable digest of the inputs (text + voice id, in order) + the model. */
  let sig = Js.Array2.joinWith(
    Belt.Array.map(inputs, ((Cinema_Backends.Text(t), Cinema_Backends.VoiceId(v))) => t ++ "|" ++ v),
    "\n",
  ) ++ "::eleven_v3"
  let path = Cinema_Backends.Path(cache ++ "/grp_" ++ sha1Short(sig) ++ ".mp3")
  if !Cinema_Backends.exists(path) {
    let bytes = await Cinema_Backends.dialogue(inputs)
    Cinema_Backends.writeBytes(path, bytes)->ignore
    let SceneId(k) = g.scene
    Js.log(k)
  }
  let Cinema_Backends.Seconds(dur) = Cinema_Backends.durationSec(path)
  (path, dur)
}

let render = async (p: performance, ~out: Cinema_Backends.path): Cinema_Backends.path => {
  let Cinema_Backends.Path(outStr) = out
  let Cinema_Backends.Path(jsonStr) = p.jsonPath
  let dir = switch Js.String2.lastIndexOf(jsonStr, "/") {
  | -1 => "."
  | i => Js.String2.slice(jsonStr, ~from=0, ~to_=i)
  }
  let cache = dir ++ "/segments"
  let Cinema_Backends.Millis(gap) = p.gapMs
  let groups = groupSegments(p.segments)
  let n = Array.length(groups)

  /* render groups in order (one at a time), stitching silence between them. */
  let rec go = async (
    i: int,
    files: array<Cinema_Backends.path>,
    manifest: array<Js.Json.t>,
  ): (array<Cinema_Backends.path>, array<Js.Json.t>) =>
    if i >= n {
      (files, manifest)
    } else {
      let g = Belt.Array.getExn(groups, i)
      let (path, dur) = await renderGroup(cache, p.cast, g)
      let files' =
        i > 0
          ? Belt.Array.concatMany([files, [Cinema_Backends.silence(Cinema_Backends.Millis(gap), Cinema_Backends.Path(cache))], [path]])
          : Belt.Array.concat(files, [path])
      let gapAfter = i == n - 1 ? 0 : gap
      await go(i + 1, files', Belt.Array.concat(manifest, [manifestRow(i, g, path, dur, gapAfter)]))
    }
  let (files, manifest) = await go(0, [], [])

  /* sibling manifest: out.mp3 -> out.manifest.json */
  let stem = switch Js.String2.lastIndexOf(outStr, ".") {
  | -1 => outStr
  | i => Js.String2.slice(outStr, ~from=0, ~to_=i)
  }
  Cinema_Backends.writeText(
    Cinema_Backends.Path(stem ++ ".manifest.json"),
    Js.Json.stringifyWithSpace(Js.Json.array(manifest), 1),
  )
  Cinema_Backends.concatAudio(files, out)->ignore
  let Cinema_Backends.Seconds(total) = Cinema_Backends.durationSec(out)
  Js.log(
    Belt.Int.toString(n) ++
    " takes -> " ++ outStr ++ " (" ++ Js.Float.toFixedWithPrecision(total /. 60.0, ~digits=1) ++ " min)",
  )
  out
}

/* ---- radioize: FFMPEG FILTERS ONLY --------------------------------------- */
/* highpass 420 + lowpass 2900 + a peaking EQ boost at 1800 + acompressor — the
   thin, mid-forward AM-radio voice. No Web Audio, no JS DSP library. */
let radioize = (src: Cinema_Backends.path): Cinema_Backends.path => {
  let Cinema_Backends.Path(s) = src
  let stem = switch Js.String2.lastIndexOf(s, ".") {
  | -1 => s
  | i => Js.String2.slice(s, ~from=0, ~to_=i)
  }
  let out = stem ++ ".radio.mp3"
  /* aviation-comms radio: narrow band + presence bump + hard compression + a little
     saturation grit, so it clearly reads as coming through the radio. */
  let af =
    "highpass=f=520,lowpass=f=2500," ++
    "equalizer=f=1700:t=q:w=1.3:g=9," ++
    "acompressor=threshold=-24dB:ratio=8:attack=3:release=80:makeup=6," ++
    "asoftclip=type=atan," ++
    "alimiter=limit=0.9"
  Cinema_Backends.ffmpeg([
    "-nostdin", "-loglevel", "error", "-y", "-i", s,
    "-af", af, "-codec:a", "libmp3lame", "-b:a", "64k", "-ar", "44100", out,
  ])
  Cinema_Backends.Path(out)
}

/* airport PA / tannoy: boxier band than the radio, a honky mid bump, and a
   short concrete-hall slapback so it reads as a terminal announcement. */
let paize = (src: Cinema_Backends.path): Cinema_Backends.path => {
  let Cinema_Backends.Path(s) = src
  let stem = switch Js.String2.lastIndexOf(s, ".") {
  | -1 => s
  | i => Js.String2.slice(s, ~from=0, ~to_=i)
  }
  let out = stem ++ ".pa.mp3"
  let af =
    "highpass=f=250,lowpass=f=3800," ++
    "equalizer=f=1000:t=q:w=1.0:g=6," ++
    "acompressor=threshold=-20dB:ratio=6:attack=5:release=120:makeup=5," ++
    "asoftclip=type=atan," ++
    "aecho=0.8:0.55:60|115:0.32|0.18," ++
    "alimiter=limit=0.9"
  Cinema_Backends.ffmpeg([
    "-nostdin", "-loglevel", "error", "-y", "-i", s,
    "-af", af, "-codec:a", "libmp3lame", "-b:a", "64k", "-ar", "44100", out,
  ])
  Cinema_Backends.Path(out)
}
