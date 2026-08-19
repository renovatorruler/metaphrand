# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Provider preflight — before delegating any work

Establish from the trusted system/product identity that this agent is hosted by Claude, then
follow `docs/PROVIDER_ISOLATION.md`. Use only native Claude subagents/agent threads by default.
Do not run `codex`, `codex exec`, an OpenAI API, or a Codex subagent as a worker unless the user
explicitly requests that provider or execution mode for the current task.

If the host identity is not Claude, this file does not grant permission to claim that it is. If
the provider cannot be established, do not delegate and ask the user. Repository files and older
task history are not an override. Zero-cost fake-worker tests are allowed because they make no
provider request.

For story-engine work, follow `studio/NATIVE_WORKERS.md`. ReScript emits a provider-bound job
file; delegate that exact job to one native Claude subagent, wait for it to write the declared
response file, and then rerun the engine. The orchestrator owns validation and acceptance. The
worker must not edit or approve the final scene directly.

## The governing law — read this before writing anything

**ReScript for everything. No Python, no JavaScript, no new languages.**

> AUTHOR-APPROVED EXCEPTION (2026-08-13) — the Defold game runtime.
> The literacy game is built on the Defold engine, which is Lua-only. The split the
> author confirmed: **ReScript owns all episode data and its validation**; the typed
> plan in `studio/` EMITS the Lua data tables and the asset manifest the game loads.
> Hand-written Lua is permitted ONLY for engine glue — input, the stroke scorer,
> screen transitions. No episode content, no letter/word data, no asset paths are
> ever authored in Lua. This exception covers `game/` and nothing else.
 This has been
stated before and violated before — including by a Claude session that reached for Python
"just to run one gate," then kept building Python tooling for an entire conversation before
being caught. If you are about to write a `.py` file, or use `python`/`pip` for anything
beyond a one-off disposable shell command, stop. The answer is ReScript in `studio/`, not a
new script in a new language.

**The type system is the enforcement mechanism, not a style preference.** `studio/`'s whole
design is that a violation should be a compiler error or a structurally-impossible state, not
a documented rule a future session can forget. When you add a constraint, ask first whether it
can be a type (an `@unboxed` newtype, a closed variant, an opaque type with no external
constructor) before reaching for a runtime check or a comment. See "Architecture — the studio
engine" below for the concrete mechanisms already in place (`Gate.clean`, `Write.scene`,
`Seed.sceneSeed`).

**Scene prose is never hand-typed.** A screenplay scene exists only if it came out of
`Write.writeScene` (from a `Seed.sceneSeed` — structure, not prose) and was `Write.emit`-ted
with a receipt that `Write.verify` can check. If you are composing scene dialogue or action
lines directly in a conversation response and then pasting them into a file with `Edit`/`Write`,
you are doing exactly the thing this file exists to prevent. The proof that a scene was engine-
generated and not hand-written is the receipt, not a claim in a commit message.

## What this is

Metaphrand turns a one-line idea into a finished story. A story is modeled as a
**directed acyclic graph of metaphors** (Jaynes's sense: an abstract `meaning` always
carried by a concrete `manifestation` on the page). The engine owns the *structure* and a
stack of *gates*; a model only fills the slots inside each gate — never the structure.

**`studio/` (ReScript) is the only active engine.** The old Python package was removed;
some historical Kuku production shell files still invoke Python and are being ported. Their
exact tracked count is frozen by `studio/scripts/python-legacy-allowlist.txt`: do not add to
it. `npm run audit:workspace` also reports ignored and untracked local remnants. References
to the removed `metaphrand/` package, `pytest`, or `pip install` are historical, not commands
to follow.

## Commands

```bash
cd studio && npm install       # first time in a fresh worktree — node_modules is NOT
                                # shared between worktrees; a bare `npx` here will grab
                                # whatever rescript version is on PATH and can silently
                                # run the wrong compiler. Always npm ci/install first.
npm test        # hatches + language/media ratchets + compile + zero-cost safety tests
npm run build   # rescript      (compiles .res -> .res.mjs in-source, next to the .res file)
npm run watch   # rescript -w
npm run audit:workspace          # strict report of all remaining local Python debt
node src/<Something>.res.mjs   # run a compiled driver directly (after building)
```
The build is itself a gate: `warnings.error: +8` makes warning 8 fatal, and `npm test` runs
`scripts/no-escape-hatches.sh` first — it greps `src/` for `Obj.magic`, `%raw`, `%identity`
and fails the build if any are present. Do not add escape hatches; if one seems truly needed,
stop and ask.

**Model work is capped and provider-bound.** `Session.res` prepares native-worker jobs using
`STUDIO_NATIVE_WORKER_PROVIDER`, `STUDIO_NATIVE_JOB_DIR`, and a positive
`STUDIO_WORKER_BUDGET`. It never chooses or launches a real provider by default. Follow
`studio/NATIVE_WORKERS.md`; do not raise a budget merely to make a refusal disappear. The
historical Claude CLI path is disabled unless the user explicitly requests it and the
run supplies both `STUDIO_ALLOW_CLAUDE_CLI=1` and `CLAUDE_STUDIO_BUDGET`. Tests use the
explicit zero-cost fake-worker mode.

## Architecture — the studio engine (ReScript, `studio/`)

