import sys
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from examples import score

# M83-style epic dreamy swell (NOT M83 itself; describe the sound, name no artist).
PROMPT = ("Epic, dreamy, euphoric-yet-melancholic cinematic instrumental in the spirit of big "
          "emotional 1980s-influenced synth-pop and post-rock: huge reverberant analog synthesizer "
          "pads, shimmering arpeggios, a soaring nostalgic lead-synth melody, a slow emotional build "
          "into an anthemic wall-of-sound climax and a gentle comedown. Warm, bittersweet, gorgeous, "
          "widescreen and cinematic. No vocals. Lots of reverb and air. Instrumental only.")

OUT = "/Users/dusty/dev/brehon-law/stories/sky-king/music_m83.mp3"
score._music_elevenlabs(PROMPT, 145000, OUT)   # ~145s, through-composed, ElevenLabs Music
print("music ->", OUT, flush=True)
import subprocess
subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                "-of", "default=nw=1:nk=1", OUT])
