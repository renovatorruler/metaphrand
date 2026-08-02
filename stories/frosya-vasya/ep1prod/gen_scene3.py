"""Scene 3 «Там же, чуть позже» — prop, stills, clips, music.
Approved cut: SCENE3_CUTLIST.md. Same set as Scene 2 (за печкой).
Order: prop plate first (it anchors the list in every shot), then stills, clips, music.
"""
import subprocess, json, urllib.request, os
from concurrent.futures import ThreadPoolExecutor

CS = "../charsheets"
STYLE = "856a99ee-5cc9-4fad-ad8d-998d79edb4f4"  # pinned low-poly key — never re-resolve
PLATE = "plates/s2_home_wide.png"
PROP = "plates/prop_list.png"
MAMA = f"{CS}/mama_lowpoly_v1.png"
FROSYA = f"{CS}/frosya_lowpoly_v2.png"
VASYA = f"{CS}/vasya_lowpoly.png"

ST = ("STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY — low poly 3D, visible flat "
      "triangular facets, hard polygon edges, flat-shaded surfaces, rich warm saturated colours, cinematic warm "
      "hearth light and deep coloured shadow. ")

PLACE = ("LOCATION REFERENCE: the place image is THE SAME home behind the stove as the reference — the same warm brick "
         "wall, the same wooden thread-spool table with cork stools, the same matchbox beds, the same glowing bulb "
         "lamp, the same thimble and steaming kettle, the same hearth glow from the right. Match it EXACTLY. ")

FAMILY = ("They are домовые — tiny Slavic folklore HOUSE SPIRIT creatures, not humans. Everyone matches their attached "
          "LOCKED character reference EXACTLY: deep warm-brown button noses, freckles, consistent medium brown hair, "
          "no blond. BAREFOOT. ")

M_DESC = ("МАМА: round dumpling-shaped mother house spirit, candy-wrapper kerchief with a knot, patched apron, warm "
          "half-lidded calm eyes; baby РУСЯ (thin, ochre onesie) perched on her arm; baby МУСЯ (round, pink onesie) "
          "asleep against her back. ")
F_DESC = ("ФРОСЯ: long wavy dark-brown hair, whittled pencil stub above one ear, small orange flower on the other, "
          "finer soft brows, floral patchwork dress, pouch with an enormous safety pin; her body is two and a half of "
          "her own head-heights tall, thin spindly arms and legs. ")
V_DESC = ("ВАСЯ: short spiky warm-brown hair, THICK DARK WINGED eyebrows with a pointed outer flick, gap-toothed "
          "mouth, boyish patchwork clothes, pale wrist-thick shoelace belt with an aglet tail; his body is two and a "
          "half of his own head-heights tall, head as big as his torso, thin spindly arms and legs. ")

LIST_DESC = ("THE LIST: the prop image is the LOCKED chore list — a creased strip of sweet-wrapper paper, matte pale "
             "inner side showing, completely BLANK with no writing, big as a bedsheet relative to the tiny house "
             "spirits. Its look never changes. ")

NEG = ("NEGATIVE: no text, no letters, no writing, no numbers, no extra characters, no humans, no looking at the "
       "camera, no pointed ears, no shoes, no watermark, no photorealism, nothing scary. ")

MOUTH = "Mouth GENTLY CLOSED, relaxed — this face will be animated for dialogue later. "

PROP_PROMPT = (ST +
  "PROP SHEET on a plain warm neutral background: a single strip of sweet-wrapper paper — a rectangle of thin "
  "crinkly candy-wrapper foil-paper, its matte pale inner side facing the viewer, COMPLETELY BLANK, softly creased "
  "from having been rolled up, edges slightly curled. Low poly faceted rendering of the creases. Nothing else in "
  "frame. NEGATIVE: no text, no letters, no writing, no logos, no characters, no watermark, no photorealism.")

