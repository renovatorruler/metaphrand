/* EDL v3 retimer: resize beats so every beat FULLY CONTAINS its anchored dialogue.
 *
 * The user's law, verbatim: "You absolutely know when a dialogue stops. Only then you need
 * to switch the scene." The v2 beat durations were authored for picture pacing without
 * measuring the recorded lines, so cuts landed mid-sentence (S01-B04 cut away during
 * Rishi's line). This tool computes each beat's spoken load from the line->beat anchor
 * manifest plus the derived/manual line durations, gives every speaking beat
 * ceil(speech + 1.4s) so lines breathe, floors silent beats at 2s, and distributes the
 * remaining time across all beats proportionally to their v2 durations so the authored
 * pacing survives and the main story still totals exactly 12:00.
 *
 * Run:  node studio/src/Kuku_Ep9EdlRetime.res.mjs
 * Reads  finale/manifests/ep9_finale_animatic_edl.v2.json + ep9_dialogue_beat_anchors.v1.json
 * Writes finale/manifests/ep9_finale_animatic_edl.v3.json
 */
@val @scope("process") external exitProcess: int => unit = "exit"
@module("node:fs") external readFileSync: (string, string) => string = "readFileSync"
@module("node:fs") external writeFileSync: (string, string, string) => unit = "writeFileSync"
@module("node:fs") external readdirSync: string => array<string> = "readdirSync"

exception RetimeError(string)
let fail = m => raise(RetimeError(m))

let root = "stories/kuku/ep9prod/finale"
let json = path =>
  switch Js.Json.parseExn(readFileSync(path, "utf8")) {
  | j => j
  | exception _ => fail("unparseable json: " ++ path)
  }
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

let parseTc = tc =>
  switch Js.String2.split(tc, ":") {
  | [m, s] =>
    switch (Belt.Int.fromString(m), Belt.Int.fromString(s)) {
    | (Some(mm), Some(ss)) => mm * 60 + ss
    | _ => fail("bad timecode " ++ tc)
    }
  | _ => fail("bad timecode " ++ tc)
  }
let fmtTc = total => {
  let m = total / 60
  let s = mod(total, 60)
  Belt.Int.toString(m) ++ ":" ++ (s < 10 ? "0" : "") ++ Belt.Int.toString(s)
}

/* per-line durations: derived v5 timing files + manual-review candidates + the mimic */
let lineDurations = () => {
  let durs: Js.Dict.t<float> = Js.Dict.empty()
  let dir = root ++ "/audio/alignment/stem_validation/derived"
  readdirSync(dir)
  ->Belt.Array.keep(n => Js.String2.endsWith(n, ".json"))
  ->Belt.Array.forEach(n => {
    let o = obj(json(dir ++ "/" ++ n), n)
    if str(o, "pipeline_version", n) == "kuku-ep9-finale-dialogue-v5-candidate-content-bound" {
      let order = Js.Float.toString(num(o, "order", n))
      if Js.Dict.get(durs, order) == None {
        Js.Dict.set(durs, order, num(o, "source_end", n) -. num(o, "source_start", n))
      }
    }
  })
  let manual = obj(
    json(root ++ "/audio/EP9_DIALOGUE_MANUAL_REVIEW_kuku-ep9-finale-dialogue-v5-candidate-content-bound.json"),
    "manual",
  )
  switch Js.Json.decodeArray(get(manual, "exceptions", "manual")) {
  | Some(rows) => rows->Belt.Array.forEach(r => {
      let o = obj(r, "manual exception")
      Js.Dict.set(
        durs,
        Js.Float.toString(num(o, "order", "manual")),
        num(o, "candidate_duration_seconds", "manual"),
      )
    })
  | None => fail("manual.exceptions is not an array")
  }
  /* order 316 is the tansen mimic clip added by the guide builder; measured 2.5s is a safe
     ceiling for beat sizing (over-reserving by fractions of a second only widens a shot) */
  Js.Dict.set(durs, "316", 2.5)
  durs
}

