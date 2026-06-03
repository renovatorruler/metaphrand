"""The cinema layer — tell it in pictures, not in talk.

Film is a visual medium: a story should read with the sound off, in any
language. The model does not believe this. Left alone it writes scenes of people
explaining things to each other, because dialogue is the cheapest way to move
information. This layer is the counterweight. It splits every beat into what the
audience SEES (the manifestation — action and image) and what it HEARS (the
dialogue), and holds the SEEN track to account:

* the **modality** gate (deterministic, lexical) measures how much of the spine is
  carried by action versus talk, forbids long runs of talking-heads beats, and
  insists the load-bearing beats (the opening and final image, the finale) be
  carried by the eye;
* the **silent-spine** round-trip (needs a model) strips every word of dialogue,
  shows the model only the images in order, and asks whether the transformation
  still reads. If the story collapses with the sound off, it is a radio play.

A beat is *verbal* only when it is talk with no physical anchor; a beat that gives
the eye a real action or image counts as *visual* even when people also speak. The
fix this gate pushes toward is not spectacle — it is meaning carried in pictures.
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import TYPE_CHECKING, Optional

if TYPE_CHECKING:
    from brehon.generate import LLMClient
    from brehon.metaphor import Metaphor
    from brehon.story import Story

_WORD = re.compile(r"[a-z']+")

# Physical action / motion / image — a camera can photograph these happening.
_ACTION = {
    "walk", "walks", "walked", "run", "runs", "ran", "take", "takes", "took",
    "grab", "grabs", "grabbed", "set", "sets", "put", "puts", "drop", "drops",
    "dropped", "pick", "picks", "picked", "load", "loads", "loaded", "drive",
    "drives", "drove", "hit", "hits", "strike", "strikes", "struck", "throw",
    "throws", "threw", "pull", "pulls", "pulled", "push", "pushes", "pushed",
    "open", "opens", "opened", "shut", "shuts", "close", "closes", "closed",
    "break", "breaks", "broke", "lift", "lifts", "lifted", "carry", "carries",
    "carried", "climb", "climbs", "climbed", "fall", "falls", "fell", "stand",
    "stands", "stood", "sit", "sits", "sat", "turn", "turns", "turned", "cross",
    "crosses", "crossed", "hand", "hands", "handed", "slide", "slides", "slid",
    "press", "presses", "pressed", "fold", "folds", "folded", "sign", "signs",
    "signed", "fire", "fires", "fired", "reload", "reloads", "haul", "hauls",
    "hauled", "drag", "drags", "dragged", "spit", "spits", "grin", "grins",
    "grinned", "smoke", "smokes", "pour", "pours", "poured", "shake", "shakes",
    "shaking", "tremble", "trembles", "trembling", "kick", "kicks", "kicked",
    "slap", "slaps", "slapped", "hug", "hugs", "hugged", "march", "marches",
    "ship", "ships", "shipped", "bleed", "bleeds", "bled", "wave", "waves",
    "flick", "flicks", "flicked", "aim", "aims", "aimed", "crawl", "crawls",
    "crawled", "hide", "hides", "hid", "tear", "tears", "tore", "burn", "burns",
    "burned", "dig", "digs", "dug", "lay", "lays", "laid", "strips", "stripping",
    "buries", "bury", "buried", "raises", "raise", "raised", "folds", "shoves",
}

# Speech acts — a camera can only photograph the mouth moving.
_SPEECH = {
    "say", "says", "said", "tell", "tells", "told", "argue", "argues", "argued",
    "argument", "explain", "explains", "explained", "admit", "admits", "admitted",
    "ask", "asks", "asked", "talk", "talks", "talked", "insist", "insists",
    "confess", "confesses", "lecture", "lectures", "debate", "debates", "plead",
    "pleads", "announce", "announces", "recite", "recites", "declare", "declares",
    "repeat", "repeats", "speech", "conversation", "mutters", "whispers", "answer",
    "answers", "reply", "replies", "states", "claims", "jokes", "quips", "warns",
}

# Function tags whose beats must land as an image, never as a conversation.
_MUST_SEE = {"opening image", "final image", "finale"}

_STOP = {
    "the", "a", "an", "and", "or", "but", "of", "to", "in", "on", "at", "for",
    "with", "his", "her", "him", "she", "they", "them", "their", "that", "this",
    "who", "into", "out", "up", "down", "off", "over", "not", "no", "from", "as",
    "is", "was", "were", "be", "are", "it", "he", "you", "your", "all", "one",
}


def _tokens(text: str) -> list[str]:
    return _WORD.findall(text.lower())


def _has(text: str, vocab: set[str]) -> bool:
    return any(w in vocab for w in _tokens(text))


def _content(text: str) -> set[str]:
    return {w for w in _tokens(text) if w not in _STOP and len(w) > 2}


def seen(node: "Metaphor") -> str:
    """What the audience SEES in this beat — its action/image, dialogue aside."""
    return (node.manifestation or node.meaning or "").strip()


def heard(node: "Metaphor") -> str:
    """The spoken line, when the seed carries the actual words (not a flag)."""
    value = node.attributes.get("dialogue")
    if isinstance(value, str) and value.strip().lower() not in ("", "yes", "no", "true"):
        return value.strip()
    return ""


def classify(node: "Metaphor") -> str:
    """``"visual"`` | ``"verbal"`` | ``"empty"`` — carried by the eye or the ear?

    A beat is *verbal* only if it is speech with no physical anchor. A beat that
    gives the eye a real action or image is *visual* even when people also talk —
    the point is whether a stranger could see anything happen.
    """
    text = f"{node.meaning} {node.manifestation}"
    flagged_speech = bool(node.attributes.get("dialogue"))
    if not text.strip() and not flagged_speech:
        return "empty"
    action = _has(text, _ACTION)
    speech = flagged_speech or _has(text, _SPEECH)
    return "verbal" if (speech and not action) else "visual"


def spine_beats(story: "Story") -> list["Metaphor"]:
    """The page beats in narrative order: previous -> mirror -> next, or acts."""
    if story.root_id is None:
        return []
    root = story.get(story.root_id)
    out: list["Metaphor"] = []
    if root.kind == "mirror":
        states = {s.attributes.get("role"): s
                  for s in story.children(root.id) if s.kind == "state"}
        prev, nxt = states.get("previous"), states.get("next")
        if prev is not None:
            out += [n for n in story.walk(prev.id) if n.kind == "beat"]
        out.append(root)  # the mirror scene sits at the hinge, and must be seen
        if nxt is not None:
            out += [n for n in story.walk(nxt.id) if n.kind == "beat"]
    else:
        for act in (m for m in story.children(root.id) if m.kind == "act"):
            out += [n for n in story.walk(act.id) if n.kind == "beat"]
    return out


@dataclass
class ModalityReport:
    total: int
    visual: int
    longest_talk_run: int
    talky_key_beats: list[str]      # load-bearing beats carried by talk alone
    max_run: int
    min_visual: float

    @property
    def verbal(self) -> int:
        return self.total - self.visual

    @property
    def visual_fraction(self) -> float:
        return self.visual / self.total if self.total else 1.0

    @property
    def passed(self) -> bool:
        return (self.longest_talk_run <= self.max_run
                and self.visual_fraction >= self.min_visual
                and not self.talky_key_beats)

    def summary(self) -> str:
        head = f"{self.visual}/{self.total} beats visual ({self.visual_fraction:.0%})"
        if self.passed:
            return f"{head}, longest talk-run {self.longest_talk_run}"
        bits = [head]
        if self.longest_talk_run > self.max_run:
            bits.append(f"talk-run {self.longest_talk_run}>{self.max_run}")
        if self.visual_fraction < self.min_visual:
            bits.append(f"under {self.min_visual:.0%} visual")
        if self.talky_key_beats:
            bits.append("talky key beats: " + ", ".join(self.talky_key_beats))
        return "; ".join(bits)


def modality(story: "Story", *, max_run: int = 2, min_visual: float = 0.5) -> ModalityReport:
    """Measure the eye/ear balance of the spine and flag talking-heads runs."""
    pairs = [(b, classify(b)) for b in spine_beats(story)]
    pairs = [(b, k) for b, k in pairs if k != "empty"]
    total = len(pairs)
    visual = sum(1 for _, k in pairs if k == "visual")

    run = longest = 0
    for _, kind in pairs:
        run = run + 1 if kind == "verbal" else 0
        longest = max(longest, run)

    talky_key: list[str] = []
    for beat, kind in pairs:
        if kind != "verbal":
            continue
        if beat.kind == "mirror":
            talky_key.append("mirror")
        function = str(beat.attributes.get("function", "")).strip().lower()
        if function in _MUST_SEE:
            talky_key.append(function)
    return ModalityReport(total, visual, longest, talky_key, max_run, min_visual)


def silent_spine(story: "Story") -> str:
    """The sound-off cut: every beat's image, in order, with the dialogue gone."""
    lines = []
    for index, beat in enumerate(spine_beats(story), 1):
        image = seen(beat)
        if image:
            lines.append(f"{index}. {image}")
    return "\n".join(lines)


