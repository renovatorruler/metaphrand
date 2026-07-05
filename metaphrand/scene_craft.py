"""metaphrand.scene_craft — the Mercurio scene rubric, enforced (docs/07-SCENE-CRAFT.md).

Where ``drama.py`` asks "is the scene a fight?" (Mamet) and ``showing.py`` asks "is it shown?", this
asks Jim Mercurio's question: is each scene a complete story that changes BOTH the plot AND a person?
A local model judges each scene against a FIXED rubric and returns a per-criterion verdict, so a clean
scene is shown, not claimed. It over-flags by design (triage; the author's ear is the calibration —
don't chase the score). CORE criteria fail the gate; the rest are flags.

    from metaphrand.scene_craft import audit, report, gate
    from metaphrand.generate import OllamaClient
    print(report(audit(scene_text, OllamaClient(json_mode=True))))

CLI:  python -m metaphrand.scene_craft amal [n_scenes]
"""
from __future__ import annotations

import json
import re
from collections import namedtuple

Check = namedtuple("Check", "id desc core passed note")

# (id, description, core?) — CORE criteria fail the gate; the rest are triage flags.
RUBRIC = [
    ("single_action",    "One focused action, one time & place (unity)", True),
    ("plot_change",      "The situation ends shifted from how it opened", True),
    ("character_change", "A character's inner state shifts, caused by the scene's action", True),
    ("reversal",         "A set-up surprise, inevitable in hindsight & rooted in character", True),
    ("beats",            "Distinct, escalating beats — not one note repeated (Clurman)", False),
    ("escalation",       "Stakes/accountability rise; hard for the protagonist", False),
]
CORE = [r[0] for r in RUBRIC if r[2]]

CRITIC_SYSTEM = (
    "You are a ruthless scene editor, not a writer, enforcing Jim Mercurio's scene craft. A SCENE is a "
    "story in itself: one action, in one time and place, that changes BOTH the plot AND a person.\n\n"
    "Judge the scene against EACH criterion; return pass/fail with a short reason:\n"
    "  single_action     — one focused action, one time & place. FAIL if two scenes are fused, or it "
    "meanders with no single dramatic event.\n"
    "  plot_change       — the external situation ends DIFFERENT from how it opened. FAIL if nothing in "
    "the story moves (a static info-dump or mood beat).\n"
    "  character_change  — a character's INNER state shifts, caused by what they do here. FAIL if everyone "
    "ends inside exactly as they began. This is the one most scenes miss.\n"
    "  reversal          — a surprise or directional shift, SET UP so it feels inevitable in hindsight and "
    "rooted in character (a frustrated expectation). FAIL if it is a frictionless straight line.\n"
    "  beats             — built of distinct, escalating beats, not one note repeated. FAIL if the beats "
    "are redundant or hold a single note.\n"
    "  escalation        — stakes and accountability RISE; it is hard for the protagonist. FAIL if it is "
    "easy or the pressure never mounts.\n\n"
    "Do NOT judge prose, subtext, or whether lines sound good — other gates handle those. Judge ONLY the "
    "dramatic architecture above. Be strict on character_change and reversal.\n\n"
    'Return ONLY JSON: {"checks":[{"id":"<criterion>","pass":<true|false>,"note":"<reason, max 12 words>"}]}'
    ", one entry per criterion."
)


def _parse(raw: str) -> dict:
    m = re.search(r"\{.*\}", raw.strip(), re.S)
    try:
        obj = json.loads(m.group() if m else raw)
    except Exception:
        return {}
    rows = obj.get("checks", []) if isinstance(obj, dict) else obj
    out = {}
    for c in rows if isinstance(rows, list) else []:
        if isinstance(c, dict) and "id" in c:
            out[str(c["id"])] = (bool(c.get("pass", True)), str(c.get("note", ""))[:80])
    return out


def audit(scene: str, client) -> list[Check]:
    """Judge one scene against the rubric. Missing criteria default to pass (never false-fail)."""
    raw = client.complete(f"Judge this scene against every criterion.\n\nSCENE:\n{scene.strip()}",
                          system=CRITIC_SYSTEM)
    got = _parse(raw)
    return [Check(cid, desc, core, *got.get(cid, (True, ""))) for cid, desc, core in RUBRIC]


def report(checks: list[Check], heading: str = "") -> str:
    head = f"scene craft — {heading}".rstrip() if heading else "scene craft"
    fails = [c for c in checks if not c.passed]
    if not fails:
        return f"{head}: PASS — all {len(checks)} criteria met."
    core_n = sum(1 for c in fails if c.core)
    out = [f"{head}: {core_n} core FAIL, {len(fails) - core_n} flag(s)"]
    for c in checks:
        mark = "✓" if c.passed else ("✗" if c.core else "•")
        line = f"  {mark} {c.id:17} {c.desc}"
        if not c.passed and c.note:
            line += f"  → {c.note}"
        out.append(line)
    return "\n".join(out)


def gate(scene: str, client) -> tuple[bool, str]:
    checks = audit(scene, client)
    core_fail = [c.id for c in checks if c.core and not c.passed]
    return (not core_fail, f"core fails: {', '.join(core_fail)}" if core_fail else "scene-craft clean")


def split_scenes(text: str) -> list[tuple[str, str]]:
    """[(heading, body)] split on markdown '## ...' scene headings."""
    parts = re.split(r"(?m)^##\s+(.+?)\s*$", text)
    return [(parts[i].strip(), parts[i + 1].strip()) for i in range(1, len(parts) - 1, 2)]


if __name__ == "__main__":
    import os
    import sys

    from metaphrand.generate import OllamaClient

    slug = sys.argv[1] if len(sys.argv) > 1 else "amal"
    limit = int(sys.argv[2]) if len(sys.argv) > 2 else 0
    sdir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "stories", slug)
    path = next((os.path.join(sdir, f) for f in ("EP1_PAGES.md", "EP1_PAGES_HI.md")
                 if os.path.exists(os.path.join(sdir, f))), None)
    scenes = split_scenes(open(path, encoding="utf-8").read())
    if limit:
        scenes = scenes[:limit]
    client = OllamaClient(json_mode=True)
    print(f"[{os.path.basename(path)}] — {len(scenes)} scene(s)\n")
    npass = 0
    for heading, body in scenes:
        if len(body) < 40:
            continue
        checks = audit(body, client)
        ok = not [c for c in checks if c.core and not c.passed]
        npass += ok
        print(report(checks, heading[:48]), "\n")
    print(f"== {npass}/{len(scenes)} scenes pass the core rubric ==", flush=True)
