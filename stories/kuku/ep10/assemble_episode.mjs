// assemble_episode.mjs — the whole of «द से दीया».
//
// THE EDIT RULE: an action beat plays as its motion clip; a spoken line cuts to a
// close single on whoever is speaking. The wide group frames open a shot and then
// give way to coverage, which is how a dialogue scene is actually cut — and is
// what makes the lip-sync pass possible, since a group frame gives a face-tracker
// six faces and no idea which one is talking.
//
//   node assemble_episode.mjs [out.mp4]
import { execFileSync } from "child_process";
import fs from "fs";

const P = new URL("./", import.meta.url).pathname;
const B = P + "build_ep/"; fs.rmSync(B, { recursive: true, force: true }); fs.mkdirSync(B, { recursive: true });
const W = 1280, H = 720, FPS = 24;
const HEAD = 0.22, TAIL = 0.5, GAP = 0.26, ESTAB = 1.5;
const out = process.argv[2] || "EP10_FULL.mp4";

const dur = f => Number(execFileSync("ffprobe", ["-v","error","-show_entries","format=duration",
  "-of","csv=p=0", f], { encoding: "utf8" }).trim());

const cues = JSON.parse(fs.readFileSync(P + "cue_index.json", "utf8"));
const cueDir = P + "table_read/cues/";
// A take is found by its own index+speaker prefix — NEVER by sorted position.
// Position lookup silently played 43 of 79 lines under the wrong frame after a
// scene was inserted mid-script and stale-numbered takes sat beside the new ones.
const takeFor = (i, c) => {
  const pre = String(i + 1).padStart(3, "0") + "_" + c.who + "_";
  const legacy = String(i + 1).padStart(3, "0") + "_" + c.who + ".mp3";
  const f = fs.readdirSync(cueDir).find(x => (x.startsWith(pre) || x === legacy) && x.endsWith(".mp3"));
  if (!f) throw new Error("no take for line " + (i + 1) + " (" + c.who + ")");
  return cueDir + f;
};
const cuDir = P + "closeups/";
const cuFiles = fs.readdirSync(cuDir).filter(f => f.endsWith(".png")).sort();

const DEV = "०१२३४५६७८९";
// A shot label may carry a Devanagari suffix — शॉट ३३-अ — because the कड़ा scene
// was inserted without renumbering the episode. The key is number PLUS suffix, so
// six shots that all live at 33 keep their own lines instead of pooling them.
const SUF = { "अ":"a", "ब":"b", "स":"c", "द":"d", "य":"e", "र":"f" };
const n0 = s => Number([...s.replace("शॉट ","").split("-")[0]].map(c => DEV.indexOf(c)).join(""));
const keyOf = label => {
  const body = label.replace("शॉट ", "");
  const [digits, suf] = body.split("-");
  const n = Number([...digits].map(c => DEV.indexOf(c)).join(""));
  return String(n) + (suf ? (SUF[suf] || suf) : "");
};
// a manifest id like s33b_transform -> key "33b"; s07_kuku -> key "7"
const keyOfId = id => {
  const m = id.match(/^s(\d\d)([a-f])?_/);
  return m ? String(Number(m[1])) + (m[2] || "") : id;
};

// A close single is matched to a line by ORDINAL first; if the ordinals have
// shifted (inserting a scene renumbers everything after it) it falls back to any
// unused frame of the same character in the same light. These frames are generic
// mid-speech singles, so a लेडा-in-the-dark frame serves any लेडा line in the
// dark — which turns a renumbering into a remap instead of 74 credits of reshoots.
const catalog = JSON.parse(fs.readFileSync(P + "closeup_index.json", "utf8"));
const spent = new Set();
const ROLE = { "दादी":"DADI","कुकु":"KUKU","फ्यूरिया":"FYURIA","वैस्पर":"VESPER",
               "लेडा":"LEDA","कैस्टर":"CASTOR","पापा":"PAPA","सब":"KUKU" };
const lightOfShot = n =>
  n <= 13 ? "Dusk" : n <= 25 ? "LampNight" : n <= 50 ? "Dark" : n <= 63 ? "Golden" : "NextDusk";

const cuFor = (i, cue) => {
  const want = "cu" + String(i + 1).padStart(3, "0") + "_";
  const exact = cuFiles.find(x => x.startsWith(want) && x.includes(ROLE[cue.who] || ""));
  if (exact) { spent.add(P + "closeups/" + exact); return cuDir + exact; }
  const role = ROLE[cue.who], light = lightOfShot(n0(cue.shot));
  const pool = catalog.filter(c => c.role === role && c.light === light);
  const fresh = pool.find(c => !spent.has(P + c.file)) || pool[0];
  if (fresh) { spent.add(P + fresh.file); return P + fresh.file; }
  const anyRole = catalog.find(c => c.role === role);
  return anyRole ? P + anyRole.file : null;
};

