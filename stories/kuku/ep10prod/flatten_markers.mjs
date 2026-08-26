// The red marks were built as raised wedges standing on the centreline — i.e.
// obstacles in the cart's path — so video quite reasonably drove the cart over
// them like speed bumps. They are distance marks: flat stones set flush into the
// paving. This flattens them in the plate and in the frames the clips start from.
import { execFileSync } from "child_process";
import fs from "fs";
import { editPrompt } from "../../../studio/src/Kuku_PromptSpec.res.mjs";
const P = "/Users/dusty/Dev/metaphrand/stories/kuku/ep10prod/";
const CHANGE = "Make every red marker on the lane FLAT: each becomes a flat red paving stone set flush into the ground, level with the surrounding flagstones, like an inlaid tile. Remove all raised red blocks, wedges, posts and standing markers entirely — nothing red may stick up above the road surface anywhere. Keep their positions on the lane exactly where they are.";
const targets = process.argv.slice(2);
for (const rel of targets) {
  const dst = P + rel;
  if (!fs.existsSync(dst)) { console.log("missing " + rel); continue; }
  const bak = dst.replace(/([^/]+)$/, "PRE_FLAT_$1");
  if (!fs.existsSync(bak)) fs.copyFileSync(dst, bak);
  const prompt = editPrompt({
    change: CHANGE,
    keep: ["the lane itself — same flagstones, kerbs, walls, post, horizon and light", "the cart, the cow and any characters exactly as they are"],
    extraRules: [],
  });
  let raw;
  try {
    raw = execFileSync("higgsfield", ["generate", "create", "nano_banana_pro", "--prompt", prompt,
      "--image", bak, "--aspect_ratio", "16:9", "--resolution", "2k", "--wait", "--json"], { encoding: "utf8", timeout: 900000 });
  } catch (e) { raw = String(e.stdout || "") + String(e.stderr || e.message); }
  const url = (raw.match(/https:\/\/[^"\s]*\.(png|webp|jpg)/) || [null])[0];
  if (url) { execFileSync("curl", ["-sL", "--retry", "3", "-o", dst, url], { timeout: 300000 }); console.log("flattened " + rel); }
  else console.log("FAIL " + rel);
}
