// «कर्क की तांती» assembler. Every shot is a still with a slow Ken Burns move
// (free, ffmpeg) — the singer's shots and the couple's photographs alike, cut
// to the author-confirmed seam map. Output: 1920x1080 / 24fps / master audio.
import { execFileSync } from "child_process";
import fs from "fs";

const D = "/Users/dusty/Dev/metaphrand/stories/songbook/kark-mv/";
const B = D + "build/";
fs.mkdirSync(B, { recursive: true });
const P = D + "photos/", A = D + "atape/", K = D + "keyframes/", E = D + "elements/", S = D + "samples/", BT = D + "btape/";

// [source, seconds, move] — moves: in (push in), out (pull back), l/r (drift), still
const EDL = [
  // 0:00-0:17 ALAP — the singer, close, alone
  [A + "c3_close_storm.png", 8.5, "in"], [A + "c2_mid_gold.png", 8.5, "out"],
  // 0:17-0:25 verse 1 opens
  [A + "c2_mid_gold.png", 8, "in"],
  // 0:25-1:27 BEAT 1 — courtship 1976 (15 photos across three verse gaps, singer heads verses 2 and 3)
  [P + "b1_01_lane.png", 3, "in"], [P + "b1_02_window.png", 3, "in"], [P + "b1_05_well.png", 3, "l"],
  [P + "b1_04_friends.png", 3, "r"], [P + "b1_03_bangles.png", 3, "in"], [P + "b1_08_jalebi.png", 3, "in"],
  [A + "c3_close_storm.png", 8, "out"],
  [P + "b1_07_cart.png", 3, "l"], [P + "b1_09_field.png", 3.5, "in"], [P + "b1_12_mehndi.png", 3, "in"],
  [P + "b1_11_studio.png", 3, "in"], [BT + "o1_crowd_pull.png", 3.5, "r"],
  [A + "c5_wide_storm.png", 8, "in"],
  [BT + "o4_wheel_ride.png", 3, "in"], [BT + "o3_after.png", 3, "in"], [BT + "o2_first_thread.png", 3.5, "in"],
  [K + "kf_1976.png", 4, "out"],
  // 1:27-1:56 INSTRUMENTAL 1 — BEAT 2 begins, no singer
  [P + "b2_16_newborn.png", 3.5, "in"], [P + "b2_23_charpai.png", 3.5, "l"], [P + "b2_17_firststeps.png", 3, "in"],
  [P + "b2_18_bath.png", 3, "r"], [P + "b2_20_birthday.png", 3, "in"], [P + "b2_22_school.png", 3, "in"],
  [BT + "n1_shoulders.png", 3.5, "in"], [BT + "n3_courtyard.png", 3.5, "l"], [BT + "n2_competence.png", 3, "r"],
  // 1:56-2:04 verse 4 opens
  [A + "c5_wide_storm.png", 8, "out"],
  // 2:04-2:43 BEAT 3 — teenagers (verse gaps 5 and 6, singer between)
  [K + "kf_1990.png", 3.5, "in"], [P + "b3_26_busstop.png", 3, "in"], [P + "b3_27_study.png", 3, "l"],
  [A + "c3_close_storm.png", 8, "in"],
  [P + "b3_28_scooter.png", 3, "r"], [P + "b3_29_measure.png", 3, "in"], [P + "b3_31_rotis.png", 3, "in"],
  [P + "b3_33_mechanic.png", 3, "l"], [P + "b3_30_prizeday.png", 3, "in"], [P + "b3_32_sofa.png", 3, "in"],
  // 2:42-2:50 the लीलण verse opens
  [A + "c4_ivstand_storm.png", 8, "out"],
  // 2:50-3:05 her, across the years
  [BT + "n4_thread_watch.png", 3.5, "in"], [P + "b3_34_bangles2.png", 3.5, "in"], [K + "kf_2005.png", 4, "out"],
  // 3:05-3:27 INSTRUMENTAL 2 first half — BEAT 4 + BEAT 5, no singer
  [P + "b4_36_wedding.png", 3.5, "in"], [P + "b4_37_rooftop.png", 3, "out"], [P + "b4_38_empty.png", 3.5, "l"],
  [P + "b4_39_videocall.png", 3, "in"], [K + "kf_2018.png", 3.5, "in"],
  [P + "b5_43_kite.png", 3, "in"], [P + "b5_41_newgrand.png", 3, "in"],
  // 3:27-3:49 second half — BEAT 6, the disease arrives, wordless
  [P + "b5_44_nap.png", 3, "l"], [P + "b5_46_selfie.png", 3, "in"], [K + "kf_2021.png", 3.5, "out"],
  [P + "b6_48_doorcrack.png", 4, "in"], [P + "b6_49_corridorface.png", 4, "in"], [P + "b6_50_hair.png", 3.5, "in"],
  // 3:49-3:57 the turn — singer
  [A + "c6_close_rain.png", 8, "in"],
  // 3:57-4:12 the hospital
  [P + "b6_51_cap.png", 3.5, "in"], [P + "b6_52_drip.png", 3.5, "l"], [P + "b6_55_3am.png", 3.5, "in"],
  [P + "b6_57_ivtaanti.png", 4.5, "in"],
  // 4:12-4:20 the ask — singer
  [A + "c4_ivstand_storm.png", 8, "out"],
  // 4:20-4:28 THE VOW
  [BT + "m3_vow_lipsync.png", 8, "in"],
  // 4:28-4:34 the मेला
  [BT + "m1_arrival.png", 3, "in"], [BT + "m2_wheel_faces.png", 3, "in"],
  // 4:34-4:42 the renewal line — singer
  [A + "c6_close_rain.png", 8, "out"],
  // 4:42-4:48 THE CASCADE — six thread-tyings, fifty years, 1s each
  [K + "kf_1976.png", 1, "still"], [K + "kf_1990.png", 1, "still"], [K + "kf_2005.png", 1, "still"],
  [K + "kf_2018.png", 1, "still"], [K + "kf_2021.png", 1, "still"], [K + "kf_2026.png", 1, "still"],
  // 4:48-4:56 algoza alone
  [P + "x_43_fluteboy.png", 4, "in"], [P + "x_42_childwrist.png", 4, "in"],
  // 4:56-5:03 the whisper
  [BT + "m5_thread_post.png", 12.7, "in"],
];

