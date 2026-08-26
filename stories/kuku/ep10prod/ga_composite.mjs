// The ग is COMPOSITED, never generated.
//
// An image model renders Devanagari wrong every time and differently wrong in
// every frame, which is exactly what happened: the forged letter came out as a
// different golden object in each shot. So the frames are generated with the
// flat stone deliberately EMPTY, and the letter is built here from the real
// glyph — typeset, given papercraft depth in layers, lit warm — and placed onto
// each frame at a hand-set position.
//
//   node ga_composite.mjs --glyph     # (re)build the letter element only
//   node ga_composite.mjs             # composite into every registered shot
//
// Output goes to stills/<shot>.png and the pre-composite frame is kept as
// RAW_<shot>.png so a placement can be re-tuned without regenerating anything.
//
// KNOWN LIMIT: the letter is composited ON TOP, so in shots where the cart is
// baked into the frame it cannot sit BEHIND the cart. Those placements put it
// beside the cart instead — the cart reads as having come to rest at the ग. To
// have the cart truly cradled in the curve, the frame must be generated with
// neither cart nor letter and both composited in depth order.
import { execFileSync } from "child_process";
import fs from "fs";

const P = "/Users/dusty/Dev/metaphrand/stories/kuku/ep10prod/";
const S = P + "stills/";
const EL = P + "elements/"; fs.mkdirSync(EL, { recursive: true });
const GLYPH = EL + "ga_glyph.png";

// --- the letter as layered paper -------------------------------------------
// Five offset copies from dark to bright build the cut-paper thickness, then a
// warm rim on top. Rendered big so it downscales cleanly into any frame.
const buildGlyph = () => {
  const layers = [
    { dy: 26, fill: "rgb(120, 76, 18)" },
    { dy: 20, fill: "rgb(158, 104, 26)" },
    { dy: 14, fill: "rgb(198, 140, 38)" },
    { dy: 8,  fill: "rgb(228, 176, 60)" },
    { dy: 0,  fill: "rgb(250, 214, 110)" },
  ];
  const body = layers.map(l =>
    `#place(center + horizon, dy: ${l.dy}pt, text(font: ("Kohinoor Devanagari", "Devanagari Sangam MN"), size: 620pt, weight: "bold", fill: ${l.fill})[ग])`
  ).join("\n");
  fs.writeFileSync("/tmp/ga_glyph.typ",
`#set page(width: 900pt, height: 900pt, margin: 0pt, fill: none)
${body}
`);
  execFileSync("typst", ["compile", "/tmp/ga_glyph.typ", GLYPH, "--format", "png", "--ppi", "72"], { timeout: 120000 });
  console.log("built " + GLYPH);
};

// --- where the letter sits in each frame ------------------------------------
// x,y are the CENTRE of the letter as a fraction of frame width/height; w is its
// width as a fraction of frame width. Tuned by eye against each empty plate.
const PLACEMENTS = [
  { shot: "h29_ga_stands",      x: 0.50, y: 0.645, w: 0.28, glow: 1.0, shadow: 0.55 },
  { shot: "h35_last_marker",    x: 0.62, y: 0.46, w: 0.10, glow: 0.6, shadow: 0.35 },
  { shot: "h37_cart_into_curve",x: 0.72, y: 0.60, w: 0.26, glow: 0.9, shadow: 0.45 },
  { shot: "h38_stopped",        x: 0.74, y: 0.585, w: 0.24, glow: 0.9, shadow: 0.45 },
];

const I = P + "inbetweens/";
const composite = (pl, variant) => {
  const dir = variant ? I : S;
  const name = variant ? pl.shot + "__" + variant : pl.shot;
  const dst = dir + name + ".png";
  const raw = dir + "RAW_" + name + ".png";
  if (!fs.existsSync(dst)) { console.log("missing frame " + pl.shot); return false; }
  // keep the generated (empty-stone) frame so placement can be re-tuned freely
  if (!fs.existsSync(raw)) fs.copyFileSync(dst, raw);
  const [W, H] = execFileSync("ffprobe", ["-v", "error", "-show_entries", "stream=width,height",
    "-of", "csv=p=0:s=x", raw], { encoding: "utf8" }).trim().split("x").map(Number);
  const gw = Math.round(W * pl.w);
  const gx = Math.round(W * pl.x - gw / 2);
  // the letter's height follows its own aspect; overlay y is set from the centre
  const gh = Math.round(gw); // glyph canvas is square
  const gy = Math.round(H * pl.y - gh / 2);
  // a warm pool under it so it reads as forged INTO the stone, not pasted on
  const shW = Math.round(gw * 0.92), shH = Math.round(gh * 0.16);
  const shX = Math.round(W * pl.x - shW / 2), shY = Math.round(gy + gh * 0.80);
  const fc = [
    `[1:v]scale=${gw}:${gh}[g]`,
    `[g]split=3[g1][g2][g3]`,
    // a squashed, blurred copy laid on the stone at the letter's foot
    `[g3]scale=${shW}:${shH},boxblur=18:2,colorchannelmixer=rr=0:gg=0:bb=0,format=rgba,colorchannelmixer=aa=${pl.shadow}[sh]`,
    `[g2]boxblur=24:2,colorchannelmixer=rr=1.15:gg=0.85:bb=0.35,format=rgba,colorchannelmixer=aa=${pl.glow * 0.55}[glow]`,
    `[0:v][sh]overlay=${shX}:${shY}[b0]`,
    `[b0][glow]overlay=${gx}:${gy}[bg]`,
    `[bg][g1]overlay=${gx}:${gy}[v]`,
  ].join(";");
  execFileSync("ffmpeg", ["-v", "error", "-y", "-i", raw, "-i", GLYPH,
    "-filter_complex", fc, "-map", "[v]", "-frames:v", "1", dst], { timeout: 300000 });
  console.log("composited ग into " + name);
  return true;
};

if (process.argv.includes("--glyph")) { buildGlyph(); process.exit(0); }
if (!fs.existsSync(GLYPH)) buildGlyph();
let n = 0;
for (const pl of PLACEMENTS) {
  if (composite(pl)) n++;
  // every derivation of a composited hero needs the element re-applied
  if (fs.existsSync(I)) {
    for (const f of fs.readdirSync(I)) {
      const m = f.match(new RegExp("^" + pl.shot + "__([a-z_0-9]+)\\.png$"));
      if (m && composite(pl, m[1])) n++;
    }
  }
}
console.log(`ग composited into ${n} frames — raw frames kept as RAW_*.png`);
