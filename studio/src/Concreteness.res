/* CONCRETENESS - the anti-ornament layer (port of metaphrand/concreteness.py;
   docs/02 SS2, docs/05 sweep 8). Every manifestation is already a metaphor;
   the sin is not having metaphors, it is DECORATING them. A manifestation must
   be a bare physical fact ("Her skin is cold"), never ornament ("the glass
   bleeds rainbows"). Deliberately lexical and conservative: catches the
   obvious crimes without false-flagging plain prose. */

let purple = Belt.Set.String.fromArray([
  "bleed", "bleeds", "bled", "bleeding",
  "bloom", "blooms", "bloomed", "blooming",
  "shimmer", "shimmers", "shimmered", "shimmering",
  "glisten", "glistens", "glistened", "glistening",
  "glimmer", "glimmers", "glimmered", "glimmering",
  "weep", "weeps", "wept", "weeping",
  "thrum", "thrums", "thrummed", "thrumming",
  "sing", "sings", "sang", "singing",
  "breathe", "breathes", "breathed", "breathing",
  "whisper", "whispers", "whispered", "whispering",
  "murmur", "murmurs", "murmured", "murmuring",
  "dance", "dances", "danced", "dancing",
  "caress", "caresses", "caressed", "caressing",
  "devour", "devours", "devoured", "devouring",
])

let abstract = Belt.Set.String.fromArray([
  "refusal", "betrayal", "guilt", "fate", "destiny", "sorrow", "despair",
  "longing", "oblivion", "eternity", "soul", "redemption", "salvation",
  "innocence", "abyss", "void", "doom", "anguish", "yearning", "essence",
])

let likeRe = %re("/\blike\b/i")
let asAsRe = %re("/\bas\b\s+\w+\s+\bas\b/i")
let emphasisRe = %re("/\*[^*]+\*/")
let wordRe = %re("/[a-z]+/g")

type finding =
  | Simile(string)
  | PurpleVerb(string)
  | Abstract(string)
  | Emphasis

let show = f =>
  switch f {
  | Simile(s) => "simile: " ++ s
  | PurpleVerb(w) => "purple-verb: " ++ w
  | Abstract(w) => "abstract: " ++ w
  | Emphasis => "emphasis: *...*"
  }

/* every ornamental crime in text (empty == bare/concrete) */
let findings = (text: string): array<finding> => {
  let out = []
  switch Js.Re.exec_(asAsRe, text) {
  | Some(m) =>
    switch Js.Re.captures(m)->Belt.Array.get(0)->Belt.Option.flatMap(Js.Nullable.toOption) {
    | Some(s) => Js.Array2.push(out, Simile(s))->ignore
    | None => ()
    }
  | None =>
    if Js.Re.test_(likeRe, text) {
      Js.Array2.push(out, Simile("like"))->ignore
    }
  }
  let lower = Js.String2.toLowerCase(text)
  let go = ref(true)
  while go.contents {
    switch Js.Re.exec_(wordRe, lower) {
    | Some(m) =>
      switch Js.Re.captures(m)->Belt.Array.get(0)->Belt.Option.flatMap(Js.Nullable.toOption) {
      | Some(w) =>
        if Belt.Set.String.has(purple, w) {
          Js.Array2.push(out, PurpleVerb(w))->ignore
        } else if Belt.Set.String.has(abstract, w) {
          Js.Array2.push(out, Abstract(w))->ignore
        }
      | None => ()
      }
    | None => go := false
    }
  }
  if Js.Re.test_(emphasisRe, text) {
    Js.Array2.push(out, Emphasis)->ignore
  }
  out
}

let isFlowery = (text: string): bool => Belt.Array.length(findings(text)) > 0

/* 0.0-1.0: 1.0 is bare fact; each crime costs about a third */
let score = (text: string): float =>
  Js.String2.trim(text) == ""
    ? 1.0
    : Js.Math.max_float(0.0, 1.0 -. 0.34 *. Belt.Int.toFloat(Belt.Array.length(findings(text))))
