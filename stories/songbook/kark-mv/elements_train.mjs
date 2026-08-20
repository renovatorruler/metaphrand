// Final elements pipeline: 4 anchored views per approved canonical (12 gens),
// then soul-id training per character on its 5-image set. Skip-if-exists.
import { execFileSync } from "child_process";
import fs from "fs";

const D = "/Users/dusty/Dev/metaphrand/stories/songbook/kark-mv/elements";
const P = "Sharp photorealistic portrait photograph of the SAME PERSON as the reference image — identical face, identical features, identical clothing style. Natural light, plain neutral background. No text anywhere. ";

const chars = [
  ["mangu", "mangu_c3.png", [
    "Three-quarter view from his left, warm confident smile, chin up.",
    "Right profile portrait, dignified, mustache and safa clear.",
    "Front-facing, mid-song: mouth open singing, brow intense, passionate.",
    "Three-quarter from his right, laughing heartily, eyes crinkled.",
  ]],
  ["husband", "husband_c3.png", [
    "Three-quarter view from his left, listening with quiet amusement.",
    "Right profile portrait, calm, head slightly bowed.",
    "Front-facing, laughing softly, eyes bright.",
    "Three-quarter from his right, serious and gentle, evening light.",
  ]],
  ["wife", "wife_c6.png", [
    "Three-quarter view from her left, faint knowing smile.",
    "Right profile portrait, composed, chin level, pallu over head.",
    "Front-facing, laughing warmly against her will.",
    "Three-quarter from her right, tired but resolute, soft evening light.",
  ]],
];

const run = (args) => {
  try { return execFileSync("higgsfield", args, { encoding: "utf8", timeout: 900000 }); }
  catch (e) { return String(e.stdout || "") + String(e.stderr || e.message); }
};

let made = 0, failed = [];
for (const [slug, canon, views] of chars) {
  views.forEach((view, i) => {
    const out = `${D}/${slug}_t${i + 1}.png`;
    if (fs.existsSync(out)) return;
    const raw = run(["generate", "create", "nano_banana_pro", "--prompt", P + view, "--image", `${D}/${canon}`, "--aspect_ratio", "3:4", "--resolution", "2k", "--wait", "--json"]);
    const url = (raw.match(/https:\/\/[^"\s]*\.(png|webp|jpg)/) || [null])[0];
    if (url) { execFileSync("curl", ["-sL", "--retry", "2", "-o", out, url], { timeout: 300000 }); made++; console.log("OK " + slug + "_t" + (i + 1)); }
    else { failed.push(slug + "_t" + (i + 1)); console.log("FAIL " + slug + "_t" + (i + 1) + ": " + raw.slice(0, 150)); }
  });
}
console.log(`views: made=${made} failed=${failed.length} ${failed.join(",")}`);
if (failed.length) process.exit(1);

const names = { mangu: "Mangu Bhopa", husband: "Kark Husband", wife: "Kark Wife" };
for (const [slug, canon, views] of chars) {
  const imgs = [`${D}/${canon}`, ...views.map((_, i) => `${D}/${slug}_t${i + 1}.png`)];
  const args = ["soul-id", "create", "--name", names[slug], "--soul-2"];
  imgs.forEach(p => { args.push("--image", p); });
  const raw = run([...args, "--json"]);
  console.log("TRAIN " + slug + ": " + raw.slice(0, 400).replace(/\n/g, " "));
}
console.log("training submitted — poll with: higgsfield soul-id list");
