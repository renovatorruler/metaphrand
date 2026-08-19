# Echo and the Broken Bonds — Candidate and Evidence Identity v2

No screenshot, clip, log, measurement, score, or verdict belongs to a round unless this non-circular identity chain verifies.

## Canonical bytes

All identity JSON uses RFC 8785 JSON Canonicalization Scheme bytes, with duplicate keys rejected and every key/string first normalized to Unicode NFC. Canonical output has no BOM or terminal newline. Paths are UTF-8 NFC, `/`-separated, relative to a declared root, and reject absolute paths, empty components, `.`, `..`, NUL, and newline. SHA-256 is lowercase hexadecimal. Runtime/package roots reject symlinks; the separately locked browser bundle uses the explicit file/symlink manifest algorithm in `browser-lock.json`.

`planning-lock.json` is a JCS object containing every reviewed planning path, byte size, and SHA-256, including the frozen `reference-evidence-manifest.json` and every file it names. It does not include itself. `planning_id = SHA256(JCS(planning-lock.json))`. A clearly named `preapproval-planning-lock.json` may be made before reference capture, but it cannot authorize provider spend, a build, or a scored round.

## 1. Immutable runtime content

Before execution, create `content-manifest.json` containing:

- every production source path/hash;
- compiler/bundler/runtime versions, lockfiles, exact release commands, configuration, and hashes;
- executable/package hashes and complete packaged dependency closure;
- every shipped asset path/hash, originating master/reference lineage, final/placeholder status, rights-evidence hash, and runtime asset-use identifier;
- exact evaluator contracts/formal fixtures;
- the complete reviewed planning set by explicit path/hash: `asset-package.md`, `canon-lock.json`, `assets.csv`, `asset-contracts.csv`, `rights-ledger.csv`, `references.csv`, `scope.md`, `sequence-v2.md`, `style-spec.md`, `audio-spec.md`, `quality-bar.md`, `test-envelope.md`, `test-oracle.md`, `reference-lock.md`, `browser-lock.json`, `candidate-evidence.md`, `lookdev-batch-01.md`, `lookdev-batch-01-requests.json`, and every later approved billable-batch request manifest used;
- `planning_id`, `planning-lock.json` hash, and the verified reference-evidence manifest hash.

`content_id = SHA256(JCS(content-manifest.json))`. The content ID is **not embedded into any hashed runtime byte**. In evidence mode the unchanged runtime reads a test-only external `evidence-envelope.json`, displays the first twelve content-ID characters on the title and capture watermark, and exposes the full ID accessibly. The harness first recomputes the content ID and rejects a mismatched envelope. The envelope is excluded from shipping closure and is separately hash-bound below, avoiding a self-referential executable hash.

Envelope data may feed only the diagnostic overlay and evidence log fields. Static dependency analysis must prove there is no envelope-, nonce-, session-, mode-, capture-, or watermark-dependent path into evaluator, story, input acceptance, world projection, timing policy, asset selection, audio, or save state. The scored session includes the complete oracle/full trace once with no envelope/diagnostic query and once in evidence mode. Evaluator/event/save sequences must be byte-identical; every canonical checkpoint must be pixel-identical outside the frozen watermark rectangle and audio-cue-identical. Any other mode delta is a hard failure.

Runtime events carry `content_id`, monotonic milliseconds from navigation start, input sequence, evaluator-before hash, authorized transition hash or `NONE`, evaluator-after hash, and rendered-world projection hash. Evidence video shows the same monotonic clock. Wall time is never the join key.

## 2. Frozen test system

Before a scored nomination, create `test-system-manifest.json` with exact paths, byte sizes, hashes, versions, and commands for:

- Node executable and package manager;
- Playwright package and transitive lockfile closure;
- the verified browser bundle/symlink manifest and launch/context/CDP settings;
- game server, capture, input, oracle, fuzz, rejoin, package-inventory, dependency, renderer-coupling, memory/RSS, audio-sync, frame-time, percentile, and report harnesses;
- video/image tools, codecs, capture settings, masking/letterbox transform, and deterministic algorithms from `test-envelope.md`;
- all canonical input traces and test fixtures.

`test_system_id = SHA256(JCS(test-system-manifest.json))`. Changed test bytes, command, algorithm, dependency, browser, OS, or setting create a new test-system ID and reset the streak.

## 3. Precommitted scored session

Before the first formal run, create immutable `session-manifest.json` with `content_id`, `test_system_id`, an OS-CSPRNG nonce, exact lane/order/seed/input schedule, every oracle case in production and evidence modes, twenty consecutive left/right runs per lane, the cross-mode equivalence trace/checkpoints, capture indices, and the separate no-recording performance runs. No evidence output exists when it is sealed. `session_id = SHA256(JCS(session-manifest.json))`.

Before launching a browser, send `{content_id,test_system_id,session_id,nonce_hash}` to one designated host-native **session-witness** Codex thread that is separate from the builder and critics. Its durable thread transcript is the independent timestamped sink. The witness rejects a second scored nomination for the same content ID and returns a sealed acknowledgement; absence of that acknowledgement blocks launch.

