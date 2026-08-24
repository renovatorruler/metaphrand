#!/bin/bash
# build_assembly.sh <manifest> <out.mp4> — build a cut from a declared shot list.
#
# Refuses to build if any listed clip is missing. Prints the shot count and the
# per-shot durations so a dropped or truncated shot is visible in the output,
# not discovered later in the player.
set -euo pipefail
MAN="$1"; OUT="$2"
DIR="$(cd "$(dirname "$MAN")/../seedance_batch/output" && pwd)"
LIST=$(mktemp); N=0; TOT=0
while IFS= read -r line; do
  line="${line%%#*}"; line="$(echo "$line" | xargs)"
  [ -z "$line" ] && continue
  case "$line" in /*) P="$line";; *) P="$DIR/$line";; esac
  if [ ! -f "$P" ]; then echo "MISSING: $P" >&2; exit 1; fi
  D=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$P")
  printf '%7.2f  %s\n' "$D" "$(basename "$P")"
  TOT=$(python3 -c "print(round($TOT+$D,2))"); N=$((N+1))
  echo "file '$P'" >> "$LIST"
done < "$MAN"
echo "-------  $N shots, ${TOT}s"
ffmpeg -v error -y -f concat -safe 0 -i "$LIST" -c:v libx264 -pix_fmt yuv420p -crf 21 \
  -preset fast -c:a aac -b:a 160k -ar 48000 "$OUT"
ACT=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT")
python3 -c "
a=float('$ACT'); t=float('$TOT')
print('wrote $OUT  %.2fs'%a)
if abs(a-t)>0.5: raise SystemExit('LENGTH MISMATCH: expected %.2fs, got %.2fs'%(t,a))
"
