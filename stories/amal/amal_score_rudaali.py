import os, json, urllib.request, urllib.error
KEY = open(os.path.expanduser("~/.elevenlabs_api_key")).read().strip()
TAKES = {
 "rudaali_voice": (False,
  "A haunting Rajasthani Rudaali mourning lament. A solo female voice keening long wordless alaaps — "
  "aching melismas that rise into something between a song and a woman's stifled scream of grief — "
  "answered by a lone sarangi, over a low sustained tanpura drone. Sparse, raw, funereal, unbearably sad. "
  "Wordless vocalise only, no lyrics, no words. Very slow, spacious, no percussion. The grief of a mother "
  "who is forbidden to weep."),
 "rudaali_sarangi": (True,
  "A haunting Rajasthani mourning lament, instrumental. A lone sarangi keening like a woman's wail — long "
  "aching glissandi that climb into a stifled scream of grief — over a low sustained tanpura drone, sparse "
  "and funereal, unbearably sad. Very slow, spacious, no percussion, no vocals. The grief that cannot be "
  "spoken."),
}
for tag, (instr, prompt) in TAKES.items():
    out = f"stories/amal/audio/amal_score_{tag}.mp3"
    body = {"prompt": prompt, "music_length_ms": 45000, "model_id": "music_v1", "force_instrumental": instr}
    req = urllib.request.Request("https://api.elevenlabs.io/v1/music?output_format=mp3_44100_128",
        headers={"xi-api-key": KEY, "Content-Type": "application/json"}, data=json.dumps(body).encode())
    try:
        open(out, "wb").write(urllib.request.urlopen(req, timeout=300).read())
        print("OK", tag, f"{os.path.getsize(out)/1e6:.1f}MB", flush=True)
    except urllib.error.HTTPError as e:
        print("HTTP", tag, e.code, e.read()[:200].decode(errors="replace"), flush=True)
print("[done]", flush=True)
