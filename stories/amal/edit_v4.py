"""Run the full v4 episode through the stateful editor, in chunks, fresh session per chunk."""
import sys, uuid
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from metaphrand.editor import Editor, show

D = "/Users/dusty/dev/brehon-law/stories/amal"
ctx = (
 "STORY: अमल, gritty realist Hindi crime drama, Malwa opium belt (register: Paatal Lok). "
 "PROTAGONIST: INSPECTOR RATAN SINGH PANWAR, CBN, ~58 — a fallen Rajput (Parmar, descendant of Malwa's "
 "kings) reduced by 25 years of surrender to a bought rubber-stamp who signs deaths off as accidents; a "
 "quiet doda (poppy-husk-tea) amli. SPINE: a bought man redeems himself by keeping his word and dies for "
 "it — rough/melancholy, never triumphant. EP1 = ESTABLISHMENT (the cage), NOT investigation; the ONLY "
 "turn is the last shot (Sc20: he sends the dead girl to postmortem instead of signing 'accident'). DEVA "
 "= young constable who left a city posting to serve under the storied 'Ratan Singh Panwar'; his "
 "reverence vs Ratan's debasement is the engine.\n"
 "HELD CARDS (must stay buried — flag any leak): (1) the dead girl's mother SUGNA (Bherulal's wife, a STRANGER to Ratan by blood, linked only by the buried train)"
 " is the eventual KILLER (revealed ~ep5); in EP1 she is ONLY the grieving mother."
 "(2) 'Hamir' = both the legendary Jhujhar ANCESTOR and Ratan's pawned signet RING; the Than scene (Sc9) "
 "must read Hamir as the ancestor/legend, reinforcing the cold-open misdirection (Sc1's bloodied saka "
 "hand reads as the ancestor, not Ratan), and must NOT reveal Hamir is a ring or weld the cold-open hand "
 "to Ratan. (3) the marriage-deal horror is the SELLING (debt > daughter), never religion (all Hindu).\n"
 "DIALOGUE is Hindi/Malwi (नी, छोरी, म्हारी, काई) — judge it as written; do not ask for English.\n"
 "THIS IS DRAFT v4: the STRUCTURE already passed your bar in earlier drafts. v4 rewrote the ENGLISH "
 "ACTION/DESCRIPTION prose to fix a pervasive AI tic (staccato fragments + facts appended after the "
 "sentence, e.g. 'A clipboard. He writes.'). Judge whether the new prose holds the whole BAR — especially "
 "CLEAR PANE, SHOW-DON'T-TELL, DIALOGUE REALISM — and confirm the staccato was NOT merely traded for a "
 "new tic (baggy run-ons, polysyndeton 'and...and...and', over-explaining). Keep the held cards buried. "
 "Be hard but fair; 'ship' if it's good enough to shoot.")

full = open(f"{D}/EP1_PAGES.md").read()
def sc(n):
    tag = f"## SCENE {n} "
    if tag not in full:
        return ""
    start = full.index(tag)
    nxt = f"## SCENE {n+1} "
    end = full.index(nxt) if nxt in full else len(full)
    return full[start:end].strip()

chunks = [(1, 5), (6, 10), (11, 15), (16, 20)]
for a, b in chunks:
    ed = Editor(context=ctx, session_id=str(uuid.uuid4()))
    draft = "\n\n".join(s for n in range(a, b + 1) if (s := sc(n)))
    print(f"\n########## SCENES {a}-{b} ##########", flush=True)
    print(show(ed.review(draft)), flush=True)
print("\n########## EDITOR PASS COMPLETE ##########", flush=True)
