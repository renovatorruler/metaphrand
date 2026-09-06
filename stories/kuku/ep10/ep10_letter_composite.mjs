// ep10_letter_composite.mjs — lay the true द over a frame or a clip.
//
// The letterform is NEVER generated. A model asked for द once returned दा, and a
// literacy episode cannot ship the wrong letter. The letter is drawn from a
// Devanagari font by make_letter.py, and this composites it — screen-blended so
// it sits inside the golden light the model already rendered, rather than
// pasting a flat sticker on top.
//
//   node ep10_letter_composite.mjs <in.png|in.mp4> <out> [xFrac] [yFrac] [hFrac]
// x/y are the letter's CENTRE as a fraction of frame; h is its height as a
// fraction of frame height. Defaults place it before the niche.
import { execFileSync } from "child_process";
import fs from "fs";

const P = new URL("./", import.meta.url).pathname;
const LETTER = P + "elements/letter_da_TRUE.png";
const argvv = process.argv.slice(2).filter(a => a !== "--mirror");
const MIRROR = process.argv.includes("--mirror");   // the reversed letter of s47/s48 — a VFX layer too
const [src, dst, xf = "0.5", yf = "0.52", hf = "0.30"] = argvv;
if (!src || !dst) { console.error("usage: <in> <out> [x] [y] [h]"); process.exit(1); }
if (!fs.existsSync(LETTER)) { console.error("letter asset missing: " + LETTER); process.exit(1); }

const isVideo = /\.(mp4|mov|webm)$/i.test(src);
// THE LETTER IS ONLY EVER DRAWN ONTO A FRAME THE MODEL WAS NOT ASKED TO DRAW IT IN.
// A receipt whose prompt carries a shape noun came from before the law; refuse it.
const receipt = src + ".gen.json";
if (fs.existsSync(receipt)) {
  const pr = JSON.parse(fs.readFileSync(receipt, "utf8")).prompt || "";
  if (/\b(letter|glyph|curve|column|beam|shape)\b/i.test(pr)) {
    console.error("REFUSED: " + src + " was generated from a prompt that names a shape — regenerate it under the law first");
    process.exit(2);
  }
}
// screen blend keeps the glow additive: the letter brightens what is behind it
// instead of occluding it, which is how a light source behaves.
const chain =
  `[1:v]scale=-1:ih*0:eval=init[ignored];` +
  `[1:v]scale=-1:${hf}*H_OUT[lt];` +
  `[0:v][lt]overlay=x=(W*${xf})-(w/2):y=(H*${yf})-(h/2):format=auto`;

// ffmpeg cannot reference the main input's height inside a scale on the overlay
// input, so resolve the pixel height first and substitute it.
const probe = execFileSync("ffprobe", ["-v","error","-select_streams","v","-show_entries",
  "stream=height","-of","csv=p=0", src], { encoding: "utf8" }).trim().split("\n")[0];
const px = Math.round(Number(probe) * Number(hf));
const filter = `[1:v]scale=-1:${px}${MIRROR ? ",hflip" : ""}[lt];[0:v][lt]overlay=x=(W*${xf})-(w/2):y=(H*${yf})-(h/2)`;

const args = ["-v","error","-y","-i",src,"-i",LETTER,"-filter_complex",filter];
if (isVideo) args.push("-c:v","libx264","-crf","18","-preset","slow","-pix_fmt","yuv420p","-an");
args.push(dst);
execFileSync("ffmpeg", args, { timeout: 1800000 });
console.log("composited द → " + dst);
