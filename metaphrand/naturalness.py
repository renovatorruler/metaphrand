"""metaphrand.naturalness — The One Law, enforced (docs/06-THE-ONE-LAW.md).

The ceiling above ``craftlint``'s mechanical floor. A model runs as a *harsh editor, not a
generator*, reads every line, and flags whatever is **arranged for effect** — the infinite tail of
AI tells that no regex can catch. It writes a per-line audit to ``<story>/.passes/``, so a clean
pass is *shown*, never *claimed*. The gate is imperfect (an AI can excuse the prose it would itself
write), so the author's ear stays the calibration; each flagged line is added to the critic's
examples to sharpen it.

    from metaphrand.naturalness import audit, gate, write_report
    from metaphrand.generate import OllamaClient
    flags = audit(open("scene.md").read(), OllamaClient(json_mode=True))
"""
from __future__ import annotations

import json
import re
from collections import namedtuple

Flag = namedtuple("Flag", "line text reason")

LAW = ("Every line must read exactly as a real person would say or write it, in that moment. "
       "Nothing may be arranged for effect.")

CRITIC_SYSTEM = (
    "You are a ruthless script editor, not a writer. You enforce ONE LAW:\n"
    f"  {LAW}\n\n"
    "These are all VIOLATIONS — language shaped to LAND instead of said plainly:\n"
    '  - two-word punch sentences: "Cold."\n'
    '  - staccato runs: "The room was empty. Cold. Just three chairs."\n'
    '  - facts recited as beats: "छब्बीस की रात। पौने दस बजे।"\n'
    '  - balanced antithesis: "He didn\'t have a plan. He had a problem."\n'
    '  - a key word held to the end for punch: "मुझे गुड़िया चाहिए, ज़िंदा।"\n'
    '  - the end-loaded detail — a fact tacked on after a pause, by comma-tail or fragment: '
    '"...देखी गई थी, पौने दस बजे, तेरे साथ।" / "...छोड़ा था, मैडम। आनंद विहार।"\n'
    '  - composed pathos / quotable epigrams: "यहाँ बस मैं हूँ, और बाहर वो औरत जो तीन रात से सोई नहीं।"\n'
    "  - any cadence where each sentence begs you to read the next.\n\n"
    "You are NOT judging meaning, grammar, or whether the line sounds good. GOOD-SOUNDING IS THE "
    "TRAP. You judge ONE thing: does the line's SHAPE exist to make it land? A genuinely terse real "
    'reply ("No.", "हाँ।", "Bol.") is fine — a single plain line is rarely a violation. The tell is '
    "composition: arrangement for effect.\n\n"
    'Return ONLY JSON: {"flags": [{"line": <int>, "reason": "<reason, max 12 words>"}]}. '
    "Return an empty list if every line is plain. Do not flag plain, ordinary, real lines."
)


def _candidate_lines(text: str) -> list[tuple[int, str]]:
    """Numbered prose/dialogue lines, with screenplay cues and parentheticals stripped so the
    judged text is the spoken line or action itself."""
    out: list[tuple[int, str]] = []
    for i, line in enumerate(text.splitlines(), 1):
        s = line.strip()
        if not s or s.startswith(("#", "```", ">", "---", "*", "|")):
            continue
        if re.match(r"^\*{0,2}(INT\.|EXT\.|CUT|FADE|COLD OPEN|TAG|END)", s):
            continue
        s = re.sub(r"^\*{0,2}[A-Z][A-Z0-9 .'’()&/-]{1,28}:\*{0,2}\s*", "", s)  # drop ROLE: cue
        s = re.sub(r"\([^)]*\)", "", s).strip()                                # drop parentheticals
        if len(s.split()) >= 2 or re.search(r"[।॥]", s):
            out.append((i, s))
    return out


def _parse(raw: str) -> list:
    raw = raw.strip()
    m = re.search(r"\{.*\}", raw, re.S)
    if m:
        raw = m.group()
    try:
        obj = json.loads(raw)
    except Exception:
        return []
    if isinstance(obj, dict):
        return obj.get("flags", [])
    return obj if isinstance(obj, list) else []


def audit(text: str, client, max_lines: int = 80) -> list[Flag]:
    """Run the critic over the text; return the lines it judged arranged-for-effect."""
    lines = _candidate_lines(text)[:max_lines]
    if not lines:
        return []
    numbered = "\n".join(f"{n}\t{t}" for n, t in lines)
    raw = client.complete("Judge each numbered line. Flag ONLY the ones arranged for effect.\n\n"
                          + numbered, system=CRITIC_SYSTEM)
    by_line = {n: t for n, t in lines}
    flags = []
    for d in _parse(raw):
        if isinstance(d, dict) and d.get("line") in by_line:
            flags.append(Flag(d["line"], by_line[d["line"]], str(d.get("reason", ""))[:80]))
    return flags


def report(flags: list[Flag]) -> str:
    if not flags:
        return "clean — every line reads plain"
    out = [f"{len(flags)} lines arranged for effect (The One Law):", ""]
    for f in flags:
        out.append(f"  L{f.line}: {f.text[:72]}")
        out.append(f"        -> {f.reason}")
    return "\n".join(out)


def gate(text: str, client) -> tuple[bool, str]:
    fl = audit(text, client)
    return (not fl, f"{len(fl)} lines arranged for effect")


def write_report(text: str, client, path: str) -> bool:
    import os
    fl = audit(text, client)
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(report(fl) + "\n")
    return not fl
