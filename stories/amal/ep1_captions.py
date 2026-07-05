"""Attach the English SRT to a YouTube video as a selectable CC track (captions.insert).
Needs youtube.force-ssl, so it keeps its own token (~/.youtube_tokens_ssl.json) via the device flow.

  python stories/amal/ep1_captions.py auth          # approve on phone (one time)
  python stories/amal/ep1_captions.py insert <VID>  # upload ep1.srt as the 'English' track
"""
import json, os, sys, time, urllib.parse, urllib.request, urllib.error

O = json.load(open(os.path.expanduser("~/.youtube_oauth.json")))
CID, CSEC = O["client_id"], O["client_secret"]
TOK = os.path.expanduser("~/.youtube_tokens_ssl.json")
SRT = "/Users/dusty/dev/brehon-law/stories/amal/ep1.srt"
SCOPE = ("https://www.googleapis.com/auth/youtube.upload "
         "https://www.googleapis.com/auth/youtube.force-ssl")


def _form(url, data):
    req = urllib.request.Request(url, data=urllib.parse.urlencode(data).encode(),
                                 headers={"Content-Type": "application/x-www-form-urlencoded"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        return json.loads(e.read().decode())


def auth():
    d = _form("https://oauth2.googleapis.com/device/code", {"client_id": CID, "scope": SCOPE})
    if "device_code" not in d:
        raise RuntimeError(f"device/code failed: {d}")
    print("VERIFICATION_URL:", d.get("verification_url") or d.get("verification_uri"), flush=True)
    print("USER_CODE:", d["user_code"], flush=True)
    print("(approve on your phone — grant the captions permission)", flush=True)
    interval = d.get("interval", 5)
    deadline = time.time() + d.get("expires_in", 1800)
    while time.time() < deadline:
        time.sleep(interval)
        t = _form("https://oauth2.googleapis.com/token", {
            "client_id": CID, "client_secret": CSEC, "device_code": d["device_code"],
            "grant_type": "urn:ietf:params:oauth:grant-type:device_code"})
        if "access_token" in t:
            json.dump(t, open(TOK, "w")); os.chmod(TOK, 0o600)
            print("AUTHORIZED", flush=True); return
        if t.get("error") == "authorization_pending":
            continue
        if t.get("error") == "slow_down":
            interval += 5; continue
        raise RuntimeError(f"auth failed: {t}")
    raise RuntimeError("device code expired before approval")


LOG = "/Users/dusty/dev/brehon-law/stories/amal/.cap_auth.log"


def _log(*a):
    msg = " ".join(str(x) for x in a)
    print(msg, flush=True)
    open(LOG, "a").write(msg + "\n")


def auth_loopback():
    """Browser/loopback flow — the standard installed-app flow, which (unlike the device flow)
    permits youtube.force-ssl. Works if the OAuth client is a 'Desktop app' type. Does not open a
    browser itself; the URL is logged so it can be handed to the user."""
    import http.server
    from urllib.parse import urlparse, parse_qs, urlencode
    port = 8765
    got = {}

    class H(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            q = parse_qs(urlparse(self.path).query)
            if "code" in q or "error" in q:
                got.update(q)
            self.send_response(200); self.send_header("Content-Type", "text/html"); self.end_headers()
            self.wfile.write(b"<h2>Authorized. Close this tab and return to the terminal.</h2>")
        def log_message(self, *a): pass

    redirect = f"http://127.0.0.1:{port}/"
    url = "https://accounts.google.com/o/oauth2/v2/auth?" + urlencode({
        "client_id": CID, "redirect_uri": redirect, "response_type": "code",
        "scope": SCOPE, "access_type": "offline", "prompt": "consent"})
    open(LOG, "w").write("")
    srv = http.server.HTTPServer(("127.0.0.1", port), H)
    _log("LISTENING", port)
    _log("AUTH_URL", url)
    while "code" not in got and "error" not in got:   # ignore favicon/probe hits
        srv.handle_request()
    if "error" in got:
        _log("OAUTH_ERROR", got); return
    t = _form("https://oauth2.googleapis.com/token", {
        "client_id": CID, "client_secret": CSEC, "code": got["code"][0],
        "grant_type": "authorization_code", "redirect_uri": redirect})
    if "refresh_token" in t:
        json.dump(t, open(TOK, "w")); os.chmod(TOK, 0o600)
        _log("AUTHORIZED")
    else:
        _log("TOKEN_EXCHANGE_FAILED", t)


def _token():
    t = json.load(open(TOK))
    r = _form("https://oauth2.googleapis.com/token", {
        "client_id": CID, "client_secret": CSEC,
        "refresh_token": t["refresh_token"], "grant_type": "refresh_token"})
    if "access_token" not in r:
        raise RuntimeError(f"refresh failed: {r}")
    return r["access_token"]


def insert(vid):
    tok = _token()
    meta = {"snippet": {"videoId": vid, "language": "en", "name": "English", "isDraft": False}}
    b = "capb" + str(int(time.time()))
    body = (f"--{b}\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n"
            + json.dumps(meta)
            + f"\r\n--{b}\r\nContent-Type: application/octet-stream\r\n\r\n").encode("utf-8")
    body += open(SRT, "rb").read() + f"\r\n--{b}--\r\n".encode("utf-8")
    req = urllib.request.Request(
        "https://www.googleapis.com/upload/youtube/v3/captions?part=snippet&uploadType=multipart",
        data=body, method="POST",
        headers={"Authorization": f"Bearer {tok}",
                 "Content-Type": f"multipart/related; boundary={b}",
                 "Content-Length": str(len(body))})
    try:
        with urllib.request.urlopen(req, timeout=180) as r:
            print("CAPTION OK:", json.load(r).get("id"), flush=True)
    except urllib.error.HTTPError as e:
        print("CAPTION FAIL", e.code, e.read()[:600].decode(), flush=True)


if __name__ == "__main__":
    cmd = sys.argv[1]
    if cmd == "auth":
        auth()
    elif cmd == "insert":
        insert(sys.argv[2])
