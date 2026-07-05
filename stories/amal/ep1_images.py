"""अमल Ep1 — one photoreal image per scene, for the video backplates. Wide and atmospheric (the belt,
the mood, the figures); original anonymous faces (commercial-clearable)."""
import os, sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import frames

OUT = "/Users/dusty/dev/brehon-law/stories/amal/ep1_images"; os.makedirs(OUT, exist_ok=True)
TAIL = (" Set in the Malwa opium belt of Madhya Pradesh, India; gritty realist, natural light, the look "
        "of 35mm film, muted earth tones. Wide, atmospheric. All faces ORIGINAL and anonymous, not "
        "resembling any real or famous person.")

SCENES = [
 ("01_field", "A poppy field at first light, cold mist, rows of scored poppy pods weeping grey opium gum. A teenage girl's body lies on its side at the earthen bund, one slipper off in the furrow; a line of labourers scrape the rows nearby without looking over; a heavyset CBN inspector in khaki stands at a distance."),
 ("02_room", "A small dim village room, thin light through one barred window, a steel almirah and a string cot. A middle-aged woman in a faded sari sits on the floor folding a dead girl's clothes into her lap, grieving."),
 ("03_office", "A yellowed government office, steel file almirahs, a slow ceiling fan, a framed Gandhi. A heavyset inspector stands before a superintendent seated at a paper-strewn desk; a young constable waits at the door."),
 ("04_field_dusk", "A poppy field at dusk, the harvest stopped, grey gum drying on the pods. An inspector and a young constable with a torch walk the earthen bund; a well at the field's edge, a single lit house far off."),
 ("05_devahome", "A modest farming household at evening, a kitchen open to a courtyard, a hand-pump, woodsmoke. An older woman kneads dough, a father sits on a charpai, a young woman serves food, a young man in police uniform stands in the doorway."),
 ("06_sunita_night", "A village house at night, the family asleep, one low bulb in a corner. A young woman sits up alone on her bedding with a school notebook open in her lap, not writing, listening toward the next room."),
 ("07_mandi", "A government opium weighment shed, a measurement officer seated at a brass scale weighing a lump of dark latex and writing in a register; a line of anxious farmers wait with steel pots of gum."),
 ("08_teastall", "A roadside tea stall in a small-town bazaar by day, a kettle steaming, men on a wooden bench with glasses of tea, talking low, the market behind."),
 ("09_postmortem", "A grim government hospital postmortem room, white tiles, a drain, a steel table with a small sheeted body. An overworked doctor fills a form standing; two policemen at the door."),
 ("10_routine", "A licensed poppy field by day, a prosperous grower walking the rows with a CBN inspector, a discreet folded wad of currency passing hand to hand at the end of a row."),
 ("11_wound", "A country dirt road at dusk, a jeep pulled over, a heavyset inspector standing alone at the edge of an empty well-worked field, looking across it."),
 ("12_alliance", "A village house courtyard after a death, the mourners thinned. A prosperous unhurried older man sits where mourners sat with a hard-faced forty-year-old man behind him; the dead girl's father stands before them with folded hands."),
 ("13_womenshouse", "A dim inner room of a village house, an older woman folding a dead girl's clothes into a cloth bundle to give away; a small girl watches from against the wall; the numb mother sits on the floor, hands in her lap."),
 ("14_pressure", "A government office, a superintendent standing with a telephone receiver to his ear, his face grave; an inspector waits in the doorway."),
 ("15_school", "A narrow lane behind a government school, a brick wall, a frightened teenage girl in a school uniform with a cloth bag walking fast; a heavyset inspector beside her, the lane empty."),
 ("16_jeep", "A CBN jeep on a dark country road at night, headlights cutting the dark, black fields on both sides, two men inside."),
 ("17_witness", "An old night-watchman sitting on a charpai outside a mud hut, a wooden stick across his knees, wary; a young constable and a heavyset inspector standing over him in daylight."),
 ("18_deva_morning", "A village house at morning, a family at tea on the floor, an older father dressed to go out, a young woman holding a kettle with her eyes down, a young man not rising, tension in the room."),
 ("19_envelope", "A modest house interior at night, a man in a pressed shirt standing just inside the door setting a thick envelope on the edge of a table; a weary inspector seated at the table; a woman clearing a pot in the back."),
 ("20_close", "A dark village courtyard at night, empty after mourning. A grieving mother sits alone against the wall with her dead daughter's folded clothes in her lap, utterly still."),
]

for name, prompt in SCENES:
    out = f"{OUT}/{name}.png"
    if os.path.exists(out):
        print("skip", name, flush=True); continue
    try:
        frames.shot(prompt + TAIL, out, register="photoreal", pro=True)
    except Exception as e:
        print("FAIL", name, str(e)[:120], flush=True)
print("IMAGES DONE", flush=True)
