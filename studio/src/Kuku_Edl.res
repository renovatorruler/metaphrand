/* कुकु और अक्षर — the edit decision list, as types.

   This replaces the duck-typed dictionaries the Python assembler carried around.
   The important win is `take`: the Python distinguished a spoken line from a sound
   effect by asking `'i' in tk`, and the rule "only speech advances the clock" lived
   in a comment. Here speech and effect are separate constructors, so every place
   that walks a segment's takes must say what it does with each — the compiler will
   not let that rule be forgotten again.

   Decoding is strict on purpose: a malformed EDL raises with the offending path
   rather than defaulting a field and silently producing a wrong cut. */

exception EdlError(string)

/* ---- shapes -------------------------------------------------------------- */

type source =
  | Still(string) /* stills/<name>.png  */
  | Clip(string) /* clips/<name>.mp4   */
  | Card(string) /* cards/<name>.png   */
  | File(string) /* a literal path (lip-synced clips land here) */
  | Seq /* a sequence of cards, listed in `cards` */

type take =
  | Speech({idx: int, at: option<float>})
  | Effect({name: string, at: option<float>, duck: bool})

type fx = {png: string, at: float, scale: float, pos: string}

type segment = {
  src: source,
  dur: option<float>,
  inPoint: option<float>,
  fadeout: option<float>,
  bridge: bool,
  cards: array<string>,
  fx: array<fx>,
  takes: array<take>,
  stillWas: option<string>, /* set when a still was swapped for a lip-synced clip */
}

type scene = {
  name: string,
  cue: string,
  scoreVol: float,
  cueIn: float,
  segments: array<segment>,
}

type t = {scenes: array<scene>}

/* ---- decoding ------------------------------------------------------------ */

let objOf = (j: Js.Json.t, where: string): Js.Dict.t<Js.Json.t> =>
  switch Js.Json.decodeObject(j) {
  | Some(o) => o
  | None => raise(EdlError(where ++ ": expected an object"))
  }

let arrOf = (j: Js.Json.t, where: string): array<Js.Json.t> =>
  switch Js.Json.decodeArray(j) {
  | Some(a) => a
  | None => raise(EdlError(where ++ ": expected an array"))
  }

let get = (o: Js.Dict.t<Js.Json.t>, k: string): option<Js.Json.t> => Js.Dict.get(o, k)

let optStr = (o, k): option<string> => get(o, k)->Belt.Option.flatMap(Js.Json.decodeString)
let optNum = (o, k): option<float> => get(o, k)->Belt.Option.flatMap(Js.Json.decodeNumber)
let optBool = (o, k): option<bool> => get(o, k)->Belt.Option.flatMap(Js.Json.decodeBoolean)

let reqStr = (o, k, where): string =>
  switch optStr(o, k) {
  | Some(s) => s
  | None => raise(EdlError(where ++ ": missing string field '" ++ k ++ "'"))
  }

let optArr = (o, k, where): array<Js.Json.t> =>
  switch get(o, k) {
  | Some(j) => arrOf(j, where ++ "." ++ k)
  | None => []
  }

/* "still:e5_d4_dadi" -> Still("e5_d4_dadi"). An unknown prefix is an error, not a
   default — a typo in the EDL must not quietly render the wrong thing. */
let decodeSource = (s: string, where: string): source => {
  let split = (prefix: string): option<string> =>
    Js.String2.startsWith(s, prefix)
      ? Some(Js.String2.sliceToEnd(s, ~from=Js.String2.length(prefix)))
      : None
  switch (s, split("still:"), split("clip:"), split("card:"), split("file:")) {
  | ("seq", _, _, _, _) => Seq
  | (_, Some(n), _, _, _) => Still(n)
  | (_, _, Some(n), _, _) => Clip(n)
  | (_, _, _, Some(n), _) => Card(n)
  | (_, _, _, _, Some(n)) => File(n)
  | _ => raise(EdlError(where ++ ": unknown src '" ++ s ++ "'"))
  }
}

let sourceToString = (s: source): string =>
  switch s {
  | Still(n) => "still:" ++ n
  | Clip(n) => "clip:" ++ n
  | Card(n) => "card:" ++ n
  | File(n) => "file:" ++ n
  | Seq => "seq"
  }

/* the file a source actually reads, relative to the episode dir (Seq has none —
   it renders from `cards`) */
let sourcePath = (s: source): option<string> =>
  switch s {
  | Still(n) => Some("stills/" ++ n ++ ".png")
  | Clip(n) => Some("clips/" ++ n ++ ".mp4")
  | Card(n) => Some("cards/" ++ n ++ ".png")
  | File(p) => Some(p)
  | Seq => None
  }

