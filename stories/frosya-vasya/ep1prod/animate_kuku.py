"""Animate Scene 1 the way the Kuku pipeline does it:
gemini_omni + FULL reference stack (style key, character sheets, location anchor, prop)
+ SCENE/MOTION/AUDIO prompt structure + the full negative block.
"""
import subprocess, json, urllib.request, os
from concurrent.futures import ThreadPoolExecutor

CS = "../charsheets"
PLATE = "plates/s1_underfloor_wide.png"
SOCK = "plates/prop_sock.png"
PRESET = "3e4bfd81-fbd8-4587-886d-296cbe48d152"

def style_key():
    o = subprocess.run(["higgsfield","preset","resolve","video-explainer",PRESET,"--json"],
                       capture_output=True, text=True, timeout=90)
    return json.loads(o.stdout)["media_id"]

CP = (
 "STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY — low poly 3D, visible flat "
 "triangular facets, hard polygon edges, flat-shaded, rich warm saturated colours. "
 "LOCATION REFERENCE: the place image is THE SET — match its floorboards, its colossal overhead joists, its shallow "
 "back wall of boards over foundation stone, its cobwebs, its dust and its warm shafts of light. The tunnel continues "
 "off both sides of frame. "
 "PROP REFERENCE: the sock image is the LOCKED sock — a big knitted woollen sock with broad stripes in a fixed order, "
 "CREAM, RUST-RED, CREAM, DEEP TEAL-BLUE, repeating, with a plain cream ribbed cuff. Its colours never change. "
 "CHARACTER REFERENCES: the character images are LOCKED designs; match each EXACTLY and keep them identical for the "
 "whole shot. ФРОСЯ: long wavy dark-brown hair, pencil stub above one ear, orange flower on the other, floral patchwork "
 "dress, pouch with a big safety pin, barefoot. ВАСЯ: spiky brown hair, thick dark winged eyebrows, small deep-brown "
 "button nose, patchwork clothes, pale shoelace belt with an aglet, barefoot. "
 "ФРОСЯ is ALWAYS on the LEFT and ALWAYS about half a head TALLER than ВАСЯ, who is ALWAYS on the RIGHT. "
 "They are домовые — tiny house spirits, not human children."
)

EN = (
 "NEGATIVE: no third character, no extra characters of any kind, NO giant foot or leg or hand entering the tunnel, "
 "no human body parts in the shot, no one else appearing, no character changing size or shape, no character swapping "
 "sides, no sock changing colour or pattern, no red-white-blue sock, no shoes, no readable text, no letters, no numbers, "
 "no watermark, no photorealism, no live action, nothing scary, nobody in danger, no child falling."
)

SHOTS = [
 ("k_s1_02_haul",
  "SCENE: the dusty tunnel under the floorboards. ФРОСЯ on the left and ВАСЯ on the right haul the enormous striped "
  "sock leftward along the floor, both facing left, leaning into the pull, hands gripping the sock's cuff, bare feet "
  "braced; the sock trails behind them to the right. Warm shafts of light, floating dust. "
  "MOTION: the two children take slow straining steps to the left, bodies rocking with the effort, the heavy sock "
  "sliding after them across the boards; dust puffs at their feet; dust motes drift in the light beams. "
  "The camera pans slowly left with them. AUDIO: none needed."),
 ("k_s1_04_vasya",
  "SCENE: closer on ВАСЯ on the right, still hauling, facing left, ФРОСЯ's shoulder and hair at the left edge. Warm "
  "light across his face. "
  "MOTION: he keeps pulling and turns his head toward his sister, mouth moving as he puffs out a question, eyebrows "
  "lifting, chest heaving; his hair shifts with the movement; dust drifts in the light. Very slow push in. "
  "AUDIO: none needed."),
 ("k_s1_05_frosya",
  "SCENE: closer on ФРОСЯ on the left, still hauling, facing left, chin up, unbothered. Warm light on her face. "
  "MOTION: she keeps pulling and speaks matter-of-factly, mouth moving, chin lifting slightly, her long wavy hair "
  "swaying; she does not look back. Dust drifts in the light. Very slow push in. AUDIO: none needed."),
 ("k_s1_07_boom",
  "SCENE: the tunnel; ФРОСЯ left and ВАСЯ right stand beside the sock, the ceiling of colossal joists above them. "
  "A large soft DARK SHADOW lies across the boards of the ceiling overhead — it is only a shadow on the wood, nothing "
  "solid, nothing enters the tunnel. "
  "MOTION: the dark shadow on the ceiling slides slowly across the overhead boards and fades; at the same moment a fine "
  "shower of pale dust sifts down through the cracks between the boards into the shafts of light; both children stop and "
  "tilt their heads up to look at the ceiling, eyes widening. The camera shakes very slightly once. "
  "Nothing solid comes down; only dust falls. AUDIO: none needed."),
 ("k_s1_08_zamri",
  "SCENE: the tunnel; ФРОСЯ on the left with one arm raised in a sharp stop gesture, ВАСЯ on the right caught mid-step, "
  "the sock lying behind them to the right. Only the two of them are present. "
  "MOTION: ФРОСЯ's raised hand snaps up and stops dead; both children freeze completely rigid and stop moving entirely, "
  "holding their breath; after that nothing about them moves at all. Only fine dust keeps drifting down through the "
  "light. The camera is locked off. AUDIO: none needed."),
 ("k_s1_09_held",
  "SCENE: a wide view of the tunnel with the two tiny children standing frozen and motionless beside the enormous sock, "
  "dwarfed by the joists overhead. Only the two of them are present. "
  "MOTION: almost nothing moves. The children remain perfectly still. Fine dust settles slowly through the warm shafts "
  "of light and the light shifts almost imperceptibly. A held breath. The camera is locked off. AUDIO: none needed."),
]

def run(shot):
    name, desc = shot
    out = f"clips/{name}.mp4"
    if os.path.exists(out):
        print("SKIP", name, flush=True); return
    for attempt in range(3):
        try:
            mid = style_key()
            o = subprocess.run(["higgsfield","generate","create","gemini_omni",
                                "--prompt", f"{CP} {desc} {EN}",
                                "--image", mid, "--image", PLATE, "--image", SOCK,
                                "--image", f"{CS}/frosya_lowpoly_v2.png", "--image", f"{CS}/vasya_lowpoly.png",
                                "--duration","10","--aspect_ratio","16:9","--resolution","720p",
                                "--wait","--wait-timeout","12m","--json"],
                               capture_output=True, text=True, timeout=800)
            raw=o.stdout; i=raw.find("[")
            d=json.loads(raw[i:]) if i>=0 else json.loads(raw)
            rec=d[0] if isinstance(d,list) else d
            u=rec.get("result_url")
            if u:
                urllib.request.urlretrieve(u,out); print("OK",name,flush=True); return
            print("retry",attempt+1,name,rec.get("status"),flush=True)
        except Exception as e:
            print("retry",attempt+1,name,str(e)[:70],flush=True)
    print("FAIL",name,flush=True)

os.makedirs("clips", exist_ok=True)
with ThreadPoolExecutor(max_workers=6) as ex:
    list(ex.map(run, SHOTS))
print("KUKU-STYLE CLIPS:", sorted(f for f in os.listdir("clips") if f.startswith("k_")))
