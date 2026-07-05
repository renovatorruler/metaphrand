"""INDIVISIBLE — the melting-pot score: one instrument/flavor per family.

Peter-and-the-Wolf leitmotif as scaffolding: each family's musical color lives
in a data table (FAMILIES); the composer reads the table and renders an
instrumental underscore bed via ElevenLabs Music. A scene declares which family
is DOMINANT; that family's bed plays. Everything is mixed UNDER George with
sidechain ducking + a speech-band EQ carve, so it never fights the narration —
it's an audiobook first.

  python -m examples.score bed <family>          # render one family's bed
  python -m examples.score mix <bed.mp3> <narration.mp3> <out.mp3>
  python -m examples.score proof                 # home + one flavor, mixed under George

Families seeded from the pilot cast. The American "home key" is the harmonic
home every immigrant flavor resolves toward — the e-pluribus-unum the title
names. Key at ~/.elevenlabs_api_key.
"""
from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
import time
import urllib.request
import urllib.error

OUT = "stories/civil-war/score"
MUSIC_API = "https://api.elevenlabs.io/v1/music?output_format=mp3_44100_128"
MUSICGEN_VER = "671ac645ce5e552cc63a54a2bbff63fcf798043055d2dac5fc9e36a837eedcfb"
# Backend: "elevenlabs" once the key has the music_generation permission;
# "replicate" (MusicGen) works today and is the default.
BACKEND = os.environ.get("MUSIC_BACKEND", "replicate")

# The American home key — not a family flavor but the harmonic home they fuse to.
HOME = ("spacious cinematic American orchestral underscore, wide-open prairie "
        "strings and a soft distant French horn, expansive big-sky breadth, "
        "hopeful but tested, very slow, sustained, no percussion, no melodic "
        "hook, gentle, ambient film-score bed")

# family -> signature instrument + idiom (the leitmotif carrier).
FAMILIES = {
    "desmond": ("Black American (Desmond's family) — a lone resonant low electric "
                "guitar and warm hymn-like strings, dignified and grounded, "
                "blues-rooted without pastiche"),
    "nguyen":  ("Vietnamese (the Nguyens) — a lone đàn bầu monochord and đàn tranh "
                "zither with gentle bent notes over a soft string pad, plaintive "
                "and reserved"),
    "mehta":   ("Indian (the Mehtas) — a bansuri bamboo flute and sarangi over a "
                "tanpura drone, raga-inflected, warm and searching"),
    "min":     ("Korean (Min's family) — a gayageum zither and haegeum fiddle, "
                "restrained and formal, a held distance"),
    "adeyemi": ("Nigerian (the Adeyemis) — a kora and a soft, low talking drum, a "
                "warm communal lilt kept quiet"),
}
MOODS = {
    "warm":    "warm, tender, intimate, unhurried family calm",
    "tension": "tense and slowly building, rising unease, strings tightening, "
               "a sense of something coming",
    "action":  "driving and urgent, a propulsive low pulse under tense strings, "
               "semi-action, building, cinematic, no full drum kit",
    "dread":   "low, tense, foreboding, sparse",
    "calm":    "calm, tender, intimate",
    "cold":    "still and distant, a held melancholy, withdrawn and lonely, very sparse",
}

# Per-chapter score plan: a list of (onset_keyword|None, family, mood) cues. The
# family can SWITCH mid-chapter — the dominant family of the scene scores it. The
# first cue opens at 0; each later cue starts where its keyword first appears in
# the NARRATION prose.
CHAPTER_CUES = {
    "ch1": [(None, "desmond", "warm"), ("dust", "desmond", "tension"),
            ("fired", "desmond", "action")],
    # house-hunt (Desmond) -> the Korean family's fence (Min, cold/reserved) ->
    # the boy crosses the gate to Nia (Min, warming — the melting pot's first act).
    "ch2": [(None, "desmond", "warm"), ("fence", "min", "cold"),
            ("gate", "min", "warm")],
}


def _music_elevenlabs(prompt: str, length_ms: int, path: str) -> None:
    key = open(os.path.expanduser("~/.elevenlabs_api_key")).read().strip()
    body = {"prompt": prompt, "music_length_ms": length_ms,
            "model_id": "music_v1", "force_instrumental": True}
    req = urllib.request.Request(
        MUSIC_API, headers={"xi-api-key": key, "Content-Type": "application/json"},
        data=json.dumps(body).encode())
    try:
        with urllib.request.urlopen(req, timeout=300) as r:
            open(path, "wb").write(r.read())
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"music HTTP {e.code}: {e.read()[:300]!r}") from e


