# studio

The story engine, built as **software** — a typed, tested ReScript project — instead of a pile of documents and throwaway scripts.

## The umbrella rule

Every assumption lives in the **types**, where the compiler enforces it. Not in a doc I might not open, not in a memory I might ignore, not in a comment. If a rule matters, it becomes a type, and breaking it is a **build error**, not a bad habit.

## The four principles

1. **Distinct concepts, distinct types.** A city is not a country; a rule name is not a snippet. Each gets its own `@unboxed` newtype — zero runtime cost, but the compiler refuses to let them be swapped (`u.city = u.country` won't typecheck).
2. **Impossible states impossible.** Encode dependencies as *sum types*, not optional fields on a flat record. If a country has no states, an address there structurally cannot carry one — at the granularity that matters (the dependency), not max precision.
3. **No defaults.** Never a sentinel (`""`, `-1`, a zero-value). Use `option` only for *independent, reasonless* absence; use `result` when a failure carries a cause that `None` would throw away.
4. **No escape hatches.** `Obj.magic`, `%raw`, `%identity` — banned, because an escape hatch is exactly how the three above get routed around. **The build refuses them** (`npm run lint:hatches`), so it isn't a matter of trust. If one is ever genuinely needed, stop and ask.

## The contract — `src/Gate.resi`

`Gate.clean` is an **abstract type**: no constructor outside the `Gate` module. The only way to hold a `clean` is to run `craftlint` and pass. So:

- **Ungated text cannot reach the output.** `Pipeline.ship` demands a `clean`; hand it `rawText` and it won't compile. (Proven — try uncommenting the cheat in `Pipeline.res`.)
- **A passed gate is never re-run.** Clean text has the wrong type to go back into `craftlint`. The proof rides in the type, so no model call is wasted re-checking what's proven.

This is *parse, don't validate*: a gate returns a value that proves it passed, not a boolean you can ignore.

## Build & test

```sh
cd studio
npm install
npm test      # escape-hatch gate, then compile, then the contract tests
```

The build is the first gate. The escape-hatch gate runs before it. Tests must pass.

## Next (not yet built)

- **The brake before the engine:** a budgeted, capped model caller — the in-code governor — before any pass touches a model. The hard wall (no credential on this machine) is a deployment concern; this is the in-code half.
- The full pipeline pass-state in the type, so a scene carries exactly which passes it has cleared.
