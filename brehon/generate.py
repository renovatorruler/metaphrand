"""Generate a metaphor DAG from a premise — the top-down story algorithm.

The hand-authored ``examples/janitor.py`` shows the *target*: a root three-act
metaphor, a handful of recurring themes, the motifs that carry them, and the
page-level beats — every beat hanging under both an act (structure) and a
theme/motif (meaning), so the graph is a true DAG. This module produces that
artifact automatically from a one-line premise.

The split mirrors the rest of the project. An :class:`LLMClient` (by default
:class:`OllamaClient`, talking to a local open-source model) proposes the story
as one strict-JSON document; :func:`build_story` then *assembles* that document
into a :class:`~brehon.story.Story` through the ordinary
``instantiate``/``link`` API. Assembly is pure and deterministic — it reuses
the Story's cycle protection and canonical serialization, repairs bad edges and
voices rather than trusting the model, and is what the tests exercise (with the
model mocked). Only the proposal step is fuzzy; the graph it lands in is the
same deterministic seed every other module already speaks.

The JSON contract the model must return::

    {
      "title": str,
      "premise": str,                 # the controlling idea (root meaning)
      "author": str,                  # optional, defaults to "brehon"
      "narrator_voice": str,          # an allowed voice id (see _AMERICAN_VOICES)
      "cast": {"CHARACTER": voice},   # per-speaker voices
      "themes": [{"id": str, "meaning": str}],
      "motifs": [{"id": str, "meaning": str, "parents": [theme_or_motif_id]}],
      "acts":   [{"id": str, "meaning": str, "beats": [beat]}]
    }
    beat = {
      "id": str, "meaning": str, "manifestation": str,
      "also": [parent_id],            # extra non-act parents -> the DAG
      "slug": str, "character": str, "parenthetical": str, "dialogue": str
    }
"""

from __future__ import annotations

import json
import re
import sys
import urllib.parse
import urllib.request
from typing import Any, Optional, Protocol

from brehon import concreteness
from brehon.story import CycleError, Story

# Kokoro American-English voices (lang_code "a"). Casting is clamped to this
# set so the audio backend never receives a voice it cannot speak. Female ids
# start ``af_``, male ``am_``.
_AMERICAN_VOICES = {
    "af_heart", "af_bella", "af_nicole", "af_sarah", "af_sky", "af_aoede",
    "af_kore", "af_jessica", "af_river", "af_alloy", "af_nova",
    "am_adam", "am_michael", "am_onyx", "am_eric", "am_liam", "am_fenrir",
    "am_puck", "am_echo", "am_santa",
}
_DEFAULT_NARRATOR = "af_heart"


def _slug(text: str) -> str:
    """Reduce arbitrary text to a stable, id-friendly slug (cf. story._slug)."""
    slug = re.sub(r"[^a-z0-9]+", "-", str(text).lower()).strip("-")
    return slug or "node"


def _clamp_voice(voice: object, default: str) -> str:
    """Keep a voice only if it is a known American id, else fall back."""
    if isinstance(voice, str) and voice in _AMERICAN_VOICES:
        return voice
    return default


def _extract_json(text: str) -> dict[str, Any]:
    """Parse the model's reply into a dict, tolerating fences and prose.

    ``ollama`` with ``format="json"`` returns clean JSON, but we stay robust:
    strip ``` fences, then fall back to the outermost ``{...}`` span.
    """
    text = text.strip()
    if text.startswith("```"):
        text = re.sub(r"^```[a-zA-Z0-9]*\n?", "", text)
        text = re.sub(r"\n?```$", "", text).strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        start, end = text.find("{"), text.rfind("}")
        if start != -1 and end > start:
            return json.loads(text[start : end + 1])
        raise


# -- assembly: spec dict -> Story (pure, deterministic) --------------------


