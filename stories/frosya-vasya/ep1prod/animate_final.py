# Scene 1 motion — Kuku pipeline: gemini_omni, 10s, style key FIRST (pinned, never re-resolved),
# SCENE/MOTION/AUDIO prompts, full negative block, skip-if-exists, 3x retry.
import subprocess, json, urllib.request, os
from concurrent.futures import ThreadPoolExecutor

STYLE = "856a99ee-5cc9-4fad-ad8d-998d79edb4f4"   # PINNED for the whole show

CP = ("STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY — low poly 3D, flat triangular "
      "facets, hard polygon edges, warm saturated colours, non-photorealistic, illustrated, not a photo. "
      "SCENE REFERENCE: the SECOND attached image IS this exact shot — the same two tiny house-spirit characters, the "
      "same enormous striped sock carried the same way, the same under-floor tunnel, the same framing and the same "
      "lighting. Animate THIS EXACT scene; keep every character, the sock, the set and the light exactly as shown.")

EN = ("Full-bleed scene, camera INSIDE the world. NEGATIVE: no third character, no extra characters, NO giant foot or "
      "leg or hand entering the tunnel, no human body parts, no character changing size or position, no sock changing "
      "colour or size, no readable text, no letters, no numbers, no watermark, no photorealism, no live action, "
      "nothing scary, nobody in danger.")

SHOTS = [
 ("m_k_f1_haul",
  "SCENE: the two children haul the enormous striped sock leftward through the tunnel, the girl under the cuff, the boy "
  "pushing behind, both straining. "
  "MOTION: they take slow heavy steps toward the left, bodies rocking with effort, the sock sliding along behind them, "
  "small dust puffs at their bare feet, dust motes drifting in the warm light shafts. Slow camera pan left following "
  "them. AUDIO: none needed."),
 ("m_k_f2_asks",
  "SCENE: closer on the boy carrying his side of the sock behind his sister, turning his head toward her mid-question, "
  "out of breath. "
  "MOTION: he keeps pushing while his mouth moves as he puffs out a question, eyebrows lifting, chest heaving, hair "
  "shifting slightly; the girl's arm stays braced on the cuff; dust drifts in the light. Very slow push in. "
  "AUDIO: none needed."),
 ("m_k_f3_answers",
  "SCENE: the two still carrying the sock, the girl answering over her shoulder mid-sentence, chin up, unbothered. "
  "MOTION: she keeps walking and talking, mouth moving, her long wavy hair swaying gently, the sock inching along "
  "behind them; dust motes drift in the beams. Very slow push in. AUDIO: none needed."),
 ("m_k_f4_hears",
  "SCENE: the two stop mid-step under the beams, the girl's head tilted up, listening hard to something faint above; "
  "the boy still straining, not yet noticing. "
  "MOTION: almost still — her eyes narrow and flick upward, her head tilts a little more, his body keeps a slight "
  "straining sway, dust drifts slowly through the light. The camera is locked off. AUDIO: none needed."),
 ("m_k_f5_zamri",
  "SCENE: the girl's arm shot up in a sharp stop gesture, her face urgent, the boy jolting to a halt behind her, both "
  "still holding the sock. "
  "MOTION: her raised hand snaps up and freezes; both children lock rigid and stop moving entirely, holding their "
  "breath; after the freeze only dust drifts down through the light. The camera is locked off. AUDIO: none needed."),
 ("m_k_f6_dust",
  "SCENE: the tunnel gone dim and cold — the light from the overhead gap is blocked — with pale dust pouring down onto "
  "the two frozen children still holding the sock, heads tilted up. "
  "MOTION: the dust streams steadily down through the gloom, settling on their hair and shoulders; the children stay "
  "perfectly frozen, only their wide eyes blinking once; a very slight camera shake at the start as the impact lands, "
  "then locked off. At the very end the gloom begins to lift slightly as the light starts to return. AUDIO: none needed."),
]

def run(shot):
    name, desc = shot
    out = f"clips/n_{name}.mp4"
    if os.path.exists(out): print("SKIP", name, flush=True); return
    for t in range(3):
        try:
            o = subprocess.run(["higgsfield","generate","create","gemini_omni",
                                "--prompt", f"{CP} {desc} {EN}",
                                "--image", STYLE, "--image", f"stills/{name}.png",
                                "--duration","10","--aspect_ratio","16:9","--resolution","720p",
                                "--wait","--wait-timeout","12m","--json"],
                               capture_output=True, text=True, timeout=800)
            raw=o.stdout; i=raw.find("[")
            d=json.loads(raw[i:]) if i>=0 else json.loads(raw)
            rec=d[0] if isinstance(d,list) else d
            u=rec.get("result_url")
            if u: urllib.request.urlretrieve(u,out); print("OK",name,flush=True); return
            print("retry",t+1,name,rec.get("status"),flush=True)
        except Exception as e:
            print("retry",t+1,name,str(e)[:60],flush=True)
    print("FAIL",name,flush=True)

os.makedirs("clips", exist_ok=True)
with ThreadPoolExecutor(max_workers=6) as ex: list(ex.map(run,SHOTS))
print("CLIPS:", sorted(f for f in os.listdir("clips") if f.startswith("n_")))
