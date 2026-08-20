// Builds the proof-sheet review page: small grid thumbs + a full-screen viewer
// with large images, keyboard marking, and a copyable summary.
import fs from "fs";
import { execFileSync } from "child_process";

const D = "/Users/dusty/Dev/metaphrand/stories/songbook/kark-mv/";
const G = D + "graded/";
const TH = "/tmp/th_small/", LG = "/tmp/th_large/";
[TH, LG].forEach(d => fs.mkdirSync(d, { recursive: true }));

const files = fs.readdirSync(G).filter(f => f.endsWith(".png")).sort();
for (const f of files) {
  const b = f.replace(".png", ".jpg");
  if (!fs.existsSync(TH + b)) execFileSync("ffmpeg", ["-v", "error", "-y", "-i", G + f, "-vf", "scale=320:-1", "-q:v", "7", TH + b]);
  if (!fs.existsSync(LG + b)) execFileSync("ffmpeg", ["-v", "error", "-y", "-i", G + f, "-vf", "scale=1100:-1", "-q:v", "5", LG + b]);
}

const GROUPS = [
  ["1976 — courtship", f => f.startsWith("b1_")],
  ["1976 — origin · pre-dates the young canonicals", f => /^o[0-9]/.test(f)],
  ["1990 — young kids", f => f.startsWith("b2_")],
  ["1990 — family", f => /^n[0-9]/.test(f)],
  ["2005 — teenagers", f => f.startsWith("b3_")],
  ["2018 — weddings", f => f.startsWith("b4_")],
  ["2021 — grandkids", f => f.startsWith("b5_")],
  ["present — the hospital", f => f.startsWith("b6_")],
  ["the मेला and the ending", f => f.startsWith("m") || f.startsWith("x_")],
  ["thread keyframes", f => f.startsWith("kf_")],
];
const used = new Set(); const groups = [];
for (const [label, test] of GROUPS) {
  const items = files.filter(f => !used.has(f) && test(f));
  items.forEach(f => used.add(f));
  if (items.length) groups.push({ label, items });
}
const rest = files.filter(f => !used.has(f));
if (rest.length) groups.push({ label: "other", items: rest });

const b64 = (p) => "data:image/jpeg;base64," + fs.readFileSync(p).toString("base64");
let flat = [], html = "";
for (const g of groups) {
  html += `<section><h2>${g.label} <span class="n">${g.items.length}</span></h2><div class="grid">`;
  for (const f of g.items) {
    const id = f.replace(".png", ""), jpg = f.replace(".png", ".jpg");
    const i = flat.length;
    flat.push({ id, large: b64(LG + jpg) });
    html += `<figure data-id="${id}" data-i="${i}">
<button class="shot" type="button" aria-label="Enlarge ${id}"><img loading="lazy" src="${b64(TH + jpg)}" alt="${id}"><span class="mark" aria-hidden="true"></span></button>
<figcaption>${id}</figcaption>
<div class="row"><button class="v k" type="button">keep</button><button class="v r" type="button">redo</button></div>
<textarea placeholder="what is wrong with it"></textarea></figure>`;
  }
  html += `</div></section>`;
}

