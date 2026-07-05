"""Run the REAL local editorial gate — metaphrand.naturalness (The One Law) — over EP1.
This is the line-by-line 'arranged for effect' critic on the local model, not the generic craft bar."""
import sys, time
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from metaphrand.naturalness import audit, report
from metaphrand.generate import OllamaClient

path = sys.argv[1] if len(sys.argv) > 1 else "/Users/dusty/dev/brehon-law/stories/amal/EP1_PAGES.md"
text = open(path).read()
client = OllamaClient(model="gemma3:27b", json_mode=True, temperature=0.2, timeout=1800)
print(f"[The One Law] local gemma3:27b, line-by-line audit of {path}...", flush=True)
t0 = time.time()
flags = audit(text, client, max_lines=300)
print(f"[done in {time.time()-t0:.0f}s]\n", flush=True)
print(report(flags))
