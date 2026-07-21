#!/bin/bash
# KUKU Ep1 1-min proof — wait for clips, cut to the audio bed's beats, overlay क, mux.
set -e
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep1/v1min

# 1) wait + download
while read -r tag id; do
  [ "$tag" = "SUBMIT_DONE" ] && break
  n="${tag#CLIP_}"
  [ -s "clip$n.mp4" ] && continue
  url=$(higgsfield generate wait "$id" --json 2>/dev/null | python3 -c "import sys,json
d=json.load(sys.stdin); d=d[0] if isinstance(d,list) else d
print(d.get('result_url') or '')")
  if [ -n "$url" ]; then curl -s -o "clip$n.mp4" "$url"; echo "GOT clip$n"; else echo "FAILED clip$n ($id)"; fi
done < clip_jobs.txt

# 2) cut/stretch each clip to its beat duration
python3 <<'PY'
import json, subprocess, os
beats=json.load(open('beats.json'))
order=['B1','B2','B3','B4','B5','B6','B7']
for i,b in enumerate(order,1):
    s,e,d=beats[b]
    if not os.path.exists(f'clip{i}.mp4'):
        print(f'MISSING clip{i}'); continue
    k=d/10.005
    vf=f"scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,setsar=1,setpts={k:.5f}*PTS,fps=30"
    subprocess.run(['ffmpeg','-y','-i',f'clip{i}.mp4','-vf',vf,'-an','-c:v','libx264','-preset','veryfast','-pix_fmt','yuv420p','-t',f'{d:.3f}',f'seg{i}.mp4'],capture_output=True)
    print(f'seg{i}: target {d}s got', subprocess.check_output(['ffprobe','-v','quiet','-show_entries','format=duration','-of','csv=p=0',f'seg{i}.mp4']).decode().strip())
PY

# 3) concat video
printf "file 'seg1.mp4'\nfile 'seg2.mp4'\nfile 'seg3.mp4'\nfile 'seg4.mp4'\nfile 'seg5.mp4'\nfile 'seg6.mp4'\nfile 'seg7.mp4'\n" > vconcat.txt
ffmpeg -y -f concat -safe 0 -i vconcat.txt -c:v libx264 -preset veryfast -pix_fmt yuv420p video_track.mp4 2>/dev/null

# 4) overlay क fading in at the अक्षर! क! beat (~65.8s), out at end of B6 (68.23s)
ffmpeg -y -i video_track.mp4 -loop 1 -i ../../build/ka_overlay.png -filter_complex \
 "[1:v]format=rgba,fade=in:st=65.8:d=0.4:alpha=1,fade=out:st=68.0:d=0.4:alpha=1[ov];[0:v][ov]overlay=0:0:shortest=1[v]" \
 -map "[v]" -c:v libx264 -preset veryfast -pix_fmt yuv420p video_ka.mp4 2>/dev/null

# 5) mux with the dialogue bed
ffmpeg -y -i video_ka.mp4 -i bed.wav -map 0:v -map 1:a -c:v copy -c:a aac -movflags +faststart ../../KUKU_EP1_1MIN.mp4 2>/dev/null
echo "DONE: $(ffprobe -v quiet -show_entries format=duration -of csv=p=0 ../../KUKU_EP1_1MIN.mp4)s -> stories/kuku/KUKU_EP1_1MIN.mp4"
