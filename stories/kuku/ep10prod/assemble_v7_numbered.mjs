// EP10 V7 — NUMBERED review animatic. Same cut as EP10_V7_REVIEW_ANIMATIC, with
// a shot chip burned into every shot (S001…S155) plus the speaker's name, so the
// author can name any moment precisely. Emits a shot list alongside.
import { execFileSync } from "child_process";
import fs from "fs";

const K = "/Users/dusty/Dev/metaphrand/stories/kuku/";
const P = K + "ep10prod/";
const CUES = P + "v7_table_read/cues/";
const S = P + "stills/", I = P + "inbetweens/";
const B = P + "v7_table_read/build_num/"; fs.mkdirSync(B, { recursive: true });
const NUM = "/tmp/ep10nums/"; fs.mkdirSync(NUM, { recursive: true });
const W = 1920, H = 1080, FPS = 30, GAP = 0.45;

const CUEIDX = JSON.parse(fs.readFileSync(P + "v7_table_read/cue_index.json", "utf8"));
const cueFiles = fs.readdirSync(CUES).filter(f => f.endsWith(".mp3")).sort();
const dur = f => +execFileSync("ffprobe", ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", CUES + f], { encoding: "utf8" }).trim();

const BAD = new Set(["h01_ring_wide__a_rishi_enters.png","h01_ring_wide__b_furia_steps_out.png"]);

// per-cue overrides from the author's review notes: a cue-specific still (img)
// or a generated clip (video) wins over every pool rule below
const CUE_MEDIA = {
  S011: { img: S + "s011_castor_calm_solo.png" },
  S014: { video: P + "clips/S014_furia_ring_flight.mp4" },
};
const pool = (names) => names.flatMap(n => {
  const hero = S + n + ".png";
  const derived = fs.existsSync(I) ? fs.readdirSync(I).filter(f => f.startsWith(n + "__") && !BAD.has(f)).sort().map(f => I + f) : [];
  return fs.existsSync(hero) ? [hero, ...derived] : derived;
});
const SCENES = [
  { name: "0 उड़ान-आँगन", upto: 22, frames: pool(["h01_ring_wide", "h51_gauri_grazing", "h52_gauri_hay_cart", "h45_leda_watch_ring", "h02_rishi_teach", "h03_furia_mark", "h04_launch", "h05_bell_touch", "h06_landing_paw", "h07_cart_tethered", "h08_gauri_close", "h09_rishi_boon"]) },
  { name: "0अ मीनार", upto: 30, frames: pool(["h10_cheel_tower", "h11_shards_close", "h12_rope_slip", "h13_bell_taken", "h14_furia_choice"]) },
  { name: "1 भागती गाड़ी", upto: 48, frames: pool(["h15_cart_runs", "h46_leda_calls_lane", "h16_five_flank", "h17_group_lift", "h18_cow_slips", "h19_wheels_return"]) },
  { name: "2 निशान", upto: 70, frames: pool(["h20_furia_brake", "h47_leda_warns", "h21_vesper_above", "h22_castor_calm", "h23_marker_pass", "h24_kuku_breath_fail"]) },
  { name: "3 ग बनना", upto: 100, frames: pool(["h25_leda_knock", "h48_leda_counts", "h26_tings", "h27_kuku_hears", "h28_forging", "h29_ga_stands", "h30_bracelets"]) },
  { name: "4 आख़िरी मोड़", upto: 118, frames: pool(["h31_vesper_yawn", "h32_cart_drifts", "h33_cheel_flyover", "h34_furia_refuses"]) },
  { name: "5 रुकना", upto: 136, frames: pool(["h35_last_marker", "h49_leda_relief", "h36_three_beats", "h37_cart_into_curve", "h38_stopped"]) },
  { name: "6 बाद में", upto: 150, frames: pool(["h39_shrink_glow", "h50_leda_small_sits", "h40_small_five_sit", "h41_castor_in_hay"]) },
  { name: "7/8 दादी और मीनार", upto: 999, frames: pool(["h42_doorway_dadi", "h43_vesper_asleep", "h44_tower_door"]) },
];
const sceneOf = i => SCENES.find(s => i < s.upto) || SCENES[SCENES.length - 1];

// which hero setups feature each speaker as the SUBJECT of the frame
const SUBJECT = {
  'कुकु': ['h24_kuku_breath_fail','h27_kuku_hears','h28_forging'],
  'फ्यूरिया': ['h03_furia_mark','h04_launch','h06_landing_paw','h14_furia_choice','h20_furia_brake','h34_furia_refuses','h36_three_beats'],
  'लेडा': ['h25_leda_knock','h45_leda_watch_ring','h46_leda_calls_lane','h47_leda_warns','h48_leda_counts','h49_leda_relief','h50_leda_small_sits'],
  'कैस्टर': ['h22_castor_calm','h41_castor_in_hay'],
  'वैस्पर': ['h21_vesper_above','h31_vesper_yawn','h43_vesper_asleep'],
  'ऋषि': ['h02_rishi_teach','h09_rishi_boon'],
  'चील': ['h10_cheel_tower','h13_bell_taken','h33_cheel_flyover','h44_tower_door'],
  'दादी': ['h42_doorway_dadi'],
};
const speakerFrames = (who) => pool(SUBJECT[who] || []);

// A line about a subject should SHOW that subject, not the speaker's face.
const SUBJECT_OF_TEXT = [
  { re: /गौरी|गाय/, frames: ['h51_gauri_grazing','h52_gauri_hay_cart','h08_gauri_close','h07_cart_tethered','h18_cow_slips'] },
  { re: /घंटी/,      frames: ['h05_bell_touch','h13_bell_taken','h33_cheel_flyover','h44_tower_door'] },
  { re: /रस्सी/,     frames: ['h12_rope_slip','h07_cart_tethered'] },
  { re: /निशान|पटरी|सपाट/, frames: ['h23_marker_pass','h35_last_marker','h32_cart_drifts'] },
  { re: /गाड़ी/,     frames: ['h15_cart_runs','h37_cart_into_curve','h38_stopped','h19_wheels_return'] },
];
const subjectFrames = (text) => {
  const hit = SUBJECT_OF_TEXT.find(s => s.re.test(text || ''));
  return hit ? pool(hit.frames) : [];
};
const inScene = (frames, sc) => frames.filter(f => sc.frames.includes(f));

const rows = [];
const segs = [], alist = [];
let t = 0, shown = new Map();

cueFiles.forEach((f, i) => {
  const id = "S" + String(i + 1).padStart(3, "0");
  const who = f.replace(/^\d+_/, "").replace(/\.mp3$/, "");
  const d = dur(f);
  const sc = sceneOf(i);
  const text = (CUEIDX[i] && CUEIDX[i].text) || '';
  const subj = inScene(subjectFrames(text), sc);
  const mine = speakerFrames(who);
  const here = inScene(mine, sc);
  // a named subject in the line wins on its first mention in a scene
  const kSub = 'subj|' + sc.name + '|' + (subj[0] || '');
  const firstMention = subj.length && !shown.has(kSub);
  if (firstMention) shown.set(kSub, 1);
  const candidates = firstMention ? subj : (here.length ? here : (mine.length ? mine : (subj.length ? subj : sc.frames)));
  const k = firstMention ? kSub + '|use' : who + '|' + (here.length ? 'scene' : mine.length ? 'any' : 'fallback');
  const used = shown.get(k) || 0;
  let img = candidates.length ? candidates[used % candidates.length] : S + "h01_ring_wide.png";
  shown.set(k, used + 1);
  const ov = CUE_MEDIA[id];
  if (ov && ov.img) img = ov.img;
  // a clip cue holds the screen for the full clip, not just the line
  const clipDur = ov && ov.video
    ? +execFileSync("ffprobe", ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", ov.video], { encoding: "utf8" }).trim()
    : 0;
  const segDur = Math.max(d + GAP, clipDur);

  // number chip: S### + speaker
  const chip = NUM + id + ".png";
  if (!fs.existsSync(chip)) {
    fs.writeFileSync("/tmp/n10.typ", `#set page(width: 460pt, height: 84pt, margin: 0pt, fill: none)
#set text(font: ("Helvetica", "Devanagari Sangam MN"))
#place(left + horizon, box(fill: rgb(0,0,0,205), inset: 12pt, radius: 6pt)[
  #text(fill: white, size: 34pt, weight: "bold", "${id}")
  #h(10pt)
  #text(fill: rgb(255,214,120), size: 26pt, "${who}")
])`);
    execFileSync("typst", ["compile", "/tmp/n10.typ", chip, "--format", "png"], { timeout: 60000 });
  }

  const out = B + "v" + String(i).padStart(3, "0") + ".mp4";
  if (!fs.existsSync(out)) {
    if (ov && ov.video) {
      // clip cue: play the clip, freeze its last frame if the cue outlasts it
      execFileSync("ffmpeg", ["-v", "error", "-y", "-i", ov.video, "-i", chip, "-t", segDur.toFixed(3),
        "-filter_complex", `[0:v]scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2,fps=${FPS},tpad=stop_mode=clone:stop_duration=30[bg];[bg][1:v]overlay=36:H-h-36,format=yuv420p[v]`,
        "-map", "[v]", "-c:v", "libx264", "-crf", "20", "-preset", "veryfast", "-an", out], { timeout: 300000 });
    } else {
      execFileSync("ffmpeg", ["-v", "error", "-y", "-loop", "1", "-i", img, "-i", chip, "-t", segDur.toFixed(3),
        "-filter_complex", `[0:v]scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2,fps=${FPS}[bg];[bg][1:v]overlay=36:H-h-36,format=yuv420p[v]`,
        "-map", "[v]", "-c:v", "libx264", "-crf", "20", "-preset", "veryfast", "-an", out], { timeout: 300000 });
    }
  }
  segs.push(out); alist.push({ f, at: t, d });
  rows.push(`| ${id} | ${(t).toFixed(1)}s | ${who} | ${sc.name} | ${(ov && ov.video ? ov.video : img).split("/").pop()} |`);
  t += segDur;
});

fs.writeFileSync(B + "cat.txt", segs.map(s => `file '${s}'`).join("\n") + "\n");
execFileSync("ffmpeg", ["-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", B + "cat.txt", "-c", "copy", B + "picture.mp4"], { timeout: 900000 });

// own dialogue mix from THIS timeline (clip cues can stretch segments, so the
// shared build/dialogue.m4a timings no longer apply)
const inputs = [], filters = [];
alist.forEach((a, i) => { inputs.push("-i", CUES + a.f); filters.push(`[${i}:a]adelay=${Math.round(a.at * 1000)}|${Math.round(a.at * 1000)}[a${i}]`); });
const fc = filters.join(";") + ";" + alist.map((_, i) => `[a${i}]`).join("") + `amix=inputs=${alist.length}:normalize=0[aout]`;
execFileSync("ffmpeg", ["-v", "error", "-y", ...inputs, "-filter_complex", fc, "-map", "[aout]",
  "-c:a", "aac", "-b:a", "192k", "-ar", "44100", "-ac", "2", B + "dialogue.m4a"], { timeout: 900000 });

execFileSync("ffmpeg", ["-v", "error", "-y", "-i", B + "picture.mp4", "-i", B + "dialogue.m4a",
  "-map", "0:v", "-map", "1:a", "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
  "-movflags", "+faststart", "-shortest", P + "EP10_V7_REVIEW_NUMBERED.mp4"], { timeout: 900000 });

fs.writeFileSync(P + "EP10_V7_SHOTLIST.md",
  "# EP10 V7 — review animatic shot list\n\n| # | at | speaker | scene | frame |\n|---|----|---------|-------|-------|\n" + rows.join("\n") + "\n");
console.log("EP10_V7_REVIEW_NUMBERED.mp4 + EP10_V7_SHOTLIST.md — " + cueFiles.length + " numbered shots");
