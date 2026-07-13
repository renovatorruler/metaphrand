/* PSE index — match a scene's ACTION line to the best local recording.
   Each downloaded file carries two sources of searchable text: the pull-list
   QUERY it was fetched under (curated cue phrase, in _manifest.json) and its
   UCS filename description. We stem both and the action line, then score by
   shared words. Returns a file path when a real overlap exists, else None
   (the renderer generates the sound instead). */

@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external existsSync: string => bool = "existsSync"

let dir = "/Users/dusty/SFX/PSE/"
let manPath = dir ++ "_manifest.json"

let stop = [
  "a", "an", "the", "and", "of", "on", "in", "to", "with", "at", "by", "for",
  "into", "over", "out", "off", "as", "it", "its", "one", "two", "some",
  "near", "past", "then", "that", "this", "goe", "come", "run", "sit", "set",
  "work", "hold", "somewher", "behind", "under", "across", "through", "st",
  "ext", "int", "cu", "far", "close", "long", "short", "small", "big",
  /* generic motion/placement words that produce false single-word matches */
  "down", "up", "back", "find", "drop", "turn", "put", "keep", "let", "get",
  "walk", "stop", "look", "twice", "tinny", "whole", "slow", "fast",
  "loud", "soft", "here", "there", "away", "onto", "upon", "desk",
  "side", "end", "top", "bottom", "front", "left", "right", "cold", "warm",
]->Belt.Set.String.fromArray

/* crude stemmer: drop a trailing ing / ed / s so chimes~chime, chanting~chant */
let stem = w => {
  let w = Js.String2.length(w) > 5 && Js.String2.endsWith(w, "ing")
    ? Js.String2.slice(w, ~from=0, ~to_=Js.String2.length(w) - 3)
    : w
  let w = Js.String2.length(w) > 4 && Js.String2.endsWith(w, "ed")
    ? Js.String2.slice(w, ~from=0, ~to_=Js.String2.length(w) - 2)
    : w
  Js.String2.length(w) > 3 && Js.String2.endsWith(w, "s")
    ? Js.String2.slice(w, ~from=0, ~to_=Js.String2.length(w) - 1)
    : w
}

let tokenize = s =>
  s
  ->Js.String2.toLowerCase
  ->Js.String2.replaceByRe(%re("/[^a-z0-9 ]/g"), " ")
  ->Js.String2.split(" ")
  ->Belt.Array.keep(w => Js.String2.length(w) > 2)
  ->Belt.Array.map(stem)
  ->Belt.Array.keep(w => Js.String2.length(w) > 2 && !Belt.Set.String.has(stop, w))

let describe = fname => {
  let noExt = Js.String2.replace(fname, ".wav", "")
  let parts = Js.String2.split(noExt, "_")
  switch Belt.Array.length(parts) {
  | n if n >= 4 => Belt.Array.slice(parts, ~offset=1, ~len=n - 3)->Belt.Array.joinWith(" ", x => x)
  | _ => noExt
  }
}

type entry = {file: string, tokens: Belt.Set.String.t}

/* build entries from the manifest: every file gets tokens from its fetch
   query PLUS its filename description */
let index: Lazy.t<array<entry>> = lazy (
  if !existsSync(manPath) {
    []
  } else {
    let man: Js.Dict.t<array<string>> = Obj.magic(Js.Json.parseExn(readFileSync(manPath, "utf8")))
    let out = []
    Js.Dict.entries(man)->Belt.Array.forEach(((query, files)) => {
      let qtok = tokenize(query)
      files->Belt.Array.forEach(fname => {
        /* the fetcher marks already-present files "<name> (existed)" */
        let full = Js.String2.replace(fname, " (existed)", "")
        let toks = Belt.Array.concat(qtok, tokenize(describe(full)))->Belt.Set.String.fromArray
        Js.Array2.push(out, {file: dir ++ full, tokens: toks})->ignore
      })
    })
    out
  }
)

let match = (actionText: string): option<string> => {
  let want = tokenize(actionText)->Belt.Set.String.fromArray
  let best = ref(None)
  let bestScore = ref(0)
  Lazy.force(index)->Belt.Array.forEach(e => {
    let score = Belt.Set.String.size(Belt.Set.String.intersect(want, e.tokens))
    if score > bestScore.contents {
      bestScore := score
      best := Some(e.file)
    }
  })
  /* one shared content word is enough to prefer a real recording over a
     synthetic guess; zero means truly nothing fits -> generate */
  bestScore.contents >= 1 ? best.contents : None
}
