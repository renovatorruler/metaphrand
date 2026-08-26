// «कर्क की तांती» — CHRONOLOGICAL cut v3 (the working cut).
//  · opens with the disease HINTED impersonally: the needle in a hand, the wrist
//    with band+thread — no faces — so the illness never arrives abruptly
//  · years run forward; illness in strict order (diagnosis -> corridor -> hair -> cap -> treatment)
//  · the लीलण verse (2:51) is HER montage, chronological
//  · after the vow at 4:20: the FAST fall through good memories (1.5s/shot), then the tree
//  · master plays full length, fades; every shot numbered; ENGLISH SUBTITLES BAKED IN
import { execFileSync } from "child_process";
import fs from "fs";
import { kb, FPS, W, H } from "./move.mjs";

const D = "/Users/dusty/Dev/metaphrand/stories/songbook/kark-mv/";
const G = D + "stock/", A = D + "atape/", B = D + "build_ch/", NB = D + "build_chn/";
[B, NB].forEach(d => fs.mkdirSync(d, { recursive: true }));
const END = 307.2;
// encode quality — env-overridable so an upload master can be rendered without
// touching the cut: CRF=15 PRESET=slow node assemble_chrono.mjs
const CRF = process.env.CRF || "20", PRESET = process.env.PRESET || "veryfast";

// The approved OPENING (0-30.05) lives inline so every internal cut gets its own
// shot number: disease+deity photo pops around OmniHuman singer segments,
// मूर्ति on the first थाप. Entries: [file, at, dur, sourceStart?]
const SINGER = [
  ["omni_daf_test.mp4", 6.4, 10.61, 2.4],   // the आलाप unbroken on his face
  ["omni_daf_chunk2.mp4", 21.2, 8.85, 4.7], // drumming + verse after the मूर्ति
  ["omni_stormwide.mp4", 63.5, 15],   // «यो सांप कोनी तेजा यो कर्क है» 63.7-78.3
  ["omni_stormclose.mp4", 133, 15],   // doctors' marks verse 133.4-146.5
  ["omni_rainclose.mp4", 228, 15],    // «पण तू भी तो कोनी बच्यो» 229.0-243
];

// ---- colour grade (LUTs emitted by studio/src/Kark_Lut.res) ----------------
// Era conform first, then the master print look. The singer clips take the look
// only — an era conform would strip the warmth out of his gold/storm skies.
const L = D + "luts/";
const LOOK = L + "look_print.cube";
const ERA = (n) =>
  /^(b1_|o[1-4]|kf_1976)/.test(n) ? L + "tmax1976.cube"
  : /^(b2_|n[1-4]|kf_1990|w_young_carry)/.test(n) ? L + "print1990.cube"
  : /^(b3_|kf_2005)/.test(n) ? L + "portra400.cube"
  : /^(b4_|b5_|kf_2018|kf_2021|w_umbrella)/.test(n) ? L + "portra800.cube"
  : L + "present.cube";
const lut = (f) => `lut3d=file='${f}':interp=tetrahedral`;

