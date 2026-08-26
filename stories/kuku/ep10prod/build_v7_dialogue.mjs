// EP10 V7 — dialogue generation via the locked ElevenLabs cast registry.
// Parses the screenplay, maps Devanagari character names to their canonical
// voice ids (studio/src/Kuku_Cast.res), renders one mp3 per cue.
// Dry-run by default: `node build_v7_dialogue.mjs --go` to actually spend.
import { execFileSync } from "child_process";
import fs from "fs";

const K = "/Users/dusty/Dev/metaphrand/stories/kuku/";
const SCRIPT = K + "2026-08-20_EP10_ga_gaay_SPEC_SCREENPLAY_v7_AUDIO_FIRST.md";
const OUT = K + "ep10prod/v7_table_read/cues/";
const GO = process.argv.includes("--go");
fs.mkdirSync(OUT, { recursive: true });

const VOICE = {
  "कुकु": "NbvR1eY6Q8ivACdEO8PV", "फ्यूरिया": "FFmp1h1BMl0iVHA0JxrI",
  "वैस्पर": "subIZc6skATBQ1Rbqpi7", "दादी": "nfMYisZqs1GOjTFllho3",
  "कैस्टर": "4iqKdEXMW8NRF8USiS3Q", "लेडा": "nUX4UWK0Tf1qh5zvFZWR",
  "चील": "PId0lEbL3SOYkQZSraml", "ऋषि": "ocf4J1Vk0yOOFNBy3kNq",
};
// the group cheer + the five children speaking together
const CHORUS = { "चारों साथी": ["कुकु", "लेडा", "कैस्टर", "वैस्पर"], "पाँचों बच्चे": ["कुकु", "फ्यूरिया", "लेडा", "कैस्टर", "वैस्पर"] };

const KEY = fs.readFileSync("/Users/dusty/Dev/metaphrand/.env", "utf8")
  .split("\n").find(l => l.startsWith("ELEVENLABS_API_KEY=")).split("=").slice(1).join("=").trim();

const lines = fs.readFileSync(SCRIPT, "utf8").split("\n");
const cues = [];
for (const l of lines) {
  const m = l.match(/^([^\s(:\[#|]+):\s*(?:\(([^)]*)\)\s*)?(.+)$/);
  if (!m) continue;
  const who = m[1], direction = m[2] || "", text = m[3].trim();
  if (!VOICE[who] && !CHORUS[who]) continue;
  cues.push({ who, direction, text });
}

const chars = cues.reduce((s, c) => s + c.text.length, 0);
const words = cues.reduce((s, c) => s + c.text.split(/\s+/).length, 0);
console.log(`cues: ${cues.length}   words: ${words}   billable characters: ${chars}`);
const byWho = {};
cues.forEach(c => { byWho[c.who] = (byWho[c.who] || 0) + 1; });
console.log(Object.entries(byWho).map(([k, v]) => `${k}:${v}`).join("  "));
const speakRequests = cues.reduce((s, c) => s + (CHORUS[c.who] ? CHORUS[c.who].length : 1), 0);
console.log(`provider requests (chorus expanded): ${speakRequests}`);
console.log(`projected speech at 130.6 wpm: ${(words / 130.6 * 60).toFixed(0)}s of dialogue`);
if (!GO) { console.log("\nDRY RUN — rerun with --go to generate."); process.exit(0); }

let made = 0, failed = 0;
cues.forEach((c, i) => {
  const id = String(i).padStart(3, "0") + "_" + c.who;
  const speakers = CHORUS[c.who] ? CHORUS[c.who] : [c.who];
  speakers.forEach((sp, si) => {
    const dst = OUT + id + (speakers.length > 1 ? "_" + sp : "") + ".mp3";
    if (fs.existsSync(dst)) return;
    const body = JSON.stringify({
      text: c.text,
      model_id: "eleven_v3",
      voice_settings: { stability: 0.45, similarity_boost: 0.8, style: 0.35 },
    });
    try {
      execFileSync("curl", ["-s", "-X", "POST",
        `https://api.elevenlabs.io/v1/text-to-speech/${VOICE[sp]}`,
        "-H", `xi-api-key: ${KEY}`, "-H", "Content-Type: application/json",
        "-d", body, "-o", dst], { timeout: 180000 });
      if (fs.statSync(dst).size > 2000) { made++; }
      else { fs.unlinkSync(dst); failed++; console.log("FAIL " + id + " " + sp); }
    } catch (e) { failed++; console.log("ERR " + id + " " + sp); }
  });
  if (i % 20 === 0) console.log(`  …${i}/${cues.length}`);
});
console.log(`DIALOGUE DONE: made=${made} failed=${failed}`);
fs.writeFileSync(K + "ep10prod/v7_table_read/cue_index.json", JSON.stringify(cues, null, 1));
