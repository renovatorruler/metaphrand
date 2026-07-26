/* SHOWING - detect telling, so it can be traded for showing (port of
   metaphrand/showing.py; docs/05 sweep 8). A told claim ("he was brave",
   "she felt jealous") asks the reader to take the writer's word for it.
   Deterministic and lexical: interiority verbs, linking-verb-plus-trait,
   summary constructions. Over-flagging is triage - free indirect and
   competence-knowing are judged in context (docs/05 SS8 legal list);
   dialogue is exempt (people say "I thought"). */

let interiority = Belt.Set.String.fromArray([
  "knew", "know", "knows", "felt", "feels", "feel", "realized", "realised",
  "realize", "realizes", "understood", "understands", "understand", "sensed",
  "senses", "wanted", "wants", "decided", "decides", "remembered", "remembers",
  "believed", "believes", "hoped", "hopes", "feared", "fears", "wondered",
  "wonders", "recognized", "recognised", "thought", "thinks",
])

let traits = "brave|cowardly|coward|scared|afraid|fearful|jealous|envious|angry|furious|sad|happy|proud|ashamed|lonely|nervous|anxious|calm|kind|cruel|smart|clever|stupid|strong|weak|confident|shy|bitter|miserable|desperate|hopeful|terrified|embarrassed|guilty|restless|ruthless|gentle|fierce|content"

let stateRe = Js.Re.fromStringWithFlags(
  "\\b(?:was|were|is|are|been|seemed|seems|looked|looks|appeared|appears|became|becomes|grew)\\b(?:\\s+\\w+){0,2}?\\s+\\b(?:" ++
  traits ++ ")\\b",
  ~flags="i",
)
let summaryRe = %re("/\bthere (?:was|were|is|are) no [\w-]+ing\b|\bthe (?:truth|fact) (?:was|is)\b/i")
let wordRe = %re("/[a-z']+/g")

type tell =
  | Interiority(string) /* narrating the inside of a head */
  | State(string) /* linking verb + trait: "was brave" */
  | Summary(string) /* "there was no out-arguing him" */

let show = t =>
  switch t {
  | Interiority(w) => "interiority: " ++ w
  | State(s) => "state: " ++ s
  | Summary(s) => "summary: " ++ s
  }

/* every place text tells instead of shows (empty == it shows) */
let tells = (text: string): array<tell> => {
  let out = []
  let lower = Js.String2.toLowerCase(text)
  let go = ref(true)
  while go.contents {
    switch Js.Re.exec_(wordRe, lower) {
    | Some(m) =>
      switch Js.Re.captures(m)->Belt.Array.get(0)->Belt.Option.flatMap(Js.Nullable.toOption) {
      | Some(w) =>
        if Belt.Set.String.has(interiority, w) {
          Js.Array2.push(out, Interiority(w))->ignore
        }
      | None => ()
      }
    | None => go := false
    }
  }
  switch Js.Re.exec_(stateRe, text) {
  | Some(m) =>
    switch Js.Re.captures(m)->Belt.Array.get(0)->Belt.Option.flatMap(Js.Nullable.toOption) {
    | Some(s) => Js.Array2.push(out, State(Js.String2.trim(s)))->ignore
    | None => ()
    }
  | None => ()
  }
  switch Js.Re.exec_(summaryRe, text) {
  | Some(m) =>
    switch Js.Re.captures(m)->Belt.Array.get(0)->Belt.Option.flatMap(Js.Nullable.toOption) {
    | Some(s) => Js.Array2.push(out, Summary(s))->ignore
    | None => ()
    }
  | None => ()
  }
  out
}

let isTelling = (text: string): bool => Belt.Array.length(tells(text)) > 0

/* 1.0 = it shows; each tell costs about a third */
let showScore = (text: string): float =>
  Js.String2.trim(text) == ""
    ? 1.0
    : Js.Math.max_float(0.0, 1.0 -. 0.34 *. Belt.Int.toFloat(Belt.Array.length(tells(text))))
