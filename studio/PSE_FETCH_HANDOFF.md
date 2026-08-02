# Pro Sound Effects — automated fetch: handoff guide

For an agent that has to pull sound effects from Pro Sound Effects (PSE) on this machine. The tool already exists and works; do not rewrite it. Read this whole page before running anything.

## 0. What this does

`studio/src/PseFetch.res` logs into prosoundeffects.com in a real browser, reads a **pull list** of search queries, searches each one, keeps only results from **libraries the account actually owns**, downloads the top N takes of each, and writes a manifest so re-runs skip what's already on disk.

It is resumable. Re-running after a crash is safe and cheap.

## 1. Credentials

Stored on this machine at **`~/.pse_credentials`** — line 1 is the email, line 2 is the password, file mode 600. The script reads it itself; you never need to open it, echo it, or paste it anywhere. Do not copy its contents into logs, prompts, commits, or documents.

The browser profile is persisted at **`~/.pse_browser`**, so a successful login is reused across runs. If auth breaks, deleting that directory forces a clean login.

## 2. Prerequisites

- Node, and Playwright with Chromium installed.
- **`npm ci` inside `studio/` first.** This is not optional in a git worktree — worktrees have no `node_modules`, and a bare `npx` will pull ReScript v12, which panics against this codebase. The project is pinned to **ReScript 11.1.4**.
- Compile before running: the executable artifact is `src/PseFetch.res.mjs`, produced by the ReScript build. If you edit the `.res`, rebuild.

## 3. The pull list format

A markdown file. The script reads **numbered lines** and takes every **backtick-quoted** string on them as a search query. A **★** immediately after the number marks the item as priority.

```
1. ★ `heavy wooden door slam` `door bolt draw`
2. `village night crickets`
```

Queries are de-duplicated, and priority items are processed first.

⚠️ **The pull-list path is hardcoded** in `PseFetch.res` (currently pointing at the Four Olds list). For a new project, edit `pullPath` at the top of the file to your own list, then rebuild. Output directory (`outDir`) is hardcoded the same way — currently `~/SFX/PSE/`.

## 4. Running it

From `studio/`:

```
STAR=1 TAKES=2 node src/PseFetch.res.mjs
```

Environment switches:

| var | meaning | default |
|---|---|---|
| `TAKES` | how many takes to download per query | 2 |
| `STAR` | `1` = only the ★ priority items | off |
| `LIMIT` | cap the number of queries processed | unlimited |
| `HEADED` | `1` = show the browser window (use when debugging login) | headless |
| `TESTHREF` | a single `/sound-effects/...` path: downloads exactly that one sound to prove the mechanism, then exits | unset |

Start with `TESTHREF` on a known-owned sound to confirm the pipe works before launching a long run.

## 5. How the login actually works (the part that breaks)

PSE splits authentication across two hosts. The PSE page takes the **email**, then redirects to Microsoft B2C at `identity.prosoundeffects.com`, which takes the **password**. The relevant selectors are `#signInName`, `#password`, `#next`. A "Stay signed in?" interstitial may appear and is dismissed by clicking through.

After the B2C submit, the `/signin-oidc` callback exchanges the code for tokens **asynchronously via MSAL**. Two consequences, both already handled — preserve them if you touch the code:

1. **Never check auth state once.** The app renders anonymous first and only then hydrates from storage and re-renders. The script polls (8 attempts, 3s apart) and waits for the badge `text=Included in your CORE` to become visible. Checking too early was the original "auth looks flaky" bug.
2. A screenshot of the post-submit state is written to `/tmp/b2c_after_submit.png` for debugging. Look there first when login fails.

Log file: `/tmp/pse_fetch.log`.

## 6. Ownership filtering

The account owns a CORE bundle, not the whole catalogue, so most search results are **not** downloadable. Ownership is determined two ways:

- **Seeded once** from the CORE Standard bundle page, by scraping library codes (`PSE_XXX`) out of the thumbnail URLs.
- **Learned during runs** and persisted to `~/SFX/PSE/_libs.json` as `{owned: [...], unowned: [...]}`. A library proven un-entitled is skipped instantly on later encounters.

On each sound page, the presence of the **"Included in your CORE" badge** is the ownership test. Absent after 12 seconds means premium — the script records the library as unowned and moves on. **Do not click Download during the anonymous render window**; you'll hit the purchase modal instead of a file.

## 7. How the download works

Not through the UI file dialog. The script listens for Playwright's `download` event, which fires with a **pre-signed Azure SAS blob URL** (`blob.core.windows.net/library/wav|mp3/...`), and saves from there. Files land in `outDir` under their suggested filenames; existing files are reported as `(existed)` and not re-fetched.

## 8. Search behaviour worth knowing

Each query is searched twice — once on the first two words, once on the first word alone — and the results merged and de-duplicated. This is deliberate: premium libraries rank highest, so a narrow search often returns nothing owned. The results grid also lazy-loads, so the script scrolls the page five times before harvesting links.

Consequence for writing pull lists: **put the most distinctive word first.** `wooden door slam` works better than `slam wooden door`.

## 9. Outputs

- Audio files → `outDir` (`~/SFX/PSE/`)
- `_manifest.json` → per-query list of what was downloaded (drives resume)
- `_libs.json` → learned owned/unowned library codes
- `/tmp/pse_fetch.log` → run log

## 10. Failure modes and what they mean

| symptom | cause | fix |
|---|---|---|
| `login failed after B2C submit` | credentials wrong, or B2C changed its markup | check `/tmp/b2c_after_submit.png`; verify `~/.pse_credentials` has exactly two lines |
| everything returns `NOT OWNED` | auth didn't hydrate — the badge never appeared | delete `~/.pse_browser` and re-run; run with `HEADED=1` to watch |
| ReScript panic on build | wrong compiler version | `npm ci` in `studio/`; must be 11.1.4 |
| `no-download` | the Download button never fired the event | usually a timing flake; re-run, it's resumable |
| nothing found for a query | the owned libraries genuinely lack it | rewrite the query with the distinctive word first, or fall back (§11) |

## 11. Fallbacks when PSE doesn't own it

- **Freesound** for sharp Foley (real recordings; synthetic Foley sounds weak).
- **AudioLDM**, run locally, for ambience beds.
- AudioGen was evaluated and rejected on this machine: install-hostile and CPU-only.

## 12. Rules

Don't rewrite the fetcher. Don't disable the ownership check to "get more results" — un-entitled downloads are not available and the attempts just slow the run. Don't print credentials. Prefer `TESTHREF` over a full run when verifying a change.
