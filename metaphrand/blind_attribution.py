"""metaphrand.blind_attribution — the voice-differentiation gate (docs/04 step 4).

Strip the cue, read the line cold, name the speaker. A local model, given ONLY the voice cards as the
key, attributes each dialogue line to a character; we compare its guess to the truth. High correct-
attribution == distinct voices; confusions == two characters sharing one nervous system → the flagged
lines and pairs get re-voiced.

The companion to ``preflight``: preflight checks the voice cards EXIST (before drafting); this checks
they were HONORED (on the draft). Same family as the One-Law gate — a local-model judge that over-flags
by design, so the author's ear stays the calibration (don't chase the score).

    from metaphrand.blind_attribution import audit, report, gate
    from metaphrand.generate import OllamaClient
    res = audit(script_text, cards_text, OllamaClient(json_mode=True), alias=HINDI_CUES)
    print(report(res))

CLI:  python -m metaphrand.blind_attribution amal     # dogfood on the current script
"""
from __future__ import annotations

import json
import re
from collections import Counter, namedtuple

Rec = namedtuple("Rec", "idx true guess text")
Result = namedtuple("Result", "records cast unmapped")

SYSTEM = (
    "You are a voice-identification engine, not a writer. You are given VOICE CARDS describing how each "
    "character in a cast speaks — sentence shape, emotion, vocabulary, directness, tics — and then a list "
    "of numbered dialogue lines with the speaker's name REMOVED.\n\n"
    "For each line, name the SINGLE character whose voice it best matches. Judge by MANNER and VOICE — the "
    "shape, rhythm, diction, length, directness — NOT by the topic and NOT by who the plot would assign it "
    "to. A line about a body is not 'the cop' unless it SOUNDS like him. If a line is generic and could be "
    "almost anyone, still pick the closest — you will be wrong often on generic lines, and that is exactly "
    "the signal we want.\n\n"
    'Return ONLY JSON: {"calls": [{"line": <int>, "speaker": "<one key from the cards>"}]}. '
    "Use the lowercase key shown in each card header. One call per line, no commentary."
)


def keys_from_cards(cards: str) -> list[str]:
    """The valid character keys, taken from the card headers (### Name — `key`)."""
    return list(dict.fromkeys(re.findall(r"`([a-z][a-z0-9_]+)`", cards)))


def parse_dialogue(script: str, alias: dict | None = None) -> list[tuple[str, str]]:
    """[(key, line)] for every 'SPEAKER: text' dialogue line; action prose is skipped."""
    alias = alias or {}
    out: list[tuple[str, str]] = []
    for raw in script.splitlines():
        s = raw.strip()
        if not s or s[0] in "#*>|`-":
            continue
        m = re.match(r"^([^:：]{1,22}?)\s*[:：]\s*(.+)$", s)
        if not m:
            continue
        label, text = m.group(1).strip(), m.group(2).strip()
        text = re.sub(r"\([^)]*\)", "", text).strip()          # drop parentheticals
        if len(text) < 2:
            continue
        key = alias.get(label)
        if key is None:
            if re.search(r"\s", label):        # multi-word label -> a slugline/note, not a cue
                continue
            key = label.lower()
        out.append((key, text))
    return out


def _parse_calls(raw: str) -> dict[int, str]:
    m = re.search(r"\{.*\}", raw.strip(), re.S)
    try:
        obj = json.loads(m.group() if m else raw)
    except Exception:
        return {}
    calls = obj.get("calls", []) if isinstance(obj, dict) else obj
    out = {}
    for c in calls if isinstance(calls, list) else []:
        if isinstance(c, dict) and "line" in c and "speaker" in c:
            try:
                out[int(c["line"])] = str(c["speaker"]).strip().lower()
            except Exception:
                pass
    return out


def audit(script: str, cards: str, client, alias: dict | None = None,
          max_lines: int = 120, chunk: int = 24) -> Result:
    cast = keys_from_cards(cards)
    castset = set(cast)
    pairs = parse_dialogue(script, alias)
    unmapped = sorted({k for k, _ in pairs if k not in castset})
    judged = [(k, t) for k, t in pairs if k in castset][:max_lines]

    guesses: dict[int, str] = {}
    for start in range(0, len(judged), chunk):
        block = judged[start:start + chunk]
        numbered = "\n".join(f"{start + i}\t{t}" for i, (_, t) in enumerate(block))
        raw = client.complete(
            f"VOICE CARDS (the key):\n{cards}\n\nLINES (speaker removed):\n{numbered}\n\n"
            "Attribute each numbered line to one character key.", system=SYSTEM)
        guesses.update(_parse_calls(raw))

    records = [Rec(i, true, guesses.get(i), text) for i, (true, text) in enumerate(judged)]
    return Result(records, cast, unmapped)


