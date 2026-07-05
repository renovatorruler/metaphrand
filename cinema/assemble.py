"""cinema.assemble — story-agnostic edit: a shot list + an audio track -> a cut.

Each shot is a still (subtle Ken Burns) or a video clip (Seedance). Cross-dissolves
at every cut; clip lengths are weight-proportional and scaled so the picture lands
exactly on the audio. Generalizes civilwar_av.chapter_video + _assemble_xfade, plus
the Ken-Burns the civil-war stills never had (they held static).

    shots = [(src, kind, weight), ...]   kind: "video" | "kb_in" | "kb_out" | "static"
    assemble(shots, "scene.mp3", "out.mp4")
"""
from __future__ import annotations

import os
import subprocess
import tempfile

from . import backends as bk


def _run(cmd: list[str]) -> None:
    subprocess.run(cmd, check=True)


def _clip(src: str, kind: str, seconds: float, res: tuple[int, int], fps: int, out: str) -> str:
    """One normalized clip of exactly `seconds`. Stills get Ken Burns; videos play once
    then freeze their last frame to fill the hold (no loop seam)."""
    W, H = res
    if kind == "video":
        vf = (f"scale={W}:{H}:force_original_aspect_ratio=increase,crop={W}:{H},"
              f"fps={fps},tpad=stop_mode=clone:stop_duration={seconds:.3f},format=yuv420p")
        _run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", src, "-t", f"{seconds:.3f}",
              "-vf", vf, "-an", "-c:v", "libx264", "-preset", "ultrafast", "-crf", "20", out])
        return out
    n = max(1, round(seconds * fps))
    if kind == "static":
        # no motion -> skip zoompan entirely (just scale + hold); much cheaper
        vf = f"scale={W}:{H}:force_original_aspect_ratio=increase,crop={W}:{H},format=yuv420p"
        _run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-loop", "1", "-t", f"{seconds:.3f}",
              "-i", src, "-r", str(fps), "-vf", vf, "-c:v", "libx264", "-preset", "ultrafast",
              "-crf", "20", out])
        return out
    z = "if(eq(on,0),1.12,max(zoom-0.00035,1.0))" if kind == "kb_out" else "min(zoom+0.00035,1.12)"
    sw, sh = int(W * 1.4), int(H * 1.4)   # modest oversample: smooth enough, far cheaper than 2x
    vf = (f"scale={sw}:{sh}:force_original_aspect_ratio=increase,crop={sw}:{sh},"
          f"zoompan=z='{z}':d={n}:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s={W}x{H}:fps={fps},"
          f"format=yuv420p")
    _run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-loop", "1", "-t", f"{seconds:.3f}",
          "-i", src, "-vf", vf, "-c:v", "libx264", "-preset", "ultrafast", "-crf", "20", out])
    return out


def assemble(shots: list[tuple], audio: str, out: str,
             res: tuple[int, int] = (1920, 1080), fps: int = 30, xfade: float = 0.5) -> str:
    """Cut `shots` to `audio`, cross-dissolving every cut, synced to the audio length."""
    n = len(shots)
    dur = bk.duration(audio)
    wsum = sum(w for *_, w in shots) or 1
    total = dur + (n - 1) * xfade          # xfades overlap, so holds must overshoot the audio
    holds = [total * w / wsum for *_, w in shots]

    tmp = tempfile.mkdtemp(prefix="cine_asm_")
    clips = [(_clip(src, kind, h + xfade, res, fps, f"{tmp}/c{i:02d}.mp4"), h)
             for i, ((src, kind, _), h) in enumerate(zip(shots, holds))]

    W, H = res
    cmd = ["ffmpeg", "-nostdin", "-loglevel", "error", "-y"]
    for c, _ in clips:
        cmd += ["-i", c]
    cmd += ["-i", audio]
    parts = [f"[{i}:v]fps={fps},scale={W}:{H},setsar=1,format=yuv420p[v{i}]" for i in range(n)]
    prev, base = "v0", 0.0
    for j in range(n - 1):
        base += clips[j][1]
        tj = max(0.05, min(xfade, clips[j][1] * 0.7, clips[j + 1][1] * 0.7))
        lbl = "vout" if j == n - 2 else f"x{j + 1}"
        parts.append(f"[{prev}][v{j + 1}]xfade=transition=fade:duration={tj:.3f}:"
                     f"offset={base - tj / 2:.3f}[{lbl}]")
        prev = lbl
    cmd += ["-filter_complex", ";".join(parts), "-map", "[vout]", "-map", f"{n}:a",
            "-c:v", "libx264", "-pix_fmt", "yuv420p", "-preset", "veryfast", "-crf", "21",
            "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-shortest", "-movflags", "+faststart", out]
    _run(cmd)
    print(f"{out}: {n} shots, {dur:.1f}s, {os.path.getsize(out) / 1e6:.1f} MB", flush=True)
    return out
