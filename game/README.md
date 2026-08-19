# «Фрося и Вася» — literacy game, proof of concept

Defold 1.13.0. The child writes the letters that make the spells fire.

## The language split (CLAUDE.md exception, 2026-08-13)
`studio/src/Drakosha_GamePlan.res` owns the episode data and validates the pedagogy;
it EMITS `main/episode1.lua`. Hand-written Lua here is engine glue only:
`main/main.script` (input, screens) and `main/strokes.lua` (stroke templates + scorer).
No episode content is ever authored in Lua.

## Build
    export PATH=/opt/homebrew/opt/openjdk/bin:$PATH
    java -jar ../tools/bob.jar -p wasm-web --archive resolve build bundle -bo ../game_dist      # HTML5
    java -jar ../tools/bob.jar -p arm64-macos --archive resolve build bundle -bo ../game_dist_mac  # native

Note: the bundle output directory must be OUTSIDE the project (Defold reserves `build/`).

## Regenerate the episode data
    cd ../studio && npx rescript build && node src/Drakosha_GameEp1.res.mjs

## What the PoC proves
- episode data flows ReScript → Lua → engine
- stroke scoring works: perfect 1.00, wobbly 0.95, drawn backwards 1.00, wrong letter 0.01
- a full chapter plays: СОК → МАМА → КОТ, letter by letter, stroke by stroke
- no fail state: after two misses the threshold drops 0.62 → 0.40 and a hint plays
- the child's trace draws live on the tile in the show's gold
