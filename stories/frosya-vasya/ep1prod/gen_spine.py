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

STYLE_TXT = ("Low poly 3D, visible flat triangular facets, hard polygon edges, flat-shaded surfaces, rich warm saturated "
             "colours, cinematic lighting with warm shafts and deep coloured shadow, glowing dust motes. ")

PLACE = ("LOCATION REFERENCE: the SECOND attached image is THE SET — match it EXACTLY: the same wide worn floorboards, the "
         "same colossal overhead joists, the same shallow back wall of boards over foundation stone, the same cobwebs high "
         "in the beams, the same warm golden shafts of light falling in pools. The same fixed props live in this tunnel: a "
         "huge wooden THREAD SPOOL, a giant four-hole shirt BUTTON, a dark THIMBLE. The tunnel continues off both sides. ")

PROP = ("PROP REFERENCE: the THIRD attached image is the LOCKED SOCK — broad stripes in a fixed order, CREAM, RUST-RED, "
        "CREAM, DEEP TEAL-BLUE, repeating, with a plain cream ribbed cuff. Its colours and pattern NEVER change. ")

# ---- THE ONE CANONICAL CARRY — repeated verbatim in every shot ----
# ---- THE ONE CANONICAL CARRY — repeated verbatim in every shot ----
CARRY = ("THE SOCK AND HOW THEY MOVE IT — IDENTICAL IN EVERY SHOT, NEVER CHANGES: it is a LIMP, FLOPPY, EMPTY knitted "
         "woollen SOCK, unmistakably a sock — you can clearly see its rounded TOE at one end, the bulge of its HEEL, and "
         "its cream ribbed CUFF at the other end. It is ENORMOUS, far longer than either child is tall. "
         "IT IS NEVER LIFTED INTO THE AIR AND NEVER HELD HORIZONTALLY LIKE A LOG OR A TUBE OR A ROLLED RUG. It lies flat "
         "along the floorboards, slack and sagging under its own weight, and they DRAG it. "
         "ФРОСЯ on the LEFT and ВАСЯ on the RIGHT each grip the edge of the cream CUFF with both hands, down at about "
         "waist height, leaning forward and hauling it along the ground behind them. The long body of the sock slumps "
         "across the boards behind them, creasing and folding where it drags, with the rounded TOE end trailing away off "
         "the RIGHT edge of the frame. Neither child is ever behind the sock, on top of it, or inside it. ")

CHARS = ("CHARACTER REFERENCES: the FOURTH image is ФРОСЯ, the FIFTH is ВАСЯ — match both LOCKED designs EXACTLY. "
         "ФРОСЯ: long wavy dark-brown hair, whittled PENCIL STUB above one ear, small ORANGE FLOWER on the other, softer "
         "defined brows, deep-brown button nose, freckles, smile with ONE MISSING BOTTOM TOOTH, floral patchwork dress, "
         "pouch fastened by an ENORMOUS safety pin. "
         "ВАСЯ: spiky warm-brown hair, THICK DARK WINGED eyebrows with a pointed flick, deep-brown button nose, freckles, "
         "gap-toothed mouth, boyish patchwork clothes, pale wrist-thick SHOELACE belt wrapped twice with an AGLET tail. "
         "BOTH BAREFOOT. They are домовые — tiny house spirits, not human children. ")

STAGING = ("STAGING RULES, ABSOLUTE: (1) ФРОСЯ is ALWAYS on the LEFT, ВАСЯ ALWAYS on the RIGHT — they never swap. "
           "(2) ФРОСЯ is ALWAYS about half a head TALLER than ВАСЯ. (3) Home is SCREEN LEFT; they always travel RIGHT TO "
           "LEFT and face LEFT while hauling. (4) Danger always comes from ABOVE. They never face the camera and never "
           "look at the viewer. ")

NEG = ("NEGATIVE: no third character, no extra characters, NO giant foot or leg or hand entering the tunnel, no human body "
       "parts in the shot, no looking at the camera, no facing the viewer, no tug of war, no sock changing colour or "
       "pattern, no small sock, no shoes, no text, no letters, no numbers, no watermark, no photorealism, nothing scary. ")