let main = () => {
  let edlPath = root ++ "/manifests/ep9_finale_animatic_edl.v2.json"
  let edl = obj(json(edlPath), "edl")
  let anchors =
    obj(get(obj(json(root ++ "/manifests/ep9_dialogue_beat_anchors.v1.json"), "anchors"),
      "anchors", "anchors"), "anchors.anchors")
  let durs = lineDurations()

  /* speech per beat */
  let speech: Js.Dict.t<float> = Js.Dict.empty()
  Js.Dict.entries(anchors)->Belt.Array.forEach(((order, beatJson)) => {
    let beat = switch Js.Json.decodeString(beatJson) {
    | Some(b) => b
    | None => fail("anchor " ++ order ++ " not a string")
    }
    let d = switch Js.Dict.get(durs, order) {
    | Some(v) => v
    | None => 0.0 /* line not in the guide (unrecorded) — contributes nothing */
    }
    Js.Dict.set(speech, beat, switch Js.Dict.get(speech, beat) {
    | Some(prev) => prev +. d
    | None => d
    })
  })

  let beats = switch Js.Json.decodeArray(get(edl, "beats", "edl")) {
  | Some(b) => b
  | None => fail("edl.beats not an array")
  }
  let timeline = obj(get(edl, "timeline", "edl"), "timeline")
  let offset = parseTc(str(timeline, "start", "timeline"))
  let total = 720

  /* floors: speaking beats fit their lines + 1.4s; silent beats >= 2s */
  let floors = beats->Belt.Array.map(bj => {
    let b = obj(bj, "beat")
    let id = str(b, "id", "beat")
    switch Js.Dict.get(speech, id) {
    | Some(s) if s > 0.0 => Js.Math.ceil_int(s +. 1.4)
    | _ => 2
    }
  })
  let floorSum = floors->Belt.Array.reduce(0, (a, b) => a + b)
  if floorSum > total {
    fail("dialogue no longer fits 12:00: floors total " ++ Belt.Int.toString(floorSum))
  }
  /* distribute the remaining seconds proportionally to v2 durations (authored pacing) */
  let orig = beats->Belt.Array.map(bj => num(obj(bj, "beat"), "durationSeconds", "beat"))
  let origSum = orig->Belt.Array.reduce(0.0, (a, b) => a +. b)
  let slack = total - floorSum
  let exact = orig->Belt.Array.map(o => Belt.Int.toFloat(slack) *. o /. origSum)
  let extra = exact->Belt.Array.map(e => Js.Math.floor(e))
  let used = extra->Belt.Array.reduce(0, (a, b) => a + b)
  /* hand out the leftover seconds by largest fractional remainder */
  let rem = slack - used
  let byFrac =
    exact
    ->Belt.Array.mapWithIndex((i, e) => (i, e -. Js.Math.floor_float(e)))
    ->Js.Array2.sortInPlaceWith(((_, a), (_, b)) => a < b ? 1 : -1)
  for k in 0 to rem - 1 {
    switch byFrac->Belt.Array.get(k) {
    | Some((i, _)) => Belt.Array.setExn(extra, i, Belt.Array.getExn(extra, i) + 1)
    | None => ()
    }
  }

  let cursor = ref(offset)
  beats->Belt.Array.forEachWithIndex((i, bj) => {
    let b = obj(bj, "beat")
    let d = Belt.Array.getExn(floors, i) + Belt.Array.getExn(extra, i)
    Js.Dict.set(b, "start", Js.Json.string(fmtTc(cursor.contents)))
    Js.Dict.set(b, "end", Js.Json.string(fmtTc(cursor.contents + d)))
    Js.Dict.set(b, "durationSeconds", Js.Json.number(Belt.Int.toFloat(d)))
    cursor := cursor.contents + d
  })
  if cursor.contents - offset != total {
    fail("retime does not total 12:00: " ++ Belt.Int.toString(cursor.contents - offset))
  }
  Js.Dict.set(edl, "version", Js.Json.string("ep9-finale-animatic-edl-v3"))
  Js.Dict.set(edl, "retimeNote", Js.Json.string(
    "v3 (2026-08-18): beat durations resized so each beat fully contains its anchored " ++
    "dialogue (ceil(speech+1.4s); silent floor 2s; remaining time distributed by v2 " ++
    "pacing weights; total exactly 720s). Rule: a shot never ends before its dialogue.",
  ))
  writeFileSync(root ++ "/manifests/ep9_finale_animatic_edl.v3.json",
    Js.Json.stringifyWithSpace(Js.Json.object_(edl), 1), "utf8")
  Js.Console.log("EDL v3 written: floors " ++ Belt.Int.toString(floorSum) ++
    "s + distributed " ++ Belt.Int.toString(slack) ++ "s = 720s")
}

switch main() {
| () => ()
| exception RetimeError(m) => {
    Js.Console.error("RETIME FAILED: " ++ m)
    exitProcess(1)
  }
}
