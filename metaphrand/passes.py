"""metaphrand.passes — the craft-pass pipeline.

Each pass is a PROMPT run by a blind ``claude -p`` critic over the scene text — a unit test whose
assertion is an LLM read. Every pass has a **test** prompt (validate: pass/fail + findings) and a
**fix** prompt (rewrite to pass). Content passes first, the **editorial** pass last (and local:
craftlint + the ollama One-Law critic, which works well for language). Every verdict is written to
``<scene>/.passes/`` so a run is shown on disk, never merely claimed.

    python -m metaphrand.passes stories/amal/EP1.md            # audit (all test passes)
    python -m metaphrand.passes stories/amal/EP1.md --repair   # test -> fix -> retest

The blind critic is the point: a fresh Claude that never saw the author write the scene cannot excuse
its own prose, the way the author-in-context can.
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field

from metaphrand import craftlint as _craftlint

_VERDICT = ('\n\nReturn ONLY minified JSON, no prose, no code fence: '
            '{"pass": true|false, "verdict": "<one blunt sentence>", '
            '"findings": ["<specific, actionable problem, with where>", ...]}. '
            'findings is [] when it passes. Be a hard grader; a borderline scene FAILS.')


@dataclass
class Pass:
    name: str
    scope: str   # "scene" | "story"
    test: str    # validate prompt (the critic's role + the rule)
    fix: str     # implement prompt (how to rewrite)


@dataclass
class Result:
    name: str
    passed: bool
    verdict: str
    findings: list = field(default_factory=list)


def _claude(prompt: str, timeout: int = 300) -> str:
    r = subprocess.run(["claude", "-p"], input=prompt, capture_output=True, text=True, timeout=timeout)
    if r.returncode != 0:
        raise RuntimeError(f"claude -p failed ({r.returncode}): {r.stderr[:300]}")
    return r.stdout.strip()


def _parse(raw: str) -> tuple[bool, str, list]:
    m = re.search(r"\{.*\}", raw, re.S)
    try:
        o = json.loads(m.group()) if m else {}
    except Exception:
        return False, "(critic returned unparseable output)", [raw[:200]]
    return bool(o.get("pass", False)), str(o.get("verdict", "")), list(o.get("findings", []))


def _ctx(prompt: str, context: str) -> str:
    return prompt.replace("{{CONTEXT}}", context or "(none supplied)")


def test_pass(p: Pass, text: str, context: str = "") -> Result:
    if p.name == "editorial":            # local: deterministic floor + ollama One-Law ceiling
        return _editorial(text)
    raw = _claude(_ctx(p.test, context) + _VERDICT + "\n\n=== SCENE ===\n" + text)
    return Result(p.name, *_parse(raw))


def fix_pass(p: Pass, text: str, findings: list, context: str = "") -> str:
    fb = ("\n\nFix exactly these problems, change nothing else:\n- " + "\n- ".join(findings)) if findings else ""
    return _claude(_ctx(p.fix, context) + fb
                   + "\n\nReturn ONLY the rewritten scene in the same format (English action, "
                     "Devanagari dialogue), nothing else.\n\n=== SCENE ===\n" + text)


def _editorial(text: str) -> Result:
    """The language pass, kept local. The GATE is craftlint (deterministic, reliable); the ollama
    One-Law critic runs as ADVISORY only — it is too noisy on clean prose to gate on."""
    vs = _craftlint.lint(text, mode="screenplay")
    hi = [v for v in vs if v.severity == "HIGH"]
    passed = not hi                                   # deterministic floor is the gate
    findings = [f"L{v.line} {v.rule}: {v.snippet}" for v in hi]
    verdict = "clean (craftlint floor)" if passed else f"{len(hi)} hard line-level tells"
    try:                                              # ceiling: advisory, never gates
        from metaphrand import naturalness as _nat
        from metaphrand.generate import OllamaClient
        fl = _nat.audit(text, OllamaClient(json_mode=True))
        if fl:
            verdict += f"; +{len(fl)} ollama advisory"
            findings += [f"(advisory) L{f.line}: {f.reason}" for f in fl]
    except Exception:
        pass
    return Result("editorial", passed, verdict, findings)


def audit(text: str, passes: list[Pass], context: str = "", workers: int = 6) -> list[Result]:
    """Run every test pass (content passes concurrently via claude -p; editorial local at the end)."""
    content = [p for p in passes if p.name != "editorial"]
    out: list[Result] = []
    with ThreadPoolExecutor(max_workers=workers) as ex:
        futs = {ex.submit(test_pass, p, text, context): p for p in content}
        done = {}
        for f in futs:
            p = futs[f]
            try:
                done[p.name] = f.result()
            except Exception as e:
                done[p.name] = Result(p.name, False, f"(pass errored: {str(e)[:80]})", [])
    out = [done[p.name] for p in content]
    out.append(_editorial(text))         # editorial last
    return out


def report(results: list[Result]) -> str:
    n = sum(1 for r in results if r.passed)
    lines = [f"CRAFT PASSES — {n}/{len(results)} passed", ""]
    for r in results:
        lines.append(f"[{'PASS' if r.passed else 'FAIL'}] {r.name:<18} {r.verdict}")
        for f in r.findings:
            lines.append(f"        · {f}")
    return "\n".join(lines)


def write_report(text: str, passes: list[Pass], path: str, context: str = "") -> bool:
    res = audit(text, passes, context)
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    open(path, "w", encoding="utf-8").write(report(res) + "\n")
    return all(r.passed for r in res)


# ---------------------------------------------------------------- the passes
SCENE_PASSES = [
    Pass("drama", "scene",
         "You are a ruthless drama editor in the Mamet tradition. A scene must be a FIGHT: someone "
         "wants something concrete and urgent, is actively OPPOSED, and the scene TURNS on a win or a "
         "loss. People exchanging information, the protagonist gathering facts, or characters who "
         "simply agree = FAIL. Name who wants what, the opposition, and the turn — or their absence.",
         "Rewrite so the scene is a fight: give the characters colliding wants, real opposition, and a "
         "turn, WITHOUT changing the plot facts or adding melodrama."),
    Pass("human-reaction", "scene",
         "You are a human-truth editor. Judge whether every character reacts the way a real person in "
         "that exact situation and relationship would — emotionally, not as a plot function. A "
         "bereaved parent must grieve, not behave like a clerk; fear, shame, love must be present "
         "where they would be. Flag any reaction too cold, too convenient, or inhuman for the moment.",
         "Rewrite so each character's reaction is the true human one for their situation and bond, "
         "keeping the plot intact."),
    Pass("voice", "scene",
         "You are a dialogue editor. With the character names hidden, could you still tell who is "
         "speaking? Each must have a distinct voice — rhythm, vocabulary, class, caste, what they "
         "will and will not say. Flag any two who sound alike, anyone who sounds like 'the writer,' "
         "and anyone with eloquence their station has not earned.",
         "Rewrite the dialogue so each character is unmistakable with the names hidden, per their "
         "station and nature; only a character who earns eloquence gets it."),
    Pass("dialogue-realism", "scene",
         "You are a realism editor in the key of Lonergan, Annie Baker, Mike Leigh. Real speech is "
         "messy, halting, interrupted, evasive, and inarticulate about pain. Flag lines that are too "
         "clean, too on-the-nose, too well-made, or that 'land' like written dialogue rather than "
         "spoken talk.",
         "Rewrite the dialogue into real speech — messy, indirect, inarticulate where it should be — "
         "without losing the clarity of each character's intent."),
    Pass("backstory", "scene",
         "You are a subtext editor guarding the iceberg. These facts are SUBMERGED and must NOT appear "
         "on the page, stated or implied-too-clearly: {{CONTEXT}}. Flag any line that leaks one. "
         "Separately, flag any character who fails to carry their own history as subtext (states what "
         "they should only let show).",
         "Rewrite to bury any leaked held card back under the surface, and let each character carry "
         "their history as subtext, never as statement."),
    Pass("heart", "scene",
         "You are an emotion editor (the Good Wife anatomy): feeling is EARNED through banked history "
         "and behavior, never announced. Flag any emotion that is declared or explained instead of "
         "shown, any bond asserted without being built, and any beat that tells the audience how to "
         "feel.",
         "Rewrite so feeling is earned and shown — through action, history, and the withheld — never "
         "announced or explained."),
    Pass("layers", "scene",
         "You are a subtext/PaRDeS editor. The surface must both SHOW and WITHHOLD; the deeper meaning "
         "lives under it and is never stated. Flag anything that flattens the scene to one literal "
         "layer, and any line that says the theme or the point aloud.",
         "Rewrite so the surface carries the held depth as subtext; cut any line that states the "
         "meaning or theme."),
    Pass("show-not-tell", "scene",
         "You are a show-don't-tell editor. Flag every place the script TELLS a state, trait, or "
         "feeling that should be SHOWN through action, behavior, or image — in action lines and in "
         "on-the-nose dialogue alike.",
         "Convert every told state into a shown one — action, behavior, image — without adding "
         "length."),
    Pass("shrink-wrap", "scene",
         "You are a density editor. Flag any passage that is skeletal, generic, or shrink-wrapped: the "
         "abstract where the specific belongs, the placeholder where the lived particular detail of "
         "THIS exact world (Malwa, the opium belt, 1990s rural India) belongs. The world must be felt, "
         "not gestured at.",
         "Flesh the thin places with specific, lived, particular detail of this exact world — without "
         "padding or purple prose."),
    Pass("concreteness", "scene",
         "You are a concreteness editor. Flag flowery, abstract, or vague phrasing (aim ~0% flowery); "
         "every image must be physical and concrete, and any metaphor must carry a legible meaning, "
         "not serve as decoration.",
         "Make every flowery or abstract phrase concrete and physical; ensure any metaphor carries a "
         "clear meaning."),
    Pass("clear-pane", "scene",
         "You are the clear-pane editor. Intrigue must live in the EVENTS, the MEANING, and the "
         "INTENT — never in sentence construction. Flag any place where the writing manufactures "
         "mystery or weight through confusing, withholding, or 'arranged' SYNTAX rather than through "
         "what actually happens. The prose is a clear pane; the depth is behind it.",
         "Rewrite so the sentences are clear and plain; move all intrigue into events, meaning, and "
         "intent, none into syntax."),
    Pass("consistency", "scene",
         "You are a continuity editor. Flag anything in this scene that contradicts the established "
         "world and canon: {{CONTEXT}}.",
         "Fix any contradiction with the canon without changing the scene's intent."),
    Pass("editorial", "scene", "(local: craftlint + ollama One-Law)", "(handled locally)"),
]


def repair(text: str, passes: list[Pass], context: str = "", rounds: int = 1) -> tuple[str, list[str]]:
    """test -> fix -> retest, pass by pass. Conservative: only fixes passes that FAIL."""
    log: list[str] = []
    for p in passes:
        if p.name == "editorial":
            continue
        r = test_pass(p, text, context)
        if r.passed:
            log.append(f"[ok]  {p.name}")
            continue
        text = fix_pass(p, text, r.findings, context)
        r2 = test_pass(p, text, context)
        log.append(f"[fix] {p.name}: {'now passes' if r2.passed else 'still flags — '+r2.verdict}")
    return text, log


if __name__ == "__main__":
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    src = open(args[0], encoding="utf-8").read()
    ctx = open(args[1], encoding="utf-8").read() if len(args) > 1 else ""
    if "--repair" in sys.argv:
        new, log = repair(src, SCENE_PASSES, ctx)
        print("\n".join(log))
        open(args[0].rsplit(".", 1)[0] + ".repaired.md", "w").write(new)
    else:
        print(report(audit(src, SCENE_PASSES, ctx)))
