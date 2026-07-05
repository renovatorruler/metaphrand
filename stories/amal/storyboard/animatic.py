"""अमल — train animatic with narrated stage directions (previz scratch-VO).

Audio = a calm narrator reading the condensed stage directions per frame + the two Hindi lines on the
'settled' beat + a synthesized train bed. Each frame holds for the length of its narration, so picture
and voice stay synced. ElevenLabs TTS (key allows TTS; sound-generation/voices are scope-blocked, so
the bed is synthesized).
"""
import os, sys, subprocess
sys.path.insert(0, "/Users/dusty/dev/brehon-law")
from cinema import backends as bk, assemble as asm

D = "/Users/dusty/dev/brehon-law/stories/amal/storyboard"
A = f"{D}/audio"; os.makedirs(A, exist_ok=True)

NARR = "JBFqnCBsd6RMkjVDRZzb"   # George — calm narrator
VP   = "XrExE9yKIg1WjnnlVkGX"   # Matilda — the passenger
VW   = "EXAVITQu4vr4xnSDxMaL"   # Sarah — the woman at the window

# condensed stage directions, one per frame (plain, observational)
N = {
 1: "A crowded platform in the heat. A woman waits near the edge, a baby wrapped to the crown in a faded green cloth against her shoulder, one hand flat on its back. When the train comes, she lets the crowd carry her aboard.",
 2: "She takes a place by the barred window and settles the child against her, and she hums, low, the same few notes over and over.",
 3: "A fly settles on the green cloth. She does not brush it away.",
 4: "There are more flies now. The child has not stirred, not at the whistle, not at the vendor's shout. The quiet spreads down the carriage, one face and then the next, and a man rises and the word goes forward.",
 5: "The train slows at a small station. Two policemen come down the platform and climb aboard.",
 6: "They push through the crowd. A policeman reaches for the bundle. Her hand holds it down a moment, then lets go.",
 7: "They bring her down between two constables, her hands empty now. The train pulls away, and her seat is already taken. We never see her face, and we never see inside the cloth.",
}


def ff(args):
    subprocess.run(["ffmpeg", "-nostdin", "-loglevel", "error", "-y"] + args, check=True)


def tts(text, voice, out):
    open(out, "wb").write(bk.elevenlabs_tts(text, voice))
    return out


def sil(sec, out):
    ff(["-f", "lavfi", "-i", "anullsrc=r=44100:cl=mono", "-t", f"{sec}", "-c:a", "libmp3lame", "-b:a", "128k", out])
    return out


def cat(files, out):                      # concat (re-encode for identical params)
    lst = out + ".txt"
    open(lst, "w").write("".join(f"file '{os.path.abspath(p)}'\n" for p in files))
    ff(["-f", "concat", "-safe", "0", "-i", lst, "-c:a", "libmp3lame", "-b:a", "128k", "-ar", "44100", "-ac", "1", out])
    os.remove(lst); return out


# narration + the two lines
for i, t in N.items():
    tts(t, NARR, f"{A}/n{i}.mp3")
tts("कितने महीने का है?", VP, f"{A}/l1.mp3")
tts("सो रहा है।", VW, f"{A}/l2.mp3")
sil(0.4, f"{A}/lead.mp3"); sil(0.55, f"{A}/g.mp3"); sil(1.25, f"{A}/pad.mp3")

# per-frame segments (frame 2 carries the dialogue after its narration); record durations as weights
segs, weights = [], []
for i in range(1, 8):
    parts = [f"{A}/lead.mp3", f"{A}/n{i}.mp3"]
    if i == 2:
        parts += [f"{A}/g.mp3", f"{A}/l1.mp3", f"{A}/g.mp3", f"{A}/l2.mp3"]
    parts.append(f"{A}/pad.mp3")
    s = cat(parts, f"{A}/seg{i}.mp3")
    segs.append(s); weights.append(bk.duration(s))

vo = cat(segs, f"{A}/vo.mp3")
VOD = bk.duration(vo)
print(f"VO {VOD:.1f}s, frame holds: {[round(w,1) for w in weights]}", flush=True)

# synthesized layered train bed at VO length
ff(["-f", "lavfi", "-i", f"anoisesrc=color=brown:amplitude=0.30:duration={VOD}",
    "-f", "lavfi", "-i", f"anoisesrc=color=pink:amplitude=0.16:duration={VOD}",
    "-f", "lavfi", "-i", f"sine=frequency=70:duration={VOD}",
    "-filter_complex",
    "[0:a]lowpass=f=240[r];[1:a]bandpass=f=900:width_type=h:w=1300,tremolo=f=11:d=0.5[t];"
    "[2:a]tremolo=f=1.7:d=0.92,lowpass=f=150,volume=0.7[c];"
    "[r][t][c]amix=inputs=3:normalize=0,highpass=f=38,volume=0.8[bed]",
    "-map", "[bed]", "-t", f"{VOD}", "-c:a", "libmp3lame", f"{A}/bed.mp3"])

# mix: VO over the bed
ff(["-i", f"{A}/vo.mp3", "-i", f"{A}/bed.mp3", "-filter_complex",
    "[1:a]volume=0.32[b];[0:a]volume=1.35[v];[v][b]amix=inputs=2:duration=first:normalize=0,volume=0.95[out]",
    "-map", "[out]", "-c:a", "libmp3lame", "-b:a", "160k", f"{A}/mix.mp3"])

# assemble: each frame held for its narration (weights = segment durations)
kinds = ["kb_in", "kb_in", "kb_in", "kb_out", "kb_in", "kb_in", "kb_out"]
shots = [(f"{D}/f{i}_{n}.png", k, w) for i, n, k, w in zip(
    range(1, 8), ["platform", "settled", "cloth_fly", "noticing", "police", "hand", "empty"], kinds, weights)]
asm.assemble(shots, f"{A}/mix.mp3", f"{D}/train_animatic.mp4", res=(1920, 1080), fps=24, xfade=0.7)
print("ANIMATIC DONE", flush=True)
