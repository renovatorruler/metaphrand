"""cinema.characters — story-agnostic character pipeline.

    description -> portrait -> multi-view turnaround model sheet -> (conditioning ref)

Best practices baked in (researched 2026): a turnaround model sheet — front / 3-4 /
profile face + full-body front & side, flat studio light, neutral background, consistent
wardrobe — is the consistency gold standard; every shot then conditions on the sheet.
And an explicit guard against famous-actor likeness (the trap where "weary detective"
collapses onto Hugh Laurie and "handsome 50s lead" onto Clooney): we demand an ORIGINAL
face and steer with the character's own distinct features in the description.

Works for ANY character — detective, queen, alien — because the only input is text.
"""
from __future__ import annotations

import os

from . import backends as bk

PORTRAIT_HEAD = (
    "A photorealistic cinematic character portrait, three-quarter view, plain neutral "
    "dark-gray studio background, soft flattering light, sharp focus. The face of a "
    "specific UNKNOWN real person — an ORIGINAL face that does NOT resemble any famous "
    "actor, celebrity, or public figure. Character: ")

TURNAROUND_HEAD = (
    "A professional CHARACTER REFERENCE MODEL SHEET of the SAME person as in the attached "
    "portrait, on a plain light-gray seamless background with flat even studio lighting, "
    "reference-sheet style, sharp and clean. Layout in one image: a TOP ROW of three "
    "head-and-shoulders views of the face — front view, three-quarter view, and side "
    "profile — and a BOTTOM ROW of two full-body shots, one front and one side, in a "
    "neutral relaxed standing pose. It is the SAME person in every view: identical face, "
    "hair, build, and wardrobe, neutral expression, fully consistent. No text, no labels. "
    "The person: ")


def portrait(description: str, out: str, pro: bool = True) -> str:
    """Generate a single hero portrait from a text description (with the actor-guard)."""
    bk.save_png(out, bk.image(PORTRAIT_HEAD + description, refs=None, pro=pro))
    print("portrait ->", out, flush=True)
    return out


def turnaround(portrait_path: str, description: str, out: str, pro: bool = True) -> str:
    """Multi-view model sheet conditioned on the locked portrait (keeps identity)."""
    bk.save_png(out, bk.image(TURNAROUND_HEAD + description, refs=[portrait_path], pro=pro))
    print("turnaround ->", out, flush=True)
    return out


def build_cast(cast: dict[str, str], outdir: str, turnarounds: bool = True) -> dict:
    """cast = {name: description}. Emits {name: {'portrait', 'turnaround'}} under outdir.

    The portrait is the identity; the turnaround is what every shot conditions on.
    """
    os.makedirs(outdir, exist_ok=True)
    sheets = {}
    for name, desc in cast.items():
        p = portrait(desc, f"{outdir}/{name}.png")
        t = turnaround(p, desc, f"{outdir}/{name}_turnaround.png") if turnarounds else None
        sheets[name] = {"portrait": p, "turnaround": t}
    return sheets


def contact_sheet(sheets: dict, labels: dict, out: str, cols: int = 2) -> str:
    """Label and grid the portraits into one reviewable cast sheet."""
    from PIL import Image, ImageDraw, ImageFont
    items = list(sheets.items())
    cw, ch, pad, lab = 640, 360, 16, 44
    rows = (len(items) + cols - 1) // cols
    W = cols * cw + pad * (cols + 1)
    H = rows * (ch + lab) + pad * (rows + 1)
    img = Image.new("RGB", (W, H), (18, 18, 20))
    d = ImageDraw.Draw(img)

    def font(sz):
        try:
            return ImageFont.truetype("/System/Library/Fonts/Supplemental/Georgia.ttf", sz)
        except OSError:
            return ImageFont.load_default()

    for i, (name, paths) in enumerate(items):
        r, c = divmod(i, cols)
        x, y = pad + c * (cw + pad), pad + r * (ch + lab + pad)
        im = Image.open(paths["portrait"]).convert("RGB").resize((cw, ch))
        img.paste(im, (x, y))
        d.text((x + 6, y + ch + 4), name.upper(), font=font(26), fill=(236, 226, 206))
        d.text((x + 6, y + ch + 30), labels.get(name, ""), font=font(19), fill=(170, 160, 150))
    os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
    img.save(out)
    return out
