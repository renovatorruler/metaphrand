# The Pass Manifest — every sweep a chapter must survive

The canonical checklist. Loop prompts BIND to this file instead of half-remembering it;
when a pass evolves, it evolves here. Detail lives in the cited docs/modules; this page
is the law in one line each. Order matters: structure → flesh → feeling → surface.

## Per-work (run once, before drafting)
1. **Promise** — the opening makes the contract (en-medias-res or Godfather-style; a shard of the destination or the storm). No valid story opens without one.
2. **Clock** — a named doom with shrinking distance, visible early (Registration Day → transfers → the seal).
3. **Antagonist with agency** — a face that wants the protagonist's world unmade and acts on it; the engine's recurring shape is love-as-erasure (the Settling, the Sealing, the Sort). Institutions get lanyards, not fogs.
4. **Doorways** — Act 1 and Act 2 breaks present and in order (`metaphrand/doorways.py`).
5. **Transformation** — tested, never declared; the mirror moment placed (framework: `docs/01`).
6. **Weave law** — every principal carries ≥2 plot-causal edges; every cost arrives along a built edge; deliberate single-edge texture is chosen, not leaked (THE HEIR plotline-v4 §ledger is the worked example).
7. **Iceberg backstories** — every named character gets backstory that INFORMS and is never stated (spec §8) + natal chart + voice card + a distinct dialogue ARCHITECTURE (docs/04; the voice-differentiation law: no shared nervous system). **ENFORCED, not remembered:** the chart + voice-card artifacts (`CHARTS.md`, `VOICE_CARDS.md`, one entry per cast member) are required by `metaphrand/preflight.py`, which `Project.build_*` calls — production hard-stops while they're missing. A required pass with no gate gets skipped (we skipped this for AMAL and drafted on top of it); the gate makes the skip impossible. Build the chart FIRST — it generates the voice.
8. **Arena rules** — how the world actually works, written down before scenes need it (the Karash model; bible §arena).