def _music_replicate(prompt: str, length_ms: int, path: str) -> None:
    token = open(os.path.expanduser("~/.replicate_api_key")).read().strip()
    body = {"version": MUSICGEN_VER,
            "input": {"prompt": prompt, "duration": max(8, round(length_ms / 1000)),
                      "output_format": "mp3", "normalization_strategy": "loudness",
                      "model_version": "stereo-large"}}
    req = urllib.request.Request(
        "https://api.replicate.com/v1/predictions",
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        data=json.dumps(body).encode())
    with urllib.request.urlopen(req, timeout=300) as r:
        pred = json.load(r)
    get = pred["urls"]["get"]
    while pred.get("status") in ("starting", "processing"):
        time.sleep(3)
        with urllib.request.urlopen(urllib.request.Request(
                get, headers={"Authorization": f"Bearer {token}"}), timeout=60) as r:
            pred = json.load(r)
    if pred.get("status") != "succeeded":
        raise RuntimeError(f"musicgen {pred.get('status')}: {pred.get('error')}")
    url = pred["output"] if isinstance(pred["output"], str) else pred["output"][0]
    open(path, "wb").write(urllib.request.urlopen(url, timeout=180).read())


def _music(prompt: str, length_ms: int, path: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    (_music_elevenlabs if BACKEND == "elevenlabs" else _music_replicate)(prompt, length_ms, path)


def bed(family: str, mood: str = "calm", length_ms: int = 26000) -> str:
    """Render (cached) one family's underscore bed. family='home' = American key."""
    desc = HOME if family == "home" else FAMILIES[family].split(" — ", 1)[1]
    prompt = (f"{desc}; {MOODS[mood]}; slow harmonic rhythm, no drums or beat, no "
              f"vocals, lots of space and air, sits quietly under a spoken voice; "
              f"instrumental underscore only")
    digest = hashlib.sha1(f"{prompt}{length_ms}".encode()).hexdigest()[:10]
    path = f"{OUT}/bed_{family}_{mood}_{BACKEND}_{digest}.mp3"
    if not os.path.exists(path):
        _music(prompt, length_ms, path)
        print(f"bed: {family}/{mood} -> {path}")
    else:
        print(f"bed cached: {path}")
    return path


PERF = "stories/civil-war/performance"


def chapter_clock(ch: str):
    """Chapter-relative (scene, start_sec) for each group, and total duration —
    derived from the same manifest the video assembler uses, so cues land on cuts."""
    man = json.load(open(f"{PERF}/pilot.manifest.json"))
    rows, t, inch = [], 0.0, False
    for m in man:
        if m["scene"].startswith(ch):
            inch = True
            rows.append((m["scene"], t))
            t += m["duration"] + m.get("gap_after_ms", 0) / 1000.0
        elif inch:
            break
    return rows, t


def onset_time(ch: str, keyword: str) -> float:
    """Chapter-relative time of the first scene whose narration contains keyword."""
    perf = json.load(open(f"{PERF}/pilot.performance.json"))
    scene_of = {}
    for s in perf["segments"]:
        if keyword.lower() in s["text"].lower() and s["scene"].startswith(ch):
            scene_of = s["scene"]
            break
    rows, _ = chapter_clock(ch)
    for scene, start in rows:
        if scene == scene_of:
            return start
    return 0.0


def build_music(cues: list[tuple[float, str]], total: float, out: str) -> None:
    """cues = [(start_sec, bed_path), ...] sorted; loop each bed across its span
    with short fades, concatenate to one chapter-length music track."""
    segs = []
    for i, (start, bed_path) in enumerate(cues):
        end = cues[i + 1][0] if i + 1 < len(cues) else total
        dur = max(1.0, end - start)
        last = i == len(cues) - 1
        fout = 8.0 if last else 1.5   # long cool-down on the final bed (the aftermath)
        fstart = max(0.3, dur - fout)
        seg = f"{OUT}/_seg{i}.mp3"
        subprocess.run(
            ["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-stream_loop", "-1",
             "-i", bed_path, "-t", f"{dur:.3f}",
             "-af", f"afade=t=in:st=0:d=1.2,afade=t=out:st={fstart:.3f}:d={fout}",
             "-c:a", "libmp3lame", "-b:a", "160k", seg], check=True)
        segs.append(seg)
    lst = f"{OUT}/_music_concat.txt"
    with open(lst, "w") as f:
        for s in segs:
            f.write(f"file '{os.path.abspath(s)}'\n")
    subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-f", "concat",
                    "-safe", "0", "-i", lst, "-c:a", "libmp3lame", "-b:a", "160k", out], check=True)


