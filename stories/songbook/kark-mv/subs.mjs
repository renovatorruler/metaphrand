// Burn the author's English gloss onto the cut. No `subtitles` filter in this
// ffmpeg build, so each cue is rendered as a transparent PNG via typst and
// overlaid with an enable window. Timings follow the confirmed seam map and the
// verse-break analysis.
import { execFileSync } from "child_process";
import fs from "fs";

const D = "/Users/dusty/Dev/metaphrand/stories/songbook/kark-mv/";
const C = D + "subs/";
fs.mkdirSync(C, { recursive: true });

// [start, end, text] — text split for two-line readability
const CUES = [
  [18, 24, "I have come, O Teja — I have come with the thread."],
  [24, 30, "But where is the sting? Show me the bite marks."],
  [44, 54, "I searched the whole body — there is no wound."],
  [54, 64, "The blood drains from inside; nothing shows without."],
  [66, 72, "This is no snake, Teja. This is the crab — this is cancer."],
  [72, 80, "A snake strikes and flees — this one has gripped and settled."],
  [80, 87, "It never walks straight… it advances sideways, sideways."],
  [117, 124, "Your name binds snakes. Who binds this one's name?"],
  [124, 131, "I have tied your thread — but it does not know this animal."],
  [134, 140, "You asked for bite marks? Come and look — there ARE marks…"],
  [140, 146, "but they are the doctors' marks."],
  [146, 152, "Every day the needle's fang bites in… slowly the venom is raised."],
  [152, 160, "Poison kills poison — your own work, done without asking you."],
  [164, 170, "And look at this one, Teja… just look at her."],
  [170, 176, "Your Lilan was a mare — mine is this one."],
  [176, 181, "She never chose the road… but she never once stumbled."],
  [181, 186, "Every round she lifted me and carried me — wherever we had to go."],
  [230, 237, "But then — you did not survive either."],
  [237, 244, "All you asked was time: enough to keep your word."],
  [245, 251, "So let him reach the Bhadva fair. We will come to your fair —"],
  [251, 256, "she is the one who will bring him."],
  [256, 263, "There he will tie the thread with his own hand, and give the word:"],
  [263, 268, "\"Next Bhadva I will come again.\""],
  [269, 276, "That is the word, Teja… that is the one still pending."],
  [276, 285, "Fulfilled each year — tied again each year."],
  [297, 300, "Tie the thread — tie it to the word."],
  [300, 304, "Next Bhadva… we meet again."],
];

const W = 1920, H = 1080;
const esc = (s) => s.replace(/\\/g, "\\\\").replace(/"/g, '\\"');

CUES.forEach(([s, e, text], i) => {
  const png = `${C}c${String(i).padStart(2, "0")}.png`;
  if (fs.existsSync(png)) return;
  const typ = `${C}c${i}.typ`;
  fs.writeFileSync(typ, `#set page(width: ${W}pt, height: 200pt, margin: 0pt, fill: none)
#set text(font: "Helvetica", size: 42pt, weight: "medium", fill: white)
#place(center + horizon, box(width: ${W - 260}pt)[
  #set par(justify: false, leading: 12pt)
  #align(center)[#text(stroke: 3.5pt + rgb(0,0,0,190))[${esc(text)}]]
])
#place(center + horizon, box(width: ${W - 260}pt)[
  #set par(justify: false, leading: 12pt)
  #align(center)[${esc(text)}]
])`);
  execFileSync("typst", ["compile", typ, png, "--format", "png"], { timeout: 60000 });
});
console.log(CUES.length + " cue cards rendered");

// Chain the overlays: each enabled only within its window.
const inputs = ["-i", D + "KARK_MV_V1.mp4"];
CUES.forEach((_, i) => inputs.push("-i", `${C}c${String(i).padStart(2, "0")}.png`));
let fc = "[0:v]null[v0];";
CUES.forEach(([s, e], i) => {
  fc += `[${i + 1}]scale=${W}:-1[t${i}];[v${i}][t${i}]overlay=0:H-h-70:enable='between(t,${s},${e - 0.06})'[v${i + 1}];`;
});
fc = fc.slice(0, -1).replace(new RegExp(`\\[v${CUES.length}\\]$`), `[vout]`);

execFileSync("ffmpeg", ["-v", "error", "-y", ...inputs, "-filter_complex", fc,
  "-map", "[vout]", "-map", "0:a", "-c:v", "libx264", "-crf", "20", "-preset", "veryfast",
  "-c:a", "copy", "-movflags", "+faststart", D + "KARK_MV_V1_ENGSUB.mp4"], { timeout: 2400000 });
const dur = execFileSync("ffprobe", ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", D + "KARK_MV_V1_ENGSUB.mp4"], { encoding: "utf8" }).trim();
console.log("KARK_MV_V1_ENGSUB.mp4 — " + dur + "s");
