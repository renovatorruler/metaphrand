/* DENSITY - flesh on the bones, against the shrink-wrap fallacy (port of
   metaphrand/density.py; docs/05 sweep 3). The model's instinct is to stretch
   the thinnest story over exactly the beats it was handed, so every element
   exists only because the plot demanded it. This gate splits scenes into
   BONES (structural function: a spine beat, a doorway) and FLESH (subplot,
   texture, the living world) and names the two tells of a shrink-wrapped
   seed: too little flesh, and declared-but-undramatized wants. The gate only
   names the lack; the flesh itself is grown by the writer. */

type kind = Bone | Flesh

type report = {
  total: int,
  bones: int,
  undramatizedWants: array<string>, /* cast given a want but never a beat */
  minFlesh: float,
  minFleshCount: int,
}

let flesh = (r: report) => r.total - r.bones

let fleshRatio = (r: report) =>
  r.total == 0 ? 0.0 : Belt.Int.toFloat(flesh(r)) /. Belt.Int.toFloat(r.total)

let shrinkWrapped = (r: report) => flesh(r) < r.minFleshCount || fleshRatio(r) < r.minFlesh

/* Both tells fail: too little flesh, and a cast member handed a want they
   never get a beat to pursue (set dressing for the hero's line). */
let passed = (r: report) => !shrinkWrapped(r) && Belt.Array.length(r.undramatizedWants) == 0

let summary = (r: report): string => {
  let head =
    Belt.Int.toString(flesh(r)) ++
    "/" ++
    Belt.Int.toString(r.total) ++
    " scenes are flesh (" ++
    Js.Float.toFixedWithPrecision(fleshRatio(r) *. 100.0, ~digits=0) ++ "%)"
  let notes = []
  if shrinkWrapped(r) {
    Js.Array2.push(notes, "shrink-wrapped (almost all bone)")->ignore
  }
  if Belt.Array.length(r.undramatizedWants) > 0 {
    Js.Array2.push(notes, "undramatized wants: " ++ r.undramatizedWants->Belt.Array.joinWith(", ", x => x))->ignore
  }
  Belt.Array.length(notes) == 0
    ? head ++ ", world has its own life"
    : head ++ "; " ++ notes->Belt.Array.joinWith("; ", x => x)
}

/* scenes: (id, kind) in order. wants: (characterName, hasABeatOfTheirOwn). */
let audit = (
  ~scenes: array<(string, kind)>,
  ~wants: array<(string, bool)>=[],
  ~minFlesh: float=0.33,
  ~minFleshCount: int=2,
): report => {
  let bones = scenes->Belt.Array.keep(((_, k)) => k == Bone)->Belt.Array.length
  let undramatized = wants->Belt.Array.keepMap(((name, dramatized)) => dramatized ? None : Some(name))
  {
    total: Belt.Array.length(scenes),
    bones: bones,
    undramatizedWants: undramatized,
    minFlesh: minFlesh,
    minFleshCount: minFleshCount,
  }
}
