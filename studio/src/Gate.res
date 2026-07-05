type rawText = RawText(string)
let raw = s => RawText(s)
let read = (RawText(s)) => s

@unboxed type lineNo = LineNo(int)
@unboxed type slopWord = SlopWord(string)

/* The KIND of violation, captured in the type — not a string. The compiler knows
   every case, so a finding can never carry a bogus or unhandled rule, and every
   consumer must handle each kind. */
type violation =
  | EmDash
  | FragmentAppend
  | CurlyQuote
  | AiVocab(slopWord)
  | NegativeParallelism
  | CopulaDodge
  | Emoji
  | CommaDrip          // model-judged (the Judge, not the mechanical floor)
  | ForcedTriad        // model-judged
  | ArrangedForEffect  // model-judged

type finding = {line: lineNo, violation: violation}

/* The hidden constructor. Because `clean` is abstract in Gate.resi, only the
   code in THIS file can build a `Clean(...)`. Nobody downstream can fake one. */
type clean = Clean(string)
let cleanText = (Clean(s)) => s

/* --- the mechanical floor: pure pattern-matching, no model, free ----------- */

let flag = (v: violation): array<finding> => [{line: LineNo(0), violation: v}]

let emDash = (s): array<finding> => Js.String2.includes(s, "—") ? flag(EmDash) : []

/* words in a fragment: split on spaces, drop the empties. */
let wordCount = (fragment: string): int => {
  let t = Js.String2.trim(fragment)
  t == "" ? 0 : Js.Array2.filter(Js.String2.split(t, " "), w => w != "")->Array.length
}

/* "Four of them. Monkeys. African. Black." — three or more clipped one/two-word
   sentences in a row: information rationed into fragments for effect. */
let fragmentAppend = (s): array<finding> => {
  let (worst, _) = Belt.Array.reduce(Js.String2.split(s, "."), (0, 0), ((worst, run), sentence) => {
    let next = {
      let w = wordCount(sentence)
      w >= 1 && w <= 2 ? run + 1 : 0
    }
    (Js.Math.max_int(worst, next), next)
  })
  worst >= 3 ? flag(FragmentAppend) : []
}

/* AI loves smart quotes; clean prose uses straight ones. */
let curlyQuotes = (s): array<finding> =>
  Js.Array2.some(["“", "”", "‘", "’"], q => Js.String2.includes(s, q)) ? flag(CurlyQuote) : []

/* The AI-vocabulary slop words you never want on the page (stems, so plurals and
   -ing forms are caught too). */
let aiSlopWords = ["testament", "tapestry", "underscore", "showcas", "nestl", "boast", "vibrant", "delv", "pivotal", "intricate", "myriad", "bustling"]
let aiVocab = (s): array<finding> => {
  let lower = Js.String2.toLowerCase(s)
  switch Js.Array2.find(aiSlopWords, w => Js.String2.includes(lower, w)) {
  | Some(w) => flag(AiVocab(SlopWord(w)))
  | None => []
  }
}

/* "It's not just a market, it's a way of life." — the not-just / not-only flip. */
let negativeParallelism = (s): array<finding> => {
  let lower = Js.String2.toLowerCase(s)
  Js.String2.includes(lower, "not just") ||
  Js.String2.includes(lower, "isn't just") ||
  Js.String2.includes(lower, "not only")
    ? flag(NegativeParallelism)
    : []
}

/* "stands as / serves as a testament" — the AI dodge around a plain "is". */
let copulaDodge = (s): array<finding> => {
  let lower = Js.String2.toLowerCase(s)
  Js.Array2.some(
    ["stands as a", "stands as an", "serves as a", "serves as an", "serving as a", "stand as a"],
    p => Js.String2.includes(lower, p),
  )
    ? flag(CopulaDodge)
    : []
}

/* Decorative emoji: a formatting tell with no business in prose. */
let emojis = ["🚀", "💡", "✅", "🔥", "✨", "🎯", "📊", "👇", "🌟", "💪", "🙌", "❌"]
let emoji = (s): array<finding> =>
  Js.Array2.some(emojis, e => Js.String2.includes(s, e)) ? flag(Emoji) : []

/* `clean` is ABSTRACT: the only way to hold one is to pass every check above.
   Parse, don't validate — the proof rides inside the type. */
let craftlint = (RawText(s)): result<clean, array<finding>> => {
  let findings = Belt.Array.concatMany([
    emDash(s),
    fragmentAppend(s),
    curlyQuotes(s),
    aiVocab(s),
    negativeParallelism(s),
    copulaDodge(s),
    emoji(s),
  ])
  Array.length(findings) == 0 ? Ok(Clean(s)) : Error(findings)
}

/* The ONE place a human-readable message lives — derived FROM the violation. */
let describe = (v: violation): string =>
  switch v {
  | EmDash => "em-dash"
  | FragmentAppend => "fragment-append (clipped one/two-word sentences in a row)"
  | CurlyQuote => "curly quotes (use straight ones)"
  | AiVocab(SlopWord(w)) => "AI-slop word (" ++ w ++ ")"
  | NegativeParallelism => "negative-parallelism (not just / not only ...)"
  | CopulaDodge => "copula-dodge (stands/serves as a ... instead of 'is')"
  | Emoji => "decorative emoji"
  | CommaDrip => "comma-drip (comma fragments rationed for suspense)"
  | ForcedTriad => "forced triad (three items padded for rhythm)"
  | ArrangedForEffect => "arranged for effect (bent for impact, not stated plainly)"
  }