def build_story(
    spec: dict[str, Any],
    *,
    premise: Optional[str] = None,
    warnings: Optional[list[str]] = None,
) -> Story:
    """Assemble a proposed story ``spec`` into a metaphor DAG.

    Deterministic and defensive: model-supplied ids are honoured where they can
    be (so cross-references resolve) but de-duplicated when they collide; edges
    that are unknown or would form a cycle are dropped into ``warnings`` instead
    of raising; voices are clamped to ones the audio backend can speak.

    Raises ``ValueError`` only when there is no structural spine to render
    (no acts, or no beats under any act).
    """
    warn = warnings if warnings is not None else []
    s = Story()

    title = str(spec.get("title") or "Untitled")
    root_meaning = premise or spec.get("premise") or title
    narrator = _clamp_voice(spec.get("narrator_voice"), _DEFAULT_NARRATOR)
    cast = {
        str(name).upper(): _clamp_voice(voice, narrator)
        for name, voice in (spec.get("cast") or {}).items()
    }

    root = s.three_act(
        str(root_meaning),
        id="three-act",
        title=title,
        credit="written by",
        author=str(spec.get("author") or "brehon"),
        source="generated from a metaphor DAG",
        narrator_voice=narrator,
        cast=cast,
    )

    # model id -> actual story id, so parents/also references resolve even
    # after a colliding id has been renamed.
    resolved: dict[str, str] = {"three-act": root.id, root.id: root.id}

    def register(model_id: object, actual: str) -> None:
        if isinstance(model_id, str) and model_id:
            resolved[model_id] = actual
        resolved[actual] = actual

    def unique_id(requested: object, seed: str) -> str:
        base = _slug(requested) if isinstance(requested, str) and requested else _slug(seed)
        if base not in s:
            return base
        n = 2
        while f"{base}-{n}" in s:
            n += 1
        return f"{base}-{n}"

    def safe_link(parent_id: object, child_id: str) -> bool:
        target = resolved.get(parent_id) if isinstance(parent_id, str) else None
        if target is None:
            warn.append(f"dropped edge to unknown parent {parent_id!r} -> {child_id}")
            return False
        try:
            s.link(target, child_id)
            return True
        except CycleError:
            warn.append(f"dropped cyclic edge {target} -> {child_id}")
            return False

    # themes (children of root) ------------------------------------------
    for theme in spec.get("themes") or []:
        meaning = str(theme.get("meaning") or "").strip()
        if not meaning:
            continue
        tid = unique_id(theme.get("id"), meaning)
        s.instantiate(root.id, meaning, kind="theme", id=tid)
        register(theme.get("id"), tid)

    # motifs (shared vehicles; create all, then wire every parent so that a
    # motif may name a theme *or* a later motif as a parent) --------------
    motif_specs = [m for m in (spec.get("motifs") or []) if str(m.get("meaning") or "").strip()]
    parked_under_root: set[str] = set()
    for motif in motif_specs:
        meaning = str(motif["meaning"]).strip()
        declared = motif.get("parents") or []
        parents = [resolved[p] for p in declared if p in resolved]
        first = parents[0] if parents else root.id
        mid = unique_id(motif.get("id"), meaning)
        s.instantiate(first, meaning, kind="motif", id=mid)
        register(motif.get("id"), mid)
        if declared and not parents:
            # Parked under root only because its first parent is a later motif not
            # created yet. The real edge is wired below, and this one retracted —
            # otherwise the motif keeps a stray root edge the spec never asked for.
            parked_under_root.add(mid)
    for motif in motif_specs:
        child = resolved.get(motif.get("id"))
        if child is None:
            continue
        wired = False
        for parent in motif.get("parents") or []:
            if safe_link(parent, child):
                wired = True
        if wired and child in parked_under_root:
            s.unlink(root.id, child)

    # acts (the structural spine) ----------------------------------------
    created_acts: list[tuple[str, dict[str, Any]]] = []
    for act in spec.get("acts") or []:
        meaning = str(act.get("meaning") or "").strip()
        aid = unique_id(act.get("id"), meaning or "act")
        s.instantiate(root.id, meaning, kind="act", id=aid)
        register(act.get("id"), aid)
        created_acts.append((aid, act))
    if not created_acts:
        raise ValueError("generated spec has no acts; cannot render a screenplay")

    # beats (page-level leaves; each may name extra theme/motif parents) --
    beat_count = 0
    for act_id, act in created_acts:
        for beat in act.get("beats") or []:
            meaning = str(beat.get("meaning") or "").strip()
            manifestation = str(beat.get("manifestation") or "").strip()
            attrs: dict[str, Any] = {}
            for key in ("slug", "character", "parenthetical", "dialogue"):
                value = beat.get(key)
                if isinstance(value, str) and value.strip():
                    attrs[key] = value.strip().upper() if key == "character" else value.strip()
            bid = unique_id(beat.get("id"), meaning or manifestation or "beat")
            s.instantiate(
                act_id, meaning, manifestation=manifestation,
                kind="beat", id=bid, attributes=attrs,
            )
            register(beat.get("id"), bid)
            beat_count += 1
            for parent in beat.get("also") or []:
                safe_link(parent, bid)

    if beat_count == 0:
        raise ValueError("generated spec has no beats; cannot render a screenplay")

    concreteness.annotate(s)  # score every page metaphor for concreteness
    return s


