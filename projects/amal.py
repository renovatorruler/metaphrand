"""projects.amal — DATA for अमल Ep1 (live-action stills via the cinema pipeline).

Visual pipeline: cast turnaround sheets (consistent faces), then one frame per scene conditioned on them.
The multi-voice audio is handled separately (stories/amal/amal_audio_hi.py — the Hindi table read).

    python -m projects.amal cast    # portraits + turnarounds under stories/amal/sheets/
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from cinema.project import Project  # noqa: E402

# Original faces — Malwa (Mandsaur–Neemuch belt) bones; the actor-likeness guard is in cinema.characters.
CAST_LOOKS = {
    "ratan": ("An Indian man of about fifty-eight, a fallen Rajput police inspector worn down by "
              "twenty-five years of surrender. Heavy-set and tired, a soft belly, a deeply lined "
              "weather-beaten brown face, a thick untrimmed grey moustache, heavy-lidded weary eyes that "
              "once missed nothing, short greying hair, a faded soft-khaki CBN uniform gone shapeless at "
              "the seams. A characterful ORIGINAL face with rural Malwa bones — NOT any known actor."),
    "deva": ("A young Indian man of twenty-four, an earnest idealistic police constable fresh from the "
             "city. Lean, light stubble, alert hopeful dark eyes, neat short black hair, a crisp new "
             "khaki constable's uniform still creased from the shop. An ORIGINAL ordinary-handsome face, "
             "not any known actor."),
    "sugna": ("An Indian woman of about fifty-five, hard and grief-worn — Ratan's estranged sister. A "
              "weathered face closed like a fist, greying hair pulled back tight, fierce dry dark eyes, a "
              "plain worn off-white cotton sari. An ORIGINAL face, a hard rural woman, not any actress."),
    "kanta": ("An Indian woman of about sixty, tired and resigned, an inspector's wife. A soft lined "
              "face, greying hair in a loose bun, a plain household cotton sari. An ORIGINAL face."),
    "mishra": ("An Indian man in his fifties, a neat compromised police superintendent. Combed hair, "
               "clean-shaven, a pressed uniform, careful unbothered eyes — a man who made his peace years "
               "ago. An ORIGINAL face."),
    "bherulal": ("A powerful Indian opium-grower patriarch of about fifty-five — the empire of the belt, "
                 "Sugna's husband. Heavy and prosperous, a hard shrewd jowled face, gold on the hand, a "
                 "good kurta, the stillness of a man used to being obeyed; grief over his dead daughter "
                 "buried deep under the power. An ORIGINAL face, not any known actor."),
    "leela": ("A sharp-eyed Indian village girl of sixteen, quick and spirited and alive. Straight dark "
              "hair in a braid, a printed cotton kameez, clear defiant eyes. An ORIGINAL face."),
    "dhanraj": ("A moneyed, sleazy Indian man in his sixties — soft and heavy, gold rings on three "
                "fingers, oiled thinning hair, small cold eyes, a fine cream kurta. An ORIGINAL face, "
                "bland and repellent, not any actor."),
    "charan": ("A very old Indian bard of about eighty, a Charan keeper of the family's names. One eye "
               "gone milky-blind, a deep-lined leathery dark face, a thin white beard, a faded turban, a "
               "frail frame. An ORIGINAL face."),
    "rana": ("A heavy Indian politician in his fifties, risen from the Chambal ravines on others' ruin. "
             "A broad smiling face, a crisp white kurta, gold, the ease of a man who owns the room. An "
             "ORIGINAL face."),
    "amma": ("A warm Indian mother in her fifties, plump and bright, a household sari, kind busy eyes. "
             "An ORIGINAL face."),
    "manju": ("An Indian girl of eighteen, Deva's sister, quiet and pretty with downcast eyes, a simple "
              "salwar-kameez. An ORIGINAL face."),
    "govind": ("An Indian man of about fifty-eight, Ratan's oldest friend and conscience — warm, plain, "
               "alive in the eyes where Ratan is dead. A lined kind face, grey stubble, a clean ordinary "
               "shirt, a man who kept his soul. An ORIGINAL face, not any known actor."),
    "bhanwar": ("Dr. Bhanwar Singh — an Indian government doctor of about fifty-five, a finished Rajput, "
                "Ratan's cold mirror. Clean-shaven, tired clinical eyes, a pressed shirt, a man at peace "
                "with the rot. An ORIGINAL face, not any known actor."),
}

PROJECT = Project(slug="amal", title="अमल — Ep1: तौल", register="live-action",
                  cast=CAST_LOOKS, voices={}, roles={}, scenes=[],
                  enforce_preflight=True)   # in production: build_* blocks until charts + voice cards exist


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "cast"
    if cmd == "cast":
        PROJECT.build_cast()
