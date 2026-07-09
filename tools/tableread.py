#!/usr/bin/env python
"""Table read renderer — data-driven (one driver for every scene).

Reads a performance JSON:
  cast:  {ROLE: {voice, voice_id}}
  beats: [{caption, lines:[{role,text}],
           panel: {"gen": prompt} | {"reuse": "path.png"} | {"insert": [lines]} | {"title": text}}]

Per beat: one ElevenLabs v3 dialogue take (digest-cached), one ink panel
(gen results cached on disk), caption box composited locally. Assembles MP4.

Run: PYTHONPATH=/Users/dusty/dev/metaphrand \
     .venv/bin/python tools/tableread.py stories/four-olds/tableread/performance_sc02.json
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

INK = ("Black-and-white brush-ink graphic novel panel, heavy expressive linework, "
       "flat gray screentone shading, deep blacks, dramatic cinematic composition. "
       "No text, no lettering, no captions, no speech bubbles, no watermarks. ")

SIZE = (1920, 1080)


def _font(px: int):
    from PIL import ImageFont
    try:
        return ImageFont.truetype(
            "/System/Library/Fonts/Supplemental/Courier New Bold.ttf", px)
    except OSError:
        return ImageFont.load_default()


def caption_panel(png_path: str, caption: str) -> str:
    from PIL import Image, ImageDraw
    img = Image.open(png_path).convert("RGB").resize(SIZE)
    d = ImageDraw.Draw(img)
    font = _font(34)
    pad = 16
    text = caption.upper()
    bbox = d.textbbox((0, 0), text, font=font)
    w, h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    d.rectangle([28, 28, 28 + w + pad * 2, 28 + h + pad * 2], fill=(12, 12, 12))
    d.text((28 + pad, 28 + pad - bbox[1]), text, font=font, fill=(240, 240, 240))
    out = png_path.replace(".png", "_cap.png")
    img.save(out)
    return out


def title_card(text: str, path: str) -> str:
    from PIL import Image, ImageDraw
    img = Image.new("RGB", SIZE, (0, 0, 0))
    d = ImageDraw.Draw(img)
    font = _font(120)
    bbox = d.textbbox((0, 0), text, font=font)
    d.text(((SIZE[0] - bbox[2]) / 2, (SIZE[1] - bbox[3]) / 2), text,
           font=font, fill=(235, 235, 235))
    img.save(path)
    return path


def insert_card(lines: list[str], path: str) -> str:
    """A typeset readout panel (database rows, documents) — no generation."""
    from PIL import Image, ImageDraw
    img = Image.new("RGB", SIZE, (8, 10, 8))
    d = ImageDraw.Draw(img)
    font = _font(56)
    y = SIZE[1] // 2 - (len(lines) * 84) // 2
    for ln in lines:
        bbox = d.textbbox((0, 0), ln, font=font)
        d.text(((SIZE[0] - bbox[2]) / 2, y), ln, font=font, fill=(190, 235, 190))
        y += 84
    img.save(path)
    return path


def main() -> int:
    perf_path = sys.argv[1]
    perf = json.load(open(perf_path))
    base = os.path.dirname(os.path.abspath(perf_path))
    slug = os.path.splitext(os.path.basename(perf_path))[0].replace("performance_", "")
    panels = os.path.join(base, "panels")
    segs = os.path.join(base, f"segs_{slug}")
    os.makedirs(panels, exist_ok=True)
    os.makedirs(segs, exist_ok=True)
    cast = perf["cast"]

    seg_files = []
    for n, beat in enumerate(perf["beats"]):
        p = beat["panel"]
        if "title" in p:
            panel = title_card(p["title"], os.path.join(panels, f"{slug}_{n:02}_title.png"))
        elif "insert" in p:
            panel = insert_card(p["insert"], os.path.join(panels, f"{slug}_{n:02}_ins.png"))
            panel = caption_panel(panel, beat["caption"])
        elif "reuse" in p:
            panel = caption_panel(os.path.join(panels, p["reuse"]), beat["caption"])
        else:
            raw = os.path.join(panels, f"{slug}_{n:02}.png")
            if not os.path.exists(raw):
                print(f"gen panel {n}: {beat['caption']}")
                refs = [os.path.join(base, r) for r in p["refs"]] if p.get("refs") else None
                bk.save_png(raw, bk.image(INK + p["gen"], refs=refs,
                                           pro=p.get("pro", False), aspect="16:9"))
            panel = caption_panel(raw, beat["caption"])

        lines = beat.get("lines", [])
        if lines and any(l.get("fx") for l in lines):
            # per-line mode: lines with fx (e.g. radio) are synthesized solo,
            # filtered, then stitched with the rest in order.
            digest_src = [{**l, "voice_id": cast[l["role"]]["voice_id"]} for l in lines]
            digest = hashlib.sha1(json.dumps(digest_src, sort_keys=True).encode()).hexdigest()[:12]
            audio = os.path.join(segs, f"seg{n:02}_{digest}.mp3")
            if not os.path.exists(audio):
                print(f"beat {n}: {len(lines)} lines -> per-line takes (fx)")
                parts = []
                for i, l in enumerate(lines):
                    raw = os.path.join(segs, f"b{n:02}_l{i:02}_{digest}.mp3")
                    open(raw, "wb").write(
                        bk.elevenlabs_tts(l["text"], cast[l["role"]]["voice_id"],
                                          model=perf.get("model_id", "eleven_v3")))
                    if l.get("fx") == "radio":
                        fx = raw.replace(".mp3", "_fx.mp3")
                        subprocess.run(
                            ["ffmpeg", "-y", "-loglevel", "error", "-i", raw, "-af",
                             "highpass=f=320,lowpass=f=3200,acompressor=threshold=-18dB:"
                             "ratio=4,volume=4dB", fx], check=True)
                        raw = fx
                    parts.append(raw)
                lst_a = os.path.join(segs, f"b{n:02}_parts.txt")
                with open(lst_a, "w") as f:
                    for p in parts:
                        f.write(f"file '{p}'\n")
                subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "concat",
                                "-safe", "0", "-i", lst_a, "-af", "apad=pad_dur=0.25",
                                audio], check=True)
            else:
                print(f"beat {n}: cached")
        elif lines:
            inputs = [{"text": l["text"], "voice_id": cast[l["role"]]["voice_id"]}
                      for l in lines]
            digest = hashlib.sha1(json.dumps(inputs, sort_keys=True).encode()).hexdigest()[:12]
            audio = os.path.join(segs, f"seg{n:02}_{digest}.mp3")
            if not os.path.exists(audio):
                print(f"beat {n}: {len(inputs)} lines -> v3 take")
                open(audio, "wb").write(
                    bk.elevenlabs_dialogue(inputs, model=perf.get("model_id", "eleven_v3")))
            else:
                print(f"beat {n}: cached")
        else:
            audio = os.path.join(segs, f"seg{n:02}.wav")
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "lavfi",
                            "-i", "anullsrc=r=44100:cl=mono", "-t", "3", audio], check=True)

        seg = os.path.join(segs, f"seg{n:02}.mp4")
        subprocess.run(
            ["ffmpeg", "-y", "-loglevel", "error", "-loop", "1", "-i", panel,
             "-i", audio, "-c:v", "libx264", "-tune", "stillimage", "-r", "24",
             "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "160k",
             "-af", "apad=pad_dur=0.6", "-shortest", seg], check=True)
        seg_files.append(seg)

    lst = os.path.join(segs, "list.txt")
    with open(lst, "w") as f:
        for s in seg_files:
            f.write(f"file '{s}'\n")
    stamp = datetime.now().strftime("%Y-%m-%d_%H%M")
    final = os.path.join(base, f"TABLEREAD_{slug}_{stamp}.mp4")
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-f", "concat", "-safe", "0",
                    "-i", lst, "-c:v", "copy", "-c:a", "aac", "-b:a", "160k", final],
                   check=True)
    print("OUT:", final)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
