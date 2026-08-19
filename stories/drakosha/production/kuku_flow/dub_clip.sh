#!/bin/bash
# dub_clip.sh <video> <out> "<mp3>@<start>[:<mp3>@<start>...]" [keep:<from>-<to>,...]
#
# Lays approved Russian recordings onto a generated clip.
#
# The model generates its own audio. It is worth keeping WHERE NOBODY SPEAKS —
# cloth, the knock of a lid, the room — and worth nothing where someone speaks,
# because what it says is invented Russian-shaped noise.
#
# MUTING IS AUTOMATIC AND TOTAL. Earlier versions took a hand-written list of
# spans to silence, and every span I mistyped or forgot left the model's own
# voice audible underneath ours. So the script now DETECTS every speech window in
# the generated track itself and mutes all of them. The only way generated speech
# survives is if it is named explicitly in the keep list — which is for wordless
# sounds worth having, like a laugh or a gasp.
#
#   keep:14.2-15.0        preserve the generated audio across 14.2s-15.0s
#
# Placement still comes from the generated audio's own envelope: the model marks
# where it animated each mouth, and a recording placed anywhere else makes the
# lips disagree with the words. Measure first, then place.
set -euo pipefail

VIDEO="$1"; OUT="$2"; LINES="$3"; KEEP="${4:-}"

VIDLEN=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$VIDEO")

# ---- refuse to truncate -------------------------------------------------------
OVERRUN=0
IFS=':' read -ra CHECK <<< "$LINES"
for item in "${CHECK[@]}"; do
  FILE="${item%@*}"; AT="${item##*@}"
  ALEN=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$FILE")
  python3 -c "
import sys
end=float('$AT')+float('$ALEN'); vid=float('$VIDLEN')
if end>vid:
    print('  OVERRUN %s: ends at %.2fs in a %.2fs clip — %.2fs would be cut off the end.'%('$FILE'.split('/')[-1],end,vid,end-vid))
    sys.exit(1)
" || OVERRUN=1
done
if [ "$OVERRUN" = "1" ]; then
  echo "REFUSED: at least one line does not fit. Re-gap the recording or place it earlier; never ship the truncation." >&2
  exit 1
fi

# ---- detect every speech window in the generated track -------------------------
SPANS=$(ffmpeg -v error -i "$VIDEO" -ac 1 -ar 8000 -f s16le - 2>/dev/null | python3 -c "
import sys,struct,math
d=sys.stdin.buffer.read(); n=len(d)//2
v=struct.unpack('<%dh'%n,d[:n*2]); w=800   # 0.1s
loud=[]
for i in range(0,n-w,w):
    seg=v[i:i+w]
    loud.append(math.sqrt(sum(x*x for x in seg)/len(seg))>700)
g=0
for i,x in enumerate(loud):
    if x: g=0
    else:
        g+=1
        if g<=6 and i+1<len(loud) and any(loud[i+1:i+7]): loud[i]=True
out=[];s=None
for i,x in enumerate(loud):
    if x and s is None: s=i
    if not x and s is not None:
        if i-s>=2: out.append((max(0,s*0.1-0.25), i*0.1+0.25))
        s=None
if s is not None: out.append((max(0,s*0.1-0.25), len(loud)*0.1+0.25))
print(','.join('%.2f-%.2f'%(a,b) for a,b in out))
")

KEEPLIST="${KEEP#keep:}"
BED="[0:a]volume=0.5"
if [ -n "$SPANS" ]; then
  IFS=',' read -ra S <<< "$SPANS"
  for span in "${S[@]}"; do
    FROM="${span%%-*}"; TO="${span##*-}"
    SKIP=0
    if [ -n "$KEEPLIST" ] && [ "$KEEPLIST" != "$KEEP" ]; then
      IFS=',' read -ra K <<< "$KEEPLIST"
      for k in "${K[@]}"; do
        KF="${k%%-*}"; KT="${k##*-}"
        python3 -c "import sys; sys.exit(0 if (float('$FROM')<float('$KT') and float('$TO')>float('$KF')) else 1)" && SKIP=1
      done
    fi
    if [ "$SKIP" = "0" ]; then
      BED="$BED,volume=enable='between(t,$FROM,$TO)':volume=0"
    else
      echo "  keeping generated audio across ${FROM}-${TO}"
    fi
  done
fi
BED="$BED[bed]"

INPUTS=(); FILTERS=("$BED"); MIX="[bed]"; i=1
IFS=':' read -ra ITEMS <<< "$LINES"
for item in "${ITEMS[@]}"; do
  FILE="${item%@*}"; AT="${item##*@}"
  MS=$(python3 -c "print(int(float('$AT')*1000))")
  INPUTS+=(-i "$FILE")
  FILTERS+=("[${i}:a]adelay=${MS}|${MS},volume=1.9[v${i}]")
  MIX="${MIX}[v${i}]"
  i=$((i+1))
done

FILTERS+=("${MIX}amix=inputs=${i}:normalize=0:dropout_transition=0[out]")
FC=$(IFS=';'; echo "${FILTERS[*]}")

ffmpeg -v error -y -i "$VIDEO" "${INPUTS[@]}" \
  -filter_complex "$FC" \
  -map 0:v -map "[out]" -c:v copy -c:a aac -b:a 192k -shortest "$OUT"
echo "wrote $OUT  (muted: $SPANS)"
