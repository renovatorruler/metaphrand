"""THE HEIR — render a stored performance file through ElevenLabs v3 dialogue.

The performance layer (stories/the-heir/performance/*.performance.json) is the
maintained artifact: screenplay text verbatim, expressive v3 audio tags, a cast
map, and a storyboard frame per segment. This renderer executes it.

Consecutive segments sharing (scene, frame) are rendered as ONE
/v1/text-to-dialogue request, so a whole stretch of conversation is a single
continuous multi-speaker generation — no per-line voice drift (v3 does not
support request stitching; dialogue mode is its continuity mechanism). Group
boundaries land exactly on storyboard cuts, where a beat is natural anyway.

Groups are cached by content hash (re-runs only fetch what changed), stitched
with ffmpeg, and a manifest.json (group -> frame, duration) is written for the
video assembler (examples/heir_video.py). Key at ~/.elevenlabs_api_key.

    python -m examples.heir_elevenlabs stories/the-heir/performance/act1-opening.performance.json out.mp3
"""

from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
import time
import urllib.request

API = "https://api.elevenlabs.io/v1/text-to-dialogue?output_format={fmt}"


def synth_group(inputs: list[dict], model: str, fmt: str, key: str, path: str) -> None:
    req = urllib.request.Request(
        API.format(fmt=fmt),
        headers={"xi-api-key": key, "Content-Type": "application/json"},
        data=json.dumps({"inputs": inputs, "model_id": model}).encode(),
    )
    for attempt in range(3):
        try:
            with urllib.request.urlopen(req, timeout=300) as r:
                open(path, "wb").write(r.read())
            return
        except urllib.error.HTTPError as e:
            detail = e.read()[:300]
            if e.code in (429, 500, 502, 503) and attempt < 2:
                time.sleep(5 * (attempt + 1))
                continue
            raise RuntimeError(f"group HTTP {e.code} {detail!r}") from e


def silence(ms: int, cache: str) -> str:
    path = f"{cache}/silence_{ms}.mp3"
    if not os.path.exists(path):
        subprocess.run(
            ["ffmpeg", "-nostdin", "-loglevel", "error", "-y",
             "-f", "lavfi", "-i", "anullsrc=r=44100:cl=mono",
             "-t", f"{ms/1000:.3f}", "-codec:a", "libmp3lame", "-b:a", "128k", path],
            check=True,
        )
    return path


def duration_of(path: str) -> float:
    """Exact duration by full decode — mp3 header estimates drift (off by
    seconds per file), which desyncs the video cut."""
    proc = subprocess.run(
        ["ffmpeg", "-nostdin", "-i", path, "-f", "null", "-"],
        capture_output=True, text=True,
    )
    import re
    times = re.findall(r"time=(\d+):(\d+):(\d+\.\d+)", proc.stderr)
    h, m, s = times[-1]
    return int(h) * 3600 + int(m) * 60 + float(s)


def main(argv: list[str]) -> None:
    perf_path = argv[0]
    out = argv[1] if len(argv) > 1 else perf_path.replace(".performance.json", ".mp3")
    perf = json.load(open(perf_path))
    key = open(os.path.expanduser("~/.elevenlabs_api_key")).read().strip()

    cache = os.path.join(os.path.dirname(perf_path), "segments")
    os.makedirs(cache, exist_ok=True)
    model, fmt = perf["model_id"], perf.get("output_format", "mp3_44100_128")
    gap_ms = perf.get("gaps_ms", {}).get("group", 600)

    # group consecutive segments by (scene-root, frame): one dialogue request each
    groups: list[dict] = []
    for seg in perf["segments"]:
        k = (seg.get("scene", "").split("—")[0].strip(), seg.get("frame"))
        if groups and groups[-1]["key"] == k:
            groups[-1]["segments"].append(seg)
        else:
            groups.append({"key": k, "frame": seg.get("frame"), "segments": [seg]})

    files, manifest, chars = [], [], 0
    for gi, g in enumerate(groups):
        inputs = [{"text": s["text"], "voice_id": perf["cast"][s["speaker"]]["voice_id"]}
                  for s in g["segments"]]
        digest = hashlib.sha1(
            json.dumps([inputs, model], sort_keys=True).encode()
        ).hexdigest()[:16]
        path = f"{cache}/grp_{digest}.mp3"  # digest-only: content cache survives insertions
        if not os.path.exists(path):
            synth_group(inputs, model, fmt, key, path)
            print(f"[{gi+1}/{len(groups)}] {len(inputs):2d} lines  {g['key'][0][:40]}")
        chars += sum(len(i["text"]) for i in inputs)
        if files:
            files.append(silence(gap_ms, cache))
        files.append(path)
        manifest.append({"group": gi, "scene": g["key"][0], "frame": g["frame"],
                         "path": path, "duration": duration_of(path),
                         "gap_after_ms": 0 if gi == len(groups) - 1 else gap_ms})
    manifest_path = out.rsplit(".", 1)[0] + ".manifest.json"
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=1)

    concat = f"{cache}/concat.txt"
    with open(concat, "w") as f:
        for p in files:
            f.write(f"file '{os.path.abspath(p)}'\n")
    subprocess.run(
        ["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-f", "concat", "-safe", "0",
         "-i", concat, "-codec:a", "libmp3lame", "-b:a", "96k", "-ac", "1", out],
        check=True,
    )
    print(f"\n{len(groups)} dialogue groups, {chars} chars -> {out}  "
          f"({duration_of(out)/60:.1f} min); manifest -> {manifest_path}")


if __name__ == "__main__":
    main(sys.argv[1:])
