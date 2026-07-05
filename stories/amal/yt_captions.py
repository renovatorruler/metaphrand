"""Upload an .srt as an English caption track to a YouTube video (captions.insert).
captions.insert needs the youtube.force-ssl scope, broader than youtube.upload — so this keeps its own
token cache and its own device-flow auth (approve the printed code on your phone, once).

  python stories/amal/yt_captions.py auth
  python stories/amal/yt_captions.py insert <video_id> <file.srt> [language] [name]
"""
import json, os, sys, time, urllib.error, urllib.parse, urllib.request

OAUTH = json.load(open(os.path.expanduser("~/.youtube_oauth.json")))
CID, CSEC = OAUTH["client_id"], OAUTH["client_secret"]
TOK = os.path.expanduser("~/.youtube_tokens_fs.json")
SCOPE = "https://www.googleapis.com/auth/youtube.force-ssl"


def _post(url, data):
    req = urllib.request.Request(url, data=urllib.parse.urlencode(data).encode(),
                                 headers={"Content-Type": "application/x-www-form-urlencoded"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        return json.loads(e.read().decode())


def auth():
    d = _post("https://oauth2.googleapis.com/device/code", {"client_id": CID, "scope": SCOPE})
    if "device_code" not in d:
        sys.exit(f"device/code failed: {d}")
    print("VERIFICATION_URL:", d.get("verification_url") or d.get("verification_uri"), flush=True)
    print("USER_CODE:", d["user_code"], flush=True)
    print("(approve on your phone — polling...)", flush=True)
    interval, deadline = d.get("interval", 5), time.time() + d.get("expires_in", 1800)
    while time.time() < deadline:
        time.sleep(interval)
        t = _post("https://oauth2.googleapis.com/token", {
            "client_id": CID, "client_secret": CSEC, "device_code": d["device_code"],
            "grant_type": "urn:ietf:params:oauth:grant-type:device_code"})
        if "access_token" in t:
            json.dump(t, open(TOK, "w")); os.chmod(TOK, 0o600); print("AUTHORIZED", flush=True); return
        if t.get("error") == "authorization_pending":
            continue
        if t.get("error") == "slow_down":
            interval += 5; continue
        sys.exit(f"auth failed: {t}")
    sys.exit("device code expired")


def _token():
    t = json.load(open(TOK))
    r = _post("https://oauth2.googleapis.com/token", {
        "client_id": CID, "client_secret": CSEC, "refresh_token": t["refresh_token"],
        "grant_type": "refresh_token"})
    if "access_token" not in r:
        sys.exit(f"refresh failed: {r}")
    return r["access_token"]


def insert(video_id, srt, language="en", name="English"):
    tok = _token()
    meta = {"snippet": {"videoId": video_id, "language": language, "name": name, "isDraft": False}}
    b = "====amalcaptionboundary===="
    body = (f"--{b}\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n{json.dumps(meta)}\r\n"
            f"--{b}\r\nContent-Type: application/octet-stream\r\n\r\n").encode("utf-8") \
        + open(srt, "rb").read() + f"\r\n--{b}--\r\n".encode("utf-8")
    req = urllib.request.Request(
        "https://www.googleapis.com/upload/youtube/v3/captions?part=snippet&uploadType=multipart",
        data=body, method="POST",
        headers={"Authorization": f"Bearer {tok}", "Content-Type": f"multipart/related; boundary={b}",
                 "Content-Length": str(len(body))})
    try:
        with urllib.request.urlopen(req, timeout=300) as r:
            res = json.load(r)
        print("CAPTION TRACK ADDED:", res.get("id"), res["snippet"]["name"], flush=True)
    except urllib.error.HTTPError as e:
        print("CAPTIONS FAILED", e.code, e.read()[:500].decode(), flush=True); sys.exit(1)


if __name__ == "__main__":
    if sys.argv[1] == "auth":
        auth()
    elif sys.argv[1] == "insert":
        insert(*sys.argv[2:])
