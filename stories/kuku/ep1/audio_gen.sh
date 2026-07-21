#!/bin/bash
# KUKU Ep1 — cast dialogue TTS. 107 merged calls, Inworld Riya/Manoj (hi), 6 workers.
cd /Users/dusty/Dev/metaphrand/stories/kuku/ep1
mkdir -p raw

voice_for() { # who -> voice name
  case "$1" in
    KUKU|FURIA|"DADI MAYA"|CHEEKU|RADIO) echo "Riya (hi)";;
    *) echo "Manoj (hi)";;
  esac
}

gen_one() {
  local idx="$1" who="$2" text="$3"
  [ -s "raw/$idx.audio" ] && return 0
  local voice; voice=$(voice_for "$who")
  local out url
  out=$(higgsfield generate create inworld_text_to_speech --prompt "$text" --voice "$voice" --wait --json 2>/dev/null)
  url=$(echo "$out" | python3 -c "import sys,json
try:
  d=json.load(sys.stdin); d=d[0] if isinstance(d,list) else d
  print(d.get('result_url') or '')
except: print('')")
  if [ -n "$url" ]; then
    curl -s -o "raw/$idx.audio" "$url" && echo "OK $idx $who"
  else
    echo "FAIL $idx $who"
  fi
}

worker() {
  local k="$1"
  while IFS=$'\t' read -r idx scene who radio whisper text; do
    if [ $((idx % 6)) -eq "$k" ]; then
      gen_one "$idx" "$who" "$text"
    fi
  done < lines.tsv
}

for k in 0 1 2 3 4 5; do worker "$k" & done
wait

# one retry pass for failures
while IFS=$'\t' read -r idx scene who radio whisper text; do
  [ -s "raw/$idx.audio" ] || gen_one "$idx" "$who" "$text"
done < lines.tsv

echo "GENERATED: $(ls raw | wc -l | tr -d ' ')/107"
