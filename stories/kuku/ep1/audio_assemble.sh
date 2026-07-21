#!/bin/bash
# KUKU Ep1 — voice-shape each line per character, then assemble the episode track.
set -e
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep1
mkdir -p proc

pitch_chain() { # factor extra_atempo -> filter string (keeps duration correct)
  python3 -c "
f=float('$1'); extra=float('${2:-1.0}')
at=(1.0/f)*extra
steps=[]
# atempo valid 0.5..2.0; chain if needed
while at<0.5: steps.append(0.5); at/=0.5
while at>2.0: steps.append(2.0); at/=2.0
steps.append(at)
tempo=','.join(f'atempo={s:.5f}' for s in steps)
print(f'aresample=48000,asetrate=48000*{f},aresample=48000,{tempo}')
"
}

filter_for() { # who radio whisper
  local who="$1" radio="$2" whisper="$3" base=""
  case "$who" in
    KUKU)        base=$(pitch_chain 1.22);;
    FURIA)       base=$(pitch_chain 1.10);;
    "DADI MAYA") base=$(pitch_chain 0.93);;
    CHEEKU)      base=$(pitch_chain 1.35);;
    VESPER)      base=$(pitch_chain 1.28 0.95);;
    PAPA)        base=$(pitch_chain 1.0);;
    MUKHIYA)     base=$(pitch_chain 0.97);;
    RADIO)       base=$(pitch_chain 1.02);;
    *)           base=$(pitch_chain 1.0);;
  esac
  [ "$radio" = "1" ] || [ "$who" = "RADIO" ] || [ "$who" = "MUKHIYA" ] && base="$base,highpass=f=300,lowpass=f=3400,volume=0.85"
  [ "$whisper" = "1" ] && base="$base,volume=0.75"
  echo "$base,aformat=sample_rates=48000:channel_layouts=stereo"
}

echo "processing lines..."
while IFS=$'\t' read -r idx scene who radio whisper text; do
  [ -s "raw/$idx.audio" ] || { echo "MISSING raw/$idx.audio"; continue; }
  f=$(filter_for "$who" "$radio" "$whisper")
  ffmpeg -y -i "raw/$idx.audio" -af "$f" -c:a pcm_s16le -ar 48000 -ac 2 "proc/$idx.wav" 2>/dev/null
done < lines.tsv
echo "processed: $(ls proc | wc -l | tr -d ' ')"

# silences
ffmpeg -y -f lavfi -i anullsrc=r=48000:cl=stereo -t 0.35 -c:a pcm_s16le sil_line.wav 2>/dev/null
ffmpeg -y -f lavfi -i anullsrc=r=48000:cl=stereo -t 1.4  -c:a pcm_s16le sil_scene.wav 2>/dev/null

# concat list in manifest order with gaps
python3 -c "
rows=[l.rstrip('\n').split('\t') for l in open('lines.tsv')]
import os
out=open('concat.txt','w')
prev_scene=None
for r in rows:
    idx,scene=r[0],r[1]
    if not os.path.exists(f'proc/{idx}.wav'): continue
    if prev_scene is not None:
        out.write(\"file 'sil_scene.wav'\n\" if scene!=prev_scene else \"file 'sil_line.wav'\n\")
    out.write(f\"file 'proc/{idx}.wav'\n\")
    prev_scene=scene
out.close()
print('concat list written')
"
ffmpeg -y -f concat -safe 0 -i concat.txt -c:a libmp3lame -q:a 2 ../KUKU_EP1_AUDIO_v1.mp3 2>/dev/null
echo "EPISODE AUDIO: $(ffprobe -v quiet -show_entries format=duration -of csv=p=0 ../KUKU_EP1_AUDIO_v1.mp3)s -> stories/kuku/KUKU_EP1_AUDIO_v1.mp3"
