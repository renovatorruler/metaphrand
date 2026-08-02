import subprocess, json, urllib.request, os
from concurrent.futures import ThreadPoolExecutor

STYLE = "856a99ee-5cc9-4fad-ad8d-998d79edb4f4"   # PINNED — never re-resolve
CS = "../charsheets"
PLATES = {"wide":"plates/plate_wide.png","medwide":"plates/plate_medwide.png","med":"plates/plate_med.png"}
SOCK = "plates/prop_sock.png"
CARRYREF = "plates/ref_haul_LOCKED_FINAL.png"
SCALE = "plates/ref_sock_scale.png"

LIGHT = ("LIGHTING INTEGRATION — CRITICAL: the characters and the sock must be LIT BY THE SCENE, not by studio light. "
 "The tunnel's warm golden shafts fall from above: surfaces facing the beams catch warm light, their opposite sides fall "
 "into the tunnel's deep cool shadow, and characters standing in a light pool are bright while those outside it are dim. "
 "Cast soft contact shadows from the characters and the sock onto the floorboards, matching the scene's light direction. "
 "The attached carry reference is for POSE AND PROPORTION ONLY — do NOT copy its flat even studio lighting or its plain "
 "background. ")

SP = ("STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. "
      "LOCATION REFERENCE: match the place image's floorboards, joists, back wall, cobwebs and shafts of light EXACTLY — "
      "same place, different angle. "
      "CHARACTER REFERENCES: the character images are locked designs; match each EXACTLY. "
      "Low poly 3D, faceted geometry, warm saturated colours, non-photorealistic, illustrated. LANDSCAPE 16:9 SHOT for a "
      "children's cartoon. Фрося is the taller older sister on the LEFT; Вася is the shorter younger brother on the RIGHT. ")

# v4 carry restored — this is what kept the sock big and in their hands — plus the toe
CARRY = ("CARRY REFERENCE: one of the attached images shows the two children carrying the sock — the girl in front with the "
         "ribbed cuff over her shoulder, the boy behind pushing it up, the sock's body trailing on the ground behind them, "
         "the pale lace tail curving with slack to a rounded nugget tip on the floor. In every shot where they carry the "
         "sock, match that image's poses, grip, scale, effort and body proportions EXACTLY. "
         "THE SOCK: one enormous knitted sock, far longer than either child is tall, striped cream / rust-red / cream / "
         "deep teal-blue with a cream ribbed CUFF at one end and a clearly visible rounded TOE at the other end. "
         "They carry it TOGETHER between them at chest height: Фрося grips it on the LEFT, Вася grips it on the RIGHT, "
         "and its long body extends away behind them to the RIGHT of frame with the rounded toe at that trailing end. "
         "It stays exactly this big in every shot and they never let go of it. ")

EN = ("Full-bleed scene, the camera is INSIDE the world. NEGATIVE: no readable text, no letters, no numbers, no watermark, "
      "no photorealism, no realistic humans, no shoes, no extra characters, no giant foot or leg in the tunnel, no second "
      "sock, no small sock, nothing scary.")

FRAMING = {"f1_haul":"wide","f2_asks":"med","f3_answers":"medwide","f4_hears":"med","f5_zamri":"med","f6_dust":"medwide"}

SHOTS = [
 ("f1_haul",    "Фрося and Вася carrying the huge sock between them leftward through THE SAME under-floor tunnel, both leaning into the weight, straining, bare feet braced."),
 ("f2_asks",    "Вася carrying his end of the sock and turning his head toward his sister, mouth open asking a question, out of breath. Фрося is beside him with her head and shoulder clearly in frame at the left, not cropped."),
 ("f3_answers", "The two still carrying the sock exactly as in the carry reference — Фрося in front under the cuff, Вася pushing behind — while Фрося answers matter-of-factly over her shoulder, chin up, mid-sentence, not stopping."),
 ("f4_hears",   "Фрося stopping, head tilted up, listening hard to a faint creak above, while Вася beside her has not noticed yet. Both still holding the sock."),
 ("f5_zamri",   "Фрося throwing one arm up in a sharp stop gesture and looking up at the ceiling; the sock's cuff rests against her OTHER shoulder at chest height, clearly BESIDE her head and not on it or over it; Вася jolting to a halt behind her, hands still on the sock."),
 ("f6_dust",    "THE SAME tunnel suddenly DIM and dark because the light from the gap overhead is blocked, pale dust pouring down through the gloom onto the two frozen children, BOTH heads tilted back looking straight UP at the ceiling, both still holding the sock."),
]

def run(shot):
    name, desc = shot
    out = f"stills/k_{name}.png"
    if os.path.exists(out): print("SKIP", name, flush=True); return
    for t in range(3):
        try:
            o = subprocess.run(["higgsfield","generate","create","nano_banana_pro",
                                "--prompt", f"{SP}{CARRY}{desc} {EN}",
                                "--image", STYLE, "--image", PLATES[FRAMING[name]], "--image", CARRYREF,
                                "--image", f"{CS}/frosya_lowpoly_v2.png", "--image", f"{CS}/vasya_lowpoly.png",
                                "--aspect_ratio","16:9","--resolution","2k","--wait","--json"],
                               capture_output=True, text=True, timeout=430)
            raw=o.stdout; i=raw.find("[")
            d=json.loads(raw[i:]) if i>=0 else json.loads(raw)
            rec=d[0] if isinstance(d,list) else d
            u=rec.get("result_url")
            if u: urllib.request.urlretrieve(u,out); print("OK",name,flush=True); return
            print("retry",t+1,name,rec.get("status"),flush=True)
        except Exception as e:
            print("retry",t+1,name,str(e)[:60],flush=True)
    print("FAIL",name,flush=True)

os.makedirs("stills", exist_ok=True)
with ThreadPoolExecutor(max_workers=6) as ex: list(ex.map(run, SHOTS))
print("SHOTS with matched framing done")