STILLS = [
 ("s3_mama_list", [STYLE, PLATE, PROP, MAMA],
  "SHOT: MEDIUM CLOSE on МАМА standing by the spool table, holding the blank creased wrapper-strip list open in one "
  "hand at chest height, reading it over calmly, eyes down on the strip. РУСЯ on her other arm has grabbed hold of "
  "МАМА's EAR with one tiny hand and holds it contentedly. " + MOUTH + "Warm hearth light across her face."),
 ("s3_frosya_reads", [STYLE, PLATE, PROP, FROSYA],
  "SHOT: MEDIUM CLOSE on ФРОСЯ holding the blank wrapper-strip list open in both hands just below her chin, chin up, "
  "proud and businesslike, eyes on the strip. " + MOUTH + "Warm hearth light on her face."),
 ("s3_vasya_waits", [STYLE, PLATE, VASYA],
  "SHOT: MEDIUM on ВАСЯ standing by a cork stool, caught mid-bounce on his bare toes, fists tight at his sides with "
  "excitement, eyes shining, waiting to hear his name. " + MOUTH),
 ("s3_vasya_moloko", [STYLE, PLATE, VASYA],
  "SHOT: CLOSE on ВАСЯ lit up with joy, arms flung up over his head, chest out, eyes wide and delighted, brows high. "
  + MOUTH),
 ("s3_frosya_kuvshin", [STYLE, PLATE, FROSYA],
  "SHOT: MEDIUM CLOSE on ФРОСЯ being the older sister: one hand out flat palm-up in a calm 'let me handle it' "
  "gesture, head tilted, brows level, a small knowing smile. " + MOUTH),
 ("s3_vasya_sam", [STYLE, PLATE, VASYA],
  "SHOT: CLOSE-UP, the key shot of the episode. ВАСЯ has just stopped himself from shouting: chest full of held "
  "breath, shoulders up, both hands pressed flat against his sides, chin lifted, looking up and off-frame at his "
  "mother with careful, earnest, hopeful eyes. His thick winged brows keep their exact shape, ONLY rotated so the "
  "inner ends lift. " + MOUTH + "Warm hearth light, quiet moment."),
 ("s3_beat", [STYLE, PLATE, MAMA, VASYA],
  "SHOT: MEDIUM TWO-SHOT, quiet held beat. МАМА on the left looks down at ВАСЯ on the right; he looks up at her. "
  "Nobody moves. Her expression is warm and measuring; his is hopeful and still. Both mouths closed. МАМА is much "
  "rounder and taller than the small thin boy spirit. Warm hearth light between them."),
 ("s3_mama_delo", [STYLE, PLATE, MAMA],
  "SHOT: CLOSE on МАМА, warm and serious at once — the look of a mother handing over a real job: soft half-lidded "
  "eyes, gentle level brows, the faintest proud smile. РУСЯ's tiny hand still holds her ear from off-shoulder. "
  + MOUTH + "Warm hearth light."),
 ("s3_vasya_listens", [STYLE, PLATE, VASYA],
  "SHOT: CLOSE on ВАСЯ listening as the job becomes real: eyes very wide, solemn, awed, brows lifted at the inner "
  "ends, body very still. The size of the task is landing on him. " + MOUTH),
]

CLIPS = [
 ("s3_c1_list", [STYLE, PLATE, PROP, MAMA],
  "SCENE: the warm home behind the stove; МАМА stands by the spool table holding the rolled-up blank wrapper-strip "
  "list; РУСЯ the thin baby house spirit rides on her other arm. "
  "MOTION: МАМА unrolls the creased strip with both hands and it springs open with a papery crackle; РУСЯ silently "
  "reaches over and hauls the near corner of the strip toward her open mouth; without even glancing down МАМА lifts "
  "the strip smoothly up out of the baby's reach; РУСЯ, completely unbothered, reaches up and takes hold of МАМА's "
  "EAR instead and holds it. МАМА keeps reading the blank strip. Gentle domestic rhythm, warm hearth light, small "
  "dust motes. The camera is a slow gentle push-in. AUDIO: none needed."),
 ("s3_c11_bolt", [STYLE, PLATE, FROSYA, VASYA],
  "SCENE: the warm home behind the stove, by the doorway at the left edge of the set; ВАСЯ and ФРОСЯ stand near the "
  "spool table. "
  "MOTION: ВАСЯ spins on his heel and dashes off toward the doorway at screen left, arms pumping, bare feet "
  "pattering, and vanishes out of frame; ФРОСЯ stays behind alone, folds her arms, looks after him, and mutters to "
  "herself, shoulders slumping in a small grumble; she idly scuffs one bare foot against the floorboards. Warm "
  "hearth light; the room feels suddenly quieter. Camera locked off. AUDIO: none needed."),
]

