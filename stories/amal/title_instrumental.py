import os, sys, json, urllib.request, urllib.error
KEY = open(os.path.expanduser("~/.elevenlabs_api_key")).read().strip()
PROMPT = ("Dark Malwi folk-noir instrumental title theme; a lone sarangi and harmonium over a tanpura "
          "drone and a low hypnotic dholak pulse; a distant algoza folk-flute line; brooding, fatalistic, "
          "sparse, atmospheric; slowly building tension to one dark swell then resolving; cinematic "
          "prestige crime-drama main title; no vocals; mid-tempo")
out = "stories/amal/audio/amal_title_theme_instrumental_v1.mp3"
os.makedirs(os.path.dirname(out), exist_ok=True)
body = {"prompt": PROMPT, "music_length_ms": 75000, "model_id": "music_v1", "force_instrumental": True}
req = urllib.request.Request("https://api.elevenlabs.io/v1/music?output_format=mp3_44100_128",
    headers={"xi-api-key": KEY, "Content-Type": "application/json"}, data=json.dumps(body).encode())
try:
    with urllib.request.urlopen(req, timeout=300) as r:
        open(out, "wb").write(r.read())
    sz = os.path.getsize(out)
    print(f"OK -> {out} ({sz} bytes)")
except urllib.error.HTTPError as e:
    print("HTTP", e.code, e.read()[:400].decode(errors='replace'))
