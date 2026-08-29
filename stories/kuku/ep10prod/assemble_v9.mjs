// EP10 V7 — the FULL cut: every screenplay beat gets picture, not just dialogue.
//
// The numbered animatic gave screen time only to the 155 dialogue cues and chose
// each picture from the speaker's own frames, so 46 generated frames — including
// the opening wide, the golden ग standing and the stopped cart — never appeared
// at all. Here the screenplay's ACTION lines and (ध्वनि) sound cues become their
// own silent beats, and the frame is chosen from what the beat describes.
//
// Numbering is deliberately preserved: dialogue keeps S001…S155 so the author's
// existing frame notes still address the same moments; action beats are numbered
// A01… separately.
//
//   node assemble_v7_full.mjs            # build
//   node assemble_v7_full.mjs --dry      # report the beat list and frame coverage
import { execFileSync } from "child_process";
import fs from "fs";

const K = "/Users/dusty/Dev/metaphrand/stories/kuku/";
const P = K + "ep10prod/";
const SCRIPT = K + "2026-08-20_EP10_ga_gaay_SPEC_SCREENPLAY_v7_AUDIO_FIRST.md";
const CUES = P + "v7_table_read/cues/";
const S = P + "stills/", I = P + "inbetweens/";
const B = P + "v7_table_read/build_v8/"; fs.mkdirSync(B, { recursive: true });
const NUM = "/tmp/ep10nums_full/"; fs.mkdirSync(NUM, { recursive: true });
const W = 1920, H = 1080, FPS = 30, GAP = 0.45;
const DRY = process.argv.includes("--dry");

