# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## The governing law — read this before writing anything

**ReScript for everything. No Python, no JavaScript, no new languages.** This has been
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

**`studio/` (ReScript) is the only engine.** There used to be a parallel Python engine
(`metaphrand/`), a separate Python production pipeline (`cinema/`), and per-story Python
scripts under `stories/*/` — all removed. If you find a stray reference to `metaphrand/` a
Python import, `pytest`, or `pip install` anywhere (in this file, in a doc, in a comment),
that reference is stale; fix or remove it, don't follow it.

## Commands

```bash
cd studio && npm install       # first time in a fresh worktree — node_modules is NOT
                                # shared between worktrees; a bare `npx` here will grab
                                # whatever rescript version is on PATH and can silently
                                # run the wrong compiler. Always npm ci/install first.
npm test        # runs lint:hatches, THEN rescript compile, THEN the contract tests
npm run build   # rescript      (compiles .res -> .res.mjs in-source, next to the .res file)
npm run watch   # rescript -w
node src/<Something>.res.mjs   # run a compiled driver directly (after building)
```
The build is itself a gate: `warnings.error: +8` makes warning 8 fatal, and `npm test` runs
`scripts/no-escape-hatches.sh` first — it greps `src/` for `Obj.magic`, `%raw`, `%identity`
and fails the build if any are present. Do not add escape hatches; if one seems truly needed,
stop and ask.

**Model calls cost real money and are capped by a human-held budget, not a line in the
source.** `Session.res` holds exactly one warm `claude` process per run (boot cost paid once,
not per call — this is not incidental, it fixes a real incident where cold-booting `claude -p`
per call burned through a token budget for zero output). It is capped by the
`CLAUDE_STUDIO_BUDGET` environment variable, which you set explicitly and modestly for a
bounded run — never omit it to get an implicit "unlimited," and never raise it to make a
budget error go away without checking with the user first. `CLAUDE_STUDIO_BIN` can point at
`scripts/fake-claude.mjs` for zero-spend structural testing.

## Architecture — the studio engine (ReScript, `studio/`)

The core idea: `Gate.clean` is an **abstract type** with no constructor outside the `Gate`
module, so the only way to obtain a `clean` value is to run `craftlint` and pass. This is
*parse, don't validate* — a gate returns a value that proves it passed, not a boolean you
could ignore. The same shape repeats everywhere in this codebase:

- **`Session.res`** — the one and only path to the model (`Session.ask`). Warm, sequential by
  construction (one promise queue; no code path issues two calls at once), budget-capped,
  spend-observable (every turn logs cost).
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
  really went through the pipeline. This receipt is the actual, checkable answer to "was this
  generated by the engine or handwritten" — not a claim, a file you can diff against.
- **`Gate.res`** — the deterministic floor. `craftlint: rawText => result<clean, array<finding>>`.
  Every violation kind is a closed variant (`EmDash`, `FragmentAppend`, `AiVocab`, ...), not a
  string — the compiler knows every case exhaustively.
- **`Craft.res`** — the mechanical AI-marker gate riding on top of `Gate`'s types:
  `gateAction` (strict — narration must not perform) vs `gateDialogue` (looser — dialogue is a
  character's own voice) vs `echoViolation` (the flat cross-speaker-repeat tell).
- **`Judge.res`** — the model-judged ceiling for what regex can't catch (comma-drip, forced
  triads, arranged-for-effect) — costs a `Session.ask` call, pair it with the free
  mechanical floor, don't rely on it alone.
- Per-project driver files (`SkyKing_Write*.res`, `FourOlds_Write*.res`, etc.) are where a
  specific `sceneSeed` gets assembled and run — one file per scene/batch, not a shared
  generic entry point. When starting a new one, copy the shape of an existing
  `*_Write*.res` + `*_Lift*.res` pair rather than reinventing the driver pattern.

### A known, real limitation of this design (stated honestly, not hidden)

None of this is a *type-level* guarantee against a determined bypass — ReScript has no linear
types, nothing stops a session from setting `CLAUDE_STUDIO_BUDGET` itself, writing a raw
`fetch`/`spawn` that skips `Session`, or hand-editing an emitted `.scene.txt` file directly.
What the design buys is that a bypass is no longer *invisible*: it costs deliberate effort,
and `Write.verify` / `Session.callsMade()` make it checkable after the fact. Treat "I ran it
through the engine" as a claim that must be backed by a receipt on disk, from anyone,
including yourself.

## Conventions

- **Media is `.gitignore`d, NEVER Git LFS.** `.png .jpg .jpeg .webp .mp3 .mp4 .m4a .wav .glb
  .pdf` and the table-read production output are all git-ignored — regenerable, not versioned.
  This was a real incident, not a style choice: an earlier attempt to put media on Git LFS hit
  the free-tier push cap mid-push and nearly lost work. Source (the .fountain/.res/.md text)
  is what's committed; deliverables live on YouTube or get sent directly to the user.
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
