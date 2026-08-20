// Motion engine v2. The v1 engine gave every shot the same linear centre push,
// which read as formulaic. This one eases (slow-in/slow-out), anchors off-centre,
// varies distance and speed per shot, and holds roughly one shot in five dead
// still so the moving ones mean something.
export const FPS = 60, W = 1920, H = 1080;

// ease: 0..1 -> 0..1, cosine slow-in/slow-out. Applied via a per-frame expression.
const ease = (n) => `(0.5-0.5*cos(PI*min(on/${n},1)))`;

/**
 * kb(mode, dur, opts)
 *   push  — move in toward an anchor
 *   pull  — start close on the anchor and retreat to the full frame
 *   drift — hold scale, travel laterally
 *   tilt  — hold scale, travel vertically (dir: "u" rises, "d" descends)
 *   diag  — hold scale, travel corner to corner (dir: "ur" | "ul" | "dr" | "dl",
 *           naming the corner the camera moves TOWARD)
 *   still — no movement at all
 * opts: { amt: zoom distance (default .10), ax/ay: anchor 0..1 (default centre) }
 */
// MOTION RETIRED (author, 2026-08-19): the photographs are shown as photographs.
// No pan, no zoom, no crop — each still is presented whole, print frame and all.
export function kb(mode, dur, opts = {}) {
  const n = Math.max(2, Math.round(dur * FPS));
  return {
    n,
    vf: `scale=${W}:${H}:force_original_aspect_ratio=decrease:flags=lanczos,` +
        `pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2,fps=${FPS},format=yuv420p`,
  };
}

/* eslint-disable no-unreachable */
export function kbLegacy(mode, dur, opts = {}) {
  const n = Math.max(2, Math.round(dur * FPS));
  // Damped globally: the original amounts read as too rapid. Slower travel = cinema.
  const amt = (opts.amt ?? 0.10) * 0.6;
  const ax = opts.ax ?? 0.5, ay = opts.ay ?? 0.5;
  const e = ease(n);
  const up = 1.30; // source is pre-scaled this much so there is room to move
  const SS = 2;    // supersample: zoompan works at 2x and is lanczos-downscaled,
                   // turning its integer-pixel steps into sub-pixel motion (approved A/B)

  let z, x, y;
  if (mode === "still") {
    z = "1"; x = `iw/2-(iw/zoom/2)`; y = `ih/2-(ih/zoom/2)`;
  } else if (mode === "drift") {
    const dir = opts.dir === "l" ? -1 : 1;
    z = `${1 + amt}`;
    x = `(iw-iw/zoom)*(0.5+${dir * 0.5}*(2*${e}-1))`;
    y = `(ih-ih/zoom)*${ay}`;
  } else if (mode === "tilt") {
    const dir = opts.dir === "u" ? -1 : 1;
    z = `${1 + amt}`;
    x = `(iw-iw/zoom)*${ax}`;
    y = `(ih-ih/zoom)*(0.5+${dir * 0.5}*(2*${e}-1))`;
  } else if (mode === "diag") {
    const d = opts.dir || "dr";
    const dx = d.includes("l") ? -1 : 1, dy = d.includes("u") ? -1 : 1;
    z = `${1 + amt}`;
    x = `(iw-iw/zoom)*(0.5+${dx * 0.5}*(2*${e}-1))`;
    y = `(ih-ih/zoom)*(0.5+${dy * 0.5}*(2*${e}-1))`;
  } else {
    // push travels 1 -> 1+amt, pull travels 1+amt -> 1; both ease.
    z = mode === "pull" ? `${1 + amt}-${amt}*${e}` : `1+${amt}*${e}`;
    // drift the framing toward the anchor as we move, so the move has a subject
    x = `(iw-iw/zoom)*(0.5+(${ax}-0.5)*${e})`;
    y = `(ih-ih/zoom)*(0.5+(${ay}-0.5)*${e})`;
  }
  const sw = Math.round(W * up * SS), sh = Math.round(H * up * SS);
  return {
    n,
    vf: `scale=${sw}:${sh}:force_original_aspect_ratio=increase:flags=lanczos,crop=${sw}:${sh},` +
        `zoompan=z='${z}':x='${x}':y='${y}':d=${n}:s=${W * SS}x${H * SS}:fps=${FPS},` +
        `scale=${W}:${H}:flags=lanczos,format=yuv420p`,
  };
}