const P = (n, m = "push", o = {}) => ({ name: n, mode: m, opts: o });
const RUNS = [
  // THE OPENING — disease and deity only, no couple faces before the verse
  [0, 3.2, [P("s05_ward_drip", "push", { amt: 0.10 })]],
  [3.2, 6.4, [P("s02_diya_wrist", "push", { amt: 0.12 })]],
  [17.01, 21.2, [P("x_murti_close", "push", { amt: 0.10 })]],  // the god on the first थाप
  // 30.05-63.5 — BEAT 1, the courtship
  [30.05, 63.5, [
    P("b1_01_lane", "diag", { dir: "dr", amt: 0.10 }), P("b1_02_window", "push", { ax: 0.58, ay: 0.42, amt: 0.13 }),
    P("b1_05_well", "drift", { dir: "l", amt: 0.08 }), P("b1_04_friends", "still"),
    P("b1_03_bangles", "push", { amt: 0.14 }), P("b1_08_jalebi", "push", { ax: 0.58, amt: 0.10 }),
    P("b1_07_cart", "drift", { dir: "r", amt: 0.07 }), P("b1_09_field", "diag", { dir: "ur", amt: 0.11 }),
    P("b1_12_mehndi", "push", { amt: 0.12 }), P("b1_11_studio", "still"),
    P("o1_crowd_pull", "drift", { dir: "r", amt: 0.09 }), P("o4_wheel_ride", "tilt", { dir: "u", amt: 0.11 }),
    P("o3_after", "drift", { dir: "l", amt: 0.08 }), P("o2_first_thread", "push", { amt: 0.15 }),
  ]],
  // 77-134 — the young family into the school years
  [78.5, 133, [
    P("kf_1976", "still"), P("b2_16_newborn", "push", { amt: 0.11 }),
    P("b2_23_charpai", "drift", { dir: "l", amt: 0.07 }), P("b2_17_firststeps", "diag", { dir: "ur", amt: 0.10 }),
    P("b2_18_bath", "drift", { dir: "r", amt: 0.08 }), P("b2_20_birthday", "push", { ax: 0.45, amt: 0.13 }),
    P("n1_shoulders", "tilt", { dir: "u", amt: 0.10 }), P("n3_courtyard", "pull", { amt: 0.12 }),
    P("kf_1990", "drift", { dir: "r", amt: 0.08 }),
    P("b3_26_busstop", "drift", { dir: "l", amt: 0.08 }), P("b3_27_study", "still"),
    P("b3_28_scooter", "drift", { dir: "l", amt: 0.10 }), P("b3_29_measure", "tilt", { dir: "u", amt: 0.10 }),
    P("b3_34_bangles2", "push", { amt: 0.12 }), P("kf_2005", "pull", { amt: 0.11 }),
  ]],
  // 144-161 — teenagers into 2005
  // 144-155.7 — «निशान तो है पण बड़ा वैदान रा» — the doctors' marks made literal:
  // the cold-open clinical imagery returns. Impersonal — the drip, the hand, the wrist. No faces.
  [148, 155.7, [
    P("s05_ward_drip", "drift", { dir: "l", amt: 0.07 }),
    P("s07_hand_cannula", "push", { ax: 0.42, amt: 0.13 }),
    P("s08_drip_chamber", "tilt", { dir: "d", amt: 0.10 }),  // धीरे धीरे — drop by drop; nobody in frame
  ]],
  // «अरे याने देख तेजा» 155.9-160.0 — push straight into her face, then the लीलण verse takes her story
  [155.7, 161, [
    P("w_portrait_look", "push", { ay: 0.44, amt: 0.17 }),
  ]],
  // 171-186 — THE लीलण VERSE: her, chronological
  [161, 186, [
    P("w_young_carry", "tilt", { dir: "u", amt: 0.09 }),          // 1976 — sure-footed in the rain
    P("o1_crowd_pull", "drift", { dir: "r", amt: 0.09 }), // she leads him
    P("b2_22_school", "push", { ax: 0.45, amt: 0.10 }),
    P("n2_competence", "drift", { dir: "r", amt: 0.09 }),
    P("b3_31_rotis", "push", { amt: 0.11 }),
    P("w_umbrella", "drift", { dir: "l", amt: 0.08 }),     // the umbrella held over him
    P("b5_42_feeding", "push", { ax: 0.45, amt: 0.11 }),
  ]],
  // 186-230 — weddings, grandchildren, and the illness beginning (strict order)
  [186, 228, [
    P("b4_36_wedding", "drift", { dir: "r", amt: 0.09 }), P("b4_37_rooftop", "still"),
    P("b4_38_empty", "drift", { dir: "l", amt: 0.07 }), P("b4_39_videocall", "push", { amt: 0.12 }),
    P("kf_2018", "diag", { dir: "ul", amt: 0.09 }), P("b5_43_kite", "tilt", { dir: "u", amt: 0.12 }),
    P("b5_41_newgrand", "push", { amt: 0.11 }), P("b5_45_hands", "push", { amt: 0.15 }),
    P("b5_46_selfie", "still"), P("kf_2021", "diag", { dir: "dl", amt: 0.09 }),
    P("b6_48_doorcrack", "push", { amt: 0.13 }), P("b6_49_corridorface", "push", { ax: 0.55, amt: 0.12 }),
    P("b6_50_hair", "push", { amt: 0.11 }), P("b6_51_cap", "still"),
    P("b6_52_drip", "drift", { dir: "l", amt: 0.08 }),
  ]],
  // 238.5-260 — treatment life, then the मेला begins (picks up right where the c6 clip ends)
  [243, 260, [
    P("b6_53_waiting", "drift", { dir: "l", amt: 0.07 }), P("b6_54_thermos", "still"),
    P("b6_55_3am", "drift", { dir: "r", amt: 0.07 }),
    P("w_support_walk", "drift", { dir: "r", amt: 0.08 }),  // she carries HIM now — beanie-legal here
    P("b6_57_ivtaanti", "push", { amt: 0.14 }),
    P("m1_arrival", "diag", { dir: "ur", amt: 0.10 }),
  ]],
];

