#!/usr/bin/env python3
"""run_scene.py — compose ONE scene through the full enforcement battery.

The whole point of this file: a scene only *exists* if it came out of this pipeline.
There is no hand-written path. Author (claude -p from a brief, or an existing draft)
-> repair() through SCENE_PASSES (drama, human-reaction, voice, dialogue-realism,
backstory/held-cards, heart, layers, show-not-tell, shrink-wrap, concreteness,
clear-pane, consistency) -> craftlint deterministic floor -> emit the gated scene
plus the pass log. The human is the final stop; nothing auto-ships.

  python -m metaphrand.run_scene --brief brief.md --context ctx.md --out scene.md
  python -m metaphrand.run_scene --draft draft.md --context ctx.md --out scene.md
  python -m metaphrand.run_scene --draft draft.md --only show-not-tell,shrink-wrap   # subset
"""
import sys
import os
import argparse

from metaphrand.passes import SCENE_PASSES, repair, _claude
from metaphrand import craftlint

AUTHOR_PROMPT = """You are writing ONE scene of a grounded Hindi crime drama — the register of \
Paatal Lok / Kohrra: realistic, restrained, no melodrama — set in the Malwa opium belt of 1990s \
Madhya Pradesh.

FORMAT, exactly:
- a header line:  ## दृश्य N — <title>
- action lines prefixed "N:" — Hindi prose describing ONLY what a camera sees and what people do. \
Never name a feeling, a relationship, or a theme. Every action line must be a SHOT.
- dialogue as  नाम: पंक्ति . Malwi dialect in local/village mouths, plain Hindi for officials.

Hold every held card in the context below — never state it or clearly imply it.

BRIEF FOR THIS SCENE:
{brief}

CONTEXT — canon to honor, and HELD CARDS to keep buried:
{context}

Write the scene now. Output ONLY the scene, nothing before or after."""


def author(brief: str, context: str) -> str:
    return _claude(AUTHOR_PROMPT.format(brief=brief or "(none)", context=context or "(none)"))


def compose(brief="", context="", draft=None, rounds=1, only=None):
    """Returns (text, log, floor_report, clean)."""
    passes = SCENE_PASSES
    if only:
        wanted = {n.strip() for n in only}
        passes = [p for p in SCENE_PASSES if p.name in wanted or p.name == "editorial"]
    text = draft if draft is not None else author(brief, context)
    text, log = repair(text, passes, context, rounds)
    ok_floor, floor_report = craftlint.gate(text, mode="screenplay")
    still = [l for l in log if "still flags" in l]
    clean = ok_floor and not still
    return text, log, floor_report, clean


def main(argv):
    ap = argparse.ArgumentParser(description="Compose a scene through the enforcement battery.")
    ap.add_argument("--brief", help="scene brief (the seed): want/wall/turn, beats, voices")
    ap.add_argument("--context", default="", help="canon + held cards (held cards stay buried)")
    ap.add_argument("--draft", help="an existing draft to enforce instead of authoring fresh")
    ap.add_argument("--out", help="write the gated scene here (else stdout)")
    ap.add_argument("--rounds", type=int, default=1)
    ap.add_argument("--only", help="comma-separated pass names to run (subset)")
    a = ap.parse_args(argv)

    brief = open(a.brief, encoding="utf-8").read() if a.brief else ""
    context = open(a.context, encoding="utf-8").read() if a.context else ""
    draft = open(a.draft, encoding="utf-8").read() if a.draft else None
    only = a.only.split(",") if a.only else None

    text, log, floor_report, clean = compose(brief, context, draft, a.rounds, only)

    sys.stderr.write("=== repair log (each pass: test -> fix -> re-test) ===\n")
    sys.stderr.write("\n".join(log) + "\n\n")
    sys.stderr.write("=== craftlint floor ===\n" + floor_report + "\n\n")
    sys.stderr.write(("PASSED the battery — ready for human review\n"
                      if clean else
                      "FAILED — some passes still flag or the floor breaks; needs a human\n"))

    if a.out:
        open(a.out, "w", encoding="utf-8").write(text + "\n")
        sys.stderr.write(f"written: {a.out}\n")
    else:
        print(text)
    return 0 if clean else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
