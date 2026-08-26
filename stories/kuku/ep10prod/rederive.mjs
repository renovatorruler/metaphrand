// Re-derive in-between frames whose HERO has been regenerated since.
//
// A derivation inherits its parent's set, style and characters, so when a hero
// is re-rolled its old derivations become stale — the cut then mixes two
// different lanes. This re-runs only the affected rows from gen_inbetweens.mjs,
// with the edit prompt rendered by the engine (Kuku_PromptSpec.editPrompt) so
// the standing laws travel with it.
//
//   node rederive.mjs              # list what is stale, spend nothing
//   node rederive.mjs --go         # re-derive them (2cr each)
//   node rederive.mjs --go h16_five_flank h20_furia_brake   # only these heroes
import { execFileSync } from "child_process";
import fs from "fs";
import { editPrompt } from "../../../studio/src/Kuku_PromptSpec.res.mjs";

const P = "/Users/dusty/Dev/metaphrand/stories/kuku/ep10prod/";
const S = P + "stills/", OUT = P + "inbetweens/";

// the derivation table, read from the original script so it stays single-source
const src = fs.readFileSync(P + "gen_inbetweens.mjs", "utf8");
const rows = [...src.matchAll(/\["(h\d+_[a-z_0-9]+)",\s*"([a-z_0-9]+)",\s*"([^"]+)"\]/g)]
  .map(m => ({ hero: m[1], variant: m[2], change: m[3] }));

const args = process.argv.slice(2);
const go = args.includes("--go");
const only = args.filter(a => !a.startsWith("--"));

// stale = the hero file is NEWER than its derivation
const stale = rows.filter(r => {
  const hero = S + r.hero + ".png";
  const der = OUT + `${r.hero}__${r.variant}.png`;
  if (!fs.existsSync(hero) || !fs.existsSync(der)) return false;
  if (only.length && !only.includes(r.hero)) return false;
  return fs.statSync(hero).mtimeMs > fs.statSync(der).mtimeMs;
});

console.log(`${stale.length} stale derivation(s) of ${rows.length} total`);
stale.forEach(r => console.log(`  ${r.hero}__${r.variant}`));
if (!go) { console.log("\ndry run — pass --go to re-derive (2cr each)"); process.exit(0); }

let made = 0, failed = [];
for (const r of stale) {
  // If the hero carries a locally composited element (the ग), derive from the
  // PRE-COMPOSITE frame — otherwise nano is asked to redraw the letter and gets
  // it wrong, which is the exact failure the composite exists to prevent. The
  // element is re-applied afterwards by ga_composite.mjs.
  const rawHero = S + "RAW_" + r.hero + ".png";
  const hero = fs.existsSync(rawHero) ? rawHero : S + r.hero + ".png";
  const dst = OUT + `${r.hero}__${r.variant}.png`;
  const bak = OUT + `PRE_RESET_${r.hero}__${r.variant}.png`;
  if (!fs.existsSync(bak)) fs.copyFileSync(dst, bak);
  const prompt = editPrompt({
    change: r.change,
    keep: [
      "the set exactly as the attached image has it — the same ground, landmarks, walls, kerbs and horizon",
      "every character's design, colours, scale and golden bracelet",
    ],
    extraRules: [],
  });
  let raw;
  try {
    raw = execFileSync("higgsfield", ["generate", "create", "nano_banana_pro", "--prompt", prompt,
      "--image", hero, "--aspect_ratio", "16:9", "--resolution", "2k", "--wait", "--json"],
      { encoding: "utf8", timeout: 900000 });
  } catch (e) { raw = String(e.stdout || "") + String(e.stderr || e.message); }
  const url = (raw.match(/https:\/\/[^"\s]*\.(png|webp|jpg)/) || [null])[0];
  if (url) { execFileSync("curl", ["-sL", "--retry", "3", "-o", dst, url], { timeout: 300000 }); made++; console.log("OK " + r.hero + "__" + r.variant); }
  else { failed.push(r.hero + "__" + r.variant); console.log("FAIL " + r.hero + "__" + r.variant); }
}
console.log(`RE-DERIVED: ${made} ok, ${failed.length} failed ${failed.join(",")}`);
