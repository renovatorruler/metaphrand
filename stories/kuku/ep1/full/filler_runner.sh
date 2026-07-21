#!/bin/bash
# Generate filler takes (same prompt, fresh generation) for every overflow span.
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep1/full
STYLE=0c47270d-70f7-4dd0-887f-c06c88ef5fd9
FILLERS="s0A3_f1 T6_f1 s1B3_f1 s1B5_f1 s2W1_f1 s2W4_f1 s2W5_f1 s2W6_f1 s3Y4_f1 s3Y5_f1 s3Y6_f1 s5H1_f1 s5H2_f1 s5H2_f2 s5H4_f1 s6N1_f1 s6N1_f2 s6N3_f1 s6N2_f1 E4_f1"

prompt_for() { # base setup name
  local base="$1"
  if grep -q "^$base|||" prompts.txt; then grep "^$base|||" prompts.txt | sed 's/^[^|]*|||//'
  else grep "^$base|||" ../../titles/shot_prompts.txt | sed 's/^[^|]*|||//'
  fi
}

submit() {
  higgsfield generate create gemini_omni --prompt "$2" --image "$STYLE" --duration 10 --aspect_ratio 16:9 --resolution 720p --json 2>/dev/null | python3 -c "import sys,json
try:
  d=json.load(sys.stdin); v=d[0] if isinstance(d,list) and isinstance(d[0],str) else (d[0].get('id') if isinstance(d,list) else d.get('id'))
  print(v or '')
except Exception: print('')"
}
fetch() {
  local url; url=$(higgsfield generate wait "$2" --json 2>/dev/null | python3 -c "import sys,json
d=json.load(sys.stdin); d=d[0] if isinstance(d,list) else d
print(d.get('result_url') or '')")
  if [ -n "$url" ]; then curl -s -o "$1.mp4" "$url"; echo "GOT $1"; else echo "FAILED $1 $2"; fi
}

declare -a QN QI
for name in $FILLERS; do
  [ -s "$name.mp4" ] && continue
  base="${name%_f*}"
  p=$(prompt_for "$base")
  while :; do
    if [ "${#QN[@]}" -ge 7 ]; then fetch "${QN[0]}" "${QI[0]}"; QN=("${QN[@]:1}"); QI=("${QI[@]:1}"); fi
    id=$(submit "$name" "$p")
    if [ -n "$id" ] && [ "$id" != "None" ]; then QN+=("$name"); QI+=("$id"); echo "SUBMITTED $name"; break; fi
    if [ "${#QN[@]}" -gt 0 ]; then fetch "${QN[0]}" "${QI[0]}"; QN=("${QN[@]:1}"); QI=("${QI[@]:1}"); else sleep 30; fi
  done
done
for k in "${!QN[@]}"; do fetch "${QN[$k]}" "${QI[$k]}"; done
echo "FILLERS: $(ls *_f?.mp4 2>/dev/null | wc -l | tr -d ' ')/20"
