import os, json, urllib.request, urllib.error
KEY=open(os.path.expanduser("~/.elevenlabs_api_key")).read().strip()
PROMPT=("Instrumental Rajasthani veer-ras saka war theme for a prestige TV main title. Opens sparse and "
 "solemn: a lone sarangi and a slow, distant heartbeat of nagara war-drums. Builds gradually — dhol, a "
 "swelling tanpura and harmonium drone, a faraway male war-chant feel — rising to a heroic, tragic, "
 "defiant climax, the doomed last stand. Martial and elegiac, proud and mournful. NOT eerie, NOT horror. "
 "Cinematic, slow steady build, no vocals.")
out="stories/amal/audio/amal_title_theme_saka_v2.mp3"
body={"prompt":PROMPT,"music_length_ms":78000,"model_id":"music_v1","force_instrumental":True}
req=urllib.request.Request("https://api.elevenlabs.io/v1/music?output_format=mp3_44100_128",
 headers={"xi-api-key":KEY,"Content-Type":"application/json"},data=json.dumps(body).encode())
try:
 open(out,"wb").write(urllib.request.urlopen(req,timeout=300).read()); print("OK",out,os.path.getsize(out),"bytes")
except urllib.error.HTTPError as e: print("HTTP",e.code,e.read()[:300].decode(errors="replace"))