const VOW = { name: "m3_vow_lipsync", mode: "push", opts: { amt: 0.09 }, at: 260, dur: 8 };

// 268 -> : the fast fall through the good memories, then the tree ending
const FAST = ["b1_01_lane", "b1_02_window", "b1_05_well", "b1_08_jalebi", "b2_17_firststeps",
  "n1_shoulders", "kf_1990", "b3_28_scooter", "kf_2005", "b4_36_wedding", "kf_2018", "b5_46_selfie", "kf_2021"];
const TAIL = [];
let ft = 268;
FAST.forEach(n => { TAIL.push({ name: n, mode: "still", opts: {}, at: ft, dur: 1.5 }); ft += 1.5; });
TAIL.push({ name: "m2_wheel_faces", mode: "tilt", opts: { dir: "u", amt: 0.10 }, at: ft, dur: 3.5 }); ft += 3.5;
TAIL.push({ name: "m4_family", mode: "push", opts: { amt: 0.10 }, at: ft, dur: 4 }); ft += 4;
TAIL.push({ name: "x_tree_tying", mode: "push", opts: { amt: 0.12 }, at: ft, dur: 5 }); ft += 5;
TAIL.push({ name: "x_tree_fifty", mode: "tilt", opts: { dir: "u", amt: 0.13 }, at: ft, dur: END - ft });

// ---- timeline ----
const timeline = [];
RUNS.forEach(([from, to, shots]) => {
  const each = (to - from) / shots.length;
  shots.forEach((s, i) => timeline.push({ kind: "photo", ...s, at: from + i * each, dur: each }));
});
SINGER.forEach(([f, at, dur, ss]) => timeline.push({ kind: "clip", file: A + f, at, dur, ss: ss || 0 }));
timeline.push({ kind: "photo", ...VOW });
TAIL.forEach(t => timeline.push({ kind: "photo", ...t }));
timeline.sort((a, b) => a.at - b.at);

const list = timeline.map((t, i) => ({ id: "S" + String(i + 1).padStart(2, "0"), ...t }));
fs.writeFileSync(D + "SHOTLIST_CHRONO_V3.md",
  "# Chronological cut v3 — shot list\n\n| # | at | dur | source |\n|---|----|-----|--------|\n" +
  list.map(s => `| ${s.id} | ${Math.floor(s.at / 60)}:${String(Math.floor(s.at % 60)).padStart(2, "0")} | ${s.dur.toFixed(1)}s | ${s.kind === "clip" ? "SINGER " + s.file.split("/").pop() : s.name} |`).join("\n") + "\n");

const NUMDIR = "/tmp/shotnums/"; fs.mkdirSync(NUMDIR, { recursive: true });
list.forEach(s => {
  const p = NUMDIR + s.id + ".png";
  if (fs.existsSync(p)) return;
  fs.writeFileSync("/tmp/n.typ", `#set page(width: 170pt, height: 64pt, margin: 0pt, fill: none)
#place(center + horizon, box(fill: rgb(0,0,0,200), inset: 10pt, radius: 5pt, text(fill: white, size: 30pt, weight: "bold", font: "Helvetica", "${s.id}")))`);
  execFileSync("typst", ["compile", "/tmp/n.typ", p, "--format", "png"], { timeout: 60000 });
});

