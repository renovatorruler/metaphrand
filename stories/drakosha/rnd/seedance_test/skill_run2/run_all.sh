#!/usr/bin/env bash
# CINEDANCE batch 2 — jobs 10–19 (SH018–SH046), sequential, fixed list = hard budget cap (~432 credits).
set -uo pipefail
cd "$(dirname "$0")"

REFS="../../../ep1prod/scene1/references"
FROSYA="$REFS/frosya_pregift_lowpoly_cutout.png"
VASYA="$REFS/vasya_lowpoly_cutout.png"

run_job () {
  local n="$1" dur="$2"; shift 2
  local refargs=()
  for r in "$@"; do refargs+=(--image-references "$r"); done
  echo "=== JOB $n (${dur}s) start $(date +%H:%M:%S) ==="
  higgsfield generate create seedance_2_0 \
    --prompt "$(cat "job${n}.prompt.txt")" \
    --duration "$dur" --resolution 720p --aspect-ratio 16:9 --mode std --generate-audio true \
    ${refargs[@]+"${refargs[@]}"} \
    --wait --wait-timeout 25m > "job${n}.url.txt" 2> "job${n}.err.txt"
  local rc=$?
  echo "=== JOB $n exit $rc: $(tail -1 "job${n}.url.txt" 2>/dev/null) ==="
  if [ $rc -eq 0 ]; then
    url=$(grep -Eo 'https://[^ ]+\.mp4' "job${n}.url.txt" | tail -1)
    [ -n "$url" ] && curl -sL --max-time 180 -o "clip${n}.mp4" "$url"
  fi
}

run_job 15 8
run_job 16 8
run_job 17 8  "$FROSYA" "$VASYA"
run_job 18 8
run_job 19 8  "$FROSYA"

echo "=== assembling reel 2 ==="
: > concat.txt
for i in 10 11 12 13 14 15 16 17 18 19; do
  [ -f "clip${i}.mp4" ] && echo "file 'clip${i}.mp4'" >> concat.txt
done
ffmpeg -y -f concat -safe 0 -i concat.txt -c:v libx264 -pix_fmt yuv420p -c:a aac \
  "2026-08-06_EP1_scenes2-4_skillrun_reel_v1.mp4" 2> ffmpeg.log
echo "=== DONE $(date +%H:%M:%S) ==="
ls -la clip*.mp4 2026-08-06_EP1_scenes2-4_skillrun_reel_v1.mp4 2>/dev/null
