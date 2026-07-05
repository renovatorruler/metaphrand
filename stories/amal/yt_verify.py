"""Re-auth the YouTube OAuth with read scope added, then report whether the channel can upload
videos over 15 minutes (longUploadsStatus). Device flow: approve the printed code on your phone."""
import json, os, sys, time, urllib.request, urllib.parse, urllib.error

OAUTH = json.load(open(os.path.expanduser("~/.youtube_oauth.json")))
CID, CSEC = OAUTH["client_id"], OAUTH["client_secret"]
TOKENS = os.path.expanduser("~/.youtube_tokens.json")
SCOPE = ("https://www.googleapis.com/auth/youtube.upload "
         "https://www.googleapis.com/auth/youtube.readonly")


def post(url, data):
    req = urllib.request.Request(url, data=urllib.parse.urlencode(data).encode(),
                                 headers={"Content-Type": "application/x-www-form-urlencoded"})
    try:
        with urllib.request.urlopen(req, timeout=60) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        return json.loads(e.read().decode())


d = post("https://oauth2.googleapis.com/device/code", {"client_id": CID, "scope": SCOPE})
if "device_code" not in d:
    sys.exit(f"device/code failed: {d}")
print("VERIFICATION_URL:", d.get("verification_url") or d.get("verification_uri"), flush=True)
print("USER_CODE:", d["user_code"], flush=True)
print("(approve on your phone — polling...)", flush=True)
interval, deadline = d.get("interval", 5), time.time() + d.get("expires_in", 1800)
tok = None
while time.time() < deadline:
    time.sleep(interval)
    t = post("https://oauth2.googleapis.com/token", {
        "client_id": CID, "client_secret": CSEC, "device_code": d["device_code"],
        "grant_type": "urn:ietf:params:oauth:grant-type:device_code"})
    if "access_token" in t:
        json.dump(t, open(TOKENS, "w")); os.chmod(TOKENS, 0o600)
        tok = t["access_token"]; print("AUTHORIZED", flush=True); break
    if t.get("error") in ("authorization_pending",):
        continue
    if t.get("error") == "slow_down":
        interval += 5; continue
    sys.exit(f"auth failed: {t}")
if not tok:
    sys.exit("device code expired before approval")

req = urllib.request.Request(
    "https://www.googleapis.com/youtube/v3/channels?part=status,snippet,contentDetails&mine=true",
    headers={"Authorization": f"Bearer {tok}"})
with urllib.request.urlopen(req, timeout=60) as r:
    data = json.load(r)
items = data.get("items", [])
if not items:
    print(">>> NO CHANNEL on this account."); sys.exit(0)
for it in items:
    st = it.get("status", {})
    print(">>> channel:", it["snippet"]["title"], flush=True)
    print(">>> longUploadsStatus:", st.get("longUploadsStatus"), flush=True)
    print(">>> privacyStatus:", st.get("privacyStatus"), "isLinked:", st.get("isLinked"), flush=True)
