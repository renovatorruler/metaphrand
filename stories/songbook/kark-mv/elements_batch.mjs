// ELEMENTS training diet — 5 consistent views per character, anchored on the
// canonical crop, Malwa lock in every prompt. 15 gens total, skip-if-exists.
import { execFileSync } from "child_process";
import fs from "fs";

const D = "/Users/dusty/Dev/metaphrand/stories/songbook/kark-mv/elements";
const MALWA = "North Indian man from the Malwa region, wheat-brown complexion. ";
const MALWA_F = "North Indian woman from the Malwa region, wheat-brown complexion. ";
const PHOTO = "Sharp photorealistic portrait photograph, natural light, plain neutral background, 85mm lens look. The SAME PERSON as the reference image — identical face, identical features. No text anywhere. ";

const chars = [
  ["mangu", `${D}/ref_mangu.png`, MALWA + "A charismatic folk-singer of 58, groomed silver-streaked beard, immaculate saffron turban, deep-red silk kurta, silver neckpiece. ", [
    "Front-facing portrait, calm confident expression, looking straight into the lens.",
    "Three-quarter view from his left, gentle smile, chin slightly up.",
    "Right profile portrait, dignified, eyes forward.",
    "Front-facing, mid-song expression: mouth open singing, brow intense.",
    "Three-quarter from his right, laughing warmly, eyes crinkled.",
  ]],
  ["husband", `${D}/ref_him.png`, MALWA + "A thin man of 60, hollow-cheeked from long illness, sparse grey stubble beard, knitted woolen cap, brown shawl over hospital clothes, warm tired eyes. ", [
    "Front-facing portrait, the dry half-smile of a man mid-joke, looking into the lens.",
    "Three-quarter view from his left, listening, slight amusement.",
    "Right profile portrait, calm, head slightly bowed.",
    "Front-facing, laughing softly despite tiredness.",
    "Three-quarter from his right, serious and gentle, eyes moist.",
  ]],
  ["wife", `${D}/ref_her.png`, MALWA_F + "A woman of 55, deep-green cotton sari, grey-streaked black hair in a tight bun, small gold nose stud, small earrings, strong steady bearing, distinctly North Indian Malwa features. ", [
    "Front-facing portrait, calm level gaze straight into the lens, unhurried competence.",
    "Three-quarter view from her left, faint knowing smile.",
    "Right profile portrait, composed, chin level.",
    "Front-facing, laughing against her will, hand not visible.",
    "Three-quarter from her right, tired but resolute, evening light.",
  ]],
];

const run = (args) => {
  try { return execFileSync("higgsfield", args, { encoding: "utf8", timeout: 600000 }); }
  catch (e) { return String(e.stdout || "") + String(e.stderr || e.message); }
};

let made = 0, failed = [];
for (const [slug, ref, desc, views] of chars) {
  views.forEach((view, i) => {
    const out = `${D}/${slug}_v${i + 1}.png`;
    if (fs.existsSync(out)) return;
    const raw = run(["generate", "create", "nano_banana_pro", "--prompt", PHOTO + desc + view, "--image", ref, "--aspect_ratio", "3:4", "--resolution", "2k", "--wait", "--json"]);
    const url = (raw.match(/https:\/\/[^"\s]*\.(png|webp|jpg)/) || [null])[0];
    if (url) { execFileSync("curl", ["-sL", "--retry", "2", "-o", out, url], { timeout: 300000 }); made++; console.log("OK " + slug + "_v" + (i + 1)); }
    else { failed.push(slug + "_v" + (i + 1)); console.log("FAIL " + slug + "_v" + (i + 1) + ": " + raw.slice(0, 150)); }
  });
}
console.log(`\nmade=${made} failed=${failed.length} ${failed.join(",")}`);
