#!/usr/bin/env python
"""fountain_reflow — collapse hard-wrapped source lines into one line per
paragraph, in place, on real .fountain files (not just at render time).

Source screenplay files get hand-wrapped at ~65 cols for comfortable editing.
That's invisible to a compliant Fountain renderer (a blank line ends a
paragraph; mid-paragraph newlines are supposed to get rejoined) — our own
fountain2pdf.py already does this at render time. But a plain-text viewer, a
different Fountain app, or GitHub's raw view has no such logic and will show
a literal broken line mid-sentence. This tool removes the ambiguity at the
source: every action/dialogue/center paragraph becomes exactly one line on
disk, so no downstream tool has to guess.

Reuses the same block parser as fountain2pdf.py so the two never disagree.

Usage:
  fountain_reflow.py file1.fountain [file2.fountain ...]   # edits in place
"""
from __future__ import annotations

import re
import sys

CUE_RE = re.compile(r"^([A-Z][A-Z0-9 .'\-]{0,30}?)(\s*\((?:V\.O\.|O\.S\.|CONT'D|ON SCREEN|FILTERED)\))?:$")
SLUG_RE = re.compile(r"^(INT\.|EXT\.|EST\.|INT/EXT\.|I/E\.)", re.I)
CENTER_RE = re.compile(r"^>\s*(.*?)\s*<$")
TRANS_RE = re.compile(r"^(CUT TO|SMASH CUT TO|MATCH CUT TO|FADE (IN|OUT|TO)|DISSOLVE TO|WHITE OUT|BLACK)[ A-Z]*:?$")
PAGEBREAK_RE = re.compile(r"^===+$")
TITLEKEY_RE = re.compile(r"^(Title|Credit|Author|Source|Draft date|Contact|Notes):\s*(.*)$", re.I)
INSERT_RE = re.compile(r"^INSERT\s*[—-]")


def reflow(text: str) -> str:
    lines = text.splitlines()
    i, out = 0, []

    # title block passes through untouched (already one key per line)
    lastkey = None
    while i < len(lines):
        m = TITLEKEY_RE.match(lines[i].strip())
        if m:
            out.append(lines[i])
            lastkey = m.group(1)
            i += 1
        elif lastkey and lines[i].startswith(("   ", "\t")):
            out.append(lines[i])
            i += 1
        else:
            break

    in_dialogue = False
    buf: list[str] = []
    buf_kind = None  # "action" | "dialogue"

    def flush():
        if buf:
            out.append(" ".join(buf))
            buf.clear()

    while i < len(lines):
        raw = lines[i]
        s = raw.strip()
        if not s:
            flush()
            out.append("")
            in_dialogue = False
            i += 1
            continue
        if (PAGEBREAK_RE.match(s) or CENTER_RE.match(s) or SLUG_RE.match(s)
                or TRANS_RE.match(s)):
            flush()
            out.append(s)
            in_dialogue = False
            i += 1
            continue
        if INSERT_RE.match(s):
            # starts a new action-like block; its wrapped continuation
            # lines must still get joined, so fall through to buffering
            # instead of passing it through frozen.
            flush()
            in_dialogue = False
            buf_kind = "action"
            buf.append(s)
            i += 1
            continue
        if CUE_RE.match(s):
            flush()
            out.append(s)
            in_dialogue = True
            i += 1
            continue
        if in_dialogue and s.startswith("(") and s.endswith(")"):
            flush()
            out.append(s)  # parentheticals stay their own line
            i += 1
            continue
        kind = "dialogue" if in_dialogue else "action"
        if buf and buf_kind != kind:
            flush()
        buf_kind = kind
        buf.append(s)
        i += 1

    flush()
    return "\n".join(out) + "\n"


def main() -> int:
    if len(sys.argv) < 2:
        print(__doc__)
        return 2
    for path in sys.argv[1:]:
        original = open(path, encoding="utf-8").read()
        new = reflow(original)
        if new != original:
            open(path, "w", encoding="utf-8").write(new)
            print(f"reflowed: {path}")
        else:
            print(f"unchanged: {path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
