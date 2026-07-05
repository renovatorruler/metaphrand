"""projects.free_ross — DATA for the Free Ross episode "The Porch Light".

Pure project data: the cinema engine produces it. A new episode = edit the cast looks,
the voices, and the scenes here; the engine code never changes.

    python -m projects.free_ross cast     # build cast portraits + turnarounds
    python -m projects.free_ross audio    # build the multi-voice episode audio
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from cinema.project import Project              # noqa: E402
from examples.free_ross_audio import CAST as VOICES, EPISODE  # noqa: E402  (scene + voice data)

# Locked visual looks (the corrections: Ross handsome + original, Ruth blonde lead).
CAST_LOOKS = {
    "ross": ("A ruggedly handsome, magnetic leading man in his early fifties — an ex-NYPD detective. "
             "Thick dark-brown hair graying only at the temples, strong dark eyebrows, deep-set "
             "blue-gray eyes, a clean strong jaw with light stubble, a small old scar through the "
             "left eyebrow, a fit lean athletic build, a well-cut charcoal jacket over a dark henley."),
    "cole": ("A contained, proud Texan man in his early fifties, a grieving father: neat short graying "
             "hair, clean-shaven, a pressed plaid shirt buttoned high, a tight controlled jaw, grief "
             "pushed down behind careful eyes."),
    "sadie": ("A sixteen-year-old Texan girl seated in a wheelchair, guarded and sharp: straight "
              "shoulder-length brown hair, a plain hoodie, level eyes that have decided not to need "
              "anyone, quietly defiant."),
    "enya": ("A composed professional woman in her early thirties, crisp and controlled, a true "
             "believer in rules: dark hair pulled back tight, a sharp charcoal blazer, an even "
             "unreadable expression."),
    "ruth": ("An attractive blonde woman in her late thirties, warm and quick — a romantic lead and a "
             "sharp legal mind: shoulder-length wavy blonde hair, fair skin, bright hazel eyes, a "
             "subtle knowing half-smile, an elegant cream blazer."),
    "tomas": ("A careful, weathered Tejano man in his sixties, a lifelong contractor in Dallas: short "
              "gray hair, deep work-lines, big calloused hands, a worn canvas work shirt, watchful "
              "patient eyes."),
}
ROLE_TO_CAST = {"ROSS": "ross", "COLE": "cole", "SADIE": "sadie",
                "ENYA": "enya", "RUTH": "ruth", "TOMAS": "tomas"}

PROJECT = Project(slug="free-ross", title="Free Ross — The Porch Light", register="live-action",
                  cast=CAST_LOOKS, voices=VOICES, roles=ROLE_TO_CAST, scenes=EPISODE)


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "audio"
    if cmd == "cast":
        PROJECT.build_cast()
    elif cmd == "audio":
        PROJECT.build_audio()
