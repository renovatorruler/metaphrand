// «कर्क की तांती» — reverse-chronological cut, v2.
// Author's fixes (2026-08-16):
//  · strict reverse chronology inside the illness: treatment (beanie) shots first,
//    then the cap going on, then the hair loss, then the diagnosis — the beanie
//    can never appear EARLIER (i.e. later in reverse order) than the hair photo
//  · the लीलण verse (2:51–3:06) is HER montage: wife photos, reverse chrono
//  · after the vow at 4:20 the good-memories fall runs FAST (~1.5s a shot)
//  · picture covers the master's full 307.2s, fades out, no -shortest
//  · every shot is numbered; a parallel NUMBERED build burns S## into the corner
import { execFileSync } from "child_process";
import fs from "fs";
import { kb, FPS, W, H } from "./move.mjs";

const D = "/Users/dusty/Dev/metaphrand/stories/songbook/kark-mv/";
const G = D + "graded/", A = D + "atape/", B = D + "build_rev2/", NB = D + "build_rev2n/";
[B, NB].forEach(d => fs.mkdirSync(d, { recursive: true }));
const END = 307.2;

// Fixed points: singer clips at their lip-synced audio positions.
const SINGER = [
  ["wan3.mp4", 6.5, 10], ["wan_c1_wide_gold.mp4", 17, 10], ["wan_c5_wide_storm.mp4", 67, 10],
  ["wan_c3_close_storm.mp4", 134, 10], ["wan_c4_ivstand_storm.mp4", 161, 10], ["wan_c6_close_rain.mp4", 230, 10],
];

const P = (n, m = "push", o = {}) => ({ name: n, mode: m, opts: o });
const RUNS = [
  // [from, to, shots]
  [0, 6.5, [P("kf_2026", "pull", { amt: 0.12 })]],
  // 27-67 — the present, then the illness in strict reverse: mela -> treatment -> cap -> hair -> diagnosis
  [27, 67, [
    P("m4_family", "push", { amt: 0.10 }), P("m1_arrival", "push", { amt: 0.10 }),
    P("m2_wheel_faces", "push", { ax: 0.55, amt: 0.12 }),
    P("b6_57_ivtaanti", "push", { amt: 0.14 }), P("b6_55_3am", "drift", { dir: "r", amt: 0.07 }),
    P("b6_53_waiting", "push", { amt: 0.10 }), P("b6_54_thermos", "still"),
    P("b6_52_drip", "drift", { dir: "l", amt: 0.08 }),
    P("b6_51_cap", "still"), P("b6_50_hair", "push", { amt: 0.11 }),
    P("b6_49_corridorface", "push", { ax: 0.55, amt: 0.12 }), P("b6_48_doorcrack", "push", { amt: 0.13 }),
  ]],
  // 77-134 — grandchildren, then the weddings, then 2005
  [77, 134, [
    P("kf_2021", "push", { amt: 0.10 }), P("b5_46_selfie", "still"),
    P("b5_45_hands", "push", { amt: 0.15 }), P("b5_44_nap", "drift", { dir: "r", amt: 0.07 }),
    P("b5_41_newgrand", "push", { amt: 0.11 }), P("b5_43_kite", "pull", { amt: 0.13 }),
    P("kf_2018", "push", { amt: 0.09 }), P("b4_39_videocall", "push", { amt: 0.12 }),
    P("b4_38_empty", "drift", { dir: "l", amt: 0.07 }), P("b4_37_rooftop", "still"),
    P("b4_36_wedding", "push", { amt: 0.10 }), P("kf_2005", "pull", { amt: 0.11 }),
    P("b3_34_bangles2", "push", { amt: 0.12 }), P("b3_32_sofa", "push", { amt: 0.09 }),
  ]],
  // 144-161 — teenagers
  [144, 161, [
    P("b3_30_prizeday", "still"), P("b3_33_mechanic", "drift", { dir: "r", amt: 0.08 }),
    P("b3_29_measure", "push", { amt: 0.11 }), P("b3_28_scooter", "drift", { dir: "l", amt: 0.10 }),
    P("b3_26_busstop", "push", { amt: 0.09 }),
  ]],
  // 171-186 — THE लीलण VERSE: her, in reverse chronology
  [171, 186, [
    P("b5_42_feeding", "push", { ax: 0.45, amt: 0.11 }),   // her, grandchild era
    P("b3_31_rotis", "push", { amt: 0.11 }),               // her, teaching the daughter
    P("n2_competence", "drift", { dir: "r", amt: 0.09 }),  // her, carrying everything
    P("b2_22_school", "push", { ax: 0.45, amt: 0.10 }),    // her, fixing the child's hair
    P("o1_crowd_pull", "drift", { dir: "r", amt: 0.09 }),  // her, leading him — the first फेरा
  ]],
  // 186-230 — school years back to the cradle
  [186, 230, [
    P("b3_27_study", "still"), P("kf_1990", "push", { amt: 0.10 }),
    P("n4_thread_watch", "push", { ax: 0.58, amt: 0.13 }), P("n1_shoulders", "push", { ay: 0.40, amt: 0.10 }),
    P("n3_courtyard", "pull", { amt: 0.12 }), P("b2_20_birthday", "push", { ax: 0.45, amt: 0.13 }),
    P("b2_18_bath", "drift", { dir: "r", amt: 0.08 }), P("b2_17_firststeps", "push", { amt: 0.12 }),
    P("b2_23_charpai", "drift", { dir: "l", amt: 0.07 }), P("b2_16_newborn", "push", { amt: 0.11 }),
  ]],
  // 240-260 — the courtship
  [240, 260, [
    P("b1_11_studio", "still"), P("b1_12_mehndi", "push", { amt: 0.12 }),
    P("b1_08_jalebi", "push", { ax: 0.58, amt: 0.10 }), P("b1_07_cart", "drift", { dir: "r", amt: 0.07 }),
    P("b1_03_bangles", "push", { amt: 0.14 }),
  ]],
];