def submit_image(prompt, refs, out_path, ar="16:9"):
    for attempt in range(3):
        try:
            cmd = ["higgsfield","generate","create","nano_banana_pro","--prompt",prompt]
            for r in refs: cmd += ["--image", r]
            cmd += ["--aspect_ratio",ar,"--resolution","2k","--wait","--json"]
            o = subprocess.run(cmd, capture_output=True, text=True, timeout=430)
            raw=o.stdout; i=raw.find("[")
            d=json.loads(raw[i:]) if i>=0 else json.loads(raw)
            rec=d[0] if isinstance(d,list) else d
            u=rec.get("result_url")
            if u:
                urllib.request.urlretrieve(u,out_path); print("OK",out_path,flush=True); return True
            print("retry",attempt+1,out_path,rec.get("status"),(o.stderr or "")[:80],flush=True)
        except Exception as e:
            print("retry",attempt+1,out_path,str(e)[:80],flush=True)
    print("FAIL",out_path,flush=True); return False

def submit_clip(name, refs, desc):
    out=f"clips/{name}.mp4"
    if os.path.exists(out): print("SKIP",name,flush=True); return
    prompt = ST + PLACE + FAMILY + M_DESC + F_DESC + V_DESC + LIST_DESC + desc + " " + NEG
    for attempt in range(3):
        try:
            cmd=["higgsfield","generate","create","gemini_omni","--prompt",prompt]
            for r in refs: cmd += ["--image", r]
            cmd += ["--duration","10","--aspect_ratio","16:9","--resolution","720p",
                    "--wait","--wait-timeout","12m","--json"]
            o=subprocess.run(cmd, capture_output=True, text=True, timeout=800)
            raw=o.stdout; i=raw.find("[")
            d=json.loads(raw[i:]) if i>=0 else json.loads(raw)
            rec=d[0] if isinstance(d,list) else d
            u=rec.get("result_url")
            if u:
                urllib.request.urlretrieve(u,out); print("OK",name,flush=True); return
            print("retry",attempt+1,name,rec.get("status"),(o.stderr or "")[:80],flush=True)
        except Exception as e:
            print("retry",attempt+1,name,str(e)[:80],flush=True)
    print("FAIL",name,flush=True)

os.makedirs("stills", exist_ok=True); os.makedirs("clips", exist_ok=True)

# 1. prop plate (anchors the list everywhere)
if not os.path.exists(PROP):
    if not submit_image(PROP_PROMPT, [STYLE], PROP):
        raise SystemExit("prop failed — stop before wasting credits on stills")

# 2. stills in parallel
def run_still(s):
    name, refs, desc = s
    out=f"stills/{name}.png"
    if os.path.exists(out): print("SKIP",name,flush=True); return
    prompt = ST + PLACE + FAMILY + M_DESC + F_DESC + V_DESC + LIST_DESC + desc + " " + NEG
    submit_image(prompt, refs, out)

with ThreadPoolExecutor(max_workers=5) as ex:
    list(ex.map(run_still, STILLS))

# 3. clips in parallel
with ThreadPoolExecutor(max_workers=2) as ex:
    list(ex.map(lambda c: submit_clip(*c[0:1]+c[1:]), [(c[0],c[1],c[2]) for c in CLIPS]))

# 4. music bed
if not os.path.exists("sfx/music_s3.mp3"):
    try:
        o=subprocess.run(["higgsfield","generate","create","sonilo_music","--prompt",
            "Warm cozy domestic morning underscore for a children's cartoon: soft pizzicato strings, "
            "light woodwind, gentle celesta, unhurried and homely; a tender quiet pause in the middle; "
            "ends with a small proud determined march flourish. No vocals.",
            "--duration","50","--wait","--json"], capture_output=True, text=True, timeout=500)
        raw=o.stdout; i=raw.find("[")
        d=json.loads(raw[i:]) if i>=0 else json.loads(raw)
        rec=d[0] if isinstance(d,list) else d
        u=rec.get("result_url")
        if u: urllib.request.urlretrieve(u,"sfx/music_s3.mp3"); print("OK music_s3",flush=True)
        else: print("MUSIC-FAIL",rec.get("status"),flush=True)
    except Exception as e:
        print("MUSIC-FAIL",str(e)[:100],flush=True)

print("SCENE3 GEN DONE",flush=True)
