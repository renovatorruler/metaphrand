import json, os, sys, time, urllib.request, urllib.error, subprocess
sys.path.insert(0,"/Users/dusty/dev/brehon-law/stories/amal")
from ep2_spotting import SPOTS, SUF
D="/Users/dusty/dev/brehon-law/stories/amal"; CUES=f"{D}/audio/ep2_cues"; os.makedirs(CUES,exist_ok=True)
man=json.load(open(f"{D}/ep2_timing.json"))
scn={}
for s in man["segments"]:
    a,b=s["start"],s["start"]+s["dur"]; sc=s["scene"]
    scn.setdefault(sc,[a,b]); scn[sc][0]=min(scn[sc][0],a); scn[sc][1]=max(scn[sc][1],b)
key=open(os.path.expanduser("~/.elevenlabs_api_key")).read().strip()
def gen(brief, ms, out):
    body=json.dumps({"prompt":brief+SUF,"music_length_ms":ms,"model_id":"music_v1","force_instrumental":True}).encode()
    for attempt in range(4):
        req=urllib.request.Request("https://api.elevenlabs.io/v1/music?output_format=mp3_44100_128",
            data=body,headers={"xi-api-key":key,"content-type":"application/json"},method="POST")
        try:
            data=urllib.request.urlopen(req,timeout=220).read(); open(out,"wb").write(data); return len(data)
        except urllib.error.HTTPError as e:
            msg=e.read().decode()[:160]
            if e.code in (429,500,503) and attempt<3:
                print(f"   {e.code} retry in 12s",flush=True); time.sleep(12); continue
            return f"HTTP{e.code}:{msg}"
todo=[sc for sc in sorted(SPOTS) if SPOTS[sc]["kind"]=="gen" and not os.path.exists(f"{CUES}/sc{sc:02d}.mp3")]
print(f"{len(todo)} cues to generate: {todo}",flush=True)
for sc in todo:
    spec=SPOTS[sc]; a,b=scn.get(sc,[0,60])
    dur = spec["win"][1] if "win" in spec else (b-a)
    ms=int(min(max(dur*1000,15000),150000)); out=f"{CUES}/sc{sc:02d}.mp3"
    r=gen(spec["brief"], ms, out)
    if isinstance(r,str):
        print(f"  sc{sc:02d} FAIL {r}",flush=True)
        if "HTTP401" in r: print("CREDITS EXHAUSTED — stopping",flush=True); break
    else:
        print(f"  sc{sc:02d} ok {ms/1000:.0f}s {r/1e6:.1f}MB",flush=True)
    time.sleep(2)
done=[sc for sc in sorted(SPOTS) if SPOTS[sc]["kind"]=="gen" and os.path.exists(f"{CUES}/sc{sc:02d}.mp3")]
print(f"GEN DONE {len(done)}/{sum(1 for s in SPOTS.values() if s['kind']=='gen')} gen-cues present",flush=True)
