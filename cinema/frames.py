"""cinema.frames — story-agnostic shot generation.

A shot conditions on the character TURNAROUND sheets (faces/wardrobe) and a LOCATION
master (geography), in either register. Generic: refs + prompt + register, nothing
story-specific. Faces hold because every shot rides the same turnaround; the world
holds because every shot rides the same location master (or the same Blender clay).
"""
from __future__ import annotations

from . import backends as bk

PHOTOREAL = ("A photorealistic cinematic film still, naturalistic light, shallow depth of field, "
             "fine grain, the look of 35mm film. ")
STORYBOARD = ("Film storyboard illustration: loose confident graphite pencil and charcoal on "
              "off-white paper, monochrome, cinematic widescreen, expressive, NO text anywhere. ")
_CONDITION = (" Use the attached reference images as canon: the character turnaround sheets fix each "
              "person's face, hair and wardrobe — reproduce them EXACTLY; any attached location frame "
              "or gray 3D clay fixes the geography and camera — match it precisely. Keep everything "
              "consistent. No drawing, no border." )

# Commercial-use face lock. Tight shots invent the most face pixels and drift to the nearest
# famous actor the model knows ("ruggedly handsome detective" -> Jake Gyllenhaal). This makes the
# original-likeness demand non-negotiable; pair it with cascade conditioning (pass an already-good
# wider frame of the SAME character as the first ref) and the verify gate below.
_FACE_LOCK = (" CRITICAL — COMMERCIAL LIKENESS: this person must be an ORIGINAL individual who matches "
              "the attached turnaround and wider frame EXACTLY — same age, same face shape, same "
              "hairline, same build. He must NOT resemble any real, famous or recognizable actor or "
              "public figure. If the rendered face reads as a known actor, it is WRONG and unusable. "
              "An original, clearable likeness is required.")


def _head(register: str) -> str:
    return PHOTOREAL if register == "photoreal" else STORYBOARD


def location_master(description: str, out: str, register: str = "photoreal", pro: bool = True) -> str:
    """One consistent establishing plate per location; every shot there conditions on it."""
    prompt = _head(register) + description + " Establishing wide of the empty location, no people."
    bk.save_png(out, bk.image(prompt, refs=None, pro=pro))
    print("location ->", out, flush=True)
    return out


def shot(prompt: str, out: str, refs: list[str] | None = None, register: str = "photoreal",
         pro: bool = True, face_lock: bool = False, avoid: tuple[str, ...] = ()) -> str:
    """One shot. refs = [an already-good wider frame of the hero (cascade), location/clay,
    character turnaround sheets]. Set face_lock=True on any shot featuring a lead's face;
    pass avoid=("Actor Name",) to negative-prompt a known drift target."""
    full = _head(register) + prompt + (_CONDITION if refs else "")
    if face_lock:
        full += _FACE_LOCK
        if avoid:
            full += " Specifically do NOT resemble: " + ", ".join(avoid) + "."
    bk.save_png(out, bk.image(full, refs=refs, pro=pro))
    print("shot ->", out, flush=True)
    return out
