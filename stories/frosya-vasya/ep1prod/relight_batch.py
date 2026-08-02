import subprocess, json, urllib.request, os, base64
from concurrent.futures import ThreadPoolExecutor

BASE = ("Edit this image. KEEP EVERYTHING IDENTICAL — the same two characters in the same poses with the same faces, "
 "expressions, clothes and props, the same enormous striped sock carried the same way, the same tunnel set, the same "
 "composition and framing. CHANGE ONLY THE LIGHTING ON THE CHARACTERS AND THE SOCK so they belong to the scene: "
 "the tunnel's warm golden shafts fall from above — surfaces facing up and toward the beams catch warm golden light, "
 "lower and away sides fall into deep warm-brown shadow; overall the figures sit darker and warmer, matching the "
 "tunnel's ambience, with no crisp white studio brightness; figures inside a light pool glow warmly, outside it they "
 "dim; strengthen soft contact shadows on the floorboards; add a faint warm rim along their upper edges. "
 "The background stays as it is. NEGATIVE: no pose change, no face change, no new objects, no text, no watermark.")

DUST6 = ("Edit this image. KEEP the two characters in the same poses with the same faces, clothes, props, the same sock "
 "and the same composition. TWO CHANGES: (1) THE LIGHT FROM ABOVE IS BLOCKED — the warm shaft from the overhead gap is "
 "cut off, its bright pool gone, dropping the whole tunnel into dim cool near-darkness with only faint spill from "
 "distant gaps; relight the characters and sock accordingly — dim, cool, their eyes catching what little light remains. "
 "(2) A heavy shower of pale DUST pours down from the boards overhead through the gloom onto them, dust settling on "
 "their hair and shoulders. NEGATIVE: no pose change, no giant foot, no new characters, no text, no watermark.")

SHOTS = [("k_f1_haul",BASE),("k_f2_asks",BASE),("k_f3_answers",BASE),
         ("k_f4_hears",BASE),("k_f5_zamri",BASE),("k_f6_dust",DUST6)]

def run(s):
    name, prompt = s
    out = f"stills/m_{name}.png"
    if os.path.exists(out): print("SKIP", name, flush=True); return
    for t in range(3):
        try:
            o = subprocess.run(["higgsfield","generate","create","nano_banana_pro","--prompt",prompt,
                                "--image", f"stills/{name}.png",
                                "--aspect_ratio","16:9","--resolution","2k","--wait","--json"],
                               capture_output=True, text=True, timeout=430)
            raw=o.stdout; i=raw.find("[")
            d=json.loads(raw[i:]) if i>=0 else json.loads(raw)
            rec=d[0] if isinstance(d,list) else d
            u=rec.get("result_url")
            if u: urllib.request.urlretrieve(u,out); print("OK",name,flush=True); return
            print("retry",t+1,name,rec.get("status"),flush=True)
        except Exception as e:
            print("retry",t+1,name,str(e)[:50],flush=True)
    print("FAIL",name,flush=True)

with ThreadPoolExecutor(max_workers=6) as ex: list(ex.map(run,SHOTS))
print("RELIT:", sorted(f for f in os.listdir("stills") if f.startswith("m_")))
