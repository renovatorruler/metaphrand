import re
P = "/Users/dusty/dev/brehon-law/stories/amal/EP1.md"
text = open(P, encoding="utf-8").read()
parts = re.split(r'(?=^## )', text, flags=re.M)
pre, scenes = parts[0], parts[1:]
tag = lambda b: b.split('\n', 1)[0].strip()
i3 = next(i for i, b in enumerate(scenes) if tag(b) == '## दृश्य तीन')
b3 = scenes.pop(i3)                                   # cut the Mishra scene
i6 = next(i for i, b in enumerate(scenes) if tag(b) == '## दृश्य छह')
scenes.insert(i6 + 1, b3)                             # paste it after the postmortem
open(P, "w", encoding="utf-8").write(pre + ''.join(scenes))
print("NEW ORDER:")
for n, b in enumerate(scenes, 1):
    print(f"  {n:2d}. {tag(b)[3:]}")
