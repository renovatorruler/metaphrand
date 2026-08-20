// Re-GENERATE every photograph with its film stock native to the image —
// not a filter: nano re-renders each approved photo on T-Max / Portra,
// content locked by using the approved image as the reference.
import { execFileSync } from "child_process";
import fs from "fs";
const D = "/Users/dusty/Dev/metaphrand/stories/songbook/kark-mv/";
const OUT = D + "stock/"; fs.mkdirSync(OUT, { recursive: true });

// canonical source for every shot name (rebuilt wins)
const src = (n) => {
  for (const d of ["rebuilt/", "photos/", "btape/", "previz/"]) if (fs.existsSync(D + d + n + ".png")) return D + d + n + ".png";
  return null;
};
const KEEP = "Keep EVERYTHING identical to the reference photograph — the same people with the same faces, same poses, same clothing, same composition, same background, same framing, same border if it has one. Change ONLY the photographic rendering: ";
const STOCK = {
  tmax: KEEP + "re-render it as a genuine 1970s BLACK-AND-WHITE photograph shot on Kodak T-Max 100: true monochrome, deep rich blacks, luminous highlights, fine silver-halide grain, the tonality of a real darkroom print of that era. No color anywhere.",
  early: KEEP + "re-render it as an early-1990s colour print from consumer Kodak negative film: warm faded colours, visible film grain, the slight colour shift and softness of an aged print.",
  p400: KEEP + "re-render it as shot on Kodak Portra 400: warm natural skin tones, gentle contrast, clearly visible fine film grain, the golden quality of a printed memory.",
  p800: KEEP + "re-render it as shot on Kodak Portra 800: warm golden tones, soft filmic contrast, pronounced visible film grain, cinematic and warm — never digital-clean.",
};
const ERA = (n) => /^(b1_|o[0-9]|kf_1976)/.test(n) ? "tmax" : /^(b2_|n[0-9]|kf_1990)/.test(n) ? "early" : /^(b3_|kf_2005)/.test(n) ? "p400" : "p800";

const NAMES = ["b1_01_lane","b1_02_window","b1_03_bangles","b1_04_friends","b1_05_well","b1_07_cart","b1_08_jalebi","b1_09_field","b1_11_studio","b1_12_mehndi","o1_crowd_pull","o2_first_thread","o3_after","o4_wheel_ride","kf_1976","b2_16_newborn","b2_17_firststeps","b2_18_bath","b2_20_birthday","b2_22_school","b2_23_charpai","n1_shoulders","n2_competence","n3_courtyard","n4_thread_watch","kf_1990","b3_26_busstop","b3_27_study","b3_28_scooter","b3_29_measure","b3_30_prizeday","b3_31_rotis","b3_32_sofa","b3_33_mechanic","b3_34_bangles2","kf_2005","b4_36_wedding","b4_37_rooftop","b4_38_empty","b4_39_videocall","kf_2018","b5_41_newgrand","b5_42_feeding","b5_43_kite","b5_44_nap","b5_45_hands","b5_46_selfie","kf_2021","b6_48_doorcrack","b6_49_corridorface","b6_50_hair","b6_51_cap","b6_52_drip","b6_53_waiting","b6_54_thermos","b6_55_3am","b6_57_ivtaanti","kf_2026","m1_arrival","m2_wheel_faces","m3_vow_lipsync","m4_family","x_tree_tying","x_tree_fifty","s05_ward_drip","s02_diya_wrist"];

let made = 0, failed = [];
for (const n of NAMES) {
  const out = OUT + n + ".png"; if (fs.existsSync(out)) continue;
  const s = src(n); if (!s) { console.log("NO SOURCE " + n); failed.push(n); continue; }
  let raw;
  try { raw = execFileSync("higgsfield", ["generate", "create", "nano_banana_pro", "--prompt", STOCK[ERA(n)],
    "--image", s, "--aspect_ratio", "16:9", "--resolution", "2k", "--wait", "--json"], { encoding: "utf8", timeout: 900000 }); }
  catch (e) { raw = String(e.stdout || "") + String(e.stderr || e.message); }
  let url = (raw.match(/https:\/\/[^"\s]*\.(png|webp|jpg)/) || [null])[0];
  if (!url) { try { const j = JSON.parse(raw); const a = Array.isArray(j) ? j : [j]; url = a[0].result_url || null; } catch (e) {} }
  if (url) { execFileSync("curl", ["-sL", "--retry", "3", "-o", out, url], { timeout: 300000 }); made++; console.log("OK " + n); }
  else { failed.push(n); console.log("FAIL " + n + ": " + raw.slice(0, 100)); }
}
console.log(`made=${made} failed=${failed.length} ${failed.join(",")}`);
