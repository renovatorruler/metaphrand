"""THE HEIR — assemble the storyboard video: frozen audio + shotlist-timed frames.

Inputs:
  manifest.json   — written by examples/heir_elevenlabs.py: one entry per rendered
                    dialogue group (frame used for grouping, measured duration, gap).
  performance     — the performance JSON the audio was rendered from (segments).
  shotlist        — optional: maps segment index -> shot frame, or a list of
                    [frame, weight] pairs to cut WITHIN one segment.

The audio is never re-rendered here. Groups are re-derived with the renderer's
grouping rule and sanity-checked against the manifest; each group's measured
duration is apportioned across its segments by character count (a good proxy
for speech time), and the shotlist supplies the frame(s) per segment. Without a
shotlist it falls back to one frame per group, as before.

    python -m examples.heir_video manifest.json performance.json audio.mp3 out.mp4 [shotlist.json]
"""

from __future__ import annotations

import json
import os
import subprocess
import sys


def groups_of(perf: dict) -> list[list[tuple[int, dict]]]:
    """Re-derive the renderer's (scene-root, frame) grouping, with indices."""
    groups, key = [], None
    for i, seg in enumerate(perf["segments"]):
        k = (seg.get("scene", "").split("—")[0].strip(), seg.get("frame"))
        if not groups or key != k:
            groups.append([])
            key = k
        groups[-1].append((i, seg))
    return groups


def main(argv: list[str]) -> None:
    manifest_path, perf_path, audio, out = argv[0], argv[1], argv[2], argv[3]
    shotlist = json.load(open(argv[4]))["shots"] if len(argv) > 4 else {}
    manifest = json.load(open(manifest_path))
    perf = json.load(open(perf_path))

    groups = groups_of(perf)
    if len(groups) != len(manifest):
        raise SystemExit(f"grouping mismatch: {len(groups)} derived vs {len(manifest)} rendered "
                         "— the performance file changed since the audio render")

    # timeline: (frame, hold_seconds)
    cuts: list[tuple[str, float]] = []
    for g, m in zip(groups, manifest):
        total_chars = sum(len(s["text"]) for _, s in g) or 1
        for j, (i, seg) in enumerate(g):
            hold = m["duration"] * len(seg["text"]) / total_chars
            if j == len(g) - 1:
                hold += m.get("gap_after_ms", 0) / 1000.0
            shot = shotlist.get(str(i), seg.get("frame"))
            if isinstance(shot, list):  # weighted sub-cuts within one segment
                wsum = sum(w for _, w in shot) or 1
                for frame, w in shot:
                    cuts.append((frame, hold * w / wsum))
            else:
                cuts.append((shot, hold))

    # merge consecutive identical frames so cuts are real cuts
    merged: list[list] = []
    for frame, hold in cuts:
        if merged and merged[-1][0] == frame:
            merged[-1][1] += hold
        else:
            merged.append([frame, hold])

    black = os.path.join(os.path.dirname(os.path.abspath(merged[0][0])), "black.png")
    if not os.path.exists(black):
        from PIL import Image
        Image.new("RGB", (1376, 768), (0, 0, 0)).save(black)

    lst = out + ".frames.txt"
    with open(lst, "w") as f:
        for frame, hold in merged:
            f.write(f"file '{os.path.abspath(frame)}'\nduration {hold:.3f}\n")
        # end on black: vfr drops a repeated identical frame, so the closer must differ
        f.write(f"file '{black}'\nduration 1.0\nfile '{black}'\n")

    subprocess.run(
        ["ffmpeg", "-nostdin", "-loglevel", "error", "-y",
         "-f", "concat", "-safe", "0", "-i", lst, "-i", audio,
         "-vf", "scale=1376:768,format=yuv420p", "-fps_mode", "vfr",
         "-c:v", "libx264", "-tune", "stillimage", "-preset", "slow", "-crf", "26",
         "-c:a", "aac", "-b:a", "96k", "-movflags", "+faststart", out],
        check=True,
    )
    os.remove(lst)
    probe = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration,size",
         "-of", "json", out], capture_output=True, text=True, check=True)
    fmt = json.loads(probe.stdout)["format"]
    print(f"{out}: {len(merged)} cuts, {float(fmt['duration'])/60:.1f} min, "
          f"{int(fmt['size'])/1e6:.1f} MB")


if __name__ == "__main__":
    main(sys.argv[1:])
