"""Executable prose gates — the banned-pattern scans as code, not memory.

Runs the mechanical half of the assembly scans (docs/05 §10) over a manuscript.
Born 2026-06-11 after the third claimed-but-not-run pass: enforcement by model
memory failed three times; this runs before ANY deliverable is staged.

    python -m examples.prose_gates stories/civil-war/civil-war-novel.md
    python -m examples.prose_gates <file> --chapters 3,14   # changed chapters only

Exit code 1 on hits, so it gates a staging script. Heuristics are deliberately
high-precision / modest-recall: they catch the mechanical shapes; the judged
shapes (announce-then-deliver in fresh clothes) still need the read — but the
read now has a checklist with teeth.
"""

from __future__ import annotations

import re
import sys

# words that count as a finite verb / auxiliary for the fragment heuristic
VERBISH = re.compile(
    r"\b(is|are|was|were|be|been|being|has|have|had|do|does|did|will|would|"
    r"can|could|may|might|must|shall|should|went|came|said|stood|sat|got|"
    r"ran|put|took|made|let|kept|held|saw|looked|gave|knew|told|asked|"
    r"called|turned|walked|fired|counted|opened|closed|pushed|pulled|"
    r"thought|brought|bought|caught|taught|felt|left|met|sent|spent|built|"
    r"heard|found|paid|laid|read|cut|set|shut|hit|hurt|cost|burst|spat|"
    r"swung|hung|rang|sang|drank|sank|stuck|struck|threw|drew|flew|grew|"
    r"knew|blew|wore|tore|bore|spoke|broke|woke|chose|froze|drove|rode|"
    r"say|do|go|see|know|make|take|come|give|get|keep|stand|sit|hold|"
    r"rose|wrote|ate|gave|came|became|forgave|lay|fell|told|sold|held|"
    r"stole|meant|leant|learnt|dreamt|began|ran|won|shone|shot|got|gotten|"
    r"[a-z]+ed|[a-z]+s)\b", re.I)

# deliberate refrains / documentary field-lines, exempt by law
EXEMPT = {
    "One road in.",
    "Language at home.",
    "Names, prior address, current address.",
    "Mid-game, my friend.",
    "Consistent: Y.",
}

BANNED = [
    ("corrective definition",
     re.compile(r"(That's not [^.]+\. That's|wasn't a [a-z]+[,.] (it|he|she) was|"
                r"isn't [a-z]+\. It's|not [a-z]+\. Now it (was|is))")),
    ("negative parallelism", re.compile(r"\bnot (just|merely|only) [^.]{3,40}[,;] (but|it)")),
    ("costume metaphor",
     re.compile(r"wearing the (clothes|uniform|costume|skin) of|"
                r"in [a-z]+'s clothing|wearing a different [a-z]+\b(?! shirt| coat| dress| hat)")),
    ("announce-then-deliver",
     re.compile(r"(wrong|right|true|odd) (twice|three times)\b|"
                r"two things[,:] | said it (twice|three times) —")),
    ("rule-of-three drumbeat (check by eye)",
     re.compile(r", [a-z]+ed, and [a-z]+ed\.\s|, [a-z]+ly, [a-z]+ly, and [a-z]+ly")),
]


ABBREV = re.compile(r"\b(Mr|Mrs|Dr|Ms|St|[A-Z])\.$")


def sentences_of(par: str):
    # split on sentence enders, glue back abbreviation splits
    raw = [s.strip() for s in re.split(r"(?<=[.!?])\s+", par) if s.strip()]
    out = []
    for s in raw:
        if out and ABBREV.search(out[-1]):
            out[-1] = out[-1] + " " + s
        else:
            out.append(s)
    return out


def is_dialogue(s: str) -> bool:
    return s.startswith('"') or s.startswith("“") or s.startswith("*")


def fragment_hits(text: str):
    """Verbless narration sentences (completion-fragments). Tracks quote state
    so anything inside dialogue is exempt; skips headings, separators, and
    quoted-document lines (ALL CAPS heavy)."""
    hits = []
    contract = re.compile(r"\b\w+n't\b|\b(won't|can't|ain't|let's)\b", re.I)
    for ln, par in enumerate(text.split("\n"), 1):
        p = par.strip()
        if not p or p.startswith(("#", "*", "—", "⸻", ">")):
            continue
        quotes_seen = 0
        stars_seen = 0
        for s in sentences_of(p):
            inside = quotes_seen % 2 == 1 or stars_seen % 2 == 1
            quotes_seen += s.count('"')
            stars_seen += s.count("*")
            if inside or s.startswith('"') or s.endswith('"') or len(s.split()) > 9:
                continue
            if s.startswith("*") or s.endswith("*") or s in EXEMPT:
                continue
            if "'d " in s or "'ll " in s or "'ve " in s or "'re " in s:
                continue
            core = re.sub(r"[\"“”]", "", s)
            if sum(c.isupper() for c in core) > len(core) * 0.4:  # doc/card text
                continue
            if len(core.split()) >= 2 and not (VERBISH.search(core) or contract.search(core)):
                hits.append((ln, s))
    return hits


def main(argv):
    path = argv[0]
    chapters = None
    if len(argv) > 2 and argv[1] == "--chapters":
        chapters = {int(c) for c in argv[2].split(",")}
    text = open(path, encoding="utf-8").read()

    if chapters is not None:
        keep, cur = [], None
        for line in text.split("\n"):
            m = re.match(r"## (\d+)$", line.strip())
            if m:
                cur = int(m.group(1))
            if cur in chapters:
                keep.append(line)
        text = "\n".join(keep)

    failed = False
    for name, rx in BANNED:
        found = [(text[:m.start()].count("\n") + 1, m.group(0)[:60])
                 for m in rx.finditer(text)]
        if found:
            failed = True
            print(f"[GATE] {name}: {len(found)} hit(s)")
            for ln, frag in found[:8]:
                print(f"   line {ln}: …{frag}…")
    frags = fragment_hits(text)
    if frags:
        failed = True
        print(f"[GATE] verbless narration sentence (completion-fragment): {len(frags)}")
        for ln, s in frags[:10]:
            print(f"   line {ln}: {s[:70]}")
    # clear-pane density warnings (non-fatal — pointers for the skill read, docs/05 §11)
    import collections
    warn = collections.OrderedDict([
        ("similes (like a/the way)", len(re.findall(r"\blike an? \b|\bthe way [a-z]", text))),
        ("knowingness (', which ' asides)", len(re.findall(r", which (was|meant|he|she|nobody)", text))),
        ("one-line dramatic paragraphs", len(re.findall(r"\n\n[A-Z][^\n.]{0,35}\.\n\n", text))),
    ])
    words = max(len(text.split()), 1)
    for name, n in warn.items():
        per_k = n * 1000 / words
        if per_k > 6:
            print(f"[clear-pane warn] {name}: {n} ({per_k:.0f}/1k words) — run the skill")
    if not failed:
        print("prose gates: CLEAN")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
