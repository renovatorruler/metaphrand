// assemble_act.mjs — cut a range of EP10 shots with the table read over them.
//
// Each shot holds for as long as its own dialogue needs, so picture and voice
// stay locked without stretching anything: a motion clip plays and then freezes
// on its last frame if the line runs longer; a dialogue still simply holds.
//
//   node assemble_act.mjs <firstShotNum> <lastShotNum> <out.mp4>
import { execFileSync } from "child_process";
import fs from "fs";

const P = new URL("./", import.meta.url).pathname;
const B = P + "build/"; fs.mkdirSync(B, { recursive: true });
const W = 1280, H = 720, FPS = 24, GAP = 0.28;
const HEAD = 0.25, TAIL = 0.55, MIN_STILL = 3.6;
const [a, b, out] = process.argv.slice(2);
const lo = Number(a), hi = Number(b);

const DEV = "०१२३४५६७८९";
const devToNum = s => Number([...s].map(c => DEV.indexOf(c) >= 0 ? DEV.indexOf(c) : c).join(""));

const cues = JSON.parse(fs.readFileSync(P + "cue_index.json", "utf8"));
const cueDir = P + "table_read/cues/";
const cueFiles = fs.readdirSync(cueDir).filter(f => f.endsWith(".mp3")).sort();
const dur = f => Number(execFileSync("ffprobe", ["-v","error","-show_entries","format=duration",
  "-of","csv=p=0", f], { encoding: "utf8" }).trim());

// which shot each recorded line belongs to
const byShot = new Map();
cues.forEach((c, i) => {
  const n = devToNum(c.shot.replace("शॉट ", ""));
  if (!byShot.has(n)) byShot.set(n, []);
  byShot.get(n).push({ ...c, file: cueDir + cueFiles[i] });
});

// the shot list, in story order, from the module's own manifest
const manifest = execFileSync("node", ["src/KukuEp12_Shots.res.mjs", "list"],
  { cwd: "/Users/dusty/Dev/metaphrand/studio", encoding: "utf8" })
  .trim().split("\n").filter(l => / (motion|still) /.test(l))
  .map(l => { const p = l.trim().split(/\s+/); return { id: p[0], kind: p[1], secs: Number(p[2].replace("s","")) }; });

const segs = [], audio = [];
let t = 0, used = 0;
for (const sh of manifest) {
  const n = Number(sh.id.slice(1, 3));
  if (n < lo || n > hi) continue;
  const lines = byShot.get(n) || [];
  const spoken = lines.reduce((s, l) => s + dur(l.file) + GAP, 0);
  const clipPath = P + "clips/EP10_" + sh.id + ".mp4";
  const clipLen = fs.existsSync(clipPath) ? dur(clipPath) : 0;
  // THE VOICE SETS THE LENGTH, not the written duration. Those durations were
  // guessed before the takes existed and ran 3-6s long on every dialogue shot —
  // 46% of the act was dead air. A still now holds for its line plus a breath;
  // a silent action beat runs exactly as long as its clip.
  const voiced = HEAD + spoken + TAIL;
  const len = lines.length === 0
    ? (clipLen || sh.secs)
    : (clipLen ? Math.max(clipLen, voiced) : Math.max(voiced, MIN_STILL));

  const clip = clipPath;
  const stillF = P + "stills_final/" + sh.id + ".png";
  const stillP = fs.existsSync(stillF) ? stillF : P + "stills/" + sh.id + ".png";
  const seg = B + sh.id + "_seg.mp4";
  const common = ["-t", len.toFixed(3), "-r", String(FPS), "-map", "[v]", "-c:v", "libx264",
                  "-profile:v", "main", "-crf", "21", "-preset", "veryfast",
                  "-pix_fmt", "yuv420p", "-an", seg];
  if (fs.existsSync(clip)) {
    // play, then hold the last frame if the line outlasts the clip
    execFileSync("ffmpeg", ["-v","error","-y","-i", clip, "-filter_complex",
      `[0:v]scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2,fps=${FPS},tpad=stop_mode=clone:stop_duration=30[v]`,
      ...common], { timeout: 900000 });
  } else if (fs.existsSync(stillP)) {
    execFileSync("ffmpeg", ["-v","error","-y","-loop","1","-i", stillP, "-filter_complex",
      `[0:v]scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2,fps=${FPS}[v]`,
      ...common], { timeout: 900000 });
  } else { console.log("no picture for " + sh.id); continue; }

  segs.push(seg);
  let at = t + HEAD;
  for (const l of lines) { audio.push({ f: l.file, at }); at += dur(l.file) + GAP; }
  t += len; used++;
}

fs.writeFileSync(B + "cat.txt", segs.map(s => `file '${s}'`).join("\n") + "\n");
execFileSync("ffmpeg", ["-v","error","-y","-f","concat","-safe","0","-i", B + "cat.txt",
  "-c","copy", B + "picture.mp4"], { timeout: 1800000 });

const ins = [], filt = [];
audio.forEach((x, i) => { ins.push("-i", x.f); filt.push(`[${i}:a]adelay=${Math.round(x.at*1000)}|${Math.round(x.at*1000)}[a${i}]`); });
execFileSync("ffmpeg", ["-v","error","-y", ...ins, "-filter_complex",
  filt.join(";") + ";" + audio.map((_,i)=>`[a${i}]`).join("") + `amix=inputs=${audio.length}:normalize=0[o]`,
  "-map","[o]","-c:a","aac","-b:a","160k","-ar","44100","-ac","2", B + "dialogue.m4a"], { timeout: 1800000 });

execFileSync("ffmpeg", ["-v","error","-y","-i", B + "picture.mp4","-i", B + "dialogue.m4a",
  "-map","0:v","-map","1:a","-c:v","copy","-c:a","aac","-b:a","160k","-movflags","+faststart",
  P + out], { timeout: 1800000 });
console.log(`${out} — ${used} shots, ${audio.length} lines, ${t.toFixed(1)}s`);
