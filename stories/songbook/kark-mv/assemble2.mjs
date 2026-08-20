// «कर्क की तांती» assembler v2.
//  · the singer is now VIDEO (lip-synced to the master), dropped at his audio positions
//  · photographs come from graded/ (era grade + frame applied in post)
//  · motion comes from move.mjs: eased, off-centre anchored, varied, some held still
//  · sky order runs one way: gold -> storm -> rain
import { execFileSync } from "child_process";
import fs from "fs";
import { kb, FPS, W, H } from "./move.mjs";

const D = "/Users/dusty/Dev/metaphrand/stories/songbook/kark-mv/";
const G = D + "graded/", A = D + "atape/", B = D + "build2/";
fs.mkdirSync(B, { recursive: true });

// Singer clips: [file, audio position in the master, length]
const SINGER = [
  [A + "wan3.mp4", 6.5, 10],                 // the alap
  [A + "wan_c1_wide_gold.mp4", 17, 10],      // gold
  [A + "wan_c5_wide_storm.mp4", 67, 10],     // storm arrives
  [A + "wan_c3_close_storm.mp4", 134, 10],   // storm
  [A + "wan_c4_ivstand_storm.mp4", 161, 10], // storm
  [A + "wan_c6_close_rain.mp4", 230, 10],    // rain
];

// Photograph runs that fill the gaps between singer appearances.
// Each entry: [name, move, opts?] — move: push | pull | drift | still
const P = (n, m = "push", o = {}) => [n, m, o];
const RUNS = {
  open: [ // 0 -> 6.5   he is present but not singing yet: no voice in the master here
    P("kf_1976", "pull", { amt: 0.12 }),
  ],
  r1: [ // 27 -> 67   BEAT 1, the courtship
    P("b1_01_lane", "push", { ax: 0.62, amt: 0.09 }), P("b1_02_window", "push", { ax: 0.58, ay: 0.42, amt: 0.13 }),
    P("b1_05_well", "drift", { dir: "l", amt: 0.08 }), P("b1_04_friends", "still"),
    P("b1_03_bangles", "push", { amt: 0.14 }), P("b1_08_jalebi", "push", { ax: 0.58, amt: 0.10 }),
    P("b1_07_cart", "drift", { dir: "r", amt: 0.07 }), P("b1_09_field", "pull", { amt: 0.16 }),
    P("b1_12_mehndi", "push", { amt: 0.12 }), P("b1_11_studio", "still"),
    P("o1_crowd_pull", "drift", { dir: "r", amt: 0.09 }), P("o4_wheel_ride", "push", { ay: 0.42, amt: 0.10 }),
    P("o3_after", "push", { ax: 0.55, amt: 0.11 }), P("o2_first_thread", "push", { amt: 0.15 }),
  ],
  r2: [ // 77 -> 134   BEAT 2 into BEAT 3
    P("kf_1976", "still"),
    P("b2_16_newborn", "push", { amt: 0.11 }), P("b2_23_charpai", "drift", { dir: "l", amt: 0.07 }),
    P("b2_17_firststeps", "push", { amt: 0.12 }), P("b2_18_bath", "drift", { dir: "r", amt: 0.08 }),
    P("b2_20_birthday", "push", { ax: 0.45, amt: 0.13 }), P("b2_22_school", "still"),
    P("n1_shoulders", "push", { ay: 0.40, amt: 0.10 }), P("n3_courtyard", "pull", { amt: 0.12 }),
    P("n2_competence", "drift", { dir: "r", amt: 0.09 }), P("kf_1990", "push", { amt: 0.10 }),
    P("b3_26_busstop", "push", { amt: 0.09 }), P("b3_27_study", "still"),
    P("b3_28_scooter", "drift", { dir: "l", amt: 0.10 }), P("b3_29_measure", "push", { amt: 0.11 }),
  ],
  r3: [ // 144 -> 161
    P("b3_31_rotis", "push", { amt: 0.11 }), P("b3_33_mechanic", "drift", { dir: "r", amt: 0.08 }),
    P("b3_30_prizeday", "still"), P("b3_32_sofa", "push", { amt: 0.09 }),
    P("n4_thread_watch", "push", { ax: 0.58, amt: 0.13 }),
  ],
  r4: [ // 171 -> 230   BEAT 3 close, BEAT 4, BEAT 5, then the disease
    P("b3_34_bangles2", "push", { amt: 0.12 }), P("kf_2005", "pull", { amt: 0.11 }),
    P("b4_36_wedding", "push", { amt: 0.10 }), P("b4_37_rooftop", "still"),
    P("b4_38_empty", "drift", { dir: "l", amt: 0.07 }), P("b4_39_videocall", "push", { amt: 0.12 }),
    P("kf_2018", "push", { amt: 0.09 }), P("b5_43_kite", "pull", { amt: 0.13 }),
    P("b5_41_newgrand", "push", { amt: 0.11 }), P("b5_44_nap", "drift", { dir: "r", amt: 0.07 }),
    P("b5_45_hands", "push", { amt: 0.15 }), P("b5_46_selfie", "still"),
    P("kf_2021", "push", { amt: 0.10 }), P("b6_48_doorcrack", "push", { amt: 0.13 }),
    P("b6_49_corridorface", "push", { ax: 0.55, amt: 0.12 }), P("b6_50_hair", "push", { amt: 0.11 }),
    P("b6_51_cap", "still"), P("b6_52_drip", "drift", { dir: "l", amt: 0.08 }),
  ],
  r5: [ // 240 -> 303   the present, the vow, the return, the ending
    P("b6_53_waiting", "push", { amt: 0.10 }), P("b6_54_thermos", "still"),
    P("b6_55_3am", "drift", { dir: "r", amt: 0.07 }), P("b6_57_ivtaanti", "push", { amt: 0.14 }),
    P("m1_arrival", "push", { amt: 0.10 }), P("m2_wheel_faces", "push", { ax: 0.55, amt: 0.12 }),
    P("m3_vow_lipsync", "push", { amt: 0.09 }),          // 4:20, the vow
    P("kf_1976", "still"), P("kf_1990", "still"), P("kf_2005", "still"),
    P("kf_2018", "still"), P("kf_2021", "still"), P("kf_2026", "still"),  // the cascade
    P("m4_family", "push", { amt: 0.10 }),
    P("x_tree_tying", "push", { amt: 0.12 }),
    P("x_tree_fifty", "pull", { amt: 0.16 }),            // the final image
  ],
};

