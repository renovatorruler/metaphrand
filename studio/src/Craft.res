type violation = {device: string, evidence: string}

let show = v => v.device ++ ": \"" ++ v.evidence ++ "\""

/* (device, regex). One exec gives us a concrete snippet of evidence. */
let actionRes = [
  ("em-dash (narration)", %re("/—/")),
  ("colon-reveal", %re("/[a-z]:\s/")),
  ("rule-of-three", %re("/,\s+\w+,\s+\w+[.!?]/")),
  ("negative-parallelism", %re("/not (just|only) .+?(it's|its|but)/i")),
  ("antithesis-instruction", %re("/\byou (don'?t|do not)\b[^,.!?]{3,45},\s*you\b/i")),
  ("corrective-definition", %re("/that'?s not .+?[,.]\s*that'?s/i")),
  ("copula-inflation", %re("/(serves as|stands as|a testament to|is a testament|marks a )/i")),
]

/* Dialogue gets the antithesis family too — a real person doesn't talk in
   "you don't X, you Y" / "not just X but Y" / "that's not X, that's Y". */
let dialogueRes = [
  ("negative-parallelism", %re("/not (just|only) .+?(it's|its|but)/i")),
  ("antithesis-instruction", %re("/\byou (don'?t|do not)\b[^,.!?]{3,45},\s*you\b/i")),
  ("corrective-definition", %re("/that'?s not .+?[,.]\s*that'?s/i")),
  ("rule-of-three", %re("/,\s+\w+,\s+\w+[.!?]/")),
  /* NOTE: manufactured false-start stammers ("That was, he just, that was clean.") and
     summarizing "Lines" are judgment-level — enforced via DIALOGUE_DOCTRINE.md's
     "Tells that keep slipping through", applied by the lift, not a regex. */
]

let runRe = (text, device, re) =>
  switch Js.Re.exec_(re, text) {
  | Some(res) =>
    let ev =
      Js.Re.captures(res)
      ->Belt.Array.get(0)
      ->Belt.Option.flatMap(Js.Nullable.toOption)
      ->Belt.Option.getWithDefault("(matched)")
    Some({device, evidence: ev})
  | None => None
  }

/* one-word "sentences" — the clipped fragment cadence ("Holds there." catches as
   two words and is left to judgment; bare "Unbothered." is mechanical). */
let fragments = text =>
  Js.String2.splitByRe(text, %re("/[.!?]+/"))
  ->Belt.Array.keepMap(x => x)
  ->Belt.Array.keepMap(s => {
    let t = Js.String2.trim(s)
    let words = t == "" ? [] : Js.String2.splitByRe(t, %re("/\s+/"))->Belt.Array.keepMap(x => x)
    Belt.Array.length(words) == 1 && Js.Re.test_(%re("/^[A-Za-z']+$/"), t)
      ? Some({device: "clipped-fragment", evidence: t})
      : None
  })

let collect = (text, res, withFragments) => {
  let fromRe = res->Belt.Array.keepMap(((device, re)) => runRe(text, device, re))
  let all = withFragments ? Belt.Array.concat(fromRe, fragments(text)) : fromRe
  Belt.Array.length(all) == 0 ? Ok() : Error(all)
}

let gateAction = text => collect(text, actionRes, true)
let gateDialogue = text => collect(text, dialogueRes, false)

/* ---- flat-echo (cross-line) --------------------------------------------- */
/* BANNED: speaker B merely repeats speaker A's words AND the line ends in a period
   — a flat, dead repetition. ALLOWED when it CHANGES something: B becomes a QUESTION
   ("I am the danger." -> "You're the danger?"), a DECLARATION with a bang ("The
   danger!"), or B ANSWERS a question A asked ("Start him Monday?" -> "Monday.").
   One-word back-channels (yeah/okay/right/...) are not content echoes. */
let backchannel = [
  "yeah", "yea", "yes", "yep", "yup", "no", "nope", "nah", "ok", "okay", "right",
  "sure", "uh", "um", "mm", "hm", "huh", "fine", "well",
]

let normWords = (t: string): array<string> =>
  t
  ->Js.String2.toLowerCase
  ->Js.String2.replaceByRe(%re("/[^a-z0-9 ]/g"), " ")
  ->Js.String2.split(" ")
  ->Belt.Array.keep(w => w != "")

/* is b's whole word-sequence a contiguous run inside a? (b repeats a) */
let containsRun = (a: array<string>, b: array<string>): bool => {
  let la = Belt.Array.length(a)
  let lb = Belt.Array.length(b)
  if lb == 0 || lb > la {
    false
  } else {
    let found = ref(false)
    for i in 0 to la - lb {
      if !found.contents {
        let ok = ref(true)
        for j in 0 to lb - 1 {
          if Belt.Array.getExn(a, i + j) != Belt.Array.getExn(b, j) {
            ok := false
          }
        }
        if ok.contents {
          found := true
        }
      }
    }
    found.contents
  }
}

let echoViolation = (~prev: string, ~cur: string): option<violation> => {
  let a = Js.String2.trim(prev)
  let b = Js.String2.trim(cur)
  let bTransforms = Js.Re.test_(%re("/[?!]\s*$/"), b) // B is itself a question or exclamation
  let aIsQuestion = Js.Re.test_(%re("/\?\s*$/"), a) // Q&A: A asked, B answers
  let bw = normWords(b)
  let aw = normWords(a)
  let isBackchannel =
    Belt.Array.length(bw) == 1 && Belt.Array.some(backchannel, w => w == Belt.Array.getExn(bw, 0))
  if !bTransforms && !aIsQuestion && !isBackchannel && Belt.Array.length(bw) > 0 && containsRun(aw, bw) {
    Some({device: "flat-echo (repeats prior line + ends in period; make it a question/!, or cut)", evidence: b})
  } else {
    None
  }
}