// ---- render segments ----
let clean = [], numbered = [], missing = 0;
list.forEach((t, i) => {
  const co = `${B}${t.id}.mp4`, no = `${NB}${t.id}.mp4`;
  const last = i === list.length - 1;
  const fade = last ? `,fade=t=out:st=${Math.max(0, t.dur - 3).toFixed(2)}:d=3` : "";
  if (!fs.existsSync(co)) {
    if (t.kind === "clip") {
      // Singer clips get the same optical character as the photographs: filmic
      // highlight rolloff, warm halation bloom, chromatic aberration, vignette,
      // grain, and a slow gate-weave so the frame is never digitally locked.
      const fc =
        `[0:v]scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2,fps=${FPS},` +
        `curves=all='0/0 0.5/0.5 0.82/0.80 1/0.96',split=2[base][hl];` +
        `[hl]curves=all='0/0 0.68/0 1/1',gblur=sigma=22,colorchannelmixer=rr=1.0:gg=0.72:bb=0.55[glow];` +
        `[base][glow]blend=all_mode=screen:all_opacity=0.30,rgbashift=rh=1:bh=-1,vignette=angle=PI/5,` +
        `noise=alls=9:allf=t+u,crop=w=iw-10:h=ih-10:x='5+2.5*sin(2*PI*t/6)':y='5+2*cos(2*PI*t/7.5)',` +
        `scale=${W}:${H}:flags=lanczos,${lut(LOOK)},format=yuv420p${fade}[v]`;
      execFileSync("ffmpeg", ["-v", "error", "-y", "-ss", String(t.ss || 0), "-t", String(t.dur), "-i", t.file,
        "-filter_complex", fc, "-map", "[v]",
        "-c:v", "libx264", "-crf", CRF, "-preset", PRESET, "-an", co], { timeout: 600000 });
    } else {
      // Album law: healthy-past photographs wear a print frame (stock_framed/);
      // present-and-sick shots (clinical, b6_, मेला, vow, trees) run full-bleed.
      // Source priority: album matte (already built from the treated photo) ->
      // photoreal-treated still (stock_real/) -> untreated original.
      const framed = D + "stock_framed/" + t.name + ".png";
      const treated = D + "stock_real/" + t.name + ".png";
      const src = fs.existsSync(framed) ? framed
                : fs.existsSync(treated) ? treated
                : G + t.name + ".png";
      if (!fs.existsSync(src)) { console.log("MISSING " + src); missing++; return; }
      const m = kb(t.mode, t.dur, t.opts);
      m.vf = m.vf.replace(",format=yuv420p", `,${lut(ERA(t.name))},${lut(LOOK)},format=yuv420p`);
      execFileSync("ffmpeg", ["-v", "error", "-y", "-loop", "1", "-i", src,
        "-vf", m.vf + fade, "-frames:v", String(m.n), "-r", String(FPS),
        "-c:v", "libx264", "-crf", CRF, "-preset", PRESET, "-an", co], { timeout: 600000 });
    }
  }
  if (!fs.existsSync(no)) {
    execFileSync("ffmpeg", ["-v", "error", "-y", "-i", co, "-i", NUMDIR + t.id + ".png",
      "-filter_complex", "[0][1]overlay=28:H-h-28", "-c:v", "libx264", "-crf", CRF, "-preset", PRESET, "-an", no], { timeout: 600000 });
  }
  clean.push(co); numbered.push(no);
});
if (missing) { console.log(missing + " missing — aborting"); process.exit(1); }
console.log(list.length + " shots, " + list.reduce((s, t) => s + t.dur, 0).toFixed(1) + "s of picture");