@dataclass
class SilentReport:
    transformation: str
    recovered: str
    passed: bool

    def summary(self) -> str:
        if self.passed:
            return "sound off, the transformation still reads"
        got = self.recovered[:60] + ("…" if len(self.recovered) > 60 else "")
        return f"sound off, the arc doesn't read (got: {got!r})"


def silent_legibility(story: "Story", client: "LLMClient", *, threshold: float = 0.34) -> SilentReport:
    """Strip the dialogue, show the model only the images: does the arc read?"""
    if story.root_id is None:
        return SilentReport("", "", True)
    from brehon.generate import _extract_json  # lazy: avoid an import cycle

    transformation = story.get(story.root_id).meaning.strip()
    prompt = (
        "Below is a film told only in pictures — the actions and images, in order, "
        "with every word of dialogue removed. In one sentence: what change does the "
        "main character go through, beginning to end?\n\n"
        f"{silent_spine(story)}\n\n"
        'Return JSON: {"arc": "<the transformation you can read>"}'
    )
    try:
        data = _extract_json(client.complete(
            prompt, system="You read a story from its pictures alone. Output only JSON."))
        recovered = str(data.get("arc", "")).strip()
    except Exception:
        recovered = ""
    target = _content(transformation)
    passed = (not target) or (len(target & _content(recovered)) / len(target) >= threshold)
    return SilentReport(transformation, recovered, passed)