def score_chapter(ch: str, video_in: str, video_out: str, gain: float = 0.14) -> None:
    """Score one chapter from CHAPTER_CUES[ch]: a dominant-family bed per mood,
    each placed at its narration onset, built into a track that follows the
    dramatic build (calm -> tension -> action), ducked under George, muxed in."""
    spec = CHAPTER_CUES[ch]
    _rows, total = chapter_clock(ch)
    cues = []
    for kw, family, mood in spec:
        start = 0.0 if not kw else onset_time(ch, kw)
        cues.append((start, bed(family, mood, 60000), f"{family}/{mood}"))
    cues.sort(key=lambda c: c[0])
    print(f"{ch}: total {total:.0f}s; " + ", ".join(f"{m}@{round(s)}s" for s, _, m in cues))
    music = f"{OUT}/_music_{ch}.mp3"
    build_music([(s, b) for s, b, _ in cues], total, music)
    scored = f"{OUT}/_scored_{ch}.mp3"
    mix_under(f"{PERF}/{ch}.mp3", music, scored, gain=gain)
    subprocess.run(
        ["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", video_in, "-i", scored,
         "-map", "0:v", "-map", "1:a", "-c:v", "copy",
         "-c:a", "aac", "-ar", "48000", "-b:a", "160k", "-shortest",
         "-movflags", "+faststart", video_out], check=True)
    print(f"scored chapter -> {video_out}")


def mix_under(narration: str, bed_path: str, out: str, gain: float = 0.28) -> None:
    """Duck the bed under the narration: speech-band EQ carve + sidechain duck +
    low level, so the voice stays clear and the music is felt, not heard."""
    os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
    fc = (
        f"[1:a]aresample=44100,volume={gain},highpass=f=110,"
        "equalizer=f=1500:t=o:w=2.6:g=-8,equalizer=f=600:t=o:w=2:g=-4[bedeq];"
        "[0:a]aresample=44100,asplit=2[v0][vsc];"
        "[bedeq][vsc]sidechaincompress=threshold=0.025:ratio=8:attack=12:"
        "release=380:makeup=1[duck];"
        "[v0][duck]amix=inputs=2:duration=first:normalize=0[mix]")
    subprocess.run(
        ["ffmpeg", "-nostdin", "-loglevel", "error", "-y",
         "-i", narration, "-stream_loop", "-1", "-i", bed_path,
         "-filter_complex", fc, "-map", "[mix]",
         "-c:a", "libmp3lame", "-b:a", "160k", "-ar", "44100", out],
        check=True)
    print(f"mixed -> {out}")


def proof() -> None:
    home = bed("home", "warm")
    nguyen = bed("nguyen", "calm")
    # a homestead (American) narration slice and a Nguyen (ch3) slice
    perf = "stories/civil-war/performance"
    subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-ss", "8",
                    "-t", "24", "-i", f"{perf}/ch1.mp3", f"{OUT}/_slice_home.mp3"], check=True)
    subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-ss", "6",
                    "-t", "24", "-i", f"{perf}/ch3.mp3", f"{OUT}/_slice_nguyen.mp3"], check=True)
    mix_under(f"{OUT}/_slice_home.mp3", home, f"{OUT}/PROOF_american-home_under-narration.mp3")
    mix_under(f"{OUT}/_slice_nguyen.mp3", nguyen, f"{OUT}/PROOF_vietnamese_under-narration.mp3")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "proof"
    if cmd == "bed":
        bed(sys.argv[2], sys.argv[3] if len(sys.argv) > 3 else "calm")
    elif cmd == "mix":
        mix_under(sys.argv[3], sys.argv[2], sys.argv[4])
    elif cmd == "chapter":  # chapter <ch> <video_in> <video_out>
        score_chapter(sys.argv[2], sys.argv[3], sys.argv[4])
    elif cmd == "proof":
        proof()
