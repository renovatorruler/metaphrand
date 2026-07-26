/* DRAMA CARDS - the conception layer as TYPED artifacts (docs/08-DRAMA_GATES.md).
   Ground truth before beats; beats as a causal graph whose edge enum has NO
   and-then constructor (Parker/Stone: if "and then" fits, you're fucked);
   escalation telemetry as integers; the scene card before prose. Every field
   is required - an incomplete artifact does not compile. DramaGate.res walks
   a story's spine and blocks. */

/* ---- Layer B: causality as a type. The edge is a CLAIM about the previous
   beat: this happens BECAUSE of it (Therefore) or IN SPITE of it (But).
   A beat pair whose only honest label is "and then" has no legal encoding -
   delete or rewrite the beat, not the label. */
type edge = But | Therefore

/* the proximate cause of the beat's event. Coincidence is directional
   (Pixar 19): luck may worsen the hero's position, never rescue it. */
type cause = Protagonist | Antagonist | ThirdParty | Coincidence

type charge = Plus | Minus

/* ---- Layer A: the ground truth. Revision diffs against THESE, never
   against the previous draft (Grillo-Marxuach: notes run against the
   anterior artifact). */
type premise = {
  x: string, /* the trait/value that drives (Egri: "Frugality...") */
  leadsTo: string, /* the causal verb phrase ("...leads to...") */
  y: string, /* the demonstrated terminal state ("...waste") */
}

type argument = {
  claim: string, /* arguable - someone could take the other side (Mazin) */
  antithesis: string, /* the other side's BEST case; it gets a real scene */
}

/* the ONE thing hero and opponent both want (Truby). The mutual exclusion is
   not implied - it is a required field. If you cannot write why both cannot
   have it, they can, and you have no story. */
type contested = {
  object_: string,
  whyBothCannotHave: string,
}

type groundTruth = {
  premise: premise,
  argument: argument,
  designingPrinciple: string, /* the one-line strategy that makes this telling original (Truby) */
  lighthouse: string, /* the DNA scene, written FIRST, in prose (Gilroy) */
  authorialStake: string, /* what this risks saying that a safe version wouldn't (Kaufman) */
  contestedObject: contested,
  opponentPlan: array<string>, /* the antagonist's campaign; succeeds absent the hero */
}

/* ---- Layer B+C: the spine. The opening beat carries no edge - there is
   nothing before it to claim causality against; that too is typed. */
type opening = {
  id: string,
  summary: string, /* one line, civilian-legible */
  povWant: string, /* what the POV character is trying to get, this beat */
  obstacle: string, /* what stands against it (the corkboard interrogation) */
  fortune: int, /* protagonist fortune after this beat, -5..+5 (Vonnegut) */
  stakes: int, /* magnitude at risk, 1..10; may never retreat (McKee) */
  question: string, /* what this beat throws forward (Scriptnotes 532) */
}

type beat = {
  id: string,
  edge: edge, /* claim against the PREVIOUS beat */
  cause: cause,
  summary: string,
  povWant: string,
  obstacle: string,
  fortune: int,
  stakes: int,
  antagonistAction: option<string>, /* the opposition's forward move in this beat, if any */
  question: string,
}

type spine = {
  story: string,
  truth: groundTruth,
  opening: opening,
  beats: array<beat>,
  climaxId: string, /* the climax beat: the antagonist must be present and ACTING in it */
}

/* ---- Layer D: the scene card - presented before a scene is drafted.
   Four masters, one invariant: Mamet's litmus, Sorkin's drive shaft,
   Mazin's truth-in/truth-out, McKee's value turn. */
type sceneCard = {
  scene: string, /* matches the scene id in the map */
  want: string, /* who wants what FROM WHOM */
  wall: string, /* what stands against it - formidable: it could win */
  cost: string, /* named consequence of failure; generic cost blocks */
  clock: string, /* why now */
  truthIn: string, /* the truth the scene opens on (Mazin) */
  truthOut: string, /* the different truth it closes on */
  value: string, /* the value at stake (McKee) */
  chargeIn: charge,
  chargeOut: charge, /* must differ from chargeIn or the scene is a nonevent */
  audienceDelta: string, /* Hitchcock's ledger: what the audience knows NOW that it didn't */
  forward: string, /* the question thrown to the next scene */
}
