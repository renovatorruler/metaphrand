// lipsync_pass.mjs — animate the mouths on EP10's dialogue close-ups.
//
// A close single is held as a still for the length of its line, then fal's
// Sync Lipsync 2.0 moves the mouth to the author's own recorded take. The frame
// is otherwise untouched: this animates a picture already approved rather than
// generating a new one, which is why it cannot drift the way a fresh generation can.
//
// Files are staged through fal's own storage (the old tailnet shelf is down and
// fal rejects data-URI inputs), so no public host is required.
//
//   node lipsync_pass.mjs <maxSeconds>     # covers lines until that much runtime
//   DRY=1 node lipsync_pass.mjs 62         # plan and price only, no spend
import { execFileSync } from "child_process";
import fs from "fs";

const P = new URL("./", import.meta.url).pathname;
const OUT = P + "lipsync/"; fs.mkdirSync(OUT, { recursive: true });
const KEY = fs.readFileSync("/Users/dusty/Dev/metaphrand/.env", "utf8")
  .split("\n").find(l => l.startsWith("FAL_AI=")).split("=").slice(1).join("=").trim().replace(/^["']|["']$/g, "");
const RATE = 0.14;                 // OmniHuman: $0.14 per second of synced video
const LIMIT = Number(process.argv[2] || 62);
const DRY = process.env.DRY === "1";

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
const catalog = JSON.parse(fs.readFileSync(P + "closeup_index.json", "utf8"));
const ROLE = { "दादी":"DADI","कुकु":"KUKU","फ्यूरिया":"FYURIA","वैस्पर":"VESPER",
               "लेडा":"LEDA","कैस्टर":"CASTOR","पापा":"PAPA","सब":"KUKU" };
const DEV = "०१२३४५६७८९";
const shotNum = s => Number([...s.replace("शॉट ","").split("-")[0]].map(c => DEV.indexOf(c)).join(""));
const lightOf = n => n<=13?"Dusk":n<=25?"LampNight":n<=50?"Dark":n<=63?"Golden":"NextDusk";

const cuFiles = fs.readdirSync(P + "closeups").filter(f => f.endsWith(".png")).sort();
const spent = new Set();
const frameFor = (i, c) => {
  const want = "cu" + String(i+1).padStart(3,"0") + "_";
  const exact = cuFiles.find(x => x.startsWith(want) && x.includes(ROLE[c.who] || ""));
  if (exact) { spent.add(exact); return P + "closeups/" + exact; }
  const pool = catalog.filter(x => x.role === ROLE[c.who] && x.light === lightOf(shotNum(c.shot)));
  const pick = pool.find(x => !spent.has(x.file.split("/").pop())) || pool[0];
  return pick ? P + pick.file : null;
};

const api = async (path, opts = {}) => {
  const r = await fetch(path, { ...opts, headers: { Authorization: "Key " + KEY, "Content-Type": "application/json", ...(opts.headers||{}) } });
  return { status: r.status, body: await r.text() };
};

const upload = async (file, contentType) => {
  const init = await api(`https://rest.alpha.fal.ai/storage/upload/initiate?storage_type=fal-cdn-v3`,
    { method: "POST", body: JSON.stringify({ content_type: contentType, file_name: file.split("/").pop() }) });
  const { upload_url, file_url } = JSON.parse(init.body);
  const put = await fetch(upload_url, { method: "PUT", headers: { "Content-Type": contentType }, body: fs.readFileSync(file) });
  if (!put.ok) throw new Error("upload failed " + put.status);
  return file_url;
};

// plan: the lines that fall inside the requested runtime
const plan = [];
let t = 0;
for (let i = 0; i < cues.length; i++) {
  const c = cues[i];
  const audio = takeFor(i, c);
  if (!fs.existsSync(audio)) continue;
  const d = dur(audio);
  if (t > LIMIT) break;
  const frame = frameFor(i, c);
  if (frame) plan.push({ i, who: c.who, text: c.text, audio, frame, d, at: t });
  t += d + 0.28;
}
const secs = plan.reduce((s,x)=>s+x.d+0.77, 0);
console.log(`${plan.length} lines, ${secs.toFixed(0)}s of footage — $${(secs*RATE).toFixed(2)}`);
if (DRY) { plan.forEach(p => console.log(`  ${String(p.i+1).padStart(3,"0")} ${p.who.padEnd(9)} ${p.d.toFixed(1)}s  ${p.text.slice(0,40)}`)); process.exit(0); }

const run = async () => {
  let done = 0;
  for (const p of plan) {
    const tag = String(p.i+1).padStart(3,"0") + "_" + ROLE[p.who];
    const outF = OUT + tag + ".mp4";
    if (fs.existsSync(outF)) { console.log("skip " + tag); done++; continue; }
    // OmniHuman takes a STILL plus audio, not a video — it animates the face
    // directly, which is why it works where a video-dubbing model passes through.
    const held = OUT + tag + "_src.jpg";
    const len = 0.22 + p.d + 0.55;
    execFileSync("ffmpeg", ["-v","error","-y","-i", p.frame,
      "-vf","scale=1024:576:force_original_aspect_ratio=decrease,pad=1024:576:(ow-iw)/2:(oh-ih)/2",
      "-q:v","2", held], { timeout: 300000 });
    // the take, padded to match so the mouth starts where the voice does
    const wav = OUT + tag + ".wav";
    execFileSync("ffmpeg", ["-v","error","-y","-i", p.audio,
      "-af", `adelay=220|220,apad=whole_dur=${len.toFixed(2)}`, "-ar","44100","-ac","1", wav], { timeout: 300000 });

    const vUrl = await upload(held, "image/jpeg");
    const aUrl = await upload(wav, "audio/wav");
    const sub = await api("https://queue.fal.run/fal-ai/bytedance/omnihuman", { method: "POST",
      body: JSON.stringify({ image_url: vUrl, audio_url: aUrl }) });
    const { status_url, response_url } = JSON.parse(sub.body);
    let state = "IN_QUEUE";
    for (let k = 0; k < 90 && state !== "COMPLETED"; k++) {
      await new Promise(r => setTimeout(r, 4000));
      const st = await api(status_url);
      state = JSON.parse(st.body).status;
      if (state === "FAILED" || state === "ERROR") { console.log("FAILED " + tag + " " + st.body.slice(0,200)); break; }
    }
    if (state !== "COMPLETED") { console.log("timeout " + tag); continue; }
    const res = await api(response_url);
    const url = JSON.parse(res.body).video?.url;
    if (!url) { console.log("no video url for " + tag); continue; }
    const buf = Buffer.from(await (await fetch(url)).arrayBuffer());
    fs.writeFileSync(outF, buf);
    fs.unlinkSync(held); fs.unlinkSync(wav);
    done++;
    console.log(`SYNCED ${tag}  ${p.d.toFixed(1)}s  ${p.text.slice(0,34)}`);
  }
  console.log(`LIPSYNC DONE — ${done}/${plan.length}`);
};
run().catch(e => { console.error("ERROR", e.message); process.exit(1); });