# -- the LLM seam ----------------------------------------------------------


class LLMClient(Protocol):
    """Proposes a story as JSON text. Implementations may be local or remote;
    only the text matters, and :func:`build_story` does the trusting."""

    def complete(self, prompt: str, *, system: Optional[str] = None) -> str: ...


class OllamaClient:
    """A local open-source model served by `ollama <https://ollama.com>`_.

    Zero extra dependencies — talks to the daemon's ``/api/generate`` endpoint
    over the standard library, asking for ``format="json"`` so the reply is
    constrained to a single JSON document. A fixed ``seed`` makes the proposal
    reproducible run to run.
    """

    def __init__(
        self,
        model: str = "qwen3-coder-next:latest",
        host: str = "http://localhost:11434",
        *,
        temperature: float = 0.7,
        seed: Optional[int] = 7,
        timeout: float = 600.0,
        json_mode: bool = True,
    ) -> None:
        # Restrict to HTTP(S): the host is handed to urllib.request.urlopen, which
        # would otherwise honor schemes like file:// and reach an unexpected handler.
        if urllib.parse.urlparse(host).scheme not in ("http", "https"):
            raise ValueError(f"OllamaClient.host must be an http(s) URL, got {host!r}")
        self.model = model
        self.host = host.rstrip("/")
        self.temperature = temperature
        self.seed = seed
        self.timeout = timeout
        self.json_mode = json_mode  # JSON for structured seed calls; off for prose

    def complete(self, prompt: str, *, system: Optional[str] = None) -> str:
        options: dict[str, Any] = {"temperature": self.temperature}
        if self.seed is not None:
            options["seed"] = self.seed
        body: dict[str, Any] = {
            "model": self.model,
            "prompt": prompt,
            "stream": False,
            "options": options,
        }
        if self.json_mode:
            body["format"] = "json"
        if system:
            body["system"] = system
        request = urllib.request.Request(
            f"{self.host}/api/generate",
            data=json.dumps(body).encode("utf-8"),
            headers={"Content-Type": "application/json"},
        )
        with urllib.request.urlopen(request, timeout=self.timeout) as response:
            payload = json.loads(response.read().decode("utf-8"))
        return payload.get("response", "")