// Build the timeline: singer clips are fixed points; photo runs fill between them.
const GAPS = [
  ["open", 0, 6.5], ["r1", 27, 67], ["r2", 77, 134],
  ["r3", 144, 161], ["r4", 171, 230], ["r5", 240, 303.2],
];

const timeline = [];
GAPS.forEach(([key, from, to], gi) => {
  const run = RUNS[key];
  const each = (to - from) / run.length;
  run.forEach(([name, mode, opts], i) => timeline.push({ kind: "photo", name, mode, opts, at: from + i * each, dur: each }));
  const s = SINGER[gi];
  if (s) timeline.push({ kind: "clip", file: s[0], at: s[1], dur: s[2] });
});
timeline.sort((a, b) => a.at - b.at);

let segs = [], missing = 0;
timeline.forEach((t, i) => {
  const out = `${B}s${String(i).padStart(3, "0")}.mp4`;
  if (fs.existsSync(out)) { segs.push(out); return; }
  if (t.kind === "clip") {
    if (!fs.existsSync(t.file)) { console.log("MISSING " + t.file); missing++; return; }
    execFileSync("ffmpeg", ["-v", "error", "-y", "-t", String(t.dur), "-i", t.file,
      "-vf", `scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2,fps=${FPS},format=yuv420p`,
      "-c:v", "libx264", "-crf", "20", "-preset", "veryfast", "-an", out], { timeout: 600000 });
  } else {
    const src = G + t.name + ".png";
    if (!fs.existsSync(src)) { console.log("MISSING " + src); missing++; return; }
    const m = kb(t.mode, t.dur, t.opts);
    execFileSync("ffmpeg", ["-v", "error", "-y", "-loop", "1", "-i", src,
      "-vf", m.vf, "-frames:v", String(m.n), "-r", String(FPS),
      "-c:v", "libx264", "-crf", "20", "-preset", "veryfast", "-an", out], { timeout: 600000 });
  }
  segs.push(out);
});
if (missing) { console.log(missing + " sources missing — aborting"); process.exit(1); }

const total = timeline.reduce((s, t) => s + t.dur, 0);
console.log(`${segs.length} segments, ${total.toFixed(1)}s of picture (master 307.2s)`);

fs.writeFileSync(B + "cat.txt", segs.map(s => `file '${s}'`).join("\n") + "\n");
execFileSync("ffmpeg", ["-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", B + "cat.txt", "-c", "copy", B + "picture.mp4"], { timeout: 900000 });
execFileSync("ffmpeg", ["-v", "error", "-y", "-i", B + "picture.mp4", "-i", D + "kark_ki_taanti_master.mp3",
  "-map", "0:v", "-map", "1:a", "-c:v", "copy", "-c:a", "aac", "-profile:a", "aac_low", "-b:a", "192k",
  "-ar", "44100", "-ac", "2", "-shortest", "-movflags", "+faststart", D + "KARK_MV_V2.mp4"], { timeout: 900000 });
console.log("KARK_MV_V2.mp4 — " + execFileSync("ffprobe", ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", D + "KARK_MV_V2.mp4"], { encoding: "utf8" }).trim() + "s");
