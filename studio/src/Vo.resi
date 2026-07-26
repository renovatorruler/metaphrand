/* Vo — the VOICEOVER door. The performance law, extended to a second artifact
   class: product narration whose canon is an AUTHOR-APPROVED source file (a
   walkthrough script), not an engine-generated scene.

   Write.resi seals `scene` (only writeScene mints one) so hand-typed story
   pages can never reach production. Product VO is legitimately hand-authored
   and human-approved — so it gets its OWN sealed door with the same
   guarantees, instead of a forged receipt or a bypass fetch:

   - the source file is the words-are-law canon; its hash is recorded;
   - prepare() tags via the warm Session (eleven_v3 vocabulary, tags are the
     ONLY legal insertion) and REJECTS any line whose words drift;
   - `performed` is opaque — only load() mints it, re-running the word gate
     and total coverage against the source at load time;
   - tts() is the only render, cached by exact-text sidecar.

   No raw text reaches the API; nothing unapproved reaches tts. */

type performed

let indexOf: performed => int

/* Tag every narration line of the source file (one line per non-empty,
   non-# line). Writes <outPerf> (+ .raw.txt). Error carries the reject
   count if any line's words drifted after one corrective retry. */
let prepare: (
  ~sourcePath: string,
  ~outPerf: string,
  ~direction: string,
) => promise<result<int, string>>

/* The gate, re-run: source hash matches, zero rejects, every line covered,
   words identical modulo tags. The only constructor of `performed`. */
let load: (~sourcePath: string, ~perfPath: string) => result<array<performed>, string>

/* The only renderer. Cached: skips when the sidecar matches the exact spoken
   text. ~say is the RECORDED pronunciation map (canonical -> phonetic
   respell), applied after the word gate: the canon keeps its true spelling,
   the sidecar records exactly what was spoken — transparent, never silent.
   ~dict attaches the account's pronunciation dictionaries server-side
   ((dictionaryId, versionId) locators) — the preferred path when the rules
   are alias-type; ~say remains the fallback for models that ignore them. */
let tts: (
  performed,
  ~voiceId: string,
  ~outMp3: string,
  ~say: array<(string, string)>=?,
  ~dict: array<(string, string)>=?,
) => promise<bool>