_SYSTEM_PROMPT = """\
You are a screenwriter working in the "brehon" story model. A story is a
directed acyclic graph of METAPHORS — but NOT the decorative, English-class
kind. We mean metaphor as Julian Jaynes did: an abstract idea (the meaning) is
always carried by a concrete thing (what appears on the page). "The head of
government" is already a metaphor — "head" is a concrete body part standing in
for leadership. The metaphor is the deep structure; your only job is to make it
CONCRETE, never to decorate it.

The graph has four levels, abstract to concrete:
1. THREE-ACT root: one controlling premise the whole story concretizes.
2. ACTS: the structural spine. Exactly three, in narrative order.
3. THEMES + MOTIFS: abstract domains that recur (themes) and the concrete
   vehicles that carry them (motifs). A motif may serve several themes.
4. BEATS: the page-level leaves — the actual scenes/lines.

THE ONE RULE THAT MATTERS — CONCRETENESS:
A beat's "manifestation" (and any "dialogue") must be a BARE PHYSICAL FACT:
concrete nouns, plain verbs, something a camera could record. State the vehicle;
never the meaning. Gold standard: "Her skin is cold." "He sets the roller down
and leaves the floor the way it is." "He tapes the student ID to locker 12."

These are CRIMES — never commit them:
- Simile: no "like", no "as X as".  ("cracks bloom like veins in ice" — BANNED)
- Personification / purple verbs: glass does not "bleed", stone does not "sing",
  the sea does not "breathe", a hum does not "thrum". Use plain verbs.
- Abstract / poetic nouns naming the feeling: "refusal", "the soul", "oblivion".
- Saying the meaning out loud: "you are the bait", "he felt invisible". Show the
  fact; leave the meaning unspoken.
- Symbolic titles: name the story after a concrete thing, place, or time (like
  "The Night Shift"), NEVER an abstract symbol ("The Beacon's Lie" — BANNED).
The "meaning" field MAY be abstract — it is the metaphrand. Only "manifestation"
and "dialogue" must be concrete. Aim for ZERO ornament.

Structure: 3 acts, 4-6 themes, 4-7 motifs, 4-6 beats per act. Most beats list
one or more theme/motif ids in "also", so a beat serves both its act (structure)
and a theme (meaning) — a real DAG. At least one beat carries dialogue (set
"character" + "dialogue", and put the character in "cast" with a voice). One
late beat may list the literal id "three-act" in "also" — the hinge. "slug" is a
plain scene heading like "INT. KITCHEN - NIGHT".

Voices come from this set only:
female af_heart af_bella af_nicole af_sarah af_sky;
male am_adam am_michael am_onyx am_eric am_liam am_fenrir.
Every id is a short lowercase slug, unique across the whole document.

Return ONE JSON object and nothing else, matching the contract you are given.\
"""

_EXEMPLAR = {
    "title": "The Night Shift",
    "premise": "An institution stays clean only because someone is paid to carry away what it refuses to admit",
    "author": "brehon",
    "narrator_voice": "af_heart",
    "cast": {"SUPERVISOR": "am_adam"},
    "themes": [
        {"id": "dirt", "meaning": "What will not come out"},
        {"id": "unseen", "meaning": "Looked through; the keys of the invisible"},
        {"id": "buried", "meaning": "What is sealed away and discarded"},
    ],
    "motifs": [
        {"id": "stain", "meaning": "The dark that comes back through the paint", "parents": ["dirt", "buried"]},
        {"id": "keys", "meaning": "The keys of the invisible man", "parents": ["unseen"]},
    ],
    "acts": [
        {"id": "act1", "meaning": "Keeper of surfaces: the building is his, and no one sees him", "beats": [
            {"id": "b-door", "meaning": "He is looked through", "also": ["unseen"],
             "manifestation": "He holds the door. Forty-one go through. The forty-second thanks the door."},
        ]},
        {"id": "act2", "meaning": "The buried: his cleanliness was a cover", "beats": [
            {"id": "b-stain", "meaning": "The thing he is paid to erase", "also": ["stain"],
             "manifestation": "He has painted the floor three times. Each morning the dark comes back up through the grey.",
             "slug": "INT. SEALED LAB - NIGHT"},
            {"id": "b-raise", "meaning": "The institution begins to clean him", "also": ["dirt"],
             "manifestation": "His supervisor sets a hand on his shoulder, mentions a raise.",
             "character": "SUPERVISOR", "parenthetical": "easy, friendly",
             "dialogue": "Don't you worry about B-wing, Walt. We've got that one covered now."},
        ]},
        {"id": "act3", "meaning": "The mirror: he was the mechanism, and he stops cleaning", "beats": [
            {"id": "b-choice", "meaning": "Carry it away once more, or set it down", "also": ["three-act", "stain"],
             "manifestation": "He stands over the dark shape with the roller loaded. For a long time he does not move.",
             "slug": "INT. SEALED LAB - NIGHT"},
        ]},
    ],
}


