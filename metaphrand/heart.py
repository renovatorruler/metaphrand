"""The heart layer — relationships as ledgers, feeling as structure.

The gap this closes (the Good Wife anatomy): a bond between two characters
carries banked history; wounds set its temperature; a cold bond BLOCKS plot
actions; and the state moves again only through a re-encounter with a banked
DEPOSIT (the birthday-cake tape, the figs, the chessboard) — never through
argument. Plot pressure cannot thaw anyone. That rule is enforced here by
construction: a thaw must cite a deposit, and the deposit must have been
planted in an earlier scene, in passing, before anyone needed it.

Beat attributes (the seed carries the heart as data):
    {"bond": "nadir+lena", "deposit": "the figs"}        — banks history
    {"bond": "nadir+lena", "wound": "the east order"}    — temperature down
    {"bond": "nadir+lena", "thaw": "the figs"}           — temperature up, BY deposit
    {"bond": "nadir+lena", "blocks": "the call"}         — the cold gating plot
    {"bond": "nadir+lena", "unlocks": "the call"}        — the thaw paying into plot

Checks (deterministic, spine order):
  * a wound needs a prior deposit on the same bond — you cannot lose on the
    page what was never shown banked ("unbanked wound");
  * a thaw must name a deposit planted EARLIER on the same bond ("unbanked
    thaw") — thawing by argument is structurally impossible;
  * every declared bond banks at least one deposit;
  * a story with NO bonds at all fails — cold is a choice, not a default;
  * cross-traffic is reported (blocks/unlocks), and a story whose bonds never
    gate plot is flagged: feeling without consequence is decoration.

The gate is OPT-OUT: the pipeline runs it on every story. A deliberately
heartless piece must declare it on the root: attributes={"heart": "opt-out"}.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import TYPE_CHECKING, Optional

if TYPE_CHECKING:  # pragma: no cover
    from metaphrand.story import Metaphor, Story


@dataclass
class HeartReport:
    bonds: list[str] = field(default_factory=list)
    deposits: int = 0
    wounds: int = 0
    thaws: int = 0
    blocks: int = 0
    unlocks: int = 0
    violations: list[str] = field(default_factory=list)

    @property
    def passed(self) -> bool:
        return not self.violations

    def summary(self) -> str:
        if not self.bonds:
            return "no bonds declared — the story has no heart layer"
        if self.violations:
            return f"{len(self.violations)} violation(s): " + "; ".join(self.violations)
        traffic = (f", {self.blocks} block(s)/{self.unlocks} unlock(s)"
                   if (self.blocks or self.unlocks) else ", no cross-traffic (decorative)")
        return (f"{len(self.bonds)} bond(s), {self.deposits} deposit(s) banked, "
                f"{self.wounds} wound(s), {self.thaws} thaw(s) — all paid from the bank"
                f"{traffic}")


def _spine(story: "Story") -> list["Metaphor"]:
    from metaphrand import cinema  # lazy: avoid import cycles
    return list(cinema.spine_beats(story))


def heart(story: "Story") -> HeartReport:
    """Walk the spine in order and audit every bond's ledger."""
    rep = HeartReport()
    banked: dict[str, set[str]] = {}    # bond -> deposit names planted so far
    seen_bonds: list[str] = []

    for beat in _spine(story):
        a = beat.attributes
        bond = a.get("bond")
        if not bond:
            continue
        if bond not in seen_bonds:
            seen_bonds.append(bond)
        if a.get("deposit"):
            banked.setdefault(bond, set()).add(str(a["deposit"]))
            rep.deposits += 1
        if a.get("wound"):
            rep.wounds += 1
            if not banked.get(bond):
                rep.violations.append(
                    f"unbanked wound on '{bond}' at {beat.id}: nothing was "
                    f"deposited before it broke")
        if a.get("thaw"):
            rep.thaws += 1
            name = str(a["thaw"])
            if name not in banked.get(bond, set()):
                rep.violations.append(
                    f"unbanked thaw on '{bond}' at {beat.id}: '{name}' was never "
                    f"planted earlier — a thaw must spend a deposit, not an argument")
        if a.get("blocks"):
            rep.blocks += 1
        if a.get("unlocks"):
            rep.unlocks += 1

    rep.bonds = seen_bonds
    if not seen_bonds:
        rep.violations.append(
            "no bonds declared — the story has no heart layer (declare bonds, "
            "or opt out on the root: attributes={'heart': 'opt-out'})")
    for bond in seen_bonds:
        if not banked.get(bond):
            rep.violations.append(f"bond '{bond}' declared but never banked a deposit")
    return rep
