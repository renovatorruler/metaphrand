import re
D = "/Users/dusty/dev/brehon-law/stories/amal"
raw = open(f"{D}/EP2_PAGES.md", encoding="utf-8").read()

# --- parse existing scenes ---
i = raw.index("\n## SCENE 1")
preamble = re.sub(r'(\s*---\s*)+$', '', raw[:i]).rstrip()
parts = re.split(r'\n## SCENE ', raw[i:])
scenes = {}
for part in parts[1:]:
    m = re.match(r'(\d+)\s+—\s+(.+)', part)
    num = int(m.group(1)); title = m.group(2).strip()
    content = part[m.end():]
    content = re.sub(r'\*\[End (?:Movement \d+|of Episode 2)\.\]\*', '', content)
    content = re.sub(r'(\s*---\s*)+$', '', content).strip()
    scenes[num] = (title, content)

# --- parse new/reworked scenes ---
rs = open(f"{D}/_restructure_scenes.md", encoding="utf-8").read()
chunks = re.split(r'@@(\w+)@@\n', rs)
restruct = {}
it = iter(chunks[1:])
for key, body in zip(it, it):
    title, content = body.strip().split('\n', 1)
    restruct[key] = (title.strip(), content.strip())

# --- new order (int = keep old scene; str = new/reworked key) ---
ORDER = [1, 2, 'rana', 3, 'photo', 4, 5, 'bighouse', 6, 7, 8, 9,
         10, 11, 12, 13, 14, 15,
         16, 17, 18, 19, 20, 21, 22,
         'marzi', 24, 25, 26, 27, 28, 29, 30,
         31, 32, 33, 34, 35, 36]
MOVE_AFTER = {9: 1, 15: 2, 22: 3, 30: 4}   # old scene num -> movement that ends after it

out = [preamble + "\n\n"]
n = 0
for item in ORDER:
    n += 1
    title, content = (scenes[item] if isinstance(item, int) else restruct[item])
    out.append(f"---\n\n## SCENE {n} — {title}\n\n{content}\n\n")
    if isinstance(item, int) and item in MOVE_AFTER:
        out.append(f"---\n\n*[End Movement {MOVE_AFTER[item]}.]*\n\n")
out.append("---\n\n*[End of Episode 2.]*\n")
open(f"{D}/EP2_PAGES.md", "w", encoding="utf-8").write("".join(out))
print(f"wrote {n} scenes")
