"""The gate → repair loop — make a failed gate drive a rewrite, not just a report.

:func:`brehon.pipeline.check` *measures*; :func:`brehon.world.populate` already repairs to
its gate; :func:`brehon.concreteness.concretize` rewrites flowery beats. This is the general
form of that move. Given a ``generate(feedback)`` that produces a candidate and a
``check(candidate)`` that returns whether it passed and *why*, :func:`repair` regenerates
with the failure fed back, up to a bound — the engine becoming self-correcting instead of
handing a human a report.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Callable, Tuple


@dataclass
class RepairResult:
    value: str
    passed: bool
    tries: int
    reason: str  # the last failure reason ("" if it passed)


def repair(
    generate: Callable[[str], str],
    check: Callable[[str], Tuple[bool, str]],
    *,
    max_tries: int = 3,
) -> RepairResult:
    """Generate → check → on failure feed the reason back and regenerate, up to ``max_tries``.

    ``generate(feedback)`` produces a candidate; ``feedback`` is ``""`` on the first try and
    the prior failure reason after that, so the generator can fix exactly what failed.
    ``check(candidate)`` returns ``(passed, reason)``; ``reason`` is handed to the next
    ``generate`` call. Returns the best candidate, whether it passed, how many tries it took,
    and the last reason.
    """
    if max_tries < 1:
        raise ValueError(f"max_tries must be >= 1, got {max_tries}")
    feedback = ""
    value = ""
    reason = ""
    for attempt in range(1, max_tries + 1):
        value = generate(feedback)
        passed, reason = check(value)
        if passed:
            return RepairResult(value, True, attempt, "")
        feedback = reason
    return RepairResult(value, False, max_tries, reason)
