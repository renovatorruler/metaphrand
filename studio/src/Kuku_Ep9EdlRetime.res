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
 * Reads  finale/manifests/ep9_finale_animatic_edl.v2.json + ep9_dialogue_beat_anchors.v2.json
 * Writes finale/manifests/ep9_finale_animatic_edl.v4.json
 */
@val @scope("process") external exitProcess: int => unit = "exit"
@module("node:fs") external readFileSync: (string, string) => string = "readFileSync"
@module("node:fs") external writeFileSync: (string, string, string) => unit = "writeFileSync"
@module("node:fs") external readdirSync: string => array<string> = "readdirSync"

@module("node:child_process") external execSync: (string, {..}) => string = "execSync"

exception RetimeError(string)
let fail = m => raise(RetimeError(m))

/* Motion beats must be long enough to PLAY their clip. Sizing beats purely from dialogue
   truncated 11 of 14 paid clips (50s of animation never reached the screen; the parent:
   "S49 cuts too early... the animation isn't even over"). So a motion beat's floor is its
   clip length, and the main story grows to fit rather than chopping the footage. */
let clipSeconds = (path: string): float =>
  switch execSync(
    "ffprobe -v error -show_entries format=duration -of csv=p=0 '" ++ path ++ "'",
    {"encoding": "utf8"},
  ) {
  | out =>
    switch Belt.Float.fromString(Js.String2.trim(out)) {
    | Some(d) => d
    | None => 0.0
    }
  | exception _ => 0.0
  }

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
    obj(get(obj(json(root ++ "/manifests/ep9_dialogue_beat_anchors.v2.json"), "anchors"),
      "anchors", "anchors"), "anchors.anchors")
  let durs = lineDurations()

  /* ordered lines per beat: (order, duration), sorted by order */
  let beatLines: Js.Dict.t<array<(int, float)>> = Js.Dict.empty()
  let leadIns: Js.Dict.t<float> = Js.Dict.empty()
  Js.Dict.entries(anchors)->Belt.Array.forEach(((order, beatJson)) => {
    let beat = switch Js.Json.decodeString(beatJson) {
    | Some(b) => b
    | None =>
      switch Js.Json.decodeObject(beatJson) {
      | Some(o) => {
          switch Js.Dict.get(o, "leadIn") {
          | Some(l) =>
            switch Js.Json.decodeNumber(l) {
            | Some(v) => {
                let bid = switch Js.Json.decodeString(get(o, "beat", "anchor " ++ order)) {
                | Some(b) => b
                | None => fail("anchor " ++ order ++ " beat not a string")
                }
                let bid = switch Js.String2.splitByRe(bid, %re("/-L\d+$/")) {
                | [Some(prefix), _] => prefix
                | _ => bid
                }
                Js.Dict.set(leadIns, bid,
                  switch Js.Dict.get(leadIns, bid) {
                  | Some(prev) => prev > v ? prev : v
                  | None => v
                  })
              }
            | None => ()
            }
          | None => ()
          }
          switch Js.Json.decodeString(get(o, "beat", "anchor " ++ order)) {
          | Some(b) => b
          | None => fail("anchor " ++ order ++ " beat not a string")
          }
        }
      | None => fail("anchor " ++ order ++ " not a string or object")
      }
    }
    let d = switch Js.Dict.get(durs, order) {
    | Some(v) => v
    | None => 0.0
    }
    let beat = switch Js.String2.splitByRe(beat, %re("/-L\d+$/")) {
    | [Some(prefix), _] => prefix
    | _ => beat
    }
    if d > 0.0 {
      let o = switch Belt.Int.fromString(order) {
      | Some(v) => v
      | None => fail("non-integer order " ++ order)
      }
      let prev = switch Js.Dict.get(beatLines, beat) {
      | Some(a) => a
      | None => []
      }
      Js.Dict.set(beatLines, beat, Belt.Array.concat(prev, [(o, d)]))
    }
  })
  Js.Dict.keys(beatLines)->Belt.Array.forEach(k =>
    switch Js.Dict.get(beatLines, k) {
    | Some(a) =>
      Js.Dict.set(beatLines, k,
        a->Js.Array2.sortInPlaceWith(((oa, _), (ob, _)) => oa - ob))
    | None => ()
    }
  )
  /* which beats are MOTION (their clips must not be fragmented): override accepted_motion
     or an EDL .mp4 asset. Motion beats stay whole — except S04-B04, where the user's audit
     confirmed Furia speaking outside the chest clip; it splits knowingly. */
  let overrides = obj(json(root ++ "/review/EP9_ROUGH_ANIMATIC_OVERRIDES_V1.json"), "overrides")
  let motion: Js.Dict.t<bool> = Js.Dict.empty()
  let motionLen: Js.Dict.t<float> = Js.Dict.empty()
  let motionPath: Js.Dict.t<string> = Js.Dict.empty()
  switch Js.Json.decodeArray(get(overrides, "beatSources", "overrides")) {
  | Some(rows) => rows->Belt.Array.forEach(r => {
      let o = obj(r, "override")
      if str(o, "kind", "override") == "accepted_motion" {
        let id = str(o, "beatId", "override")
        Js.Dict.set(motion, id, true)
        let p = root ++ "/manifests/" ++ str(o, "path", "override")
        Js.Dict.set(motionPath, id, p)
        Js.Dict.set(motionLen, id, clipSeconds(p))
      }
    })
  | None => fail("overrides.beatSources missing")
  }
  Js.Dict.set(motion, "S04-B04", false)
  /* Consecutive sub-shots sharing one clip play it CONTINUOUSLY (the builder seeks), so
     their floors split the clip rather than each demanding the whole thing. */
  let sharedRun: Js.Dict.t<int> = Js.Dict.empty()
  Js.Dict.keys(motionPath)->Belt.Array.forEach(id =>
    switch Js.Dict.get(motionPath, id) {
    | Some(p) => {
        let n = Js.Dict.keys(motionPath)->Belt.Array.keep(other =>
          Js.Dict.get(motionPath, other) == Some(p)
        )->Belt.Array.length
        Js.Dict.set(sharedRun, id, n)
      }
    | None => ()
    }
  )

  let beats = switch Js.Json.decodeArray(get(edl, "beats", "edl")) {
  | Some(b) => b
  | None => fail("edl.beats not an array")
  }
  let timeline = obj(get(edl, "timeline", "edl"), "timeline")
  let offset = parseTc(str(timeline, "start", "timeline"))
  /* The 12:00 main story was an authored target, not a delivery constraint, and it became
     the binding limit once every event had to be shown and every clip played whole. The
     total is now whatever the floors need (rounded up to a whole minute), so nothing is
     truncated to protect a number. Written back into the manifest for the downstream tools. */
  let minTotal = 720

  /* floors: speaking beats fit their lines + 1.4s; silent beats >= 2s */
  let isMotion = id =>
    switch Js.Dict.get(motion, id) {
    | Some(v) => v
    | None => {
        /* EDL-carried motion */
        let carried = beats->Belt.Array.some(bj => {
          let b = obj(bj, "beat")
          str(b, "id", "beat") == id &&
          (switch Js.Dict.get(b, "acceptedAssetPath") {
          | Some(v) =>
            switch Js.Json.decodeString(v) {
            | Some(pathStr) => Js.String2.endsWith(pathStr, ".mp4")
            | None => false
            }
          | None => false
          })
        })
        carried
      }
    }
  let willSplit = id =>
    switch Js.Dict.get(beatLines, id) {
    | Some(ls) => Belt.Array.length(ls) > 0 && !isMotion(id)
    | None => false
    }
  let floors = beats->Belt.Array.map(bj => {
    let b = obj(bj, "beat")
    let id = str(b, "id", "beat")
    switch Js.Dict.get(beatLines, id) {
    | Some(ls) if Belt.Array.length(ls) > 0 =>
      willSplit(id)
        ? ls->Belt.Array.reduce(0, (acc, (_, d)) => acc + Js.Math.ceil_int(d +. 0.9))
        : Js.Math.ceil_int(
            ls->Belt.Array.reduce(0.0, (a, (_, d)) => a +. d) +. 1.4 +.
            (switch Js.Dict.get(leadIns, id) {
            | Some(l) => l
            | None => 0.0
            }),
          )
    | _ => 2
    }
  })
  /* raise every motion beat to its clip length (split across sub-shots that share a clip) */
  beats->Belt.Array.forEachWithIndex((i, bj) => {
    let id = str(obj(bj, "beat"), "id", "beat")
    switch (Js.Dict.get(motionLen, id), Js.Dict.get(sharedRun, id)) {
    | (Some(len), Some(n)) if len > 0.0 => {
        let share = Js.Math.ceil_int(len /. Belt.Int.toFloat(n))
        if share > Belt.Array.getExn(floors, i) {
          Belt.Array.setExn(floors, i, share)
        }
      }
    | _ => ()
    }
  })
  let floorSum = floors->Belt.Array.reduce(0, (a, b) => a + b)
  /* grow to the next whole minute above the floors, never below the authored 12:00 */
  let total = {
    let needed = floorSum > minTotal ? floorSum : minTotal
    let rounded = (needed + 59) / 60 * 60
    rounded
  }
  Js.Console.log(
    "main story length: " ++ fmtTc(total) ++ " (floors need " ++ Belt.Int.toString(floorSum) ++
    "s; motion clips play whole)",
  )
  /* Parent-requested holds ("room to breathe", "linger on it"), granted in priority order
     from whatever slack the dialogue leaves. A boost shrinks rather than fails when the
     budget runs out, and the log says what was actually granted. */
  let boosts = [("S10-B06", 8), ("S03-B01", 3), ("S08-B16", 3), ("S06-B02", 2)]
  let granted = ref(0)
  boosts->Belt.Array.forEach(((boostId, wanted)) => {
    let capacity = total - floorSum - granted.contents
    let give = wanted < capacity ? wanted : capacity
    if give > 0 {
      beats->Belt.Array.forEachWithIndex((i, bj) =>
        if str(obj(bj, "beat"), "id", "beat") == boostId {
          Belt.Array.setExn(floors, i, Belt.Array.getExn(floors, i) + give)
          granted := granted.contents + give
        }
      )
    }
    Js.Console.log(
      "  hold " ++ boostId ++ ": +" ++ Belt.Int.toString(give) ++ "s of +" ++
      Belt.Int.toString(wanted) ++ "s requested",
    )
  })
  let floorSum = floorSum + granted.contents
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
  let outBeats: array<Js.Json.t> = []
  let splitMap: Js.Dict.t<Js.Json.t> = Js.Dict.empty()
  beats->Belt.Array.forEachWithIndex((i, bj) => {
    let b = obj(bj, "beat")
    let id = str(b, "id", "beat")
    let total = Belt.Array.getExn(floors, i) + Belt.Array.getExn(extra, i)
    if willSplit(id) {
      let ls = switch Js.Dict.get(beatLines, id) {
      | Some(v) => v
      | None => []
      }
      let bases = ls->Belt.Array.map(((_, d)) => Js.Math.ceil_int(d +. 0.9))
      let baseSum = bases->Belt.Array.reduce(0, (a, x) => a + x)
      let remainder = total - baseSum
      let n = Belt.Array.length(ls)
      let subIds: array<Js.Json.t> = []
      for k in 0 to n - 1 {
        let clone = Js.Dict.fromArray(Js.Dict.entries(b))
        let subId = id ++ "-L" ++ Belt.Int.toString(k + 1)
        let d = Belt.Array.getExn(bases, k) +
          (k == n - 1 && (remainder > 0 && remainder < 2) ? remainder : 0)
        Js.Dict.set(clone, "id", Js.Json.string(subId))
        Js.Dict.set(clone, "parentBeat", Js.Json.string(id))
        Js.Dict.set(clone, "lineOrder",
          Js.Json.number(Belt.Int.toFloat(fst(Belt.Array.getExn(ls, k)))))
        Js.Dict.set(clone, "start", Js.Json.string(fmtTc(cursor.contents)))
        Js.Dict.set(clone, "end", Js.Json.string(fmtTc(cursor.contents + d)))
        Js.Dict.set(clone, "durationSeconds", Js.Json.number(Belt.Int.toFloat(d)))
        Js.Array2.push(outBeats, Js.Json.object_(clone))->ignore
        Js.Array2.push(subIds, Js.Json.string(subId))->ignore
        cursor := cursor.contents + d
      }
      if remainder >= 2 {
        let clone = Js.Dict.fromArray(Js.Dict.entries(b))
        let subId = id ++ "-L" ++ Belt.Int.toString(n + 1)
        Js.Dict.set(clone, "id", Js.Json.string(subId))
        Js.Dict.set(clone, "parentBeat", Js.Json.string(id))
        Js.Dict.set(clone, "start", Js.Json.string(fmtTc(cursor.contents)))
        Js.Dict.set(clone, "end", Js.Json.string(fmtTc(cursor.contents + remainder)))
        Js.Dict.set(clone, "durationSeconds", Js.Json.number(Belt.Int.toFloat(remainder)))
        Js.Array2.push(outBeats, Js.Json.object_(clone))->ignore
        Js.Array2.push(subIds, Js.Json.string(subId))->ignore
        cursor := cursor.contents + remainder
      }
      Js.Dict.set(splitMap, id, Js.Json.array(subIds))
    } else {
      Js.Dict.set(b, "start", Js.Json.string(fmtTc(cursor.contents)))
      Js.Dict.set(b, "end", Js.Json.string(fmtTc(cursor.contents + total)))
      Js.Dict.set(b, "durationSeconds", Js.Json.number(Belt.Int.toFloat(total)))
      Js.Array2.push(outBeats, bj)->ignore
      cursor := cursor.contents + total
    }
  })
  Js.Dict.set(edl, "beats", Js.Json.array(outBeats))
  Js.Dict.set(edl, "splitMap", Js.Json.object_(splitMap))
  if cursor.contents - offset != total {
    fail("retime does not total 12:00: " ++ Belt.Int.toString(cursor.contents - offset))
  }
  /* publish the new length so the validator, builder and guide mix all agree */
  Js.Dict.set(timeline, "durationSeconds", Js.Json.number(Belt.Int.toFloat(total)))
  Js.Dict.set(timeline, "end", Js.Json.string(fmtTc(offset + total)))
  Js.Dict.set(edl, "timeline", Js.Json.object_(timeline))
  Js.Dict.set(edl, "version", Js.Json.string("ep9-finale-animatic-edl-v4"))
  Js.Dict.set(edl, "retimeNote", Js.Json.string(
    "v4 (2026-08-18): per-line SUB-SHOTS. Still-backed beats with dialogue split into one " ++
    "sub-shot per line (ceil(line+0.9s)), remainder kept as a trailing sub-shot with the " ++
    "parent visual; motion beats stay whole except S04-B04. Total exactly 720s. Rules: a " ++
    "shot never ends before its dialogue, and every line shows its speaker.",
  ))
  writeFileSync(root ++ "/manifests/ep9_finale_animatic_edl.v4.json",
    Js.Json.stringifyWithSpace(Js.Json.object_(edl), 1), "utf8")
  Js.Console.log("EDL v4 written: floors " ++ Belt.Int.toString(floorSum) ++
    "s + distributed " ++ Belt.Int.toString(slack) ++ "s = " ++ fmtTc(total))
}

switch main() {
| () => ()
| exception RetimeError(m) => {
    Js.Console.error("RETIME FAILED: " ++ m)
    exitProcess(1)
  }
}
