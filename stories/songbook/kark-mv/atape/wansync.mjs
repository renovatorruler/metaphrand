import { execFileSync } from "child_process";
import fs from "fs";
const A = "/Users/dusty/Dev/metaphrand/stories/songbook/kark-mv/";
const BASE = "A Rajasthani folk singer performing, his mouth driven by the audio. The size of his mouth opening follows the loudness of the voice at every moment — barely parted when the singing is soft, opening wide only at the loudest points, easing shut between phrases. His throat and chest work with the breath; his head tilts back as notes rise. His bow hand stays still and resting on the instrument — he is singing, not bowing, and the bow never crosses the strings. Locked-off camera, no pan, no tilt, no zoom, single continuous take. Everything else stays exactly as in the start frame — same man, same face, same clothes, same instrument, same rooftop. Photoreal, cinematic. ";
// [still, audio start, sky note] — sky progresses gold -> storm -> rain across the film
const SHOTS = [
  ["c1_wide_gold", 17, "Wide: his troupe behind him at the roof edge stay completely still, the seated dholak player's palm resting flat on the skin, never striking. Golden evening light, the storm still far off. Saffron turban tail and wrist threads lift in a light wind."],
  ["c5_wide_storm", 67, "Wide: the storm has crossed overhead, wind strong — turban tail and red wrist threads stream horizontally, kurta and shawl ripple hard, the sky churns slowly behind him."],
  ["c3_close_storm", 134, "Close: his brow knots and releases with each phrase, eyes locked on the lens, wind lifting the turban tail across the frame, grey-gold storm light shifting on his face."],
  ["c4_ivstand_storm", 161, "Medium-wide: the red thread tied to the IV stand's chrome pole whips in the wind and the stand rocks slightly; storm light moves across the concrete."],
  ["c6_close_rain", 228.5, "Close in heavy rain: water runs off the turban and his beard, raindrops streak past and burst on his shoulders, city lights smeared wet behind him."],
];
for (const [name, at, sky] of SHOTS) {
  const out = A + "atape/wan_" + name + ".mp4";
  if (fs.existsSync(out)) { console.log("skip " + name); continue; }
  const wav = "/tmp/aud_" + name + ".mp3";
  execFileSync("ffmpeg", ["-v", "error", "-y", "-ss", String(at), "-t", "10", "-i", A + "kark_ki_taanti_master.mp3",
    "-ar", "44100", "-ac", "2", "-b:a", "192k", wav], { timeout: 120000 });
  let raw;
  try {
    raw = execFileSync("higgsfield", ["generate", "create", "wan2_7", "--prompt", BASE + sky,
      "--start-image", A + "atape/" + name + ".png", "--audio", wav,
      "--duration", "10", "--resolution", "720p", "--wait", "--json"], { encoding: "utf8", timeout: 1800000 });
  } catch (e) { raw = String(e.stdout || "") + String(e.stderr || e.message); }
  let url = (raw.match(/https:\/\/[^"\s]*\.mp4/) || [null])[0];
  if (!url) { try { const j = JSON.parse(raw); const a = Array.isArray(j) ? j : [j]; url = a[0].result_url || null; } catch (e) {} }
  if (!url) { console.log("FAIL " + name + ": " + raw.slice(0, 130)); continue; }
  execFileSync("curl", ["-sL", "--retry", "3", "-o", out, url], { timeout: 600000 });
  const frames = execFileSync("ffprobe", ["-v", "error", "-count_frames", "-select_streams", "v:0",
    "-show_entries", "stream=nb_read_frames", "-of", "csv=p=0", out], { encoding: "utf8" }).trim();
  console.log((+frames > 200 ? "OK   " : "BAD  ") + name + "  (audio " + at + "s, " + frames + " frames)");
}
