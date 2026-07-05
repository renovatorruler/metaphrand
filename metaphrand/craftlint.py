"""metaphrand.craftlint — the deterministic prose linter (the unfakeable gate).

Turns "I ran the humanizer" into "here is the linter output." It scans raw prose or a
screenplay for the AI writing tells we ban — first and foremost the **clickbait cadence** and
the **two-word punch-sentence** — and prints every hit with a line number. It is deterministic:
the same text always yields the same report, so a clean run cannot be *claimed*, only *produced*.

    python -m metaphrand.craftlint path/to/draft.md      # prints report, exits 1 on any HIGH

Dialogue is exempt from the short-sentence rules (people really do say "No."); the rules bite on
NARRATION and ACTION, which is where the AI tic lives.
"""
from __future__ import annotations

import re
import sys
from collections import namedtuple

Violation = namedtuple("Violation", "line severity rule snippet note")

AI_VOCAB = {"delve", "tapestry", "testament", "underscore", "underscores", "boasts", "nestled",
            "vibrant", "intricate", "intricacies", "pivotal", "realm", "myriad", "palpable",
            "showcase", "showcases", "interplay", "enduring", "seamless", "seamlessly",
            "landscape", "beacon", "crucible", "indelible"}
COPULA_AVOID = [r"\bserves as\b", r"\bstands as\b", r"\bis a testament\b", r"\bboasts\b",
                r"\bstands testament\b"]
CLICKBAIT_OPENERS = [r"here'?s the thing", r"but here'?s", r"and that'?s when", r"turns out\b",
                     r"the truth is\b", r"what'?s more\b", r"make no mistake", r"little did"]
NEG_PARALLEL = [r"\bnot only\b.*\bbut\b", r"\bit'?s not just\b.*\bit'?s\b",
                r"\bnot just\b.*\b(but|—)\b"]
CORRECTIVE = [r"\bnot\s+[\w' ]{1,30}[.,;]\s+(it'?s|that'?s|he'?s|she'?s|they'?re|it is|that is)\b",
              r"\bisn'?t\s+[\w' ]{1,30}[,.]\s+(it'?s|it is)\b",
              r"\bthat'?s not\b[\w' ]{1,30}\.\s+that'?s\b"]
_CUE = re.compile(r"^\s*\*{0,2}[A-Z][A-Z0-9 .'’()&/-]{1,28}:\*{0,2}\s")
_SLUG = re.compile(r"^\*{0,2}(INT\.|EXT\.|CUT TO|FADE|COLD OPEN|TAG|END|>)")
_DIRECTION = {"beat.", "hold.", "cut.", "silence.", "cut to black.", "end."}
_SENT = re.compile(r"[^.!?।॥]*[.!?।॥]+|\S[^.!?।॥]*$")  # । ॥ (danda) end Hindi sentences


def _narration(line: str) -> str:
    """The narration part of a line — drop a screenplay dialogue cue's speech and quoted spans."""
    if _CUE.match(line):
        return ""
    return re.sub(r"[\"“”][^\"“”]*[\"“”]", " ", line)


def _words(s: str) -> int:
    return len(re.findall(r"\w+", s, re.UNICODE))   # counts Devanagari words as well as Latin


def _split_para(blob: str, start: int):
    return [(start, m.group().strip()) for m in _SENT.finditer(blob) if m.group().strip()]


def _narration_sentences(text: str):
    """Prose/action sentences, numbered. Soft-wrapped lines are joined into a paragraph (delimited
    by a blank line, a header, or a dialogue cue) so a sentence spanning lines is judged whole, not
    in fragments; screenplay beats (one per line) are unaffected."""
    out, para, start = [], [], None
    for i, line in enumerate(text.splitlines(), 1):
        raw = line.strip()
        boundary = (not raw) or raw.startswith(("#", "```", ">")) or bool(_SLUG.match(raw))
        narr = "" if boundary else _narration(line)
        if narr:
            narr = re.sub(r"^\s*(?:[-*+]|\d+[.)])\s+", "", narr)                  # list marker
            narr = re.sub(r"`[^`]*`|[*_]", "", narr)                              # code + emphasis
            narr = re.sub(r"\S*[/\\]\S*|\b\w+\.(?:py|md|txt|json)\b", " ", narr)  # paths / files
            narr = narr.strip()
        if narr:
            start = i if start is None else start
            para.append(narr)
        else:                              # blank / header / dialogue cue ends the paragraph
            if para:
                out.extend(_split_para(" ".join(para), start))
            para, start = [], None
    if para:
        out.extend(_split_para(" ".join(para), start))
    return out