const W = 1920, H = 1080, FPS = 24;
const kb = (mode, dur) => {
  const n = Math.round(dur * FPS);
  // zoompan works on an upscaled source so the move stays smooth
  const z = { in: `min(1+0.0009*on,1.12)`, out: `max(1.12-0.0009*on,1)`, l: `1.08`, r: `1.08`, still: `1` }[mode];
  const x = { in: `iw/2-(iw/zoom/2)`, out: `iw/2-(iw/zoom/2)`, l: `(iw-iw/zoom)*(1-on/${n})`, r: `(iw-iw/zoom)*(on/${n})`, still: `iw/2-(iw/zoom/2)` }[mode];
  const y = `ih/2-(ih/zoom/2)`;
  return `scale=${Math.round(W*1.25)}:${Math.round(H*1.25)}:force_original_aspect_ratio=increase,crop=${Math.round(W*1.25)}:${Math.round(H*1.25)},zoompan=z='${z}':x='${x}':y='${y}':d=${n}:s=${W}x${H}:fps=${FPS},format=yuv420p`;
};

const segs = [];
let missing = 0, t = 0;
EDL.forEach(([src, dur, mode], i) => {
  if (!fs.existsSync(src)) { console.log("MISSING " + src); missing++; return; }
  const out = `${B}s${String(i).padStart(3, "0")}.mp4`;
  if (!fs.existsSync(out)) {
    const nf = Math.round(dur * FPS);
    execFileSync("ffmpeg", ["-v", "error", "-y", "-loop", "1", "-i", src,
      "-vf", kb(mode, dur), "-frames:v", String(nf), "-r", String(FPS), "-c:v", "libx264", "-crf", "20", "-preset", "veryfast", "-an", out], { timeout: 600000 });
  }
  segs.push(out); t += dur;
});
if (missing) { console.log(missing + " sources missing — aborting"); process.exit(1); }
console.log(`${segs.length} segments, ${t.toFixed(1)}s of picture (master is 307.2s)`);

fs.writeFileSync(B + "cat.txt", segs.map(s => `file '${s}'`).join("\n") + "\n");
execFileSync("ffmpeg", ["-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", B + "cat.txt", "-c", "copy", B + "picture.mp4"], { timeout: 900000 });
execFileSync("ffmpeg", ["-v", "error", "-y", "-i", B + "picture.mp4", "-i", D + "kark_ki_taanti_master.mp3",
  "-map", "0:v", "-map", "1:a", "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-shortest", "-movflags", "+faststart",
  D + "KARK_MV_V1.mp4"], { timeout: 900000 });
const dur = execFileSync("ffprobe", ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", D + "KARK_MV_V1.mp4"], { encoding: "utf8" }).trim();
console.log("KARK_MV_V1.mp4 — " + dur + "s");