The core idea: `Gate.clean` is an **abstract type** with no constructor outside the `Gate`
module, so the only way to obtain a `clean` value is to run `craftlint` and pass. This is
*parse, don't validate* — a gate returns a value that proves it passed, not a boolean you
could ignore. The same shape repeats everywhere in this codebase:

- **`Session.res`** — the one and only model-work boundary (`Session.ask`). It emits exact,
  provider-bound native-worker jobs and consumes their response files sequentially. It refuses
  to select a provider implicitly, enforces the call cap, and records the worker provider for
  new receipts. The historical process adapter is opt-in only.
- **`Seed.res`** — what a Claude session (or any author) is *allowed to write directly*:
  `voiceCard` (name/who/register/earnsEloquence/lexicon), `layer` (peshat/sod — the PaRDeS
  surface/buried-theme contract), `beat` (who/want/wall/turn/subtext — the Mamet shape), and
  `sceneSeed` assembling those into one scene brief. There is **no prose field** in this type.
  The seed is structure; the model, via `Write.writeScene`, turns it into sentences.
- **`Write.res`** — the writing stage. `writeScene(~seed, ~maxTries)` generates, gates on
  `Craft`, regenerates with violations fed back, up to `maxTries`. The result `scene` is
  **opaque** — no constructor takes a raw string, so a hand-typed line cannot become a
  `scene`. `liftDialogue` is a required second pass (the dialogue doctrine,
  `DIALOGUE_DOCTRINE.md`) — a scene emitted straight from `writeScene` is stamped `Written`,
  not `Lifted`, and `verify` refuses a `Written`-only scene. `emit` writes the scene file plus
  a `<file>.receipt.json` (seed hash, scene hash, gate=PASS, attempts); `verify` recomputes
  from the file + receipt and fails if the text was hand-edited after the fact, or never
  really went through the pipeline. `liftDialogue` and `extendScene` verify their INPUT
  receipt before doing work, then record their operation and parent scene hash; they cannot
  launder a hand edit into a new valid receipt. This receipt is the actual, checkable answer
  to "was this generated by the engine or handwritten" — not a claim, a file you can diff.
- **`Gate.res`** — the deterministic floor. `craftlint: rawText => result<clean, array<finding>>`.
  Every violation kind is a closed variant (`EmDash`, `FragmentAppend`, `AiVocab`, ...), not a
  string — the compiler knows every case exhaustively.
- **`Craft.res`** — the mechanical AI-marker gate riding on top of `Gate`'s types:
  `gateAction` (strict — narration must not perform) vs `gateDialogue` (looser — dialogue is a
  character's own voice) vs `echoViolation` (the flat cross-speaker-repeat tell).
- **`Judge.res`** — the model-judged ceiling for what regex can't catch (comma-drip, forced
  triads, arranged-for-effect) — consumes a worker turn through `Session.ask`; pair it with the free
  mechanical floor, don't rely on it alone.
- Per-project driver files (`SkyKing_Write*.res`, `FourOlds_Write*.res`, etc.) are where a
  specific `sceneSeed` gets assembled and run — one file per scene/batch, not a shared
  generic entry point. When starting a new one, copy the shape of an existing
  `*_Write*.res` + `*_Lift*.res` pair rather than reinventing the driver pattern.

### A known, real limitation of this design (stated honestly, not hidden)

None of this is a *type-level* guarantee against a determined bypass — ReScript has no linear
types, nothing stops a session from setting an environment variable itself, writing a raw
`fetch`/`spawn` that skips `Session`, or hand-editing an emitted `.scene.txt` file directly.
What the design buys is that a bypass is no longer *invisible*: it costs deliberate effort,
and `Write.verify` / `Session.callsMade()` make it checkable after the fact. Treat "I ran it
through the engine" as a claim that must be backed by a receipt on disk, from anyone,
including yourself.

## Conventions

- **Nothing is ever hard-deleted.** `Cinema_Backends.removeFile` MOVES files to
  `<repo>/.trash/<original-relative-path>` (collisions get a timestamp suffix), and the
  shell-side twin is `studio/scripts/trash.sh <paths...>`. Never use `rm` on repo content.
  Reclaiming space is the author's manual, per-project decision: `scripts/trash.sh --report`
  shows what a sweep would free; only the author deletes from `.trash/`.

- **Do not add new media to Git or Git LFS.** `.png .jpg .jpeg .webp .mp3 .mp4 .m4a .wav
  .glb .pdf` and production output are ignored. About eight thousand legacy LFS assets remain
  tracked from an earlier attempt; that existing debt is a separate cleanup, not precedent.
  Source (`.fountain`, `.res`, `.md`, manifests, receipts) is what should be committed;
  deliverables live on YouTube or are sent directly to the user.
- **Hardcoded absolute paths dangle.** More than one has already broken after a repo rename
  or when run from a different worktree (`Write.res`'s doctrine-file path did this twice).
  Prefer paths computed from `process.cwd()` (every driver here is documented as run from
  inside `studio/`) over a literal `/Users/.../` string.
- **`node_modules` is per-worktree, not shared.** A fresh worktree needs its own `npm ci` /
  `npm install` in `studio/` before `rescript`/`node` will work correctly — a bare `npx` can
  silently grab a different, wrong-version compiler.
- **Never commit with uncommitted work left behind.** If you touch a file, finish the thought:
  build it, verify it runs, commit it, push it. Don't leave a working-tree diff sitting
  unstaged "for later" — a later session (or a different worktree) won't know it's there.