def lint(text: str, banned=(), mode: str = "prose") -> list[Violation]:
    # In a screenplay, a terse action line ("He goes.") is a defensible convention, so a lone
    # short sentence is a warning, not a block; in PROSE it stays a hard violation. A *run* of
    # short sentences (the staccato cadence) is banned in both.
    ss_sev = "MED" if mode == "screenplay" else "HIGH"
    V: list[Violation] = []
    # 1 — the flagship: two-word punch-sentences + staccato runs (narration only). A run must be
    # ADJACENT short sentences; a line gap (dialogue or a blank line between beats) breaks it.
    run, prev_ln = 0, None

    def _flush(at):
        nonlocal run
        if run >= 3:
            V.append(Violation(at, "HIGH", "staccato-run", "…",
                               f"{run} very short sentences in a row — AI punchy cadence"))
        run = 0

    for ln, s in _narration_sentences(text):
        if prev_ln is not None and ln - prev_ln > 1:
            _flush(prev_ln)
        prev_ln = ln
        wc = _words(s)
        if wc <= 3 and re.search(r"[.!?।॥]$", s) and not s.isupper() and s.lower() not in _DIRECTION:
            V.append(Violation(ln, ss_sev, "short-sentence", s,
                               f"{wc}-word punch sentence — humans don't end on two words for effect"))
        if wc <= 6:
            run += 1
        else:
            _flush(ln)
    _flush(prev_ln or 0)
    # 2 — line-level regex tells
    for i, line in enumerate(text.splitlines(), 1):
        low = line.lower()
        if any(re.search(p, line, re.I) for p in CORRECTIVE):
            V.append(Violation(i, "HIGH", "corrective-definition", line.strip()[:80],
                               "the 'not X, it's Y' reveal — banned"))
        if any(re.search(p, line, re.I) for p in NEG_PARALLEL):
            V.append(Violation(i, "MED", "negative-parallelism", line.strip()[:80],
                               "'not only…but' / 'not just…it's'"))
        if any(re.search(p, low) for p in CLICKBAIT_OPENERS):
            V.append(Violation(i, "MED", "clickbait-opener", line.strip()[:80], "engagement-bait opener"))
        if any(re.search(p, low) for p in COPULA_AVOID):
            V.append(Violation(i, "MED", "copula-avoidance", line.strip()[:80], "use is/has, not serves-as/boasts"))
        for w in sorted({w for w in re.findall(r"[a-z']+", low)} & AI_VOCAB):
            V.append(Violation(i, "MED", "ai-vocabulary", w, "high-frequency AI word"))
        for b in banned:
            if b.lower() in low:
                V.append(Violation(i, "HIGH", "banned-phrase", b, "on this story's banned list"))
        for m in re.finditer(r"\b(\w+(?: \w+)?), (\w+(?: \w+)?),? and (\w+(?: \w+)?)\b", line):
            if all(_words(g) <= 2 for g in m.groups()):
                V.append(Violation(i, "MED", "rule-of-three", m.group()[:60], "three short parallel items — AI rhythm"))
    # 3 — em-dash density (PROSE only; slugline/title dashes like "INT. X — DAY" are screenplay
    # formatting, not the prose em-dash tell, so they must not inflate the count)
    prose = "\n".join(ln for ln in text.splitlines()
                      if not (_SLUG.match(ln.strip()) or ln.strip().startswith((">", "#"))
                              or ln.strip().lstrip("*").startswith("TITLE")))
    words = _words(prose) or 1
    dashes = prose.count("—")
    if dashes / words * 1000 > 8:
        V.append(Violation(0, "MED", "em-dash-density", f"{dashes} dashes / {words} words",
                           f"{dashes / words * 1000:.1f} per 1000 words (>8) — AI over-uses the em-dash"))
    return sorted(V, key=lambda v: (v.line, v.rule))


def report(violations: list[Violation]) -> str:
    if not violations:
        return "clean — 0 violations"
    hi = sum(1 for v in violations if v.severity == "HIGH")
    out = [f"{len(violations)} violations ({hi} HIGH):", ""]
    for v in violations:
        out.append(f"  L{v.line:<4} [{v.severity}] {v.rule}: {v.snippet}")
        out.append(f"        -> {v.note}")
    return "\n".join(out)


def gate(text: str, banned=(), mode: str = "prose") -> tuple[bool, str]:
    """Pipeline hook: passes iff no HIGH violations. Returns (passed, one-line summary)."""
    vs = lint(text, banned, mode)
    hi = [v for v in vs if v.severity == "HIGH"]
    return (not hi, f"{len(vs)} tells, {len(hi)} HIGH"
            + ("" if not hi else " — " + ", ".join(sorted({v.rule for v in hi}))))


def feedback(text: str, banned=(), mode: str = "prose", limit: int = 6) -> str:
    """The actionable note a rewrite loop feeds back to the LLM — the concrete tells to cut."""
    hi = [v for v in lint(text, banned, mode) if v.severity == "HIGH"]
    if not hi:
        return ""
    return "cut these AI writing tells and rewrite plainly: " + "; ".join(
        f"{v.rule} (\"{v.snippet}\")" for v in hi[:limit])


def write_report(text: str, path: str, banned=(), mode: str = "prose") -> bool:
    """Write the lint report as an on-disk artifact; return True if clean. The artifact is the
    proof a pass ran — there is no clean claim without this file."""
    import os
    vs = lint(text, banned, mode)
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(report(vs) + "\n")
    return not any(v.severity == "HIGH" for v in vs)


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    mode = "screenplay" if "--screenplay" in sys.argv else "prose"
    src = open(args[0], encoding="utf-8").read()
    vs = lint(src, mode=mode)
    print(report(vs))
    sys.exit(1 if any(v.severity == "HIGH" for v in vs) else 0)