The deterministic `evidence-envelope.json` then names `content_id`, `test_system_id`, `session_id`, nonce, browser lock, and evidence mode. It is served as an external QA file and its hash is recorded at session start.

The scored harness creates a hash-chained `execution-ledger.ndjson` before launch. Before every attempt it sends the witness an `ATTEMPT_START` commitment containing index, previous chain head, lane, seed, input-trace hash, and capture flags and waits for acknowledgement. At termination it sends `ATTEMPT_END` with status, canonical ledger-record hash, new chain head, and every raw-artifact hash before the next attempt can begin. The witness validates monotonic indices/chain continuity and seals a final receipt containing first/last transcript timestamps, count, terminal chain head, and session result. Every crash, retry, timeout, failed assertion, capture, and status remains in the chain. Missing acknowledgement, missing/duplicate index, chain fork, deletion, or a mismatch with the witness transcript fails the session. Twenty passes must be consecutive. A failed scored session permanently fails that content nomination; it cannot be replaced by cleaner footage or another scored session under the same content ID. Diagnostic runs are allowed only before nomination and are labelled non-evidence.

## 4. Pre-critic evidence identity

After the session, create `evidence-manifest.json` containing:

- `content_id`, content-manifest hash, `test_system_id`, test-system-manifest hash, `session_id`, session-manifest hash, evidence-envelope hash, browser lock, and verified launch record;
- the complete execution ledger and **all** attempt artifacts;
- the session-witness nomination acknowledgement, every start/end acknowledgement, and final sealed chain receipt;
- every raw unedited 11-second clip, 30-second clip, canonical full muted/no-text run, full voiced run, full grayscale/color-vision runs, still, measurement, console, oracle, fuzz, replay/rejoin, dependency report, evaluator log, and no-recording performance result with path, byte size, SHA-256, and monotonic range;
- the predeclared capture selection rule and proof that the named run indices—not handpicked alternatives—were used;
- package inventory/SBOM and proof that QA references/motion studies are absent from shipping bytes;
- the frozen reference-evidence manifest and verification of every file it names.

`evidence_id = SHA256(JCS(evidence-manifest.json))`. Critics recompute `content_id`, `test_system_id`, `session_id`, and `evidence_id`; they do **not** wait for a circular round ID.

## 5. Integrity verification and blind packets

A separate integrity verifier first inspects raw files, recomputes the four IDs, confirms the visible watermark/timestamp overlap, and seals an integrity verdict bound to `evidence_id`. Quality critics do not substitute for this check.

Blind comparison uses deterministic QA derivatives bound to the raw hashes. A fixed neutral mask covers the diagnostic watermark area in **both** Echo and reference evidence; identical neutral letterboxing is the only other transform. `reference-lock.md` freezes the rectangle and transform. The unmasked raw evidence remains authoritative for integrity and full-rubric review.

Before distribution, create `comparison-packet-manifest.json` containing `evidence_id`, transform tool/hash/command, each derived packet path/hash, critic-specific randomized A/B labels, and `SHA256(JCS({salt,mapping}))` commitments. The salt/mapping stays only in lead-orchestrator memory until every blind verdict is sealed. Each of three fresh blind critics receives only its neutral packet, five-property rubric, packet ID, and an independence/fresh-context attestation form—never raw filenames, content IDs, progress history, or the mapping. Each returns a signed/sealed score sheet binding its packet ID.

After blind verdicts seal, `comparison-key-reveal.json` publishes each salt/mapping and must match every prior commitment. Three separate fresh full-evidence critics then inspect the real unmasked output, complete runs, evaluator evidence, canon, and 100-point rubric. Each verdict binds `evidence_id`, critic identity, assigned scope, fresh-context/independence attestation, integer item scores, hard-gate results, and largest gap.

## 6. Post-verdict round record

Only after all verdicts exist does the lead create `round-verdict-manifest.json` containing `evidence_id`, integrity verdict hash, all blind packet/verdict hashes, key-reveal hash, all full-evidence verdict hashes, exact quorum arithmetic, minimum 100-point score, five-property result, and PASS/FAIL. `round_id = SHA256(JCS(round-verdict-manifest.json))`.

No critic is asked to recompute `round_id` before judging. An independent final auditor recomputes it afterward and verifies that aggregation used the frozen rules without averaging, rounding, omission, waiver, or substitution.

## Same-content and immutability rules

Performance is recorded without capture overhead but uses the identical `content_id`, test system, envelope, browser, flags, viewport, profile-reset procedure, package bytes, and precommitted session. Absence of recording never excuses an identity mismatch.

After each ID is created, its manifest and covered directory become read-only. A fix never replaces evidence in place; it creates new content/test/session/evidence/round IDs as applicable. The progress page links every failed and passing nomination and never rewrites a ledger, packet, or verdict.
