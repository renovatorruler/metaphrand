/* THE TELLS REGISTRY - named AI tells for PROSE DELIVERABLES (treatments,
   summaries, pitch copy, editor reads, docs). One typed registry: the gate
   greps the mechanical tier; the judge tier prints as a checklist for the
   finishing pass. Dialogue is exempt by construction - this gate is never
   pointed at scenes (people hedge; that's human speech).
   Sources: alxndr/dotfiles ai-tells.md (the 16 named tells) merged with the
   house law - em-dash thesis, corrective definition, poignancy-reach,
   humanizer vocabulary, and the Meeting Leak lint from the
   transcript-artifact separation law. */

type severity = Block | Warn

type tell = {
  name: string,
  example: string, /* what the disease looks like */
  fix: string, /* the plain cure */
  re: Js.Re.t,
  severity: severity,
}

let tells: array<tell> = [
  /* ---- the meeting leak (transcript-artifact law): conversation in the
     artifact. Always Block - the deliverable's reader never saw the chat. */
  {
    name: "Meeting Leak",
    example: "as requested / per your feedback / as discussed / we decided",
    fix: "state the current truth; the reader never attended the meeting",
    re: %re("/\b(as (requested|discussed|mentioned (earlier|above|previously))|per (your|our) (feedback|conversation|discussion|notes)|we (decided|agreed) (to|that)|unlike the (previous|earlier|old) (version|draft))\b/i"),
    severity: Block,
  },
  {
    name: "Meeting Leak (negation residue)",
    example: "no longer uses X / removed the X",
    fix: "an undo is absence + positive restatement, never a 'removed' note",
    re: %re("/\b(no longer (uses?|using|includes?|has)|we (removed|dropped|cut) the)\b/i"),
    severity: Block,
  },
  /* ---- the sixteen, mechanical tier ---- */
  {
    name: "Hedge Stack",
    example: "While it is important to note that X, it should be acknowledged that Y",
    fix: "say the thing once, plainly, or cut it",
    re: %re("/\b(while it('s| is) (important|worth) (to note|noting)|it should be acknowledged|it('s| is) (important|worth) (to note|noting) that)\b/i"),
    severity: Block,
  },
  {
    name: "Preamble Promise",
    example: "In this document, I'll walk you through...",
    fix: "start with the content; the reader can see what the document is",
    re: %re("/^\s*(in|with) this (document|doc|guide|deck|memo|response|section|essay)\b/im"),
    severity: Warn,
  },
  {
    name: "Transition Summary",
    example: "Now that we've covered X, let's turn to Y.",
    fix: "just turn to Y; headings do the navigation",
    re: %re("/\bnow that we('ve| have) (covered|seen|discussed|established)\b/i"),
    severity: Block,
  },
  {
    name: "Enthusiasm Injection",
    example: "This is really exciting! / I'm passionate about...",
    fix: "enthusiasm is shown by specifics, never claimed",
    re: %re("/\b(this is (really|truly|incredibly) exciting|i('m| am) (passionate|thrilled|excited) (about|to))\b|\b(exciting|amazing|thrilling)!/i"),
    severity: Block,
  },
  {
    name: "Nested Qualification",
    example: "there may be cases where X could potentially be considered",
    fix: "one hedge maximum; pick may OR could OR potentially",
    re: %re("/\b(could potentially|may potentially|might potentially|there (may|might) be cases where)\b/i"),
    severity: Block,
  },
  {
    name: "Corporate Verb",
    example: "leverage / utilize / synergy",
    fix: "use / use / (nothing)",
    re: %re("/\b(leverag(e[sd]?|ing)|utiliz(e[sd]?|ing|ation)|synerg(y|ies|istic))\b/i"),
    severity: Block,
  },
  {
    name: "Passive Distancer",
    example: "It is believed that... / It should be noted that...",
    fix: "name who believes it, or just state the fact",
    re: %re("/\bit (is|was) (believed|thought|widely (believed|thought|considered))\b|\bit should be noted\b/i"),
    severity: Block,
  },
  {
    name: "Closer Summary",
    example: "In conclusion... / To summarize... / In summary...",
    fix: "end on the last fact; the reader just read the document",
    re: %re("/\b(in conclusion|to summarize|in summary|to sum up|all in all)\b/i"),
    severity: Block,
  },
  {
    name: "Delve/Dive",
    example: "Let's delve into... / a deep dive into...",
    fix: "look at / examine / or just start",
    re: %re("/\b(delv(e|es|ed|ing)|deep dive|dive deep|diving into)\b/i"),
    severity: Block,
  },
  {
    name: "Realm Of",
    example: "in the realm of web development / in the space of...",
    fix: "name the thing: 'in web development'",
    re: %re("/\bin the (realm|space|world|landscape|arena) of\b/i"),
    severity: Block,
  },
  {
    name: "Exact Match Claim",
    example: "My background is exactly what X is looking for.",
    fix: "demonstrate the fit with one specific; never assert it",
    re: %re("/\bexactly what [^.\n]{0,40}(looking for|needs|wants)\b/i"),
    severity: Warn,
  },
  {
    name: "Reality Reframe",
    example: "...was the actual job. / That's what it's really about.",
    fix: "corrective-definition kin: state the true thing without staging a reveal",
    re: %re("/\b(that('s| is) what (it|this)('s| is)? ?(really|actually) about|the (actual|real) (job|work|point|story|question) (is|was))\b/i"),
    severity: Block,
  },
  {
    name: "Gerund Pedestal",
    example: "Working without a PM is something I'm not afraid of.",
    fix: "subject-verb-object: 'I've worked without a PM.'",
    re: %re("/\b\w+ing [^.\n]{0,50}\bis something (i|we|he|she|they)\b/i"),
    severity: Warn,
  },
  {
    name: "Pivot Closer",
    example: "[Long sentence]. That's the [short restatement].",
    fix: "the long sentence already said it; cut the button",
    re: %re("/[^.\n]{45,}\. That('s| is) the [^.\n]{3,40}\.\s*$/im"),
    severity: Warn,
  },
  {
    name: "Em-Dash Itemizer",
    example: "My stack — Node, TypeScript, React — covers everything.",
    fix: "the em-dash thesis: plain list or plain sentence, no aside-packing",
    re: %re("/—[^—\n]{0,80},[^—\n]{0,80},[^—\n]{0,80}—/"),
    severity: Warn,
  },
  {
    name: "The Landing",
    example: "...and that's what makes this such an exciting opportunity.",
    fix: "poignancy-reach in a suit: end plain",
    re: %re("/\bthat('s| is) what makes (this|it) (such )?(an? )?(exciting|great|perfect|unique|compelling)\b/i"),
    severity: Block,
  },
]

/* the judge tier - no reliable regex; printed as the finishing checklist */
let judgeTier = [
  "The Landing (soft form): does the last paragraph reach for uplift the facts didn't earn?",
  "Pivot Closer (soft form): any sentence whose only job is restating the previous one shorter?",
  "Exact Match Claim (soft form): any asserted fit/importance a specific could demonstrate instead?",
  "Hedge Stack (soft form): opinions wearing more than one qualifier?",
  "Preamble/Transition tissue: any sentence about the document instead of the subject?",
]
