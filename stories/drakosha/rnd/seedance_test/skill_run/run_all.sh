#!/usr/bin/env bash
# Verbatim CINEDANCE skill-prompt batch — 9 sequential Seedance 2.0 jobs.
# Serialized by construction; fixed job list = hard budget cap (396 credits).
set -uo pipefail
cd "$(dirname "$0")"

REFS="../../../ep1prod/scene1/references"
FROSYA="$REFS/frosya_pregift_lowpoly_cutout.png"
VASYA="$REFS/vasya_lowpoly_cutout.png"
REDCAR="$REFS/red_hero_car_candidate_v1.png"
PASSAGE="$REFS/drawer_side_interior_candidate_v1.png"

run_job () {
  local n="$1" dur="$2"; shift 2
  local refargs=()
  for r in "$@"; do refargs+=(--image-references "$r"); done
  echo "=== JOB $n (${dur}s) start $(date +%H:%M:%S) ==="
  higgsfield generate create seedance_2_0 \
    --prompt "$(cat "job${n}.prompt.txt")" \
    --duration "$dur" --resolution 720p --aspect-ratio 16:9 --mode std --generate-audio true \
    "${refargs[@]}" \
    --wait --wait-timeout 25m > "job${n}.url.txt" 2> "job${n}.err.txt"
  local rc=$?
  echo "=== JOB $n exit $rc url: $(cat "job${n}.url.txt" 2>/dev/null | tail -1) ==="
  if [ $rc -eq 0 ]; then
    url=$(grep -Eo 'https://[^ ]+\.mp4' "job${n}.url.txt" | tail -1)
    [ -n "$url" ] && curl -sL --max-time 180 -o "clip${n}.mp4" "$url"
  fi
}

run_job 1 12 "$FROSYA" "$VASYA" "$PASSAGE"
run_job 2 12 "$FROSYA" "$VASYA" "$PASSAGE"
run_job 3 8  "$VASYA" "$PASSAGE"
run_job 4 8  "$FROSYA" "$VASYA" "$PASSAGE"
run_job 5 8  "$FROSYA" "$VASYA" "$PASSAGE"
run_job 6 12 "$FROSYA" "$VASYA" "$PASSAGE"
run_job 7 8  "$FROSYA" "$VASYA" "$PASSAGE"
run_job 8 12 "$FROSYA" "$VASYA" "$REDCAR" "$PASSAGE"
run_job 9 8  "$FROSYA" "$VASYA" "$REDCAR" "$PASSAGE"

echo "=== assembling reel ==="
: > concat.txt
for i in 1 2 3 4 5 6 7 8 9; do
  [ -f "clip${i}.mp4" ] && echo "file 'clip${i}.mp4'" >> concat.txt
done
ffmpeg -y -f concat -safe 0 -i concat.txt -c:v libx264 -pix_fmt yuv420p -c:a aac \
  "2026-08-06_EP1_scene1_skillrun_reel_v1.mp4" 2> ffmpeg.log
echo "=== DONE $(date +%H:%M:%S) ==="
ls -la clip*.mp4 2026-08-06_EP1_scene1_skillrun_reel_v1.mp4 2>/dev/null
