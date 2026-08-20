#!/bin/bash
# preflight_delivery.sh <file> [--claims-audio] [--claims-duration N]
#
# Nothing goes to the author unchecked. On 2026-08-20 a concatenated cut was
# handed over with NO AUDIO STREAM AT ALL, described as though she would hear
# the line — because the first input was silent and concat dropped the track,
# and nobody looked at the result. This refuses that.
#
# It also writes a dense contact strip, because the other failure that day was
# judging motion from four sampled frames: a pointing error and a mouth opening
# are invisible in stills and obvious in a strip.
set -euo pipefail
F="$1"; shift || true
CLAIMS_AUDIO=0; CLAIMS_DUR=""
while [ $# -gt 0 ]; do
  case "$1" in
    --claims-audio) CLAIMS_AUDIO=1 ;;
    --claims-duration) shift; CLAIMS_DUR="$1" ;;
  esac; shift
done
[ -f "$F" ] || { echo "REFUSED: $F does not exist"; exit 1; }

STREAMS=$(ffprobe -v error -show_entries stream=codec_type -of csv=p=0 "$F" | tr '\n' ' ')
DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$F")
echo "  streams : $STREAMS"
echo "  duration: ${DUR}s"

FAIL=0
if [ "$CLAIMS_AUDIO" = "1" ]; then
  case "$STREAMS" in
    *audio*) echo "  audio   : present" ;;
    *) echo "  REFUSED: this file is claimed to carry dialogue and has NO AUDIO STREAM."; FAIL=1 ;;
  esac
fi
if [ -n "$CLAIMS_DUR" ]; then
  python3 - "$DUR" "$CLAIMS_DUR" <<'PY' || FAIL=1
import sys
a,b=float(sys.argv[1]),float(sys.argv[2])
if abs(a-b)>0.25:
    print(f"  REFUSED: duration is {a:.2f}s but was claimed as {b:.2f}s."); sys.exit(1)
print(f"  duration matches the claim ({a:.2f}s)")
PY
fi

# a dense strip — every 6th frame — so motion faults cannot hide between samples
OUT="${F%.*}_preflight_strip.jpg"
ffmpeg -v error -y -i "$F" -vf "select='not(mod(n\,6))',scale=240:-1,tile=10x6" -frames:v 1 "$OUT" 2>/dev/null || true
[ -f "$OUT" ] && echo "  strip   : $OUT  <- LOOK AT THIS BEFORE SENDING"

[ "$FAIL" = "0" ] || { echo "PREFLIGHT: FAILED — do not send."; exit 1; }
echo "PREFLIGHT: passed"
