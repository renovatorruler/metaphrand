import re
D = "/Users/dusty/dev/brehon-law/stories/amal"
ep = open(f"{D}/EP2_PAGES.md", encoding="utf-8").read()
rk = open(f"{D}/_m2_rework.md", encoding="utf-8").read()
chunks = re.split(r'@@(\d+)@@\n', rk); it = iter(chunks[1:])
gate = []
for num, body in zip(it, it):
    body = body.strip()
    title = re.search(r'## SCENE ' + num + r' — ([^\n]+)', ep).group(1)
    pat = re.compile(r'(## SCENE ' + num + r' — [^\n]+)\n\n.*?\n\n---', re.S)
    ep, n = pat.subn(lambda m: m.group(1) + "\n\n" + body + "\n\n---", ep, count=1)
    assert n == 1, f"scene {num} not matched"
    gate.append(f"## SCENE {num} — {title}\n\n{body}\n")
open(f"{D}/EP2_PAGES.md", "w", encoding="utf-8").write(ep)
open(f"{D}/_m2_gate.md", "w", encoding="utf-8").write("\n".join(gate))
print("swapped 14,15,16,34")
