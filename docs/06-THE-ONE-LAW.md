# The One Law

**Every line must read exactly as a real person would say or write it, in that moment. Nothing
may be arranged for effect.**

That is the whole law. It governs all prose and all dialogue, in any language.

## Why one law and not a list

Every AI writing tell is the same flaw wearing different clothes — language *shaped to land*
instead of *said plainly*:

- the two-word punch sentence — *"Cold."*
- the staccato run — *"The room was empty. Cold. Just three chairs."*
- the fact-recitation — *"छब्बीस की रात। पौने दस बजे।"*
- the balanced antithesis — *"He didn't have a plan. He had a problem."*
- the held-to-the-end punch — *"मुझे गुड़िया चाहिए, ज़िंदा।"*
- the end-loaded detail — the key fact tacked on after a pause, by comma-tail or fragment: *"...देखी गई थी, पौने दस बजे, तेरे साथ।"* / *"...छोड़ा था, मैडम। आनंद विहार।"* (the comma-tail is the fragment-tail in disguise)
- the composed pathos — *"यहाँ बस मैं हूँ, और बाहर वो औरत जो तीन रात से सोई नहीं।"*
- the clickbait cadence where every sentence begs you to read the next.

Cataloguing these and writing a rule for each is whack-a-mole: there is an infinite tail of ways
to be composed, and a rule-list will forever miss the next one. **The Law subsumes them all,
including the ones nobody has named yet.** When a new tell appears, it is not a new rule — it is
the Law, broken in a new way.

## The test

Read the line aloud *as that person, in that moment.* If it sounds composed — if it sounds like
**writing** — it is wrong, however good it sounds. *Good-sounding is the trap.* The instinct that
makes a line elegant is the same instinct that makes it false. Plainness over elegance, always.

## How it is enforced (two layers)

1. **craftlint** (`metaphrand/craftlint.py`) — the **mechanical floor**. Deterministic detection of
   the enumerable tells (em-dash density, banned phrases, obvious two-word punches in narration).
   Necessary, never sufficient. **Do not keep growing it** to chase the tail; that is the mistake.
2. **the naturalness gate** (`metaphrand/naturalness.py`) — the **ceiling**. A model running as a
   *harsh editor, not a generator* applies the Law to every line and flags whatever is arranged for
   effect, writing a per-line audit to `<story>/.passes/`. This is the layer that catches the tail.

The gate is imperfect — an AI judging AI-composed prose can excuse what it would itself write — so
the author's ear is the final calibration, and every line the author flags is added here as a
training example. But the Law itself is not negotiable, and it is not "extra rules." It is *the*
rule, and the catalogue above exists only to teach it, never to replace it.
