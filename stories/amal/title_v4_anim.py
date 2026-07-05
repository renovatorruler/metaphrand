import os, json, base64, time, io, urllib.request
from PIL import Image
TOKEN = open(os.path.expanduser("~/.replicate_api_key")).read().strip()
VER = "e6f571e8d6990da3c96abf8d3082894024d652822f0ca3cd244acece84a1cc3e"  # kling-v1.6-standard
D = "stories/amal/title_v4"
NEG = "fast motion, camera shake, zoom, rapid movement, morphing faces, warping, distortion, jitter, walking, flicker, glitch, changing faces, deforming"
JOBS = [
 ("fire_overlay",  "extremely slow: orange flames flicker and rise gently, embers drift upward slowly, smooth continuous fire on pure solid black background, locked camera"),
 ("smoke_overlay", "extremely slow: pale grey smoke curls and drifts slowly upward and sideways on pure solid black background, soft billowing, continuous, locked camera"),
 ("sword_overlay", "extremely slow: the small flame along the curved sword blade flickers and rises, the blade held steady upright, turns almost imperceptibly, pure solid black background, locked camera"),
 ("g_rana_court",  "extremely slow: banknotes drift down very slowly through the air like falling leaves, the enthroned man and the two men beside him perfectly still, the bowed figures still, lamp flames flicker faintly, locked camera"),
 ("fort_inside",   "extremely slow: pale mist drifts very slowly through the arched stone hall, the distant torch flame flickers, the lone figure perfectly still, dust motes float in the shaft of light, locked camera"),
 ("river_crowd",   "extremely slow: river mist drifts slowly across the gathered crowd at dawn, the water surface glints and ripples gently, the people barely move, faint smoke rises, locked camera"),
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
for _ in range(240):
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
