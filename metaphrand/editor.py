"""metaphrand.editor — a SINGLE STATEFUL Claude script-editor, held across drafts.

The fix for the blind-fresh-critic problem (13 memoryless critics that contradict each other and
re-litigate every round, so the score rotates instead of converging): ONE editor session reads the
scene, holds a ledger of notes, and on each revised draft checks ONLY whether its outstanding notes are
resolved and whether anything NEW broke — reconciling the whole craft bar as a single human editor
would. `craftlint` stays the deterministic floor; the human is the stop (an editor never reaches zero).

    ed = Editor(context=open('stories/amal/PASS_CONTEXT.md').read())
    print(ed.review(open('stories/amal/EP1.md').read()))                 # draft 1: the reconciled notes
    # ...author fixes...
    print(ed.review(new_scene, changed="cut the rage-line; named the prayer"))  # draft 2: deltas only
"""
from __future__ import annotations

import json
import re
import subprocess
import uuid

BAR = """You are ONE ruthless, experienced script editor for a gritty realist Hindi crime drama in the
register of Paatal Lok / Aranyak. You hold a single consistent standard across every draft and you have
MEMORY: once you accept something you do not re-litigate it; on each new draft you check only whether
your outstanding notes were resolved and whether anything NEW broke. You do not invent fresh subjective
complaints about parts you already approved, and you do not pad.

You judge against this whole bar AT ONCE and you RECONCILE its tensions yourself instead of giving
contradictory notes. (E.g. if grief must be shown but a held secret must stay buried, you find the one
reading that does both — open, ordinary grief that reads innocent, not a guarded wall that reads guilty.)

THE BAR:
- DRAMA: a scene is a fight — a concrete want, real opposition, a turn on a win/loss; not fact-gathering.
- HUMAN TRUTH: every character reacts as a real person would in that exact situation and bond.
- VOICE: each character blind-attributable; nobody talks like the writer; eloquence must be earned.
- DIALOGUE REALISM: messy, halting, evasive, inarticulate about pain; no well-made buttons, no on-the-nose lines.
- ICEBERG / HELD CARDS: the submerged facts below must NEVER surface or be pointed at on the page.
- HEART: feeling earned through behavior and banked history, never announced.
- LAYERS: the surface shows and withholds; the theme is never said aloud.
- SHOW DON'T TELL: no narrator interiority naming a state the staging already carries; no emotion wrylies.
- DENSITY: specific, lived, particular to THIS world; never skeletal or generic.
- CONCRETENESS: physical and concrete; metaphor only when it carries a legible meaning.
- CLEAR PANE: intrigue lives in events / meaning / intent, never in arranged or chopped syntax.
- CONSISTENCY: nothing contradicts canon; held cards stay buried.

CANON AND HELD CARDS FOR THIS STORY:
{context}

Return ONLY JSON, no prose, no fence:
{"verdict":"ship"|"revise",
 "outstanding":[{"note":"<problem>","where":"<line/speaker>","fix":"<the specific fix>"}],
 "resolved_this_round":["<a note you previously raised that is now fixed>"],
 "new_breakage":["<anything the latest change broke>"]}
Be hard but FAIR. If the scene is good enough to shoot, return "ship" with outstanding empty."""


class Editor:
    def __init__(self, context: str = "", session_id: str | None = None):
        self.sid = session_id or str(uuid.uuid4())
        self.context = context
        self.started = False

    def _claude(self, prompt: str, resume: bool) -> str:
        cmd = ["claude", "-p", "--output-format", "json"]
        cmd += (["--resume", self.sid] if resume else ["--session-id", self.sid])
        r = subprocess.run(cmd, input=prompt, capture_output=True, text=True, timeout=600)
        if r.returncode != 0:
            raise RuntimeError(f"claude failed ({r.returncode}): {r.stderr[:200]}")
        return json.loads(r.stdout).get("result", "")

    def _parse(self, raw: str) -> dict:
        m = re.search(r"\{.*\}", raw, re.S)
        try:
            return json.loads(m.group()) if m else {"verdict": "?", "raw": raw[:400]}
        except Exception:
            return {"verdict": "?", "raw": raw[:400]}

    def review(self, scene: str, changed: str = "") -> dict:
        if not self.started:
            prompt = BAR.replace("{context}", self.context or "(none)") + "\n\n=== DRAFT 1 ===\n" + scene
            out = self._parse(self._claude(prompt, resume=False))
            self.started = True
            return out
        prompt = ("Here is the revised draft. "
                  + (f"What I changed: {changed}\n" if changed else "")
                  + "Check ONLY whether your outstanding notes are now resolved and whether anything new "
                    "broke. Do not re-litigate what you already accepted.\n\n=== NEW DRAFT ===\n" + scene)
        return self._parse(self._claude(prompt, resume=True))


def show(ledger: dict) -> str:
    if "raw" in ledger:
        return "EDITOR (unparsed):\n" + ledger["raw"]
    out = [f"EDITOR VERDICT: {ledger.get('verdict','?').upper()}"]
    for k in ("resolved_this_round", "new_breakage"):
        for x in ledger.get(k, []):
            out.append(f"  [{k.split('_')[0]}] {x}")
    for o in ledger.get("outstanding", []):
        out.append(f"  • {o.get('where','')}: {o.get('note','')}")
        if o.get("fix"):
            out.append(f"        fix: {o['fix']}")
    return "\n".join(out)
