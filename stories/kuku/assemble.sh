#!/bin/bash
set -e
cd /Users/dusty/Dev/metaphrand/stories/kuku
mkdir -p build && cd build

VIDS=(1ef98150-3555-41df-8e57-a1aaca48dacb c563342f-6fb0-4d7e-aa30-1a45c50949ca 99c6bfd0-dddf-483b-999b-19ce8f1c3dab c6e3bcfb-b1a6-484b-aec8-23df0028da74 8e247855-e121-42a8-aff0-30b06931b74f d4a6b046-fd90-4d49-87a4-a7b469f73eb3)
AUDS=(93d73ae9-20db-4f34-857d-70e1dfe1dd1d a129f564-2e16-4023-a7e7-c15a9c207428 da202985-7f07-479d-b3e7-79f74ee7e922 cd82f277-6556-4195-816b-0fa5a934354a 9750f8c9-fc55-4a63-8f55-186f330256c2 6f0e064e-47ca-4f85-adb8-1a3ea3cb5876)

url() { higgsfield generate wait "$1" --json 2>/dev/null | python3 -c "import sys,json;d=json.load(sys.stdin);d=d[0] if isinstance(d,list) else d;print(d.get('result_url'))"; }

echo "downloading assets..."
for i in 0 1 2 3 4 5; do
  n=$((i+1))
  curl -s -o "v$n.mp4" "$(url ${VIDS[$i]})"
  curl -s -o "a$n.mp3" "$(url ${AUDS[$i]})"
  echo "block $n: video $(ffprobe -v quiet -show_entries format=duration -of csv=p=0 v$n.mp4)s / audio $(ffprobe -v quiet -show_entries format=duration -of csv=p=0 a$n.mp3)s"
done

echo "building 10s segments (narration centered, over-long takes pitch-safely sped)..."
for n in 1 2 3 4 5 6; do
  da=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "a$n.mp3")
  af=$(python3 -c "
da=float('$da')
base='aformat=sample_rates=48000:channel_layouts=stereo,'
if da>10.05:
    print(base+'atempo=%.5f,apad=whole_dur=480000,atrim=0:10'%(da/10.0))
else:
    d=int(max(0.0,(10.0-da)/2.0)*1000)
    print(base+'adelay=%d|%d,apad=whole_dur=480000,atrim=0:10'%(d,d))
")
  ffmpeg -y -i "v$n.mp4" -i "a$n.mp3" -filter_complex \
    "[0:v]scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=30,tpad=stop_mode=clone:stop_duration=10,trim=0:10,setpts=PTS-STARTPTS[v];[1:a]${af}[a]" \
    -map "[v]" -map "[a]" -c:v libx264 -preset veryfast -pix_fmt yuv420p -c:a aac -ar 48000 -t 10 "seg$n.mp4" 2>"seg$n.log"
  echo "seg$n: $(ffprobe -v quiet -show_entries format=duration -of csv=p=0 seg$n.mp4)s"
done

# overlay the clean typographic क onto block 5 (the letter reveal)
ffmpeg -y -i seg5.mp4 -i ka_overlay.png -filter_complex "[0:v][1:v]overlay=0:0[v]" \
  -map "[v]" -map 0:a -c:v libx264 -preset veryfast -pix_fmt yuv420p -c:a copy seg5_ka.mp4 2>seg5_overlay.log
mv seg5_ka.mp4 seg5.mp4
echo "seg5 overlaid with clean क"

printf "file 'seg1.mp4'\nfile 'seg2.mp4'\nfile 'seg3.mp4'\nfile 'seg4.mp4'\nfile 'seg5.mp4'\nfile 'seg6.mp4'\n" > list.txt
ffmpeg -y -f concat -safe 0 -i list.txt -c:v libx264 -preset veryfast -pix_fmt yuv420p -c:a aac -movflags +faststart ../KUKU_EP1_K.mp4 2>concat.log
echo "TOTAL: $(ffprobe -v quiet -show_entries format=duration -of csv=p=0 ../KUKU_EP1_K.mp4)s"
echo "DONE -> stories/kuku/KUKU_EP1_K.mp4"
