import os, json, urllib.request, urllib.error
KEY=open(os.path.expanduser("~/.elevenlabs_api_key")).read().strip()
TAKES={
"v3a":("Instrumental Rajput saka war-charge theme for a prestige TV main title. A defiant last stand: "
 "warriors who have accepted death and ride out with fury. A low nagara war-drum heartbeat and a lone "
 "defiant sarangi war-call open it; it builds steadily and relentlessly — dhol and nagara accelerating "
 "like galloping hooves, a rising shehnai battle-cry, a thundering martial ostinato — to a furious, "
 "heroic, blood-up climax: the charge itself. Proud, wrathful, unbroken. A tragic undertone but DEFIANT, "
 "exalted, never mournful. Not eerie, not a dirge. Cinematic, accelerating build, no vocals."),
"v3b":("Instrumental Malwa folk-noir main title that becomes a Rajput saka battle-hymn. Begins brooding "
 "and sparse — sarangi and tanpura drone, a distant war-drum — then a martial pulse enters and the whole "
 "thing rises with grim resolve into a defiant, heroic saka swell: nagara and dhol driving, a proud "
 "sarangi and shehnai war-melody soaring, the sound of men marching to a last stand they will not survive "
 "and do not fear. Powerful, defiant, building to one big climactic statement then a hard cut. Tragic but "
 "unbowed, never sad, never eerie. Cinematic, no vocals."),
}
for tag,prompt in TAKES.items():
    out=f"stories/amal/audio/amal_title_theme_saka_{tag}.mp3"
    body={"prompt":prompt,"music_length_ms":78000,"model_id":"music_v1","force_instrumental":True}
    req=urllib.request.Request("https://api.elevenlabs.io/v1/music?output_format=mp3_44100_128",
        headers={"xi-api-key":KEY,"Content-Type":"application/json"},data=json.dumps(body).encode())
    try:
        open(out,"wb").write(urllib.request.urlopen(req,timeout=300).read())
        print("OK",tag,out,f"{os.path.getsize(out)/1e6:.1f}MB",flush=True)
    except urllib.error.HTTPError as e:
        print("HTTP",tag,e.code,e.read()[:300].decode(errors="replace"),flush=True)