def _build_prompt(premise: str) -> str:
    exemplar = json.dumps(_EXEMPLAR, indent=2, ensure_ascii=False)
    return (
        "Here is a complete (abbreviated) example in the exact JSON contract:\n\n"
        f"{exemplar}\n\n"
        "Now write a NEW story — your own title, themes, motifs, acts, and beats "
        "— for this premise:\n\n"
        f"    {premise}\n\n"
        "Return one JSON object in the same shape. Make the three acts a real arc, "
        "give every beat a bare, concrete manifestation — a physical fact a "
        "camera could record, with zero ornament (no simile, no purple verbs, "
        "no abstract nouns, no symbolic title) — and wire every beat to at "
        "least one theme or motif via \"also\"."
    )


class DagGenerator:
    """Premise in, metaphor DAG out. Wraps an :class:`LLMClient`."""

    def __init__(self, client: Optional[LLMClient] = None) -> None:
        self.client = client or OllamaClient()
        self.warnings: list[str] = []
        self.report: Optional[concreteness.ConcretenessReport] = None

    def generate(self, premise: str, *, concretize: bool = True) -> Story:
        reply = self.client.complete(_build_prompt(premise), system=_SYSTEM_PROMPT)
        spec = _extract_json(reply)
        self.warnings = []
        story = build_story(spec, premise=premise, warnings=self.warnings)
        if concretize:
            self.report = concreteness.concretize(
                story, self.client, warnings=self.warnings
            )
        else:
            self.report = concreteness.annotate(story)
        return story


def generate_story(
    premise: str, *, client: Optional[LLMClient] = None, concretize: bool = True
) -> Story:
    """Convenience: generate a :class:`~brehon.story.Story` from a premise.

    With ``concretize`` (default), ornamental beats are rewritten toward bare
    physical fact before returning. Warnings from defensive assembly (dropped
    edges, clamped voices, un-concretizable lines) and the final flowery
    fraction are printed to stderr; the returned graph is always renderable.
    """
    generator = DagGenerator(client=client)
    story = generator.generate(premise, concretize=concretize)
    for message in generator.warnings:
        print(f"[generate] {message}", file=sys.stderr)
    if generator.report is not None:
        print(f"[generate] {generator.report.summary()}", file=sys.stderr)
    return story


# -- the spine generator: premise -> mirror-rooted, doorway-marked DAG ------

def _unique_id(story: Story, requested: object, seed: str) -> str:
    base = _slug(requested) if isinstance(requested, str) and requested else _slug(seed)
    if base not in story:
        return base
    n = 2
    while f"{base}-{n}" in story:
        n += 1
    return f"{base}-{n}"


