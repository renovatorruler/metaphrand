import os, sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from cinema.project import Project

# Look reference (faces are locked via stories/sky-king/build_cast.py; Birdy = the
# approved test frame). Kept here for record.
CAST_LOOKS = {
    "birdy": ("A gentle ordinary everyman of about 30, soft-featured, short mussed brown "
              "hair, warm tired hazel eyes, faint stubble, a shy quiet melancholy face. "
              "An unremarkable working-class man you would not look at twice."),
    "maya": ("A warm, tired woman in her late 20s, wavy brown hair, kind worried hazel "
             "eyes, fair skin, little makeup, a soft real face. An original individual."),
    "dez": ("A big, broad-shouldered working man in his mid-30s, close-cropped dark hair "
            "and a short beard, an open friendly face. An original individual."),
}

# role -> (voice_name, ElevenLabs voice_id)
VOICES = {
    "BIRDY":  ("Will",    "bIHbv24MWmeRgasZH58o"),   # warm, relaxed, young everyman
    "MAYA":   ("Suzanne", "b0XAJReHClzJsXv2FxoO"),   # young, emotive, captivating
    "DEZ":    ("Chris",   "iP95p4xoKVk53GoZ742B"),   # charming, down-to-earth
    "BISHOP": ("Bill",    "pqHfZKP75CvOlQylNhV4"),   # wise, mature, steady (radio)
}

ROLES = {"BIRDY": "birdy", "MAYA": "maya", "DEZ": "dez"}  # BISHOP is V.O. only

SCENES = [
    ("s1", [
        ("BISHOP", "How you doing up there."),
        ("BIRDY",  "Doing okay. It's real pretty up here."),
        ("BISHOP", "You're gonna want to start bringing her down soon. While you've still got the light."),
        ("BIRDY",  "Yeah. Couple more minutes."),
        ("BIRDY",  "You seeing this? The mountain."),
        ("BISHOP", "I'm on the ground, partner. I'll take your word for it."),
        ("BIRDY",  "Man. I didn't think it'd look like this."),
        ("BISHOP", "You still with me?"),
        ("BIRDY",  "Still here."),
        ("BIRDY",  "Hey. Thanks for staying up with me. Sorry to keep you so late."),
        ("BISHOP", "That's what I'm here for."),
        ("BIRDY",  "Okay."),
    ]),
    ("s2", [
        ("DEZ",   "You know what Marquez got. The new guy. Six months."),
        ("BIRDY", "I don't, no."),
        ("DEZ",   "Guess."),
        ("BIRDY", "Dez."),
        ("DEZ",   "More than you. Six months in and more than you."),
        ("BIRDY", "Good for him."),
        ("DEZ",   "That's not. No. That's not good for him. That's them robbing you and you saying thank you."),
        ("BIRDY", "He asked. I bet he asked."),
        ("DEZ",   "So go ask."),
        ("BIRDY", "Now?"),
        ("DEZ",   "Klein's still up there. Light's on. Right now, before he leaves. I did the math last night, Birdy. What they pay you an hour, for this. It's a joke. It's an actual joke."),
        ("BIRDY", "It's enough."),
        ("DEZ",   "It's not the point if it's enough."),
        ("BIRDY", "I'll talk to him. Next week. When he's not running out the door."),
        ("DEZ",   "That's what you told me last month."),
        ("BIRDY", "He's a busy guy."),
        ("DEZ",   "You'd take less. Just to not make him look at you."),
        ("BIRDY", "I'll take what he offers."),
        ("DEZ",   "You're soaked, man. Come on."),
    ]),
    ("s3", [
        ("MAYA",  "Wash up. It's ready."),
        ("MAYA",  "Donna asked about you today. At the register. I told her you were gonna fix her gate. You said that."),
        ("BIRDY", "I'll get to it."),
        ("MAYA",  "Remember when we drove up to Index? You climbed that thing in your church shoes."),
        ("MAYA",  "Anyway."),
        ("MAYA",  "Hey. How are you. Really. Just one. The real one."),
        ("BIRDY", "I'm fine."),
        ("MAYA",  "Okay."),
        ("MAYA",  "I'm going up."),
        ("BIRDY", "I'll be up."),
    ]),
    ("s4", [
        ("BIRDY", "Lost track of time."),
        ("MAYA",  "I saw you."),
        ("BIRDY", "I'll be up in a minute."),
        ("MAYA",  "Don't be long."),
    ]),
]

PROJECT = Project(
    slug="sky-king",
    title="Sky King",
    register="live-action",
    cast=CAST_LOOKS,
    voices=VOICES,
    roles=ROLES,
    scenes=SCENES,
)

if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "audio"
    if cmd == "cast":
        PROJECT.build_cast()
    elif cmd == "audio":
        PROJECT.build_audio()
