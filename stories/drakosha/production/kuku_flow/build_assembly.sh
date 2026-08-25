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
TMPD=$(mktemp -d)
trap 'rm -rf "$TMPD"' EXIT
while IFS= read -r line; do
  line="${line%%#*}"; line="$(echo "$line" | xargs)"
  [ -z "$line" ] && continue
  case "$line" in /*) P="$line";; *) P="$DIR/$line";; esac
  if [ ! -f "$P" ]; then echo "MISSING: $P" >&2; exit 1; fi
  D=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$P")
  printf '%7.2f  %s\n' "$D" "$(basename "$P")"
  TOT=$(python3 -c "print(round($TOT+$D,2))"); N=$((N+1))
  NORM_INDEX=$N
  # NORMALISE BEFORE JOINING. The concat demuxer needs every input to share codec
  # parameters, and ours do not: Kling arrives silent and gets a mono bed, mini
  # arrives with stereo 44.1k, the composited inserts are mono 48k. Fed straight
  # in, the join produced a 178s file out of 118s of footage and printed AAC
  # channel-allocation errors while doing it. Each clip is re-encoded to one spec
  # first — same size, same frame rate, same audio layout — and only then joined.
  N2="$TMPD/$(printf '%03d' $NORM_INDEX).mp4"
  # -nostdin: ffmpeg reads stdin by default, and inside this `while read` loop it
  # ate the manifest — the next shot came back with its first character missing
  # and the build reported a file that does not exist.
  ffmpeg -nostdin -v error -y -i "$P" -vf "scale=1280:720:force_original_aspect_ratio=decrease,pad=1280:720:(ow-iw)/2:(oh-ih)/2,fps=24" \
    -c:v libx264 -crf 18 -preset fast -pix_fmt yuv420p \
    -af "aresample=48000" -ac 2 -c:a aac -b:a 192k -ar 48000 "$N2"
  echo "file '$N2'" >> "$LIST"
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
