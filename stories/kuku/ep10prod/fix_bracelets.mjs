// The कड़ा law, applied. Two stages:
//   A. corrected great-form boards (written to ep10prod/elements/, never mutating
//      EP9's shared assets) so every FUTURE frame inherits the bracelet;
//   B. an edit-in pass over the 45 existing great-form frames — bracelet added,
//      composition/palette/characters untouched.
// `--boards` for stage A only, `--frames` for stage B, no flag = both.
import { execFileSync } from "child_process";
import fs from "fs";

const K = "/Users/dusty/Dev/metaphrand/stories/kuku/";
const E = K + "ep9prod/coldopen/elements/";
const OUTE = K + "ep10prod/elements/"; fs.mkdirSync(OUTE, { recursive: true });
const S = K + "ep10prod/stills/", I = K + "ep10prod/inbetweens/";
const only = process.argv[2];

const gen = (prompt, refs, dst) => {
  const args = ["generate", "create", "nano_banana_pro", "--prompt", prompt];
  refs.forEach(r => { if (fs.existsSync(r)) args.push("--image", r); });
  args.push("--aspect_ratio", "16:9", "--resolution", "2k", "--wait", "--json");
  let raw;
  try { raw = execFileSync("higgsfield", args, { encoding: "utf8", timeout: 900000 }); }
  catch (e) { raw = String(e.stdout || "") + String(e.stderr || e.message); }
  let url = (raw.match(/https:\/\/[^"\s]*\.(png|webp|jpg)/) || [null])[0];
  if (!url) { try { const j = JSON.parse(raw); const a = Array.isArray(j) ? j : [j]; url = a[0].result_url || null; } catch (e) {} }
  if (!url) return false;
  execFileSync("curl", ["-sL", "--retry", "3", "-o", dst, url], { timeout: 300000 });
  return true;
};

const BRACELET = "Edit this image so the dragon visibly wears its golden कड़ा bracelet: a thick matte-gold paper cuff around the forearm, clearly readable, with a small blank golden medallion set into it. Keep EVERYTHING else identical — same papercraft medium, same layered cut-paper texture, same colours, same palette, same character design, same pose, same background, same lighting. Add only the bracelet. No readable text, letters, numbers or glyphs anywhere.";

// ---- stage A: the five great-form boards -----------------------------------
if (only !== "--frames") {
  const boards = ["future_kuku_board_v1", "future_fyuria_board_v1", "future_leda_board_v1", "future_castor_board_v1", "future_vesper_board_v1"];
  let ok = 0;
  boards.forEach(b => {
    const dst = OUTE + b.replace("_v1", "_bracelet") + ".png";
    if (fs.existsSync(dst)) { console.log("skip board " + b); ok++; return; }
    if (gen(BRACELET, [E + b + ".png"], dst)) { ok++; console.log("OK board " + b); }
    else console.log("FAIL board " + b);
  });
  console.log(`BOARDS: ${ok}/5 corrected → ep10prod/elements/`);
}

// ---- stage B: the 45 existing great-form frames -----------------------------
if (only !== "--boards") {
  const G = ["h01", "h03", "h04", "h06", "h14", "h16", "h17", "h20", "h21", "h22", "h24", "h25", "h27", "h28", "h31", "h34", "h36"];
  const targets = [
    ...fs.readdirSync(S).filter(f => f.endsWith(".png") && !f.startsWith("PRE_") && G.some(g => f.startsWith(g + "_"))).map(f => [S, f]),
    ...fs.readdirSync(I).filter(f => f.endsWith(".png") && G.some(g => f.startsWith(g + "_"))).map(f => [I, f]),
  ];
  let made = 0, failed = [];
  targets.forEach(([dir, f], n) => {
    const src = dir + f;
    const bak = dir + "PRE_KADA_" + f;
    if (fs.existsSync(bak)) { console.log("skip " + f); return; }
    fs.copyFileSync(src, bak);
    if (gen(BRACELET, [src], src)) { made++; console.log(`OK ${n + 1}/${targets.length} ${f}`); }
    else { fs.copyFileSync(bak, src); fs.unlinkSync(bak); failed.push(f); console.log("FAIL " + f); }
  });
  console.log(`BRACELETS: made=${made} failed=${failed.length} ${failed.join(",")}`);
}