const byShot = new Map();
cues.forEach((c, i) => {
  const k = keyOf(c.shot);
  if (!byShot.has(k)) byShot.set(k, []);
  byShot.get(k).push({ ...c, audio: takeFor(i, c), cu: cuFor(i, c) });
});

const manifest = execFileSync("node", ["src/KukuEp12_Shots.res.mjs", "list"],
  { cwd: "/Users/dusty/Dev/metaphrand/studio", encoding: "utf8" })
  .trim().split("\n").filter(l => / (motion|still) /.test(l))
  .map(l => { const p = l.trim().split(/\s+/); return { id: p[0], kind: p[1], secs: Number(p[2].replace("s","")) }; });

const seg = (src, len, i, tag) => {
  const o = B + String(i).padStart(3,"0") + "_" + tag + ".mp4";
  const common = ["-t", len.toFixed(3), "-r", String(FPS), "-map", "[v]", "-c:v","libx264",
                  "-profile:v","main","-crf","21","-preset","veryfast","-pix_fmt","yuv420p","-an", o];
  const fit = `scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2,fps=${FPS}`;
  if (/\.mp4$/.test(src)) {
    execFileSync("ffmpeg", ["-v","error","-y","-i",src,"-filter_complex",
      `[0:v]${fit},tpad=stop_mode=clone:stop_duration=30[v]`, ...common], { timeout: 900000 });
  } else {
    execFileSync("ffmpeg", ["-v","error","-y","-loop","1","-i",src,"-filter_complex",
      `[0:v]${fit}[v]`, ...common], { timeout: 900000 });
  }
  return o;
};

const segs = [], audio = [];
let t = 0, k = 0, nCu = 0, nClip = 0, nWide = 0;

for (const sh of manifest) {
  const lines = byShot.get(keyOfId(sh.id)) || [];
  const clip = P + "clips/EP10_" + sh.id + ".mp4";
  const wideF = P + "stills_final/" + sh.id + ".png";
  const wide = fs.existsSync(wideF) ? wideF : P + "stills/" + sh.id + ".png";

  if (lines.length === 0) {
    if (!fs.existsSync(clip)) continue;
    const L = dur(clip);
    segs.push(seg(clip, L, k++, sh.id)); t += L; nClip++;
    continue;
  }

  // a motion shot that also speaks: the clip carries its own action first
  if (fs.existsSync(clip)) {
    const L = dur(clip);
    segs.push(seg(clip, L, k++, sh.id)); nClip++;
    let at = t + HEAD;
    for (const l of lines) { audio.push({ f: l.audio, at }); at += dur(l.audio) + GAP; }
    t += Math.max(L, HEAD + lines.reduce((s,l)=>s+dur(l.audio)+GAP,0) + TAIL - GAP);
    continue;
  }

  // a dialogue shot: a brief wide to establish, then a close single per line
  if (fs.existsSync(wide)) { segs.push(seg(wide, ESTAB, k++, sh.id + "_est")); t += ESTAB; nWide++; }
  for (const l of lines) {
    const d = dur(l.audio);
    const len = HEAD + d + TAIL;
    const src = l.cu && fs.existsSync(l.cu) ? l.cu : wide;
    if (l.cu && fs.existsSync(l.cu)) nCu++; 
    segs.push(seg(src, len, k++, sh.id + "_" + l.who));
    audio.push({ f: l.audio, at: t + HEAD });
    t += len;
  }
}

fs.writeFileSync(B + "cat.txt", segs.map(s => `file '${s}'`).join("\n") + "\n");
execFileSync("ffmpeg", ["-v","error","-y","-f","concat","-safe","0","-i", B+"cat.txt","-c","copy", B+"picture.mp4"], { timeout: 1800000 });

const ins = [], filt = [];
audio.forEach((x,i) => { ins.push("-i", x.f); filt.push(`[${i}:a]adelay=${Math.round(x.at*1000)}|${Math.round(x.at*1000)}[a${i}]`); });
execFileSync("ffmpeg", ["-v","error","-y", ...ins, "-filter_complex",
  filt.join(";") + ";" + audio.map((_,i)=>`[a${i}]`).join("") + `amix=inputs=${audio.length}:normalize=0[o]`,
  "-map","[o]","-c:a","aac","-b:a","160k","-ar","44100","-ac","2", B+"dialogue.m4a"], { timeout: 1800000 });

execFileSync("ffmpeg", ["-v","error","-y","-i",B+"picture.mp4","-i",B+"dialogue.m4a",
  "-map","0:v","-map","1:a","-c:v","copy","-c:a","aac","-b:a","160k","-movflags","+faststart", P+out], { timeout: 1800000 });

console.log(`${out} — ${t.toFixed(0)}s | ${nClip} motion, ${nCu} close singles, ${nWide} establishers, ${audio.length} lines`);
