// prompt-fixtures.mjs — the gate must REFUSE the prompts that made the bad frames.
// Zero cost: no provider call. Lesson 10 — a guard that has never failed on a
// known-bad input has not been tested.
//
// The known-bad prompts are PINNED under scripts/prompt-fixtures/ as the exact
// text the receipts carried on 2026-09-04 (commit fe43c9f). They used to be read
// from the live receipts, which broke the moment those shots were lawfully
// regenerated: a fixture that reads a moving file tests the file, not the gate.
import fs from "fs";
import * as G from "../src/PromptGate.res.mjs";
import * as E from "../src/Kuku_Engine.res.mjs";
const DIR = new URL("./prompt-fixtures/", import.meta.url).pathname;
const BAD = [
  ["s33e still (small + lit lamp)",       "s33e.prompt.txt"],
  ["s52 still (invented glyph)",         "s52.prompt.txt"],
  ["s27 clip ('the five', pronouns)",    "s27.prompt.txt"],
  ["s33c clip ('five great dragons')",   "s33c.prompt.txt"],
];
let fails = 0;
for (const [label, file] of BAD) {
  const prompt = fs.readFileSync(DIR + file, "utf8");
  const found = G.scanStrict(prompt);
  const ok = found.length > 0;
  if (!ok) fails++;
  console.log(`  ${ok ? "REFUSED" : "PASSED!!"}  ${label}  (${found.length} findings${ok ? ": " + found[0].slice(0, 70) : ""})`);
}
// a prompt written under the law must pass: every actor named in every sentence
const GOOD = `SHOT: MEDIUM
SCENE: कुकु sits at the niche and लेडा leans toward कुकु.
- KUKU — green paper dragon, small everyday form. कुकु sits close to the niche shelf with both paws on the stone.
- LEDA — lavender paper dragon, small everyday form. लेडा leans toward कुकु with one claw raised.
LIGHTING: Deep blue darkness. All light comes from the night sky.
HARD RULES:
- THE NICHE SHELF IS BARE STONE, in shadow.`;
const g = G.scanStrict(GOOD);
if (g.length) { fails++; console.log("  BAD: the lawful prompt was refused:", g); } else console.log("  PASSED   lawful per-name prompt");
// THE INVARIANT THAT FAILED ON 2026-09-02: a reference in the receipt is a
// reference in the call, because both are rendered from one list.
const R = (TAG, _0) => ({ TAG, _0 });
const refs = [R("Style","key.png"), R("Plate","plate.png"), R("Start","a.png"), R("Board","kuku.png")];
const argv = E.argsOfRefs(true, refs);
const paths = refs.map(E.pathOf);
const missing = paths.filter(p => !argv.includes(p));
if (missing.length) { fails++; console.log("  BAD: refs absent from the call:", missing); }
else console.log("  PASSED   every reference in the receipt appears in the provider call");
// and a start frame cannot be an end frame: the types differ, so this is a
// compile-time guarantee — asserted here by checking the flags they render to
const flags = E.argsOfRefs(true, [R("Start","s.png"), R("End","e.png")]);
if (flags[0] !== "--start-image" || flags[2] !== "--end-image") { fails++; console.log("  BAD frame flags:", flags); }
else console.log("  PASSED   start and end frames render to their own flags");
console.log(fails ? `PROMPT FIXTURES: ${fails} FAILED` : "PROMPT FIXTURES: all known-bad prompts refused, lawful prompt passed");
process.exit(fails ? 1 : 0);