## Per-chapter / per-scene (the sweep stack, in order)
0. **LAYER CARD FIRST (user law, 2026-06-10):** every chapter has a recorded card in
   `stories/<work>/LAYERS.md` — pure PaRDeS, written as CONTRACTS, no extra fields: **Peshat** is
   the plain sense of the page *including its silences* (two registers: *shows* / *withholds* —
   the withheld is as binding as the shown); **Remez** states the hint AND the condition keeping it
   felt-not-stated; **Derash** is the sermon the chapter aims (an added beat serving a different
   sermon is wrong even if it's good); **Sod** is off-page by definition — voicing it is the
   violation. BEFORE any edit touches a scene: read the card; the edit must keep every *shows*,
   add nothing to a *withholds*, keep the Remez unstated, serve the Derash, leave the Sod unvoiced.
   Soul-loss happens at the structure layer — the prose sweeps below cannot catch it. (Born from
   INDIVISIBLE ch.1: prose-legal edits put the hidden man on the page; the concealment WAS the
   Peshat.) New chapters get their card before drafting; changing a card is a named design
   decision, never an edit's side effect.
1. **Drama (Mamet)** — who wants what from whom / what it costs / why now, every scene; a scene without an engine is a postcard (`metaphrand/drama.py`).
2. **Heart (the emotion pass)** — bonds as ledgers (`metaphrand/heart.py`, OPT-OUT): deposits banked early, in passing, in scenes about something else; wounds need prior deposits; thaws SPEND deposits — *you cannot argue someone warm*; cold blocks plot, thaws unlock it; deposits can SOUR (re-keyed by new knowledge); tragedy's move is the ALMOST-THAW (loses by one vote). ≥1 deposit scene per act. **Kindness must be PRICED (user law, 2026-06-10): a kindness that costs nothing characterizes nothing — save-the-cat only works under fire; the character must visibly pay for the mercy (fuel, time, risk, margin) and the bill must arrive ON PAGE.** (The model: Ray's free dog = two gallons = the dead-stick glide home.)
3. **Shrinkwrap / density (the flesh pass)** — the world lives its own business beside the spine (`metaphrand/density.py`): flesh beats that serve no structural function, cast wants dramatized not listed; no bone-only stretches. If the scene reads like a synopsis wearing dialogue, it's still shrink-wrapped. **The Grace rule (user law, 2026-06-10): no flat bigots — when a scene plays as racism/exclusion and opens a thread, give it a second, specific, private cause that re-keys the scene later; the veneer stays true for the character who reads it, the world stays more specific than the read.**
4. **PaRDeS + sermon discipline** — Peshat clean and self-sufficient; Remez felt, never stated; Derash aimed; **Sod stays OFF the page** (a leaked Sod kills the reveal; nobody names the theme; the flag never waves) (docs/03 §3).
5. **Voice (prose)** — Leonard: if it sounds like writing, cut it; the narrator wears the POV character's grain (docs/03 §§0–2).
6. **Voice (dialogue)** — per-character architecture held (plain-complete default; fragments only when motivated; ration the epigram to ~1 per character per act); dialogue realism: real speech is messy, halting, inarticulate about pain (Lonergan/Baker/Leigh compass); blind-attribution must sort the lines. **World-true language over comfort (user law, 2026-06-10): period and faction speech keeps its ugliness — villains talk like their world, sparingly enough to shock — while the narration never borrows it.**
7. **Momentum + modulation** — never close a loop without opening a bigger one; dread > surprise; end scenes on the turn; THEN the counterweight: octane fatigue is real — valleys after peaks, release ≠ resolution, change the color of tension; the bonding work happens in the valleys (docs/03 §5).
8. **Show-don't-tell + concreteness + embodiment** — no interiority labels, 0% flowery (`metaphrand/showing.py`, `concreteness.py`); every metaphor concrete AND carrying one legible meaning at core-story altitude (embodiment: concrete is necessary, not sufficient).
    **The sweep is RUN at assembly, not remembered (user law, 2026-06-10):** `showing.py` gates the SEED only; the finished text gets its own scan — grep the interiority tags (thought/realized/knew/felt/noticed/understood/believed/decided + emotion nouns: afraid/worry/relief/anger/...) and judge every hit in context. Drop tags where free indirect carries (the thought stays, the "he thought" goes); kill tag-anaphora ("She thought about X. She thought about Y."). LEGAL: competence-knowing ("he knew her order before the door finished chiming"), communal knowing ("nobody knew what they burned up there"), belief subordinated to behavior ("whatever Grace believed about lines, she ate the cornbread"), displaced interiority ("his hand wanted the box"), and an emotion label only when a page of behavior cashes it ("the gentlest thing he had ever hated" + the buses). Dialogue is exempt — people say "I thought."