// ---- approved English subtitles, baked into every output ----
// Windows snapped to ElevenLabs Scribe word timestamps (scribe_words.json, 2026-08-17).
// Start leads the first sung word by 0.2s; splits inside a line are word-exact.
const CUES = [
  [17.5, 27.1, 0], [29.1, 43.7, 1], [46.1, 52.0, 2], [54.3, 62.1, 3], [63.5, 69.2, 4],
  [71.1, 78.3, 5], [79.1, 87.3, 6], [115.7, 123.2, 7], [123.9, 132.0, 8], [133.2, 137.5, 9],
  [137.5, 142.1, 10], [141.9, 146.5, 11], [146.7, 154.0, 12], [155.7, 160.0, 13],
  [160.0, 167.5, 14], [168.3, 175.9, 15], [176.6, 185.2, 16], [228.8, 233.4, 17],
  [233.5, 242.0, 18], [242.2, 251.0, 19], [251.2, 255.5, 20], [255.6, 260.8, 21],
  [260.9, 266.0, 22], [266.7, 275.3, 23], [275.9, 286.3, 24], [295.8, 300.8, 25],
  [300.9, 307.0, 26],
];
const SUBS = fs.readdirSync(D + "subs/").filter(f => f.endsWith(".png")).sort();
const burnAndMux = (segs, cat, out) => {
  fs.writeFileSync(cat, segs.map(s => `file '${s}'`).join("\n") + "\n");
  execFileSync("ffmpeg", ["-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", cat, "-c", "copy", cat + ".mp4"], { timeout: 900000 });
  const inputs = ["-i", cat + ".mp4"];
  CUES.forEach(([, , ci]) => inputs.push("-i", D + "subs/" + SUBS[ci]));
  let fc = "[0:v]null[v0];";
  CUES.forEach(([s, e], i) => {
    fc += `[${i + 1}]scale=${W}:-1[t${i}];[v${i}][t${i}]overlay=0:H-h-70:enable='between(t,${s},${e - 0.06})'[v${i + 1}];`;
  });
  fc = fc.slice(0, -1).replace(new RegExp(`\\[v${CUES.length}\\]$`), "[vout]");
  execFileSync("ffmpeg", ["-v", "error", "-y", ...inputs, "-i", D + "kark_ki_taanti_master.mp3",
    "-filter_complex", fc, "-map", "[vout]", "-map", String(CUES.length + 1) + ":a",
    "-c:v", "libx264", "-crf", CRF, "-preset", PRESET,
    "-c:a", "aac", "-profile:a", "aac_low", "-b:a", "192k", "-ar", "44100", "-ac", "2",
    "-movflags", "+faststart", out], { timeout: 2400000 });
};
// ---- prologue: two black-screen cards BEFORE the song (silent) -------------
// card1 5.2s + card2 5.8s, each fading in/out; the film follows untouched.
const PREROLL = D + "cards/preroll.mp4";
if (!fs.existsSync(PREROLL)) {
  const seg = (png, dur, out) =>
    execFileSync("ffmpeg", ["-v", "error", "-y", "-loop", "1", "-i", D + png,
      "-f", "lavfi", "-i", "anullsrc=channel_layout=stereo:sample_rate=44100",
      "-t", String(dur),
      "-vf", `scale=${W}:${H},fps=${FPS},fade=t=in:st=0:d=0.8,fade=t=out:st=${(dur - 0.8).toFixed(1)}:d=0.8,format=yuv420p`,
      "-c:v", "libx264", "-crf", CRF, "-preset", PRESET,
      "-c:a", "aac", "-profile:a", "aac_low", "-b:a", "192k", "-ar", "44100", "-ac", "2",
      "-shortest", out], { timeout: 300000 });
  seg("cards/card1.png", 5.2, "/tmp/card_seg1.mp4");
  seg("cards/card2.png", 5.8, "/tmp/card_seg2.mp4");
  fs.writeFileSync("/tmp/preroll_cat.txt", "file '/tmp/card_seg1.mp4'\nfile '/tmp/card_seg2.mp4'\n");
  execFileSync("ffmpeg", ["-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", "/tmp/preroll_cat.txt", "-c", "copy", PREROLL], { timeout: 300000 });
}
const withPreroll = (body, out) => {
  fs.writeFileSync("/tmp/final_cat.txt", `file '${PREROLL}'\nfile '${body}'\n`);
  execFileSync("ffmpeg", ["-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", "/tmp/final_cat.txt",
    "-c", "copy", "-movflags", "+faststart", out], { timeout: 900000 });
};
burnAndMux(clean, B + "cat.txt", D + "body_clean.mp4");
burnAndMux(numbered, NB + "cat.txt", D + "body_numbered.mp4");
withPreroll(D + "body_clean.mp4", D + "KARK_MV_CHRONO_V3.mp4");
withPreroll(D + "body_numbered.mp4", D + "KARK_MV_CHRONO_V3_NUMBERED.mp4");
console.log("done: KARK_MV_CHRONO_V3(.mp4 / _NUMBERED.mp4) — prologue cards + subtitles burned");
