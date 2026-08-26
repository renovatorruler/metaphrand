import { execFileSync } from "child_process";
import fs from "fs";
const A = "/Users/dusty/Dev/metaphrand/stories/songbook/kark-mv/atape/";
// Motion law: he does NOT bow — a bhopa bows between sung lines, and seedance
// cannot render the stroke. Wind, weather and breath carry the movement.
const BASE = "Animate this exact frame. He is SINGING, not bowing: his bow hand stays still and resting, the bow does not move across the strings at any point. His mouth opens and closes on long held phrases, his throat and chest work with the breath, his head tilts back slightly on the highest notes and settles again. ";
const WIND = "The saffron safa tail and the red sacred threads on his wrist stream and snap in the strong wind; his kurta and shawl ripple; the hanging medallions on the instrument sway gently. ";
const HOLD = "Locked-off camera: no pan, no tilt, no zoom, no push. Single continuous take, no cuts. Everything stays exactly as in the first frame — same man, same face, same clothes, same instrument, same rooftop, same light. Photoreal, cinematic. ";
const SHOTS = [
  ["c1_wide_gold", "480p", BASE + WIND + "Wide: his troupe behind him at the roof edge stay completely still and waiting — the seated dholak player keeps his palm resting flat on the drum skin and never strikes it. The oil lamp flame flickers; the unrolled scroll lifts at one corner. Far off, the storm wall drifts almost imperceptibly closer over the city. " + HOLD],
  ["c2_mid_gold", "720p", BASE + WIND + "Medium: golden sunset light rakes his face; distant rain curtains drift slowly over the city behind him. " + HOLD],
  ["c3_close_storm", "720p", BASE + WIND + "Close: his brow knots and releases with the phrase, his eyes stay locked on the lens; the storm sky churns slowly behind him and the light shifts grey-gold across his face. " + HOLD],
  ["c4_ivstand_storm", "480p", BASE + WIND + "Medium-wide: the red thread tied to the IV stand's chrome pole whips horizontally in the wind and the stand rocks very slightly; the drip bag sways. Storm light moves over the concrete. " + HOLD],
  ["c5_wide_storm", "480p", BASE + WIND + "Wide at storm peak: his face is turned up at the sky as he sings, back arched; the whole sky churns and darkens, the first heavy raindrops begin to fall and strike the concrete; his troupe brace at the roof edge, still not playing. " + HOLD],
  ["c6_close_rain", "720p", BASE + "Close in heavy rain: water runs off the safa and his beard, raindrops streak past the lens and burst on his shoulders, his eyes stay on the lens as he sings; the city lights smear wet behind him. " + HOLD],
];
let spent = 0;
for (const [name, res, prompt] of SHOTS) {
  const out = A + "clip_" + name + ".mp4";
  if (fs.existsSync(out)) { console.log("skip " + name); continue; }
  let raw;
  try {
    raw = execFileSync("higgsfield", ["generate", "create", "seedance_2_5", "--mode", "omni_reference",
      "--prompt", prompt, "--start-image", A + name + ".png", "--duration", "10",
      "--aspect_ratio", "16:9", "--resolution", res, "--generate_audio", "false", "--wait", "--json"],
      { encoding: "utf8", timeout: 1800000 });
  } catch (e) { raw = String(e.stdout || "") + String(e.stderr || e.message); }
  let url = (raw.match(/https:\/\/[^"\s]*\.mp4/) || [null])[0];
  if (!url) { try { const j = JSON.parse(raw); const a = Array.isArray(j) ? j : [j]; url = (a[0] && a[0].result_url) || null; } catch (e) {} }
  if (url) { execFileSync("curl", ["-sL", "--retry", "2", "-o", out, url], { timeout: 600000 });
    spent += res === "720p" ? 65 : 25; console.log("OK " + name + " (" + res + ")"); }
  else console.log("FAIL " + name + ": " + raw.slice(0, 150));
}
console.log("~" + spent + " credits spent");