# ---- scoring -------------------------------------------------------------------------------------
def _scored(res: Result) -> list[Rec]:
    return [r for r in res.records if r.guess in set(res.cast)]


def accuracy(res: Result) -> tuple[int, int]:
    sc = _scored(res)
    return sum(1 for r in sc if r.guess == r.true), len(sc)


def confusions(res: Result) -> Counter:
    """Unordered character pairs the model could not keep apart -> count."""
    c: Counter = Counter()
    for r in _scored(res):
        if r.guess != r.true:
            c[tuple(sorted((r.true, r.guess)))] += 1
    return c


def report(res: Result) -> str:
    correct, total = accuracy(res)
    if not total:
        return "blind attribution: no judged lines (check the script format / alias)."
    pct = 100 * correct / total
    out = [f"blind attribution — {total} lines judged, {correct} correct ({pct:.0f}%)."]

    per_true = {k: [r for r in _scored(res) if r.true == k] for k in res.cast}
    out.append("\nper character (recall — low = a blurred voice):")
    for k in res.cast:
        rs = per_true[k]
        if not rs:
            continue
        ok = sum(1 for r in rs if r.guess == r.true)
        miss = Counter(r.guess for r in rs if r.guess != r.true)
        top = f"  most taken for: {miss.most_common(1)[0][0]} ×{miss.most_common(1)[0][1]}" if miss else ""
        out.append(f"  {k:10} {ok:2}/{len(rs):<2} {100*ok//len(rs):3}%{top}")

    worst = confusions(res).most_common(6)
    if worst:
        out.append("\nworst blur (re-voice these pairs):")
        out += [f"  {a} ↔ {b}  ×{n}" for (a, b), n in worst]

    miss_lines = [r for r in _scored(res) if r.guess != r.true][:12]
    if miss_lines:
        out.append("\nsample misattributions (the lines that could be anyone):")
        for r in miss_lines:
            out.append(f"  true={r.true:9} guess={r.guess:9} {r.text[:46]}")
    if res.unmapped:
        out.append(f"\n(not judged — speakers absent from the cards: {', '.join(res.unmapped)})")
    return "\n".join(out)


def gate(script: str, cards: str, client, alias: dict | None = None,
         threshold: float = 0.70, max_pair: int = 3) -> tuple[bool, str]:
    """Pass if overall accuracy >= threshold AND no character pair is confused more than max_pair times."""
    res = audit(script, cards, client, alias=alias)
    correct, total = accuracy(res)
    pct = correct / total if total else 0.0
    worst = confusions(res).most_common(1)
    blur_ok = (not worst) or worst[0][1] <= max_pair
    ok = total > 0 and pct >= threshold and blur_ok
    tag = f"{100*pct:.0f}% attributed"
    if worst:
        tag += f", worst blur {worst[0][0][0]}↔{worst[0][0][1]}×{worst[0][1]}"
    return ok, tag


# Devanagari cue → voice-card key (project data for the Hindi script; the module itself is general).
_AMAL_CUES = {
    "रतन": "ratan", "देवा": "deva", "मिश्रा": "mishra", "भेरूलाल": "bherulal", "कांता": "kanta",
    "सुगना": "sugna", "लीला": "leela", "धनराज": "dhanraj", "चारण": "charan", "राणा": "rana",
    "अम्मा": "amma", "मंजू": "manju", "गोविंद": "govind", "भँवर": "bhanwar", "डॉक्टर": "bhanwar",
    "भाट": "charan",
}

if __name__ == "__main__":
    import os
    import sys

    from metaphrand.generate import OllamaClient

    slug = sys.argv[1] if len(sys.argv) > 1 else "amal"
    sdir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "stories", slug)
    cards = open(os.path.join(sdir, "VOICE_CARDS.md"), encoding="utf-8").read()
    script_path = next((os.path.join(sdir, f) for f in ("EP1_PAGES_HI.md", "EP1_PAGES.md")
                        if os.path.exists(os.path.join(sdir, f))), None)
    script = open(script_path, encoding="utf-8").read()
    cap = int(sys.argv[2]) if len(sys.argv) > 2 else 120
    res = audit(script, cards, OllamaClient(json_mode=True),
                alias=_AMAL_CUES if slug == "amal" else None, max_lines=cap)
    print(f"[{os.path.basename(script_path)}]")
    print(report(res), flush=True)
