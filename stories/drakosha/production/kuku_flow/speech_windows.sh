#!/bin/bash
# speech_windows.sh <video> [threshold]
#
# Prints the spans where the GENERATED audio carries speech. Those spans are where
# the model animated a mouth, and they are the only correct places to put our own
# recordings — a line placed from the script's timings instead lands where no lips
# are moving. Read the output as: dub each line at the START of its span.
set -euo pipefail
V="$1"; TH="${2:-900}"
ffmpeg -v error -i "$V" -ac 1 -ar 8000 -f s16le - 2>/dev/null | python3 -c "
import sys,struct,math
th=float('$TH')
d=sys.stdin.buffer.read(); n=len(d)//2
v=struct.unpack('<%dh'%n,d[:n*2]); w=int(8000*0.1)
loud=[]
for i in range(0,n-w,w):
    seg=v[i:i+w]
    loud.append(math.sqrt(sum(x*x for x in seg)/len(seg))>th)
# close gaps shorter than 0.5s so one sentence is one span, not eight
g=0
for i,x in enumerate(loud):
    if x: g=0
    else:
        g+=1
        if g<=5 and i+1<len(loud) and any(loud[i+1:i+6]): loud[i]=True
spans=[];s=None
for i,x in enumerate(loud):
    if x and s is None: s=i
    if not x and s is not None:
        if (i-s)>=3: spans.append((s*0.1,i*0.1))
        s=None
if s is not None: spans.append((s*0.1,len(loud)*0.1))
for a,b in spans: print('  speech %5.2f -> %5.2f   (%.2fs)'%(a,b,b-a))
"