let decodeTake = (j: Js.Json.t, where: string): take => {
  let o = objOf(j, where)
  let at = optNum(o, "at")
  switch (optNum(o, "i"), optStr(o, "sfx")) {
  | (Some(i), _) => Speech({idx: Belt.Float.toInt(i), at})
  | (None, Some(name)) =>
    Effect({name, at, duck: optBool(o, "duck")->Belt.Option.getWithDefault(true)})
  | (None, None) => raise(EdlError(where ++ ": take has neither 'i' nor 'sfx'"))
  }
}

let decodeFx = (j: Js.Json.t, where: string): fx => {
  let o = objOf(j, where)
  {
    png: reqStr(o, "png", where),
    at: optNum(o, "at")->Belt.Option.getWithDefault(0.0),
    scale: optNum(o, "scale")->Belt.Option.getWithDefault(1.0),
    pos: optStr(o, "pos")->Belt.Option.getWithDefault("tc"),
  }
}

let decodeSegment = (j: Js.Json.t, where: string): segment => {
  let o = objOf(j, where)
  {
    src: decodeSource(reqStr(o, "src", where), where),
    dur: optNum(o, "dur"),
    inPoint: optNum(o, "in"),
    fadeout: optNum(o, "fadeout"),
    bridge: optBool(o, "bridge")->Belt.Option.getWithDefault(false),
    cards: optArr(o, "cards", where)->Belt.Array.mapWithIndex((k, c) =>
      switch Js.Json.decodeString(c) {
      | Some(s) => s
      | None => raise(EdlError(where ++ ".cards[" ++ Belt.Int.toString(k) ++ "]: expected a string"))
      }
    ),
    fx: optArr(o, "fx", where)->Belt.Array.mapWithIndex((k, f) =>
      decodeFx(f, where ++ ".fx[" ++ Belt.Int.toString(k) ++ "]")
    ),
    takes: optArr(o, "takes", where)->Belt.Array.mapWithIndex((k, t) =>
      decodeTake(t, where ++ ".takes[" ++ Belt.Int.toString(k) ++ "]")
    ),
    stillWas: optStr(o, "still_was"),
  }
}

let decodeScene = (j: Js.Json.t, where: string): scene => {
  let o = objOf(j, where)
  let name = reqStr(o, "name", where)
  {
    name,
    cue: reqStr(o, "cue", where ++ " (" ++ name ++ ")"),
    scoreVol: optNum(o, "score_vol")->Belt.Option.getWithDefault(0.5),
    cueIn: optNum(o, "cue_in")->Belt.Option.getWithDefault(0.0),
    segments: optArr(o, "segments", name)->Belt.Array.mapWithIndex((k, s) =>
      decodeSegment(s, name ++ "#" ++ Belt.Int.toString(k))
    ),
  }
}

let decode = (raw: string): t => {
  let j = switch Js.Json.parseExn(raw) {
  | j => j
  | exception _ => raise(EdlError("EDL is not valid JSON"))
  }
  let o = objOf(j, "<edl>")
  switch get(o, "scenes") {
  | Some(ss) => {
      scenes: arrOf(ss, "scenes")->Belt.Array.mapWithIndex((k, s) =>
        decodeScene(s, "scenes[" ++ Belt.Int.toString(k) ++ "]")
      ),
    }
  | None => raise(EdlError("<edl>: missing 'scenes'"))
  }
}

let load = (p: Cinema_Backends.path): t => decode(Cinema_Backends.readText(p))

/* ---- encoding ------------------------------------------------------------ */
/* Only the fields that were present survive a round trip; absent options stay
   absent so re-saving an EDL does not litter it with defaults. */

let setOptNum = (o, k, v: option<float>) =>
  switch v {
  | Some(x) => Js.Dict.set(o, k, Js.Json.number(x))
  | None => ()
  }

let encodeTake = (t: take): Js.Json.t => {
  let o = Js.Dict.empty()
  switch t {
  | Speech({idx, at}) => {
      Js.Dict.set(o, "i", Js.Json.number(Belt.Int.toFloat(idx)))
      setOptNum(o, "at", at)
    }
  | Effect({name, at, duck}) => {
      Js.Dict.set(o, "sfx", Js.Json.string(name))
      setOptNum(o, "at", at)
      Js.Dict.set(o, "duck", Js.Json.boolean(duck))
    }
  }
  Js.Json.object_(o)
}

let encodeFx = (f: fx): Js.Json.t => {
  let o = Js.Dict.empty()
  Js.Dict.set(o, "png", Js.Json.string(f.png))
  Js.Dict.set(o, "at", Js.Json.number(f.at))
  Js.Dict.set(o, "scale", Js.Json.number(f.scale))
  Js.Dict.set(o, "pos", Js.Json.string(f.pos))
  Js.Json.object_(o)
}

