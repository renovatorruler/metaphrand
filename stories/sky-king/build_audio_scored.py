import os, sys, subprocess
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from examples import score

BASE = "/Users/dusty/dev/brehon-law/stories/sky-king"
DIALOG = f"{BASE}/performance/sky-king.mp3"
BED = f"{BASE}/music_bed.mp3"
PADDED = f"{BASE}/dialog_padded.mp3"
SCORED = f"{BASE}/scored.mp3"

# 1. Dreamy gold-melancholy bed (~30s; mix_under loops it). No artist names.
PROMPT = ("dreamy ambient post-rock film score, warm gold melancholy, slow swelling synth "
          "pads and a distant clean reverbed electric guitar, hopeful and sad at once, "
          "cinematic, very slow, lots of air and space, no drums, no beat, no vocals, "
          "an instrumental underscore that sits quietly under dialogue")
if not os.path.exists(BED):
    score._music(PROMPT, 30000, BED)
    print("bed ->", BED, flush=True)

# 2. Pad the dialogue: 6s of music to open on the gold sky, ~14s to close.
subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y", "-i", DIALOG,
                "-af", "adelay=6000:all=1,apad=pad_dur=14",
                "-c:a", "libmp3lame", "-b:a", "160k", PADDED], check=True)
print("padded ->", PADDED, flush=True)

# 3. Duck the bed under the padded dialogue.
score.mix_under(PADDED, BED, SCORED, gain=0.22)
print("SCORED ->", SCORED, flush=True)
print("duration:")
subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                "-of", "default=nw=1:nk=1", SCORED])