def build_spine(
    spec: dict[str, Any],
    *,
    premise: Optional[str] = None,
    warnings: Optional[list[str]] = None,
) -> Story:
    """Assemble a mirror-rooted, doorway-marked spine from a proposed spec.

    Deterministic and defensive: the LLM proposes the transformation, the mirror
    scene, and the two branches of beats; this seats them through the ``Story``
    API and scores their concreteness. Raises only if there is nothing to render.
    """
    warn = warnings if warnings is not None else []
    s = Story()
    title = str(spec.get("title") or "Untitled")
    transformation = premise or spec.get("transformation") or spec.get("premise") or title
    narrator = _clamp_voice(spec.get("narrator_voice"), _DEFAULT_NARRATOR)
    cast = {
        str(name).upper(): _clamp_voice(voice, narrator)
        for name, voice in (spec.get("cast") or {}).items()
    }

    attrs: dict[str, Any] = {
        "title": title, "credit": "written by",
        "author": str(spec.get("author") or "brehon"),
        "source": "generated from a metaphor DAG",
        "narrator_voice": narrator, "cast": cast,
    }
    if spec.get("slug"):
        attrs["slug"] = str(spec["slug"])

    def _label(*keys: str, default: str) -> str:
        for key in keys:
            value = spec.get(key)
            if isinstance(value, str) and value.strip():
                return value
        return default

    def _beats(*keys: str) -> list:
        for key in keys:  # models often nest the beats under the state key itself
            value = spec.get(key)
            if isinstance(value, list):
                return value
        return []

    root, previous, following = s.mirror(
        str(transformation),
        manifestation=str(spec.get("mirror") or ""),
        previous=_label("previous_label", "previous_state", default="the previous self"),
        next=_label("next_label", "next_state", default="the next self"),
        **attrs,
    )

    def _seat(branch_id: str, beats: Any) -> int:
        count = 0
        for beat in beats or []:
            meaning = str(beat.get("meaning") or "").strip()
            manifestation = str(beat.get("manifestation") or "").strip()
            battrs: dict[str, Any] = {}
            for key in ("slug", "character", "parenthetical", "dialogue"):
                value = beat.get(key)
                if isinstance(value, str) and value.strip():
                    battrs[key] = value.strip().upper() if key == "character" else value.strip()
            if beat.get("doorway"):
                try:
                    battrs["doorway"] = int(beat["doorway"])
                except (TypeError, ValueError):
                    warn.append(f"bad doorway value {beat.get('doorway')!r}")
            bid = _unique_id(s, beat.get("id"), meaning or manifestation or "beat")
            s.instantiate(branch_id, meaning, manifestation=manifestation,
                          kind="beat", id=bid, attributes=battrs)
            count += 1
        return count

    seated = (
        _seat(previous.id, _beats("previous_beats", "previous", "previous_state"))
        + _seat(following.id, _beats("next_beats", "next", "next_state"))
    )
    if seated == 0:
        raise ValueError("generated spine has no beats; cannot render")

    concreteness.annotate(s)
    return s


_SPINE_SYSTEM = """\
You write the SPINE of a story in the brehon model. The root is the MIRROR
moment — the transformation itself, the scene where both worlds are held at once.
It has two branches: the PREVIOUS state (the self the hero leaves) and the NEXT
state (the self he becomes). Read previous -> mirror -> next, it is a screenplay.

Requirements:
- "transformation": the controlling change (the root's meaning).
- "mirror": one concrete scene that holds both worlds at once.
- Each beat is a bare PHYSICAL FACT (a thing a camera records) that CARRIES its
  meaning — never flowery, never telling, never naming the meaning out loud.
  Plain common names, no invented-literary words.
- Mark exactly one previous beat with "doorway": 1 (the irreversible lock-out
  that ends Act 1) and one next beat with "doorway": 2 (what forces him into the
  test).
- Give two or three beats dialogue, spoken by DIFFERENT characters so the
  recording has several voices; put each speaker in "cast" with a distinct voice
  (female af_heart af_bella af_sarah af_nicole; male am_michael am_adam am_fenrir
  am_onyx). Set "narrator_voice".

Return ONE JSON object:
{"title","transformation","mirror","previous_state","next_state","narrator_voice",
 "cast":{CHARACTER:voice},
 "previous_beats":[{"id","meaning","manifestation","slug?","character?","dialogue?","doorway?"}],
 "next_beats":[...]}.\
"""


def generate_spine(
    premise: str, client: "LLMClient", *, warnings: Optional[list[str]] = None
) -> Story:
    """Premise in, a mirror-rooted, doorway-marked metaphor DAG out."""
    reply = client.complete(
        f"Transformation signal: {premise}\n\nWrite the spine. Return the JSON object.",
        system=_SPINE_SYSTEM,
    )
    return build_spine(_extract_json(reply), premise=premise, warnings=warnings)
