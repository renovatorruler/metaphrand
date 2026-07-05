"""AMAL Ep1 v2.1 ENGLISH — scene-heading cards (English). White on near-black. -> cards_v2en/."""
import os, re
from PIL import Image, ImageDraw, ImageFont

D = "/Users/dusty/dev/brehon-law/stories/amal"
OUT = f"{D}/cards_v2en"; os.makedirs(OUT, exist_ok=True)
FONT = "/System/Library/Fonts/Supplemental/Georgia.ttf"
if not os.path.exists(FONT):
    FONT = "/System/Library/Fonts/Supplemental/Times New Roman.ttf"
W, H = 1920, 1080
F = lambda px: ImageFont.truetype(FONT, px)


def wrap(d, text, font, maxw):
    words, lines, cur = text.split(), [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if d.textlength(t, font=font) <= maxw:
            cur = t
        else:
            lines.append(cur); cur = w
    if cur:
        lines.append(cur)
    return lines


def render(path, blocks):
    img = Image.new("RGB", (W, H), (8, 8, 10)); d = ImageDraw.Draw(img)
    rows = []
    for text, px, col in blocks:
        font = F(px)
        for ln in wrap(d, text, font, W - 360):
            rows.append((ln, font, col, d.textbbox((0, 0), ln, font=font)[3]))
    gap = 28; total = sum(h for *_, h in rows) + gap * (len(rows) - 1); y = (H - total) // 2
    for ln, font, col, h in rows:
        d.text(((W - d.textlength(ln, font=font)) // 2, y), ln, font=font, fill=col); y += h + gap
    img.save(path)


render(f"{OUT}/title.png", [("AMAL", 200, (235, 225, 205)),
                            ("Episode 1 — The Weighing", 70, (170, 165, 150)),
                            ("a Malwa opium-belt crime drama", 38, (110, 108, 100))])

text = open(f"{D}/EP1_PAGES_v2_EN.md", encoding="utf-8").read()
parts = re.split(r"(?m)^## (SCENE \d+[^\n]*)$", text)
n = 0
for k in range(1, len(parts), 2):
    head = parts[k].strip()
    m = re.search(r"^\*\*(.+?)\*\*", parts[k + 1], re.M)
    slug = m.group(1).strip() if m else ""
    num = int(re.match(r"SCENE (\d+)", head).group(1))
    blocks = [(head, 60, (150, 148, 140))]
    if slug:
        blocks.append((slug, 80, (235, 230, 220)))
    render(f"{OUT}/card{num:02d}.png", blocks)
    n += 1
print(f"cards: title + {n} -> {OUT}", flush=True)
