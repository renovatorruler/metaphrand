// EP10 V7 — REVIEW ANIMATIC: picture (heroes + in-betweens) cut against the
// generated dialogue, scene by scene. No SFX bed, no title song yet — this is
// for judging performance, pacing and whether the story reads.
import { execFileSync } from "child_process";
import fs from "fs";

const K = "/Users/dusty/Dev/metaphrand/stories/kuku/";
const P = K + "ep10prod/";
const CUES = P + "v7_table_read/cues/";
const S = P + "stills/", I = P + "inbetweens/";
const B = P + "v7_table_read/build/"; fs.mkdirSync(B, { recursive: true });
const W = 1920, H = 1080, FPS = 30, GAP = 0.45;

const cueFiles = fs.readdirSync(CUES).filter(f => f.endsWith(".mp3")).sort();
const dur = f => +execFileSync("ffprobe", ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", CUES + f], { encoding: "utf8" }).trim();

// picture pool per scene, in story order: heroes interleaved with their derivations
const pool = (names) => names.flatMap(n => {
  const hero = S + n + ".png";
  const derived = fs.existsSync(I) ? fs.readdirSync(I).filter(f => f.startsWith(n + "__")).sort().map(f => I + f) : [];
  return fs.existsSync(hero) ? [hero, ...derived] : derived;
});

// cue index → scene (from the screenplay's order)
const SCENES = [
  { upto: 22, frames: pool(["h01_ring_wide", "h02_rishi_teach", "h03_furia_mark", "h04_launch", "h05_bell_touch", "h06_landing_paw", "h07_cart_tethered", "h08_gauri_close", "h09_rishi_boon"]) },
  { upto: 30, frames: pool(["h10_cheel_tower", "h11_shards_close", "h12_rope_slip", "h13_bell_taken", "h14_furia_choice"]) },
  { upto: 48, frames: pool(["h15_cart_runs", "h16_five_flank", "h17_group_lift", "h18_cow_slips", "h19_wheels_return"]) },
  { upto: 70, frames: pool(["h20_furia_brake", "h21_vesper_above", "h22_castor_calm", "h23_marker_pass", "h24_kuku_breath_fail"]) },
  { upto: 100, frames: pool(["h25_leda_knock", "h26_tings", "h27_kuku_hears", "h28_forging", "h29_ga_stands", "h30_bracelets"]) },
  { upto: 118, frames: pool(["h31_vesper_yawn", "h32_cart_drifts", "h33_cheel_flyover", "h34_furia_refuses"]) },
  { upto: 136, frames: pool(["h35_last_marker", "h36_three_beats", "h37_cart_into_curve", "h38_stopped"]) },
  { upto: 150, frames: pool(["h39_shrink_glow", "h40_small_five_sit", "h41_castor_in_hay"]) },
  { upto: 999, frames: pool(["h42_doorway_dadi", "h43_vesper_asleep", "h44_tower_door"]) },
];
const sceneOf = i => SCENES.find(s => i < s.upto) || SCENES[SCENES.length - 1];

// audio: cues in order separated by GAP
const alist = [], segs = [];
let t = 0, shown = new Map();
cueFiles.forEach((f, i) => {
  const d = dur(f);
  const sc = sceneOf(i);
  const used = shown.get(sc) || 0;
  const img = sc.frames.length ? sc.frames[used % sc.frames.length] : S + "h01_ring_wide.png";
  shown.set(sc, used + 1);
  const segDur = d + GAP;
  const out = B + "v" + String(i).padStart(3, "0") + ".mp4";
  if (!fs.existsSync(out)) {
    execFileSync("ffmpeg", ["-v", "error", "-y", "-loop", "1", "-i", img, "-t", segDur.toFixed(3),
      "-vf", `scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2,fps=${FPS},format=yuv420p`,
      "-c:v", "libx264", "-crf", "20", "-preset", "veryfast", "-an", out], { timeout: 300000 });
  }
  segs.push(out);
  alist.push({ f, at: t, d });
  t += segDur;
});

// concat picture
fs.writeFileSync(B + "cat.txt", segs.map(s => `file '${s}'`).join("\n") + "\n");
execFileSync("ffmpeg", ["-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", B + "cat.txt", "-c", "copy", B + "picture.mp4"], { timeout: 900000 });

// build the dialogue track: each cue delayed to its slot
const inputs = [], filters = [];
alist.forEach((a, i) => { inputs.push("-i", CUES + a.f); filters.push(`[${i}:a]adelay=${Math.round(a.at * 1000)}|${Math.round(a.at * 1000)}[a${i}]`); });
const mixIn = alist.map((_, i) => `[a${i}]`).join("");
const fc = filters.join(";") + ";" + mixIn + `amix=inputs=${alist.length}:normalize=0[aout]`;
execFileSync("ffmpeg", ["-v", "error", "-y", ...inputs, "-filter_complex", fc, "-map", "[aout]",
  "-c:a", "aac", "-b:a", "192k", "-ar", "44100", "-ac", "2", B + "dialogue.m4a"], { timeout: 900000 });

execFileSync("ffmpeg", ["-v", "error", "-y", "-i", B + "picture.mp4", "-i", B + "dialogue.m4a",
  "-map", "0:v", "-map", "1:a", "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
  "-movflags", "+faststart", "-shortest", P + "EP10_V7_REVIEW_ANIMATIC.mp4"], { timeout: 900000 });

console.log("EP10_V7_REVIEW_ANIMATIC.mp4 — " +
  execFileSync("ffprobe", ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", P + "EP10_V7_REVIEW_ANIMATIC.mp4"], { encoding: "utf8" }).trim() + "s, " +
  cueFiles.length + " cues");
