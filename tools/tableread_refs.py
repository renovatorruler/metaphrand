#!/usr/bin/env python
"""Reference sheets for the table read — recurring characters AND props.

Same doctrine as cinema.characters (portrait -> turnaround -> conditioning
ref), adapted to our ink style and extended to non-human recurring assets
(the simulator, the crates) which characters.py doesn't cover: a multi-angle
turnaround generated once, then passed as `refs=[...]` to every panel that
features it, so the thing drawn stays the SAME thing drawn.

Run once per new recurring character/prop; the sheet is cached on disk and
reused free thereafter.
"""
from __future__ import annotations

import os
import sys

sys.path.insert(0, "/Users/dusty/dev/metaphrand")
from cinema import backends as bk  # noqa: E402

INK = ("Black-and-white brush-ink graphic novel style, heavy expressive linework, "
       "flat gray screentone shading, deep blacks. No text, no lettering, no watermarks. ")

SHEET_DIR = "stories/four-olds/tableread/refsheets"
os.makedirs(SHEET_DIR, exist_ok=True)


def character_sheet(key: str, description: str, pro: bool = True) -> str:
    """A locked turnaround for a recurring HUMAN character: front / 3-4 / profile
    face, plus a full-body pose, all the same person, same wardrobe."""
    out = f"{SHEET_DIR}/{key}.png"
    if os.path.exists(out):
        return out
    prompt = (INK + "A character reference sheet, plain flat-gray background, even "
              "light. Three views of the SAME person's face in a row — front, "
              "three-quarter, profile — plus one full-body standing pose below. "
              "Identical face, build, age, and wardrobe in every view, neutral "
              "expression. No text, no labels. The person: " + description)
    bk.save_png(out, bk.image(prompt, pro=pro, aspect="16:9"))
    print("character sheet ->", out, flush=True)
    return out


def prop_sheet(key: str, description: str, pro: bool = True) -> str:
    """A locked turnaround for a recurring PROP/set-piece: 3 angles, same object."""
    out = f"{SHEET_DIR}/{key}.png"
    if os.path.exists(out):
        return out
    prompt = (INK + "A prop reference sheet, plain flat-gray background, even "
              "studio light. Three views of the exact SAME object side by side — "
              "a three-quarter hero view, a straight-on front view, and a side "
              "profile view. Identical object, identical details, materials, and "
              "proportions in every view. No text, no labels, no people. "
              "The object: " + description)
    bk.save_png(out, bk.image(prompt, pro=pro, aspect="16:9"))
    print("prop sheet ->", out, flush=True)
    return out


if __name__ == "__main__":
    SIMULATOR_DESC = (
        "a homebuilt astronaut training simulator inside a barn: a single reclined "
        "seat on a welded plywood-and-angle-iron frame, surrounded by a dense wall of "
        "salvaged aircraft instrument panels covered in round analog gauges, toggle "
        "switches, and a control yoke, all clearly homemade but meticulously kept, "
        "cables running to a separate vintage ham-radio unit on a side table"
    )
    PELL_DESC = (
        "Administrator Pell, an American man in his mid-fifties, soft square build, "
        "thinning combed-back hair, wire-rim glasses, wearing a company zip fleece "
        "over a collared shirt with a laminated badge lanyard, a permanently pleasant "
        "bureaucratic expression"
    )
    WADE_DESC = (
        "Wade Halversen, an American county sheriff's deputy in his mid-forties, "
        "sturdy build, short cropped hair going gray at the temples, a weathered "
        "kind face, wearing a tan sheriff's department uniform with a star badge "
        "and a wide-brim hat, a tired decent expression"
    )
    print(prop_sheet("simulator", SIMULATOR_DESC))
    print(character_sheet("pell", PELL_DESC))
    print(character_sheet("wade", WADE_DESC))
