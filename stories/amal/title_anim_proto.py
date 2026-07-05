import os, json, base64, time, io, urllib.request
from PIL import Image
TOKEN = open(os.path.expanduser("~/.replicate_api_key")).read().strip()
src = "stories/amal/title_culture/hand_poppy.png"
im = Image.open(src).convert("RGB"); s = max(1280/im.width, 720/im.height)
im = im.resize((round(im.width*s), round(im.height*s)), Image.LANCZOS)
x=(im.width-1280)//2; y=(im.height-720)//2; im=im.crop((x,y,x+1280,y+720))
buf=io.BytesIO(); im.save(buf,"JPEG",quality=92)
uri="data:image/jpeg;base64,"+base64.b64encode(buf.getvalue()).decode()
body={"version":"e6f571e8d6990da3c96abf8d3082894024d652822f0ca3cd244acece84a1cc3e",
 "input":{"start_image":uri,
  "prompt":"extremely slow subtle cinematic motion: the weathered old hand drifts very gently through the poppy flowers, petals barely sway in a faint breeze, soft drifting haze, meditative, atmospheric, locked tripod, minimal movement",
  "negative_prompt":"fast motion, camera shake, zoom, rapid movement, morphing, warping, distortion, jitter, people walking",
  "duration":5,"aspect_ratio":"16:9","cfg_scale":0.5}}
req=urllib.request.Request("https://api.replicate.com/v1/predictions",
 headers={"Authorization":f"Bearer {TOKEN}","Content-Type":"application/json"},data=json.dumps(body).encode())
pred=json.load(urllib.request.urlopen(req,timeout=60)); get=pred["urls"]["get"]
print("submitted", pred.get("status"), flush=True)
for _ in range(120):
    time.sleep(6)
    pred=json.load(urllib.request.urlopen(urllib.request.Request(get,headers={"Authorization":f"Bearer {TOKEN}"}),timeout=60))
    if pred.get("status") not in ("starting","processing"): break
print("status", pred.get("status"), flush=True)
if pred.get("status")=="succeeded":
    out=pred["output"]; url=out if isinstance(out,str) else out[0]
    open("stories/amal/title_culture/hand_poppy_anim.mp4","wb").write(urllib.request.urlopen(url,timeout=120).read())
    print("SAVED hand_poppy_anim.mp4", flush=True)
else:
    print("ERR", str(pred.get("error"))[:300], flush=True)