9. **Backstory-leak check** — the iceberg informs behavior; no résumé exposition; lenses leak (Desmond reads the world in failure modes), facts don't.
10. **Humanizer (the slop pass)** — the kill-list: stapled-fragment narration, rule-of-three stacks, "not X but Y" parallelism, mic-drop closers, em-dash chains, purple verbs, poignancy-reach endings — scenes end FLAT; plus the deeper tell: clipped/punchy/buttoned rhythm itself (userSettings:humanizer + docs/03 §2).
    **"Humanizer" means INVOKE THE SKILL (user law, 2026-06-10, second offense):** the assembly-phase humanizer pass is the actual `userSettings:humanizer` skill run over the finished text — never a from-memory approximation. The hand-applied kill-list during drafting is step 10's per-chapter hygiene; it does NOT satisfy the assembly pass. Claimed-but-not-invoked happened on THE HEIR and again on INDIVISIBLE; both times the user caught surviving tells. Run the skill; report what it flags honestly.
    **BANNED OUTRIGHT — the corrective definition (user law, 2026-06-10):** defining a thing by negating one label and substituting another — *"That's not my price you're short. That's fuel."* / *"It wasn't an armband — it was a lanyard."* / *"Not to settle the arguments. To keep having them."* In dialogue AND narration. Say the thing directly: *"The two coins are Beto's fuel on the far end."* Plain conversational negation ("I'm not joking," "Wasn't a request") is normal speech and stays; the ban is the negate-then-redefine RHETORICAL move.
    **BANNED AS RHYTHM — the rule of three (user law, 2026-06-10):** triples used as cadence are saturated everywhere and read as machine writing even when locally "good." A list of three is allowed ONLY when the three things are real, countable objects in the world (a form's actual fields, props actually on a table) — never as prose music, and never to close a paragraph on a drumbeat. Default to two, or four-plus and irregular.
    **THE MASTER BAN — the completion-sentence (user law, 2026-06-11, third catch):** no sentence
    — and no comma-separated clause — whose SOLE JOB is to complete the information of the
    previous one. *"He was going. Four days. To New Jersey. On a train."* — each unit must be a
    full, independent predication; if a unit cannot stand as its own sentence with its own verb
    and its own news, fold it into the sentence it serves or cut it. This subsumes every variant
    below (period fragments, comma drips, announce-then-deliver: "which was wrong twice — wrong
    because X, and wrong because Y"). Applies to NARRATION and DIALOGUE. Legal: a genuine new
    predication about the same moment ("It came out half a question."), one-word ANSWERS in a
    two-speaker exchange, quoted documents, refrains.
    **BANNED — the costume metaphor (user law, 2026-06-11):** "X wearing the clothes/uniform/
    costume of Y," "Y in X's clothing," and kin — AI-saturated; at most once per BOOK, deliberate,
    or not at all.
    **ENFORCEMENT IS MECHANICAL (2026-06-11, after the third miss):** the prose gates run as CODE
    (`examples/prose_gates.py`) on every changed chapter BEFORE any deliverable is staged — the
    assembly scans are no longer satisfied by a model remembering to do them.
    **BANNED OUTRIGHT — the withhold-then-append (user law, 2026-06-10):** a sentence written with its information missing, then the information delivered as one or more trailing fragments. *"There were horseback riders. Four. All black."* Never. Write the complete sentence: *"There were four horseback riders, all of them Black."* This includes the verbless cousins: inventory fragments after a setup sentence ("He took things out of the bag. A frame. Shoes."), manner appends ("His thumb crossed it. Not looking. Not slowing."), and observation stacks ("Ray looked at him. The shoes. The sedan."). **The comma variant is the same ban (user law, 2026-06-10, second catch):** re-punctuating the drip with commas is still the drip — *"Forty-one people, a church group, the wrong neighborhood by one exit ramp by one account and on purpose by another, and then the thing that made it…"* parcels information in installments and never commits to a verb. A single appositive is English; a STACK of reclassifying appositions before the sentence commits is the disease. THE REAL FIX: write a complete subject-verb sentence that carries its information in one motion ("A church group of about forty people took a wrong exit and ended up in the wrong neighborhood, and the thing that happened to them there ended up on every screen") — and deliver the secondary nuance through the REPRESENTATIONAL layer (behavior, the world's reaction, metaphor) or a second complete sentence, never by packing the literal layer. A colon reveal that completes its clause ("…one word stamped in purple ink, slantwise: PENDING.") stays legal. Refrains and quoted documents are exempt; appends are not. This applies to NARRATION and DIALOGUE both.
11. **CLEAR-PANE (the layer law — user decree 2026-06-12: EVERY pipeline, EVERY story):**
    intrigue lives in EVENTS, MEANING, and INTENT — never in the sentence's own construction.
    The text layer is a clear pane of glass. Run the `clear-pane` skill
    (~/.claude/skills/clear-pane: six families, thirty-one devices, the Layer Test, the
    Relocation Rule) over every chapter at drafting AND as an assembly scan. A sentence that
    dies when flattened marks an EVENT-GAP — fix the scene, never re-decorate the words. The
    §10 bans above are instances of clear-pane families; clear-pane is the law they hang from.
12. **Continuity / canon** — arena rules obeyed; the naming-tells consistent; motifs tracked across chapters; props don't teleport (the landline/mobile lesson).

## Assembly (run once, after drafting)
- Full start-to-finish read: sequence seams, who-knows-what-when, motif audit, per-character blind-attribution spot-check.
- Then the three assembly scans, ACTUALLY RUN over the whole text (not the per-chapter hand versions): (1) the humanizer SKILL (§10 law), (2) the show-not-tell scan (§8 law), (3) the CLEAR-PANE skill (§11 law) with its removal ledger and event-gap flags. Each produces a findings report — what was fixed, what was judged exempt and why.
- Gates green: the work's seed in `examples/` through `pipeline.check` — heart included (no opt-out for human stories).
