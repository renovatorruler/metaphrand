#!/bin/bash
# Dadi reshoot: 12 shots re-rendered with character reference sheets attached.
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep1/full
STYLE=0c47270d-70f7-4dd0-887f-c06c88ef5fd9
CS=../../charsheets
mkdir -p reshoot

refs_for() { # base name -> extra --image args
  case "$1" in
    T6|s1B1|s1B4) echo "--image $CS/dadi.png --image $CS/kuku.png --image $CS/furia.png --image $CS/vesper.png";;
    T7)           echo "--image $CS/dadi.png --image $CS/kuku.png --image $CS/furia.png --image $CS/vesper.png --image $CS/kalu.png";;
    s1B3)         echo "--image $CS/dadi.png";;
    s6N1|s6N3)    echo "--image $CS/dadi.png --image $CS/kuku.png --image $CS/furia.png";;
  esac
}

prompt_for() { # base
  local base="$1" src
  if grep -q "^$base|||" prompts.txt; then src=$(grep "^$base|||" prompts.txt | sed 's/^[^|]*|||//')
  else src=$(grep "^$base|||" ../../titles/shot_prompts.txt | sed 's/^[^|]*|||//')
  fi
  echo "$src" | sed 's/STYLE REFERENCE: Match the attached reference image EXACTLY\./STYLE REFERENCE: the FIRST attached image is the art style; match it EXACTLY. CHARACTER REFERENCES: every other attached image is the exact locked design of one character in this scene; match each character design EXACTLY, including colors, proportions, and features./'
}

submit() { # name base
  local p refs; p=$(prompt_for "$2"); refs=$(refs_for "$2")
  higgsfield generate create gemini_omni --prompt "$p" --image "$STYLE" $refs --duration 10 --aspect_ratio 16:9 --resolution 720p --json 2>/dev/null | python3 -c "import sys,json
try:
  d=json.load(sys.stdin); v=d[0] if isinstance(d,list) and isinstance(d[0],str) else (d[0].get('id') if isinstance(d,list) else d.get('id'))
  print(v or '')
except Exception: print('')"
}
fetch() {
  local url; url=$(higgsfield generate wait "$2" --json 2>/dev/null | python3 -c "import sys,json
d=json.load(sys.stdin); d=d[0] if isinstance(d,list) else d
print(d.get('result_url') or '')")
  if [ -n "$url" ]; then curl -s -o "reshoot/$1.mp4" "$url"; echo "GOT $1"; else echo "FAILED $1 $2"; fi
}

SHOTS="T6 T7 s1B1 s1B3 s1B4 s6N1 s6N3 T6_f1 s1B3_f1 s6N1_f1 s6N1_f2 s6N3_f1"
declare -a QN QI
for name in $SHOTS; do
  [ -s "reshoot/$name.mp4" ] && continue
  base="${name%_f*}"
  while :; do
    if [ "${#QN[@]}" -ge 7 ]; then fetch "${QN[0]}" "${QI[0]}"; QN=("${QN[@]:1}"); QI=("${QI[@]:1}"); fi
    id=$(submit "$name" "$base")
    if [ -n "$id" ] && [ "$id" != "None" ]; then QN+=("$name"); QI+=("$id"); echo "SUBMITTED $name"; break; fi
    if [ "${#QN[@]}" -gt 0 ]; then fetch "${QN[0]}" "${QI[0]}"; QN=("${QN[@]:1}"); QI=("${QI[@]:1}"); else sleep 30; fi
  done
done
for k in "${!QN[@]}"; do fetch "${QN[$k]}" "${QI[$k]}"; done
echo "RESHOT: $(ls reshoot/*.mp4 2>/dev/null | wc -l | tr -d ' ')/12"