SHOTS = [
 ("a_haul_wide",
  "SHOT: WIDE, low three-quarter. The two carry the sock leftward along the tunnel, both facing LEFT, leaning into the "
  "weight, bare feet braced and skidding, dust puffing at their feet. Straining with effort. They are passing through a "
  "pool of warm shaft light. Open floor ahead of them at the left."),
 ("b_vasya_asks",
  "SHOT: MEDIUM CLOSE on ВАСЯ on the right, still carrying, facing LEFT. He turns his head toward his sister without "
  "stopping, mouth open mid-question, puffing and out of breath, brows raised and strained. ФРОСЯ's shoulder and hair at "
  "the left edge of frame, her hands still on the cuff. Warm light across his face."),
 ("c_frosya_answers",
  "SHOT: MEDIUM CLOSE on ФРОСЯ on the left, still carrying, facing LEFT, not looking back. She answers matter-of-factly "
  "and a little smugly, chin up, mouth open mid-sentence, brows level and certain. ВАСЯ's hands still on the cuff at the "
  "right edge. Warm light on her face."),
 ("d_frosya_hears",
  "SHOT: MEDIUM. The two are still carrying the sock, mid-step. ФРОСЯ has stopped walking and turned her head sharply, "
  "ear tilted UPWARD, eyes narrowed, listening hard to something very faint above — a floorboard creaking somewhere over "
  "their heads. Her mouth is closed. ВАСЯ, still mid-stride beside her, has not noticed anything yet and is still looking "
  "ahead to the left. NOTHING is falling; the air is clear; no shadow overhead; the ceiling is normal. Quiet, alert, the "
  "instant before danger."),
 ("e_zamri",
  "SHOT: MEDIUM three-quarter. ФРОСЯ has snapped one arm UP and BACK toward her brother in a sharp STOP gesture, her head "
  "tilted UP toward the ceiling, chin lifted, mouth open on a hissed urgent command. Her eyes are on the ceiling — she is "
  "NOT looking at the viewer. ВАСЯ is jolting to a halt beside her, one bare foot still off the ground, head snapping up, "
  "eyes wide, mouth open. Both still hold the sock cuff between them. STILL NO DUST FALLING and NO SHADOW yet — the air is "
  "clear. The split second of the warning."),
 ("f_boom_dust",
  "SHOT: MEDIUM WIDE, low angle. THE LIGHT IS BLOCKED FROM ABOVE. A giant has stepped across the gap in the floorboards "
  "directly overhead, so the warm shaft of light that was pouring down through that gap is now CUT OFF — the bright pool "
  "it made on the floor has vanished and the tunnel has dropped into sudden dim near-darkness, lit only by faint spill "
  "from the other gaps further along. The gap in the boards above reads as a dark blocked slot, NOT as a shadow shaped "
  "like a foot — there is NO foot, NO leg, NO silhouette of a body part anywhere; the light is simply obstructed. "
  "The impact shakes pale DUST loose from the boards and it pours down through the dimmed air onto the two children. "
  "Both are frozen rigid, still holding the sock cuff between them, heads tilted up, eyes wide and catching what little "
  "light remains, dust settling on their hair and shoulders."),
 ("g_held_still",
  "SHOT: WIDE, static. THE LIGHT HAS RETURNED — the giant's foot has lifted off the gap overhead and the warm shaft is "
  "pouring down through it again, its bright pool restored on the floor. The two stand frozen and tiny, still holding the "
  "sock cuff between them, utterly motionless, dwarfed by the colossal joists. Only the last of the shaken-loose dust "
  "drifts down through the returned light. Held breath, the quiet after danger."),
]

def run(shot):
    name, desc = shot
    out_path = f"stills/v5_{name}.png"
    if os.path.exists(out_path):
        print("SKIP", name, flush=True); return
    prompt = ("STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. " + STYLE_TXT
              + PLACE + PROP + CARRY + CHARS + STAGING + desc + " " + NEG)
    for attempt in range(3):
        try:
            mid = style_key()
            o = subprocess.run(["higgsfield","generate","create","nano_banana_pro","--prompt",prompt,
                                "--image",mid,"--image",PLATE,"--image",SOCK,
                                "--image",f"{CS}/frosya_lowpoly_v2.png","--image",f"{CS}/vasya_lowpoly.png",
                                "--aspect_ratio","16:9","--resolution","2k","--wait","--json"],
                               capture_output=True, text=True, timeout=430)
            raw = o.stdout; i = raw.find("[")
            d = json.loads(raw[i:]) if i >= 0 else json.loads(raw)
            rec = d[0] if isinstance(d, list) else d
            u = rec.get("result_url")
            if u:
                urllib.request.urlretrieve(u, out_path); print("OK", name, flush=True); return
            print("retry", attempt+1, name, rec.get("status"), flush=True)
        except Exception as e:
            print("retry", attempt+1, name, str(e)[:60], flush=True)
    print("FAIL", name, flush=True)

os.makedirs("stills", exist_ok=True)
with ThreadPoolExecutor(max_workers=7) as ex:
    list(ex.map(run, SHOTS))
print("DONE:", sorted(f for f in os.listdir("stills") if f.startswith("v5_")))