let encodeSegment = (s: segment): Js.Json.t => {
  let o = Js.Dict.empty()
  Js.Dict.set(o, "src", Js.Json.string(sourceToString(s.src)))
  setOptNum(o, "dur", s.dur)
  setOptNum(o, "in", s.inPoint)
  setOptNum(o, "fadeout", s.fadeout)
  if s.bridge {
    Js.Dict.set(o, "bridge", Js.Json.boolean(true))
  }
  if Belt.Array.length(s.cards) > 0 {
    Js.Dict.set(o, "cards", Js.Json.array(Belt.Array.map(s.cards, Js.Json.string)))
  }
  if Belt.Array.length(s.fx) > 0 {
    Js.Dict.set(o, "fx", Js.Json.array(Belt.Array.map(s.fx, encodeFx)))
  }
  Js.Dict.set(o, "takes", Js.Json.array(Belt.Array.map(s.takes, encodeTake)))
  switch s.stillWas {
  | Some(w) => Js.Dict.set(o, "still_was", Js.Json.string(w))
  | None => ()
  }
  Js.Json.object_(o)
}

let encodeScene = (s: scene): Js.Json.t => {
  let o = Js.Dict.empty()
  Js.Dict.set(o, "name", Js.Json.string(s.name))
  Js.Dict.set(o, "cue", Js.Json.string(s.cue))
  Js.Dict.set(o, "score_vol", Js.Json.number(s.scoreVol))
  if s.cueIn != 0.0 {
    Js.Dict.set(o, "cue_in", Js.Json.number(s.cueIn))
  }
  Js.Dict.set(o, "segments", Js.Json.array(Belt.Array.map(s.segments, encodeSegment)))
  Js.Json.object_(o)
}

let encode = (e: t): string => {
  let o = Js.Dict.empty()
  Js.Dict.set(o, "scenes", Js.Json.array(Belt.Array.map(e.scenes, encodeScene)))
  Js.Json.stringifyWithSpace(Js.Json.object_(o), 1)
}

let save = (p: Cinema_Backends.path, e: t): unit => Cinema_Backends.writeText(p, encode(e))

/* ---- durations (ep5_durs.json) ------------------------------------------- */

type durs = {takes: Js.Dict.t<float>, sfx: Js.Dict.t<float>}

let decodeNumDict = (j: option<Js.Json.t>, where: string): Js.Dict.t<float> =>
  switch j {
  | None => Js.Dict.empty()
  | Some(x) => {
      let o = objOf(x, where)
      let out = Js.Dict.empty()
      Js.Dict.entries(o)->Belt.Array.forEach(((k, v)) =>
        switch Js.Json.decodeNumber(v) {
        | Some(n) => Js.Dict.set(out, k, n)
        | None => raise(EdlError(where ++ "." ++ k ++ ": expected a number"))
        }
      )
      out
    }
  }

let loadDurs = (p: Cinema_Backends.path): durs => {
  let o = objOf(Js.Json.parseExn(Cinema_Backends.readText(p)), "<durs>")
  {
    takes: decodeNumDict(get(o, "takes"), "durs.takes"),
    sfx: decodeNumDict(get(o, "sfx"), "durs.sfx"),
  }
}

let takeDur = (d: durs, idx: int): float =>
  switch Js.Dict.get(d.takes, Belt.Int.toString(idx)) {
  | Some(x) => x
  | None => raise(EdlError("no duration for take " ++ Belt.Int.toString(idx)))
  }

let sfxDur = (d: durs, name: string): float =>
  switch Js.Dict.get(d.sfx, name) {
  | Some(x) => x
  | None => raise(EdlError("no duration for sfx '" ++ name ++ "'"))
  }

/* the duration a take contributes, whichever kind it is */
let eventDur = (d: durs, t: take): float =>
  switch t {
  | Speech({idx}) => takeDur(d, idx)
  | Effect({name}) => sfxDur(d, name)
  }

/* The audio file a take plays.

   Mimicry is the exception: तानसेन's lines are placed as EFFECTS so they do not
   advance the dialogue clock, but they are recorded VOICE and live in takes/ with
   the rest of the cast. Sending them to sfx/ hands ffmpeg an input that does not
   exist and the whole scene's audio bus fails. */
let eventPath = (t: take): string =>
  switch t {
  | Speech({idx}) =>
    "takes/" ++ (idx < 10 ? "0" : "") ++ Belt.Int.toString(idx) ++ ".mp3"
  | Effect({name}) =>
    Js.String2.startsWith(name, "mimic_") ? "takes/" ++ name ++ ".mp3" : "sfx/" ++ name ++ ".mp3"
  }