const page = `<title>कर्क की तांती — proof sheet</title>
<style>
:root{--ground:#15130e;--surface:#1e1b15;--raised:#282419;--line:#3a3323;--ink:#efe8d8;--muted:#948b79;--dim:#655e4e;--keep:#e3ab3d;--redo:#d25541}
@media (prefers-color-scheme:light){:root{--ground:#e9e5da;--surface:#f7f4ed;--raised:#fffdf7;--line:#d0c9b7;--ink:#211e16;--muted:#6a6353;--dim:#968e7c;--keep:#9d6b13;--redo:#a63528}}
:root[data-theme=dark]{--ground:#15130e;--surface:#1e1b15;--raised:#282419;--line:#3a3323;--ink:#efe8d8;--muted:#948b79;--dim:#655e4e;--keep:#e3ab3d;--redo:#d25541}
:root[data-theme=light]{--ground:#e9e5da;--surface:#f7f4ed;--raised:#fffdf7;--line:#d0c9b7;--ink:#211e16;--muted:#6a6353;--dim:#968e7c;--keep:#9d6b13;--redo:#a63528}
*{box-sizing:border-box}
body{margin:0;background:var(--ground);color:var(--ink);font-family:ui-sans-serif,-apple-system,"Segoe UI",Roboto,sans-serif;padding-bottom:96px;-webkit-font-smoothing:antialiased}
header{padding:24px 16px 14px;border-bottom:1px solid var(--line)}
h1{margin:0;font-size:19px;font-weight:650;letter-spacing:-.01em}
.sub{margin:7px 0 0;color:var(--muted);font-size:13.5px;line-height:1.6;max-width:64ch}
kbd{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;background:var(--raised);border:1px solid var(--line);border-radius:4px;padding:1px 6px;font-size:12px;color:var(--ink)}
section{padding:22px 12px 2px}
h2{margin:0 0 12px;font-size:11.5px;font-weight:600;letter-spacing:.13em;text-transform:uppercase;color:var(--muted);display:flex;gap:10px;align-items:baseline}
h2 .n{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;color:var(--dim);letter-spacing:0}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(172px,1fr));gap:13px}
figure{margin:0;background:var(--surface);border:1.5px solid var(--line);border-radius:3px;overflow:hidden;display:flex;flex-direction:column}
figure[data-v=keep]{border-color:var(--keep)}
figure[data-v=redo]{border-color:var(--redo)}
.shot{position:relative;display:block;width:100%;padding:0;border:0;background:#000;aspect-ratio:16/9;cursor:zoom-in}
.shot img{width:100%;height:100%;object-fit:cover;display:block}
.shot:focus-visible{outline:2px solid var(--keep);outline-offset:-2px}
.mark{position:absolute;top:6px;right:7px;width:26px;height:26px;border-radius:50%;display:none;align-items:center;justify-content:center;font-size:16px;font-weight:700;line-height:1}
figure[data-v=keep] .mark{display:flex;background:var(--keep);color:#15130e}
figure[data-v=redo] .mark{display:flex;background:var(--redo);color:#fff}
figcaption{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:10.5px;color:var(--muted);padding:6px 8px 0;word-break:break-all;line-height:1.4}
.row{display:flex;gap:6px;padding:6px 8px 8px}
.v{flex:1;background:var(--raised);color:var(--muted);border:1.5px solid var(--line);border-radius:3px;padding:8px 0;font:inherit;font-size:12.5px;font-weight:650;cursor:pointer}
.v:hover{color:var(--ink)}
.v:focus-visible{outline:2px solid var(--ink);outline-offset:1px}
figure[data-v=keep] .v.k,.v.k.on{background:var(--keep);color:#15130e;border-color:var(--keep)}
figure[data-v=redo] .v.r,.v.r.on{background:var(--redo);color:#fff;border-color:var(--redo)}
textarea{display:none;width:calc(100% - 16px);margin:0 8px 8px;background:var(--ground);color:var(--ink);border:1px solid var(--line);border-radius:3px;padding:7px;font:inherit;font-size:12.5px;resize:vertical;min-height:46px}
figure[data-v=redo] textarea{display:block}
footer{position:fixed;left:0;right:0;bottom:0;background:var(--surface);border-top:1px solid var(--line);padding:11px 14px;display:flex;gap:12px;align-items:center;justify-content:space-between;flex-wrap:wrap;z-index:20}
.tally{font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:13px;color:var(--muted);font-variant-numeric:tabular-nums}
.tally b{color:var(--ink);font-weight:650}.tally .k{color:var(--keep)}.tally .r{color:var(--redo)}
footer button{background:var(--raised);color:var(--ink);border:1.5px solid var(--line);border-radius:4px;padding:9px 14px;font:inherit;font-size:13px;font-weight:650;cursor:pointer}
footer button.primary{background:var(--keep);color:#15130e;border-color:var(--keep)}
.acts{display:flex;gap:8px}
#lb{position:fixed;inset:0;background:rgba(8,7,5,.97);z-index:50;display:none;flex-direction:column}
#lb.open{display:flex}
#lb .pic{flex:1;min-height:0;display:flex;align-items:center;justify-content:center;padding:10px}
#lb img{max-width:100%;max-height:100%;object-fit:contain}
#lb .bar{border-top:1px solid var(--line);background:var(--surface);padding:10px 12px calc(10px + env(safe-area-inset-bottom));display:grid;grid-template-columns:1fr 1fr;gap:9px}
#lb .id{grid-column:1/-1;font-family:ui-monospace,SFMono-Regular,Menlo,monospace;font-size:12px;color:var(--muted);display:flex;justify-content:space-between;align-items:center}
#lb .bar button{background:var(--raised);color:var(--ink);border:2px solid var(--line);border-radius:6px;padding:16px 10px;font:inherit;font-size:16px;font-weight:700;cursor:pointer;min-height:56px}
#lb .bar button.wide{grid-column:1/-1;padding:13px;font-size:14px;min-height:48px;color:var(--muted)}
#lb .bar button.k.on{background:var(--keep);color:#15130e;border-color:var(--keep)}
#lb .bar button.r.on{background:var(--redo);color:#fff;border-color:var(--redo)}
#lb .note{grid-column:1/-1;width:100%;background:var(--ground);color:var(--ink);border:1px solid var(--line);border-radius:5px;padding:11px;font:inherit;font-size:16px;min-height:52px;resize:vertical}
@media (max-width:430px){.grid{grid-template-columns:repeat(2,1fr);gap:9px}section{padding:18px 9px 2px}}
@media (prefers-reduced-motion:reduce){*{transition:none!important}}
</style>
<header><h1>कर्क की तांती — proof sheet</h1>
<p class="sub">Tap a frame to see it big. In the viewer, <b>keep</b> marks it and moves you straight to the next one, <b>redo</b> opens a box to say what's wrong. Swipe left or right to move between frames. Marks are saved as you go. When you're done, hit <b>Copy feedback</b> and paste it back into the chat.</p></header>
${html}
<footer><div class="tally" id="tally">—</div><div class="acts"><button type="button" id="clear">Clear all</button><button type="button" class="primary" id="copy">Copy feedback</button></div></footer>
<div id="lb" role="dialog" aria-modal="true" aria-label="Enlarged frame">
  <div class="pic"><img id="lbimg" alt=""></div>
  <div class="bar">
    <span class="id"><span id="lbid"></span><span id="lbpos"></span></span>
    <button type="button" class="k" id="lbkeep">\u2713 keep</button>
    <button type="button" class="r" id="lbredo">\u2715 redo</button>
    <textarea class="note" id="lbnote" placeholder="what is wrong with it"></textarea>
    <button type="button" id="lbprev">\u2190 back</button>
    <button type="button" id="lbnext">next \u2192</button>
    <button type="button" class="wide" id="lbclose">close</button>
  </div>
</div>
<script>
const LARGE = ${JSON.stringify(flat)};
const figs = [...document.querySelectorAll('figure')];
const tally = document.getElementById('tally');
let cur = -1;

function setV(f, v){
  if (v) f.dataset.v = v; else delete f.dataset.v;
  f.querySelector('.mark').textContent = v === 'keep' ? '\\u2713' : (v === 'redo' ? '\\u2715' : '');
  count(); save(); if (cur >= 0) syncLB();
}
function count(){
  const k = figs.filter(f => f.dataset.v === 'keep').length;
  const r = figs.filter(f => f.dataset.v === 'redo').length;
  tally.innerHTML = '<b>' + (k + r) + '</b> of ' + figs.length + ' marked &nbsp;·&nbsp; <span class="k">' + k + ' keep</span> &nbsp;·&nbsp; <span class="r">' + r + ' redo</span>';
}
function save(){
  try { const s = {}; figs.forEach(f => { const n = f.querySelector('textarea').value;
    if (f.dataset.v || n) s[f.dataset.id] = [f.dataset.v || '', n]; });
    localStorage.setItem('kark-proof-v2', JSON.stringify(s)); } catch(e){}
}
figs.forEach(f => {
  f.querySelector('.shot').addEventListener('click', () => open(+f.dataset.i));
  f.querySelector('.k').addEventListener('click', () => setV(f, f.dataset.v === 'keep' ? '' : 'keep'));
  f.querySelector('.r').addEventListener('click', () => setV(f, f.dataset.v === 'redo' ? '' : 'redo'));
  f.querySelector('textarea').addEventListener('input', save);
});
const lb = document.getElementById('lb'), lbimg = document.getElementById('lbimg');
const lbid = document.getElementById('lbid'), lbpos = document.getElementById('lbpos'), lbnote = document.getElementById('lbnote');
const lbkeep = document.getElementById('lbkeep'), lbredo = document.getElementById('lbredo');
function open(i){ cur = i; lb.classList.add('open'); syncLB(); }
function close(){ cur = -1; lb.classList.remove('open'); }
function syncLB(){
  if (cur < 0) return;
  const f = figs[cur];
  lbimg.src = LARGE[cur].large; lbimg.alt = LARGE[cur].id;
  lbid.textContent = LARGE[cur].id;
  lbpos.textContent = (cur + 1) + ' / ' + figs.length;
  lbnote.value = f.querySelector('textarea').value;
  lbkeep.classList.toggle('on', f.dataset.v === 'keep');
  lbredo.classList.toggle('on', f.dataset.v === 'redo');
}
function step(d){ if (cur < 0) return; cur = (cur + d + figs.length) % figs.length; syncLB(); }
lbkeep.addEventListener('click', () => { const on = figs[cur].dataset.v === 'keep'; setV(figs[cur], on ? '' : 'keep'); if (!on) step(1); });
lbredo.addEventListener('click', () => setV(figs[cur], figs[cur].dataset.v === 'redo' ? '' : 'redo'));
document.getElementById('lbprev').addEventListener('click', () => step(-1));
document.getElementById('lbnext').addEventListener('click', () => step(1));
document.getElementById('lbclose').addEventListener('click', close);
let tx = 0, ty = 0;
lb.addEventListener('touchstart', e => { tx = e.changedTouches[0].clientX; ty = e.changedTouches[0].clientY; }, {passive:true});
lb.addEventListener('touchend', e => {
  const dx = e.changedTouches[0].clientX - tx, dy = e.changedTouches[0].clientY - ty;
  if (Math.abs(dx) > 55 && Math.abs(dx) > Math.abs(dy) * 1.6) step(dx < 0 ? 1 : -1);
}, {passive:true});
lbnote.addEventListener('input', () => { if (cur < 0) return; figs[cur].querySelector('textarea').value = lbnote.value; save(); });
document.addEventListener('keydown', e => {
  if (cur < 0) return;
  if (e.target === lbnote) { if (e.key === 'Escape') lbnote.blur(); return; }
  if (e.key === 'Escape') close();
  else if (e.key === 'ArrowRight') step(1);
  else if (e.key === 'ArrowLeft') step(-1);
  else if (e.key.toLowerCase() === 'k') { setV(figs[cur], figs[cur].dataset.v === 'keep' ? '' : 'keep'); step(1); }
  else if (e.key.toLowerCase() === 'r') setV(figs[cur], figs[cur].dataset.v === 'redo' ? '' : 'redo');
});
try { const s = JSON.parse(localStorage.getItem('kark-proof-v2') || '{}');
  figs.forEach(f => { const v = s[f.dataset.id]; if (v) { f.querySelector('textarea').value = v[1] || ''; if (v[0]) setV(f, v[0]); } }); } catch(e){}
count();
document.getElementById('clear').addEventListener('click', () => {
  figs.forEach(f => { f.querySelector('textarea').value = ''; setV(f, ''); }); save();
});
document.getElementById('copy').addEventListener('click', async () => {
  const keep = [], redo = [];
  figs.forEach(f => { const n = f.querySelector('textarea').value.trim();
    if (f.dataset.v === 'keep') keep.push(f.dataset.id);
    if (f.dataset.v === 'redo') redo.push(f.dataset.id + (n ? ' — ' + n : '')); });
  const txt = 'PROOF SHEET FEEDBACK\\n\\nREDO (' + redo.length + '):\\n' + (redo.map(x => '- ' + x).join('\\n') || '- none') +
    '\\n\\nKEEP (' + keep.length + '):\\n' + (keep.map(x => '- ' + x).join('\\n') || '- none');
  try { await navigator.clipboard.writeText(txt); }
  catch(e){ const t = document.createElement('textarea'); t.value = txt; document.body.appendChild(t); t.select(); document.execCommand('copy'); t.remove(); }
  const b = document.getElementById('copy'); const o = b.textContent; b.textContent = 'Copied';
  setTimeout(() => b.textContent = o, 1400);
});
</script>`;

const out = "/private/tmp/claude-501/-Users-dusty-Dev-metaphrand/bb2593f0-6bdb-4e47-b833-6c7a4814888d/scratchpad/proof.html";
fs.writeFileSync(out, page);
console.log("proof.html " + (fs.statSync(out).size / 1048576).toFixed(2) + "MB, " + flat.length + " frames");
