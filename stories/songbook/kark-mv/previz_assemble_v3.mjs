// PREVIZ assembly — disposable. Cuts stills+clips to the confirmed seam map,
// muxes the master, appends black tail. 1280x720 / 24fps throughout.
import { execFileSync } from "child_process";
import fs from "fs";

const D = "/Users/dusty/Dev/metaphrand/stories/songbook/kark-mv";
const P = `${D}/previz`;
const S = `${D}/samples`;
const B = `${P}/build`;
fs.mkdirSync(B, { recursive: true });

// (source, seconds) in play order — sums to 303.0s; +4.3s black = 307.3
const edl = [
  // 0:00-0:17 intro — the god first, not the disease
  [`${P}/s00_tejaji_murti.png`, 6], [`${P}/s37_devra_threads.png`, 5], [`${S}/artist_star.png`, 6],
  // 0:17-1:27 seg1 — 1976 onward, nobody knows
  [`${P}/s32_newlyweds.png`, 8], [`${P}/s31_first_thread.png`, 9], [`${P}/c03_1976_leads.mp4`, 5],
  [`${P}/s27_1976_approach.png`, 8], [`${P}/s28_wheel_1976.png`, 8], [`${S}/artist_star.png`, 7],
  [`${P}/s22_kids_shoulders.png`, 8], [`${P}/s23_her_carrying.png`, 9], [`${P}/s21_1990_fair.png`, 8],
  // 1:27-1:56 flute1 — 2005 era
  [`${P}/s16_rooftop_algoza.png`, 7], [`${P}/s18_scooter.png`, 8], [`${P}/s19_bangles.png`, 7],
  [`${P}/s17_2005_fair.png`, 7],
  // 1:56-2:42 seg2 quarrel+needles — 2018, still healthy
  [`${P}/s14_2018_selfie.png`, 9], [`${P}/s15_2018_thread.png`, 9], [`${P}/c01_2018_fair.mp4`, 5],
  [`${P}/s24_mangu_quarrel.png`, 8], [`${P}/s25_dholak_palm.png`, 7], [`${P}/s13_mangu_ivwind.png`, 8],
  // 2:42-3:05 the लीलण verse — SHE takes care of HIM
  [`${P}/s07_forms.png`, 7], [`${P}/s26_lifting.png`, 8], [`${S}/btape_couple.png`, 8],
  // 3:05-3:49 instrumental — the album catches up: the disease, wordless
  [`${P}/s10_doctor_gray.png`, 7], [`${P}/s20_needle_flash.png`, 5], [`${P}/s05_ward_drip.png`, 7],
  [`${P}/s06_taanti_pole.png`, 8], [`${P}/s08_thermos.png`, 7], [`${P}/s12_fair_eve.png`, 6],
  [`${P}/s29_mangu_storm.png`, 4],
  // 3:49-4:48 seg3 — the granted मेला; on the vow, back into memory
  [`${P}/s33_2026_rain_wheel.png`, 9], [`${P}/s35_family_rain.png`, 10], [`${P}/s34_grandkid_wrist.png`, 8],
  [`${P}/c02_wheel_back.mp4`, 5], [`${P}/s32_newlyweds.png`, 9], [`${P}/s31_first_thread.png`, 9],
  [`${P}/s22_kids_shoulders.png`, 9],
  // 4:48-4:56 algoza alone
  [`${P}/s36_flute_boy.png`, 8],
  // 4:56-5:03 whisper
  [`${P}/s37_devra_threads.png`, 7],
];

const ff = (args) => execFileSync("ffmpeg", ["-v", "error", "-y", ...args], { timeout: 600000 });
const VF = "scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,fps=24,format=yuv420p";
const ENC = ["-c:v", "libx264", "-crf", "23", "-preset", "fast", "-an"];

const segs = [];
let missing = 0;
edl.forEach(([src, dur], i) => {
  if (!fs.existsSync(src)) { console.log("MISSING " + src); missing++; return; }
  const out = `${B}/v3seg${String(i).padStart(3, "0")}.mp4`;
  if (!fs.existsSync(out)) {
    if (src.endsWith(".mp4")) ff(["-i", src, "-t", String(dur), "-vf", VF, ...ENC, out]);
    else ff(["-loop", "1", "-framerate", "24", "-t", String(dur), "-i", src, "-vf", VF, ...ENC, out]);
  }
  segs.push(out);
});
if (missing) { console.log(missing + " sources missing — aborting"); process.exit(1); }

const black = `${B}/v3segblack.mp4`;
if (!fs.existsSync(black)) ff(["-f", "lavfi", "-i", "color=black:s=1280x720:r=24", "-t", "4.3", ...ENC, black]);
segs.push(black);

fs.writeFileSync(`${B}/cat3.txt`, segs.map(s => `file '${s}'`).join("\n") + "\n");
ff(["-f", "concat", "-safe", "0", "-i", `${B}/cat3.txt`, "-c", "copy", `${B}/video3.mp4`]);
ff(["-i", `${B}/video3.mp4`, "-i", `${D}/kark_ki_taanti_master.mp3`, "-map", "0:v", "-map", "1:a", "-c:v", "copy", "-c:a", "aac", "-b:a", "160k", "-shortest", `${D}/KARK_MV_PREVIZ_V3.mp4`]);
const dur = execFileSync("ffprobe", ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", `${D}/KARK_MV_PREVIZ_V3.mp4`], { encoding: "utf8" }).trim();
console.log("PREVIZ: " + dur + "s -> KARK_MV_PREVIZ_V3.mp4, " + segs.length + " segments");
