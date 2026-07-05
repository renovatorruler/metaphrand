"""Upload a video to YouTube as UNLISTED via the OAuth 2.0 device flow.

Device flow = made for "you're on a device, approve on your phone". `auth`
prints a short code + URL and waits; you open the URL on your phone, sign in,
enter the code, approve. Tokens are cached; `upload` then pushes the file.

  python -m examples.youtube_upload auth
  python -m examples.youtube_upload upload <file> "<title>" "<description>"

Client id/secret in ~/.youtube_oauth.json; tokens cached in ~/.youtube_tokens.json.
"""
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

OAUTH = json.load(open(os.path.expanduser("~/.youtube_oauth.json")))
CID, CSEC = OAUTH["client_id"], OAUTH["client_secret"]
TOKENS = os.path.expanduser("~/.youtube_tokens.json")
SCOPE = "https://www.googleapis.com/auth/youtube.upload"


def _post_form(url: str, data: dict) -> dict:
    req = urllib.request.Request(
        url, data=urllib.parse.urlencode(data).encode(),
        headers={"Content-Type": "application/x-www-form-urlencoded"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        return json.loads(e.read().decode())


def auth() -> None:
    d = _post_form("https://oauth2.googleapis.com/device/code",
                   {"client_id": CID, "scope": SCOPE})
    if "device_code" not in d:
        raise RuntimeError(f"device/code failed: {d}")
    print("VERIFICATION_URL:", d.get("verification_url") or d.get("verification_uri"), flush=True)
    print("USER_CODE:", d["user_code"], flush=True)
    print("(polling for approval — approve on your phone)", flush=True)
    interval = d.get("interval", 5)
    deadline = time.time() + d.get("expires_in", 1800)
    while time.time() < deadline:
        time.sleep(interval)
        t = _post_form("https://oauth2.googleapis.com/token", {
            "client_id": CID, "client_secret": CSEC, "device_code": d["device_code"],
            "grant_type": "urn:ietf:params:oauth:grant-type:device_code"})
        if "access_token" in t:
            json.dump(t, open(TOKENS, "w"))
            os.chmod(TOKENS, 0o600)
            print("AUTHORIZED", flush=True)
            return
        if t.get("error") == "authorization_pending":
            continue
        if t.get("error") == "slow_down":
            interval += 5
            continue
        raise RuntimeError(f"auth failed: {t}")
    raise RuntimeError("device code expired before approval")


def _access_token() -> str:
    t = json.load(open(TOKENS))
    r = _post_form("https://oauth2.googleapis.com/token", {
        "client_id": CID, "client_secret": CSEC,
        "refresh_token": t["refresh_token"], "grant_type": "refresh_token"})
    if "access_token" not in r:
        raise RuntimeError(f"refresh failed: {r}")
    return r["access_token"]


def upload(path: str, title: str, desc: str) -> None:
    tok = _access_token()
    meta = {"snippet": {"title": title, "description": desc, "categoryId": "1"},
            "status": {"privacyStatus": "unlisted", "selfDeclaredMadeForKids": False}}
    size = os.path.getsize(path)
    init = urllib.request.Request(
        "https://www.googleapis.com/upload/youtube/v3/videos"
        "?uploadType=resumable&part=snippet,status",
        data=json.dumps(meta).encode(),
        headers={"Authorization": f"Bearer {tok}",
                 "Content-Type": "application/json; charset=UTF-8",
                 "X-Upload-Content-Length": str(size),
                 "X-Upload-Content-Type": "video/*"})
    with urllib.request.urlopen(init, timeout=60) as r:
        session = r.headers["Location"]
    print(f"uploading {size/1e6:.0f} MB ...", flush=True)
    put = urllib.request.Request(
        session, data=open(path, "rb").read(), method="PUT",
        headers={"Authorization": f"Bearer {tok}", "Content-Type": "video/*",
                 "Content-Length": str(size)})
    with urllib.request.urlopen(put, timeout=3600) as r:
        res = json.load(r)
    vid = res["id"]
    print("VIDEO_ID:", vid, flush=True)
    print("URL:", f"https://youtu.be/{vid}", flush=True)
    print("STUDIO:", f"https://studio.youtube.com/video/{vid}/edit", flush=True)


def thumbnail(video_id: str, path: str) -> None:
    tok = _access_token()
    ct = "image/png" if path.lower().endswith(".png") else "image/jpeg"
    data = open(path, "rb").read()
    req = urllib.request.Request(
        f"https://www.googleapis.com/upload/youtube/v3/thumbnails/set?videoId={video_id}",
        data=data, method="POST",
        headers={"Authorization": f"Bearer {tok}", "Content-Type": ct,
                 "Content-Length": str(len(data))})
    try:
        with urllib.request.urlopen(req, timeout=120) as r:
            json.load(r)
        print("THUMBNAIL SET", flush=True)
    except urllib.error.HTTPError as e:
        print("THUMBNAIL FAILED", e.code, e.read()[:400].decode(), flush=True)


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "auth":
        auth()
    elif cmd == "upload":
        upload(sys.argv[2], sys.argv[3], sys.argv[4])
    elif cmd == "thumbnail":
        thumbnail(sys.argv[2], sys.argv[3])
