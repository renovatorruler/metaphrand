import os, json, base64, time, io, urllib.request
from PIL import Image
TOKEN = open(os.path.expanduser("~/.replicate_api_key")).read().strip()
VER = "e6f571e8d6990da3c96abf8d3082894024d652822f0ca3cd244acece84a1cc3e"  # kling-v1.6-standard
D = "stories/amal/title_culture"
NEG = "fast motion, camera shake, zoom, rapid movement, morphing, warping, distortion, jitter, people walking quickly, flicker, glitch"
# (still, very-slow motion brief)
JOBS = [
 ("hand_poppy", "extremely slow: the weathered hand drifts very gently through the poppies, petals barely sway, faint haze, minimal movement, locked camera"),
 ("d_darbar", "extremely slow: banknotes drift down through the air very slowly like falling leaves, the bowed figures perfectly still, lamp flames flicker faintly, locked camera"),
 ("mahakal", "extremely slow: sacred ash-smoke curls and drifts very slowly through the lamplight, the flame breathes gently, everything else perfectly still, locked camera"),
 ("d_wedding", "extremely slow: marigold petals and banknotes drift down very slowly, the figures perfectly still, smoke curls faintly, minimal movement, locked camera"),
 ("kumbh", "extremely slow: the sacred fire breathes and smoke drifts very slowly, the sadhus perfectly still, faint embers float, locked camera"),
 ("d_scale", "extremely slow: the great brass scale sways almost imperceptibly, fine dust drifts slowly through the shaft of light, the figures perfectly still, locked camera"),
 ("mata_pujan", "extremely slow: the small oil-lamp flames flicker gently, incense smoke drifts up very slowly, everything else perfectly still, locked camera"),
 ("d_pen", "extremely slow: loose papers and banknotes drift very slowly through the air, the lamp flame flickers, the figures perfectly still, ominous stillness, locked camera"),
 ("d_grounddown", "extremely slow: suspended dust drifts very slowly through the lamplight, the bowed figures barely move, a faint breeze, locked camera"),
 ("d_title", "extremely slow: embers and marigold petals drift down very slowly, smoke curls, the figures on the steps perfectly still, grand and slow, locked camera"),
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
    except Exception as e: print("SUBMIT FAIL",name,str(e)[:120],flush=True)
done=set()
for _ in range(200):
    if len(done)>=len(jobs): break
    time.sleep(8)
    for name,get in jobs.items():
        if name in done: continue
        try:
            p=json.load(urllib.request.urlopen(urllib.request.Request(get,headers={"Authorization":f"Bearer {TOKEN}"}),timeout=60))
        except Exception: continue
        st=p.get("status")
        if st=="succeeded":
            o=p["output"]; url=o if isinstance(o,str) else o[0]
            open(f"{D}/{name}_anim.mp4","wb").write(urllib.request.urlopen(url,timeout=180).read())
            done.add(name); print("DONE",name,f"({len(done)}/{len(jobs)})",flush=True)
        elif st in ("failed","canceled"):
            done.add(name); print("FAILED",name,str(p.get('error'))[:120],flush=True)
print("BATCH COMPLETE", len(done), "of", len(jobs), flush=True)
