#!/usr/bin/env python
"""gate_prep — join Fountain cue+dialogue rows into `KEY: text` one-liners.

metaphrand.blind_attribution.parse_dialogue wants dialogue as single
`SPEAKER: text` lines. Our Fountain puts the cue on its own row:

    CRICKET:
    I'm current.

This adapter emits:

    CRICKET: I'm current.

Parentheticals are dropped (the gate strips them anyway); multi-row speeches
are joined with spaces; (V.O.)/(FILTERED)/etc. suffixes are removed so the
key matches the voice-card slug.

Usage:
  gate_prep.py draft.fountain > joined.txt
  PYTHONPATH=~/dev/metaphrand .venv/bin/python -c "
    from metaphrand.blind_attribution import audit, report; ..." < joined.txt
"""
from __future__ import annotations

import re
import sys

CUE_RE = re.compile(r"^([A-Z][A-Z .'\-]{0,30}?)(\s*\((?:V\.O\.|O\.S\.|CONT'D|ON SCREEN|FILTERED)\))?:$")
SLUG_RE = re.compile(r"^(INT\.|EXT\.|EST\.|INT/EXT\.|I/E\.)", re.I)


def join_cues(text: str) -> list[str]:
    out: list[str] = []
    lines = text.splitlines()
    i = 0
    while i < len(lines):
        s = lines[i].strip()
        m = CUE_RE.match(s)
        if not m or SLUG_RE.match(s):
            i += 1
            continue
        key = m.group(1).strip().split()[0].lower()  # first word = card slug
        i += 1
        speech: list[str] = []
        while i < len(lines):
            t = lines[i].strip()
            if not t:
                break
            if t.startswith("(") and t.endswith(")"):
                i += 1
                continue
            if CUE_RE.match(t) or SLUG_RE.match(t):
                break
            speech.append(t)
            i += 1
        if speech:
            out.append(f"{key.upper()}: {' '.join(speech)}")
    return out


def main() -> int:
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    text = open(sys.argv[1], encoding="utf-8").read()
    joined = join_cues(text)
    print("\n".join(joined))
    print(f"\n# {len(joined)} dialogue lines", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
