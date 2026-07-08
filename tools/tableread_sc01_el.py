#!/usr/bin/env python
"""Table read, cold open — ElevenLabs v3 with expression tags.

Reads the hand-authored performance JSON (the maintained artifact), renders
each beat as ONE continuous v3 dialogue take (the cast plays off each other),
reuses the cached ink panels, assembles the MP4. Takes are digest-cached:
re-runs only pay for beats whose lines changed.

Run: PYTHONPATH=/Users/dusty/dev/metaphrand \
     /Users/dusty/dev/metaphrand/.venv/bin/python tools/tableread_sc01_el.py
"""
from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
from datetime import datetime

sys.path.insert(0, "/Users/dusty/dev/metaphrand")
from cinema import backends as bk  # noqa: E402

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(HERE, "stories/four-olds/tableread")
PANELS = os.path.join(OUT, "panels")
SEGS = os.path.join(OUT, "segs_el")
os.makedirs(SEGS, exist_ok=True)

# panel captioning + title card from the pilot driver
sys.path.insert(0, os.path.join(HERE, "tools"))
from tableread_sc01 import caption_panel, title_card  # noqa: E402


def main() -> int:
    perf = json.load(open(os.path.join(OUT, "performance_sc01.json")))
    cast = perf["cast"]
    seg_files = []

    for n, beat in enumerate(perf["beats"]):
        seg = os.path.join(SEGS, f"seg{n:02}.mp4")
        if beat["caption"] == "__TITLE__":
            panel = title_card(beat["text"], os.path.join(PANELS, f"el{n:02}_title.png"))
            audio = os.path.join(SEGS, f"seg{n:02}.wav")
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "lavfi",
                            "-i", "anullsrc=r=44100:cl=mono", "-t", "3", audio], check=True)
        else:
            panel = caption_panel(os.path.join(PANELS, beat["panel"]), beat["caption"])
            inputs = [{"text": l["text"], "voice_id": cast[l["role"]]["voice_id"]}
                      for l in beat["lines"]]
            digest = hashlib.sha1(json.dumps(inputs, sort_keys=True).encode()).hexdigest()[:12]
            audio = os.path.join(SEGS, f"seg{n:02}_{digest}.mp3")
            if not os.path.exists(audio):
                print(f"beat {n}: {len(inputs)} lines -> v3 dialogue take")
                data = bk.elevenlabs_dialogue(inputs, model=perf["model_id"])
                open(audio, "wb").write(data)
            else:
                print(f"beat {n}: cached")
        subprocess.run(
            ["ffmpeg", "-y", "-loglevel", "error", "-loop", "1", "-i", panel,
             "-i", audio, "-c:v", "libx264", "-tune", "stillimage", "-r", "24",
             "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "160k",
             "-af", "apad=pad_dur=0.6", "-shortest", seg],
            check=True)
        seg_files.append(seg)

    lst = os.path.join(SEGS, "list.txt")
    with open(lst, "w") as f:
        for s in seg_files:
            f.write(f"file '{s}'\n")
    stamp = datetime.now().strftime("%Y-%m-%d_%H%M")
    final = os.path.join(OUT, f"TABLEREAD_cold-open_ElevenLabs_{stamp}_v2.mp4")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "concat", "-safe", "0",
                    "-i", lst, "-c:v", "copy", "-c:a", "aac", "-b:a", "160k", final],
                   check=True)
    print("OUT:", final)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
