/* ============================================================================
   Gate — the deterministic floor.

   Every assumption lives here, in the types, where the compiler enforces it.
   A violation is a build error, not a bad habit.
   ============================================================================ */

/* Unverified text from the outside world. */
type rawText
let raw: string => rawText
let read: rawText => string

@unboxed type lineNo = LineNo(int)
@unboxed type slopWord = SlopWord(string)

/* The KIND of violation, captured in the type, never a string. The compiler
   knows every case exhaustively, so a finding can't carry a bogus or unhandled
   kind and no consumer can forget to handle one. */
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

/* `clean` is ABSTRACT: outside this module there is no constructor for it. The
   only way to hold one is to run `craftlint` and get Ok. Parse, don't validate —
   the proof that the text passed rides inside its type. */
type clean
let craftlint: rawText => result<clean, array<finding>>
let cleanText: clean => string

/* The one place a violation becomes a human-readable line, derived from the type. */
let describe: violation => string
