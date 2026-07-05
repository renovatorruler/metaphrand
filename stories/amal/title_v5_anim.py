import os, json, base64, time, io, urllib.request
from PIL import Image
TOKEN = open(os.path.expanduser("~/.replicate_api_key")).read().strip()
VER = "e6f571e8d6990da3c96abf8d3082894024d652822f0ca3cd244acece84a1cc3e"  # kling-v1.6-standard
D = "stories/amal/title_v5"
NEG = ("fast motion, camera shake, zoom, rapid movement, morphing faces, changing faces, deforming, "
 "warping, distortion, jitter, walking, flicker, glitch, extra limbs, melting")
JOBS = [
 ("ratan_desk_v2",  "extremely slow: the oil-lamp flame flickers gently, thin bidi smoke curls up through the light, the inspector sits perfectly still, eyes lowered to the register; faces completely still, no morphing, locked camera"),
 ("rana_court_v2b", "extremely slow: the oil-lamp flame flickers, faint smoke drifts, the reclining man breathes almost imperceptibly, the kneeling supplicant's shoulders settle once; everyone else perfectly still, faces completely still, no morphing, locked camera"),
 ("sale_v2",        "extremely slow: the lamp flame flickers gently, the veiled bride's lowered eyes stay still, the old man's hand rests motionless on the document, faint smoke drifts; faces completely still, no morphing, locked camera"),
 ("deva_family_v2", "extremely slow: the floor oil-lamp flame flickers, the three figures pressed together hold still and breathe faintly; faces completely still, no morphing, no warping, locked camera"),
 ("ratan_kanta_v2", "extremely slow: the floor oil-lamp flame flickers between them, thin smoke drifts, the seated man's hand moves the slightest amount, the woman by the doorway stays still and turned away; faces completely still, no morphing, locked camera"),
 ("lancing_v2",     "extremely slow: a single drop of milky white latex slowly swells and beads on the scored poppy pod and begins to run down it, the blade perfectly still, faint dawn haze drifting; macro, shallow focus, locked camera"),
]
def submit(name, prompt):
    im = Image.open(f"{D}/{name}.png").convert("RGB"); s=max(1280/im.width,720/im.height)
    im=im.resize((round(im.width*s),round(im.height*s)),Image.LANCZOS); x=(im.width-1280)//2; y=(im.height-720)//2
    im=im.crop((x,y,x+1280,y+720)); buf=io.BytesIO(); im.save(buf,"JPEG",quality=92)
    uri="data:image/jpeg;base64,"+base64.b64encode(buf.getvalue()).decode()
    body={"version":VER,"input":{"start_image":uri,"prompt":prompt,"negative_prompt":NEG,"duration":5,"aspect_ratio":"16:9","cfg_scale":0.5}}
    req=urllib.request.Request("https://api.replicate.com/v1/predictions",headers={"Authorization":f"Bearer {TOKEN}","Content-Type":"application/json"},data=json.dumps(body).encode())
    return json.load(urllib.request.urlopen(req,timeout=90))["urls"]["get"]
jobs={}
for name,prompt in JOBS:
    out=f"{D}/{name}_anim.mp4"
    if os.path.exists(out): print("skip",name,flush=True); continue
    try: jobs[name]=submit(name,prompt); print("submitted",name,flush=True); time.sleep(2)
    except Exception as e: print("SUBMIT FAIL",name,str(e)[:140],flush=True)
done=set()
for _ in range(260):
    if len(done)>=len(jobs): break
    time.sleep(8)
    for name,get in list(jobs.items()):
        if name in done: continue
        try: p=json.load(urllib.request.urlopen(urllib.request.Request(get,headers={"Authorization":f"Bearer {TOKEN}"}),timeout=60))
        except Exception: continue
        st=p.get("status")
        if st=="succeeded":
            o=p["output"]; url=o if isinstance(o,str) else o[0]
            open(f"{D}/{name}_anim.mp4","wb").write(urllib.request.urlopen(url,timeout=180).read())
            done.add(name); print("DONE",name,f"({len(done)}/{len(jobs)})",flush=True)
        elif st in ("failed","canceled"):
            done.add(name); print("FAILED",name,str(p.get('error'))[:140],flush=True)
print("BATCH COMPLETE", len(done), "of", len(jobs), flush=True)
