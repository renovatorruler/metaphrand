# Drama Gates — Ground Truth, the Typed Spine, and the Scene Card

*The conception layer. `01-STORY_FRAMEWORK.md` gives the order of development; `07-SCENE-CRAFT.md`
judges scenes after they are written. This doc governs what may be written at all: the artifacts
that must exist before beats, the causality a spine must carry, the telemetry that catches a story
going safe, and the card a scene must present before prose. Enforced by `studio/src/DramaCards.res`
(typed — an incomplete artifact does not compile) and `studio/src/DramaGate.res` (blocks).*

## The thesis

A writers' room does not trust the writer. It trusts **the board** — quality lives in required
artifacts and stage gates, not in anyone's memory of principles (Grillo-Marxuach, "The Eleven Laws
of Showrunning": the story exists in six artifact states, and notes at each state are given against
the *anterior* artifact). Two consequences, both laws here:

1. **Notes run against the anterior artifact, never against the previous draft of the same
   artifact.** Scenes are judged against the spine, the spine against the ground truth. This kills
   the self-referential failure — designing against one's own last draft until the fixes only make
   sense to one's past self.
2. **Stage rubrics.** The board is judged on causation and stakes ONLY; outlines are never read
   with line-level critics; line passes are fenced behind structure approval (the two batteries of
   `05-PASSES.md` are this law's downstream half).

## Layer A — the ground truth (required before any beats)

Every item is a typed field. Revision diffs against THESE, forever.

- **Premise** (Egri) — a provable proposition in strict grammar: *X leads to Y* ("Frugality leads
  to waste"). The final beat must state Y as a demonstrated consequence of X. Abstract-noun themes
  ("brotherhood") do not parse.
- **Central dramatic argument** (Mazin, Scriptnotes 403) — an arguable claim **plus its
  antithesis**, both fields required: "structure is a symptom of a character's relationship with a
  central dramatic argument." Somewhere the antithesis must get its best case; the hero answers by
  action, never narration.
- **Designing principle** (Truby) — the one-line strategy that makes this telling original. Test:
  strip the proper nouns; if the sentence fits any competent genre entry, it isn't one.
- **The lighthouse scene** (Gilroy, BAFTA) — the one scene "where what the movie's about and this
  sort of lighthouse kind of scene co-exist together," written FIRST, in prose, before structure.
  Every later scene is checked for consanguinity against it. It doubles as the signature seed.
- **Authorial stake** (Kaufman, BAFTA) — what this story risks saying that a safe version wouldn't.
  Signature is a seed-time property; no finishing pass can add it.
- **The contested object** (Truby) — the ONE thing hero and opponent are both fighting for, stated
  so both cannot have it: "if they have two separate goals, each can get what he wants... and you
  have no story." Mutually satisfiable goals = no climax = build error.
- **The opponent's plan** (Truby step 11; Hitchcock: "the more successful the villain, the more
  successful the picture") — the antagonist's campaign as steps that succeed *absent the hero*.
  A villain who only reacts is the hero being kept safe.
- **The parable check** (user law, 2026-07-15 — two dead pitches in one day): a story built to
  demonstrate its argument is an explainer at story altitude; the theme's victory is foreordained
  and the audience smells the teleology. THE ARGUMENT MUST BE ABLE TO LOSE — the antithesis wins
  real ground at real cost somewhere in the spine, and the ending costs the thesis something true.
  If every beat serves the demonstration, the premise is a brochure. Companions: the arena takes
  one entropy perturbation off-mode before encoding (the first setting that comes to mind IS the
  mode), and stakes are denominated in PEOPLE — belonging, standing, the ability to stop — never
  in the mechanism (structure gates cannot smell what stakes are made of).

## Layer B — the spine (causality as a type)

The beat graph's edge is an enum with two constructors — **BUT | THEREFORE** (Parker/Stone: if
"and then" fits between two beats, "you're fucked"). AND-THEN has no representation: a beat pair
whose only honest label is "and then" has no legal encoding — delete or rewrite the beat. The edge
label is a *claim*; encoding one dishonestly is lying to the compiler, and the read-back check is
exactly the Breaking Bad corkboard interrogation, per beat: *what is the POV character trying to
get, and what stands against it?* Both fields required on every beat.

Each beat also declares its **proximate cause** — protagonist choice, antagonist action, third
party, or coincidence. Coincidence is directional (Pixar rule 19): luck may get characters INTO
trouble, never out. A luck-caused improvement in fortune is a gate failure.

Each beat throws a **forward question** (Scriptnotes 532) — what the audience is now waiting to
see answered.

## Layer C — escalation telemetry (the flinch instruments)

Safe-hero syndrome is not a taste call; it is a set of measurable curve properties. Per beat, two
integers:

- **fortune** (Vonnegut's G–I axis, −5..+5): the curve must not be flat (variance minimum), and
  its global minimum must land late (the all-is-lost exists, near the second doorway).
- **stakes** (magnitude at risk, 1..10): non-decreasing — McKee's progressive complications
  "must not retreat to actions of lesser quality or magnitude." A stakes dip is a build error,
  and draft N+1's max may never sink below draft N's (stakes-shrink is a regression, not a note).

Plus the **climax roll-call** (McKee's Principle of Antagonism — the hero's ceiling is SET by the
antagonist): the climax beat must carry the antagonist *present and acting*. Absence is a build
error, not a style note. And a **passivity census**: if too few beats are caused by protagonist
choice, the hero is a passenger; if the antagonist acts in too few, the villain is furniture.

The generative counter when the curve reads safe (Vonnegut rule 6; Mazin): *"What would be the
meanest thing I could do to her right now? What would be the worst way to do the meanest thing
right now? Then do it."*

## Layer D — the scene card (before a scene is drafted)

Four masters, one invariant, one schema. Mamet's litmus ("WHO WANTS WHAT? WHAT HAPPENS IF THEY
DON'T GET IT? WHY NOW?"), Sorkin's drive shaft (intention + a formidable obstacle), Mazin's
dialectic (a truth in, a different truth out), McKee's value turn (a charge must flip or the scene
is a nonevent). A scene presents its card before prose exists; an incomplete card does not
compile.

Fields: `want` (who wants what from whom) · `wall` (what stands against it — formidable: it could
win) · `cost` (named consequence of failure — "things stay awkward" is generic and blocks) ·
`clock` (why now) · `truthIn / truthOut` (must differ) · `value + chargeIn / chargeOut` (must
flip) · `audienceDelta` (Hitchcock's ledger: what the audience knows now that it didn't — each
danger tagged *suspense*, shown early with a clock, or *twist*, the reveal itself the payoff) ·
`forward` (the question thrown).

The card gates whether the scene may be written; the Mercurio rubric (`07`) judges what got
written. Same scene, two gates, different moments.

## Not in this doc (handled elsewhere)

Voice and idiom — `03/04` + the blind-attribution gate. Line-level prose law — `05/06` and the
skills (humanizer, clear-pane, drama-enhancer as the *advisory* form of Layer D). Scene-as-written
judgment — `07`. Casting off the mode, natal charts — the entropy engine and `04`.

## How it runs

`DramaCards.res` holds the types: ground truth, spine (opening beat + edged beats), scene cards.
The spine of a story is encoded as data (`<Story>_Spine.res`); `DramaGate.res` walks it and
blocks on: malformed premise, missing antithesis, mutually satisfiable goals, opponent plan under
three steps, flat fortune curve, early minimum, stakes retreat, luck-caused rescue, climax without
the antagonist acting, thin fields. Warns on: passivity census, low BUT density (all-therefore =
no reversals), unanswered forward questions. The human is the stop.

## Credit & sources

David Mamet (memo to the writers of *The Unit*); Aaron Sorkin (MasterClass, intention & obstacle);
Craig Mazin (Scriptnotes 403, central dramatic argument; 450; 532); Robert McKee (*Story* — value
turn, the Gap, progressive complications, Principle of Antagonism); Lajos Egri (*The Art of
Dramatic Writing* — premise, orchestration, unity of opposites); John Truby (*The Anatomy of
Story* — contested object, opponent's plan, character web); Trey Parker & Matt Stone (NYU,
but/therefore); Dan Harmon (Story Circle); Kurt Vonnegut (shapes of stories; "be a sadist");
Blake Snyder (*Save the Cat* — landmark assertions only); Tony Gilroy (BAFTA lecture — the
lighthouse scene, no tuxedo until the end); Charlie Kaufman (BAFTA lecture — the authorial
stake); Alfred Hitchcock (Truffaut interviews — the bomb under the table); Javier
Grillo-Marxuach ("The Eleven Laws of Showrunning" — anterior artifacts, stage rubrics); Emma
Coats (Pixar's 22 rules). Re-expressed as working rules; none of the sources are reproduced.
