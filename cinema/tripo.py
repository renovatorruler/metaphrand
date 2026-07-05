"""Tripo3D image-to-3D client (cinema layer).

Turns a clean still into a textured 3D mesh (.glb) we can re-light and re-angle
in Blender — i.e. pull NEW camera shots of a subject we only have one frame of.
Best on a single clear subject on a plain-ish background (character sheet
portraits, props, vehicles); not whole multi-character lit scenes.

Key: ~/.tripo_api_key.  Flow:
    tok = upload("ratan.png")
    tid = image_to_model(tok)        # or from_image("ratan.png")
    data = wait(tid)                 # blocks, polls until success
    fetch_outputs(data, "out/ratan", stem="ratan")   # downloads .glb + preview

Each task costs Tripo credits (check balance()).  Output dict ['output'] carries
model URLs: 'pbr_model' / 'model' (GLB), 'base_model', 'rendered_image' (preview).
"""
import os, time, urllib.request
import requests

BASE = "https://api.tripo3d.ai/v2/openapi"
TERMINAL_BAD = {"failed", "banned", "expired", "cancelled", "unknown"}


def _key():
    return open(os.path.expanduser("~/.tripo_api_key")).read().strip()

def _hdr(json=False):
    h = {"Authorization": f"Bearer {_key()}"}
    if json:
        h["Content-Type"] = "application/json"
    return h

def balance():
    r = requests.get(f"{BASE}/user/balance", headers=_hdr(), timeout=30)
    r.raise_for_status()
    return r.json()["data"]

def _img_type(path):
    e = os.path.splitext(path)[1].lower().lstrip(".")
    return {"jpeg": "jpg"}.get(e, e) or "png"

def upload(path):
    """Upload a local image; return its image_token."""
    with open(path, "rb") as f:
        r = requests.post(f"{BASE}/upload/sts", headers=_hdr(), files={"file": f}, timeout=180)
    r.raise_for_status()
    d = r.json()
    assert d.get("code") == 0, d
    return d["data"]["image_token"]

def image_to_model(image_token, image_type="png", *, texture=True, pbr=True,
                   texture_quality="detailed", **opts):
    """Create an image_to_model task; return task_id. Extra Tripo opts via **opts
    (e.g. face_limit=, model_version=, auto_size=True, orientation='align_image')."""
    body = {"type": "image_to_model",
            "file": {"type": image_type, "file_token": image_token},
            "texture": texture, "pbr": pbr, "texture_quality": texture_quality}
    body.update(opts)
    r = requests.post(f"{BASE}/task", headers=_hdr(json=True), json=body, timeout=60)
    r.raise_for_status()
    d = r.json()
    assert d.get("code") == 0, d
    return d["data"]["task_id"]

def from_image(path, **opts):
    """upload + image_to_model in one call."""
    return image_to_model(upload(path), image_type=_img_type(path), **opts)

def multiview_to_model(tokens, image_type="png", *, texture=True, pbr=True,
                       texture_quality="detailed", **opts):
    """Create a multiview_to_model task from 4 view tokens; return task_id.
    `tokens` is a dict with keys front/left/back/right (missing -> empty), or a
    list in that order. A real back/side view kills the single-image hallucination."""
    if isinstance(tokens, dict):
        order = [tokens.get(k) for k in ("front", "left", "back", "right")]
    else:
        order = list(tokens)
    files = [{"type": image_type, "file_token": t} if t else {} for t in order]
    body = {"type": "multiview_to_model", "files": files,
            "texture": texture, "pbr": pbr, "texture_quality": texture_quality}
    body.update(opts)
    r = requests.post(f"{BASE}/task", headers=_hdr(json=True), json=body, timeout=60)
    r.raise_for_status()
    d = r.json()
    assert d.get("code") == 0, d
    return d["data"]["task_id"]

def status(task_id):
    r = requests.get(f"{BASE}/task/{task_id}", headers=_hdr(), timeout=60)
    r.raise_for_status()
    return r.json()["data"]

def wait(task_id, timeout=1200, every=5):
    """Poll until success; return the finished task data dict (has ['output'])."""
    t0 = time.time()
    while True:
        d = status(task_id)
        st = d.get("status")
        print(f"  tripo {task_id[:8]} {st} {d.get('progress')}%", flush=True)
        if st == "success":
            return d
        if st in TERMINAL_BAD:
            raise RuntimeError(f"tripo task {st}: {d}")
        if time.time() - t0 > timeout:
            raise TimeoutError(f"tripo task {task_id} timed out")
        time.sleep(every)

def download(url, out):
    os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
    urllib.request.urlretrieve(url, out)
    return out

def fetch_outputs(data, outdir, stem="model"):
    """Download every model/preview URL from a finished task's output dict."""
    os.makedirs(outdir, exist_ok=True)
    ext = {"pbr_model": "glb", "model": "glb", "base_model": "glb", "rendered_image": "webp"}
    saved = {}
    for k, url in (data.get("output") or {}).items():
        if isinstance(url, str) and url.startswith("http"):
            saved[k] = download(url, f"{outdir}/{stem}_{k}.{ext.get(k, 'bin')}")
    return saved
