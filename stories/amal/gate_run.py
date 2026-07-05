"""Run the craft-gate stack on EP1_PAGES_v2.md for a scene range and write a report.
The goal's step-2 gate, reusable per movement.

    python stories/amal/gate_run.py [first_scene] [last_scene]   # default: whole file
    python stories/amal/gate_run.py --dry                        # parse only, no model
"""
import os
import sys

sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from metaphrand import blind_attribution as ba  # noqa: E402
from metaphrand import naturalness, scene_craft  # noqa: E402

D = "/Users/dusty/dev/brehon-law/stories/amal"
FILE = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--file=")), "EP1_PAGES_v2.md")
STEM = FILE.rsplit(".", 1)[0]
text = open(f"{D}/{FILE}", encoding="utf-8").read()
cards = open(f"{D}/VOICE_CARDS.md", encoding="utf-8").read()
scenes = scene_craft.split_scenes(text)

# Hindi cue -> English card slug, so blind-attribution can score the carded cast.
ALIAS = {"रतन": "ratan", "देवा": "deva", "मिश्रा": "mishra", "भेरूलाल": "bherulal",
         "कांता": "kanta", "अम्मा": "amma", "सुगना": "sugna", "मंजू": "manju",
         "गोविंद": "govind", "भँवर": "bhanwar", "चारण": "charan", "धनराज": "dhanraj",
         "राणा": "rana", "लीला": "leela"}

dry = "--dry" in sys.argv
args = [a for a in sys.argv[1:] if not a.startswith("--")]
lo = int(args[0]) if args else 1
hi = int(args[1]) if len(args) > 1 else len(scenes)
ranged = "\n\n".join(b for i, (h, b) in enumerate(scenes, 1) if lo <= i <= hi)

if dry:
    print(f"{len(scenes)} scenes; range {lo}-{hi}")
    pairs = ba.parse_dialogue(ranged, ALIAS)
    cast = set(ba.keys_from_cards(cards))
    print("dialogue lines:", len(pairs), "| in-cast:", sum(1 for k, _ in pairs if k in cast))
    from collections import Counter
    print("per character:", dict(Counter(k for k, _ in pairs if k in cast)))
    sys.exit(0)

from metaphrand.generate import OllamaClient  # noqa: E402

client = OllamaClient(json_mode=True)
out = ["=== SCENE CRAFT (Mercurio) ==="]
for i, (h, b) in enumerate(scenes, 1):
    if i < lo or i > hi or len(b) < 40:
        continue
    out.append(scene_craft.report(scene_craft.audit(b, client), f"S{i} {h[:46]}"))
    out.append("")
out.append("=== ONE LAW (naturalness) ===")
out.append(naturalness.report(naturalness.audit(ranged, client, max_lines=140)))
out += ["", "=== BLIND ATTRIBUTION (voices) ==="]
out.append(ba.report(ba.audit(ranged, cards, client, ALIAS, max_lines=140)))

report = "\n".join(out)
os.makedirs(f"{D}/.passes", exist_ok=True)
open(f"{D}/.passes/gates_{STEM}_s{lo}-{hi}.txt", "w", encoding="utf-8").write(report)
print(report, flush=True)
