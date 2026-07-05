/* ============================================================================
   Write — the writing STAGE of the pipeline. Seed in, gated scene out.

   writeScene is the only door from a Seed to prose: it asks the warm Session to
   write the scene, runs every line through the Craft gate, and regenerates
   (feeding the violations back) until the gate is clean or it gives up. The
   result `scene` is opaque — there is no constructor that takes raw strings, so
   a hand-typed line cannot become a `scene`.

   emit writes the scene AND a receipt (seed hash, scene hash, gate=PASS, model,
   attempts). verify recomputes from the file and the receipt: if I hand-edit the
   scene, or hand-author one with no real generation behind it, verify FAILS.

   The honest limit (same as Session's own): this is enforcement you can VERIFY,
   not enforcement I am incapable of evading. I hold the keys to this machine; I
   could forge a receipt. What changes is that a bypass is no longer invisible —
   it costs deliberate effort and it shows up under `verify`.
   ============================================================================ */

exception WriteError(string)

type spoken =
  | Action(string)
  | Dialogue({who: string, radio: bool, whisper: bool, text: string})

type scene // opaque — only writeScene mints it

/* generate -> gate -> regenerate, up to maxTries; raises WriteError if never clean. */
let writeScene: (~seed: Seed.sceneSeed, ~maxTries: int) => promise<scene>

/* THE DIALOGUE PASS (unskippable). Lift an already-emitted scene to the dialogue
   doctrine (DIALOGUE_DOCTRINE.md): raise lines toward subtext/tactic/lexicon/earned
   truth, re-gate on the Craft floor, and mint a scene stamped Lifted. writeScene
   emits a scene as PENDING; verify/read REFUSE a PENDING scene, so nothing can be
   produced until the lift has run. Raises WriteError if the floor is never clean. */
/* ~notes: optional director's line-notes (a specific audit) the lift MUST address. */
let liftDialogue: (
  ~path: Cinema_Backends.path,
  ~notes: string=?,
  ~maxTries: int,
) => promise<scene>

/* EXTEND a finished scene: generate ONE new beat in context and splice it in
   after line `afterLine` — every existing line preserved verbatim by
   construction; the spliced whole re-gated (incl. cross-seam echoes); minted
   PENDING so the doctrine lift must run again before rendering. */
let extendScene: (
  ~path: Cinema_Backends.path,
  ~afterLine: int,
  ~brief: string,
  ~maxTries: int,
) => promise<scene>

/* the gated lines, for production (TTS/render reads these). */
let lines: scene => array<spoken>

/* write the scene file + its <path>.receipt.json. Returns the scene-file path. */
let emit: (scene, ~txt: Cinema_Backends.path) => Cinema_Backends.path

/* recompute from the file + receipt. Ok if the chain holds; Error(reason) if the
   text was changed, the gate would now fail, or there is no receipt. */
let verify: Cinema_Backends.path => result<unit, string>

/* the door production uses: verify FIRST, then hand back the gated lines. A scene
   that fails verify cannot be produced. */
let read: Cinema_Backends.path => result<array<spoken>, string>
