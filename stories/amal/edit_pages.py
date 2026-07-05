"""Run EP1 pages 8-20 through the stateful editor, two focused passes."""
import sys, uuid
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from metaphrand.editor import Editor, show

D = "/Users/dusty/dev/brehon-law/stories/amal"
ctx = (
 "INSPECTOR RATAN SINGH PANWAR, CBN (a cop), ~58, a fallen Rajput (Parmar, descendant of Malwa's kings) "
 "reduced by 25 years of surrender to a bought rubber-stamp who signs deaths off as accidents; a quiet "
 "doda (poppy-husk-tea) amli. Spine: a bought man redeems himself by keeping his word and dies for it — "
 "rough/melancholy, never triumphant. EP1 = ESTABLISHMENT (the cage), not investigation; the only turn is "
 "the last shot (he sends the dead girl to postmortem instead of signing 'accident'). DEVA = young "
 "constable who left a city posting to serve under the storied 'Ratan Singh Panwar'; reverence vs "
 "debasement is the engine.\n"
 "HELD CARDS (guard hard — do NOT let any scene leak these):\n"
 "  1. The dead girl's mother SUGNA (Bherulal's wife; a STRANGER to Ratan by blood — only the buried train links them, the series' deepest held card) is the eventual KILLER — revealed ~ep5. In "
 "EP1 she is ONLY the grieving mother; nothing may hint she did it (and nothing may hint any tie to Ratan).\n"
 "  2. 'Hamir' = both the legendary Jhujhar ANCESTOR and Ratan's pawned signet RING. The Than scene must "
 "read Hamir as the ANCESTOR/legend (reinforcing the cold-open misdirection that the bloodied saka hand is "
 "the ancestor, not Ratan); it must NOT reveal Hamir is a ring, nor weld the cold-open hand to Ratan.\n"
 "  3. The marriage-deal horror is the SELLING (debt > daughter), never religion (all Hindu).\n"
 "CRAFT: Malwi/Hindi dialogue; show-don't-tell, NO authorial grading of the moment or poignancy-reach "
 "closers (clear-pane); every scene a fight with a turn; grounded surface (Paatal Lok), operatic/mythic "
 "heart in the bones never in a mouth; the women's world and the Malwa texture must breathe.")

full = open(f"{D}/EP1_PAGES.md").read()
def sc(n):
    start = full.index(f"## SCENE {n} ")
    try: end = full.index(f"## SCENE {n+1} ", start)
    except ValueError: end = len(full)
    return full[start:end].strip()

ed1 = Editor(context=ctx, session_id=str(uuid.uuid4()))
p1 = "\n\n".join(f"=== EP1 SCENE {n} ===\n{sc(n)}" for n in range(8, 15))
print("########## PASS 1 — SCENES 8-14 ##########")
print(show(ed1.review(p1)))

ed2 = Editor(context=ctx, session_id=str(uuid.uuid4()))
p2 = "\n\n".join(f"=== EP1 SCENE {n} ===\n{sc(n)}" for n in range(15, 21))
print("\n########## PASS 2 — SCENES 15-20 ##########")
print(show(ed2.review(p2)))
