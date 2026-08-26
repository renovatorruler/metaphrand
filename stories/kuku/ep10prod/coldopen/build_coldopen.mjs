// EP10 «ग से गाय» — cold-open animatic from stills (V7 cart lineage).
// Stills only, no motion: each frame held for its EDL duration with a short
// cross-dissolve, so the author can judge shot order, pacing and readability.
import { execFileSync } from "child_process";
import fs from "fs";

const P = "/Users/dusty/Dev/metaphrand/stories/kuku/ep10prod/coldopen/";
const F = P + "frames/", B = P + "build/";
fs.mkdirSync(B, { recursive: true });
const W = 1920, H = 1080, FPS = 30;

// [frame, seconds, on-screen note for the review cut]
const SHOTS = [
  ["co01_ring_wide", 5.0, "S1 — the ring at dusk"],
  ["co02_rishi_med", 4.5, "S2 — Rishi: fly out, land on your mark"],
  ["co03_furia_close", 3.0, "S3 — Furia: पहले मैं!"],
  ["co04_takeoff", 4.0, "S4 — the launch"],
  ["co05_landing", 4.0, "S5 — landed, paw past the mark"],
  ["co06_cart_slope", 5.0, "S6 — the cart, Gauri, three markers"],
  ["co07_cheel_tower", 4.5, "S7 — Cheel with the broken क"],
  ["co08_rope_release", 3.0, "S8 — the knot slips"],
  ["co09_cart_runs", 5.0, "S9 — the cart runs"],
  ["co10_bell_stolen", 4.0, "S10 — the bell taken"],
  ["co11_furia_choice", 5.0, "S11 — Furia chooses Gauri"],
];

const segs = [];
SHOTS.forEach(([name, dur], i) => {
  const src = F + name + ".png";
  if (!fs.existsSync(src)) { console.log("MISSING " + name); return; }
  const out = B + String(i).padStart(2, "0") + ".mp4";
  execFileSync("ffmpeg", ["-v", "error", "-y", "-loop", "1", "-i", src, "-t", String(dur),
    "-vf", `scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2,fps=${FPS},format=yuv420p`,
    "-c:v", "libx264", "-crf", "19", "-preset", "veryfast", "-an", out], { timeout: 300000 });
  segs.push(out);
});

// cross-dissolve chain (0.4s) so the animatic reads as a sequence, not a slideshow
let fc = "", prev = "[0:v]", t = 0;
const D = 0.4;
for (let i = 1; i < segs.length; i++) {
  t += SHOTS[i - 1][1] - D;
  fc += `${prev}[${i}:v]xfade=transition=fade:duration=${D}:offset=${t.toFixed(2)}[x${i}];`;
  prev = `[x${i}]`;
}
fc = fc.slice(0, -1).replace(new RegExp(`\\[x${segs.length - 1}\\]$`), "[v]");
const inputs = [];
segs.forEach(s => inputs.push("-i", s));
execFileSync("ffmpeg", ["-v", "error", "-y", ...inputs, "-filter_complex", fc, "-map", "[v]",
  "-c:v", "libx264", "-crf", "19", "-preset", "veryfast", "-movflags", "+faststart",
  P + "EP10_COLDOPEN_ANIMATIC.mp4"], { timeout: 900000 });

const dur = execFileSync("ffprobe", ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0",
  P + "EP10_COLDOPEN_ANIMATIC.mp4"], { encoding: "utf8" }).trim();
console.log(`EP10_COLDOPEN_ANIMATIC.mp4 — ${segs.length} shots, ${dur}s`);
