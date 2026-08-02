import subprocess, json, urllib.request, os
from concurrent.futures import ThreadPoolExecutor
from PIL import Image
os.makedirs("clips", exist_ok=True)
KEEP = ("Everything stays low poly 3D with flat triangular facets; the characters keep their exact designs, "
        "the set and lighting stay identical. Subtle, believable motion only.")
SHOTS = [
 ("v2_s1_02_haul_wide", "The two little house spirits haul the huge striped sock leftward along the tunnel floor, straining, taking small braced steps; the sock slides after them. Dust drifts through the warm shafts of light. Slow camera pan left following them. "+KEEP),
 ("v2_s1_04_vasya_asks", "The boy keeps hauling and turns his head, talking, mouth moving as he puffs out a question; his hair and clothes shift with the effort. Dust floats in the light. Very slow push in. "+KEEP),
 ("v2_s1_05_frosya_answers", "The girl keeps hauling and speaks matter-of-factly, mouth moving, chin lifting slightly, hair swaying; she does not look back. Dust drifts in the light. Very slow push in. "+KEEP),
 ("v2_s1_07_boom_lookup", "A heavy footfall lands above: the huge dark shadow of a giant foot sweeps across the boards overhead and a shower of pale dust pours down through the cracks. Both children snap their heads up, startled, dust settling on them. Slight camera shake on the impact. "+KEEP),
 ("v2_s1_08_zamri", "The girl's arm shoots up in a sharp stop gesture and both children freeze absolutely rigid mid-motion, holding their breath. After the freeze almost nothing moves except falling dust drifting down through the light. "+KEEP),
 ("v2_s1_09_held_still", "Held stillness. The two stay frozen and tiny in the tunnel; only fine dust settles slowly through the warm shafts of light, and the light shifts almost imperceptibly. Extremely subtle motion, a held breath. "+KEEP),
]
def run(s):
    name, prompt = s
    out = f"clips/{name}.mp4"
    if os.path.exists(out): print("SKIP", name, flush=True); return
    kf = f"clips/_kf_{name}.jpg"
    im = Image.open(f"stills/{name}.png").convert("RGB"); im.thumbnail((1920,1920)); im.save(kf, quality=93)
    for attempt in range(3):
        try:
            o = subprocess.run(["higgsfield","generate","create","kling3_0","--prompt",prompt,
                                "--start-image",kf,"--duration","5","--mode","pro","--sound","off",
                                "--aspect_ratio","16:9","--wait","--wait-timeout","10m","--json"],
                               capture_output=True, text=True, timeout=700)
            raw=o.stdout; i=raw.find("[")
            d=json.loads(raw[i:]) if i>=0 else json.loads(raw)
            rec=d[0] if isinstance(d,list) else d
            u=rec.get("result_url")
            if u: urllib.request.urlretrieve(u,out); print("OK",name,flush=True); return
            print("retry",attempt+1,name,rec.get("status"),flush=True)
        except Exception as e:
            print("retry",attempt+1,name,str(e)[:60],flush=True)
    print("FAIL",name,flush=True)
with ThreadPoolExecutor(max_workers=6) as ex: list(ex.map(run,SHOTS))
print("CLIPS:", sorted(f for f in os.listdir("clips") if f.endswith(".mp4")))
