/* Round-trip proof for Kuku_Edl against the real Ep5 files: decode the EDL, re-encode
   it, and re-decode that — then compare the two decoded structures field by field.
   If the decoder drops or invents anything, this fails.

   Run from studio/:  node src/Kuku_EdlCheck.res.mjs */
open Cinema_Backends

let dir = "/Users/dusty/Dev/metaphrand/stories/kuku/ep5prod"

let fails = ref(0)
let check = (label: string, ok: bool) =>
  if !ok {
    fails := fails.contents + 1
    Js.log("  FAIL " ++ label)
  }

let takeEq = (a: Kuku_Edl.take, b: Kuku_Edl.take): bool =>
  switch (a, b) {
  | (Speech(x), Speech(y)) => x.idx == y.idx && x.at == y.at
  | (Effect(x), Effect(y)) => x.name == y.name && x.at == y.at && x.duck == y.duck
  | _ => false
  }

let segEq = (a: Kuku_Edl.segment, b: Kuku_Edl.segment): bool =>
  Kuku_Edl.sourceToString(a.src) == Kuku_Edl.sourceToString(b.src) &&
  a.dur == b.dur &&
  a.inPoint == b.inPoint &&
  a.fadeout == b.fadeout &&
  a.bridge == b.bridge &&
  a.cards == b.cards &&
  a.stillWas == b.stillWas &&
  Belt.Array.length(a.fx) == Belt.Array.length(b.fx) &&
  Belt.Array.every(Belt.Array.zip(a.fx, b.fx), ((x, y)) =>
    x.png == y.png && x.at == y.at && x.scale == y.scale && x.pos == y.pos
  ) &&
  Belt.Array.length(a.takes) == Belt.Array.length(b.takes) &&
  Belt.Array.every(Belt.Array.zip(a.takes, b.takes), ((x, y)) => takeEq(x, y))

let main = () => {
  let edlPath = Path(dir ++ "/ep5_edl.json")
  let a = Kuku_Edl.load(edlPath)
  let b = Kuku_Edl.decode(Kuku_Edl.encode(a))

  check("scene count", Belt.Array.length(a.scenes) == Belt.Array.length(b.scenes))
  Belt.Array.zip(a.scenes, b.scenes)->Belt.Array.forEach(((x, y)) => {
    check(x.name ++ " name", x.name == y.name)
    check(x.name ++ " cue", x.cue == y.cue)
    check(x.name ++ " scoreVol", x.scoreVol == y.scoreVol)
    check(x.name ++ " cueIn", x.cueIn == y.cueIn)
    check(
      x.name ++ " segment count",
      Belt.Array.length(x.segments) == Belt.Array.length(y.segments),
    )
    Belt.Array.zip(x.segments, y.segments)->Belt.Array.forEachWithIndex((i, (p, q)) =>
      check(x.name ++ "#" ++ Belt.Int.toString(i), segEq(p, q))
    )
  })

  /* counts that must match what the Python pipeline reported */
  let segCount = Belt.Array.reduce(a.scenes, 0, (n, s) => n + Belt.Array.length(s.segments))
  let speech = Belt.Array.reduce(a.scenes, 0, (n, s) =>
    n +
    Belt.Array.reduce(s.segments, 0, (m, g) =>
      m +
      Belt.Array.length(
        Belt.Array.keep(g.takes, t =>
          switch t {
          | Speech(_) => true
          | Effect(_) => false
          }
        ),
      )
    )
  )
  let effects = Belt.Array.reduce(a.scenes, 0, (n, s) =>
    n +
    Belt.Array.reduce(s.segments, 0, (m, g) =>
      m +
      Belt.Array.length(
        Belt.Array.keep(g.takes, t =>
          switch t {
          | Speech(_) => false
          | Effect(_) => true
          }
        ),
      )
    )
  )
  let stills = Belt.Array.reduce(a.scenes, 0, (n, s) =>
    n +
    Belt.Array.length(
      Belt.Array.keep(s.segments, g =>
        switch g.src {
        | Still(_) => true
        | _ => false
        }
      ),
    )
  )

  /* durations file must resolve every event the EDL references */
  let durs = Kuku_Edl.loadDurs(Path(dir ++ "/ep5_durs.json"))
  let missing = ref(0)
  a.scenes->Belt.Array.forEach(s =>
    s.segments->Belt.Array.forEach(g =>
      g.takes->Belt.Array.forEach(t =>
        switch Kuku_Edl.eventDur(durs, t) {
        | _ => ()
        | exception _ => missing := missing.contents + 1
        }
      )
    )
  )

  Js.log(
    "scenes=" ++
    Belt.Int.toString(Belt.Array.length(a.scenes)) ++
    " segments=" ++
    Belt.Int.toString(segCount) ++
    " speech=" ++
    Belt.Int.toString(speech) ++
    " effects=" ++
    Belt.Int.toString(effects) ++
    " stills=" ++
    Belt.Int.toString(stills) ++
    " unresolved-durations=" ++
    Belt.Int.toString(missing.contents),
  )
  if fails.contents == 0 && missing.contents == 0 {
    Js.log("ROUND TRIP OK")
  } else {
    Js.log("ROUND TRIP FAILED: " ++ Belt.Int.toString(fails.contents) ++ " field mismatches")
  }
}

main()
