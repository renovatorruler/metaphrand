"""Upload अमल Ep1 to YouTube (unlisted) and set the thumbnail. Keeps the multi-line
Hindi/English title+description out of the shell."""
import sys, os
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from examples import youtube_upload as yt

D = "/Users/dusty/dev/brehon-law/stories/amal"
VIDEO = f"{D}/ep1_nosub.mp4"          # the cut; English subs go on as a selectable CC track
THUMB = f"{D}/ep1_images/01_field.png"

TITLE = "AMAL (अमल) · Episode 1 — तौल / The Weighing"

DESC = """A licensee's sixteen-year-old daughter is found dead at dawn in the family's poppy field — \
on licensed opium land in the Malwa belt of Madhya Pradesh. Everyone wants it signed off as a fall. \
Inspector Ratan Singh Panwar — two years from his pension, and no clean man himself — sends the body \
for a postmortem instead, and the keyhole opens.

Episode 1 of an original series. Hindi dialogue with English subtitles; English narration.
Register: rural noir in the key of Paatal Lok / Aranyak — not a glossy procedural.

An original, AI-assisted production. Voices: ElevenLabs. Images: Gemini. Unlisted preview cut."""

if __name__ == "__main__":
    assert os.path.exists(VIDEO), f"missing {VIDEO}"
    yt.upload(VIDEO, TITLE, DESC)
    # thumbnail is best-effort (needs a verified channel); ignore failure
    try:
        # the upload() above printed the URL/ID; re-set thumbnail via a fresh listing is overkill,
        # so we let the user set it, or pass an id arg:
        if len(sys.argv) > 1:
            yt.thumbnail(sys.argv[1], THUMB)
    except Exception as e:
        print("thumb skipped:", e)
