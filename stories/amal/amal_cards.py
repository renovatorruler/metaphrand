"""AMAL Ep1 — Hindi scene-heading cards as PNGs (this ffmpeg has no drawtext). One per scene + a
title card. White Devanagari on near-black, centred. -> stories/amal/cards/."""
import os, sys, re
from PIL import Image, ImageDraw, ImageFont

D = "/Users/dusty/dev/brehon-law/stories/amal"
OUT = f"{D}/cards"; os.makedirs(OUT, exist_ok=True)
FONT = "/System/Library/Fonts/Supplemental/Devanagari Sangam MN.ttc"
W, H = 1920, 1080
F = lambda px: ImageFont.truetype(FONT, px)
DEV = str.maketrans("०१२३४५६७८९", "0123456789")


def wrap(draw, text, font, maxw):
    words, lines, cur = text.split(), [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if draw.textlength(t, font=font) <= maxw:
            cur = t
        else:
            if cur:
                lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def render(path, blocks):
    """blocks = [(text, px, (r,g,b))]; stacked, centred."""
    img = Image.new("RGB", (W, H), (8, 8, 10))
    d = ImageDraw.Draw(img)
    rows = []
    for text, px, col in blocks:
        font = F(px)
        for ln in wrap(d, text, font, W - 320):
            h = d.textbbox((0, 0), ln, font=font)[3]
            rows.append((ln, font, col, h))
    gap = 26
    total = sum(h for *_, h in rows) + gap * (len(rows) - 1)
    y = (H - total) // 2
    for ln, font, col, h in rows:
        x = (W - d.textlength(ln, font=font)) // 2
        d.text((x, y), ln, font=font, fill=col)
        y += h + gap
    img.save(path)
    return path


# title card
render(f"{OUT}/title.png", [("अमल", 220, (235, 225, 205)),
                            ("एपिसोड १ — तौल", 78, (170, 165, 150)),
                            ("a Malwa opium-belt crime drama", 40, (110, 108, 100))])

# per-scene cards from the Hindi screenplay headers + sluglines
text = open(f"{D}/EP1_PAGES_HI.md", encoding="utf-8").read()
parts = re.split(r"(?m)^## (दृश्य [०-९]+[^\n]*)$", text)
n = 0
for k in range(1, len(parts), 2):
    head = parts[k].strip()                       # "दृश्य ३ — देवा का आना"
    body = parts[k + 1]
    m = re.search(r"^\*\*(.+?)\*\*", body, re.M)   # the slugline
    slug = m.group(1).strip() if m else ""
    numm = re.match(r"दृश्य ([०-९]+)", head)
    num = int(numm.group(1).translate(DEV))
    blocks = [(head, 64, (150, 148, 140))]
    if slug:
        blocks.append((slug, 92, (235, 230, 220)))
    render(f"{OUT}/card{num:02d}.png", blocks)
    n += 1
print(f"cards: title + {n} scene cards -> {OUT}", flush=True)
