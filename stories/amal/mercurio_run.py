import sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from metaphrand import scene_craft as sc
from metaphrand.generate import OllamaClient
FILE = sys.argv[1] if len(sys.argv) > 1 else "stories/amal/EP2_PAGES.md"
text = open(FILE, encoding="utf-8").read()
scenes = sc.split_scenes(text)
client = OllamaClient(json_mode=True)
npass = 0; total = 0
for heading, body in scenes:
    if len(body) < 60 or "TITLE SEQUENCE" in heading.upper():
        continue
    total += 1
    checks = sc.audit(body, client)
    core_fail = [c.id for c in checks if c.core and not c.passed]
    npass += not core_fail
    print(sc.report(checks, heading[:50]), flush=True)
    print(flush=True)
print(f"== {npass}/{total} scenes pass the Mercurio core rubric ==", flush=True)
