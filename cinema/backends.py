"""cinema.backends — the shared API layer. Story-agnostic.

One place for every external call so the rest of the engine never re-implements
HTTP, keys, retries, or model IDs. Keys: ~/.replicate_api_key, ~/.elevenlabs_api_key.
"""
from __future__ import annotations

import base64
import json
import os
import subprocess
import time
import urllib.error
import urllib.request

# Pinned model identities (the only place they live).
IMG_PRO = "google/nano-banana-pro"
IMG_FAST = "google/nano-banana"
SEEDANCE = "a5fd550893da3b6f67997812759065652454ddaca10e96b83b59cbae1814cb36"   # image->video
TRELLIS = "e8f6c45206993f297372f5436b90350817bd9b4a0d52d2a76df50c1c8afa2b3c"    # image->3D
MUSICGEN = "671ac645ce5e552cc63a54a2bbff63fcf798043055d2dac5fc9e36a837eedcfb"   # fallback music


def _key(path: str) -> str:
    return open(os.path.expanduser(path)).read().strip()


def save_png(path: str, data: bytes) -> str:
    """Normalize image bytes (Google sometimes returns JPEG) to a real PNG on disk."""
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    if data[:2] == b"\xff\xd8":
        import io
        from PIL import Image
        Image.open(io.BytesIO(data)).save(path, "PNG")
    else:
        open(path, "wb").write(data)
    return path


def _data_uri(path: str) -> str:
    mime = "image/png" if path.lower().endswith(".png") else "image/jpeg"
    return f"data:{mime};base64," + base64.b64encode(open(path, "rb").read()).decode()


def _jpeg(path: str, maxdim: int = 1280) -> str:
    from PIL import Image
    im = Image.open(path).convert("RGB")
    im.thumbnail((maxdim, maxdim))
    out = path + ".tmp.jpg"
    im.save(out, quality=92)
    return out


# ----------------------------------------------------------------- Replicate
def _poll(token: str, pred: dict) -> dict:
    url = pred["urls"]["get"]
    while pred.get("status") in ("starting", "processing"):
        time.sleep(4)
        req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
        with urllib.request.urlopen(req, timeout=60) as r:
            pred = json.load(r)
    return pred


def replicate_run(version: str, inp: dict):
    """Generic version-pinned Replicate prediction -> output object."""
    token = _key("~/.replicate_api_key")
    req = urllib.request.Request(
        "https://api.replicate.com/v1/predictions",
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json"},
        data=json.dumps({"version": version, "input": inp}).encode())
    pred = _poll(token, json.load(urllib.request.urlopen(req, timeout=120)))
    if pred.get("status") != "succeeded":
        raise RuntimeError(f"replicate {pred.get('status')}: {str(pred.get('error'))[:200]}")
    return pred["output"]


def image(prompt: str, refs: list[str] | None = None, pro: bool = True,
          aspect: str = "16:9") -> bytes:
    """Text (+ optional reference images) -> image via Replicate-hosted Google model."""
    token = _key("~/.replicate_api_key")
    slug = IMG_PRO if pro else IMG_FAST
    body = {"input": {"prompt": prompt, "aspect_ratio": aspect, "output_format": "png"}}
    if refs:
        body["input"]["image_input"] = [_data_uri(r) for r in refs]
    out = None
    for a in range(6):
        req = urllib.request.Request(
            f"https://api.replicate.com/v1/models/{slug}/predictions",
            headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json",
                     "Prefer": "wait"}, data=json.dumps(body).encode())
        try:
            with urllib.request.urlopen(req, timeout=300) as r:
                pred = json.load(r)
        except urllib.error.HTTPError as e:
            if e.code == 429 and a < 5:
                time.sleep(12 * (a + 1))
                continue
            raise RuntimeError(f"image HTTP {e.code}: {e.read()[:200]!r}") from e
        if pred.get("status") != "succeeded":
            pred = _poll(token, pred)
        out = pred.get("output")
        if out:
            break
        if a < 5:               # transient prediction failure ("interrupted; retry", code PA)
            time.sleep(6 * (a + 1))
            continue
        raise RuntimeError(f"image failed: status={pred.get('status')} "
                           f"error={str(pred.get('error'))[:300]}")
    url = out if isinstance(out, str) else out[0]
    return urllib.request.urlopen(url, timeout=180).read()


def image_to_video(image_path: str, prompt: str, seconds: int = 5,
                   camera_fixed: bool = True, last_frame: str | None = None) -> bytes:
    """Animate a still (Seedance). camera_fixed keeps composition; last_frame pins the end."""
    inp = {"image": _data_uri(_jpeg(image_path)), "prompt": prompt, "duration": seconds,
           "resolution": "1080p", "fps": 24, "camera_fixed": camera_fixed}
    if last_frame:
        inp["last_frame_image"] = _data_uri(_jpeg(last_frame))
    out = replicate_run(SEEDANCE, inp)
    url = out if isinstance(out, str) else (out[0] if isinstance(out, list) else out.get("video"))
    return urllib.request.urlopen(url, timeout=300).read()


