// Scene 1 as MOTION: the four Seedance clips in story order, carrying the
// scene's own dialogue. Picture comes from the clips; if the dialogue outruns
// them the last clip's final frame is held rather than looping, so nothing
// repeats. Built to be judged as a finished minute, not as a test.
import { execFileSync } from "child_process";
import fs from "fs";
const P = "/Users/dusty/Dev/metaphrand/stories/kuku/ep10prod/";
const CUES = P + "v7_table_read/cues/";
const SCRIPT = "/Users/dusty/Dev/metaphrand/stories/kuku/2026-08-20_EP10_ga_gaay_SPEC_SCREENPLAY_v7_AUDIO_FIRST.md";
const B = "/tmp/scene1_build/"; fs.mkdirSync(B, { recursive: true });
const GAP = 0.45;

// which dialogue cues belong to scene 1
const cueFiles = fs.readdirSync(CUES).filter(f => f.endsWith(".mp3")).sort();
let dlg = 0, sceneIdx = 0, mine = [], started = false;
for (const raw of fs.readFileSync(SCRIPT, "utf8").split("\n")) {
  const line = raw.trim();
  if (/^## दृश्य/.test(line)) { if (started) sceneIdx++; started = true; continue; }
  if (!line || line.startsWith("#") || line.startsWith("**") || line.startsWith("|") || line.startsWith("-") || line.startsWith("(")) continue;
  const m = line.match(/^([^:(]{1,12}):\s*(?:\(([^)]*)\)\s*)?(.+)$/);
  if (m && dlg < cueFiles.length) { if (sceneIdx === 2) mine.push(cueFiles[dlg]); dlg++; }
}
const dur = f => +execFileSync("ffprobe", ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", f], { encoding: "utf8" }).trim();
const spoken = mine.reduce((a, f) => a + dur(CUES + f) + GAP, 0);
console.log(`scene 1: ${mine.length} dialogue cues, ${spoken.toFixed(1)}s of speech`);

// picture: the clips in order, normalised, then the tail frozen to cover the speech
const order = ["c1_breaks_away", "c2_five_flank", "c3_failed_lift", "c4_wheels_return"];
const parts = [];
order.forEach((t, i) => {
  const src = P + `clips/SCENE1_${t}.mp4`, out = B + `p${i}.mp4`;
  execFileSync("ffmpeg", ["-v", "error", "-y", "-i", src, "-vf", "scale=1920:1080,fps=30,format=yuv420p",
    "-c:v", "libx264", "-crf", "20", "-preset", "veryfast", "-an", out], { timeout: 600000 });
  parts.push(out);
});
const clipTotal = parts.reduce((a, f) => a + dur(f), 0);
// Only carry the dialogue that FITS the motion. Freezing the last frame for 42
// seconds would be dishonest about what these clips deliver — better to show a
// true 25 seconds of motion and state plainly what full coverage would cost.
{
  let acc = 0; const fits = [];
  for (const f of mine) { const d = dur(CUES + f) + GAP; if (acc + d > clipTotal) break; fits.push(f); acc += d; }
  console.log(`carrying ${fits.length} of ${mine.length} cues — ${acc.toFixed(1)}s of speech over ${clipTotal.toFixed(1)}s of motion`);
  mine.length = 0; mine.push(...fits);
}
if (false) {
  const hold = spoken - clipTotal + 0.5;
  execFileSync("ffmpeg", ["-v", "error", "-y", "-sseof", "-0.1", "-i", parts[parts.length - 1],
    "-vf", `scale=1920:1080,fps=30,tpad=stop_mode=clone:stop_duration=${hold.toFixed(2)},format=yuv420p`,
    "-c:v", "libx264", "-crf", "20", "-preset", "veryfast", "-an", B + "tail.mp4"], { timeout: 600000 });
  parts.push(B + "tail.mp4");
  console.log(`held the last frame for ${hold.toFixed(1)}s to cover the speech`);
}
fs.writeFileSync(B + "cat.txt", parts.map(p => `file '${p}'`).join("\n") + "\n");
execFileSync("ffmpeg", ["-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", B + "cat.txt", "-c", "copy", B + "picture.mp4"], { timeout: 900000 });

// dialogue laid down in order over the picture
const inputs = [], filters = [];
let t = 0;
mine.forEach((f, i) => {
  inputs.push("-i", CUES + f);
  filters.push(`[${i}:a]adelay=${Math.round(t * 1000)}|${Math.round(t * 1000)}[a${i}]`);
  t += dur(CUES + f) + GAP;
});
const fc = filters.join(";") + ";" + mine.map((_, i) => `[a${i}]`).join("") + `amix=inputs=${mine.length}:normalize=0[aout]`;
execFileSync("ffmpeg", ["-v", "error", "-y", ...inputs, "-filter_complex", fc, "-map", "[aout]",
  "-c:a", "aac", "-b:a", "192k", "-ar", "44100", "-ac", "2", B + "dialogue.m4a"], { timeout: 900000 });
execFileSync("ffmpeg", ["-v", "error", "-y", "-i", B + "picture.mp4", "-i", B + "dialogue.m4a",
  "-map", "0:v", "-map", "1:a", "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
  "-movflags", "+faststart", "-shortest", P + "EP10_SCENE1_MOTION.mp4"], { timeout: 900000 });
console.log("EP10_SCENE1_MOTION.mp4 — " + dur(P + "EP10_SCENE1_MOTION.mp4").toFixed(1) + "s");
