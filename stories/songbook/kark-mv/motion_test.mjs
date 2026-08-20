// Motion-engine test reels: same five photos, same five moves, one file per variant.
import { execFileSync } from "child_process";
import fs from "fs";
const D = "/Users/dusty/Dev/metaphrand/stories/songbook/kark-mv/";
const SHOTS = [
  ["b1_09_field", "pan"],   // lateral pan L->R
  ["o4_wheel_ride", "tilt"],// tilt up
  ["b1_02_window", "push"], // push in
  ["kf_2018", "diag"],      // diagonal toward upper-left
  ["b1_07_cart", "drift"],  // gentle drift right
];
const DUR = 3;
function vfFor(mode, fps) {
  const n = DUR * fps;
  const e = `(0.5-0.5*cos(PI*min(on/${n},1)))`;
  let z, x, y;
  const amt = 0.07;
  if (mode === "pan") { z = `1.06`; x = `(iw-iw/zoom)*(0.5+0.5*(2*${e}-1))`; y = `(ih-ih/zoom)*0.5`; }
  else if (mode === "drift") { z = `1.05`; x = `(iw-iw/zoom)*(0.5+0.35*(2*${e}-1))`; y = `(ih-ih/zoom)*0.5`; }
  else if (mode === "tilt") { z = `1.06`; x = `(iw-iw/zoom)*0.5`; y = `(ih-ih/zoom)*(0.5-0.5*(2*${e}-1))`; }
  else if (mode === "diag") { z = `1.05`; x = `(iw-iw/zoom)*(0.5-0.4*(2*${e}-1))`; y = `(ih-ih/zoom)*(0.5-0.4*(2*${e}-1))`; }
  else { z = `1+${amt}*${e}`; x = `(iw-iw/zoom)*(0.5+(0.58-0.5)*${e})`; y = `(ih-ih/zoom)*(0.5+(0.42-0.5)*${e})`; }
  const sw = Math.round(1920 * 1.3 * 2), sh = Math.round(1080 * 1.3 * 2);
  return { n, vf: `scale=${sw}:${sh}:force_original_aspect_ratio=increase:flags=lanczos,crop=${sw}:${sh},` +
    `zoompan=z='${z}':x='${x}':y='${y}':d=${n}:s=3840x2160:fps=${fps},scale=1920:1080:flags=lanczos,format=yuv420p` };
}
const fpsArg = +(process.argv[2] || 24);
const T = `/tmp/mt_${fpsArg}/`; fs.mkdirSync(T, { recursive: true });
const segs = [];
SHOTS.forEach(([name, mode], i) => {
  const src = fs.existsSync(D + "stock_framed/" + name + ".png") ? D + "stock_framed/" + name + ".png" : D + "stock/" + name + ".png";
  const m = vfFor(mode, fpsArg);
  const out = T + i + ".mp4";
  execFileSync("ffmpeg", ["-v", "error", "-y", "-loop", "1", "-i", src, "-vf", m.vf,
    "-frames:v", String(m.n), "-r", String(fpsArg), "-c:v", "libx264", "-crf", "19", "-preset", "veryfast", "-an", out], { timeout: 600000 });
  segs.push(out);
});
fs.writeFileSync(T + "cat.txt", segs.map(s => `file '${s}'`).join("\n") + "\n");
execFileSync("ffmpeg", ["-v", "error", "-y", "-f", "concat", "-safe", "0", "-i", T + "cat.txt", "-c", "copy", D + `motion_test_${fpsArg}fps.mp4`], { timeout: 300000 });
console.log(`motion_test_${fpsArg}fps.mp4 done`);
