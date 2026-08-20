// Era grade + border, applied in POST so every photograph of an era is exactly
// as old as every other one — the model is no longer asked for era look at all.
// Reads photos/, writes graded/. Free, deterministic, re-runnable.
import { execFileSync } from "child_process";
import fs from "fs";

const D = "/Users/dusty/Dev/metaphrand/stories/songbook/kark-mv/";
const OUT = D + "graded/";
fs.mkdirSync(OUT, { recursive: true });

// Which era each source belongs to
const ERA = (name) => {
  if (/^b1_|^o[0-9]_|kf_1976/.test(name)) return "1976";
  if (/^b2_|^n[0-9]_|kf_1990/.test(name)) return "1990";
  if (/^b3_|kf_2005/.test(name)) return "2005";
  if (/^b4_|kf_2018/.test(name)) return "2018";
  if (/^b5_|kf_2021/.test(name)) return "2021";
  return "2026"; // b6_, x_, m*, kf_2026
};

// Per era: colour grade + border geometry.
// border = [white frame px, inner bevel px, corner style]
const LOOK = {
  // 1976 — T-MAX 100: true black-and-white, punchy curve, fine grain, warm paper mat
  1976: { vf: "hue=s=0,curves=all='0/0.03 0.25/0.20 0.75/0.82 1/0.98',eq=contrast=1.06,noise=alls=8:allf=t+u,vignette=PI/5.5", border: 46, tint: "#f2ecdc" },
  // 1990 — early consumer colour gone warm: Portra-family, soft shoulder, visible grain
  1990: { vf: "curves=all='0/0.05 0.5/0.52 1/0.95',eq=saturation=0.86:contrast=0.95,colorchannelmixer=rr=1.06:gg=1.0:bb=0.88,noise=alls=9:allf=t+u,vignette=PI/6.5", border: 30, tint: "#f6f2e8" },
  // 2005 — PORTRA 400: warm skin, gentle contrast, honest grain
  2005: { vf: "curves=all='0/0.04 0.5/0.51 1/0.96',eq=saturation=0.95:contrast=1.0,colorchannelmixer=rr=1.05:gg=1.0:bb=0.92,noise=alls=7:allf=t+u", border: 0, tint: "#ffffff" },
  // 2018/2021 — PORTRA 800: the golden memory look, a touch more grain, no clean digital
  2018: { vf: "curves=all='0/0.04 0.5/0.51 1/0.96',eq=saturation=0.97:contrast=1.01,colorchannelmixer=rr=1.05:gg=1.0:bb=0.93,noise=alls=10:allf=t+u", border: 0, tint: "#ffffff" },
  2021: { vf: "curves=all='0/0.04 0.5/0.51 1/0.96',eq=saturation=0.97:contrast=1.01,colorchannelmixer=rr=1.05:gg=1.0:bb=0.93,noise=alls=10:allf=t+u", border: 0, tint: "#ffffff" },
  // present — PORTRA 800 pushed: barely faded, warm, grained; never phone-clean
  2026: { vf: "curves=all='0/0.03 0.5/0.50 1/0.97',eq=saturation=0.94:contrast=1.02,colorchannelmixer=rr=1.04:gg=1.0:bb=0.94,noise=alls=10:allf=t+u", border: 0, tint: "#ffffff" },
};

// eras whose sources have a model-baked white border that must be cropped away
const BAKED = new Set(['1976','1990','2005']);
const REBUILT = new Set(fs.readdirSync(D + "rebuilt/"));
// rebuilt/ wins over the older versions of the same filename, and is borderless
// previz-canon: the two impersonal cold-open hint shots live in previz/
const HINTS=["s05_ward_drip.png","s02_diya_wrist.png"];
const SRC = [[D + "previz/", HINTS],[D + "rebuilt/", fs.readdirSync(D + "rebuilt/")], [D + "photos/", fs.readdirSync(D + "photos/").filter(f => !REBUILT.has(f))], [D + "btape/", fs.readdirSync(D + "btape/").filter(f => !REBUILT.has(f))], [D + "keyframes/", fs.readdirSync(D + "keyframes/").filter(f => !REBUILT.has(f))]];
let n = 0;
for (const [dir, files] of SRC) {
  for (const f of files) {
    if (!f.endsWith(".png") || /^(contact|grid|BAD|OLD|REJECT|lb|l[0-9])/.test(f)) continue;
    const era = ERA(f);
    const L = LOOK[era];
    const out = OUT + f;
    if (fs.existsSync(out)) { continue; }
    const b = L.border;
    // 1) crop away the border the model baked into the source, so the grade
    //    never touches paper; 2) age ONLY the photographic content;
    //    3) mat the aged picture inside one clean paper frame.
    const crop = (BAKED.has(era) && !REBUILT.has(f)) ? "crop=iw*0.87:ih*0.87," : "";
    const vf = b > 0
      ? `${crop}${L.vf},pad=iw+${b * 2}:ih+${b * 2}:${b}:${b}:color=${L.tint}`
      : `${crop}${L.vf}`;
    execFileSync("ffmpeg", ["-v", "error", "-y", "-i", dir + f, "-vf", vf, out], { timeout: 120000 });
    n++;
  }
}
console.log(n + " photographs graded into graded/");
