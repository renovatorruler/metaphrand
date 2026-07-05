"""Merge the 20 spine scenes (EP1_PAGES.md) + 17 new (new_scenes.md) into a renumbered 37-scene file.
Existing bodies are preserved verbatim; only the header numbers change."""
import re

D = "/Users/dusty/dev/brehon-law/stories/amal"

# old spine number -> expanded-blueprint number
OLD_TO_EXP = {1:1, 2:2, 3:4, 4:6, 5:7, 6:8, 7:10, 8:12, 9:14, 10:16,
              11:18, 12:20, 13:24, 14:27, 15:29, 16:30, 17:32, 18:35, 19:36, 20:37}

def parse(text):
    parts = re.split(r'(?m)^## SCENE (\d+) — (.+)$', text)
    pre = parts[0]
    scenes = []
    i = 1
    while i + 2 < len(parts) + 1 and i < len(parts):
        num, title, body = int(parts[i]), parts[i+1].strip(), parts[i+2]
        scenes.append((num, title, body))
        i += 3
    return pre, scenes

pre, spine = parse(open(f"{D}/EP1_PAGES.md").read())
_, new = parse(open(f"{D}/new_scenes.md").read())

merged = {}
for num, title, body in spine:
    merged[OLD_TO_EXP[num]] = (title, body)
for num, title, body in new:
    merged[num] = (title, body)

assert sorted(merged) == list(range(1, 38)), f"expected 1..37, got {sorted(merged)}"

pre = pre.replace("20 scenes, ~50 min", "37 scenes, ~50 min").rstrip()
out = [pre, ""]
for i in range(1, 38):
    title, body = merged[i]
    out.append(f"## SCENE {i} — {title}")
    b = body.strip("\n")
    if b:
        out.append("")
        out.append(b)
    out.append("")

open(f"{D}/EP1_PAGES_merged.md", "w", encoding="utf-8").write("\n".join(out).rstrip() + "\n")
print(f"merged {len(merged)} scenes -> EP1_PAGES_merged.md")
print("new-scene titles placed at:", sorted(n for n in merged if n in
      {3,5,9,11,13,15,17,19,21,22,23,25,26,28,31,33,34}))
