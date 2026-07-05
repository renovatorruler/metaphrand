/* ============================================================================
   Process — the writers' room, in types.

   You (the director) bring an idea; the room develops it WITH you through a
   back-and-forth it cannot skip; every scene earns its way to the page through
   gates it cannot skip. Read top to bottom and you have the whole pipeline —
   and the illegal moves (skip development, ship ungated, approve un-judged work,
   finish before approval) simply don't compile.
   ============================================================================ */

/* ---- distinct concepts, distinct types (principle 1) --------------------- */
/* A bare `string`/`int` appears ONLY inside an @unboxed declaration here —
   never naked in a record, a variant, or an argument. Every value is named. */
@unboxed type idea          = Idea(string)          // the spark — a vibe, a sentence
@unboxed type characterName = CharacterName(string)
@unboxed type actionLine    = ActionLine(string)    // only what a camera sees
@unboxed type dialogue      = Dialogue(string)      // only what a mic hears
@unboxed type heldCard      = HeldCard(string)      // a secret the surface must never state
@unboxed type want          = Want(string)
@unboxed type wall          = Wall(string)
@unboxed type turn          = Turn(string)
@unboxed type lineNo        = LineNo(int)
@unboxed type reasonText    = ReasonText(string)    // a model judge's free-text reason (legitimately prose, unlike a violation KIND)
@unboxed type sentenceShape = SentenceShape(string)
@unboxed type vocabulary    = Vocabulary(string)
@unboxed type sampleLine    = SampleLine(string)
@unboxed type noteText      = NoteText(string)      // a director's note, handed back in the loop
@unboxed type question      = Question(string)
@unboxed type episodeTitle  = EpisodeTitle(string)

/* ---- how the room talks to you (right brain by default) ------------------ */
/* Show a concrete thing to react to; ask a question only when it must. */
type offer<'a> = Show('a) | Ask(question)

/* ---- the world: characters from their charts ----------------------------- */
type sign =
  | Aries | Taurus | Gemini | Cancer | Leo | Virgo
  | Libra | Scorpio | Sagittarius | Capricorn | Aquarius | Pisces

/* A natal chart: exactly one sign per graha — a chart with two Suns or no Moon
   cannot exist. */
type natalChart = {
  sun: sign, moon: sign, mars: sign, mercury: sign, jupiter: sign,
  venus: sign, saturn: sign, rahu: sign, ketu: sign,
}

type eloquence = Earned | Plain
type voice = {sentence: sentenceShape, vocabulary: vocabulary, eloquence: eloquence, sample: sampleLine}

/* The character is the main type, abstract — you can't reach in and set a voice.
   You hand it a name and a chart; the chart never changes. */
type character
let make: (~name: characterName, ~chart: natalChart) => character
let name: character => characterName
let chart: character => natalChart
/* The voice is derived from the chart (expensive, asks the model) and MEMOIZED —
   derived once, cached, never re-spent. Safe to cache because `character` is
   abstract and `chart` is immutable, so it can't disagree with the chart. */
let voice: (character, string => promise<string>) => promise<voice>           // memoized; derives via the injected asker on a cache miss
let deriveVoice: (natalChart, string => promise<string>) => promise<voice>     // chart -> voice card, via the model

type bible = {cast: array<character>, secrets: array<heldCard>}

/* ---- the seed of a scene: want / wall / turn ----------------------------- */
/* Drama is not optional — want, wall and turn are required, never `option`. */
type brief = {want: want, wall: wall, turn: turn, present: array<characterName>, live: array<heldCard>}

/* ---- two gate systems, at two heights of the tree ------------------------ */
/* CONCEPT gates — the upper levels (scene, actions, events). Is this the right
   scene? do the right things happen, dramatically, in the right culture? The AI
   proposes with your feedback; these force it to fix its THINKING. */
type conceptGate = Drama | HumanReaction | Heart | Structure | SecretsBuried | Cultural

/* A finding names the SPECIFIC violation in the type, never a string: either a
   concept gate flagged the scene, or the floor (the words/letters layer) caught
   an exact language tell — `Gate.violation`: em-dash, fragment-append, AI-vocab,
   and the rest. The compiler knows every case, so a finding can't carry a bogus
   or unhandled kind. */
type finding =
  | Concept(conceptGate, reasonText, lineNo)   // which concept gate, and WHY (the judge's reason)
  | Language(Gate.violation, lineNo)
type verdict = Passed | Failed(array<finding>)
let describeFinding: finding => string   // a finding as a one-line reason

