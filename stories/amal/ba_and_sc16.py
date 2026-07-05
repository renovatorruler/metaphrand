import sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from metaphrand import blind_attribution as ba, scene_craft
from metaphrand.generate import OllamaClient
D = "/Users/dusty/dev/brehon-law/stories/amal"
text = open(f"{D}/EP2_PAGES.md", encoding="utf-8").read()
cards = open(f"{D}/VOICE_CARDS.md", encoding="utf-8").read()
ALIAS = {"रतन": "ratan", "देवा": "deva", "मिश्रा": "mishra", "भेरूलाल": "bherulal",
         "कांता": "kanta", "अम्मा": "amma", "सुगना": "sugna", "मंजू": "manju",
         "गोविंद": "govind", "भँवर": "bhanwar", "चारण": "charan", "धनराज": "dhanraj",
         "राणा": "rana", "लीला": "leela"}
scenes = scene_craft.split_scenes(text)
client = OllamaClient(json_mode=True)

sc16 = [b for h, b in scenes if h.startswith("SCENE 16")][0]
print("=== MERCURIO — Sc16 (after reversal sharpen) ===", flush=True)
print(scene_craft.report(scene_craft.audit(sc16, client), "S16 THE OFFER"), flush=True)

ranged = "\n\n".join(b for h, b in scenes)
print("\n=== BLIND ATTRIBUTION — full episode ===", flush=True)
print(ba.report(ba.audit(ranged, cards, client, ALIAS, max_lines=220)), flush=True)
print("\n[done]", flush=True)
