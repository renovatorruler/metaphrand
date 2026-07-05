"""INDIVISIBLE opening title sequence — aged map Ken Burns + title reveal + sting.

  map   : antique Civil War US map (Replicate google/nano-banana-pro)
  music : original cinematic sting (Replicate meta/musicgen)
  build : ffmpeg Ken Burns over the map -> INDIVISIBLE title reveal, sting under it

    python -m examples.title_seq map
    python -m examples.title_seq music
    python -m examples.title_seq build
"""
import json
import os
import sys
import time
import urllib.request
import urllib.error

OUT = "stories/civil-war/title"
TOKEN = open(os.path.expanduser("~/.replicate_api_key")).read().strip()


def _post(url, body, wait=True):
    headers = {"Authorization": f"Bearer {TOKEN}", "Content-Type": "application/json"}
    if wait:
        headers["Prefer"] = "wait"
    req = urllib.request.Request(url, headers=headers, data=json.dumps(body).encode())
    for a in range(6):
        try:
            with urllib.request.urlopen(req, timeout=300) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            if e.code == 429 and a < 5:
                time.sleep(10 * (a + 1))
                continue
            raise RuntimeError(f"{e.code}: {e.read()[:200]!r}") from e


def _poll(pred):
    url = pred["urls"]["get"]
    while pred.get("status") in ("starting", "processing"):
        time.sleep(3)
        req = urllib.request.Request(url, headers={"Authorization": f"Bearer {TOKEN}"})
        with urllib.request.urlopen(req, timeout=60) as r:
            pred = json.load(r)
    return pred


def _fetch(url, path):
    data = urllib.request.urlopen(url, timeout=180).read()
    os.makedirs(OUT, exist_ok=True)
    open(path, "wb").write(data)


def gen_map():
    prompt = (
        "A genuine antique 1862 American Civil War era map of the United States, "
        "hand-engraved steel-plate cartography on aged sepia parchment, the divided "
        "northern and southern states lightly shaded in faded slate-blue and ochre, an "
        "ornate compass rose, rivers, county and state borders, small engraved serif "
        "place names, a decorative engraved border, foxed weathered paper with worn "
        "creases, archival lithograph, warm candlelit tone. Antique map only — no modern "
        "elements, no people.")
    body = {"input": {"prompt": prompt, "aspect_ratio": "16:9", "output_format": "png"}}
    pred = _post("https://api.replicate.com/v1/models/google/nano-banana-pro/predictions", body)
    if pred.get("status") != "succeeded":
        pred = _poll(pred)
    out = pred["output"]
    _fetch(out if isinstance(out, str) else out[0], f"{OUT}/map.png")
    print("map saved ->", f"{OUT}/map.png")


def gen_music():
    # Modern, NOT period — signal up front this isn't a Civil War documentary.
    prompt = (
        "Modern cinematic title sting, contemporary and tense, NOT period and no orchestra. "
        "A lone clean electric guitar with deep reverb over a low pulsing analog synth bass "
        "and a subtle electronic heartbeat, building to one resonant hit, then a held "
        "atmospheric chord. Anticipatory, modern Americana, restrained, instrumental, no "
        "drum kit, no strings section.")
    key = open(os.path.expanduser("~/.elevenlabs_api_key")).read().strip()
    body = {"prompt": prompt, "music_length_ms": 11000, "model_id": "music_v1",
            "force_instrumental": True}
    req = urllib.request.Request(
        "https://api.elevenlabs.io/v1/music?output_format=mp3_44100_128",
        headers={"xi-api-key": key, "Content-Type": "application/json"},
        data=json.dumps(body).encode())
    os.makedirs(OUT, exist_ok=True)
    with urllib.request.urlopen(req, timeout=300) as r:
        open(f"{OUT}/sting.mp3", "wb").write(r.read())
    print("music saved (elevenlabs, modern) ->", f"{OUT}/sting.mp3")


def _res():
    return tuple(int(x) for x in os.environ.get("RES", "1920x1080").split("x"))


def gen_title():
    from PIL import Image, ImageDraw, ImageFont, ImageFilter
    W, H = _res()
    s = H / 1080.0
    font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Didot.ttc", int(158 * s))
    word = "INDIVISIBLE"
    track = int(158 * s * 0.24)
    probe = ImageDraw.Draw(Image.new("RGBA", (10, 10)))
    widths = [probe.textbbox((0, 0), c, font=font)[2] for c in word]
    total = sum(widths) + track * (len(word) - 1)
    x0 = (W - total) // 2
    y = H // 2 - int(95 * s)
    cream = (236, 226, 206, 255)

    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ds = ImageDraw.Draw(shadow)
    cx = x0
    for c, w in zip(word, widths):
        ds.text((cx + int(4 * s), y + int(6 * s)), c, font=font, fill=(0, 0, 0, 200))
        cx += w + track
    img = Image.alpha_composite(img, shadow.filter(ImageFilter.GaussianBlur(int(7 * s))))

    d = ImageDraw.Draw(img)
    cx = x0
    for c, w in zip(word, widths):
        d.text((cx, y), c, font=font, fill=cream)
        cx += w + track
    rule_w = int(total * 0.66)
    rx = (W - rule_w) // 2
    for ry in (y - int(46 * s), y + int(212 * s)):
        d.line([(rx, ry), (rx + rule_w, ry)], fill=(236, 226, 206, 210), width=max(2, int(2 * s)))
    os.makedirs(OUT, exist_ok=True)
    img.save(f"{OUT}/title.png")
    print(f"title saved ({W}x{H}) ->", f"{OUT}/title.png")


def build():
    import subprocess
    W, H = _res()
    vf = (
        f"[0:v]scale={W*2}:{H*2},zoompan=z='min(1.05+0.025*on/30\\,1.32)':"
        "x='iw/2-(iw/zoom/2)+(on/300-0.5)*260':y='ih/2-(ih/zoom/2)+(0.5-on/300)*150':"
        f"d=300:fps=30:s={W}x{H},setsar=1[kb];"
        f"color=c=black:s={W}x{H}:r=30:d=10,format=rgba,colorchannelmixer=aa=0.58,"
        "fade=t=in:st=4.8:d=1.8:alpha=1[blk];"
        "[1:v]format=rgba,fade=t=in:st=5.4:d=1.6:alpha=1[ttl];"
        "[kb][blk]overlay=eval=frame[d1];"
        "[d1][ttl]overlay=eval=frame[c0];"
        "[c0]fade=t=out:st=9.2:d=0.8[v]")
    out = f"{OUT}/INDIVISIBLE_title.mp4"
    cmd = ["ffmpeg", "-y", "-loglevel", "error",
           "-loop", "1", "-t", "10", "-i", f"{OUT}/map.png",
           "-loop", "1", "-t", "10", "-i", f"{OUT}/title.png",
           "-i", f"{OUT}/sting.mp3",
           "-filter_complex", vf, "-map", "[v]", "-map", "2:a",
           "-af", "afade=t=in:st=0:d=0.6,afade=t=out:st=8.8:d=1.4",
           "-t", "10", "-r", "30", "-c:v", "libx264", "-pix_fmt", "yuv420p", "-crf", "18",
           "-c:a", "aac", "-ar", "48000", "-b:a", "192k", "-movflags", "+faststart", out]
    subprocess.run(cmd, check=True)
    print("built ->", out)


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "map"
    {"map": gen_map, "music": gen_music, "title": gen_title, "build": build}[cmd]()
