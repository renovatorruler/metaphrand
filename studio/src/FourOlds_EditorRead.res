/* THE FOUR OLDS — a substance-level editorial read of the assembled v14.2
   feature. ONE stateful editor pass (the converging-editor law: one editor,
   not fresh multi-critics) over the whole fountain, judged against the
   project's own hard laws, producing a ranked punch-list of the strongest
   weaknesses with scene references and concrete fix directions.
   Run: CLAUDE_STUDIO_TURN_TIMEOUT_MS=600000 CLAUDE_STUDIO_BUDGET=10 node src/FourOlds_EditorRead.res.mjs */

@module("fs") external readFileSync: (string, string) => string = "readFileSync"
@module("fs") external writeFileSync: (string, 'a) => unit = "writeFileSync"
@val @scope("Buffer") external bufferFrom: 'a => 'b = "from"

let fountain = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/draft/THE-FOUR-OLDS_v14.2_2026-07-12_2100.fountain"
let outPath = "/Users/dusty/Dev/metaphrand/.claude/worktrees/rosca-pitch/stories/four-olds/2026-07-13_V14.2_EDITOR_READ.md"

let charter = "You are the story editor for THE FOUR OLDS — a feature comedy: four retired NASA backup astronauts (Cricket, Dutch, Stitch, Gunny — THE VARSITY CORE: the best who never got to prove it, and they know it) smuggle themselves inside museum flag-crates onto the regime's Moon-flag-retrieval mission; the climax is an illegal Fourth of July cookout on the Moon. Register: rage-and-release, a comedy; Taylor Sheridan action-line camera (NO similes/aphorisms); civilian-legible always.\n\nRead the COMPLETE screenplay below and produce THE PUNCH-LIST: the 10 strongest SUBSTANCE weaknesses, ranked by structural consequence (worst first). Judge against these laws:\n1. MAMET: every scene — who wants what, what's the wall, does it TURN? Name scenes that are information or mood only.\n2. COMEDY: is it FUNNY where it must be? Native humor (no imported gag shapes); the varsity arrogance played dead straight; flag any scene where solemnity crept back in.\n3. THE FOUR DISTINCT: in group scenes do Cricket/Dutch/Stitch/Gunny each sound like themselves (checklist / specification / mythic drawl / military-sacred), or do they blur?\n4. RAGE LADDER: do the insults escalate OFF-space (church bells, meat quotas, Legion flags, the worksheet), and does EVERY Act-3 image pay a specific Act-2 insult? Name any unpaid insult or unearned payoff.\n5. MIRROR: sc06 doorway stand (Cricket fails) must be QUOTED by the Moon standoff (Cricket holds). Is the staging actually parallel on the page — posture, cadence, lines?\n6. INTRIGUE CHAINS: hints early that reveal later (the over-spec crates, the ghost file, the primer). Does each chain terminate in a reveal worth the wait? Any dangling or telegraphed?\n7. LIKABILITY: liking vs rooting vs fascination — where does the audience's ROOTING interest sag, especially Act 2?\n8. CIVILIAN PASS: any beat only an insider parses?\n9. STAKES/CLOCK: where does the caper lose its clock?\n10. THE ENDING: does the ramp sacrifice + Ranger coda land earned, or declared?\n\nFORMAT — exactly:\n## PUNCH-LIST\nFor each item:\nN. [SCENE(s) X] TITLE — one line naming the weakness\n   WHY: 2-3 sentences, concrete, quoting the page where useful\n   FIX: the specific direction (beat-level, not vague)\nThen:\n## WHAT ALREADY WORKS (do not touch)\n5 bullets — the strongest things in the draft, so fixes never break them.\nNo praise padding. No line-editing (that is a later pass). Substance only."

let main = async () => {
  let script = readFileSync(fountain, "utf8")
  let answer = await Session.ask(charter ++ "\n\n=== THE SCREENPLAY (v14.2) ===\n\n" ++ script)
  writeFileSync(outPath, bufferFrom("# V14.2 editor read — " ++ "2026-07-13" ++ "\n\n" ++ answer))
  Js.log("WROTE " ++ outPath)
  Session.close()
}
main()->ignore
