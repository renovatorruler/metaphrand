"""Run ONE editorial pass via the LOCAL model (gemma3:27b) using the SAME editor bar,
so we can compare it against the Claude/Opus editor on identical input. Scenes 1-5."""
import sys, json, re, time
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from metaphrand.editor import BAR, show
from metaphrand.generate import OllamaClient

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
 "DIALOGUE is Hindi/Malwi — judge it as written; do not ask for English.")

full = open(f"{D}/EP1_PAGES.md").read()
def sc(n):
    tag = f"## SCENE {n} "
    if tag not in full:
        return ""
    start = full.index(tag)
    nxt = f"## SCENE {n+1} "
    end = full.index(nxt) if nxt in full else len(full)
    return full[start:end].strip()

chunk = "\n\n".join(s for n in range(1, 6) if (s := sc(n)))
prompt = BAR.replace("{context}", ctx) + "\n\n=== DRAFT 1 ===\n" + chunk

print(f"[local editor] model=gemma3:27b  prompt={len(prompt)} chars  scenes 1-5",
      flush=True)
t0 = time.time()
client = OllamaClient(model="gemma3:27b", json_mode=True, temperature=0.3, timeout=1200)
raw = client.complete(prompt)
dt = time.time() - t0
print(f"[generated in {dt:.0f}s]\n", flush=True)

print("=== RAW LOCAL OUTPUT ===")
print(raw)
print("\n=== PARSED THROUGH editor.show() ===")
m = re.search(r"\{.*\}", raw, re.S)
try:
    led = json.loads(m.group()) if m else {"verdict": "?", "raw": raw[:1000]}
except Exception:
    led = {"verdict": "?", "raw": raw[:1000]}
print(show(led))