// 260-268: the vow breaks in (pinned by the lip-sync at 4:20)
const VOW = { name: "m3_vow_lipsync", mode: "push", opts: { amt: 0.09 }, at: 260, dur: 8 };

// 268 -> end: the FAST fall through the good memories (~1.5s each), landing on the first thread.
const FAST = ["kf_2021", "b5_46_selfie", "kf_2018", "b4_36_wedding", "kf_2005", "b3_28_scooter",
  "kf_1990", "n1_shoulders", "b2_17_firststeps", "b1_08_jalebi", "b1_05_well", "b1_02_window", "b1_01_lane"];
const TAIL = [];
let ft = 268;
FAST.forEach(n => { TAIL.push({ name: n, mode: "still", opts: {}, at: ft, dur: 1.5 }); ft += 1.5; });
TAIL.push({ name: "o4_wheel_ride", mode: "push", opts: { ay: 0.42, amt: 0.08 }, at: ft, dur: 2 }); ft += 2;
TAIL.push({ name: "o3_after", mode: "push", opts: { ax: 0.55, amt: 0.09 }, at: ft, dur: 2.5 }); ft += 2.5;
TAIL.push({ name: "o2_first_thread", mode: "push", opts: { amt: 0.12 }, at: ft, dur: 4 }); ft += 4;
TAIL.push({ name: "kf_1976", mode: "pull", opts: { amt: 0.16 }, at: ft, dur: END - ft });

// ---- timeline assembly ----
const timeline = [];
RUNS.forEach(([from, to, shots]) => {
  const each = (to - from) / shots.length;
  shots.forEach((s, i) => timeline.push({ kind: "photo", ...s, at: from + i * each, dur: each }));
});
SINGER.forEach(([f, at, dur]) => timeline.push({ kind: "clip", file: A + f, at, dur }));
timeline.push({ kind: "photo", ...VOW });
TAIL.forEach(t => timeline.push({ kind: "photo", ...t }));
timeline.sort((a, b) => a.at - b.at);