def veo_video(image_path: str, prompt: str, model: str = "google/veo-3.1-fast",
              resolution: str = "720p") -> bytes:
    """Image-to-video via Google Veo 3.1 (Replicate). Higher motion quality than Seedance and
    generates native audio; describe the MOTION, not the static image."""
    token = _key("~/.replicate_api_key")
    inp = {"prompt": prompt, "image": _data_uri(_jpeg(image_path)), "resolution": resolution}
    req = urllib.request.Request(
        f"https://api.replicate.com/v1/models/{model}/predictions",
        headers={"Authorization": f"Bearer {token}", "Content-Type": "application/json",
                 "Prefer": "wait"}, data=json.dumps({"input": inp}).encode())
    with urllib.request.urlopen(req, timeout=600) as r:
        pred = json.load(r)
    if pred.get("status") not in ("succeeded", "failed", "canceled"):
        pred = _poll(token, pred)
    out = pred.get("output")
    if not out:
        raise RuntimeError(f"veo failed: {pred.get('status')} {str(pred.get('error'))[:300]}")
    url = out if isinstance(out, str) else (out[0] if isinstance(out, list) else out.get("video"))
    return urllib.request.urlopen(url, timeout=600).read()


def image_to_3d(image_path: str) -> bytes:
    """Single image -> textured GLB mesh (TRELLIS). Best on a clean single-object hero."""
    out = replicate_run(TRELLIS, {"images": [_data_uri(image_path)], "generate_model": True,
                                  "generate_color": False, "texture_size": 1024,
                                  "mesh_simplify": 0.9, "ss_sampling_steps": 12,
                                  "slat_sampling_steps": 12})
    url = out["model_file"] if isinstance(out, dict) else (out if isinstance(out, str) else out[0])
    return urllib.request.urlopen(url, timeout=300).read()


# ----------------------------------------------------------------- ElevenLabs
def elevenlabs_dialogue(inputs: list[dict], model: str = "eleven_v3",
                        fmt: str = "mp3_44100_128") -> bytes:
    """Multi-speaker continuous take: inputs = [{text, voice_id}, ...]."""
    key = _key("~/.elevenlabs_api_key")
    req = urllib.request.Request(
        f"https://api.elevenlabs.io/v1/text-to-dialogue?output_format={fmt}",
        headers={"xi-api-key": key, "Content-Type": "application/json"},
        data=json.dumps({"inputs": inputs, "model_id": model}).encode())
    with urllib.request.urlopen(req, timeout=300) as r:
        return r.read()


def elevenlabs_tts(text: str, voice_id: str, model: str = "eleven_v3",
                   fmt: str = "mp3_44100_128") -> bytes:
    """Single-voice take with v3 expression tags — one narrator performs everything."""
    key = _key("~/.elevenlabs_api_key")
    req = urllib.request.Request(
        f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}?output_format={fmt}",
        headers={"xi-api-key": key, "Content-Type": "application/json"},
        data=json.dumps({"text": text, "model_id": model}).encode())
    with urllib.request.urlopen(req, timeout=300) as r:
        return r.read()


def elevenlabs_music(prompt: str, ms: int, instrumental: bool = True) -> bytes:
    """Instrumental score bed (ElevenLabs Music). NB: naming a real artist -> ToS 400."""
    key = _key("~/.elevenlabs_api_key")
    req = urllib.request.Request(
        "https://api.elevenlabs.io/v1/music?output_format=mp3_44100_128",
        headers={"xi-api-key": key, "Content-Type": "application/json"},
        data=json.dumps({"prompt": prompt, "music_length_ms": ms, "model_id": "music_v1",
                         "force_instrumental": instrumental}).encode())
    with urllib.request.urlopen(req, timeout=300) as r:
        return r.read()


# ----------------------------------------------------------------- audio utils
def duration(path: str) -> float:
    """Exact duration by decode (mp3 header estimates drift and desync the video)."""
    import re
    p = subprocess.run(["ffmpeg", "-nostdin", "-i", path, "-f", "null", "-"],
                       capture_output=True, text=True)
    h, m, s = re.findall(r"time=(\d+):(\d+):(\d+\.\d+)", p.stderr)[-1]
    return int(h) * 3600 + int(m) * 60 + float(s)


def concat_audio(files: list[str], out: str, bitrate: str = "96k") -> str:
    lst = out + ".concat.txt"
    with open(lst, "w") as f:
        for p in files:
            f.write(f"file '{os.path.abspath(p)}'\n")
    subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-f", "concat",
                    "-safe", "0", "-i", lst, "-codec:a", "libmp3lame", "-b:a", bitrate,
                    "-ac", "1", out], check=True)
    os.remove(lst)
    return out


def silence(ms: int, cache: str) -> str:
    path = f"{cache}/silence_{ms}.mp3"
    if not os.path.exists(path):
        subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-f", "lavfi",
                        "-i", "anullsrc=r=44100:cl=mono", "-t", f"{ms/1000:.3f}",
                        "-codec:a", "libmp3lame", "-b:a", "128k", path], check=True)
    return path