const CUEIDX = JSON.parse(fs.readFileSync(P + "v7_table_read/cue_index.json", "utf8"));
// The CART CLOCK for each shot, published by the spec engine — where the cart
// is at that moment, not where the camera stands. The camera may leap ahead to
// the flat stone; the cart may never go back up the slope. The cut MUST
// obey this: a chase in which the cart teleports back up the slope is not a
// chase. Picking a picture by who is speaking, with no regard to position, is
// what produced 44 backwards jumps in 96 shots.
const POS = JSON.parse(fs.readFileSync(P + "shot_positions.json", "utf8"));
// Which story beat each shot belongs to. Without this a speaker's "subject
// frames" span the whole episode, so a scene-1 line could pull फ्यूरिया's
// scene-5 shot and pin the cart at the finish line for the rest of the chase.
const BEATS = JSON.parse(fs.readFileSync(P + "shot_beats.json", "utf8"));
const beatOf = f => BEATS[f.split("/").pop().replace(/\.png$/, "").split("__")[0]] || null;
// screenplay scene -> the story beats whose frames may appear in it
const SCENE_BEATS = {
  "० उड़ान-आँगन": ["RingDrill", "Briefing"],
  "०-अ मीनार": ["TowerMischief", "RopeSlips"],
  "१ भागती गाड़ी": ["Runaway"],
  "२ निशान": ["Braking"],
  "३ ग बनना": ["FlatSound", "Forging"],
  "४ आख़िरी मोड़": ["LastApproach"],
  "५ रुकना": ["TheStop"],
  "६ बाद में": ["AfterStop"],
  "७ दादी": ["DoorwayNight"],
  "८ मीनार": ["TowerEnd"],
};
const inScene = (f, scene) => { const b = beatOf(f); const allow = SCENE_BEATS[scene]; return !b || !allow || allow.includes(b); };
// every frame that belongs to a scene — the ONLY legitimate fallback when the
// speaker has no shot of their own there. Reaching outside the scene is what
// pulled a 42-metre frame into scene 1 and pinned the cart at the finish.
const sceneFrames = scene => {
  const allow = SCENE_BEATS[scene] || [];
  return Object.keys(BEATS).filter(k => allow.includes(BEATS[k])).flatMap(k => pool([k]));
};
const posOf = f => { const k = f.split("/").pop().replace(/\.png$/, "").split("__")[0]; return POS[k] !== undefined ? +POS[k] : null; };
let lastPos = 0;
const RUN_SCENES = new Set(["१ भागती गाड़ी", "२ निशान", "३ ग बनना", "४ आख़िरी मोड़", "५ रुकना"]);
const cueFiles = fs.readdirSync(CUES).filter(f => f.endsWith(".mp3")).sort();
const dur = f => +execFileSync("ffprobe", ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", CUES + f], { encoding: "utf8" }).trim();

// ---- parse the screenplay into ordered beats -------------------------------
const SCENES = [
  "० उड़ान-आँगन", "०-अ मीनार", "१ भागती गाड़ी", "२ निशान",
  "३ ग बनना", "४ आख़िरी मोड़", "५ रुकना", "६ बाद में", "७ दादी", "८ मीनार",
];
const beats = [];
let scene = SCENES[0], sceneIdx = 0, dlg = 0;
for (const raw of fs.readFileSync(SCRIPT, "utf8").split("\n")) {
  const line = raw.trim();
  if (/^## दृश्य/.test(line)) { sceneIdx = Math.min(sceneIdx + (beats.length ? 1 : 0), SCENES.length - 1); scene = SCENES[sceneIdx]; continue; }
  if (!line || line.startsWith("#") || line.startsWith("**") || line.startsWith("|") || line.startsWith("-")) continue;
  if (line.startsWith("(")) {
    const sound = /^\(ध्वनि/.test(line);
    const stated = line.match(/लगभग (\d+) सेकंड/);
    // an action beat is held long enough to read; a sound cue may state its own length
    const d = stated ? +stated[1] : Math.min(3.0, Math.max(1.7, line.length / 46));
    beats.push({ kind: sound ? "sound" : "action", text: line.replace(/^\(|\)$/g, ""), scene, d });
    continue;
  }
  const m = line.match(/^([^:(]{1,12}):\s*(?:\(([^)]*)\)\s*)?(.+)$/);
  if (m && dlg < cueFiles.length) {
    beats.push({ kind: "dialogue", who: m[1].trim(), text: m[3].trim(), scene, cue: dlg });
    dlg++;
  }
}

// ---- frame selection -------------------------------------------------------
const pool = names => names.flatMap(n => {
  const hero = S + n + ".png";
  const der = fs.existsSync(I) ? fs.readdirSync(I).filter(f => f.startsWith(n + "__") && !f.startsWith("PRE_")).sort().map(f => I + f) : [];
  return fs.existsSync(hero) ? [hero, ...der] : der;
});

// what an ACTION or SOUND beat is about — first match wins, and a frame that has
// not been on screen yet is preferred so the story's own images get used
const ABOUT = [
  // ORDER IS BY SPECIFICITY, NOT BY STORY ORDER. A ten-second sound cue names
  // several things at once, so the beat's RESOLUTION must be tested before its
  // texture — otherwise a generic "टनन" steals the shot of the cart stopping.
  // --- story resolutions: the images the episode exists for ---
  [/मोड़ की गोद|पूरी तरह रुक|राहत की लंबी साँस/, ["h38_stopped"]],
  [/खुले मोड़ में घुसता|मोड़ की ढाल|घिसटने का सुर/, ["h37_cart_into_curve"]],
  [/पाँच सुनहरी लहर|छोटे पंजे पत्थर पर|बड़े पंखों की आवाज़ समाप्त/, ["h39_shrink_glow"]],
  [/पाँच कड़ों/, ["h30_bracelets"]],
  [/ठोस .ग.|सुनहरा .ग.|ग खड़ा|मुड़ा हुआ/, ["h29_ga_stands"]],
  [/डोर की दो-सुरी|फाटक खुलता|दादी का आँगन|कालू/, ["h42_doorway_dadi"]],
  // --- specific actions ---
  [/पाँचों विशाल बच्चे/, ["h17_group_lift"]],
  [/गौरी गाड़ी से उतरती|खुर लकड़ी से पत्थर/, ["h40_small_five_sit"]],
  [/कैस्टर.*घास|सूखी घास पर/, ["h41_castor_in_hay"]],
  [/गौरी.*(डरकर|डरी हुई)|खुर.*(फिसल|गलत ओर)/, ["h18_cow_slips"]],
  [/चील.*घंटी|घंटी.*ले|बंधन काट|चोरी की घंटी/, ["h13_bell_taken"]],
  [/रस्सी|गाँठ|खुल गई/, ["h12_rope_slip", "h07_cart_tethered"]],
  [/पंख-थाप/, ["h36_three_beats", "h20_furia_brake"]],
  [/हवा बाईं ओर|किनारे की ओर|बीच में आती/, ["h32_cart_drifts", "h19_wheels_return"]],
  [/भारी खुर लौटता|गाड़ी की लकड़ी शांत/, ["h19_wheels_return"]],
  [/साथ-साथ उड़|पाँचों.*उड़/, ["h16_five_flank"]],
  [/उलटे घेरे|घेरे के भीतर|उड़ान भर/, ["h04_launch", "h01_ring_wide"]],
  [/ऊपर से|सिर के ऊपर|चक्कर/, ["h33_cheel_flyover", "h21_vesper_above"]],
  [/गाड़ी.*दौड़|ढलान पर|तेज़ी से/, ["h15_cart_runs"]],
  [/घास खा|चर रही|चरागाह/, ["h51_gauri_grazing", "h52_gauri_hay_cart"]],
  [/मीनार|छत|परकोटे/, ["h10_cheel_tower", "h44_tower_door"]],
  [/टुकड़े|काले|किरच/, ["h11_shards_close"]],
  // --- generic texture, tested last ---
  [/टन|ठक|गूँज|आवाज़ लौट/, ["h26_tings"]],
  [/लाल पत्थर|निशान|पटरी|सपाट/, ["h23_marker_pass", "h35_last_marker"]],
  [/घंटी/, ["h05_bell_touch"]],
  [/गौरी/, ["h08_gauri_close"]],
  [/खड़े|आँगन|गुरुकुल/, ["h01_ring_wide", "h02_rishi_teach"]],
];
const SUBJECT = {
  "कुकु": ["h24_kuku_breath_fail", "h27_kuku_hears", "h28_forging"],
  "फ्यूरिया": ["h03_furia_mark", "h04_launch", "h06_landing_paw", "h14_furia_choice", "h20_furia_brake", "h34_furia_refuses", "h36_three_beats"],
  "लेडा": ["h25_leda_knock", "h45_leda_watch_ring", "h46_leda_calls_lane", "h47_leda_warns", "h48_leda_counts", "h49_leda_relief", "h50_leda_small_sits"],
  "कैस्टर": ["h22_castor_calm", "h41_castor_in_hay"],
  "वैस्पर": ["h21_vesper_above", "h31_vesper_yawn", "h43_vesper_asleep"],
  "ऋषि": ["h02_rishi_teach", "h09_rishi_boon"],
  "चील": ["h10_cheel_tower", "h13_bell_taken", "h33_cheel_flyover", "h44_tower_door"],
  "दादी": ["h42_doorway_dadi"],
};
const OVERRIDE = [
  [/गौरी|गाय/, ["h51_gauri_grazing", "h52_gauri_hay_cart", "h08_gauri_close", "h07_cart_tethered", "h18_cow_slips"]],
  [/घंटी/, ["h05_bell_touch", "h13_bell_taken", "h33_cheel_flyover", "h44_tower_door"]],
  [/रस्सी/, ["h12_rope_slip", "h07_cart_tethered"]],
  [/निशान|पटरी|सपाट/, ["h23_marker_pass", "h35_last_marker", "h32_cart_drifts"]],
  [/गाड़ी/, ["h15_cart_runs", "h37_cart_into_curve", "h38_stopped", "h19_wheels_return"]],
];
// v8: every finished motion clip slotted at the beat whose sound it performs.
// The clip plays at its own length; tpad clones the last frame out to the cue,
// so a 5s clip under a 10s cue holds its final composition rather than cutting.
const C = P + "clips/";
const CUE_MEDIA = {
  S011: { img: S + "s011_castor_calm_solo.png" },
  /* She is still in the air on this line — «हो गया! अब मैं लौट रही हूँ!» — so it
     takes a flight frame. Left free, selection reached for the landing scuff,
     which is A05's payoff and gives the beat away before लेडा has counted. */
  S014: { img: S + "h04_launch.png" },
  /* ONE flight, not laps. The screenplay's "three" is three braking WINGBEATS
     («तीन बार धीरे पंख चलाकर अपने निशान पर रुकना»), and लेडा's count plus कैस्टर's
     joke only work if she arrives fast. Stitching a loop clip in front of the
     drill gave her two unhurried circuits, which made the overshoot read as
     incompetence instead of eagerness. s0a stays on disk, out of the cut. */
  A04: { video: C + "SCENE1_s0d_bell_touch.mp4",      // launch, through the ring, bell struck, home
         then: [I + "h05_bell_touch__a_swinging.png", S + "h05_bell_touch.png"] },
  A08: { video: C + "S0B_rope_slips.mp4" },           // the knot slips, the rope falls
  A09: { video: C + "SCENE1_s0c_bell_taken.mp4" },    // the theft, on the ring
  A12: { video: C + "SCENE1_c1_breaks_away.mp4" },    // the cart breaks away, 10s
  A13: { video: C + "SCENE1_c2_five_flank.mp4" },     // five wings take formation
  A14: { video: C + "SCENE1_c4_wheels_return.mp4" },  // wheels slam back to the track
  A16: { video: C + "SCENE1_s2a_furia_brakes.mp4" },  // her controlled braking beats
  A17: { video: C + "SCENE1_s2b_marker_passes.mp4" }, // the marker slides under the wheels
  A19: { video: C + "SCENE1_b1_breath_fail.mp4" },    // the letterless breath scatters
  A28: { video: C + "SCENE1_b2_forging.mp4" },        // the forging
  A42: { video: C + "SCENE1_b3_three_beats.mp4" },    // first slow wingbeat
  A46: { video: C + "SCENE1_b4_curve_stop.mp4" },     // third beat: into the curve, and rest
  A49: { video: C + "SCENE1_b5_shrink.mp4" },         // five columns settle into five children
  A59: { video: C + "SCENE1_b6_tower_door.mp4" },     // चील raises the bell at the door
};

const shown = new Map();
const seen = new Set();
const pickFrom = (cands, key, enforceRun, scene) => {
  // If nothing this speaker owns belongs to the scene, return nothing and let the
  // caller fall through to the scene's own frames. Silently keeping the
  // out-of-scene candidates is what let कैस्टर's after-the-stop shot appear in
  // the middle of the runaway.
  if (scene) { const sc = cands.filter(c => inScene(c, scene)); if (!sc.length) return null; cands = sc; }
  if (!cands.length) return null;
  if (enforceRun) {
    // never go back up the lane; if nothing lies ahead, hold at the furthest point
    const forward = cands.filter(c => { const p = posOf(c); return p === null || p >= lastPos; });
    if (forward.length) cands = forward;
    else { const best = Math.max(...cands.map(c => posOf(c) ?? -1)); cands = cands.filter(c => (posOf(c) ?? -1) === best); }
  }
  const fresh = cands.filter(c => !seen.has(c));
  const list = fresh.length ? fresh : cands;
  const n = shown.get(key) || 0; shown.set(key, n + 1);
  // inside the run, always take the EARLIEST candidate still ahead of us, so
  // the cart advances in small steps instead of leaping to the finish
  const ordered = enforceRun
    ? [...list].sort((a, b) => (posOf(a) ?? 1e9) - (posOf(b) ?? 1e9))
    : list;
  const chosen = ordered[n % ordered.length];
  seen.add(chosen);
  const cp = posOf(chosen);
  if (enforceRun && cp !== null) lastPos = Math.max(lastPos, cp);
  return chosen;
};

// ---- assign a picture to every beat ----------------------------------------
let sNo = 0, aNo = 0;
for (const b of beats) {
  if (b.kind === "dialogue") {
    b.id = "S" + String(++sNo).padStart(3, "0");
    const ov = OVERRIDE.find(([re]) => re.test(b.text));
    const subj = ov ? pool(ov[1]) : [];
    const mine = pool(SUBJECT[b.who] || []);
    const run = RUN_SCENES.has(b.scene);
    b.img = (subj.length && !seen.has(subj[0]) ? pickFrom(subj, "ov" + b.scene + b.who, run, b.scene) : null)
      || pickFrom(mine, "sp" + b.scene + b.who, run, b.scene) || pickFrom(subj, "ov2" + b.scene, run, b.scene)
      || pickFrom(sceneFrames(b.scene), "scene" + b.scene, run, b.scene) || S + "h01_ring_wide.png";
    b.d = dur(cueFiles[b.cue]) + GAP;
  } else {
    b.id = "A" + String(++aNo).padStart(2, "0");
    const hit = ABOUT.find(([re]) => re.test(b.text));
    const cands = pool(hit ? hit[1] : []);
    // a long sound cue describes a sequence, not a tableau: hold roughly 3.5s a
    // frame and walk the matched pool, so its variants carry the action instead
    // of one still sitting on screen for ten seconds
    const n = Math.max(1, Math.min(cands.length, Math.round(b.d / 3.5)));
    b.imgs = [];
    for (let k = 0; k < n; k++) {
      const f = pickFrom(cands.filter(c => !b.imgs.includes(c)), "ab" + b.id + k, RUN_SCENES.has(b.scene), b.scene);
      if (f) b.imgs.push(f);
    }
    if (!b.imgs.length) b.imgs = [pickFrom(sceneFrames(b.scene), "afall" + b.scene, false, b.scene) || pickFrom(pool(["h01_ring_wide"]), "fallback")];
    b.img = b.imgs[0];
  }
}

// ---- HARD MONOTONIC PASS ------------------------------------------------
// Selection has several paths (speaker frames, text overrides, action keywords,
// fallbacks) and a constraint threaded through all of them kept being routed
// around. So the run is enforced HERE, over the finished assignment, where
// nothing can bypass it: walk the beats in order and never let the cart's clock
// go backwards. A beat with nothing ahead of it holds the previous picture,
// which reads as staying with the shot rather than teleporting up the lane.
{
  let run = 0, fixed = 0, held = 0;
  let prevImg = null;
  for (const b of beats) {
    if (!RUN_SCENES.has(b.scene)) { prevImg = b.img; continue; }
    if (true) { prevImg = b.img; continue; } // within-scene order is free
    const list = b.imgs && b.imgs.length ? b.imgs : [b.img];
    const out = [];
    for (const f of list) {
      const p = posOf(f);
      if (p === null || p >= run) { if (p !== null) run = p; out.push(f); continue; }
      // this picture is behind the cart: find the nearest frame at or ahead of
      // the clock among everything this beat could legitimately show
      const alt = (b.kind === "dialogue" ? pool(SUBJECT[b.who] || []) : [])
        .concat(list)
        .filter(c => inScene(c, b.scene))
        .filter(c => { const q = posOf(c); return q !== null && q >= run; })
        .sort((x, y) => posOf(x) - posOf(y))[0];
      if (alt) { run = posOf(alt); out.push(alt); fixed++; }
      else if (prevImg) { out.push(prevImg); held++; }
      else out.push(f);
    }
    if (b.imgs && b.imgs.length) { b.imgs = out; b.img = out[0]; } else b.img = out[0];
    prevImg = b.img;
  }
  console.log(`monotonic pass: ${fixed} pulled forward, ${held} held`);
  // assert the boundary invariant the scene ranges are supposed to give us
  const ranges = {};
  for (const b of beats) {
    if (!RUN_SCENES.has(b.scene)) continue;
    for (const f of (b.imgs && b.imgs.length ? b.imgs : [b.img])) {
      const p = posOf(f); if (p === null) continue;
      const r = ranges[b.scene] || (ranges[b.scene] = [p, p]);
      r[0] = Math.min(r[0], p); r[1] = Math.max(r[1], p);
    }
  }
  const order = ["१ भागती गाड़ी", "२ निशान", "३ ग बनना", "४ आख़िरी मोड़", "५ रुकना"].filter(k => ranges[k]);
  let prevMax = -1, bad = 0;
  for (const k of order) { if (ranges[k][0] < prevMax) bad++; prevMax = Math.max(prevMax, ranges[k][1]); }
  console.log(`scene clock ranges: ${order.map(k => `${k}=${ranges[k][0]}-${ranges[k][1]}`).join("  ")}`);
  console.log(bad ? `WARNING: ${bad} scene(s) overlap the previous scene's clock` : "scene boundaries are one-way");
}

// ---- coverage report --------------------------------------------------------
const have = [...fs.readdirSync(S), ...fs.readdirSync(I)].filter(f => f.endsWith(".png") && !f.startsWith("PRE_") && !f.startsWith("gpt_"));
const used = new Set(beats.flatMap(b => (b.imgs || [b.img]).filter(Boolean).map(x => x.split("/").pop())));
console.log(`beats: ${beats.length} (${sNo} dialogue, ${aNo} action/sound)`);
console.log(`frames used: ${used.size} of ${have.length} on disk — never used: ${have.filter(f => !used.has(f)).length}`);
if (DRY) {
  const cnt={}; beats.forEach(b=>cnt[b.scene]=(cnt[b.scene]||0)+1);
  console.log("\nbeats per scene:"); Object.entries(cnt).forEach(([k,v])=>console.log(`   ${k}: ${v}`));
  console.log("\naction/sound beats:");
  beats.filter(b => b.kind !== "dialogue").forEach(b =>
    console.log(`   ${b.id} ${(b.img||"NONE").split("/").pop().padEnd(34)} ${b.text.slice(0,46)}`));
  console.log("\nnever used:"); have.filter(f => !used.has(f)).forEach(f => console.log("   " + f));
  process.exit(0);
}

// ---- render -----------------------------------------------------------------
const segs = [], alist = [], rows = [];
let t = 0;
beats.forEach((b, i) => {
  const chip = NUM + b.id + ".png";
  const label = b.kind === "dialogue" ? b.who : (b.kind === "sound" ? "ध्वनि" : "क्रिया");
  if (!fs.existsSync(chip)) {
    fs.writeFileSync("/tmp/n10f.typ", `#set page(width: 460pt, height: 84pt, margin: 0pt, fill: none)
#set text(font: ("Helvetica", "Devanagari Sangam MN"))
#place(left + horizon, box(fill: rgb(0,0,0,205), inset: 12pt, radius: 6pt)[
  #text(fill: white, size: 34pt, weight: "bold", "${b.id}")
  #h(10pt)
  #text(fill: rgb(255,214,120), size: 26pt, "${label}")
])`);
    execFileSync("typst", ["compile", "/tmp/n10f.typ", chip, "--format", "png"], { timeout: 60000 });
  }
  const ov = CUE_MEDIA[b.id];
  const img = ov && ov.img ? ov.img : b.img;
  b.parts = (b.imgs && b.imgs.length > 1 && !ov) ? b.imgs : null;
  const clip = ov && ov.video ? ov.video : null;
  /* A clip shorter than its cue used to hold its final frame for the remainder,
     which stranded फ्यूरिया landed on her mark while she was still calling that
     she was on her way back. `then` gives the rest of the cue its own stills. */
  const tail = ov && ov.then && clip ? ov.then : null;
  const clipDur = clip ? +execFileSync("ffprobe", ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", clip], { encoding: "utf8" }).trim() : 0;
  const segDur = Math.max(b.d, clipDur);
  if (b.parts) {
    // split the beat into equal sub-shots, each its own segment
    const each = b.d / b.parts.length;
    b.parts.forEach((pf, k) => {
      const po = B + "b" + String(i).padStart(3, "0") + "_" + k + ".mp4";
      if (!fs.existsSync(po)) {
        execFileSync("ffmpeg", ["-v", "error", "-y", "-loop", "1", "-i", pf, "-i", chip, "-t", each.toFixed(3),
          "-filter_complex", `[0:v]scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2,fps=${FPS}[bg];[bg][1:v]overlay=36:H-h-36,format=yuv420p[v]`,
          "-map", "[v]", "-c:v", "libx264", "-crf", "20", "-preset", "veryfast", "-an", po], { timeout: 300000 });
      }
      segs.push(po);
      rows.push(`| ${b.id}${String.fromCharCode(97 + k)} | ${(t + k * each).toFixed(1)}s | ${label} | ${b.scene} | ${pf.split("/").pop()} |`);
    });
    t += b.d;
    return;
  }
  if (tail && b.d > clipDur + 0.4) {
    const co = B + "b" + String(i).padStart(3, "0") + "_v.mp4";
    if (!fs.existsSync(co)) {
      execFileSync("ffmpeg", ["-v", "error", "-y", "-i", clip, "-i", chip,
        "-filter_complex", `[0:v]scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2,fps=${FPS}[bg];[bg][1:v]overlay=36:H-h-36,format=yuv420p[v]`,
        "-t", clipDur.toFixed(3), "-map", "[v]", "-c:v", "libx264", "-crf", "20", "-preset", "veryfast", "-an", co], { timeout: 300000 });
    }
    segs.push(co);
    rows.push(`| ${b.id} | ${t.toFixed(1)}s | ${label} | ${b.scene} | ${clip.split("/").pop()} |`);
    const each = (b.d - clipDur) / tail.length;
    tail.forEach((tf, k) => {
      const to = B + "b" + String(i).padStart(3, "0") + "_t" + k + ".mp4";
      if (!fs.existsSync(to)) {
        execFileSync("ffmpeg", ["-v", "error", "-y", "-loop", "1", "-i", tf, "-i", chip, "-t", each.toFixed(3),
          "-filter_complex", `[0:v]scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2,fps=${FPS}[bg];[bg][1:v]overlay=36:H-h-36,format=yuv420p[v]`,
          "-map", "[v]", "-c:v", "libx264", "-crf", "20", "-preset", "veryfast", "-an", to], { timeout: 300000 });
      }
      segs.push(to);
      rows.push(`| ${b.id}${String.fromCharCode(98 + k)} | ${(t + clipDur + k * each).toFixed(1)}s | ${label} | ${b.scene} | ${tf.split("/").pop()} |`);
    });
    if (b.kind === "dialogue") alist.push({ f: cueFiles[b.cue], at: t });
    t += b.d;
    return;
  }
  const out = B + "b" + String(i).padStart(3, "0") + ".mp4";
  if (!fs.existsSync(out)) {
    const common = ["-t", segDur.toFixed(3), "-map", "[v]", "-c:v", "libx264", "-crf", "20", "-preset", "veryfast", "-an", out];
    if (clip) {
      execFileSync("ffmpeg", ["-v", "error", "-y", "-i", clip, "-i", chip,
        "-filter_complex", `[0:v]scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2,fps=${FPS},tpad=stop_mode=clone:stop_duration=30[bg];[bg][1:v]overlay=36:H-h-36,format=yuv420p[v]`, ...common], { timeout: 300000 });
    } else {
      execFileSync("ffmpeg", ["-v", "error", "-y", "-loop", "1", "-i", img, "-i", chip,
        "-filter_complex", `[0:v]scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2,fps=${FPS}[bg];[bg][1:v]overlay=36:H-h-36,format=yuv420p[v]`, ...common], { timeout: 300000 });
    }
  }
  segs.push(out);
  if (b.kind === "dialogue") alist.push({ f: cueFiles[b.cue], at: t });
  rows.push(`| ${b.id} | ${t.toFixed(1)}s | ${label} | ${b.scene} | ${(clip || img).split("/").pop()} |`);
  t += segDur;
});

fs.writeFileSync(B + "cat.txt", segs.map(s => `file '${s}'`).join("\n") + "\n");
execFileSync("ffmpeg", ["-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", B + "cat.txt", "-c", "copy", B + "picture.mp4"], { timeout: 1800000 });

const inputs = [], filters = [];
alist.forEach((a, i) => { inputs.push("-i", CUES + a.f); filters.push(`[${i}:a]adelay=${Math.round(a.at * 1000)}|${Math.round(a.at * 1000)}[a${i}]`); });
const fc = filters.join(";") + ";" + alist.map((_, i) => `[a${i}]`).join("") + `amix=inputs=${alist.length}:normalize=0[aout]`;
execFileSync("ffmpeg", ["-v", "error", "-y", ...inputs, "-filter_complex", fc, "-map", "[aout]",
  "-c:a", "aac", "-b:a", "192k", "-ar", "44100", "-ac", "2", B + "dialogue.m4a"], { timeout: 1800000 });

execFileSync("ffmpeg", ["-v", "error", "-y", "-i", B + "picture.mp4", "-i", B + "dialogue.m4a",
  "-map", "0:v", "-map", "1:a", "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
  /* NO -shortest: the dialogue track ends with the last spoken cue, but the
     episode does not — the closing action beats (चील raising the bell at the
     tower door) play silent after it. -shortest truncated the picture to the
     audio and cut the cliffhanger off the end of the cut. */
  "-movflags", "+faststart", P + "EP10_V9_REVIEW_NUMBERED.mp4"], { timeout: 1800000 });

fs.writeFileSync(P + "EP10_V9_SHOTLIST.md",
  "# EP10 V9 — full cut shot list (S### dialogue, A## action/sound)\n\n| # | at | who | scene | frame |\n|---|----|-----|-------|-------|\n" + rows.join("\n") + "\n");
console.log(`EP10_V9_REVIEW_NUMBERED.mp4 — ${beats.length} beats, ${t.toFixed(1)}s`);
