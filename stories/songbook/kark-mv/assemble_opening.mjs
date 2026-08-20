// «कर्क की तांती» — OPENING preview (song 0:00–0:30) built on the OmniHuman singer chunks.
// The chunk seam is hidden editorially: a photo cut lands exactly on the first beat
// (17.01s, from the audio onset data), and the singer returns already drumming.
import { execFileSync } from "child_process";
import fs from "fs";
import { kb, FPS } from "./move.mjs";

const D = "/Users/dusty/Dev/metaphrand/stories/songbook/kark-mv/";
const T = "/tmp/open_segs/"; fs.mkdirSync(T, { recursive: true });

// timeline v3 — the opening speaks only two languages: the disease and the deity.
//   [0,3.2) ward drip · [3.2,6.4) diya wrist
//   [6.4,10.2) singer आलाप · [10.2,11.5) POP Tejaji shrine at dusk · [11.5,15.2) singer
//   [15.2,16.3) POP thread-on-IV (the one cancer whisper) · [16.3,17.01) singer breath
//   [17.01,19.2) the मूर्ति CLOSE ON THE FIRST थाप — the god he is calling · [19.2,30.05) chunk2
const photos = [
  ["s05_ward_drip", 3.2, "push", { amt: 0.10 }],
  ["s02_diya_wrist", 3.2, "push", { amt: 0.12 }],
  ["x_shrine_dusk", 1.3, "push", { amt: 0.06 }],
  ["b6_57_ivtaanti", 1.1, "push", { amt: 0.06 }],
  ["x_murti_close", 2.19, "push", { amt: 0.10 }],
];
photos.forEach(([n, dur, mode, opts], i) => {
  const m = kb(mode, dur, opts);
  execFileSync("ffmpeg", ["-v", "error", "-y", "-loop", "1", "-i", D + "stock/" + n + ".png",
    "-vf", m.vf, "-frames:v", String(m.n), "-r", String(FPS),
    "-c:v", "libx264", "-crf", "20", "-preset", "veryfast", "-an", T + "p" + i + ".mp4"], { timeout: 300000 });
});

// singer segments: chunk video time = song time − chunk audio start (chunk1@4.0, chunk2@16.5)
const segs = [
  ["omni_daf_test.mp4", 2.4, 6.2, "s1a"],    // song 6.4 → 10.2
  ["omni_daf_test.mp4", 7.5, 11.2, "s1b"],   // song 11.5 → 15.2
  ["omni_daf_test.mp4", 12.3, 13.01, "s1c"], // song 16.3 → 17.01
  ["omni_daf_chunk2.mp4", 2.7, 13.55, "s2"], // song 19.2 → 30.05
];
segs.forEach(([f, a, b, o]) => {
  execFileSync("ffmpeg", ["-v", "error", "-y", "-i", D + "atape/" + f,
    "-vf", `trim=${a}:${b},setpts=PTS-STARTPTS,scale=1920:1080:force_original_aspect_ratio=increase,crop=1920:1080,fps=${FPS},format=yuv420p`,
    "-an", "-c:v", "libx264", "-crf", "20", "-preset", "veryfast", T + o + ".mp4"], { timeout: 300000 });
});

fs.writeFileSync(T + "cat.txt", ["p0", "p1", "s1a", "p2", "s1b", "p3", "s1c", "p4", "s2"].map(x => `file '${T}${x}.mp4'`).join("\n") + "\n");
execFileSync("ffmpeg", ["-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", T + "cat.txt", "-c", "copy", T + "picture.mp4"], { timeout: 300000 });
execFileSync("ffmpeg", ["-v", "error", "-y", "-i", T + "picture.mp4", "-ss", "0", "-t", "30.1", "-i", D + "kark_ki_taanti_master.mp3",
  "-map", "0:v", "-map", "1:a", "-c:v", "copy", "-c:a", "aac", "-profile:a", "aac_low", "-b:a", "192k",
  "-ar", "44100", "-ac", "2", "-movflags", "+faststart", D + "atape/opening_v1.mp4"], { timeout: 300000 });
console.log("done", execFileSync("ffprobe", ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", D + "atape/opening_v1.mp4"], { encoding: "utf8" }).trim());