// shot list + number cards
const list = timeline.map((t, i) => ({ id: "S" + String(i + 1).padStart(2, "0"), ...t }));
fs.writeFileSync(D + "SHOTLIST_REVERSE_V2.md",
  "# Reverse cut v2 — shot list\n\n| # | at | dur | source |\n|---|----|-----|--------|\n" +
  list.map(s => `| ${s.id} | ${Math.floor(s.at / 60)}:${String(Math.floor(s.at % 60)).padStart(2, "0")} | ${s.dur.toFixed(1)}s | ${s.kind === "clip" ? "SINGER " + s.file.split("/").pop() : s.name} |`).join("\n") + "\n");

const NUMDIR = "/tmp/shotnums/"; fs.mkdirSync(NUMDIR, { recursive: true });
list.forEach(s => {
  const p = NUMDIR + s.id + ".png";
  if (fs.existsSync(p)) return;
  fs.writeFileSync("/tmp/n.typ", `#set page(width: 170pt, height: 64pt, margin: 0pt, fill: none)
#place(center + horizon, box(fill: rgb(0,0,0,200), inset: 10pt, radius: 5pt, text(fill: white, size: 30pt, weight: "bold", font: "Helvetica", "${s.id}")))`);
  execFileSync("typst", ["compile", "/tmp/n.typ", p, "--format", "png"], { timeout: 60000 });
});

// ---- render ----
let clean = [], numbered = [], missing = 0;
list.forEach((t, i) => {
  const co = `${B}${t.id}.mp4`, no = `${NB}${t.id}.mp4`;
  const last = i === list.length - 1;
  const fade = last ? `,fade=t=out:st=${Math.max(0, t.dur - 3).toFixed(2)}:d=3` : "";
  if (!fs.existsSync(co)) {
    if (t.kind === "clip") {
      if (!fs.existsSync(t.file)) { console.log("MISSING " + t.file); missing++; return; }
      execFileSync("ffmpeg", ["-v", "error", "-y", "-t", String(t.dur), "-i", t.file,
        "-vf", `scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2,fps=${FPS},format=yuv420p${fade}`,
        "-c:v", "libx264", "-crf", "20", "-preset", "veryfast", "-an", co], { timeout: 600000 });
    } else {
      const src = G + t.name + ".png";
      if (!fs.existsSync(src)) { console.log("MISSING " + src); missing++; return; }
      const m = kb(t.mode, t.dur, t.opts);
      execFileSync("ffmpeg", ["-v", "error", "-y", "-loop", "1", "-i", src,
        "-vf", m.vf + fade, "-frames:v", String(m.n), "-r", String(FPS),
        "-c:v", "libx264", "-crf", "20", "-preset", "veryfast", "-an", co], { timeout: 600000 });
    }
  }
  if (!fs.existsSync(no)) {
    execFileSync("ffmpeg", ["-v", "error", "-y", "-i", co, "-i", NUMDIR + t.id + ".png",
      "-filter_complex", "[0][1]overlay=28:H-h-28", "-c:v", "libx264", "-crf", "21", "-preset", "veryfast", "-an", no], { timeout: 600000 });
  }
  clean.push(co); numbered.push(no);
});
if (missing) { console.log(missing + " missing — aborting"); process.exit(1); }
console.log(list.length + " shots, " + list.reduce((s, t) => s + t.dur, 0).toFixed(1) + "s of picture");

const mux = (segs, cat, out) => {
  fs.writeFileSync(cat, segs.map(s => `file '${s}'`).join("\n") + "\n");
  execFileSync("ffmpeg", ["-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", cat, "-c", "copy", cat + ".mp4"], { timeout: 900000 });
  execFileSync("ffmpeg", ["-v", "error", "-y", "-i", cat + ".mp4", "-i", D + "kark_ki_taanti_master.mp3",
    "-map", "0:v", "-map", "1:a", "-c:v", "copy", "-c:a", "aac", "-profile:a", "aac_low", "-b:a", "192k",
    "-ar", "44100", "-ac", "2", "-movflags", "+faststart", out], { timeout: 900000 });
};
mux(clean, B + "cat.txt", D + "KARK_MV_REVERSE_V2.mp4");
mux(numbered, NB + "cat.txt", D + "KARK_MV_REVERSE_V2_NUMBERED.mp4");
console.log("done: KARK_MV_REVERSE_V2(.mp4 / _NUMBERED.mp4)");
