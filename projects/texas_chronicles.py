"""projects.texas_chronicles — DATA for the Texas Chronicles shorts.

Live-action register. Audio is single-voice (rendered via cinema.backends.elevenlabs_tts,
handled per-short), so the project's multi-voice fields stay empty; this file drives the
VISUAL pipeline — cast turnaround sheets, then frames conditioned on them.

    python -m projects.texas_chronicles cast   # portraits + turnarounds under stories/texas-chronicles/sheets/
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from cinema.project import Project  # noqa: E402

# Original-face designs (the actor-likeness guard is in cinema.characters; for the high-risk
# faces the negatives are stated inline too).
CAST_LOOKS = {
    "miles": ("A Union man of thirty-three, a big-city outsider who has recently lost everything and "
              "knows it. Lean, a little gaunt, restless. Short dark-brown hair, slightly overgrown and "
              "uncombed; pale skin not used to the Texas sun; light stubble; anxious hazel eyes with "
              "shadows under them. A once-good charcoal overcoat, now rumpled and travel-creased, over "
              "a wrinkled button-down. An ORIGINAL, ordinary-handsome face — not any known actor."),
    "shelby": ("A Dallas-born woman of twenty-nine, practical and unimpressed, an insurance agency's "
               "fixer. Sun-warmed skin, dark-blonde hair pulled back loosely, level grey-green eyes, no "
               "makeup, a faint permanent squint from the light. Worn jeans, scuffed boots, a faded "
               "snap-button work shirt rolled at the sleeves. Capable and lived-in. An ORIGINAL face, "
               "not a model and not any known actress."),
    "august": ("A Texan man in his sixties, the master of his trade, with a stillness that quiets a "
               "room. Tall, heavy-framed, deliberate. Iron-grey hair combed back, a deeply lined "
               "weather-beaten face, hooded pale-blue eyes that miss nothing, clean-shaven. A good dark "
               "vest over shirtsleeves, a pocket-watch chain. An ORIGINAL, unfamiliar face — explicitly "
               "NOT Tommy Lee Jones, NOT Sam Elliott, NOT Jeff Bridges; a characterful old Texan nobody "
               "can name."),
}

PROJECT = Project(slug="texas-chronicles", title="Texas Chronicles — No Service",
                  register="live-action", cast=CAST_LOOKS, voices={}, roles={}, scenes=[])


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "cast"
    if cmd == "cast":
        PROJECT.build_cast()