/* ---- the proofs (abstract — the gates are the only mint) ----------------- */
/* TWO separate proofs, because the AI routinely earns one and fails the other:
   a conceptually-right scene whose prose is slop, or clean prose saying nothing. */
type conceptCleared
type approval
type languageClean

/* ---- a draft, and the scene's journey ------------------------------------ */
type draft = {brief: brief, action: array<actionLine>, lines: array<dialogue>, ordered: array<string>}   // `ordered` keeps the scene's lines in their written order (for output); action/lines are the typed split (for the gates)
type scene =
  | Briefed(brief)
  | Drafted(draft)
  | ConceptReady(draft, conceptCleared)
  | Approved(draft, conceptCleared, approval)
  | Shippable(draft, languageClean)

/* ---- the scene's only legal moves ---------------------------------------- */
let draftScene:   (brief, bible, string => promise<string>) => promise<draft>  // the author writes the scene via the injected model-asker
let repairScene:  (draft, array<finding>, string => promise<string>) => promise<draft>  // rewrite a scene to fix findings (the repair loop's repair)
let gateConcept:  (draft, (conceptGate, string) => promise<option<reasonText>>) => promise<result<conceptCleared, array<finding>>>  // runs each concept gate via the injected judge
let approve:      (draft, conceptCleared) => approval                         // your yes: this is the right scene
let gateLanguage: (draft, approval, string => promise<array<Gate.violation>>) => promise<result<languageClean, array<finding>>>  // floor (free) + the injected model judge; only on approved prose

/* ---- the gate -> repair loop, metered from the start --------------------- */
/* Run a gate; if it fails, repair the draft and re-gate, and again, until it
   passes or the gas runs out. Each repair attempt burns a unit; at empty it
   returns Stuck (the latest draft + what's still wrong), and the only way to give
   it more is your approval — `Gas.refuel` and re-run. Generic over the gate and
   the repair, so the SAME loop drives either battery. */
type repairOutcome<'proof> =
  | Cleared('proof, draft)          // the gate passed (perhaps after repairs)
  | Stuck(draft, array<finding>)    // out of gas; here's the draft and what's still wrong

let repairToward: (
  draft,
  draft => promise<result<'proof, array<finding>>>,    // the gate to satisfy (async; it may judge via the model)
  (draft, array<finding>) => promise<draft>,   // the repair (the model; async)
  Gas.gas,
) => promise<repairOutcome<'proof>>

/* ---- the project: the room's arc, as an enforced state machine ----------- */
type episode = {title: episodeTitle, scenes: array<scene>}   // scenes sit at mixed stages, hence `scene` is a sum

/* Four stages, each its OWN abstract type — so the only way into a later stage
   is the transition that makes it, and no stage can be skipped or faked. */
type spark         // 1. the SEED — what the director hands in
type development   // 2. INTERMEDIATE — the back-and-forth, in progress
type shaped        // 3. PENULTIMATE — substance converged; finishing not yet run
type developed     // 4. DONE — the finished world
type inProduction  // the finished world, broken into episodes

let conceive: idea => spark                           // the seed arrives
let generateWorld: (idea, option<string>, string => promise<string>) => promise<bible>  // the room builds a world (charted cast + secrets) from the idea
let bibleToText:   bible => string                    // serialize a world to disk text
let bibleFromText: string => bible                    // load a world back (zero model calls)

/* Stage 2: the back-and-forth you CANNOT skip, now METERED. You begin from the
   spark; the room shows a world to react to; you respond; it keeps going or
   converges to `shaped` (never straight to done). Each `respond` burns a unit of
   gas, and after `Gas.perPhase` rounds it `Stalled`s — the only way on is your
   approval, via `approveMore`. So the back-and-forth can't loop on your quota. */
type reaction = Approve | Revise(noteText)            // what the director hands back each turn
type step = Continue(development) | Done(shaped) | Stalled(development)
let begin:   (spark, string => promise<string>) => promise<development>   // generates the first proposed world from the idea
let show:    development => offer<bible>
let respond: (development, reaction, string => promise<string>) => promise<step>   // Revise re-generates the world; Approve locks it
let approveMore: (development, Gas.approval) => development   // refuel a stalled development with your go-ahead

/* Stage 3 -> 4: run the finishing-touches tools (the `finishingPass` battery) on
   the converged substance. This is the ONLY road to a `developed`, so a world
   cannot be called done until finishing has actually run on it. */
let finish: shaped => promise<developed>

let breakInto:   (developed, array<episodeTitle>) => inProduction   // episodes break only from a finished world
let theBible:    developed => bible
let theEpisodes: inProduction => array<episode>
